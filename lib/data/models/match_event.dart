import 'json.dart';

enum EventKind { goal, ownGoal, penalty, penaltyMissed, yellow, red, subst, var_, other }

class MatchEvent {
  const MatchEvent({
    required this.minute,
    required this.kind,
    required this.teamId,
    required this.teamName,
    this.player,
    this.assist,
    this.detail,
    this.extraMinute,
  });

  final int minute;
  final int? extraMinute;
  final EventKind kind;
  final int teamId;
  final String teamName;
  final String? player;
  final String? assist;
  final String? detail;

  String get minuteLabel =>
      extraMinute != null && extraMinute! > 0 ? "$minute+$extraMinute'" : "$minute'";

  bool get isGoal =>
      kind == EventKind.goal || kind == EventKind.ownGoal || kind == EventKind.penalty;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    final time = asMap(json['time']);
    final team = asMap(json['team']);
    final player = asMap(json['player']);
    final assist = asMap(json['assist']);
    final type = asString(json['type']).toLowerCase();
    final detail = asString(json['detail']).toLowerCase();

    return MatchEvent(
      minute: asInt(time['elapsed']),
      extraMinute: asIntOrNull(time['extra']),
      kind: _kindOf(type, detail),
      teamId: asInt(team['id']),
      teamName: asString(team['name']),
      player: asStringOrNull(player['name']),
      assist: asStringOrNull(assist['name']),
      detail: asStringOrNull(json['detail']),
    );
  }

  static EventKind _kindOf(String type, String detail) {
    switch (type) {
      case 'goal':
        if (detail.contains('own')) return EventKind.ownGoal;
        if (detail.contains('missed')) return EventKind.penaltyMissed;
        if (detail.contains('penalty')) return EventKind.penalty;
        return EventKind.goal;
      case 'card':
        return detail.contains('red') ? EventKind.red : EventKind.yellow;
      case 'subst':
        return EventKind.subst;
      case 'var':
        return EventKind.var_;
      default:
        return EventKind.other;
    }
  }
}
