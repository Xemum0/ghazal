import 'package:flutter/widgets.dart';

import '../core/gz_chrome_baseline.dart';
import '../theme/gz_theme.dart';
import '../tokens/generated/gz_type.g.dart';
import 'gz_bidi.dart';

/// Numbers as the figures voice (the web `.gz-num`): Manrope, Western digits, tabular and lining, weight and colour of the
/// surrounding text, an LTR island (U+2066 ... U+2069), size taken from the surrounding role's figure role.
abstract final class GzFigures {
  /// A sign directly before the digits and a percent or plus directly after belong to the number (`-15%`, `35,000+`).
  static final RegExp run = RegExp(r'[−+]?(?:\d[\d:.,]*\d|\d)[%٪+]?');

  /// The style of an inline number inside [role] text: figures family and size, tabular lining digits, weight and colour inherited
  /// from the parent span. The line height is 0, like the web `.gz-num` (`line-height: 0`): the figures face has other metrics than
  /// the surrounding face and must never stretch the line; a number that is the whole element uses [GzNum], which carries the
  /// figure role's own line height.
  static TextStyle inlineStyle(Locale locale, GzTextRole role) {
    final base = GzType.style(locale, role);
    final figure = GzType.style(locale, role.figureRole ?? role);
    final size = figure.fontSize ?? base.fontSize ?? 16;
    return TextStyle(
      fontFamily: GzFont.fig,
      package: GzFont.package,
      fontFamilyFallback: GzFont.figFallback,
      fontSize: size,
      height: 0,
      letterSpacing: 0,
      wordSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
      fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    );
  }

  /// One inline number as a span (use inside Text.rich or GzText.rich).
  static TextSpan span(BuildContext context, String value, {GzTextRole role = GzTextRole.body, TextStyle? style}) {
    final base = inlineStyle(context.gz.locale, role);
    return TextSpan(text: GzBidi.isolateLtr(value), style: style == null ? base : base.merge(style));
  }

  /// Splits running text at its digit runs and wraps every run as a figures island: the web `Figures`.
  static List<InlineSpan> spans(BuildContext context, String text, {GzTextRole role = GzTextRole.body}) {
    final plain = GzBidi.strip(text);
    final out = <InlineSpan>[];
    var last = 0;
    for (final m in run.allMatches(plain)) {
      if (m.start > last) out.add(TextSpan(text: plain.substring(last, m.start)));
      out.add(span(context, m.group(0)!, role: role));
      last = m.end;
    }
    if (last < plain.length) out.add(TextSpan(text: plain.substring(last)));
    return out;
  }
}

/// A number that is the whole element (a price, a count, a KPI): figures face, tabular digits, an LTR island, aligned to the
/// start of the reading direction. For a number inside a sentence use [GzFigures.span] or `GzText(figures: true)`.
class GzNum extends StatelessWidget {
  const GzNum(this.value, {this.role = GzTextRole.body, this.color, this.maxLines = 1, this.textAlign, this.semanticLabel, super.key});

  /// The formatted number from the shared formatter (never hand-typed).
  final String value;

  /// The text role of the surrounding line; the figure size follows it.
  final GzTextRole role;
  final Color? color;
  final int maxLines;
  final TextAlign? textAlign;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final base = gz.text(role);
    final style = GzFigures.inlineStyle(gz.locale, role).copyWith(fontWeight: base.fontWeight, color: color ?? gz.colors.textPrimary);
    final figure = gz.text(role.figureRole ?? role);
    // A standalone number takes the figure role's own line height (the web figure role classes carry their own).
    final line = style.copyWith(height: figure.height);
    return GzChromeBaseline(
      style: line,
      paint: false,
      child: Text(
        GzBidi.isolateLtr(value),
        style: line,
        // The role's own line height holds even when a fallback face (an Arabic currency sign) has other metrics.
        strutStyle: StrutStyle.fromTextStyle(line, forceStrutHeight: true, leadingDistribution: TextLeadingDistribution.even),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        semanticsLabel: semanticLabel ?? GzBidi.strip(value),
      ),
    );
  }
}
