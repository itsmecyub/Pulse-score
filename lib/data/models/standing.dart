import 'json.dart';
import 'team.dart';

class Standing {
  const Standing({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    this.form,
    this.groupName,
  });

  final int rank;
  final Team team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  /// Last five results as a "WWDLW" string.
  final String? form;
  final String? groupName;

  int get goalDifference => goalsFor - goalsAgainst;

  String get goalDifferenceLabel =>
      goalDifference > 0 ? '+$goalDifference' : '$goalDifference';

  factory Standing.fromJson(Map<String, dynamic> json) {
    final all = asMap(json['all']);
    final goals = asMap(all['goals']);
    return Standing(
      rank: asInt(json['rank']),
      team: Team.fromJson(asMap(json['team'])),
      played: asInt(all['played']),
      won: asInt(all['win']),
      drawn: asInt(all['draw']),
      lost: asInt(all['lose']),
      goalsFor: asInt(goals['for']),
      goalsAgainst: asInt(goals['against']),
      points: asInt(json['points']),
      form: asStringOrNull(json['form']),
      groupName: asStringOrNull(json['group']),
    );
  }
}
