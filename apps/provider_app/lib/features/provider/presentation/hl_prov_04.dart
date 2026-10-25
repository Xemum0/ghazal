// HL-PROV-04 Choose a plan (web `HL-PROV-04.tsx`): Weekly, Monthly or Annual with what every plan includes. The rates are an owner decision
// (OQ-V-07): while the API says they are not announced every row says so by an hourglass, "Continue to payment" is replaced by a plain submit
// and no number appears. A major hotel or a contract partner sees an explanation instead of plans and goes straight to review. Choosing or
// paying never publishes a listing: a person at Ghazal approves it. Requirements: PA-ADS-01, PA-ADS-03..06, PA-BIL-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/provider_actions.dart';
import '../application/provider_data.dart';
import 'widgets/for_listing.dart';
import 'widgets/plan_rows.dart';
import 'widgets/prov_bits.dart';

class HlProv04Screen extends ConsumerStatefulWidget {
  const HlProv04Screen({super.key});

  @override
  ConsumerState<HlProv04Screen> createState() => _HlProv04State();
}

class _HlProv04State extends ConsumerState<HlProv04Screen> {
  AdPlanCycle? _chosen;

  ListingPick _pick(GzParams p) => ListingPick(p['listingId'] as String?, const [ListingStatus.paymentPending, ListingStatus.draft, ListingStatus.rejected, ListingStatus.expired]);

  Future<void> _go(Listing listing, BillingView b, {required bool renewal}) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final g = context.gzL10n;
    final actions = ref.read(listingActionsProvider.notifier);
    final noPlan = noPlanOf(b);
    final cycle = _chosen ?? listing.planCycle ?? AdPlanCycle.monthly;
    ActionResult<Listing> res;
    if (renewal) {
      if (b.payable && !noPlan) {
        // a payable plan is paid on the payment screen (a renewal is a new payment, never an auto-debit)
        nav.push('HL-PROV-05', params: {'listingId': listing.id, 'cycle': cycle.value, 'renewal': true});
        return;
      }
      res = await actions.renew(listing.id);
    } else {
      if (noPlan && listing.planCycle == null) {
        // the API asks for a cycle on every submit, even for a partner who pays nothing (requests.md): a quiet default
        await actions.choosePlan(listing.id, AdPlanCycle.monthly);
        if (!mounted) return;
      }
      if (!noPlan) {
        final r = await actions.choosePlan(listing.id, cycle);
        if (!mounted) return;
        if (r is ActionFailure<Listing>) {
          nav.toast(GzToastSpec(message: gzProblemMessage(g, r.problem), tone: GzToastTone.danger));
          return;
        }
        if (b.payable) {
          nav.push('HL-PROV-05', params: {'listingId': listing.id, 'cycle': cycle.value, 'renewal': renewal});
          return;
        }
      }
      res = await actions.submit(listing.id);
    }
    if (!mounted) return;
    switch (res) {
      case ActionSuccess():
        nav.toast(GzToastSpec(message: l.hotelProviderPlanSubmittedToast, tone: GzToastTone.success));
        nav.replace('HL-PROV-06', params: {'listingId': listing.id});
      case ActionFailure(:final problem):
        nav.toast(GzToastSpec(message: gzProblemMessage(g, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final params = nav.params;
    final renewal = params['renewal'] == true;
    final listingV = ref.watch(pickedListingProvider(_pick(params)));
    final billingV = ref.watch(partnerBillingProvider);
    final cats = ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final busy = ref.watch(listingActionsProvider).isBusy;
    final both = billingV.hasError ? billingV : listingV;
    final listing = listingV.value;
    final billing = billingV.value;
    final noPlan = billing != null && noPlanOf(billing);
    final exempt = billing?.feeExempt ?? false;
    final title = renewal ? l.hotelProviderPlanTitleRenew : l.hotelProviderPlanTitle;
    final category = listing == null ? null : cats.where((c) => c.id == listing.categoryId).firstOrNull?.name;
    void edit() => nav.push('HL-PROV-03', params: {'listingId': listing!.id});

    GzActionBar? bottom;
    if (listing != null && billing != null) {
      if (noPlan) {
        bottom = GzActionBar(action: GzActionBarAction(label: l.hotelProviderStepSubmit, iconEnd: GzIcons.check, loading: busy, onPressed: () => _go(listing, billing, renewal: false)));
      } else if (billing.payable) {
        bottom = GzActionBar(
          action: GzActionBarAction(
            label: l.hotelProviderPlanContinue,
            iconEnd: GzIcons.chevronRight,
            loading: busy,
            onPressed: () => _go(listing, billing, renewal: renewal),
          ),
        );
      } else {
        bottom = GzActionBar(
          action: GzActionBarAction(label: l.hotelProviderStepSubmit, iconEnd: GzIcons.check, loading: busy, onPressed: () => _go(listing, billing, renewal: renewal)),
          note: l.hotelProviderPlanReasonRates,
        );
      }
    }

    Widget body() {
      final b = billing!;
      final k = listing!;
      final chosen = _chosen ?? k.planCycle ?? AdPlanCycle.monthly;
      final gap = const SizedBox(height: GzSpace.s5);
      final c = context.gz.colors;
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (noPlan) ...[
              if (exempt)
                const Align(alignment: AlignmentDirectional.centerStart, child: GzMajorHotelBadge())
              else
                ProvNote(icon: GzIcons.coins, text: '${l.hotelProviderPlanContractTitle} · ${l.hotelProviderPlanContractBody}'),
              const Padding(padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s6), child: Center(child: GzIllustration(GzIllustrationName.seal))),
              ForListing(listing: k, category: category, onEdit: edit),
            ] else ...[
              ForListing(listing: k, category: category, onEdit: edit),
              gap,
              if (renewal && k.endsOn != null) ...[
                ProvNote(
                  icon: GzIcons.calendar,
                  figures: true,
                  text: k.status == ListingStatus.expired
                      ? l.hotelProviderPlanRenewExpired(f.date(k.endsOn!.toJson(), DateStyle.short))
                      : l.hotelProviderPlanRenewLive(f.date(k.endsOn!.toJson(), DateStyle.short)),
                ),
                gap,
              ],
              PlanRows(
                cycles: kCycles,
                periodDays: (cy) => periodDaysOf(b, cy),
                rate: (cy) => rateOf(b, cy),
                chosen: chosen,
                onChoose: (cy) => setState(() => _chosen = cy),
                label: l.hotelProviderPlanGroup,
              ),
              gap,
              for (final (text, icon) in [(l.hotelProviderPlanIncl1, GzIcons.megaphone), (l.hotelProviderPlanIncl2, GzIcons.ticket), (l.hotelProviderPlanIncl3, GzIcons.chartBar)]) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(icon, size: GzIconSize.sm, color: c.iconAccent)),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(child: GzText(text, role: GzTextRole.body, color: c.textPrimary)),
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
              ],
            ],
          ],
        ),
      );
    }

    return GzScreen(
      top: GzTopBar(title: title),
      bottom: bottom,
      child: GzAsyncView<Object?>(
        value: both.whenData((_) => billingV.value == null || listingV.value == null ? null : Object()),
        isEmpty: (v) => v == null,
        empty: Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s6), child: GzEmptyState(illustration: GzIllustrationName.emptyListings, title: context.gzL10n.commonStateTitleEmpty, fill: false)),
        loading: const _PlanSkeleton(),
        onRetry: () {
          ref.invalidate(partnerBillingProvider);
          ref.invalidate(pickedListingProvider);
        },
        data: (_) => body(),
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
          ],
        ),
      );
}
