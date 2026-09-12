import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_score/data/api/api_football_client.dart' show ApiException;
import 'package:pulse_score/data/api/koora_client.dart';
import 'package:pulse_score/data/models/fixture.dart';
import 'package:pulse_score/data/models/match_event.dart';

/// These run against payloads recorded from the live Koora backend
/// (`test/fixtures/koora_*.json`), trimmed for size but otherwise untouched —
/// same nesting, same nulls, same field spellings. Hand-written JSON would only
/// prove the parser agrees with my assumptions.
String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

/// Serves the recorded payloads and records which paths were requested.
({
  KooraClient client,
  List<String> calls,
  List<Map<String, String>> queries,
}) _client({int status = 200, String? body}) {
  final calls = <String>[];
  final queries = <Map<String, String>>[];
  final mock = MockClient((req) async {
    calls.add(req.url.path);
    queries.add(req.url.queryParameters);
    if (body != null) return http.Response(body, status);

    final name = switch (req.url.path.split('/').last) {
      'live' => 'koora_live',
      'today' => 'koora_today',
      // The backend answers per leagueId; serve the matching recording.
      'standings' =>
        req.url.queryParameters['leagueId'] == '39'
            ? 'koora_standings_39'
            : 'koora_standings',
      final other => throw StateError('unexpected path $other'),
    };
    return http.Response.bytes(utf8.encode(_fixture(name)), status, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  });
  return (
    client: KooraClient(httpClient: mock),
    calls: calls,
    queries: queries,
  );
}

void main() {
  group('live()', () {
    test('parses the recorded live snapshot', () async {
      final c = _client();
      final live = await c.client.live();

      expect(live, hasLength(3));
      final first = live.first;
      expect(first.home.name, 'IF Brommapojkarna');
      expect(first.away.name, 'IF Elfsborg');
      expect(first.isLive, isTrue);
      expect(first.status.short, '1H');
      expect(first.status.elapsed, 30);
      expect(first.league.country, isNotEmpty);
    });

    test('hits the /api/football prefix on the configured host', () async {
      final c = _client();
      await c.client.live();
      expect(c.calls.single, '/api/football/live');
    });

    test('caches, so a re-poll inside the TTL makes no second request',
        () async {
      final c = _client();
      await c.client.live();
      await c.client.live();
      expect(c.calls, hasLength(1));

      c.client.clearCache();
      await c.client.live();
      expect(c.calls, hasLength(2));
    });
  });

  group('eventsFor()', () {
    test('reads events inlined on the live payload', () async {
      final c = _client();
      final events = await c.client.eventsFor(1494265);

      expect(events, isNotEmpty);
      expect(events.first.kind, EventKind.goal);
      expect(events.first.player, 'Anton Kurochkin');
      expect(events.first.assist, 'Wilmer Odefalk');
      expect(events.first.minute, 2);
    });

    test('returns empty for a fixture that is not live', () async {
      final c = _client();
      // The backend has no events endpoint, so anything outside the live
      // snapshot legitimately has none — that must not throw.
      expect(await c.client.eventsFor(999999), isEmpty);
    });
  });

  group('today()', () {
    test('parses every status the snapshot contains', () async {
      final c = _client();
      final today = await c.client.today();

      expect(today, hasLength(8));
      final phases = today.map((f) => f.status.phase).toSet();
      expect(phases, contains(MatchPhase.finished));
      expect(phases, contains(MatchPhase.upcoming));
      expect(phases, contains(MatchPhase.live));
      // TBD and PST are real rows in the feed and must not crash the parser.
      expect(today.every((f) => f.home.name.isNotEmpty), isTrue);
    });

    test('keeps kickoff times and scores intact', () async {
      final c = _client();
      final finished = (await c.client.today()).firstWhere((f) => f.isFinished);
      expect(finished.hasScore, isTrue);
      expect(finished.kickoff.year, greaterThan(2000));
    });
  });

  group('standings()', () {
    test('sends the leagueId parameter, not the upstream spelling', () async {
      // `league`, `league_id` and `id` are all accepted by the backend and then
      // ignored, returning some other competition's table. Only `leagueId`
      // filters, and the failure is silent — hence this test.
      final c = _client();
      await c.client.standings(39);
      expect(c.queries.single['leagueId'], '39');
      expect(c.queries.single.keys, ['leagueId']);
    });

    test('parses a real Premier League table', () async {
      final c = _client();
      final snapshot = await c.client.standings(39);

      expect(snapshot.leagueId, 39);
      expect(snapshot.rows, hasLength(6));
      expect(snapshot.rows.first.rank, 1);
      expect(snapshot.rows.first.team.name, 'Arsenal');
      expect(snapshot.rows.first.points, 85);
      expect(snapshot.rows.first.played, 38);
      expect(snapshot.rows.first.goalDifference, 44);
      expect(snapshot.rows.first.form, 'WWWWW');
      expect(snapshot.rows.first.team.logo, contains('42.png'));
    });

    test('flattens the nested group array and reports the league', () async {
      final c = _client();
      final snapshot = await c.client.standings(782);

      expect(snapshot.leagueId, 782);
      expect(snapshot.rows, hasLength(4));
      expect(snapshot.rows.first.team.name, 'Lechia Zielona Góra');
      expect(snapshot.rows.first.goalDifference, 60);
    });

    test('caches per league rather than sharing one standings slot', () async {
      final c = _client();
      await c.client.standings(39);
      await c.client.standings(782);
      await c.client.standings(39);

      // Two distinct leagues, two requests — the third is served from cache.
      expect(c.calls, hasLength(2));
    });
  });

  group('failures', () {
    test('surfaces a non-200 as ApiException', () async {
      final c = _client(status: 503, body: 'gateway down');
      expect(c.client.live(), throwsA(isA<ApiException>()));
    });

    test('honours the envelope error flag over the status code', () async {
      final c = _client(
        body: '{"success":false,"error":"Upstream quota exceeded"}',
      );
      await expectLater(
        c.client.live(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('quota'),
          ),
        ),
      );
    });

    test('rejects a non-JSON body rather than hanging', () async {
      final c = _client(body: '<html>502 Bad Gateway</html>');
      expect(c.client.live(), throwsA(isA<Exception>()));
    });
  });
}
