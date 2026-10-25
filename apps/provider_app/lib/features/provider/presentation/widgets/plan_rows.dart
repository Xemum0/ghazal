// PlanRows (web `PlanRows.tsx`): the three plans as compact single-choice rows. One line each: bead, name, period, and the rate when one exists
// (through the formatter, exact mode). While rates are undecided the row shows an hourglass and never a number.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle;
import 'package:ghazal_ui/ghazal_ui.dart';

String planName(GzL10n g, AdPlanCycle c) => switch (c) {
  AdPlanCycle.weekly => g.commonPlanWeekly,
  AdPlanCycle.monthly => g.commonPlanMonthly,
  _ => g.commonPlanAnnual,
};

class PlanRows extends StatelessWidget {
  const PlanRows({required this.cycles, required this.periodDays, required this.rate, required this.chosen, required this.onChoose, required this.label, super.key});

  final List<AdPlanCycle> cycles;
  final int Function(AdPlanCycle) periodDays;
  final int? Function(AdPlanCycle) rate;
  final AdPlanCycle? chosen;
  final ValueChanged<AdPlanCycle> onChoose;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final g = context.gzL10n;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cycles.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s2),
            Builder(builder: (context) {
              final cy = cycles[i];
              final fils = rate(cy);
              final on = chosen == cy;
              final name = planName(g, cy);
              return GzPressable(
                onPressed: () => onChoose(cy),
                semanticLabel: name,
                selected: on,
                borderRadius: GzRadius.mdAll,
                minHeight: GzSize.controlLg,
                scale: 1,
                child: Container(
                  constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s2),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: GzRadius.mdAll,
                    border: Border.all(color: on ? c.controlChipBorderSelected : c.controlChipBorder, width: on ? GzStroke.focus : GzStroke.hair),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: GzSpace.s5,
                        height: GzSpace.s5,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
                        child: on ? const Center(child: GzBeadBox()) : null,
                      ),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: GzSpace.s3,
                          children: [
                            GzText(name, role: GzTextRole.title, color: c.textStrong),
                            GzText(g.commonCountDays(periodDays(cy)), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                          ],
                        ),
                      ),
                      if (fils != null)
                        GzText(f.money(fils, const MoneyOptions(mode: MoneyMode.exact)), role: GzTextRole.title, color: c.textStrong, figures: true)
                      else
                        GzIcon(GzIcons.hourglass, size: GzIconSize.md, color: c.iconSecondary, semanticLabel: g.commonRatesSoon),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
