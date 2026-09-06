import 'json.dart';

class League {
  const League({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    this.logo,
    this.flag,
    this.season,
    this.round,
  });

  final int id;
  final String name;
  final String country;

  /// Two-letter code shown next to the league name ("VN", "EN", "ES").
  final String countryCode;
  final String? logo;
  final String? flag;
  final int? season;

  /// "Regular Season - 34" as returned by the API.
  final String? round;

  /// The trailing "— 34" the UI shows after the round name.
  String? get roundLabel {
    final r = round;
    if (r == null || r.isEmpty) return null;
    final parts = r.split(' - ');
    if (parts.length < 2) return r.toLowerCase();
    return '${parts.first.toLowerCase()} — ${parts.last}';
  }

  factory League.fromJson(Map<String, dynamic> json) {
    final country = asString(json['country']);
    return League(
      id: asInt(json['id']),
      name: asString(json['name']),
      country: country,
      countryCode: asString(json['code']).isNotEmpty
          ? asString(json['code']).toUpperCase()
          : _codeForCountry(country),
      logo: asStringOrNull(json['logo']),
      flag: asStringOrNull(json['flag']),
      season: asIntOrNull(json['season']),
      round: asStringOrNull(json['round']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'code': countryCode,
        'logo': logo,
        'flag': flag,
        'season': season,
        'round': round,
      };

  /// The API returns a country name on the fixture payload but a code only on
  /// /leagues, so fall back to a lookup for the competitions we surface.
  static String _codeForCountry(String country) =>
      _countryCodes[country.toLowerCase()] ?? '';

  static const _countryCodes = <String, String>{
    'vietnam': 'VN',
    'england': 'EN',
    'spain': 'ES',
    'germany': 'DE',
    'italy': 'IT',
    'france': 'FR',
    'netherlands': 'NL',
    'portugal': 'PT',
    'turkey': 'TR',
    'scotland': 'SC',
    'belgium': 'BE',
    'usa': 'US',
    'brazil': 'BR',
    'argentina': 'AR',
    'japan': 'JP',
    'south-korea': 'KR',
    'south korea': 'KR',
    'saudi-arabia': 'SA',
    'saudi arabia': 'SA',
    'world': 'WW',
  };
}
