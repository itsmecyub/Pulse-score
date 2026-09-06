import 'json.dart';

class Team {
  const Team({
    required this.id,
    required this.name,
    this.logo,
    this.winner,
  });

  final int id;
  final String name;
  final String? logo;

  /// Null while a match is still in play.
  final bool? winner;

  /// Two- or three-letter badge used in compact rows and widgets.
  String get initials {
    final words = name
        .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '??';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: asInt(json['id']),
        name: asString(json['name']),
        logo: asStringOrNull(json['logo']),
        winner: json['winner'] is bool ? json['winner'] as bool : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'winner': winner,
      };
}
