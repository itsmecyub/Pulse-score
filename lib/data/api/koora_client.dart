import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/fixture.dart';
import '../models/json.dart';
import '../models/match_event.dart';
import '../models/standing.dart';
import 'api_football_client.dart' show ApiException;

/// Client for the Koora backend (`api-koora-production.up.railway.app`).
///
/// It is a cached proxy in front of API-Football: payloads under `data` are
/// byte-for-byte the upstream v3 shapes, so the existing [Fixture], [Standing]
/// and [MatchEvent] parsers are reused unchanged. Three things differ from
/// talking to api-sports directly, and they drive the whole design here:
///
///  * **No key.** The backend holds the credential, so the app ships working.
///  * **Filtering is `leagueId`, and only on `/standings`.** Upstream spellings
///    (`league`, `league_id`, `id`) are accepted and then silently ignored,
///    handing back the wrong competition rather than an error.
///  * **`/live` and `/today` are whole-world snapshots** that take no filter at
///    all. So there is no per-league fixtures call to make: fetch the two
///    snapshots once, cache them, and narrow in memory.
class KooraClient {
  KooraClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  final Map<String, _CacheEntry> _cache = {};

  /// `/today` is ~1MB and changes slowly; `/live` is the one worth re-pulling.
  static const _liveTtl = Duration(seconds: 25);
  static const _todayTtl = Duration(minutes: 5);
  static const _standingsTtl = Duration(minutes: 15);

  /// How long to remember that the backend had nothing. Short, because its
  /// cache can repopulate at any moment.
  static const _emptyTtl = Duration(seconds: 20);

  void dispose() => _http.close();

  void clearCache() {
    _cache.clear();
    _snapshot = null;
    _snapshotExpires = null;
  }

  Future<List<Map<String, dynamic>>> _get(
    String path, {
    required Duration ttl,
    Map<String, String>? query,
    bool force = false,
  }) async {
    final key = query == null || query.isEmpty
        ? path
        : '$path?${(query.keys.toList()..sort()).map((k) => '$k=${query[k]}').join('&')}';

    if (!force) {
      final cached = _cache[key];
      if (cached != null && !cached.isStale) return cached.data;
    }

    final http.Response res;
    try {
      res = await _http
          .get(ApiConfig.kooraUri(path, query),
              headers: const {'Accept': 'application/json'})
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      throw ApiException('Network unavailable: $e');
    }

    // Parse the envelope before judging the status code. When the backend's
    // cache is empty it answers 404 with {"success":false,"error":"No today's
    // matches data available"} — that is the server telling us it currently has
    // nothing, not a transport failure, and it must not be reported to the user
    // as "could not reach the server".
    Object? body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (body is! Map) {
      throw ApiException(
        'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    if (asBool(body['success'], true) == false) {
      final error = asString(body['error'], 'Request rejected');
      if (_meansNoData(error)) {
        // Cache the emptiness briefly too, so a screen that asks twice in a row
        // doesn't hammer a backend that is mid-refresh.
        _cache[key] = _CacheEntry(const [], DateTime.now().add(_emptyTtl));
        return const [];
      }
      throw ApiException(
        error,
        statusCode: res.statusCode == 200 ? null : res.statusCode,
      );
    }

    if (res.statusCode != 200) {
      throw ApiException(
        'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final data = asMapList(body['data']);
    _cache[key] = _CacheEntry(data, DateTime.now().add(ttl));
    return data;
  }

  /// The backend signals "my cache is empty" through the error text rather than
  /// a distinct status or code, so this has to match on wording.
  static bool _meansNoData(String error) {
    final e = error.toLowerCase();
    return e.contains('no data') ||
        (e.contains('data available') && e.startsWith('no'));
  }

  /// Every match in play, across all competitions (~180 at peak).
  ///
  /// Each row may carry an inline `events` array, which is the only source of
  /// match events this backend exposes — there is no `/events` endpoint.
  Future<List<Fixture>> live({bool force = false}) async {
    final raw = await _get('/live', ttl: _liveTtl, force: force);
    return raw.map(Fixture.fromJson).toList();
  }

  /// Everything scheduled today (~1200 fixtures, ~330 competitions), covering
  /// upcoming, in-play and finished.
  Future<List<Fixture>> today({bool force = false}) async {
    final raw = await _get('/today', ttl: _todayTtl, force: force);
    if (raw.isNotEmpty) return raw.map(Fixture.fromJson).toList();
    // `/today` 404s when the backend's day cache is cold. The aggregate
    // endpoint is populated separately, so it is worth a second look before
    // concluding there is no football today.
    return (await snapshot(force: force)).today;
  }

  /// Events for one fixture, read out of the cached `/live` payload.
  ///
  /// Returns empty for anything not currently live — the backend simply does
  /// not carry events for finished or upcoming matches.
  Future<List<MatchEvent>> eventsFor(int fixtureId) async {
    final raw = await _get('/live', ttl: _liveTtl);
    for (final row in raw) {
      if (asInt(asMap(row['fixture'])['id']) != fixtureId) continue;
      return asMapList(row['events']).map(MatchEvent.fromJson).toList();
    }
    return const [];
  }

  /// One league's table.
  ///
  /// The parameter is `leagueId`, camelCase — the upstream-style `league`,
  /// `league_id` and `id` are all accepted and then silently ignored, which
  /// hands back a different competition's table rather than an error. Getting
  /// this name wrong is invisible, so it is pinned by a test.
  Future<({int? leagueId, List<Standing> rows})> standings(
    int leagueId, {
    bool force = false,
  }) async {
    final raw = await _get(
      '/standings',
      ttl: _standingsTtl,
      query: {'leagueId': '$leagueId'},
      force: force,
    );
    if (raw.isEmpty) return (leagueId: null, rows: const <Standing>[]);

    final league = asMap(raw.first['league']);
    final groups = league['standings'];
    if (groups is! List) {
      return (leagueId: asIntOrNull(league['id']), rows: const <Standing>[]);
    }

    return (
      leagueId: asIntOrNull(league['id']),
      rows: groups
          .whereType<List>()
          .expand((g) => g.whereType<Map>())
          .map((e) => Standing.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// The whole cached snapshot in one request.
  ///
  /// `/api/football` returns an object rather than a list — live, today,
  /// yesterday and tomorrow together — so it answers questions the single-day
  /// endpoints cannot, and costs one round trip instead of several.
  Future<KooraSnapshot> snapshot({bool force = false}) async {
    if (!force) {
      final cached = _snapshot;
      if (cached != null && DateTime.now().isBefore(_snapshotExpires!)) {
        return cached;
      }
    }

    final http.Response res;
    try {
      res = await _http
          .get(ApiConfig.kooraUri(''),
              headers: const {'Accept': 'application/json'})
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      throw ApiException('Network unavailable: $e');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map) throw ApiException('Unexpected response shape');
    if (asBool(body['success'], true) == false) {
      throw ApiException(asString(body['error'], 'Request rejected'));
    }

    final data = asMap(body['data']);
    List<Fixture> read(String key) =>
        asMapList(data[key]).map(Fixture.fromJson).toList();

    final snap = KooraSnapshot(
      live: read('liveMatches'),
      today: read('todayMatches'),
      yesterday: read('yesterdayMatches'),
      tomorrow: read('tomorrowMatches'),
      lastUpdated: DateTime.tryParse(asString(data['lastUpdated']))?.toLocal(),
    );
    _snapshot = snap;
    _snapshotExpires = DateTime.now().add(_todayTtl);
    return snap;
  }

  KooraSnapshot? _snapshot;
  DateTime? _snapshotExpires;

  /// Backend status, including when its cache last refreshed.
  Future<({bool healthy, DateTime? lastUpdated})> health() async {
    final http.Response res;
    try {
      res = await _http
          .get(ApiConfig.kooraUri('/health'))
          .timeout(ApiConfig.timeout);
    } catch (e) {
      throw ApiException('Network unavailable: $e');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = asMap(asMap(body)['data']);
    return (
      healthy: asString(data['status']) == 'healthy',
      lastUpdated: DateTime.tryParse(asString(data['lastUpdated']))?.toLocal(),
    );
  }
}

/// Everything the backend currently holds, from a single request.
class KooraSnapshot {
  const KooraSnapshot({
    required this.live,
    required this.today,
    required this.yesterday,
    required this.tomorrow,
    this.lastUpdated,
  });

  final List<Fixture> live;
  final List<Fixture> today;
  final List<Fixture> yesterday;
  final List<Fixture> tomorrow;

  /// When the backend last refreshed from upstream.
  final DateTime? lastUpdated;

  bool get isEmpty =>
      live.isEmpty && today.isEmpty && yesterday.isEmpty && tomorrow.isEmpty;

  List<Fixture> forDay(DateTime day) {
    final now = DateTime.now();
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (same(day, now)) return today;
    if (same(day, now.subtract(const Duration(days: 1)))) return yesterday;
    if (same(day, now.add(const Duration(days: 1)))) return tomorrow;
    return const [];
  }
}

class _CacheEntry {
  _CacheEntry(this.data, this.expiresAt);
  final List<Map<String, dynamic>> data;
  final DateTime expiresAt;
  bool get isStale => DateTime.now().isAfter(expiresAt);
}
