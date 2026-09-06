import 'json.dart';
import 'league.dart';
import 'team.dart';

/// The lifecycle bucket a match falls into. The API ships ~18 status codes;
/// the UI only ever needs to know which of these four groups a match is in.
enum MatchPhase { upcoming, live, finished, postponed }

class MatchStatus {
  const MatchStatus({
    required this.short,
    required this.long,
    this.elapsed,
    this.extra,
  });

  final String short;
  final String long;

  /// Minutes played. Null outside of live play.
  final int? elapsed;

  /// Added time on top of `elapsed`, when the API reports it.
  final int? extra;

  static const _live = {'1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE', 'INT', 'SUSP'};
  static const _finished = {'FT', 'AET', 'PEN', 'AWD', 'WO'};
  static const _postponed = {'PST', 'CANC', 'ABD', 'TBD'};

  MatchPhase get phase {
    if (_live.contains(short)) return MatchPhase.live;
    if (_finished.contains(short)) return MatchPhase.finished;
    if (_postponed.contains(short)) return MatchPhase.postponed;
    return MatchPhase.upcoming;
  }

  bool get isLive => phase == MatchPhase.live;
  bool get isFinished => phase == MatchPhase.finished;
  bool get isUpcoming => phase == MatchPhase.upcoming;
  bool get isHalfTime => short == 'HT';

  /// What sits in the leading slot of a match row: "78'", "HT", "FT", "20:45".
  String get badge {
    if (short == 'HT') return 'HT';
    if (isLive && elapsed != null) {
      return extra != null && extra! > 0 ? "$elapsed+$extra'" : "$elapsed'";
    }
    if (isFinished) return short == 'FT' ? 'FT' : short;
    return short;
  }

  factory MatchStatus.fromJson(Map<String, dynamic> json) => MatchStatus(
        short: asString(json['short'], 'NS'),
        long: asString(json['long']),
        elapsed: asIntOrNull(json['elapsed']),
        extra: asIntOrNull(json['extra']),
      );

  Map<String, dynamic> toJson() => {
        'short': short,
        'long': long,
        'elapsed': elapsed,
        'extra': extra,
      };
}

class Venue {
  const Venue({this.name, this.city});
  final String? name;
  final String? city;

  String? get label {
    if (name == null && city == null) return null;
    if (city == null) return name;
    if (name == null) return city;
    return '$name, $city';
  }

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        name: asStringOrNull(json['name']),
        city: asStringOrNull(json['city']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'city': city};
}

class Fixture {
  const Fixture({
    required this.id,
    required this.kickoff,
    required this.status,
    required this.league,
    required this.home,
    required this.away,
    this.homeGoals,
    this.awayGoals,
    this.halftimeHome,
    this.halftimeAway,
    this.venue,
    this.referee,
  });

  final int id;
  final DateTime kickoff;
  final MatchStatus status;
  final League league;
  final Team home;
  final Team away;
  final int? homeGoals;
  final int? awayGoals;
  final int? halftimeHome;
  final int? halftimeAway;
  final Venue? venue;
  final String? referee;

  bool get isLive => status.isLive;
  bool get isFinished => status.isFinished;
  bool get isUpcoming => status.isUpcoming;
  bool get hasScore => homeGoals != null && awayGoals != null;

  String get scoreLine => hasScore ? '$homeGoals - $awayGoals' : 'vs';

  bool involvesTeam(int teamId) => home.id == teamId || away.id == teamId;

  Duration get timeUntilKickoff => kickoff.difference(DateTime.now());

  factory Fixture.fromJson(Map<String, dynamic> json) {
    final fixture = asMap(json['fixture']);
    final teams = asMap(json['teams']);
    final goals = asMap(json['goals']);
    final score = asMap(json['score']);
    final halftime = asMap(score['halftime']);

    final ts = asIntOrNull(fixture['timestamp']);
    final kickoff = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal()
        : DateTime.tryParse(asString(fixture['date']))?.toLocal() ??
            DateTime.now();

    return Fixture(
      id: asInt(fixture['id']),
      kickoff: kickoff,
      status: MatchStatus.fromJson(asMap(fixture['status'])),
      league: League.fromJson(asMap(json['league'])),
      home: Team.fromJson(asMap(teams['home'])),
      away: Team.fromJson(asMap(teams['away'])),
      homeGoals: asIntOrNull(goals['home']),
      awayGoals: asIntOrNull(goals['away']),
      halftimeHome: asIntOrNull(halftime['home']),
      halftimeAway: asIntOrNull(halftime['away']),
      venue: Venue.fromJson(asMap(fixture['venue'])),
      referee: asStringOrNull(fixture['referee']),
    );
  }

  Map<String, dynamic> toJson() => {
        'fixture': {
          'id': id,
          'timestamp': kickoff.toUtc().millisecondsSinceEpoch ~/ 1000,
          'date': kickoff.toUtc().toIso8601String(),
          'status': status.toJson(),
          'venue': venue?.toJson(),
          'referee': referee,
        },
        'league': league.toJson(),
        'teams': {'home': home.toJson(), 'away': away.toJson()},
        'goals': {'home': homeGoals, 'away': awayGoals},
        'score': {
          'halftime': {'home': halftimeHome, 'away': halftimeAway}
        },
      };
}
