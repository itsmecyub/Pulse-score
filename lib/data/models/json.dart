library;

/// Defensive coercion helpers.
///
/// API-Football is loose about types — ids arrive as ints or numeric strings,
/// goals are null before kickoff, elapsed can be absent. Rather than sprinkle
/// null checks through every model, funnel everything through these.

int asInt(Object? v, [int fallback = 0]) => asIntOrNull(v) ?? fallback;

int? asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

double? asDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim().replaceAll('%', ''));
  return null;
}

String asString(Object? v, [String fallback = '']) =>
    asStringOrNull(v) ?? fallback;

String? asStringOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true';
  return fallback;
}

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

List<Map<String, dynamic>> asMapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const <Map<String, dynamic>>[];
