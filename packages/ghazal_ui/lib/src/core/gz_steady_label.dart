import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// A label that never changes width when it turns heavy (the selected 500 weight of a chip or a tab).
///
/// The web reserves that width with a hidden duplicate of the label (`.gz-chip__ghost`). A hidden duplicate in a widget tree doubles
/// every `find.text`, takes the taps of tests and assistive tools and doubles the words of a text dump, so here the heavy width is
/// measured once with a [TextPainter] (same style, same text scale, same direction) and used as a MINIMUM width: the label is drawn
/// once, centred, and the box never changes size when [selected] flips.
///
/// [span] carries the content (plain text, figure islands, a muted count); its own styles win over [style]. [style] is the LIGHT style
/// with the colour already chosen. [fit] ellipsizes the label instead of overflowing when the cell is narrower than the text.
///
/// [leading] is a glyph that belongs to the label (the web `glyphLabel` of a ChipGroup option: the icon and the words are one label,
/// so the whole group is centred in the reserved width); [leadingExtent] is its width including the gap before the words.
class GzSteadyLabel extends StatelessWidget {
  const GzSteadyLabel({required this.span, required this.style, required this.selected, this.fit = false, this.leading, this.leadingExtent = 0, super.key});

  final InlineSpan span;
  final TextStyle style;
  final bool selected;
  final bool fit;
  final Widget? leading;
  final double leadingExtent;

  /// The width of [span] at [weight] in [style], laid out on one line with the ambient text scale and direction.
  static double widthOf(BuildContext context, InlineSpan span, TextStyle style, FontWeight? weight) {
    final painter = TextPainter(
      text: TextSpan(style: style.copyWith(fontWeight: weight, decoration: TextDecoration.none), children: [span]),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final heavy = context.gz.text(GzTextRole.title).fontWeight;
    final light = style.copyWith(decoration: TextDecoration.none);
    final reserve = style.fontWeight == heavy ? 0.0 : widthOf(context, span, light, heavy) + leadingExtent;
    final text = AnimatedDefaultTextStyle(
      duration: GzMotion.durationBase,
      curve: GzMotion.easeStandard,
      style: light.copyWith(fontWeight: selected ? heavy : style.fontWeight),
      child: Text.rich(span, softWrap: false, maxLines: 1, overflow: fit ? TextOverflow.ellipsis : null),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: reserve),
      child: Center(
        widthFactor: 1,
        child: leading == null
            ? text
            : Row(mainAxisSize: MainAxisSize.min, children: [leading!, if (fit) Flexible(child: text) else text]),
      ),
    );
  }
}
