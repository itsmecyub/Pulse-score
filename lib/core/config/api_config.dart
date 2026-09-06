/// API-Football (api-sports.io) configuration.
///
/// Supply the key at build time so it never lands in source control:
///
///   flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
///
/// With no key the app runs against the bundled fixtures in `assets/data/`,
/// so the whole UI is browsable offline.
class ApiConfig {
  ApiConfig._();

  static const String key = String.fromEnvironment('API_FOOTBALL_KEY');

  /// Direct api-sports.io host. If you subscribe through RapidAPI instead,
  /// override with --dart-define=API_FOOTBALL_HOST=api-football-v1.p.rapidapi.com
  static const String host = String.fromEnvironment(
    'API_FOOTBALL_HOST',
    defaultValue: 'v3.football.api-sports.io',
  );

  static bool get hasKey => key.isNotEmpty;

  static bool get isRapidApi => host.contains('rapidapi.com');

  static Uri uri(String path, [Map<String, String>? query]) => Uri.https(
        host,
        isRapidApi ? '/v3$path' : path,
        query,
      );

  static Map<String, String> get headers => isRapidApi
      ? {'x-rapidapi-key': key, 'x-rapidapi-host': host}
      : {'x-apisports-key': key};

  /// The season the free api-sports tier is pinned to. Paid plans can move
  /// this forward with --dart-define=API_FOOTBALL_SEASON=2025
  static const int season = int.fromEnvironment(
    'API_FOOTBALL_SEASON',
    defaultValue: 2023,
  );

  static const Duration timeout = Duration(seconds: 20);

  /// How often the Live tab re-polls while it is on screen. The free tier is
  /// rate limited, so this stays deliberately conservative.
  static const Duration livePollInterval = Duration(seconds: 30);
}
