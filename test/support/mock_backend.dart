import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_score/data/api/koora_client.dart';
import 'package:pulse_score/data/repositories/football_repository.dart';

/// A repository wired to payloads recorded from the live Koora backend.
///
/// Widget tests have no network — `flutter_test` answers every request with a
/// 400 — so without this the screens would render their "no data" state and
/// prove nothing about how they lay out real fixtures.
FootballRepository mockRepository({bool fail = false, bool noData = false}) {
  return FootballRepository(
    koora: KooraClient(httpClient: mockClient(fail: fail, noData: noData)),
  );
}

/// [noData] reproduces the backend's real behaviour when its cache is cold: a
/// 404 whose body says `{"success":false,"error":"No ... data available"}`.
http.Client mockClient({bool fail = false, bool noData = false}) {
  return MockClient((req) async {
    if (fail) return http.Response('upstream down', 502);

    final last = req.url.path.split('/').last;

    if (noData) {
      if (last == 'live' || last == 'football') {
        return _json({'success': true, 'data': last == 'live' ? [] : _emptyAggregate});
      }
      return http.Response(
        jsonEncode({
          'success': false,
          'error': "No ${last == 'today' ? "today's matches" : last} data available",
        }),
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (last == 'football') {
      return _json({
        'success': true,
        'data': {
          'liveMatches': _fixture('koora_live')['data'],
          'todayMatches': _fixture('koora_today')['data'],
          'yesterdayMatches': const [],
          'tomorrowMatches': const [],
          'lastUpdated': '2026-09-09T14:59:04.440Z',
        },
      });
    }

    final name = switch (last) {
      'live' => 'koora_live',
      'today' => 'koora_today',
      'standings' => req.url.queryParameters['leagueId'] == '39'
          ? 'koora_standings_39'
          : 'koora_standings',
      _ => throw StateError('unexpected path $last'),
    };

    return http.Response.bytes(
      utf8.encode(File('test/fixtures/$name.json').readAsStringSync()),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

const _emptyAggregate = {
  'liveMatches': [],
  'todayMatches': [],
  'yesterdayMatches': [],
  'tomorrowMatches': [],
  'lastUpdated': '2026-09-09T14:59:04.440Z',
};

Map<String, dynamic> _fixture(String name) => jsonDecode(
      File('test/fixtures/$name.json').readAsStringSync(),
    ) as Map<String, dynamic>;

http.Response _json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
