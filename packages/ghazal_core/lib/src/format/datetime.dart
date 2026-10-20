// Dates, times, weeks and calendars (ADR 0011). Dart twin of packages/i18n/src/datetime.ts. Always Asia/Kuwait as a
// fixed UTC+3 offset (no timezone package, no DST), Gregorian primary, Hijri a secondary Arabic-only line, Sunday-first
// weeks through config, 12-hour clock with the suffix composed here. Month and weekday names are tables, patterns are
// explicit, never ICU defaults.
import 'bidi.dart';
import 'config.dart';
import 'hijri_table.g.dart';
import 'numbers.dart';

/// A date or instant input: a `DateTime`, epoch milliseconds, or an ISO string. A bare `YYYY-MM-DD` is a Kuwait
/// calendar date (noon in Kuwait); `YYYY-MM-DDTHH:mm[:ss]` without an offset is Kuwait wall time; `Z` or an offset
/// is an absolute instant.
typedef DateInput = Object;

/// A civil date and wall-clock time in the country's zone. [month] is 1-12, [weekday] 0 = Sunday.
class Civil {
  const Civil(this.year, this.month, this.day, this.weekday, this.hour, this.minute);
  final int year;
  final int month;
  final int day;
  final Weekday weekday;
  final int hour;
  final int minute;

  Map<String, Object?> toJson() =>
      {'year': year, 'month': month, 'day': day, 'weekday': weekday, 'hour': hour, 'minute': minute};
}

const int _msMinute = 60000;
const int _msHour = 3600000;
const int _msDay = 86400000;

final RegExp _isoDateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final RegExp _isoLocal = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$');

/// The instant of a civil date and time in the country's zone. Month is 1-12. Default time is noon.
DateTime civilToInstant(int y, int m, int d, {int hour = 12, int minute = 0, CountryConfig? country}) {
  final c = country ?? kKuwait;
  return DateTime.utc(y, m, d, hour, minute).subtract(Duration(minutes: c.utcOffsetMinutes));
}

/// Normalises any accepted input to a UTC instant (see [DateInput]).
DateTime toInstant(DateInput input, [CountryConfig? country]) {
  final c = country ?? kKuwait;
  if (input is DateTime) return input.toUtc();
  if (input is int) return DateTime.fromMillisecondsSinceEpoch(input, isUtc: true);
  if (input is! String) throw RangeError('not a date: $input');
  final dateOnly = _isoDateOnly.firstMatch(input);
  if (dateOnly != null) {
    return civilToInstant(int.parse(dateOnly[1]!), int.parse(dateOnly[2]!), int.parse(dateOnly[3]!), country: c);
  }
  final local = _isoLocal.firstMatch(input);
  if (local != null) {
    return civilToInstant(int.parse(local[1]!), int.parse(local[2]!), int.parse(local[3]!),
        hour: int.parse(local[4]!), minute: int.parse(local[5]!), country: c);
  }
  final parsed = DateTime.tryParse(input);
  if (parsed == null) throw RangeError('not a date: $input');
  return parsed.toUtc();
}

/// Civil parts in the country's zone (the device zone is ignored, ADR 0011 D3).
Civil civilOf(DateInput input, [CountryConfig? country]) {
  final c = country ?? kKuwait;
  final s = toInstant(input, c).add(Duration(minutes: c.utcOffsetMinutes));
  return Civil(s.year, s.month, s.day, s.weekday % 7, s.hour, s.minute);
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// `2027-01-14`. Technical contexts only (exports, keys); never shown as UI copy (ADR 0011 D2).
String isoDay(DateInput input, [CountryConfig? country]) {
  final c = civilOf(input, country);
  return '${c.year.toString().padLeft(4, '0')}-${_pad2(c.month)}-${_pad2(c.day)}';
}

int _epochDay(int y, int m, int d) => DateTime.utc(y, m, d).millisecondsSinceEpoch ~/ _msDay;

/// Whole calendar days from [from] to [to] in the country's zone (positive when [to] is later).
int daysBetween(DateInput from, DateInput to, [CountryConfig? country]) {
  final a = civilOf(from, country);
  final b = civilOf(to, country);
  return _epochDay(b.year, b.month, b.day) - _epochDay(a.year, a.month, a.day);
}

/// Adds calendar days and keeps the wall-clock time (there is no DST, so 24-hour blocks agree).
DateTime addDays(DateInput input, int days, [CountryConfig? country]) =>
    toInstant(input, country).add(Duration(milliseconds: days * _msDay));

// Names -------------------------------------------------------------------------------------------------------

const _monthsLongEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
// Gulf names (ADR 0011 D2).
const _monthsLongAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _monthsShortEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdaysLongEn = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const _weekdaysLongAr = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const _weekdaysShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
// Calendar header: article-less full words in Arabic, never CLDR single letters (ADR 0011 D4).
const _weekdaysHeaderAr = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
const _hijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة', //
];

enum NameStyle { long, short, header }

String monthName(Lang lang, int month, {bool short = false}) {
  final table = lang == Lang.ar ? _monthsLongAr : (short ? _monthsShortEn : _monthsLongEn);
  return month >= 1 && month <= 12 ? table[month - 1] : '';
}

String weekdayName(Lang lang, int weekday, [NameStyle style = NameStyle.long]) {
  if (weekday < 0 || weekday > 6) return '';
  if (lang == Lang.ar) return style == NameStyle.header ? _weekdaysHeaderAr[weekday] : _weekdaysLongAr[weekday];
  return style == NameStyle.long ? _weekdaysLongEn[weekday] : _weekdaysShortEn[weekday];
}

// Dates (ADR 0011 D2) ----------------------------------------------------------------------------------------

enum DateStyle { full, short, compact, monthYear, dayMonth }

/// full `Thursday 14 January 2027`; short `Thu 14 Jan` (year only when not the current year); compact `14 Jan 2027`;
/// monthYear `January 2027`; dayMonth `14 January`. Arabic uses the Gulf month names.
String formatDate(FormatCtx ctx, DateInput input, [DateStyle style = DateStyle.full]) {
  final c = civilOf(input, ctx.country);
  final day = numToken(ctx, '${c.day}');
  final year = numToken(ctx, '${c.year}');
  final long = monthName(ctx.lang, c.month);
  final short = monthName(ctx.lang, c.month, short: true);
  switch (style) {
    case DateStyle.full:
      return '${weekdayName(ctx.lang, c.weekday)} $day $long $year';
    case DateStyle.short:
      final sameYear = c.year == civilOf(ctx.now(), ctx.country).year;
      return '${weekdayName(ctx.lang, c.weekday, NameStyle.short)} $day $short${sameYear ? '' : ' $year'}';
    case DateStyle.compact:
      return '$day $short $year';
    case DateStyle.monthYear:
      return '$long $year';
    case DateStyle.dayMonth:
      return '$day $long';
  }
}

/// A Hijri (Umm al-Qura) calendar date.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;
}

/// The Umm al-Qura date of the Kuwait civil day of [input], from the embedded table (2025-2037); null outside it.
/// Computed at noon Kuwait so a date never slips a day (ADR 0011 Notes).
HijriDate? hijriOf(DateInput input, [CountryConfig? country]) {
  final c = civilOf(input, country);
  final day = _epochDay(c.year, c.month, c.day);
  if (day < kUmmAlQuraFirstDay || day > kUmmAlQuraLastDay) return null;
  var lo = 0;
  var hi = kUmmAlQuraMonthStarts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (kUmmAlQuraMonthStarts[mid][0] <= day) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  final row = kUmmAlQuraMonthStarts[lo];
  if (row[0] > day) return null;
  return HijriDate(row[1], row[2], day - row[0] + 1);
}

/// The Umm al-Qura secondary line, Arabic only: `6 شعبان 1448 هـ`; [short] drops the year and the era mark
/// (`6 شعبان`). English returns null (ADR 0011 D1).
String? formatHijri(FormatCtx ctx, DateInput input, {bool short = false}) {
  if (!ctx.isAr) return null;
  final h = hijriOf(input, ctx.country);
  if (h == null) return null;
  final label = _hijriMonths[h.month - 1];
  if (short) return '${numToken(ctx, '${h.day}')} $label';
  return '${numToken(ctx, '${h.day}')} $label ${numToken(ctx, '${h.year}')} هـ';
}

/// Short Hijri line from a server-provided label (`6 شعبان`): the label is returned as is in Arabic, null otherwise.
String? hijriShortFromLabel(FormatCtx ctx, String? serverLabel) => ctx.isAr && serverLabel != null && serverLabel.isNotEmpty ? serverLabel : null;

/// The selected-date confirmation (ADR 0011 D1b): the full date plus, in Arabic only, one muted Hijri line.
class DateWithHijri {
  const DateWithHijri(this.primary, this.secondary);
  final String primary;
  final String? secondary;
  String get joined => secondary == null ? primary : '$primary · $secondary';
}

DateWithHijri formatDateWithHijri(FormatCtx ctx, DateInput input) =>
    DateWithHijri(formatDate(ctx, input), formatHijri(ctx, input));

// Time (ADR 0011 D3) ----------------------------------------------------------------------------------------

/// `9:00 م` / `9:00 PM` (uppercase, NBSP). [clock24h] is for technical exports only.
String formatTime(FormatCtx ctx, DateInput input, {bool? clock24h}) {
  final c = civilOf(input, ctx.country);
  if (clock24h ?? ctx.country.clock24h) return numToken(ctx, '${_pad2(c.hour)}:${_pad2(c.minute)}');
  final h12 = c.hour % 12 == 0 ? 12 : c.hour % 12;
  final suffix = ctx.isAr ? (c.hour < 12 ? 'ص' : 'م') : (c.hour < 12 ? 'AM' : 'PM');
  return '${numToken(ctx, '$h12:${_pad2(c.minute)}')}$kNbsp$suffix';
}

/// `من 7:00 م إلى 1:00 ص` / `7:00 PM – 1:00 AM`.
String formatTimeRange(FormatCtx ctx, DateInput from, DateInput to) {
  final a = formatTime(ctx, from);
  final b = formatTime(ctx, to);
  return ctx.isAr ? 'من $a إلى $b' : '$a$kNbsp$kEnDash $b';
}

/// `Sun 15 Nov, 6:00 PM` / `الأحد 15 نوفمبر، 6:00 م`: an absolute deadline (ADR 0011 D3).
String formatDateTime(FormatCtx ctx, DateInput input, [DateStyle style = DateStyle.short]) =>
    '${formatDate(ctx, input, style)}${ctx.isAr ? '،' : ','} ${formatTime(ctx, input)}';

// Relative words (ADR 0011 D7): only Today and Tomorrow are relative; everything else is absolute. ---------------

/// `Today`, `Tomorrow`, otherwise the short date.
String formatRelativeDay(FormatCtx ctx, DateInput input) {
  final delta = daysBetween(ctx.now(), input, ctx.country);
  if (delta == 0) return ctx.isAr ? 'اليوم' : 'Today';
  if (delta == 1) return ctx.isAr ? 'غدًا' : 'Tomorrow';
  return formatDate(ctx, input, DateStyle.short);
}

const _countdownEn = {'=0': 'Today', '=1': '1 day to go', 'other': '{n} days to go'};
const _countdownAr = {
  '=0': 'اليوم',
  '=1': 'باقي يوم واحد',
  '=2': 'باقي يومان',
  'few': 'باقي {n} أيام',
  'many': 'باقي {n} يومًا',
  'other': 'باقي {n} يوم',
};

/// Whole days to go, never seconds (ADR 0011 D7): `63 days to go` / `باقي 63 يومًا`.
String formatCountdownDays(FormatCtx ctx, num days) {
  final n = days.truncate();
  return formatPlural(ctx, n < 0 ? 0 : n, ctx.isAr ? _countdownAr : _countdownEn);
}

/// Operational countdown in compact form: `5 h 20 m` / `5 س 20 د` (ADR 0011 D3). Takes milliseconds.
String formatCompactDuration(FormatCtx ctx, num ms) {
  final total = ms < 0 ? 0 : (ms / _msMinute).floor();
  final days = total ~/ 1440;
  final hours = (total % 1440) ~/ 60;
  final minutes = total % 60;
  final u = ctx.isAr ? (d: 'ي', h: 'س', m: 'د') : (d: 'd', h: 'h', m: 'm');
  String piece(int n, String unit) => '${formatNumber(ctx, n)}$kNbsp$unit';
  if (total < 1) return ctx.isAr ? 'أقل من ${piece(1, u.m)}' : '<${piece(1, u.m)}';
  final parts = <String>[];
  if (days > 0) parts.add(piece(days, u.d));
  if (hours > 0 || days > 0) parts.add(piece(hours, u.h));
  if (days == 0) parts.add(piece(minutes, u.m));
  return parts.join(' ');
}

const _agoMinEn = {'=1': '1 min ago', 'other': '{n} min ago'};
const _agoMinAr = {'=1': 'منذ دقيقة', '=2': 'منذ دقيقتين', 'few': 'منذ {n} دقائق', 'many': 'منذ {n} دقيقة', 'other': 'منذ {n} دقيقة'};
const _agoHourEn = {'=1': '1 h ago', 'other': '{n} h ago'};
const _agoHourAr = {'=1': 'منذ ساعة', '=2': 'منذ ساعتين', 'few': 'منذ {n} ساعات', 'many': 'منذ {n} ساعة', 'other': 'منذ {n} ساعة'};

/// Chat and activity stamps: `Just now`, `48 min ago`, `3 h ago`; a day or more becomes the absolute short date.
String formatAgo(FormatCtx ctx, DateInput input) {
  final diff = ctx.now().toUtc().millisecondsSinceEpoch - toInstant(input, ctx.country).millisecondsSinceEpoch;
  if (diff < 0) return formatDateTime(ctx, input);
  if (diff < _msMinute) return ctx.isAr ? 'الآن' : 'Just now';
  if (diff < _msHour) return formatPlural(ctx, diff ~/ _msMinute, ctx.isAr ? _agoMinAr : _agoMinEn);
  if (diff < _msDay) return formatPlural(ctx, diff ~/ _msHour, ctx.isAr ? _agoHourAr : _agoHourEn);
  return formatDate(ctx, input, DateStyle.short);
}

// Calendar data (ADR 0011 D4, D5): data only; the component mirrors it with directional layout. --------------------

class CalendarDay {
  const CalendarDay({
    required this.year,
    required this.month,
    required this.day,
    required this.iso,
    required this.weekday,
    required this.inMonth,
    required this.isWeekend,
    required this.isPeak,
  });
  final int year;
  final int month;
  final int day;
  final String iso;
  final Weekday weekday;
  final bool inMonth;
  final bool isWeekend;
  final bool isPeak;

  Map<String, Object?> toJson() =>
      {'iso': iso, 'weekday': weekday, 'inMonth': inMonth, 'isWeekend': isWeekend, 'isPeak': isPeak};
}

/// Weekday indexes in display order for the country's week start: Sunday-first for Kuwait.
List<Weekday> weekOrder([CountryConfig? country]) {
  final c = country ?? kKuwait;
  return [for (var i = 0; i < 7; i++) (c.weekStartsOn + i) % 7];
}

List<String> weekdayHeaders(Lang lang, [CountryConfig? country]) =>
    [for (final w in weekOrder(country)) weekdayName(lang, w, NameStyle.header)];

/// Full weekday names in week order, for accessible labels of the header cells.
List<String> weekdayLabels(Lang lang, [CountryConfig? country]) => [for (final w in weekOrder(country)) weekdayName(lang, w)];

/// The weeks of a month ([month] is 1-12), padded with the neighbouring months' days to whole rows.
List<List<CalendarDay>> monthGrid(int year, int month, [CountryConfig? country]) {
  final c = country ?? kKuwait;
  final first = DateTime.utc(year, month, 1);
  final lead = (first.weekday % 7 - c.weekStartsOn + 7) % 7;
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  final rows = ((lead + daysInMonth) / 7).ceil();
  return [
    for (var r = 0; r < rows; r++)
      [
        for (var i = 0; i < 7; i++)
          () {
            final cell = DateTime.utc(year, month, 1 - lead + r * 7 + i);
            final weekday = cell.weekday % 7;
            return CalendarDay(
              year: cell.year,
              month: cell.month,
              day: cell.day,
              iso: '${cell.year.toString().padLeft(4, '0')}-${_pad2(cell.month)}-${_pad2(cell.day)}',
              weekday: weekday,
              inMonth: cell.month == month && cell.year == year,
              isWeekend: c.weekend.contains(weekday),
              isPeak: c.peakBand.contains(weekday),
            );
          }(),
      ],
  ];
}
