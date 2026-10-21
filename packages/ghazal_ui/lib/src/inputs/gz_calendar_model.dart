// Pure date arithmetic on `YYYY-MM-DD` keys (the Kuwait business day, ADR 0002 D2). No DateTime in the device zone: every function
// works on UTC midnight of the civil date, which is exact because the keys carry no time or zone. Dart twin of calendarModel.ts.

/// A year and month (month 1-12).
class GzYm {
  const GzYm(this.year, this.month);

  final int year;
  final int month;

  @override
  bool operator ==(Object other) => other is GzYm && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// A civil date key (`2027-01-14`) split into numbers.
({int year, int month, int day}) gzParseIso(String iso) {
  final p = iso.split('-').map((s) => int.tryParse(s) ?? 0).toList();
  return (year: p.isNotEmpty ? p[0] : 1970, month: p.length > 1 ? p[1] : 1, day: p.length > 2 ? p[2] : 1);
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String gzToIso(int year, int month, int day) => '${year.toString().padLeft(4, '0')}-${_pad2(month)}-${_pad2(day)}';

String gzAddDaysIso(String iso, int days) {
  final p = gzParseIso(iso);
  final d = DateTime.utc(p.year, p.month, p.day + days);
  return gzToIso(d.year, d.month, d.day);
}

GzYm gzMonthOfIso(String iso) {
  final p = gzParseIso(iso);
  return GzYm(p.year, p.month);
}

GzYm gzAddMonths(GzYm ym, int n) {
  final idx = ym.year * 12 + (ym.month - 1) + n;
  return GzYm((idx / 12).floor(), idx % 12 + 1);
}

int gzCmpMonth(GzYm a, GzYm b) => a.year * 12 + a.month - (b.year * 12 + b.month);

/// Weekday 0 = Sunday of a key.
int gzWeekdayOfIso(String iso) {
  final p = gzParseIso(iso);
  return DateTime.utc(p.year, p.month, p.day).weekday % 7;
}

/// Every key from [a] to [b] inclusive (a <= b).
List<String> gzEachDay(String a, String b) {
  final out = <String>[];
  for (var cur = a; cur.compareTo(b) <= 0 && out.length < 400; cur = gzAddDaysIso(cur, 1)) {
    out.add(cur);
  }
  return out;
}

/// Availability states (ADR 0002 D8, ADR 0004). `peak` is an available day inside a peak band: it is accepted as a status for
/// convenience and normalised to `available` plus the band tint. Held (approved for another couple, requests still allowed) is
/// selectable; booked, blocked and closed (past, inside the lead time, outside the season) are not.
enum GzDayStatus { available, held, booked, blocked, closed, peak }

/// What the venue publishes about one day.
class GzCalendarDayInfo {
  const GzCalendarDayInfo({this.status, this.price, this.peak});

  final GzDayStatus? status;

  /// The day's price in integer fils (Prices view; ADR 0010, ADR 0004).
  final int? price;

  /// Force or cancel the peak tint for this day; default follows the country's Thu-Sat band.
  final bool? peak;
}

/// A date range; [end] is null while only the start has been chosen.
class GzDateRange {
  const GzDateRange({this.start, this.end});

  static const GzDateRange empty = GzDateRange();

  final String? start;
  final String? end;

  @override
  bool operator ==(Object other) => other is GzDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Availability | Prices.
enum GzCalendarView { availability, prices }
