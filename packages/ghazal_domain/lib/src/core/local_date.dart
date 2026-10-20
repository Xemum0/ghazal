/// A Kuwait civil date (`YYYY-MM-DD`). It never passes through a time zone (data-model.md section 1): arithmetic is on the calendar only.
final class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.parse(String s) {
    final m = _pattern.firstMatch(s);
    if (m == null) throw FormatException('not a civil date (YYYY-MM-DD): $s');
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
    final check = DateTime.utc(y, mo, d);
    if (check.month != mo || check.day != d) throw FormatException('not a calendar date: $s');
    return LocalDate(y, mo, d);
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// 0 = Sunday ... 6 = Saturday (the contract's `Weekday`, ADR 0011).
  int get weekdayIndex => DateTime.utc(year, month, day).weekday % 7;

  /// A UTC midnight [DateTime] with the same fields, for calendar arithmetic only.
  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  LocalDate addDays(int days) {
    final t = DateTime.utc(year, month, day + days);
    return LocalDate(t.year, t.month, t.day);
  }

  /// Whole calendar days from this date to [other] (negative when [other] is earlier).
  int daysUntil(LocalDate other) => other.toUtcDateTime().difference(toUtcDateTime()).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// `YYYY-MM`.
  String get monthKey => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  String toJson() => toString();

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) => other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// A venue-local time of day (`HH:mm`, 24 hour). A session that ends before it starts crosses midnight.
final class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute);

  factory LocalTime.parse(String s) {
    final m = _pattern.firstMatch(s);
    if (m == null) throw FormatException('not a time (HH:mm): $s');
    final h = int.parse(m.group(1)!), mi = int.parse(m.group(2)!);
    if (h > 23 || mi > 59) throw FormatException('not a time: $s');
    return LocalTime(h, mi);
  }

  static final RegExp _pattern = RegExp(r'^(\d{2}):(\d{2})$');

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String toJson() => toString();

  @override
  int compareTo(LocalTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) => other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
