import 'dart:convert';

/// Behaviour knobs read from the same config file as the ad units.
///
/// These live outside the ads module so it stays a byte-for-byte copy of the
/// one the other apps use. Every key is optional and every default reproduces
/// the module's original behaviour, so an untouched config keeps working.
class AdsTuning {
  const AdsTuning({
    this.interClicks = 2,
    this.openOnResume = true,
    this.openOnStart = true,
    this.bannerEnabled = true,
  });

  /// Show an interstitial on every Nth meaningful tap. `0` never shows one.
  final int interClicks;

  /// Show the app-open ad when coming back from the background.
  final bool openOnResume;

  /// Show the app-open ad on the first screen after launch.
  final bool openOnStart;

  /// Render the banner strip above the tab bar at all.
  final bool bannerEnabled;

  static const defaults = AdsTuning();

  /// Reads the optional `ads.tuning` block:
  ///
  /// ```json
  /// "tuning": {
  ///   "inter_clicks": 2,
  ///   "open_on_resume": true,
  ///   "open_on_start": true,
  ///   "banner": true
  /// }
  /// ```
  factory AdsTuning.fromConfig(String rawJson) {
    try {
      final root = jsonDecode(rawJson);
      if (root is! Map) return defaults;
      final ads = root['ads'];
      if (ads is! Map) return defaults;
      final tuning = ads['tuning'];
      if (tuning is! Map) return defaults;

      return AdsTuning(
        interClicks: _int(tuning['inter_clicks'], defaults.interClicks),
        openOnResume: _bool(tuning['open_on_resume'], defaults.openOnResume),
        openOnStart: _bool(tuning['open_on_start'], defaults.openOnStart),
        bannerEnabled: _bool(tuning['banner'], defaults.bannerEnabled),
      );
    } catch (_) {
      return defaults;
    }
  }

  static int _int(Object? value, int fallback) {
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString().trim() ?? '');
    return parsed ?? fallback;
  }

  /// Accepts real booleans as well as the strings the config file tends to
  /// carry, so `"0"` and `false` mean the same thing.
  static bool _bool(Object? value, bool fallback) {
    if (value is bool) return value;
    final v = value?.toString().trim().toLowerCase() ?? '';
    if (v.isEmpty) return fallback;
    return v != '0' && v != 'false' && v != 'off' && v != 'no';
  }
}

/// The tuning in force. Replaced when the config is loaded.
AdsTuning adsTuning = AdsTuning.defaults;
