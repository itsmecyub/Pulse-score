import 'league.dart';

/// The competitions PulseScore surfaces.
///
/// Deliberately short. The backend's `today` snapshot spans 300+ competitions,
/// but only a handful are worth promoting — and these are exactly the ones the
/// backend can also serve a real league table for (`/standings?leagueId=`),
/// which was the deciding factor: a league in this list always has both
/// fixtures and standings behind it.
///
/// Ids are API-Football league ids.
class LeagueCatalog {
  LeagueCatalog._();

  static const top = <CatalogLeague>[
    CatalogLeague(id: 39, name: 'Premier League', country: 'England', code: 'EN', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
    CatalogLeague(id: 140, name: 'La Liga', country: 'Spain', code: 'ES', flag: '🇪🇸'),
    CatalogLeague(id: 135, name: 'Serie A', country: 'Italy', code: 'IT', flag: '🇮🇹'),
    CatalogLeague(id: 78, name: 'Bundesliga', country: 'Germany', code: 'DE', flag: '🇩🇪'),
    CatalogLeague(id: 61, name: 'Ligue 1', country: 'France', code: 'FR', flag: '🇫🇷'),
    CatalogLeague(id: 2, name: 'Champions League', country: 'Europe', code: 'EU', flag: '🇪🇺'),
  ];

  /// Nothing secondary is promoted at the moment; Explore hides the section
  /// while this is empty.
  static const more = <CatalogLeague>[];

  static List<CatalogLeague> get all => [...top, ...more];

  static CatalogLeague? byId(int id) {
    for (final l in all) {
      if (l.id == id) return l;
    }
    return null;
  }

  static bool contains(int id) => byId(id) != null;

  /// The league selected by default on first launch.
  static const CatalogLeague defaultLeague = CatalogLeague(
    id: 39,
    name: 'Premier League',
    country: 'England',
    code: 'EN',
    flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
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

  /// Gate for a paid competition. Nothing in the catalog uses it today — every
  /// league ships unlocked — but the check stays wired so a league can be put
  /// behind Premium without touching the screens.
  final bool premium;

  League toLeague() => League(
        id: id,
        name: name,
        country: country,
        countryCode: code,
      );
}
