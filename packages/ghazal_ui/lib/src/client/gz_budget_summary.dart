import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Budget, BudgetCategory;

import '../core/core.dart';
import '../foundation.dart';

/// BudgetSummary (CA-BUD): the total, a stacked bar (paid in ink, committed in gold, the rest on the track), what each means in words,
/// category rows with their own bars, and an alert when a category or the whole budget goes over. Money is integer fils from the
/// [Budget] model; the bars are flex ratios of those fils.
class GzBudgetSummary extends StatelessWidget {
  const GzBudgetSummary({required this.budget, super.key});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    var paid = 0, committed = 0;
    for (final cat in budget.categories) {
      paid += cat.paid.fils;
      committed += cat.committed.fils;
    }
    final total = budget.total.fils;
    final remaining = total - paid - committed;
    final overTotal = remaining < 0;
    final overCats = budget.categories.where((x) => x.paid.fils + x.committed.fils > x.allocated.fils).toList();
    final scale = [total, paid + committed, 1].reduce((a, b) => a > b ? a : b);
    final rest = remaining < 0 ? 0 : remaining;

    Widget stat(String label, int fils, Color swatch) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
                child: const SizedBox(width: GzSpace.s2, height: GzSpace.s2),
              ),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzText(label, role: GzTextRole.caption, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s1),
          GzPrice(fils: fils, size: GzPriceSize.strong),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: l.uiClientBudgetTotal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Expanded(
                child: GzText(l.uiClientBudgetTotal, role: GzTextRole.caption, color: c.textSecondary),
              ),
              const SizedBox(width: GzSpace.s3),
              GzPrice(fils: total, size: GzPriceSize.total),
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          Semantics(
            image: true,
            excludeSemantics: true,
            label: l.uiClientBudgetBarLabel(
              l.uiClientBudgetPaid,
              f.money(paid),
              l.uiClientBudgetCommitted,
              f.money(committed),
              l.uiClientBudgetRemaining,
              f.money(rest),
            ),
            child: _bar(
              context,
              paid: paid,
              committed: committed,
              rest: scale - paid - committed < 0 ? 0 : scale - paid - committed,
              height: GzStroke.threadMax,
            ),
          ),
          const SizedBox(height: GzSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(l.uiClientBudgetPaid, paid, c.surfaceDarkRaised),
              const SizedBox(width: GzSpace.s3),
              stat(l.uiClientBudgetCommitted, committed, c.markKhayt),
              const SizedBox(width: GzSpace.s3),
              stat(l.uiClientBudgetRemaining, rest, c.markTrack),
            ],
          ),
          if (overTotal || overCats.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s4),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(GzSpace.s3),
                decoration: BoxDecoration(color: c.statusDangerBg, borderRadius: GzRadius.smAll),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: GzIcon(GzIcons.warningCircle, size: GzIconSize.sm, color: c.iconDanger),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: GzText(
                        overTotal ? l.uiClientBudgetAlertTotal : l.uiClientBudgetAlertCategory(overCats.first.name.of(lang)),
                        role: GzTextRole.bodyS,
                        color: c.textDanger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: GzSpace.s4),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            padding: const EdgeInsets.only(top: GzSpace.s4),
            child: GzText(l.uiClientBudgetCategories, role: GzTextRole.caption, color: c.textPrimary, header: true),
          ),
          const SizedBox(height: GzSpace.s4),
          for (final cat in budget.categories) _BudgetRow(category: cat),
        ],
      ),
    );
  }
}

/// The stacked bar: three flex segments (paid, committed, rest), 2 dp apart, flex by integer fils (a zero segment keeps its gap, like the web).
Widget _bar(BuildContext context, {required int paid, required int committed, required int rest, required double height}) {
  final c = context.gz.colors;
  Widget seg(int flex, Color color) => flex > 0
      ? Expanded(
          flex: flex,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: GzRadius.pillAll),
          ),
        )
      : const SizedBox.shrink();
  return SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        seg(paid, c.surfaceDarkRaised),
        const SizedBox(width: GzStroke.thread),
        seg(committed, c.markKhayt),
        const SizedBox(width: GzStroke.thread),
        seg(rest, c.markTrack),
      ],
    ),
  );
}

const Map<String, String> _categoryIcon = {
  'hall': 'hall',
  'camera': 'camera',
  'flower': 'flower',
  'dress': 'dress',
  'brush': 'sparkle',
  'car': 'car',
  'mail': 'mail',
  'music': 'music',
  'plane': 'sparkle',
};

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final used = category.paid.fils + category.committed.fils;
    final over = used > category.allocated.fils;
    final top = [category.allocated.fils, used, 1].reduce((a, b) => a > b ? a : b);
    final icon = GzIcons.byName[_categoryIcon[category.icon] ?? ''] ?? GzIcons.coins;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
            child: SizedBox(
              width: GzSize.thumbSm,
              height: GzSize.thumbSm,
              child: Center(
                child: GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(category.name.of(lang), role: GzTextRole.bodyS, color: c.textStrong),
                const SizedBox(height: GzSpace.s1),
                _bar(context, paid: category.paid.fils, committed: category.committed.fils, rest: top - used < 0 ? 0 : top - used, height: GzStroke.thread),
                const SizedBox(height: GzSpace.s1),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s1,
                  children: [
                    if (category.autoLinked) GzText('${l.uiClientBudgetLinked} ·', role: GzTextRole.caption, color: c.textSecondary),
                    GzText(
                      l.uiClientBudgetOf(f.money(used), f.money(category.allocated.fils)),
                      role: GzTextRole.caption,
                      color: c.textSecondary,
                      figures: true,
                    ),
                    if (over)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                          const SizedBox(width: GzSpace.s1),
                          GzText(l.uiClientBudgetOver(f.money(used - category.allocated.fils)), role: GzTextRole.caption, color: c.textDanger, figures: true),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
