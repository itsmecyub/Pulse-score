/// Data source configuration.
///
/// Two backends, in priority order:
///
///  1. **Koora** — the default. A hosted proxy over API-Football that holds the
///     credential server-side, so the app ships working with no key. It serves
///     fixed snapshots (`/live`, `/today`) and ignores query parameters.
///  2. **API-Football direct** — used instead whenever a key is supplied:
///
///       flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
///
///     Worth doing for anything the snapshots can't answer: per-league tables,
///     historical fixtures, arbitrary dates.
///
/// If both are unreachable the app falls back to bundled demo data, so no
/// screen ever renders a dead end.
class ApiConfig {
  ApiConfig._();

  // --- Koora backend ---

  /// Override with --dart-define=KOORA_BASE_URL=https://your-host
  static const String kooraBaseUrl = String.fromEnvironment(
    'KOORA_BASE_URL',
    defaultValue: 'https://api-koora-production.up.railway.app',
  );

  /// Serve bundled sample data when the backend cannot be reached.
  ///
  /// Off by default: showing invented fixtures that look real is worse than an
  /// honest empty screen in a scores app. Turn it on for offline development
  /// with --dart-define=USE_DEMO_DATA=true
  static const bool useDemoData =
      bool.fromEnvironment('USE_DEMO_DATA', defaultValue: false);

  static Uri kooraUri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('$kooraBaseUrl/api/football$path');
    return query == null || query.isEmpty
        ? base
        : base.replace(queryParameters: query);
  }

  // --- Legal pages ---

  /// Where the privacy policy and terms are published. Override with
  /// --dart-define=LEGAL_BASE_URL=https://your-domain
  static const String legalBaseUrl = String.fromEnvironment(
    'LEGAL_BASE_URL',
    defaultValue: 'https://pulsescore-legal-yobex12-4808.vercel.app',
  );

  /// A legal document in the reader's own language.
  ///
  /// The language rides in the query string rather than the path so the link
  /// still resolves if a language has not been published yet — the page falls
  /// back to English instead of 404ing.
  static Uri legalUri(String doc, String languageCode) =>
      Uri.parse('$legalBaseUrl/$doc.html')
          .replace(queryParameters: {'lang': languageCode});

  // --- API-Football direct ---

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
