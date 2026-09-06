import 'league.dart';

/// The competitions PulseScore surfaces in Explore and the Schedule tab.
///
/// The API can enumerate thousands of leagues; this hand-picked catalog is what
/// the product actually promotes, split into the two Explore sections. Ids are
/// API-Football league ids.
class LeagueCatalog {
  LeagueCatalog._();

  static const top = <CatalogLeague>[
    CatalogLeague(id: 340, name: 'V-League', country: 'Vietnam', code: 'VN', flag: '🇻🇳'),
    CatalogLeague(id: 39, name: 'Premier League', country: 'England', code: 'EN', flag: '🇬🇧', premium: true),
    CatalogLeague(id: 140, name: 'La Liga', country: 'Spain', code: 'ES', flag: '🇪🇸', premium: true),
    CatalogLeague(id: 78, name: 'Bundesliga', country: 'Germany', code: 'DE', flag: '🇩🇪', premium: true),
    CatalogLeague(id: 135, name: 'Serie A', country: 'Italy', code: 'IT', flag: '🇮🇹', premium: true),
    CatalogLeague(id: 61, name: 'Ligue 1', country: 'France', code: 'FR', flag: '🇫🇷', premium: true),
  ];

  static const more = <CatalogLeague>[
    CatalogLeague(id: 40, name: 'Championship', country: 'England', code: 'EN', flag: '🇬🇧'),
    CatalogLeague(id: 88, name: 'Eredivisie', country: 'Netherlands', code: 'NL', flag: '🇳🇱'),
    CatalogLeague(id: 94, name: 'Primeira Liga', country: 'Portugal', code: 'PT', flag: '🇵🇹'),
    CatalogLeague(id: 203, name: 'Süper Lig', country: 'Turkey', code: 'TR', flag: '🇹🇷'),
    CatalogLeague(id: 179, name: 'Premiership', country: 'Scotland', code: 'SC', flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿'),
    CatalogLeague(id: 144, name: 'Pro League', country: 'Belgium', code: 'BE', flag: '🇧🇪'),
    CatalogLeague(id: 253, name: 'MLS', country: 'USA', code: 'US', flag: '🇺🇸'),
    CatalogLeague(id: 71, name: 'Brasileirão', country: 'Brazil', code: 'BR', flag: '🇧🇷'),
    CatalogLeague(id: 128, name: 'Liga Profesional', country: 'Argentina', code: 'AR', flag: '🇦🇷'),
    CatalogLeague(id: 98, name: 'J1 League', country: 'Japan', code: 'JP', flag: '🇯🇵'),
    CatalogLeague(id: 292, name: 'K League 1', country: 'South Korea', code: 'KR', flag: '🇰🇷'),
    CatalogLeague(id: 307, name: 'Saudi Pro League', country: 'Saudi Arabia', code: 'SA', flag: '🇸🇦'),
  ];

  static List<CatalogLeague> get all => [...top, ...more];

  static CatalogLeague? byId(int id) {
    for (final l in all) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// The league selected by default on first launch.
  static const CatalogLeague defaultLeague = CatalogLeague(
    id: 340,
    name: 'V-League',
    country: 'Vietnam',
    code: 'VN',
    flag: '🇻🇳',
  );
}

class CatalogLeague {
  const CatalogLeague({
    required this.id,
    required this.name,
    required this.country,
    required this.code,
    required this.flag,
    this.premium = false,
  });

  final int id;
  final String name;
  final String country;
  final String code;
  final String flag;

  /// Shown with a padlock until the user upgrades.
  final bool premium;

  League toLeague() => League(
        id: id,
        name: name,
        country: country,
        countryCode: code,
      );
}
