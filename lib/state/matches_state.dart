import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../data/models/fixture.dart';
import '../data/repositories/football_repository.dart';

enum LoadStatus { idle, loading, ready, error }

/// Backing store for the Live tab.
///
/// Polls while the tab is visible and stops the moment it isn't — the free API
/// tier is metered, so a timer running in the background is a real cost.
class MatchesState extends ChangeNotifier {
  MatchesState(this._repo);

  final FootballRepository _repo;

  Timer? _poll;
  bool _disposed = false;

  LoadStatus _status = LoadStatus.idle;
  List<Fixture> _live = const [];
  List<Fixture> _featured = const [];
  String? _notice;
  bool _isDemo = false;
  DateTime? _lastUpdated;

  LoadStatus get status => _status;
  List<Fixture> get live => _live;
  List<Fixture> get featured => _featured;
  String? get notice => _notice;
  bool get isDemo => _isDemo;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isFirstLoad => _status == LoadStatus.loading && _live.isEmpty;

  /// Live matches whose home or away side the user follows.
  List<Fixture> favourites(Set<int> pinnedTeamIds, Set<int> pinnedMatchIds) =>
      _live
          .where((f) =>
              pinnedMatchIds.contains(f.id) ||
              pinnedTeamIds.contains(f.home.id) ||
              pinnedTeamIds.contains(f.away.id))
          .toList();

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _status = LoadStatus.loading;
      _safeNotify();
    }

    final liveResult = await _repo.liveFixtures();
    final featuredResult = await _repo.upcomingFeatured();

    if (_disposed) return;

    // Copy before sorting: a demo-mode result can be a const list.
    _live = List.of(liveResult.data)..sort(_byKickoffDescending);
    _featured = featuredResult.data;
    _isDemo = liveResult.isDemo;
    _notice = liveResult.notice ?? featuredResult.notice;
    _status = LoadStatus.ready;
    _lastUpdated = DateTime.now();
    _safeNotify();
  }

  Future<void> refresh() async {
    _repo.clearCache();
    await load(silent: true);
  }

  void startPolling() {
    _poll?.cancel();
    // Demo mode has nothing new to fetch, so don't burn a timer on it.
    if (!_repo.isLiveMode) return;
    _poll = Timer.periodic(
      ApiConfig.livePollInterval,
      (_) => load(silent: true),
    );
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  static int _byKickoffDescending(Fixture a, Fixture b) =>
      b.kickoff.compareTo(a.kickoff);

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}
