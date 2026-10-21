import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle, Listing, ListingBillingStatus, ListingRejectionCode, ListingStatus, LocalizedText;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/overlays.dart';
import 'gz_listing_status_pill.dart';

void _noop() {}

/// ProviderListingCard (HL-PROV list): one advertisement of the provider as the Partner app shows it. A compact cover thumbnail
/// (72 x 88), the lifecycle pill, the title (as typed), the category, then the plan line (cycle and end date, or the honest "Rates
/// announced soon" / "Exempt") and, when the moderator said no, the first reason in plain words. It never shows a number the Super
/// Admin has not set. With [onOpen] the whole card is one target and a chevron closes the row.
class GzProviderListingCard extends StatelessWidget {
  const GzProviderListingCard({required this.listing, this.categoryName, this.exempt = false, this.onOpen, super.key});

  final Listing listing;

  /// The listing's service category name (the screen reads it from the category list; the card never fetches).
  final LocalizedText? categoryName;

  /// The partner is a major hotel: the plan line reads "Exempt".
  final bool exempt;
  final VoidCallback? onOpen;

  static String _reason(GzL10n l, ListingRejectionCode code) => switch (code) {
    ListingRejectionCode.contentNotCompliant => l.uiProviderListingRejectContentNotCompliant,
    ListingRejectionCode.wrongCategory => l.uiProviderListingRejectWrongCategory,
    ListingRejectionCode.missingDetails => l.uiProviderListingRejectMissingDetails,
    ListingRejectionCode.unclearPricing => l.uiProviderListingRejectUnclearPricing,
    ListingRejectionCode.other || ListingRejectionCode.unknown => l.uiProviderListingRejectOther,
  };

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final k = listing;
    final title = k.title.of(lang);
    final category = categoryName?.of(lang);
    final planName = switch (k.planCycle) {
      AdPlanCycle.weekly => l.commonPlanWeekly,
      AdPlanCycle.monthly => l.commonPlanMonthly,
      AdPlanCycle.annual => l.commonPlanAnnual,
      _ => null,
    };
    final billing = exempt ? l.commonExempt : (k.billing.status == ListingBillingStatus.ratesPending ? l.commonRatesSoon : null);
    final planParts = [
      ?planName,
      if (k.endsOn != null)
        l.uiProviderListingEndsOn(f.date(k.endsOn!.toJson(), DateStyle.short))
      else if (k.planCycle != null)
        l.uiProviderListingStartsAfter,
    ];
    final planText = planParts.isEmpty ? l.uiProviderListingNoPlan : planParts.join(' · ');
    final code = k.status == ListingStatus.rejected ? k.rejection?.codes.firstOrNull : null;
    final reason = code == null ? null : _reason(l, code);
    final waiting = reason == null && k.status == ListingStatus.pendingReview;
    final status = gzListingState(k.status);
    final cover = k.cover;

    final planStyle = gz.text(GzTextRole.caption);
    final body = Row(
      children: [
        _Thumb(src: cover == null ? null : (cover.baseUrl ?? cover.file), alt: cover?.alt.of(lang) ?? ''),
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
                  if (k.sponsored && k.status == ListingStatus.active) GzBadge(label: l.commonLabelSponsored, variant: GzBadgeVariant.quiet),
                ],
              ),
              const SizedBox(height: GzSpace.s1),
              GzText(title, role: GzTextRole.title, color: c.textStrong),
              if (category != null) ...[
                const SizedBox(height: GzSpace.s1),
                GzText(category, role: GzTextRole.caption, color: c.textSecondary),
              ],
              const SizedBox(height: GzSpace.s1),
              Text.rich(
                TextSpan(
                  style: planStyle.copyWith(color: c.textSecondary),
                  children: [
                    ...GzFigures.spans(context, planText, role: GzTextRole.caption),
                    if (billing != null) ...[
                      const TextSpan(text: ' · '),
                      TextSpan(text: billing, style: TextStyle(color: c.textPrimary, fontWeight: gz.text(GzTextRole.title).fontWeight)),
                    ],
                  ],
                ),
              ),
              if (reason != null || waiting) ...[
                const SizedBox(height: GzSpace.s1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: GzIcon(waiting ? GzIcons.clock : GzIcons.info, size: GzIconSize.xs, color: waiting ? c.textSecondary : c.textDanger),
                    ),
                    const SizedBox(width: GzSpace.s1),
                    Flexible(child: GzText(reason ?? l.uiProviderListingReview, role: GzTextRole.caption, color: waiting ? c.textSecondary : c.textDanger)),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (onOpen != null) ...[
          const SizedBox(width: GzSpace.s3),
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.textSecondary),
        ],
      ],
    );

    final label = [status.label(l, GzStatusAudience.hotel), title, ?category, planText, ?billing, ?reason, if (waiting) l.uiProviderListingReview].join(', ');
    final padded = Padding(padding: const EdgeInsets.all(GzSpace.s3), child: body);
    // The web row is a <button>: it shrinks to its content (a short plan line leaves the chevron next to the text) and is capped by the
    // card; a plain row (no onOpen) is a block and fills the card.
    final pressable = onOpen == null
        ? null
        : Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: IntrinsicWidth(
              child: GzPressable(onPressed: onOpen ?? _noop, semanticLabel: label, borderRadius: GzRadius.mdAll, minHeight: 0, child: padded),
            ),
          );
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: pressable ?? Semantics(container: true, label: label, excludeSemantics: true, child: padded),
      ),
    );
  }
}

/// The 72 x 88 cover: the photograph, or the quiet placeholder with a megaphone when the listing has none yet.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.src, required this.alt});

  final String? src;
  final String alt;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ClipRRect(
      borderRadius: GzRadius.smAll,
      child: SizedBox(
        width: GzSize.thumbCompactWidth,
        height: GzSize.thumbCompactHeight,
        child: ColoredBox(
          color: c.surfacePlaceholder,
          child: src == null
              ? Center(child: GzIcon(GzIcons.megaphone, size: GzIconSize.md, color: c.textSecondary))
              : GzPhoto(src: src!, alt: alt),
        ),
      ),
    );
  }
}
