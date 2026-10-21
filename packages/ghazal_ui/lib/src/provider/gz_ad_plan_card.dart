import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlan, AdPlanCycle;

import '../core/core.dart';
import '../foundation.dart';

void _noop() {}

/// AdPlanCard (HL-PROV plan step, ADR 0033 D8): one advertising plan, weekly, monthly or annual, in the Chip grammar (1 dp hairline,
/// selected = ink border and a gold bead) and taller because it carries a price line. The rates are NOT decided: a plan without a
/// rate says "Rates announced soon" and never a number; a rate shows only after the Super Admin sets it. For a major hotel
/// ([exempt]) the card says "Exempt" and nothing is payable. A plan is chosen, not bought: the listing still waits for review.
/// States: default, selected, rates soon, rate set, exempt, disabled ([disabled]).
class GzAdPlanCard extends StatelessWidget {
  const GzAdPlanCard({
    required this.plan,
    this.selected = false,
    this.exempt = false,
    this.disabled = false,
    this.onSelect,
    super.key,
  });

  final AdPlan plan;
  final bool selected;

  /// Major hotel: exempt, no rate, nothing to pay.
  final bool exempt;
  final bool disabled;
  final VoidCallback? onSelect;

  static String _name(GzL10n l, AdPlanCycle c) => switch (c) {
    AdPlanCycle.weekly => l.commonPlanWeekly,
    AdPlanCycle.monthly => l.commonPlanMonthly,
    AdPlanCycle.annual => l.commonPlanAnnual,
    AdPlanCycle.unknown => l.commonBillingPlan,
  };

  static String _period(GzL10n l, AdPlanCycle c) => switch (c) {
    AdPlanCycle.weekly => l.uiProviderAdPlanWeek,
    AdPlanCycle.monthly => l.uiProviderAdPlanMonth,
    AdPlanCycle.annual || AdPlanCycle.unknown => l.uiProviderAdPlanYear,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final name = _name(l, plan.cycle);
    final rate = plan.ratesFils;
    final off = disabled;
    return GzPressable(
      onPressed: off ? null : (onSelect ?? _noop),
      semanticLabel: l.uiProviderAdPlanChoose(name),
      selected: selected,
      borderRadius: GzRadius.mdAll,
      minHeight: GzSize.rowMin,
      builder: (context, st) {
        final border = !st.enabled
            ? c.borderHairline
            : (selected ? c.controlChipBorderSelected : c.controlChipBorder);
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(
              color: border,
              width: selected ? GzStroke.focus : GzStroke.hair,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(GzSpace.panelPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Radio(selected: selected),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: GzText(
                        name,
                        role: GzTextRole.title,
                        color: st.enabled ? c.textStrong : c.textDisabled,
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    GzText(
                      l.commonCountDays(plan.periodDays),
                      role: GzTextRole.caption,
                      color: c.textSecondary,
                      figures: true,
                    ),
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: GzSpace.s8),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: exempt
                        ? _exempt(context, l)
                        : rate == null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GzIcon(
                                GzIcons.clock,
                                size: GzIconSize.xs,
                                color: c.textSecondary,
                              ),
                              const SizedBox(width: GzSpace.s2),
                              Flexible(
                                child: GzText(
                                  l.commonRatesSoon,
                                  role: GzTextRole.bodyS,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              GzPrice(fils: rate, size: GzPriceSize.total),
                              const SizedBox(width: GzSpace.s2),
                              Flexible(
                                child: GzText(
                                  l.uiProviderAdPlanPerPeriod(
                                    _period(l, plan.cycle),
                                  ),
                                  role: GzTextRole.caption,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: GzSpace.s3),
                GzText(
                  l.uiProviderAdPlanStarts,
                  role: GzTextRole.caption,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exempt(BuildContext context, GzL10n l) {
    final c = context.gz.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.statusSuccessBg,
            borderRadius: GzRadius.xsAll,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.pillMin),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: GzSpace.s2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(
                    GzIcons.check,
                    size: GzIconSize.xs,
                    color: c.iconSuccess,
                  ),
                  const SizedBox(width: GzSpace.s1),
                  GzText(
                    l.commonExempt,
                    role: GzTextRole.pill,
                    color: c.statusSuccessText,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        Flexible(
          child: GzText(
            l.uiProviderAdPlanExemptBody,
            role: GzTextRole.caption,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The 20 dp radio ring of the card (a gold bead when chosen), decorative: the card is the one control.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      width: GzSize.iconSm,
      height: GzSize.iconSm,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.controlChipBorderSelected : c.borderControl,
          width: GzStroke.icon,
        ),
      ),
      child: selected ? const GzBead() : null,
    );
  }
}
