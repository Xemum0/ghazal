// Money from integer minor units (ADR 0010 D6-D9, ADR 0004 D6). Dart twin of packages/i18n/src/money.ts. The formatter
// owns every price template; UI code never builds a price string.
import 'bidi.dart';
import 'config.dart';
import 'numbers.dart';

/// browse: integer dinars when fils are zero, else exactly three decimals. exact: always three. axis: chart ticks only.
enum MoneyMode { browse, exact, axis }

class MoneyOptions {
  const MoneyOptions({this.mode = MoneyMode.browse, this.currency = CurrencyCode.kwd, this.legal = false, this.fullPrecision = false});

  final MoneyMode mode;
  final CurrencyCode currency;

  /// `false` = consumer label (KD / د.ك). `true` = the ISO code, for invoices, bank settings, gateway, API (ADR 0010 D7).
  final bool legal;

  /// Force the decimals of a whole set so one list shows one precision (ADR 0010 D8).
  final bool fullPrecision;

  MoneyOptions copyWith({MoneyMode? mode, CurrencyCode? currency, bool? legal, bool? fullPrecision}) => MoneyOptions(
        mode: mode ?? this.mode,
        currency: currency ?? this.currency,
        legal: legal ?? this.legal,
        fullPrecision: fullPrecision ?? this.fullPrecision,
      );

  /// From the golden-case JSON: `{"mode":"exact","currency":"SAR","label":"legal","fullPrecision":true}`.
  factory MoneyOptions.fromJson(Map<String, Object?>? json) => json == null
      ? const MoneyOptions()
      : MoneyOptions(
          mode: MoneyMode.values.firstWhere((m) => m.name == (json['mode'] ?? 'browse')),
          currency: json['currency'] == null ? CurrencyCode.kwd : CurrencyCode.fromCode(json['currency']! as String),
          legal: json['label'] == 'legal',
          fullPrecision: json['fullPrecision'] == true,
        );
}

class MoneyParts {
  const MoneyParts({
    required this.negative,
    required this.integer,
    required this.fraction,
    required this.fractionIsZero,
    required this.currency,
    required this.amount,
    required this.text,
  });

  final bool negative;

  /// Grouped integer digits in display digits, no sign, no isolate: `18,200`.
  final String integer;

  /// `.500`, `.000` or empty (a leading dot, display digits). The UI sets `.000` quieter (01-direction 2.4).
  final String fraction;
  final bool fractionIsZero;

  /// `KD`, `د.ك`, or `KWD` for legal labels.
  final String currency;

  /// Plain amount text with the sign inside: `−50.000`. No isolate.
  final String amount;

  /// The full string, bidi-safe: Arabic = isolated number, NBSP, currency; English = currency, NBSP, number.
  final String text;

  Map<String, Object?> toJson() => {
        'negative': negative,
        'integer': integer,
        'fraction': fraction,
        'fractionIsZero': fractionIsZero,
        'currency': currency,
        'amount': amount,
        'text': text,
      };
}

class _Core {
  _Core(this.negative, this.whole, this.frac, this.label, this.legal, this.fracIsZero);
  final bool negative;
  final String whole;
  final String frac;
  final String label;
  final bool legal;
  final bool fracIsZero;

  String get plain => '${negative ? kMinus : ''}$whole$frac';
}

_Core _core(FormatCtx ctx, int minor, MoneyOptions o) {
  final exp = o.currency.exponent;
  final unit = o.currency.unit;
  final abs = minor.abs();
  final whole = abs ~/ unit;
  final frac = abs % unit;
  final showFraction = o.mode == MoneyMode.exact || o.fullPrecision || frac != 0;
  return _Core(
    minor < 0,
    groupDigits('$whole'),
    showFraction ? '.${'$frac'.padLeft(exp, '0')}' : '',
    o.legal ? o.currency.code : o.currency.consumer(ctx.lang),
    o.legal,
    showFraction && frac == 0,
  );
}

String _compose(FormatCtx ctx, String token, _Core c) {
  if (ctx.isAr) return '$token$kNbsp${c.legal ? isolateLtr(c.label) : c.label}';
  return '${c.label}$kNbsp$token';
}

MoneyParts moneyParts(FormatCtx ctx, int minor, [MoneyOptions o = const MoneyOptions()]) {
  if (o.mode == MoneyMode.axis) throw RangeError('use formatMoneyAxis() for chart ticks');
  final c = _core(ctx, minor, o);
  String shown(String s) => ctx.digitStyle == DigitStyle.easternArabic ? toEasternDigits(s) : s;
  return MoneyParts(
    negative: c.negative,
    integer: shown(c.whole),
    fraction: shown(c.frac),
    fractionIsZero: c.fracIsZero,
    currency: c.label,
    amount: shown(c.plain),
    text: _compose(ctx, numToken(ctx, c.plain), c),
  );
}

String formatMoney(FormatCtx ctx, int minor, [MoneyOptions o = const MoneyOptions()]) {
  if (o.mode == MoneyMode.axis) return formatMoneyAxis(ctx, minor, o);
  return moneyParts(ctx, minor, o).text;
}

/// One precision per list, column or summary block (ADR 0010 D8): in browse mode, if any value has fils, every value
/// shows three decimals.
List<String> formatMoneySet(FormatCtx ctx, List<int> values, [MoneyOptions o = const MoneyOptions()]) {
  final unit = o.currency.unit;
  final anyFils = values.any((v) => v.abs() % unit != 0);
  return [for (final v in values) formatMoney(ctx, v, o.copyWith(fullPrecision: o.fullPrecision || anyFils))];
}

/// `KD 22 – 52` / `من 22 إلى 52 د.ك`: the currency once, each number isolated, one shared precision.
String formatMoneyRange(FormatCtx ctx, int fromMinor, int toMinor, [MoneyOptions o = const MoneyOptions()]) {
  final unit = o.currency.unit;
  final full = o.mode == MoneyMode.exact || o.fullPrecision || fromMinor % unit != 0 || toMinor % unit != 0;
  final a = _core(ctx, fromMinor, o.copyWith(fullPrecision: full));
  final b = _core(ctx, toMinor, o.copyWith(fullPrecision: full));
  if (ctx.isAr) {
    final label = a.legal ? isolateLtr(a.label) : a.label;
    return 'من ${numToken(ctx, a.plain)} إلى ${numToken(ctx, b.plain)}$kNbsp$label';
  }
  return '${a.label}$kNbsp${a.plain}$kNbsp$kEnDash ${b.plain}';
}

/// Chart ticks only: `18.4K` / `18.4 ألف`, `1.2M` / `1.2 مليون`. Never used for money a person has to act on.
String formatMoneyAxis(FormatCtx ctx, int minor, [MoneyOptions o = const MoneyOptions()]) {
  final major = minor.abs() / o.currency.unit;
  final sign = minor < 0 ? kMinus : '';
  if (roundHalfUp(major, 0) < 1000) {
    return numToken(ctx, '$sign${decimalParts(major, const DecimalOptions(maxFraction: 0)).text}');
  }
  final million = major >= 999950;
  final value = decimalParts(million ? major / 1000000 : major / 1000, const DecimalOptions(maxFraction: 1)).text;
  final token = numToken(ctx, '$sign$value');
  if (ctx.isAr) return '$token$kNbsp${million ? 'مليون' : 'ألف'}';
  return '$token${million ? 'M' : 'K'}';
}

// Price grammar (ADR 0010 D9, ADR 0004 D6). A price never appears without its unit or guest basis.

enum PriceUnit {
  perGuest('per guest', 'للضيف'),
  perNight('per night', 'لليلة'),
  perDay('per day', 'لليوم'),
  perHour('per hour', 'للساعة');

  const PriceUnit(this.en, this.ar);
  final String en;
  final String ar;
}

String formatPriceUnit(FormatCtx ctx, int minor, PriceUnit unit, [MoneyOptions o = const MoneyOptions()]) =>
    '${formatMoney(ctx, minor, o)} ${ctx.isAr ? unit.ar : unit.en}';

/// Flat fees put the label first in Arabic and last in English: `رسوم الإيجار 100 د.ك` / `KD 100 rental fee`.
String formatFlatFee(FormatCtx ctx, int minor, String label, [MoneyOptions o = const MoneyOptions()]) {
  final money = formatMoney(ctx, minor, o);
  return ctx.isAr ? '$label $money' : '$money $label';
}

const Map<String, String> _guestsEn = {'=1': '1 guest', 'other': '{n} guests'};
const Map<String, String> _guestsAr = {
  '=0': 'لا ضيوف',
  '=1': 'ضيف واحد',
  '=2': 'ضيفان',
  'few': '{n} ضيوف',
  'many': '{n} ضيفًا',
  'other': '{n} ضيف',
};

/// `350 guests` / `350 ضيفًا`. After a preposition the Arabic dual takes `-ين` (`لعدد ضيفين`, ADR 0013 D7).
String formatGuests(FormatCtx ctx, int n, {bool afterPreposition = false}) {
  final forms = ctx.isAr ? (afterPreposition ? {..._guestsAr, '=2': 'ضيفين'} : _guestsAr) : _guestsEn;
  return formatPlural(ctx, n, forms);
}

String formatMinGuests(FormatCtx ctx, int n) =>
    ctx.isAr ? 'الحد الأدنى ${formatGuests(ctx, n)}' : 'Minimum ${formatGuests(ctx, n)}';

enum PricePrefix {
  none('', ''),
  from('From ', 'من '),
  est('Est. ', 'تقريبًا ');

  const PricePrefix(this.en, this.ar);
  final String en;
  final String ar;
}

/// The card price line with its guest basis (ADR 0004 D6): `KD 7,843 for 400 guests`; Arabic `من 16,100 د.ك لعدد 350 ضيفًا`.
String formatPriceForGuests(FormatCtx ctx, int minor, int guests,
    [PricePrefix prefix = PricePrefix.none, MoneyOptions o = const MoneyOptions()]) {
  final money = formatMoney(ctx, minor, o);
  final word = ctx.isAr ? prefix.ar : prefix.en;
  return ctx.isAr
      ? '$word$money لعدد ${formatGuests(ctx, guests, afterPreposition: true)}'
      : '$word$money for ${formatGuests(ctx, guests)}';
}

/// `From KD 2,100 · min 200 guests` / `من 2,100 د.ك · الحد الأدنى 200 ضيف`.
String formatFromPriceMin(FormatCtx ctx, int minor, int minGuests, [MoneyOptions o = const MoneyOptions()]) {
  final money = formatMoney(ctx, minor, o);
  return ctx.isAr
      ? 'من $money · ${formatMinGuests(ctx, minGuests)}'
      : 'From $money · min ${formatGuests(ctx, minGuests)}';
}
