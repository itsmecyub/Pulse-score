import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_score/data/models/fixture.dart';
import 'package:pulse_score/data/models/match_event.dart';
import 'package:pulse_score/data/models/standing.dart';
import 'package:pulse_score/data/models/team.dart';

/// A trimmed but structurally faithful /fixtures row.
const _fixtureJson = '''
{
  "fixture": {
    "id": 1035037,
    "referee": "M. Oliver",
    "timestamp": 1693999800,
    "date": "2023-09-06T14:00:00+00:00",
    "venue": {"id": 547, "name": "Goodison Park", "city": "Liverpool"},
    "status": {"long": "Second Half", "short": "2H", "elapsed": 78, "extra": null}
  },
  "league": {
    "id": 39, "name": "Premier League", "country": "England",
    "logo": "https://media.api-sports.io/football/leagues/39.png",
    "season": 2023, "round": "Regular Season - 4"
  },
  "teams": {
    "home": {"id": 45, "name": "Everton", "logo": "e.png", "winner": null},
    "away": {"id": 33, "name": "Manchester United", "logo": "m.png", "winner": null}
  },
  "goals": {"home": 1, "away": 2},
  "score": {"halftime": {"home": 0, "away": 1}}
}
''';

void main() {
  group('Fixture.fromJson', () {
    final fixture = Fixture.fromJson(
      jsonDecode(_fixtureJson) as Map<String, dynamic>,
    );

    test('reads ids, teams and goals', () {
      expect(fixture.id, 1035037);
      expect(fixture.home.name, 'Everton');
      expect(fixture.away.name, 'Manchester United');
      expect(fixture.homeGoals, 1);
      expect(fixture.awayGoals, 2);
      expect(fixture.halftimeAway, 1);
    });

    test('derives the country code from the league country', () {
      expect(fixture.league.countryCode, 'EN');
      expect(fixture.league.roundLabel, 'regular season — 4');
    });

    test('prefers the unix timestamp over the date string', () {
      // The two fields disagree on purpose: `timestamp` says 11:30 UTC, the
      // `date` string says 14:00. The timestamp is the one that is always
      // unambiguous about the zone, so it must win.
      expect(fixture.kickoff.toUtc(), DateTime.utc(2023, 9, 6, 11, 30));
      expect(fixture.kickoff.isUtc, isFalse, reason: 'stored as local time');
    });

    test('falls back to the date string when no timestamp is sent', () {
      final noTimestamp = Fixture.fromJson(const {
        'fixture': {
          'id': 1,
          'date': '2023-09-06T14:00:00+00:00',
          'status': {'short': 'NS', 'long': 'Not Started'}
        }
      });
      expect(noTimestamp.kickoff.toUtc(), DateTime.utc(2023, 9, 6, 14, 0));
    });

    test('classifies an in-play status', () {
      expect(fixture.isLive, isTrue);
      expect(fixture.isFinished, isFalse);
      expect(fixture.status.badge, "78'");
    });

    test('reads the venue', () {
      expect(fixture.venue?.label, 'Goodison Park, Liverpool');
      expect(fixture.referee, 'M. Oliver');
    });
  });

  group('MatchStatus', () {
    test('maps every phase bucket', () {
      MatchPhase phase(String short) =>
          MatchStatus(short: short, long: '').phase;

      expect(phase('NS'), MatchPhase.upcoming);
      expect(phase('1H'), MatchPhase.live);
      expect(phase('HT'), MatchPhase.live);
      expect(phase('FT'), MatchPhase.finished);
      expect(phase('AET'), MatchPhase.finished);
      expect(phase('PST'), MatchPhase.postponed);
    });

    test('shows added time when present', () {
      const status =
          MatchStatus(short: '2H', long: '', elapsed: 90, extra: 4);
      expect(status.badge, "90+4'");
    });

    test('falls back to NS when the API omits the status', () {
      expect(MatchStatus.fromJson(const {}).short, 'NS');
    });
  });

  group('defensive parsing', () {
    test('survives nulls and missing branches', () {
      final fixture = Fixture.fromJson(const {});
      expect(fixture.id, 0);
      expect(fixture.homeGoals, isNull);
      expect(fixture.hasScore, isFalse);
      expect(fixture.scoreLine, 'vs');
    });

    test('coerces numeric strings, as the API sometimes sends them', () {
      final team = Team.fromJson(const {'id': '45', 'name': 'Everton'});
      expect(team.id, 45);
    });
  });

  group('Team.initials', () {
    test('takes one letter from each of the first two words', () {
      expect(const Team(id: 1, name: 'Manchester United').initials, 'MU');
      expect(const Team(id: 2, name: 'Everton').initials, 'EV');
    });

    test('handles diacritics and punctuation', () {
      expect(const Team(id: 3, name: 'Hồng Lĩnh Hà Tĩnh').initials, 'HL');
      expect(const Team(id: 4, name: 'Boca Jrs.').initials, 'BJ');
    });
  });

  group('Standing.fromJson', () {
    test('flattens the nested all/goals block', () {
      final standing = Standing.fromJson(const {
        'rank': 1,
        'team': {'id': 3262, 'name': 'Nam Dinh'},
        'points': 50,
        'form': 'WWDLW',
        'all': {
          'played': 24,
          'win': 15,
          'draw': 5,
          'lose': 4,
          'goals': {'for': 48, 'against': 26}
        }
      });

      expect(standing.rank, 1);
      expect(standing.played, 24);
      expect(standing.goalDifference, 22);
      expect(standing.goalDifferenceLabel, '+22');
    });
  });

  group('MatchEvent.fromJson', () {
    MatchEvent event(String type, String detail) => MatchEvent.fromJson({
          'time': {'elapsed': 58},
          'team': {'id': 451, 'name': 'Boca Juniors'},
          'player': {'name': 'E. Cavani'},
          'type': type,
          'detail': detail,
        });

    test('separates goal varieties', () {
      expect(event('Goal', 'Normal Goal').kind, EventKind.goal);
      expect(event('Goal', 'Own Goal').kind, EventKind.ownGoal);
      expect(event('Goal', 'Penalty').kind, EventKind.penalty);
      expect(event('Goal', 'Missed Penalty').kind, EventKind.penaltyMissed);
    });

    test('separates card colours', () {
      expect(event('Card', 'Yellow Card').kind, EventKind.yellow);
      expect(event('Card', 'Red Card').kind, EventKind.red);
    });

    test('treats own goals as goals for scoreline purposes', () {
      expect(event('Goal', 'Own Goal').isGoal, isTrue);
      expect(event('Card', 'Red Card').isGoal, isFalse);
    });
  });
}
