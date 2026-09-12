import 'package:shared_preferences/shared_preferences.dart';

/// Typed façade over SharedPreferences so keys live in exactly one place.
class Preferences {
  Preferences._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Preferences> load() async =>
      Preferences._(await SharedPreferences.getInstance());

  static const _kLanguage = 'language_code';
  static const _kOnboarded = 'onboarding_complete';
  static const _kNotificationsAsked = 'notifications_asked';
  static const _kNotificationsOn = 'notifications_enabled';
  static const _kDefaultLeague = 'default_league_id';
  static const _kPinnedTeams = 'pinned_team_ids';
  static const _kPinnedMatches = 'pinned_match_ids';
  static const _kPremium = 'premium_active';
  static const _kReviewPrompt = 'has_shown_review_prompt';

  String? get languageCode => _prefs.getString(_kLanguage);
  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_kLanguage, code);

  bool get onboardingComplete => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboardingComplete(bool v) => _prefs.setBool(_kOnboarded, v);

  bool get notificationsAsked => _prefs.getBool(_kNotificationsAsked) ?? false;
  Future<void> setNotificationsAsked(bool v) =>
      _prefs.setBool(_kNotificationsAsked, v);

  bool get notificationsEnabled => _prefs.getBool(_kNotificationsOn) ?? false;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(_kNotificationsOn, v);

  int get defaultLeagueId => _prefs.getInt(_kDefaultLeague) ?? 39;
  Future<void> setDefaultLeagueId(int id) => _prefs.setInt(_kDefaultLeague, id);

  bool get isPremium => _prefs.getBool(_kPremium) ?? false;
  Future<void> setPremium(bool v) => _prefs.setBool(_kPremium, v);

  /// Whether the App Store review prompt has already been offered on this
  /// device. Set once, never cleared — the ask is a one-time thing.
  bool get hasShownReviewPrompt => _prefs.getBool(_kReviewPrompt) ?? false;
  Future<void> setHasShownReviewPrompt(bool v) =>
      _prefs.setBool(_kReviewPrompt, v);

  Set<int> get pinnedTeamIds => _readIds(_kPinnedTeams);
  Future<void> setPinnedTeamIds(Set<int> ids) => _writeIds(_kPinnedTeams, ids);

  Set<int> get pinnedMatchIds => _readIds(_kPinnedMatches);
  Future<void> setPinnedMatchIds(Set<int> ids) =>
      _writeIds(_kPinnedMatches, ids);

  Set<int> _readIds(String key) => (_prefs.getStringList(key) ?? const [])
      .map(int.tryParse)
      .whereType<int>()
      .toSet();

  Future<void> _writeIds(String key, Set<int> ids) =>
      _prefs.setStringList(key, ids.map((e) => '$e').toList());
}
