import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/fixture.dart';
import '../models/json.dart';
import '../models/league.dart';
import '../models/match_event.dart';
import '../models/standing.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  /// True when the failure is the free tier's daily/minute cap rather than a
  /// bug — the UI phrases these differently.
  bool get isRateLimit => statusCode == 429;

  /// True when we never got an answer at all, as opposed to the server
  /// answering with a problem. The two deserve different wording.
  bool get isOffline =>
      statusCode == null &&
      (message.contains('Network unavailable') || message.contains('timed out'));

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin typed wrapper over the api-sports.io v3 REST surface.
///
/// Every endpoint answers with the same envelope:
///   { "response": [...], "errors": [...] | {...}, "results": n }
/// so parsing funnels through [_get].
class ApiFootballClient {
  ApiFootballClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Short-lived response cache. The free tier bills per request and several
  /// screens ask for the same day's fixtures, so this keeps traffic sane.
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 2);

  void dispose() => _http.close();

  void clearCache() => _cache.clear();

  Future<List<Map<String, dynamic>>> _get(
    String path,
    Map<String, String> query, {
    Duration ttl = _cacheTtl,
  }) async {
    if (!ApiConfig.hasKey) {
      throw ApiException('No API key configured');
    }

    final cacheKey = '$path?${_stableQuery(query)}';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isStale) return cached.data;

    final http.Response res;
    try {
      res = await _http
          .get(ApiConfig.uri(path, query), headers: ApiConfig.headers)
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      throw ApiException('Network unavailable: $e');
    }

    if (res.statusCode != 200) {
      throw ApiException(
        'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map) throw ApiException('Unexpected response shape');

    _throwIfErrors(body['errors']);

    final data = asMapList(body['response']);
    _cache[cacheKey] = _CacheEntry(data, DateTime.now().add(ttl));
    return data;
  }

  /// api-sports returns `errors` as an empty list on success but as an object
  /// of field -> message on failure, so both shapes need handling.
  void _throwIfErrors(Object? errors) {
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first.toString();
      throw ApiException(
        first,
        statusCode: first.toLowerCase().contains('limit') ? 429 : null,
      );
    }
    if (errors is List && errors.isNotEmpty) {
      throw ApiException(errors.first.toString());
    }
  }

  String _stableQuery(Map<String, String> q) {
    final keys = q.keys.toList()..sort();
    return keys.map((k) => '$k=${q[k]}').join('&');
  }

  // --- Fixtures ---

  /// Every match currently in play, across all competitions.
  Future<List<Fixture>> liveFixtures() async {
    final raw = await _get(
      '/fixtures',
      {'live': 'all'},
      ttl: const Duration(seconds: 25),
    );
    return raw.map(Fixture.fromJson).toList();
  }

  Future<List<Fixture>> fixturesOnDate(DateTime day, {String? timezone}) async {
    final raw = await _get('/fixtures', {
      'date': _ymd(day),
      'timezone': ?timezone,
    });
    return raw.map(Fixture.fromJson).toList();
  }

  Future<List<Fixture>> fixturesForLeague(
    int leagueId, {
    int? season,
    int? last,
    int? next,
  }) async {
    final raw = await _get('/fixtures', {
      'league': '$leagueId',
      'season': '${season ?? ApiConfig.season}',
      if (last != null) 'last': '$last',
      if (next != null) 'next': '$next',
    });
    return raw.map(Fixture.fromJson).toList();
  }

  Future<List<Fixture>> fixturesForTeam(int teamId, {int? season}) async {
    final raw = await _get('/fixtures', {
      'team': '$teamId',
      'season': '${season ?? ApiConfig.season}',
    });
    return raw.map(Fixture.fromJson).toList();
  }

  Future<Fixture?> fixtureById(int id) async {
    final raw = await _get(
      '/fixtures',
      {'id': '$id'},
      ttl: const Duration(seconds: 20),
    );
    return raw.isEmpty ? null : Fixture.fromJson(raw.first);
  }

  Future<List<MatchEvent>> eventsFor(int fixtureId) async {
    final raw = await _get(
      '/fixtures/events',
      {'fixture': '$fixtureId'},
      ttl: const Duration(seconds: 20),
    );
    return raw.map(MatchEvent.fromJson).toList();
  }

  // --- Standings ---

  Future<List<Standing>> standings(int leagueId, {int? season}) async {
    final raw = await _get('/standings', {
      'league': '$leagueId',
      'season': '${season ?? ApiConfig.season}',
    }, ttl: const Duration(minutes: 10));

    if (raw.isEmpty) return const [];

    // response[0].league.standings is a list of groups, each a list of rows.
    final league = asMap(raw.first['league']);
    final groups = league['standings'];
    if (groups is! List) return const [];

    return groups
        .whereType<List>()
        .expand((g) => g.whereType<Map>())
        .map((e) => Standing.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // --- Leagues ---

  Future<List<League>> leagueById(int id) async {
    final raw = await _get(
      '/leagues',
      {'id': '$id'},
      ttl: const Duration(hours: 6),
    );
    return raw.map((e) {
      final l = asMap(e['league']);
      final c = asMap(e['country']);
      return League.fromJson({...l, 'country': c['name'], 'code': c['code'], 'flag': c['flag']});
    }).toList();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _CacheEntry {
  _CacheEntry(this.data, this.expiresAt);
  final List<Map<String, dynamic>> data;
  final DateTime expiresAt;
  bool get isStale => DateTime.now().isAfter(expiresAt);
}
