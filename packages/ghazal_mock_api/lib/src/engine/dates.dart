/// Calendar arithmetic on Kuwait civil dates ('YYYY-MM-DD') and Asia/Kuwait instants (+03:00, no DST). Port of engine/dates.ts.
library;

const _msPerDay = 86400000;
const _kuwaitOffsetMs = 3 * 3600000;

int epochDay(String date) {
  final y = int.parse(date.substring(0, 4));
  final m = int.parse(date.substring(5, 7));
  final d = int.parse(date.substring(8, 10));
  return DateTime.utc(y, m, d).millisecondsSinceEpoch ~/ _msPerDay;
}

String fromEpochDay(int n) => DateTime.fromMillisecondsSinceEpoch(n * _msPerDay, isUtc: true).toIso8601String().substring(0, 10);

String addDays(String date, int days) => fromEpochDay(epochDay(date) + days);

/// Whole days from [a] to [b] (positive when b is later).
int diffDays(String a, String b) => epochDay(b) - epochDay(a);

/// 0 = Sunday ... 6 = Saturday.
int weekdayOf(String date) => (((epochDay(date) + 4) % 7) + 7) % 7;

String monthOf(String date) => date.substring(0, 7);

int monthNumber(String date) => int.parse(date.substring(5, 7));

String startOfMonth(String month) => '$month-01';

String endOfMonth(String month) {
  final y = int.parse(month.substring(0, 4));
  final m = int.parse(month.substring(5, 7));
  return fromEpochDay(DateTime.utc(y, m + 1, 1).millisecondsSinceEpoch ~/ _msPerDay - 1);
}

String addMonths(String month, int n) {
  final y = int.parse(month.substring(0, 4));
  final m = int.parse(month.substring(5, 7)) - 1 + n;
  final yy = y + (m / 12).floor();
  final mm = ((m % 12) + 12) % 12;
  return '$yy-${(mm + 1).toString().padLeft(2, '0')}';
}

List<String> datesInMonth(String month) => [for (var n = epochDay(startOfMonth(month)); n <= epochDay(endOfMonth(month)); n++) fromEpochDay(n)];

List<String> datesBetween(String from, String to) => [for (var n = epochDay(from); n <= epochDay(to); n++) fromEpochDay(n)];

// ---------------------------------------------------------------- instants

int instantMs(String at) => DateTime.parse(at).millisecondsSinceEpoch;

/// Epoch milliseconds as an Asia/Kuwait instant: 'YYYY-MM-DDTHH:MM:SS+03:00'.
String toKuwaitInstant(int ms) => '${DateTime.fromMillisecondsSinceEpoch(ms + _kuwaitOffsetMs, isUtc: true).toIso8601String().substring(0, 19)}+03:00';

String addHours(String at, int hours) => toKuwaitInstant(instantMs(at) + hours * 3600000);

String addMinutes(String at, int minutes) => toKuwaitInstant(instantMs(at) + minutes * 60000);

/// Minutes from [a] to [b] (positive when b is later), rounded like JavaScript.
int diffMinutes(String a, String b) => ((instantMs(b) - instantMs(a)) / 60000 + 0.5).floor();

String kuwaitDateOf(String at) => DateTime.fromMillisecondsSinceEpoch(instantMs(at) + _kuwaitOffsetMs, isUtc: true).toIso8601String().substring(0, 10);

String kuwaitTimeOf(String at) => DateTime.fromMillisecondsSinceEpoch(instantMs(at) + _kuwaitOffsetMs, isUtc: true).toIso8601String().substring(11, 16);

/// An instant from a civil date and a local time.
String atTime(String date, String time) => '${date}T${time.length == 5 ? '$time:00' : time}+03:00';

bool isBefore(String a, String b) => instantMs(a) < instantMs(b);
