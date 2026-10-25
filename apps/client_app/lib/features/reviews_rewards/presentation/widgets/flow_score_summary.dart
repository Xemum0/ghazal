import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show RatingSummary;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The venue's score as a figure, five stars, the review count as a quiet chat
/// glyph and figure, and the four category scores as glyph + gold bar +
/// figure with no words (the glyph is the category, the word is its
/// accessible name). Flow-local twin of the system `GzRatingSummary`, which
/// still prints the four category words and a "212 reviews" caption.
class FlowScoreSummary extends StatelessWidget {
  const FlowScoreSummary({required this.rating, super.key});

  final RatingSummary rating;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final average = rating.average;
    if (average == null || rating.count == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(context.gzL10n.commonLabelNew, role: GzTextRole.d2, color: c.textPrimary),
          const SizedBox(height: GzSpace.s2),
          GzText(l.clientReviewsRewardsListInfoNew, role: GzTextRole.bodyS, color: c.textSecondary),
        ],
      );
    }
    const one = DecimalOptions(minFraction: 1, maxFraction: 1);
    final cats = rating.categories;
    final rows = cats == null
        ? const <(String, IconData, double)>[]
        : [
            (l.clientReviewsRewardsWriteCatVenue, GzIcons.hall, cats.venue),
            (l.clientReviewsRewardsWriteCatFood, GzIcons.catering, cats.food),
            (l.clientReviewsRewardsWriteCatService, GzIcons.staff, cats.service),
            (l.clientReviewsRewardsWriteCatValue, GzIcons.coins, cats.value),
          ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              label: context.gzL10n.commonA11yRating((average * 10).round() / 10, 5),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    gzFigText(context, f.number(average, one), role: GzTextRole.fig3xl, color: c.textStrong),
                    const SizedBox(height: GzSpace.s1),
                    GzRating(value: average, variant: GzRatingVariant.stars, showValue: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s1),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GzFactChip(icon: GzIcons.chatText, label: l.clientReviewsRewardsListTitle, value: f.integer(rating.count), tone: GzFactTone.muted),
                  const SizedBox(width: GzSpace.s1),
                  GzInfoButton(
                    title: l.clientReviewsRewardsListInfoTitle,
                    paragraphs: [l.clientReviewsRewardsListInfoReal, l.clientReviewsRewardsListInfoVenue],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(width: GzSpace.s6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s4),
                  _Bar(label: rows[i].$1, icon: rows[i].$2, value: rows[i].$3),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.icon, required this.value});

  final String label;
  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final shown = f.number(value, const DecimalOptions(minFraction: 1, maxFraction: 1));
    final fill = (value * 100).round();
    final rest = ((5 - value) * 100).round();
    return Semantics(
      label: '$label: $shown',
      excludeSemantics: true,
      child: Row(
        children: [
          GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: SizedBox(
              height: GzStroke.thread,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fill > 0)
                    Expanded(
                      flex: fill,
                      child: ColoredBox(color: c.markKhayt),
                    ),
                  if (rest > 0)
                    Expanded(
                      flex: rest,
                      child: ColoredBox(color: c.markTrack),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          SizedBox(
            width: GzSpace.s6,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: gzFigText(context, shown, role: GzTextRole.figCaption, color: c.textStrong),
            ),
          ),
        ],
      ),
    );
  }
}
