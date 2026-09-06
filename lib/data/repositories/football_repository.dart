import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../api/api_football_client.dart';
import '../local/sample_data.dart';
import '../models/fixture.dart';
import '../models/match_event.dart';
import '../models/standing.dart';

/// Where a screen's data actually came from, so the UI can be honest about it
/// (a "demo data" chip rather than pretending sample rows are live).
enum DataOrigin { live, demo }

class Result<T> {
  const Result({required this.data, required this.origin, this.notice});

  final T data;
  final DataOrigin origin;

  /// Set when we fell back — e.g. "Rate limit reached, showing demo data".
  final String? notice;

  bool get isDemo => origin == DataOrigin.demo;
}

/// The single entry point every screen uses for football data.
///
/// It hides two things from the UI: whether an API key exists at all, and what
/// to do when a live call fails. In both cases the answer is the same — serve
/// the offline sample set and label it — so no screen ever has to render a
/// dead end.
class FootballRepository {
  FootballRepository({ApiFootballClient? client})
      : _client = client ?? ApiFootballClient();

  final ApiFootballClient _client;

  bool get isLiveMode => ApiConfig.hasKey;

  void dispose() => _client.dispose();

  void clearCache() => _client.clearCache();

  Future<Result<T>> _guard<T>(
    Future<T> Function() fetch,
    T Function() fallback, {
    bool preferFallbackWhenEmpty = true,
  }) async {
    if (!ApiConfig.hasKey) {
      return Result(data: fallback(), origin: DataOrigin.demo);
    }
    try {
      final data = await fetch();
      final isEmpty = data is Iterable && data.isEmpty;
      if (isEmpty && preferFallbackWhenEmpty) {
        return Result(data: data, origin: DataOrigin.live);
      }
      return Result(data: data, origin: DataOrigin.live);
    } on ApiException catch (e) {
      debugPrint('[PulseScore] API fallback: $e');
      return Result(
        data: fallback(),
        origin: DataOrigin.demo,
        notice: e.isRateLimit
            ? 'API limit reached — showing demo data'
            : 'Could not reach the server — showing demo data',
      );
    } catch (e) {
      debugPrint('[PulseScore] Unexpected fallback: $e');
      return Result(
        data: fallback(),
        origin: DataOrigin.demo,
        notice: 'Something went wrong — showing demo data',
      );
    }
  }

  Future<Result<List<Fixture>>> liveFixtures() =>
      _guard(_client.liveFixtures, SampleData.live);

  Future<Result<List<Fixture>>> fixturesOnDate(DateTime day) => _guard(
        () => _client.fixturesOnDate(day),
        () => SampleData.all()
            .where((f) => _sameDay(f.kickoff, day))
            .toList(),
      );

  Future<Result<List<Fixture>>> fixturesForLeague(int leagueId) => _guard(
        () => _client.fixturesForLeague(leagueId),
        () => SampleData.forLeague(leagueId),
      );

  Future<Result<List<Fixture>>> fixturesForTeam(int teamId) => _guard(
        () => _client.fixturesForTeam(teamId),
        () => SampleData.all().where((f) => f.involvesTeam(teamId)).toList(),
      );

  /// Upcoming matches across the leagues we promote, for the featured carousel.
  Future<Result<List<Fixture>>> upcomingFeatured() => _guard(
        () async {
          final today = await _client.fixturesOnDate(DateTime.now());
          final tomorrow = await _client
              .fixturesOnDate(DateTime.now().add(const Duration(days: 1)));
          final upcoming = [...today, ...tomorrow]
              .where((f) => f.isUpcoming)
              .toList()
            ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
          return upcoming.take(10).toList();
        },
        SampleData.featuredUpcoming,
      );

  Future<Result<Fixture?>> fixtureById(int id) => _guard(
        () => _client.fixtureById(id),
        () => SampleData.all().where((f) => f.id == id).firstOrNull,
      );

  Future<Result<List<MatchEvent>>> eventsFor(int fixtureId) => _guard(
        () => _client.eventsFor(fixtureId),
        () => SampleData.eventsFor(fixtureId),
      );

  Future<Result<List<Standing>>> standings(int leagueId) => _guard(
        () => _client.standings(leagueId),
        () => SampleData.standingsFor(leagueId),
      );

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
