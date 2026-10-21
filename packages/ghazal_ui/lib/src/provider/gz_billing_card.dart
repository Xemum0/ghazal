import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle, BillingView, PartnerBillingMode;

import '../foundation.dart';
import 'gz_major_hotel_badge.dart';

/// BillingCard (HL-SETT-04, HL-PROV-04; ADR 0035 D7): how a partner pays Ghazal. Two variants and never a price:
/// `plan` (service providers: the chosen cycle and "Rates announced soon" until the Super Admin sets rates) and `contract`
/// (hotels and halls: a Business contract card, the one-line "terms as contracted", no plan picker). A major hotel adds the
/// [GzMajorHotelBadge]. The card is a fact, not a button: the screen owns any action.
class GzBillingCard extends StatelessWidget {
  const GzBillingCard({required this.billing, this.majorHotel, super.key});

  final BillingView billing;

  /// Major hotel: adds the exempt marker. Default: the account's own flag (`billing.majorHotel`).
  final bool? majorHotel;

  static String _cycleName(GzL10n l, AdPlanCycle c) => switch (c) {
    AdPlanCycle.weekly => l.commonPlanWeekly,
    AdPlanCycle.monthly => l.commonPlanMonthly,
    AdPlanCycle.annual => l.commonPlanAnnual,
    AdPlanCycle.unknown => l.commonBillingPlan,
  };

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final contract = billing.mode == PartnerBillingMode.contract;
    final cycle = billing.plan?.cycle;
    final lang = gz.locale.languageCode;
    final title = contract ? l.commonBillingContract : (cycle != null ? _cycleName(l, cycle) : l.commonBillingPlan);
    // The rates-soon line shows while the chosen cycle has no rate set (the only state the product has today).
    final rate = cycle == null ? null : billing.plans.where((p) => p.plan.cycle == cycle).firstOrNull?.plan.ratesFils;
    final soon = !contract && rate == null;
    final summary = billing.contractSummary;
    final line = contract ? (summary != null ? summary.of(lang) : l.commonBillingContractTerms) : (soon ? l.commonRatesSoon : '');
    return Semantics(
      container: true,
      label: contract ? l.commonBillingContract : l.commonBillingPlan,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GzSpace.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: GzSpace.s3,
                  runSpacing: GzSpace.s3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(contract ? GzIcons.notes : GzIcons.megaphone, size: GzIconSize.md, color: c.textSecondary),
                        const SizedBox(width: GzSpace.s3),
                        GzText(title, role: GzTextRole.title, color: c.textStrong),
                      ],
                    ),
                    if (majorHotel ?? billing.majorHotel) const GzMajorHotelBadge(),
                  ],
                ),
              ),
              const SizedBox(height: GzSpace.s3),
              if (!contract && soon)
                Row(
                  children: [
                    GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.textSecondary),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(child: GzText(line, role: GzTextRole.bodyS, color: c.textSecondary)),
                  ],
                )
              else
                GzText(line, role: GzTextRole.bodyS, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
