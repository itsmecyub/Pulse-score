import '../models/fixture.dart';
import '../models/league.dart';
import '../models/match_event.dart';
import '../models/standing.dart';
import '../models/team.dart';

/// Offline demo content.
///
/// Used whenever no API key is configured, or when a live request fails and we
/// would otherwise show an empty screen. Everything is built relative to
/// `DateTime.now()` so the demo never looks stale — a match "78 minutes in"
/// stays 78 minutes in whenever you launch.
class SampleData {
  SampleData._();

  static const _crest = 'https://media.api-sports.io/football/teams';
  static const _leagueLogo = 'https://media.api-sports.io/football/leagues';

  static final _premierLeague = League(
    id: 39,
    name: 'Premier League',
    country: 'England',
    countryCode: 'EN',
    logo: '$_leagueLogo/39.png',
    round: 'Regular Season - 4',
  );

  static final _vLeague = League(
    id: 340,
    name: 'V.League 1',
    country: 'Vietnam',
    countryCode: 'VN',
    logo: '$_leagueLogo/340.png',
    round: 'Regular Season - 24',
  );

  static final _primeraB = League(
    id: 132,
    name: 'Primera B Metropolitana',
    country: 'Argentina',
    countryCode: 'AR',
    round: 'Regular Season - 34',
  );

  static final _ligaProfesional = League(
    id: 128,
    name: 'Liga Profesional Argentina',
    country: 'Argentina',
    countryCode: 'AR',
    round: 'Regular Season - 12',
  );

  static final _primeraA = League(
    id: 239,
    name: 'Primera A',
    country: 'Colombia',
    countryCode: 'CO',
    round: 'Regular Season - 9',
  );

  static Team _team(int id, String name, {bool crest = false}) =>
      Team(id: id, name: name, logo: crest ? '$_crest/$id.png' : null);

  static MatchStatus _live(int minute) =>
      MatchStatus(short: minute > 45 ? '2H' : '1H', long: 'Match In Play', elapsed: minute);

  static const _finished = MatchStatus(short: 'FT', long: 'Match Finished');
  static const _notStarted = MatchStatus(short: 'NS', long: 'Not Started');

  /// Matches currently in play, newest kickoff first.
  static List<Fixture> live() {
    final now = DateTime.now();
    return [
      Fixture(
        id: 900001,
        kickoff: now.subtract(const Duration(minutes: 78)),
        status: _live(78),
        league: _primeraB,
        home: _team(2380, 'Deportivo Merlo'),
        away: _team(2371, 'Defensores Unidos'),
        homeGoals: 0,
        awayGoals: 0,
        halftimeHome: 0,
        halftimeAway: 0,
      ),
      Fixture(
        id: 900002,
        kickoff: now.subtract(const Duration(minutes: 83)),
        status: _live(83),
        league: _ligaProfesional,
        home: _team(460, 'San Lorenzo', crest: true),
        away: _team(445, 'Talleres Cordoba', crest: true),
        homeGoals: 1,
        awayGoals: 0,
        halftimeHome: 1,
        halftimeAway: 0,
      ),
      Fixture(
        id: 900003,
        kickoff: now.subtract(const Duration(minutes: 84)),
        status: _live(84),
        league: _primeraA,
        home: _team(1148, 'Quindio'),
        away: _team(1146, 'Union Magdalena'),
        homeGoals: 0,
        awayGoals: 1,
        halftimeHome: 0,
        halftimeAway: 0,
      ),
      Fixture(
        id: 900004,
        kickoff: now.subtract(const Duration(minutes: 82)),
        status: _live(82),
        league: _primeraA,
        home: _team(1131, 'Deportivo Pasto'),
        away: _team(1137, 'Once Caldas'),
        homeGoals: 2,
        awayGoals: 2,
        halftimeHome: 1,
        halftimeAway: 1,
      ),
      Fixture(
        id: 900005,
        kickoff: now.subtract(const Duration(minutes: 61)),
        status: _live(61),
        league: _ligaProfesional,
        home: _team(451, 'Boca Juniors', crest: true),
        away: _team(435, 'River Plate', crest: true),
        homeGoals: 1,
        awayGoals: 1,
        halftimeHome: 0,
        halftimeAway: 1,
      ),
      Fixture(
        id: 900006,
        kickoff: now.subtract(const Duration(minutes: 34)),
        status: _live(34),
        league: _primeraB,
        home: _team(2360, 'Colegiales'),
        away: _team(2367, 'Argentino de Quilmes'),
        homeGoals: 0,
        awayGoals: 0,
      ),
    ];
  }

  /// The starred card at the top of the Live tab.
  static List<Fixture> featuredUpcoming() {
    final now = DateTime.now();
    final kickoff = now.add(const Duration(hours: 13, minutes: 14));
    return [
      Fixture(
        id: 900101,
        kickoff: kickoff,
        status: _notStarted,
        league: _premierLeague,
        home: _team(45, 'Everton', crest: true),
        away: _team(33, 'Manchester United', crest: true),
        venue: const Venue(name: 'Goodison Park', city: 'Liverpool'),
      ),
      Fixture(
        id: 900102,
        kickoff: now.add(const Duration(hours: 15, minutes: 40)),
        status: _notStarted,
        league: _premierLeague,
        home: _team(42, 'Arsenal', crest: true),
        away: _team(49, 'Chelsea', crest: true),
        venue: const Venue(name: 'Emirates Stadium', city: 'London'),
      ),
    ];
  }

  /// Completed V-League results, matching the Schedule tab.
  static List<Fixture> vLeagueResults() {
    final now = DateTime.now();
    Fixture done(int id, int daysAgo, String h, String a, int hg, int ag,
        int hid, int aid) {
      return Fixture(
        id: id,
        kickoff: now.subtract(Duration(days: daysAgo)),
        status: _finished,
        league: _vLeague,
        home: _team(hid, h),
        away: _team(aid, a),
        homeGoals: hg,
        awayGoals: ag,
      );
    }

    return [
      done(900201, 105, 'Thanh Hóa', 'Hoang Anh Gia Lai', 1, 1, 3266, 3255),
      done(900202, 105, 'Da Nang', 'Hai Phong', 2, 0, 3254, 3256),
      done(900203, 104, 'Binh Duong', 'Song Lam Nghe An', 0, 1, 3253, 3264),
      done(900204, 104, 'Hồng Lĩnh Hà Tĩnh', 'Công An Nhân Dân', 1, 1, 3258, 3268),
      done(900205, 104, 'Ha Noi', 'Nam Dinh', 2, 1, 3257, 3262),
      done(900206, 97, 'Hồng Lĩnh Hà Tĩnh', 'Da Nang', 0, 0, 3258, 3254),
      done(900207, 97, 'Nam Dinh', 'Binh Duong', 3, 0, 3262, 3253),
      done(900208, 96, 'Hai Phong', 'Thanh Hóa', 1, 2, 3256, 3266),
      done(900209, 90, 'Hoang Anh Gia Lai', 'Ha Noi', 0, 2, 3255, 3257),
      done(900210, 89, 'Song Lam Nghe An', 'Hồng Lĩnh Hà Tĩnh', 1, 0, 3264, 3258),
    ];
  }

  /// Everything the demo knows about, for search and the Schedule tab.
  static List<Fixture> all() => [
        ...featuredUpcoming(),
        ...live(),
        ...vLeagueResults(),
      ];

  static List<Fixture> forLeague(int leagueId) {
    final matches = all().where((f) => f.league.id == leagueId).toList();
    if (matches.isNotEmpty) return matches;
    // A league we have no demo rows for still gets a plausible, empty-but-valid
    // response rather than an error state.
    return const [];
  }

  static List<MatchEvent> eventsFor(int fixtureId) {
    switch (fixtureId) {
      case 900002:
        return const [
          MatchEvent(
            minute: 28,
            kind: EventKind.goal,
            teamId: 460,
            teamName: 'San Lorenzo',
            player: 'M. Cuello',
            assist: 'A. Vombergar',
          ),
        ];
      case 900005:
        return const [
          MatchEvent(
            minute: 12,
            kind: EventKind.goal,
            teamId: 435,
            teamName: 'River Plate',
            player: 'F. Colidio',
          ),
          MatchEvent(
            minute: 44,
            kind: EventKind.yellow,
            teamId: 451,
            teamName: 'Boca Juniors',
            player: 'M. Rojo',
            detail: 'Yellow Card',
          ),
          MatchEvent(
            minute: 58,
            kind: EventKind.penalty,
            teamId: 451,
            teamName: 'Boca Juniors',
            player: 'E. Cavani',
            detail: 'Penalty',
          ),
        ];
      case 900003:
        return const [
          MatchEvent(
            minute: 71,
            kind: EventKind.goal,
            teamId: 1146,
            teamName: 'Union Magdalena',
            player: 'R. Otero',
          ),
        ];
      case 900004:
        return const [
          MatchEvent(minute: 9, kind: EventKind.goal, teamId: 1131, teamName: 'Deportivo Pasto', player: 'J. Ramos'),
          MatchEvent(minute: 23, kind: EventKind.goal, teamId: 1137, teamName: 'Once Caldas', player: 'D. Torres'),
          MatchEvent(minute: 55, kind: EventKind.goal, teamId: 1131, teamName: 'Deportivo Pasto', player: 'C. Sierra'),
          MatchEvent(minute: 77, kind: EventKind.goal, teamId: 1137, teamName: 'Once Caldas', player: 'M. Rodallega'),
        ];
      default:
        return const [];
    }
  }

  static List<Standing> standingsFor(int leagueId) {
    if (leagueId != 340) return const [];
    const rows = [
      ['Nam Dinh', 3262, 24, 15, 5, 4, 48, 26, 50],
      ['Ha Noi', 3257, 24, 13, 6, 5, 44, 28, 45],
      ['Thanh Hóa', 3266, 24, 12, 6, 6, 38, 27, 42],
      ['Binh Duong', 3253, 24, 11, 7, 6, 35, 29, 40],
      ['Hai Phong', 3256, 24, 10, 7, 7, 31, 28, 37],
      ['Da Nang', 3254, 24, 9, 8, 7, 30, 27, 35],
      ['Song Lam Nghe An', 3264, 24, 8, 7, 9, 26, 30, 31],
      ['Hồng Lĩnh Hà Tĩnh', 3258, 24, 7, 8, 9, 25, 31, 29],
      ['Công An Nhân Dân', 3268, 24, 6, 6, 12, 22, 36, 24],
      ['Hoang Anh Gia Lai', 3255, 24, 4, 6, 14, 19, 41, 18],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        Standing(
          rank: i + 1,
          team: Team(id: rows[i][1] as int, name: rows[i][0] as String),
          played: rows[i][2] as int,
          won: rows[i][3] as int,
          drawn: rows[i][4] as int,
          lost: rows[i][5] as int,
          goalsFor: rows[i][6] as int,
          goalsAgainst: rows[i][7] as int,
          points: rows[i][8] as int,
        ),
    ];
  }
}
