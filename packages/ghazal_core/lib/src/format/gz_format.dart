// GzFormat: the one formatter object (ADR 0010 D4), bound to a locale, a digit style, a country and a clock. Dart
// twin of `createFormat` in packages/i18n/src/format.ts, with the same method names, tested against the same golden
// cases (packages/contracts/fixtures/format-cases.json). UI code never calls NumberFormat, DateFormat or
// toStringAsFixed; it asks this object for a string.
import 'dart:ui' show Locale;

import '../money/money.dart';
import 'bidi.dart';
import 'config.dart';
import 'datetime.dart' as dt;
import 'datetime.dart' show CalendarDay, Civil, DateInput, DateStyle, DateWithHijri, HijriDate, NameStyle;
import 'money_format.dart';
import 'numbers.dart' as nm;
import 'numbers.dart' show DecimalOptions, FormatCtx, PluralCategory;
import 'phone_kw.dart';

class GzFormat {
  /// [digitStyle] is honoured in Arabic only: the Settings switch exists only while the UI is Arabic (ADR 0010 D2).
  /// [now] is the injected clock (production: `DateTime.now`); nothing here reads the device clock otherwise.
  GzFormat({
    required Locale locale,
    DigitStyle digitStyle = DigitStyle.western,
    CountryConfig? country,
    DateTime Function()? now,
  })  : lang = Lang.fromCode(locale.languageCode),
        digitStyle = locale.languageCode == 'ar' ? digitStyle : DigitStyle.western,
        country = country ?? kKuwait,
        now = now ?? DateTime.now {
    ctx = FormatCtx(lang: lang, digitStyle: this.digitStyle, country: this.country, now: this.now);
  }

  final Lang lang;
  final DigitStyle digitStyle;
  final CountryConfig country;
  final DateTime Function() now;
  late final FormatCtx ctx;

  bool get isArabic => lang == Lang.ar;

  // ---- numbers
  String number(num n, [DecimalOptions o = const DecimalOptions()]) => nm.formatNumber(ctx, n, o);
  String integer(num n) => nm.formatNumber(ctx, nm.jsRound(n.toDouble()));
  String percent(num pct, {int maxFraction = 0}) => nm.formatPercent(ctx, pct, maxFraction: maxFraction);
  String numberRange(num from, num to, [DecimalOptions o = const DecimalOptions()]) => nm.formatNumberRange(ctx, from, to, o);
  String counter(num current, num total) => nm.formatCounter(ctx, current, total);
  PluralCategory pluralCategory(num n) => nm.pluralCategory(lang, n);
  String plural(num n, Map<String, String> forms) => nm.formatPlural(ctx, n, forms);
  String list(List<String> items, {bool or = false}) => nm.formatList(lang, items, or: or);

  // ---- money (input is always integer minor units: fils)
  String money(int minor, [MoneyOptions o = const MoneyOptions()]) => formatMoney(ctx, minor, o);

  /// A [Money] value; the currency comes from the value.
  String moneyOf(Money m, {MoneyMode mode = MoneyMode.browse, bool legal = false}) =>
      formatMoney(ctx, m.fils, MoneyOptions(mode: mode, currency: m.currency, legal: legal));
  MoneyParts moneyParts(int minor, [MoneyOptions o = const MoneyOptions()]) => formatMoneyParts(ctx, minor, o);
  MoneyParts moneyPartsOf(Money m, {MoneyMode mode = MoneyMode.browse, bool legal = false}) =>
      formatMoneyParts(ctx, m.fils, MoneyOptions(mode: mode, currency: m.currency, legal: legal));
  List<String> moneySet(List<int> values, [MoneyOptions o = const MoneyOptions()]) => formatMoneySet(ctx, values, o);
  String moneyRange(int from, int to, [MoneyOptions o = const MoneyOptions()]) => formatMoneyRange(ctx, from, to, o);
  String moneyAxis(int minor, [MoneyOptions o = const MoneyOptions()]) => formatMoneyAxis(ctx, minor, o);
  String priceUnit(int minor, PriceUnit unit, [MoneyOptions o = const MoneyOptions()]) => formatPriceUnit(ctx, minor, unit, o);
  String flatFee(int minor, String label, [MoneyOptions o = const MoneyOptions()]) => formatFlatFee(ctx, minor, label, o);
  String guests(int n, {bool afterPreposition = false}) => formatGuests(ctx, n, afterPreposition: afterPreposition);
  String minGuests(int n) => formatMinGuests(ctx, n);
  String priceForGuests(int minor, int guests, [PricePrefix prefix = PricePrefix.none, MoneyOptions o = const MoneyOptions()]) =>
      formatPriceForGuests(ctx, minor, guests, prefix, o);
  String fromPriceMin(int minor, int minGuests, [MoneyOptions o = const MoneyOptions()]) => formatFromPriceMin(ctx, minor, minGuests, o);

  // ---- dates and times (Asia/Kuwait, fixed +03:00)
  String date(DateInput d, [DateStyle style = DateStyle.full]) => dt.formatDate(ctx, d, style);

  /// `6 شعبان 1448 هـ` (Arabic only; null in English or outside the embedded Umm al-Qura table).
  String? hijri(DateInput d) => dt.formatHijri(ctx, d);

  /// `6 شعبان` (Arabic only): the Hijri day and month, no year and no era mark.
  String? hijriShort(DateInput d) => dt.formatHijri(ctx, d, short: true);

  /// The Hijri short line from a label the server sent with the day (`6 شعبان`); null in English.
  String? hijriShortFromLabel(String? serverLabel) => dt.hijriShortFromLabel(ctx, serverLabel);
  HijriDate? hijriDate(DateInput d) => dt.hijriOf(d, country);
  DateWithHijri dateWithHijri(DateInput d) => dt.formatDateWithHijri(ctx, d);
  String time(DateInput d, {bool? clock24h}) => dt.formatTime(ctx, d, clock24h: clock24h);
  String timeRange(DateInput from, DateInput to) => dt.formatTimeRange(ctx, from, to);
  String dateTime(DateInput d, [DateStyle style = DateStyle.short]) => dt.formatDateTime(ctx, d, style);
  String relativeDay(DateInput d) => dt.formatRelativeDay(ctx, d);
  String countdownDays(num days) => dt.formatCountdownDays(ctx, days);

  /// Whole calendar days from now to [d] (negative in the past).
  int daysUntil(DateInput d) => dt.daysBetween(now(), d, country);

  /// Compact operational duration from milliseconds: `5 h 20 m`.
  String duration(num ms) => dt.formatCompactDuration(ctx, ms);
  String ago(DateInput d) => dt.formatAgo(ctx, d);
  String weekdayName(int weekday, [NameStyle style = NameStyle.long]) => dt.weekdayName(lang, weekday, style);
  String monthName(int month, {bool short = false}) => dt.monthName(lang, month, short: short);
  List<String> weekdayHeaders() => dt.weekdayHeaders(lang, country);
  List<String> weekdayLabels() => dt.weekdayLabels(lang, country);
  List<List<CalendarDay>> monthGrid(int year, int month) => dt.monthGrid(year, month, country);
  Civil civil(DateInput d) => dt.civilOf(d, country);
  DateTime instant(DateInput d) => dt.toInstant(d, country);
  DateTime kuwaitDate(int y, int m, int d, {int hour = 12, int minute = 0}) =>
      dt.civilToInstant(y, m, d, hour: hour, minute: minute, country: country);
  String isoDay(DateInput d) => dt.isoDay(d, country);
  DateTime addDays(DateInput d, int days) => dt.addDays(d, days, country);

  // ---- phone (always Western digits, always an LTR isolate)
  String phone(String raw) => PhoneKw.format(raw, country);
  String phoneNational(String raw) => PhoneKw.formatNational(raw, country);
  String normalizePhone(String raw) => PhoneKw.normalizeInput(raw, country);
  bool isValidPhone(String raw) => PhoneKw.isValid(raw, country);
  String? e164(String raw) => PhoneKw.toE164(raw, country);
  String? telHref(String raw) => PhoneKw.telHref(raw, country);
  String? whatsappHref(String raw) => PhoneKw.whatsappHref(raw, country);

  // ---- input and text helpers
  String normalizeDigits(String s) => normalizeDigitsOf(s);
  String plain(String s) => plainText(s);

  /// Applies the digit style to a string of already-translated text: Western digits become Eastern when the switch is
  /// on (Arabic only). Use it for ARB output that carries counts (the generated `AppL10n` prints Western digits);
  /// formatter output already honours the style and must not be passed through twice (it is idempotent anyway).
  String digits(String s) => digitStyle == DigitStyle.easternArabic ? easternDigitsOnly(s) : s;
}

String normalizeDigitsOf(String s) => normalizeDigits(s);

MoneyParts formatMoneyParts(FormatCtx ctx, int minor, MoneyOptions o) => moneyParts(ctx, minor, o);
