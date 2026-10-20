// Numbers, percent, ranges, plurals, lists (ADR 0010 D1, D2, D5; ADR 0013 D7). Hand-rolled on purpose, exactly like
// packages/i18n/src/numbers.ts: no Intl in the hot path, so web and Dart produce identical strings.
import 'dart:math' as math;

import 'bidi.dart';
import 'config.dart';

/// What every formatter needs: language, digit style, country and the injected clock.
class FormatCtx {
  const FormatCtx({required this.lang, required this.digitStyle, required this.country, required this.now});

  final Lang lang;
  final DigitStyle digitStyle;
  final CountryConfig country;
  final DateTime Function() now;

  bool get isAr => lang == Lang.ar;
}

/// Display form of one numeric token: Eastern digits when the switch is on, then an LTR isolate in Arabic.
String numToken(FormatCtx ctx, String text) {
  final shown = ctx.digitStyle == DigitStyle.easternArabic ? toEasternDigits(text) : text;
  return ctx.isAr ? isolateLtr(shown) : shown;
}

/// Groups an unsigned integer string with commas: "18200" -> "18,200".
String groupDigits(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Round half away from zero at [digits] fraction digits, without the binary-float traps of `toStringAsFixed`.
double roundHalfUp(double value, int digits) {
  final sign = value < 0 ? -1.0 : 1.0;
  final abs = value.abs();
  final shifted = double.tryParse('${abs}e$digits');
  final base = (shifted == null || shifted.isNaN) ? abs * math.pow(10, digits) : shifted;
  final rounded = (base + 0.5).floorToDouble();
  final back = double.parse('${rounded.toStringAsFixed(0)}e-$digits');
  final out = sign * back;
  return out == 0 ? 0 : out;
}

/// JavaScript `Math.round`: half toward +infinity.
int jsRound(double value) => (value + 0.5).floor();

class DecimalOptions {
  const DecimalOptions({this.minFraction = 0, int? maxFraction, this.grouping = true}) : _maxFraction = maxFraction; // ignore: prefer_initializing_formals

  final int minFraction;
  final int? _maxFraction;
  final bool grouping;

  int get maxFraction => math.max(_maxFraction ?? minFraction, minFraction);

  factory DecimalOptions.fromJson(Map<String, Object?>? json) => json == null
      ? const DecimalOptions()
      : DecimalOptions(
          minFraction: (json['minFraction'] as num?)?.toInt() ?? 0,
          maxFraction: (json['maxFraction'] as num?)?.toInt(),
          grouping: json['grouping'] as bool? ?? true,
        );
}

class DecimalParts {
  const DecimalParts(this.negative, this.text);
  final bool negative;
  final String text;
}

/// Unsigned digits of a number as plain Western text, grouped, with a `.` fraction. Sign is returned separately.
DecimalParts decimalParts(num value, [DecimalOptions opts = const DecimalOptions()]) {
  final v = value.toDouble();
  if (v.isNaN || v.isInfinite) throw RangeError('not a finite number: $value');
  final minF = opts.minFraction;
  final maxF = opts.maxFraction;
  final rounded = roundHalfUp(v, maxF);
  final fixed = rounded.abs().toStringAsFixed(maxF);
  final dot = fixed.indexOf('.');
  final intRaw = dot < 0 ? fixed : fixed.substring(0, dot);
  var frac = dot < 0 ? '' : fixed.substring(dot + 1);
  while (frac.length > minF && frac.endsWith('0')) {
    frac = frac.substring(0, frac.length - 1);
  }
  final intText = opts.grouping ? groupDigits(intRaw) : intRaw;
  return DecimalParts(rounded < 0, frac.isEmpty ? intText : '$intText.$frac');
}

/// `18,200`, `4.5`, `−3` (U+2212 inside the isolate). Latin or Eastern digits per the context.
String formatNumber(FormatCtx ctx, num value, [DecimalOptions opts = const DecimalOptions()]) {
  final p = decimalParts(value, opts);
  return numToken(ctx, p.negative ? '$kMinus${p.text}' : p.text);
}

/// `30%`: no space, never the Arabic percent sign (ADR 0010 D5). [pct] is in percent points (30 = 30%).
String formatPercent(FormatCtx ctx, num pct, {int maxFraction = 0}) {
  final p = decimalParts(pct, DecimalOptions(maxFraction: maxFraction));
  return numToken(ctx, '${p.negative ? kMinus : ''}${p.text}%');
}

/// Ranges are words in Arabic (`من 22 إلى 52`) and an en dash in English (`22 – 52`), each number isolated.
String formatNumberRange(FormatCtx ctx, num from, num to, [DecimalOptions opts = const DecimalOptions()]) {
  final a = formatNumber(ctx, from, opts);
  final b = formatNumber(ctx, to, opts);
  return ctx.isAr ? 'من $a إلى $b' : '$a$kNbsp$kEnDash $b';
}

/// Counter `1 of 6` / `1 من 6` with LTR digits (ADR 0014 D4).
String formatCounter(FormatCtx ctx, num current, num total) {
  final a = formatNumber(ctx, current);
  final b = formatNumber(ctx, total);
  return ctx.isAr ? '$a من $b' : '$a of $b';
}

enum PluralCategory { zero, one, two, few, many, other }

/// CLDR integer plural category. Arabic has six categories decided by the last two digits (ADR 0013 D7).
PluralCategory pluralCategory(Lang lang, num n) {
  if (n is double && n != n.truncateToDouble()) return PluralCategory.other;
  final abs = n.abs().toInt();
  if (lang == Lang.en) return abs == 1 ? PluralCategory.one : PluralCategory.other;
  if (abs == 0) return PluralCategory.zero;
  if (abs == 1) return PluralCategory.one;
  if (abs == 2) return PluralCategory.two;
  final last2 = abs % 100;
  if (last2 >= 3 && last2 <= 10) return PluralCategory.few;
  if (last2 >= 11 && last2 <= 99) return PluralCategory.many;
  return PluralCategory.other;
}

/// Picks a form by category and fills `{n}` with the formatted number. Exact matches win: use `'=0'`, `'=1'`, `'=2'`
/// keys for the zero/one/two forms that read better without a number (`ضيف واحد`, `لا ضيوف`).
String formatPlural(FormatCtx ctx, num n, Map<String, String> forms) {
  final exact = forms['=$n'] ?? (n is double && n == n.truncateToDouble() ? forms['=${n.toInt()}'] : null);
  final form = exact ?? forms[pluralCategory(ctx.lang, n).name] ?? forms['other'];
  if (form == null) throw ArgumentError('plural forms need an "other" entry');
  return form.replaceAll('{n}', formatNumber(ctx, n));
}

/// `a, b and c` / `أ، ب وج`. Arabic uses the Arabic comma and the attached و (ADR 0013 D6).
String formatList(Lang lang, List<String> items, {bool or = false}) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  final last = items.last;
  final head = items.sublist(0, items.length - 1);
  if (lang == Lang.ar) {
    final joiner = or ? 'أو ' : 'و';
    return '${head.join('، ')} $joiner$last';
  }
  return '${head.join(', ')} ${or ? 'or' : 'and'} $last';
}
