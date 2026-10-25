// HL-PROV-06 Review status (web `HL-PROV-06.tsx`): where a listing is in manual review. Pending (what to expect), Approved or Live (until when),
// Not approved with reason chips and the moderator's note, and the way to edit and resubmit. Payment never publishes a listing.
// Requirements: PA-REV-01..05, PA-ADS-07.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/provider_data.dart';
import 'widgets/prov_bits.dart';

const List<ListingStatus> _prefer = [ListingStatus.pendingReview, ListingStatus.approved, ListingStatus.rejected, ListingStatus.active];

class HlProv06Screen extends ConsumerWidget {
  const HlProv06Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final id = nav.params['listingId'] as String? ?? kHeroReviewListingId;
    final value = ref.watch(pickedListingProvider(ListingPick(id, _prefer)));
    final billing = ref.watch(partnerBillingProvider).value;
    final exempt = billing?.feeExempt ?? false;
    final k = value.value;

    GzActionBar? bottom;
    if (k != null) {
      final rejected = k.status == ListingStatus.rejected;
      final live = k.status == ListingStatus.active || k.status == ListingStatus.approved;
      bottom = GzActionBar(
        action: GzActionBarAction(
          label: rejected ? l.hotelProviderEditResubmit : live ? l.hotelProviderViewPerformance : l.hotelProviderBackToListings,
          iconEnd: rejected || live ? GzIcons.chevronRight : null,
          onPressed: () {
            if (rejected) {
              nav.push('HL-PROV-03', params: {'listingId': k.id});
            } else if (live) {
              nav.push('HL-PROV-07', params: {'listingId': k.id});
            } else {
              nav.reset('HL-PROV-02');
            }
          },
        ),
      );
    }

    return GzScreen(
      top: GzTopBar(title: l.hotelProviderReviewTitle),
      bottom: bottom,
      child: GzAsyncView<Listing?>(
        value: value,
        isEmpty: (v) => v == null,
        loading: const _Skeleton(),
        onRetry: () => ref.invalidate(pickedListingProvider),
        data: (v) => _Body(listing: v!, exempt: exempt),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.listing, required this.exempt});

  final Listing listing;
  final bool exempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final k = listing;
    final now = ref.watch(clockProvider)();
    final today = dayOf(f, now);
    final waited = k.submittedAt == null ? 0 : now.difference(k.submittedAt!).inHours;
    final longWait = k.status == ListingStatus.pendingReview && waited >= kLongWaitHours;
    final isLive = k.status == ListingStatus.active;
    final rejected = k.status == ListingStatus.rejected;
    final days = daysLeft(today, k.endsOn);
    final (art, success, title, date) = rejected
        ? (GzIllustrationName.warning, false, l.hotelProviderHeadRejectedTitle, null as LocalDate?)
        : k.status == ListingStatus.approved
            ? (GzIllustrationName.seal, true, l.hotelProviderHeadApprovedTitle, k.endsOn)
            : isLive
                ? (GzIllustrationName.seal, true, l.hotelProviderHeadLiveTitle, k.endsOn)
                : (GzIllustrationName.partnerReview, false, l.hotelProviderHeadPendingTitle, null);
    final paid = k.billing.status == ListingBillingStatus.paid || k.billing.status == ListingBillingStatus.refundDue;
    final refunded = k.billing.status == ListingBillingStatus.refunded;
    final paidLine = refunded ? l.hotelProviderPlanRefunded : (paid && rejected ? l.hotelProviderPlanRetained : null);
    void support() => nav.push('HL-TODY-05', params: const {'support': true});

    Widget fact(IconData icon, String key, String value) => Container(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary, semanticLabel: key),
              const SizedBox(width: GzSpace.s4),
              Expanded(child: GzText(value, role: GzTextRole.body, color: c.textStrong, textAlign: TextAlign.end, figures: true)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzIllustration(art, tone: success ? GzIllustrationTone.standard : GzIllustrationTone.standard),
                const SizedBox(height: GzSpace.s3),
                GzText(title, role: GzTextRole.uiXl, color: c.textStrong, header: true),
                if (date != null) ...[
                  const SizedBox(height: GzSpace.s3),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    GzIcon(GzIcons.calendar, size: GzIconSize.sm, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    GzText(f.date(date.toJson(), DateStyle.short), role: GzTextRole.body, color: c.textPrimary, figures: true),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s6),
          if (longWait) ...[
            ProvNote(icon: GzIcons.clock, figures: true, text: l.hotelProviderLongWait(waited), actionLabel: l.hotelProviderContactSupport, onAction: support),
            const SizedBox(height: GzSpace.s6),
          ],
          if (rejected && k.rejection != null) ...[
            GzSectionHeader(title: l.hotelProviderReasons, voice: GzHeaderVoice.partner),
            const SizedBox(height: GzSpace.s3),
            Wrap(spacing: GzSpace.s2, runSpacing: GzSpace.s2, children: [for (final code in k.rejection!.codes) GzTag(label: _reason(l, code), icon: GzIcons.warningCircle)]),
            const SizedBox(height: GzSpace.s3),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
              decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.smAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
              child: GzUserText(k.rejection!.note.of(lang), role: GzTextRole.body),
            ),
            if (paidLine != null) ...[
              const SizedBox(height: GzSpace.s3),
              ProvNote(tone: NoteTone.quiet, icon: GzIcons.coins, text: paidLine, actionLabel: refunded ? null : l.hotelProviderContactSupport, onAction: support),
            ],
            if (k.planCycle == null && !exempt) ...[
              const SizedBox(height: GzSpace.s3),
              Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelProviderChoosePlanAgain, variant: GzButtonVariant.tertiary, onPressed: () => nav.push('HL-PROV-04', params: {'listingId': k.id}))),
            ],
            const SizedBox(height: GzSpace.s6),
          ],
          Semantics(label: l.hotelProviderListingLabel, container: true, child: GzProviderListingCard(listing: k, exempt: exempt, categoryName: ref.watch(serviceCategoriesProvider).value?.where((c) => c.id == k.categoryId).firstOrNull?.name)),
          const SizedBox(height: GzSpace.s6),
          GzSectionHeader(title: l.hotelProviderTimeline, voice: GzHeaderVoice.partner),
          const SizedBox(height: GzSpace.s3),
          GzReviewTimeline(listing: k),
          const SizedBox(height: GzSpace.s6),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (k.submittedAt != null) fact(GzIcons.calendar, l.hotelProviderFactSubmitted, '${f.date(f.isoDay(k.submittedAt!), DateStyle.short)} · ${f.time(k.submittedAt!)}'),
                fact(GzIcons.coins, l.hotelProviderFactFees, exempt ? l.hotelProviderFactNoFees : paid ? l.hotelProviderFactPaid : l.hotelProviderFactRatesSoon),
                if (isLive && days != null && k.endsOn != null) fact(GzIcons.timer, l.hotelProviderFactPlanEnds, '${f.date(k.endsOn!.toJson(), DateStyle.short)} · ${l.hotelProviderDaysLeft(days)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _reason(AppL10n l, ListingRejectionCode c) => switch (c) {
  ListingRejectionCode.contentNotCompliant => l.hotelProviderReasonContent,
  ListingRejectionCode.wrongCategory => l.hotelProviderReasonCategory,
  ListingRejectionCode.missingDetails => l.hotelProviderReasonMissing,
  ListingRejectionCode.unclearPricing => l.hotelProviderReasonPricing,
  _ => l.hotelProviderReasonOther,
};

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120), SizedBox(height: GzSpace.s6), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 240)],
        ),
      );
}
