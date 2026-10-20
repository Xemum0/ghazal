import 'local_date.dart';

/// Kuwait has no daylight saving: a fixed +03:00 offset (ADR 0011).
const Duration kuwaitOffset = Duration(hours: 3);

/// Parses an ISO 8601 instant that carries an offset (`2026-11-12T16:00:00+03:00`) or `Z`. The result is a UTC [DateTime].
DateTime parseInstant(String s) {
  final t = DateTime.tryParse(s);
  if (t == null) throw FormatException('not an ISO 8601 instant: $s');
  return t.toUtc();
}

/// Writes an instant the way the API does: Kuwait wall clock with the `+03:00` offset and whole seconds.
String instantToJson(DateTime t) {
  final k = t.toUtc().add(kuwaitOffset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${k.year.toString().padLeft(4, '0')}-${two(k.month)}-${two(k.day)}T${two(k.hour)}:${two(k.minute)}:${two(k.second)}+03:00';
}

extension KuwaitInstant on DateTime {
  /// The same instant shifted so that `year`, `month`, `day`, `hour` and `minute` read as Kuwait wall-clock time (the result is flagged UTC, do not convert it again).
  DateTime get kuwaitWallClock => toUtc().add(kuwaitOffset);

  /// The Kuwait civil date of this instant.
  LocalDate get kuwaitDate {
    final k = kuwaitWallClock;
    return LocalDate(k.year, k.month, k.day);
  }

  /// The Kuwait local time of day of this instant.
  LocalTime get kuwaitTime {
    final k = kuwaitWallClock;
    return LocalTime(k.hour, k.minute);
  }
}
