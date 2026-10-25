// ListingCard of HL-PROV-02 (web `provider/_components/ListingCard.tsx`): the system card's look with the row pinned to the card edges, and a
// plan line of its own. A fee-exempt major hotel has no plan to choose, so its line is empty; a plan with undecided rates says so.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

String rejectReason(AppL10n l, ListingRejectionCode c) => switch (c) {
  ListingRejectionCode.contentNotCompliant => l.hotelProviderRejectContent,
  ListingRejectionCode.wrongCategory => l.hotelProviderRejectCategory,
  ListingRejectionCode.missingDetails => l.hotelProviderRejectDetails,
  ListingRejectionCode.unclearPricing => l.hotelProviderRejectPricing,
  _ => l.hotelProviderRejectOther,
};

class ProvListingCard extends StatelessWidget {
  const ProvListingCard({required this.listing, required this.exempt, this.category, this.onOpen, super.key});

  final Listing listing;
  final bool exempt;
  final LocalizedText? category;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final g = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final k = listing;
    final planName = switch (k.planCycle) {
      AdPlanCycle.weekly => g.commonPlanWeekly,
      AdPlanCycle.monthly => g.commonPlanMonthly,
      AdPlanCycle.annual => g.commonPlanAnnual,
      _ => null,
    };
    var plan = '';
    if (!exempt) {
      final parts = <String>[?planName, if (k.endsOn != null) f.date(k.endsOn!.toJson(), DateStyle.short), if (k.billing.status == ListingBillingStatus.ratesPending) g.commonRatesSoon];
      plan = parts.join(' · ');
    }
    final code = k.status == ListingStatus.rejected ? k.rejection?.codes.firstOrNull : null;
    final cover = k.cover;
    final title = k.title.of(lang);
    final cat = category?.of(lang);
    final label = [title, ?cat, if (plan.isNotEmpty) plan].join(', ');
    final row = Padding(
      padding: const EdgeInsets.all(GzSpace.s3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: GzRadius.smAll,
            child: SizedBox(
              width: GzSize.thumbCompactWidth,
              height: GzSize.thumbCompactHeight,
              child: ColoredBox(
                color: c.surfacePlaceholder,
                child: cover == null
                    ? Center(child: GzIcon(GzIcons.megaphone, size: GzIconSize.md, color: c.textSecondary))
                    : GzPhoto(src: cover.baseUrl ?? cover.file, alt: cover.alt.of(lang)),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GzListingStatusPill(status: k.status),
                    if (k.sponsored && k.status == ListingStatus.active) GzBadge(label: g.commonLabelSponsored, variant: GzBadgeVariant.quiet),
                  ],
                ),
                const SizedBox(height: GzSpace.s1),
                GzText(title, role: GzTextRole.title, color: c.textStrong),
                if (cat != null) ...[const SizedBox(height: GzSpace.s1), GzText(cat, role: GzTextRole.caption, color: c.textSecondary)],
                if (plan.isNotEmpty) ...[const SizedBox(height: GzSpace.s1), GzText(plan, role: GzTextRole.caption, color: c.textSecondary, figures: true)],
                if (code != null) ...[
                  const SizedBox(height: GzSpace.s1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 3), child: GzIcon(GzIcons.info, size: GzIconSize.xs, color: c.iconDanger)),
                      const SizedBox(width: GzSpace.s1),
                      Flexible(child: GzText(rejectReason(l, code), role: GzTextRole.caption, color: c.textDanger)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.textSecondary),
        ],
      ),
    );
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
        child: GzPressable(onPressed: onOpen ?? () {}, semanticLabel: label, borderRadius: GzRadius.mdAll, minHeight: 0, child: row),
      ),
    );
  }
}
