import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_score/data/api/koora_client.dart';
import 'package:pulse_score/data/repositories/football_repository.dart';

import 'support/mock_backend.dart';

/// Repository behaviour on the keyless (Koora) path.
///
/// The backend ignores every query parameter, so all the narrowing the app does
/// — per league, per team, per date — happens here in memory. These tests pin
/// that filtering, and pin what happens when the backend is simply unable to
/// answer (a past date, a league it has no table for): an honest empty result
/// or a labelled demo fallback, never a crash.
String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

FootballRepository _repo({bool fail = false}) => mockRepository(fail: fail);

void main() {
  test('live fixtures come back as live data, not demo', () async {
    final result = await _repo().liveFixtures();
    expect(result.origin, DataOrigin.live);
    expect(result.isDemo, isFalse);
    expect(result.data, hasLength(3));
  });

  test('league fixtures are filtered from the today snapshot', () async {
    final repo = _repo();
    final all = await repo.fixturesOnDate(DateTime.now());
    final leagueId = all.data.first.league.id;

    final filtered = await repo.fixturesForLeague(leagueId);
    expect(filtered.data, isNotEmpty);
    expect(
      filtered.data.every((f) => f.league.id == leagueId),
      isTrue,
      reason: 'must not leak other leagues from the shared snapshot',
    );
    expect(filtered.data.length, lessThan(all.data.length));
  });

  test('a league absent from today returns empty rather than everything',
      () async {
    final filtered = await _repo().fixturesForLeague(-1);
    expect(filtered.data, isEmpty);
    expect(filtered.origin, DataOrigin.live);
  });

  test('team fixtures are filtered from the snapshot', () async {
    final repo = _repo();
    final all = await repo.fixturesOnDate(DateTime.now());
    final teamId = all.data.first.home.id;

    final filtered = await repo.fixturesForTeam(teamId);
    expect(filtered.data, isNotEmpty);
    expect(filtered.data.every((f) => f.involvesTeam(teamId)), isTrue);
  });

  test('a non-today date is empty, not silently today\'s snapshot', () async {
    // The backend publishes only today. Returning today's rows for last week
    // would be worse than returning nothing.
    final past = DateTime.now().subtract(const Duration(days: 30));
    final result = await _repo().fixturesOnDate(past);
    expect(result.data, isEmpty);
  });

  test('standings come back for the league that was asked for', () async {
    final pl = await _repo().standings(39);
    expect(pl.origin, DataOrigin.live);
    expect(pl.data, hasLength(6));
    expect(pl.data.first.team.name, 'Arsenal');
    expect(pl.data.first.points, 85);
  });

  test('a table for the wrong competition is dropped, not shown', () async {
    // The backend's filter is a silent no-op if the parameter name is wrong,
    // so it can answer with someone else's table. Showing that under a Premier
    // League heading would be worse than showing nothing.
    final mismatched = MockClient((req) async => http.Response.bytes(
          utf8.encode(_fixture('koora_standings')), // always Poland
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));
    final repo = FootballRepository(koora: KooraClient(httpClient: mismatched));

    expect((await repo.standings(39)).data, isEmpty);
  });

  test('featured upcoming excludes matches whose kickoff has passed', () async {
    final featured = await _repo().upcomingFeatured();

    expect(featured.data.every((f) => f.isUpcoming), isTrue);
    // A delayed fixture keeps status NS long after its scheduled time; showing
    // it in the carousel renders a spent countdown ("STARTING").
    final now = DateTime.now();
    expect(
      featured.data.every((f) => f.kickoff.isAfter(now)),
      isTrue,
      reason: 'stale not-yet-started fixtures must not lead the carousel',
    );
  });

  test('fixtureById prefers the live row for a match in play', () async {
    final repo = _repo();
    final live = (await repo.liveFixtures()).data.first;

    final found = await repo.fixtureById(live.id);
    expect(found.data?.id, live.id);
    expect(found.data?.isLive, isTrue);
  });

  test('events come from the live payload', () async {
    final repo = _repo();
    final events = await repo.eventsFor(1494265);
    expect(events.data, isNotEmpty);
    expect(events.data.first.player, 'Anton Kurochkin');
  });

  test('an outage reports itself instead of inventing fixtures', () async {
    final result = await _repo(fail: true).liveFixtures();

    // Sample data is off by default: a scores app that quietly shows invented
    // matches is worse than one that admits it has nothing.
    expect(result.isDemo, isFalse);
    expect(result.origin, DataOrigin.unavailable);
    expect(result.data, isEmpty);
    expect(result.notice, isNotNull);
    expect(result.notice, isNot(contains('demo')));
  });

  test('an entirely empty backend is flagged so screens can say so', () async {
    final repo = FootballRepository(
      koora: KooraClient(httpClient: mockClient(noData: true)),
    );
    await repo.fixturesForLeague(39);
    expect(repo.backendHasNoData, isTrue,
        reason: 'lets the UI say the service has no data, not that the '
            'league has no fixtures');

    // And it clears again once the backend has content.
    final live = mockRepository();
    await live.fixturesForLeague(39);
    expect(live.backendHasNoData, isFalse);
  });

  test('an empty backend is live-but-empty, not an error', () async {
    // The real backend 404s with {"success":false,"error":"No today's matches
    // data available"} whenever its cache is cold. That is the server telling
    // us it has nothing — reporting it as "could not reach the server" and
    // swapping in demo fixtures was the bug this guards.
    final repo = FootballRepository(
      koora: KooraClient(httpClient: mockClient(noData: true)),
    );

    final today = await repo.fixturesOnDate(DateTime.now());
    expect(today.origin, DataOrigin.live);
    expect(today.data, isEmpty);
    expect(today.notice, isNull, reason: 'nothing went wrong; there is no data');

    final featured = await repo.upcomingFeatured();
    expect(featured.origin, DataOrigin.live);
    expect(featured.data, isEmpty);
    expect(featured.notice, isNull);
  });

  test('an outage on standings returns an empty table, not a fake one',
      () async {
    final result = await _repo(fail: true).standings(39);
    expect(result.isDemo, isFalse);
    expect(result.origin, DataOrigin.unavailable);
    expect(result.data, isEmpty);
  });

  test('refresh bypasses the cache and re-hits the network', () async {
    var calls = 0;
    final counted = MockClient((req) async {
      calls++;
      return http.Response.bytes(
        utf8.encode(_fixture('koora_live')),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repo = FootballRepository(koora: KooraClient(httpClient: counted));

    await repo.liveFixtures();
    await repo.liveFixtures();
    expect(calls, 1, reason: 'the second read is served from cache');

    await repo.liveFixtures(force: true);
    expect(calls, 2, reason: 'a forced refresh must go back to the network');
  });
}
