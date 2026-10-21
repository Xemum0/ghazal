import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'hotel_bits.dart';

/// Small private helpers of the hotel part C components (not exported).

/// The style of user-typed text: its own script's role scale (an Arabic name in the English UI takes the Arabic scale).
TextStyle gzUserStyle(String text, GzTextRole role, Color color) =>
    GzType.style(Locale(gzScriptOf(text)), role).copyWith(color: color, decoration: TextDecoration.none);

/// The base direction of the paragraph is the SCREEN's (lines start at the screen start edge) while the text itself is an isolate that
/// orders by its own first strong letter: the web `<bdi dir="auto">` inside a block (an Arabic review in the English UI starts at the
/// left, its closing full stop stays inside the Arabic run).
String gzIsolateAuto(String text) => '\u2068$text\u2069';

/// User-typed text (names, review bodies, replies) in its own script's type scale, aligned to the screen's start edge.
class GzUserBlock extends StatelessWidget {
  const GzUserBlock(this.text, {required this.role, required this.color, this.maxLines, super.key});

  final String text;
  final GzTextRole role;
  final Color color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: Text(
        gzIsolateAuto(text),
        style: gzUserStyle(text, role, color),
        textDirection: Directionality.of(context),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

/// User text that sits at the INLINE END of its box (the web `dd { text-align: end }` around a `<bdi dir="auto">`). Shrink-wrapped.
class GzUserTextEnd extends StatelessWidget {
  const GzUserTextEnd(this.text, {required this.role, required this.color, super.key});

  final String text;
  final GzTextRole role;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    heightFactor: 1,
    child: Text(gzIsolateAuto(text), style: gzUserStyle(text, role, color), textDirection: Directionality.of(context)),
  );
}

/// A hairline-bottomed row border (the ruled list look shared by staff, hours, package and review rows).
BoxDecoration gzRuleBelow(GzColors c, {bool last = false}) => BoxDecoration(
  border: Border(
    bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair),
  ),
);

/// Running text with figures islands (the web `Figures`) whose every line keeps the role's own line height: the web block carries a
/// strut, so a line that holds only a number (`2026` wrapped onto its own line, a figures face with another line height) is still one
/// full line high; Flutter has no strut unless it is asked for.
class GzFigText extends StatelessWidget {
  const GzFigText(this.text, {required this.role, this.color, this.maxLines, this.textAlign, super.key});

  final String text;
  final GzTextRole role;
  final Color? color;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final style = gz.text(role).copyWith(color: color ?? gz.colors.textPrimary, decoration: TextDecoration.none);
    return Text.rich(
      TextSpan(children: GzFigures.spans(context, text, role: role)),
      style: style,
      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: false, leadingDistribution: TextLeadingDistribution.even),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
    );
  }
}
