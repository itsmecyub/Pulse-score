/// Date and duration formatting.
///
/// Deliberately hand-rolled rather than `intl`: every one of these strings is
/// rendered in the mono "terminal" style with fixed uppercase abbreviations
/// ("SUN 6 SEP · 14:00"), which is a typographic choice, not a locale-aware
/// one. Using DateFormat here would drag in per-locale data loading to produce
/// output we would then have to force back into this shape.
library;

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

String two(int n) => n.toString().padLeft(2, '0');

/// "14:00"
String hhmm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "SUN 6 SEP"
String dayMonth(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "SUN 6 SEP · 14:00"
String kickoffStamp(DateTime d) => '${dayMonth(d)} · ${hhmm(d)}';

/// "IN 13H 14M" / "IN 45M" / "IN 3D"
String countdown(Duration d) {
  if (d.isNegative) return 'STARTING';
  if (d.inDays >= 1) {
    final hours = d.inHours % 24;
    return hours > 0 ? 'IN ${d.inDays}D ${hours}H' : 'IN ${d.inDays}D';
  }
  if (d.inHours >= 1) return 'IN ${d.inHours}H ${d.inMinutes % 60}M';
  if (d.inMinutes >= 1) return 'IN ${d.inMinutes}M';
  return 'KICKING OFF';
}

/// Compact age of a past match, as the Schedule tab shows it: "105d", "6h".
String ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'now';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime d) => isSameDay(d, DateTime.now());

bool isTomorrow(DateTime d) =>
    isSameDay(d, DateTime.now().add(const Duration(days: 1)));

bool isYesterday(DateTime d) =>
    isSameDay(d, DateTime.now().subtract(const Duration(days: 1)));
