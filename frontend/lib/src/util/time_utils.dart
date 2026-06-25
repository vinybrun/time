/// Helpers for the minutes-from-local-midnight model.
library;

String dayString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

DateTime parseDay(String day) {
  final p = day.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String today() => dayString(DateTime.now());

/// "HH:MM" for a minutes-from-midnight value (1440 -> "24:00").
String formatMinutes(int min) {
  final m = min.clamp(0, 1440);
  final h = m ~/ 60;
  final mm = m % 60;
  return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

/// Human "Xh Ym" with no leading zero noise.
String formatDuration(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
