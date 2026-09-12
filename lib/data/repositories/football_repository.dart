import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../api/api_football_client.dart';
import '../api/koora_client.dart';
import '../local/sample_data.dart';
import '../models/fixture.dart';
import '../models/match_event.dart';
import '../models/standing.dart';

/// Where a screen's data actually came from, so the UI can be honest about it.
///
/// [unavailable] is the important one: the request failed, and rather than
/// inventing content we return nothing and say so. [demo] only appears when
/// sample data is explicitly switched on for development.
enum DataOrigin { live, unavailable, demo }

class Result<T> {
  const Result({required this.data, required this.origin, this.notice});

  final T data;
  final DataOrigin origin;

  /// User-facing explanation when something went wrong. Null on success.
  final String? notice;

  bool get isDemo => origin == DataOrigin.demo;
  bool get isLive => origin == DataOrigin.live;
}

/// The single entry point every screen uses for football data.
///
/// It hides three things from the UI: which backend is in play, that Koora
/// cannot filter fixtures server-side, and what to do when a call fails.
///
/// Source selection is per-capability. Koora covers today's football and every
/// promoted league's table without a key, so it is the default; an
/// API-Football key, when present, unlocks what Koora cannot answer (arbitrary
/// dates, full season history) and takes over.
class FootballRepository {
  FootballRepository({KooraClient? koora, ApiFootballClient? apiFootball})
      : _koora = koora ?? KooraClient(),
        _direct = apiFootball ?? ApiFootballClient();

  final KooraClient _koora;
  final ApiFootballClient _direct;

  bool get _hasDirect => ApiConfig.hasKey;

  bool get isLiveMode => true;

  /// When the backend last refreshed from upstream, if it told us.
  DateTime? lastUpdated;

  /// True when the backend answered but had nothing at all — no live matches,
  /// no fixtures for any day. That is a service-side outage of content, not
  /// "this league has no games", and the screens word it differently.
  bool backendHasNoData = false;

  void dispose() {
    _koora.dispose();
    _direct.dispose();
  }

  void clearCache() {
    _koora.clearCache();
    _direct.clearCache();
  }

  /// Runs a request and turns any failure into a labelled, empty result.
  ///
  /// It deliberately does *not* substitute sample data by default. A scores app
  /// that quietly shows invented fixtures is worse than one that says it has
  /// nothing — see [ApiConfig.useDemoData].
  Future<Result<T>> _guard<T>(
    Future<T> Function() fetch, {
    required T Function() empty,
    T Function()? demo,
  }) async {
    try {
      return Result(data: await fetch(), origin: DataOrigin.live);
    } on ApiException catch (e) {
      debugPrint('[PulseScore] request failed: $e');
      return _failure(
        e.isRateLimit
            ? 'API limit reached — try again shortly'
            : e.isOffline
                ? 'No connection — pull down to retry'
                : 'The server had a problem — pull down to retry',
        empty: empty,
        demo: demo,
      );
    } catch (e) {
      debugPrint('[PulseScore] unexpected failure: $e');
      return _failure('Something went wrong — pull down to retry',
          empty: empty, demo: demo);
    }
  }

  Result<T> _failure<T>(
    String notice, {
    required T Function() empty,
    T Function()? demo,
  }) {
    if (ApiConfig.useDemoData && demo != null) {
      return Result(
        data: demo(),
        origin: DataOrigin.demo,
        notice: '$notice (showing demo data)',
      );
    }
    return Result(data: empty(), origin: DataOrigin.unavailable, notice: notice);
  }

  Future<Result<List<Fixture>>> liveFixtures({bool force = false}) => _guard(
        () async {
          if (_hasDirect) return _direct.liveFixtures();
          final live = await _koora.live(force: force);
          if (live.isNotEmpty) backendHasNoData = false;
          return live;
        },
        empty: () => const <Fixture>[],
        demo: SampleData.live,
      );

  /// Fixtures on a given day.
  ///
  /// Koora publishes yesterday, today and tomorrow through its aggregate
  /// endpoint; anything outside that window needs an API-Football key, and
  /// without one comes back empty rather than pretending today's rows apply.
  Future<Result<List<Fixture>>> fixturesOnDate(
    DateTime day, {
    bool force = false,
  }) =>
      _guard(
        () async {
          if (_hasDirect) return _direct.fixturesOnDate(day);
          final snap = await _koora.snapshot(force: force);
          lastUpdated = snap.lastUpdated;
          final rows = snap.forDay(day);
          if (rows.isNotEmpty || !_isToday(day)) return rows;
          // The aggregate can lag the dedicated endpoint; try it before
          // reporting an empty day.
          return _koora.today(force: force);
        },
        empty: () => const <Fixture>[],
        demo: () =>
            SampleData.all().where((f) => _sameDay(f.kickoff, day)).toList(),
      );

  /// A league's fixtures — today's snapshot filtered in memory, because the
  /// backend ignores `?league=` on the fixtures endpoints.
  Future<Result<List<Fixture>>> fixturesForLeague(
    int leagueId, {
    bool force = false,
  }) =>
      _guard(
        () async {
          if (_hasDirect) return _direct.fixturesForLeague(leagueId);
          final all = await _todayAndLive(force: force);
          return all.where((f) => f.league.id == leagueId).toList();
        },
        empty: () => const <Fixture>[],
        demo: () => SampleData.forLeague(leagueId),
      );

  Future<Result<List<Fixture>>> fixturesForTeam(
    int teamId, {
    bool force = false,
  }) =>
      _guard(
        () async {
          if (_hasDirect) return _direct.fixturesForTeam(teamId);
          final all = await _todayAndLive(force: force);
          return all.where((f) => f.involvesTeam(teamId)).toList();
        },
        empty: () => const <Fixture>[],
        demo: () =>
            SampleData.all().where((f) => f.involvesTeam(teamId)).toList(),
      );

  /// Upcoming matches for the featured carousel, soonest first.
  Future<Result<List<Fixture>>> upcomingFeatured({bool force = false}) => _guard(
        () async {
          final pool = _hasDirect
              ? [
                  ...await _direct.fixturesOnDate(DateTime.now()),
                  ...await _direct.fixturesOnDate(
                      DateTime.now().add(const Duration(days: 1))),
                ]
              : await _todayAndTomorrow(force: force);

          // "Not started" is not the same as "still to come": a delayed match
          // keeps its NS status well past its scheduled time, and sorting by
          // kickoff would park those at the front showing a spent countdown.
          final now = DateTime.now();
          final upcoming = pool
              .where((f) => f.isUpcoming && f.kickoff.isAfter(now))
              .toList()
            ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
          return _preferBigLeagues(upcoming).take(10).toList();
        },
        empty: () => const <Fixture>[],
        demo: SampleData.featuredUpcoming,
      );

  Future<Result<Fixture?>> fixtureById(int id, {bool force = false}) => _guard(
        () async {
          if (_hasDirect) return _direct.fixtureById(id);
          // Live first: it carries the freshest score for a match in play.
          for (final f in await _koora.live(force: force)) {
            if (f.id == id) return f;
          }
          for (final f in await _koora.today(force: force)) {
            if (f.id == id) return f;
          }
          return null;
        },
        empty: () => null,
        demo: () => SampleData.all().where((f) => f.id == id).firstOrNull,
      );

  Future<Result<List<MatchEvent>>> eventsFor(int fixtureId) => _guard(
        () => _hasDirect
            ? _direct.eventsFor(fixtureId)
            : _koora.eventsFor(fixtureId),
        empty: () => const <MatchEvent>[],
        demo: () => SampleData.eventsFor(fixtureId),
      );

  /// A league table, straight from the backend for the league asked for.
  Future<Result<List<Standing>>> standings(
    int leagueId, {
    bool force = false,
  }) =>
      _guard(
        () async {
          if (_hasDirect) return _direct.standings(leagueId);
          final snapshot = await _koora.standings(leagueId, force: force);
          // Guard against the backend answering with a different competition:
          // its filter fails silently, and a mismatched table is worse than
          // none.
          if (snapshot.leagueId != null && snapshot.leagueId != leagueId) {
            return const <Standing>[];
          }
          return snapshot.rows;
        },
        empty: () => const <Standing>[],
        demo: () => SampleData.standingsFor(leagueId),
      );

  /// Today's fixtures plus anything in play, de-duplicated.
  ///
  /// A live match appears in both feeds; the live row wins because its score
  /// and minute are fresher.
  Future<List<Fixture>> _todayAndLive({required bool force}) async {
    final snap = await _koora.snapshot(force: force);
    lastUpdated = snap.lastUpdated;

    final byId = <int, Fixture>{};
    final today =
        snap.today.isNotEmpty ? snap.today : await _koora.today(force: force);
    for (final f in today) {
      byId[f.id] = f;
    }
    final live =
        snap.live.isNotEmpty ? snap.live : await _koora.live(force: force);
    for (final f in live) {
      byId[f.id] = f;
    }
    backendHasNoData = byId.isEmpty;
    return byId.values.toList();
  }

  Future<List<Fixture>> _todayAndTomorrow({required bool force}) async {
    final snap = await _koora.snapshot(force: force);
    lastUpdated = snap.lastUpdated;
    if (!snap.isEmpty) {
      backendHasNoData = false;
      return [...snap.today, ...snap.tomorrow];
    }
    final today = await _koora.today(force: force);
    backendHasNoData = today.isEmpty;
    return today;
  }

  /// The featured carousel should lead with competitions people recognise —
  /// the snapshot spans 300+ leagues, most of them obscure.
  static List<Fixture> _preferBigLeagues(List<Fixture> fixtures) {
    const marquee = {39, 140, 78, 135, 61, 2, 3, 88, 94, 203, 71, 128, 253};
    final top = fixtures.where((f) => marquee.contains(f.league.id));
    final rest = fixtures.where((f) => !marquee.contains(f.league.id));
    return [...top, ...rest];
  }

  static bool _isToday(DateTime d) => _sameDay(d, DateTime.now());

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
