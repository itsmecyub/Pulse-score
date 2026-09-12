import '../utils/log.dart';

class Settings {
  final List<String> banners;
  final List<String> inters;
  final List<String> nativees;
  final List<String> rewards;
  final String openads;

  Settings.fromJson(Map<String, dynamic> json)
    : banners = _parseList(json['banners']),
      inters = _parseList(json['inters']),
      nativees = _parseList(json['nativees']),
      openads = json['openads']?.toString() ?? "",
      rewards = _parseList(json['rewards']) {
    Log.log("openads: ------------------");
    Log.log(openads);
    Log.log("inters: ------------------");
    Log.log(inters);
    Log.log("banners: ------------------");
    Log.log(banners);
    Log.log("nativees: ------------------");
    Log.log(nativees);
    Log.log("rewards: ------------------");
    Log.log(rewards);
  }
}

List<String> _parseList(dynamic input) {
  if (input == null) return [];
  if (input is List) {
    return input
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final value = input.toString();
  if (value.isEmpty) return [];
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
