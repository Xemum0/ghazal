import 'package:flutter/widgets.dart';

import '../core/gz_chrome_baseline.dart';
import '../theme/gz_theme.dart';
import '../tokens/generated/gz_type.g.dart';
import 'gz_num.dart';

/// The one text widget of the product: a text role from the tokens, the locale's script, colour from GzColors (default
/// `textPrimary`, the web body colour), Semantics, and sane overflow. Never take a literal here in app code: the string comes
/// from the localisation layer or the shared formatter.
///
/// - English roles marked `uppercaseEn` (tracked eyebrows) are uppercased here; Arabic never is.
/// - [figures] wraps the digit runs of [data] as figures islands (the web `Figures`).
/// - [maxLines] without [overflow] ellipsises.
class GzText extends StatelessWidget {
  const GzText(
    String this.data, {
    this.role = GzTextRole.body,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    this.figures = false,
    this.header = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    super.key,
  }) : span = null;

  /// Rich text: build the spans with [GzFigures.span] for inline numbers. The role style is the base style.
  const GzText.rich(
    InlineSpan this.span, {
    this.role = GzTextRole.body,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    this.header = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    super.key,
  })  : data = null,
        figures = false;

  final String? data;
  final InlineSpan? span;
  final GzTextRole role;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  final bool figures;
  final bool header;
  final String? semanticLabel;
  final bool excludeSemantics;

  /// The web text block carries a strut of its own role: a line that holds only a figures run (the figures face has other metrics and
  /// a zero line height inline) is still one full role line high. Flutter has no strut unless it is asked for.
  ///
  /// [force] pins every line to the role's line height: the figures branch holds one role in two faces (Manrope digits, Almarai or
  /// Manrope words), and a fallback face with another ascent/descent split would otherwise add 1 dp (an Arabic fact chip value
  /// measured 27 where the web line is 26). The rich branch only sets a minimum: its spans may be larger on purpose.
  static StrutStyle _strut(TextStyle style, {bool force = false}) =>
      StrutStyle.fromTextStyle(style, forceStrutHeight: force, leadingDistribution: TextLeadingDistribution.even);

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final style = gz.text(role).copyWith(color: color ?? gz.colors.textPrimary, decoration: TextDecoration.none);
    final over = overflow ?? (maxLines != null ? TextOverflow.ellipsis : null);
    final Widget text;
    if (span != null) {
      text = Text.rich(span!, style: style, strutStyle: _strut(style), maxLines: maxLines, overflow: over, textAlign: textAlign, softWrap: softWrap, semanticsLabel: semanticLabel);
    } else {
      var value = data!;
      if (role.uppercaseEn && !gz.isAr) value = value.toUpperCase();
      text = figures
          ? Text.rich(
              TextSpan(children: GzFigures.spans(context, value, role: role)),
              style: style,
              strutStyle: _strut(style, force: true),
              maxLines: maxLines,
              overflow: over,
              textAlign: textAlign,
              softWrap: softWrap,
              semanticsLabel: semanticLabel,
            )
          : Text(value, style: style, maxLines: maxLines, overflow: over, textAlign: textAlign, softWrap: softWrap, semanticsLabel: semanticLabel);
    }
    final snapped = GzChromeBaseline(style: style, paint: false, child: text);
    if (!header && !excludeSemantics) return snapped;
    return Semantics(header: header, excludeSemantics: excludeSemantics, child: snapped);
  }
}
