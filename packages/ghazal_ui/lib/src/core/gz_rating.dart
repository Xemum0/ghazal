import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DecimalOptions;

import '../foundation.dart';
import 'gz_fig_text.dart';
import 'gz_format_scope.dart';

enum GzRatingVariant { compact, stars }

/// Rating: the star, the figure and the count as separate items (ADR 0010 D5), never one concatenated string. Stars are
/// informative gold glyphs (gold-700). `compact` = one star + value (+ count); `stars` = the five-star row filled to the value
/// (the fill grows from inline-start, so it mirrors in Arabic with the row).
class GzRating extends StatelessWidget {
  const GzRating({
    required this.value,
    this.count,
    this.variant = GzRatingVariant.compact,
    this.showValue = true,
    this.max = 5,
    super.key,
  });

  /// 0 to [max]; one decimal is shown.
  final double value;

  /// Number of reviews, shown as (212) after the value.
  final int? count;
  final GzRatingVariant variant;

  /// Print the figure next to the stars (default). Off where a large average already stands beside them.
  final bool showValue;
  final int max;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final shown = f.number(
      value,
      const DecimalOptions(minFraction: 1, maxFraction: 1),
    );
    final name = context.gzL10n.commonA11yRating(
      (value * 10).round() / 10,
      max,
    );
    final countText = count == null ? null : '(${f.integer(count!)})';
    final valueText = gzFigText(
      context,
      shown,
      role: GzTextRole.figBodyS,
      weight: gz.text(GzTextRole.price).fontWeight,
      color: c.textStrong,
    );
    final countWidget = countText == null
        ? null
        : gzFigText(
            context,
            countText,
            role: GzTextRole.figCaption,
            color: c.textSecondary,
          );

    Widget star(Color color) =>
        GzIcon(GzIcons.starFill, size: GzIconSize.xs, color: color);
    final Widget stars;
    if (variant == GzRatingVariant.stars) {
      const star16 = GzSize.iconXs;
      const gap = GzSpace.s1;
      final whole = value.floor();
      final filled = (whole * (star16 + gap) + (value - whole) * star16).clamp(
        0.0,
        max * (star16 + gap) - gap,
      );
      Widget row(Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            star(color),
          ],
        ],
      );
      // The prototype's star row sits 1 dp lower than the figure beside it (measured on the reference render); the compact star does not.
      stars = Transform.translate(
        offset: const Offset(0, 1),
        child: Stack(
          children: [
            row(c.markTrack),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: filled,
              child: ClipRect(
                child: OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: 0,
                  maxWidth: max * (star16 + gap),
                  child: row(c.iconAccent),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      stars = star(c.iconAccent);
    }
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          stars,
          if (variant == GzRatingVariant.compact || showValue) ...[
            const SizedBox(width: GzSpace.s1),
            valueText,
          ],
          if (countWidget != null) ...[
            const SizedBox(width: GzSpace.s1),
            countWidget,
          ],
        ],
      ),
    );
  }
}
