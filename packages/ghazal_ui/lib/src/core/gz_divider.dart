import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_draw_once.dart';
import 'gz_preview.dart';

enum GzDividerTone { hairline, strong, onDark }

/// Divider: the 1 dp ink hairline (line / line-strong / on-dark). Structure, not signature. Horizontal it takes the width it is
/// given; [vertical] is a rule between two inline items (a facts row) and needs a [height] or an `IntrinsicHeight` parent.
class GzDivider extends StatelessWidget {
  const GzDivider({this.tone = GzDividerTone.hairline, this.vertical = false, this.height, super.key});

  final GzDividerTone tone;
  final bool vertical;

  /// Vertical rules only.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final color = switch (tone) {
      GzDividerTone.hairline => c.borderHairline,
      GzDividerTone.strong => c.borderStrong,
      GzDividerTone.onDark => c.borderOnDark,
    };
    return ExcludeSemantics(
      child: vertical
          ? Container(width: GzStroke.hair, height: height, color: color)
          : Container(height: GzStroke.hair, color: color),
    );
  }
}

/// khayt = 24 x 1 at a section head or under a selected tab; full = spans the row (hero crown, partner header band);
/// knot = a full line that ends in the 8 dp bead (it follows reading direction).
enum GzThreadRuleVariant { khayt, full, knot }

/// ThreadRule: the gold hairline, the khayt (direction rules 2 and 5). It marks a place or a state, never decoration. It draws on
/// once, from inline-start, over 480 ms; reduced motion keeps the finished line.
class GzThreadRule extends StatelessWidget {
  const GzThreadRule({this.variant = GzThreadRuleVariant.khayt, this.draw = GzDraw.inview, super.key});

  final GzThreadRuleVariant variant;

  /// `mount` and `inview` draw when first built (a lazy list builds it as it scrolls in); `off` shows the finished line.
  final GzDraw draw;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final animate = draw != GzDraw.off;
    final line = GzDrawOnce(enabled: animate, child: Container(height: GzStroke.khayt, color: c.markKhayt));
    final Widget body = switch (variant) {
      GzThreadRuleVariant.khayt => SizedBox(width: GzSize.khaytWidth, child: line),
      GzThreadRuleVariant.full => line,
      GzThreadRuleVariant.knot => Row(
          children: [
            Expanded(child: line),
            GzFadeInOnce(enabled: animate, delay: GzMotion.durationExpressive, child: const GzBeadBox()),
          ],
        ),
    };
    return ExcludeSemantics(child: body);
  }
}
