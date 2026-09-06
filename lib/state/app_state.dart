import 'package:flutter/foundation.dart';

import '../data/local/preferences.dart';
import '../data/models/league_catalog.dart';

/// App-wide preferences: language, first-run progress, entitlement, pins.
///
/// Deliberately separate from match data — this state is cheap, synchronous
/// after boot, and read by nearly every screen.
class AppState extends ChangeNotifier {
  AppState(this._prefs)
      : _languageCode = _prefs.languageCode ?? 'en',
        _onboardingComplete = _prefs.onboardingComplete,
        _languageChosen = _prefs.languageCode != null,
        _notificationsAsked = _prefs.notificationsAsked,
        _notificationsEnabled = _prefs.notificationsEnabled,
        _defaultLeagueId = _prefs.defaultLeagueId,
        _isPremium = _prefs.isPremium,
        _pinnedTeamIds = _prefs.pinnedTeamIds,
        _pinnedMatchIds = _prefs.pinnedMatchIds;

  final Preferences _prefs;

  String _languageCode;
  bool _languageChosen;
  bool _onboardingComplete;
  bool _notificationsAsked;
  bool _notificationsEnabled;
  int _defaultLeagueId;
  bool _isPremium;
  Set<int> _pinnedTeamIds;
  Set<int> _pinnedMatchIds;

  String get languageCode => _languageCode;
  bool get languageChosen => _languageChosen;
  bool get onboardingComplete => _onboardingComplete;
  bool get notificationsAsked => _notificationsAsked;
  bool get notificationsEnabled => _notificationsEnabled;
  int get defaultLeagueId => _defaultLeagueId;
  bool get isPremium => _isPremium;
  Set<int> get pinnedTeamIds => _pinnedTeamIds;
  Set<int> get pinnedMatchIds => _pinnedMatchIds;

  CatalogLeague get defaultLeague =>
      LeagueCatalog.byId(_defaultLeagueId) ?? LeagueCatalog.defaultLeague;

  /// Free users get the padlocked leagues blocked; premium unlocks everything.
  bool canAccess(CatalogLeague league) => _isPremium || !league.premium;

  /// The cap that makes Premium worth buying.
  static const freePinLimit = 3;
  bool get pinLimitReached =>
      !_isPremium && _pinnedTeamIds.length >= freePinLimit;

  Future<void> setLanguage(String code) async {
    if (_languageCode == code && _languageChosen) return;
    _languageCode = code;
    _languageChosen = true;
    notifyListeners();
    await _prefs.setLanguageCode(code);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    await _prefs.setOnboardingComplete(true);
  }

  Future<void> recordNotificationChoice(bool enabled) async {
    _notificationsAsked = true;
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs.setNotificationsAsked(true);
    await _prefs.setNotificationsEnabled(enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs.setNotificationsEnabled(enabled);
  }

  Future<void> setDefaultLeague(int leagueId) async {
    _defaultLeagueId = leagueId;
    notifyListeners();
    await _prefs.setDefaultLeagueId(leagueId);
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    notifyListeners();
    await _prefs.setPremium(value);
  }

  bool isTeamPinned(int teamId) => _pinnedTeamIds.contains(teamId);
  bool isMatchPinned(int matchId) => _pinnedMatchIds.contains(matchId);

  /// Returns false when the free tier's pin limit blocked the pin, so the
  /// caller can surface the paywall instead of silently doing nothing.
  Future<bool> toggleTeamPin(int teamId) async {
    final next = Set<int>.from(_pinnedTeamIds);
    if (next.contains(teamId)) {
      next.remove(teamId);
    } else {
      if (pinLimitReached) return false;
      next.add(teamId);
    }
    _pinnedTeamIds = next;
    notifyListeners();
    await _prefs.setPinnedTeamIds(next);
    return true;
  }

  Future<bool> toggleMatchPin(int matchId) async {
    final next = Set<int>.from(_pinnedMatchIds);
    if (next.contains(matchId)) {
      next.remove(matchId);
    } else {
      if (!_isPremium && next.length >= freePinLimit) return false;
      next.add(matchId);
    }
    _pinnedMatchIds = next;
    notifyListeners();
    await _prefs.setPinnedMatchIds(next);
    return true;
  }
}
