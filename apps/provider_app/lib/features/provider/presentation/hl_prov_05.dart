// HL-PROV-05 Pay for the plan (web `HL-PROV-05.tsx`): the hosted gateway (same methods as the client voucher) and every outcome. Payment moves
// the listing to review; it never publishes it. While the plan rates are not announced the screen cannot be reached (it says so). Success is
// only ever taken from the server (the listing's billing turns `paid`), never from the redirect. The bank's hosted page is a third-party
// placeholder. Route params: `listingId`, `cycle`, `renewal`, and for frames `scene` (redirecting, bank, confirming, paid, failed, cancelled)
// and `sample` (the labelled sample rates). Requirements: PA-ADS-02, PA-ADS-03, PA-ADS-07, PA-REV-01.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerListingsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/provider_actions.dart';
import '../application/provider_data.dart';
import 'widgets/pay_parts.dart';
import 'widgets/prov_bits.dart';

enum _Phase { summary, redirecting, bank, confirming, paid, failed, cancelled }

/// NOT-FOR-RELEASE SAMPLE (web `SAMPLE_RATES_FILS`): the real rates are an owner decision (OQ-V-07) and stay null in the API; a frame that must
/// show the payable layout names `sample: true` and every amount then carries the "Sample" mark.
const Map<AdPlanCycle, int> _sampleFils = {AdPlanCycle.weekly: 5000, AdPlanCycle.monthly: 15000, AdPlanCycle.annual: 120000};
const int _pollEvery = 2;
const int _pollMax = 15;

class HlProv05Screen extends ConsumerStatefulWidget {
  const HlProv05Screen({super.key});

  @override
  ConsumerState<HlProv05Screen> createState() => _HlProv05State();
}

class _HlProv05State extends ConsumerState<HlProv05Screen> {
  _Phase? _phase;
  GzPaymentMethodKey _method = GzPaymentMethodKey.knet;
  bool _approved = true;
  String? _sessionId;
  DateTime? _paidBefore;
  Timer? _timer;
  int _polls = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _Phase _initial(GzParams p) => switch (p['scene']) {
    'redirecting' => _Phase.redirecting,
    'bank' || 'bank-page' => _Phase.bank,
    'confirming' || 'confirming-with-bank' => _Phase.confirming,
    'paid' || 'paid-submitted-for-review' => _Phase.paid,
    'failed' => _Phase.failed,
    'cancelled' => _Phase.cancelled,
    _ => _Phase.summary,
  };

  void _set(_Phase p) {
    _timer?.cancel();
    setState(() => _phase = p);
  }

  AdPlanCycle _cycle(GzParams p, Listing? listing) {
    final v = p['cycle'];
    final hit = kCycles.where((c) => c.value == v).firstOrNull;
    return hit ?? listing?.planCycle ?? AdPlanCycle.monthly;
  }

  Future<void> _pay(Listing listing) async {
    final nav = GzNavigatorScope.of(context);
    final g = context.gzL10n;
    _paidBefore = listing.billing.paidAt;
    final r = await ref.read(listingActionsProvider.notifier).openPayment(listing.id, gzToGatewayMethod(_method));
    if (!mounted) return;
    switch (r) {
      case ActionSuccess(:final value):
        _sessionId = value.id;
        _set(_Phase.redirecting);
        // the hosted page opens (a third-party page); a moment later its stand-in shows
        _timer = Timer(const Duration(milliseconds: 900), () => _set(_Phase.bank));
      case ActionFailure(:final problem):
        nav.toast(GzToastSpec(message: gzProblemMessage(g, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
  }

  /// The bank answered: a decline ends it; an approval waits for the server to say the fee was paid.
  void _bankPay(Listing listing) {
    _set(_Phase.confirming);
    _polls = 0;
    if (!_approved) {
      _timer = Timer(const Duration(milliseconds: 1400), () => _set(_Phase.failed));
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: _pollEvery), (t) async {
      _polls++;
      var paid = false;
      try {
        final l = await ref.read(partnerListingsRepositoryProvider).getListing(listingId: listing.id);
        paid = l.billing.status == ListingBillingStatus.paid && l.billing.paidAt != _paidBefore;
      } on Object {
        // a missed read is retried on the next tick
      }
      if (!mounted) return;
      if (paid) {
        ref.read(partnerDataRevisionProvider.notifier).bump();
        _set(_Phase.paid);
      } else if (_polls >= _pollMax) {
        _set(_Phase.failed);
      }
    });
  }

  Future<void> _askLeave() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final r = await nav.openDialog(
      GzDialogSpec(title: l.hotelProviderLeaveTitle, body: l.hotelProviderLeaveBody, icon: GzIcons.lock, confirmLabel: l.hotelProviderLeaveStay, cancelLabel: l.hotelProviderLeaveConfirm),
    );
    if (r == GzDialogResult.cancel && mounted) _set(_Phase.cancelled);
  }

  void _methods() {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => MethodsSheet(value: _method, onPick: (m) => setState(() => _method = m), onDone: nav.closeSheet),
      options: GzSheetOptions(title: context.l10n.hotelProviderMethodsTitle),
    );
  }

  void _receipt(Listing listing, AdPlanCycle cycle, int fils, String title) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => PlanReceipt(number: _sessionId ?? listing.id, listingTitle: title, cycle: cycle, fils: fils, paidAt: listing.billing.paidAt, method: methodName(context, _method)),
      options: GzSheetOptions(title: context.l10n.hotelProviderReceiptTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = GzNavigatorScope.of(context);
    final params = nav.params;
    final phase = _phase ??= _initial(params);
    final renewal = params['renewal'] == true;
    final sample = params['sample'] == true;
    final lang = context.gz.locale.languageCode;
    final listingV = ref.watch(pickedListingProvider(ListingPick(params['listingId'] as String?, const [ListingStatus.paymentPending, ListingStatus.draft, ListingStatus.rejected, ListingStatus.expired])));
    final billingV = ref.watch(partnerBillingProvider);
    final busy = ref.watch(listingActionsProvider).isBusy;
    final both = billingV.hasError ? billingV : listingV;
    final listing = listingV.value;
    final billing = billingV.value;

    Widget screen({required GzTopBar top, GzActionBar? bottom, required Widget child}) => GzScreen(top: top, bottom: bottom, child: child);

    return GzAsyncView<Object?>(
      value: both.whenData((_) => billing == null || listing == null ? null : Object()),
      isEmpty: (v) => v == null,
      empty: screen(top: GzTopBar(title: l.hotelProviderPayTitle), child: GzEmptyState(illustration: GzIllustrationName.emptyListings, title: g.commonStateTitleEmpty, fill: false)),
      loading: screen(top: GzTopBar(title: l.hotelProviderPayTitle), child: const _PaySkeleton()),
      onRetry: () {
        ref.invalidate(partnerBillingProvider);
        ref.invalidate(pickedListingProvider);
      },
      data: (_) {
        final k = listing!;
        final b = billing!;
        final cycle = _cycle(params, k);
        final live = rateOf(b, cycle);
        final fils = live ?? (sample ? _sampleFils[cycle]! : null);
        final isSample = live == null && sample;
        final blocked = fils == null || (!sample && (!b.payable || noPlanOf(b)));
        final title = k.title.of(lang);
        final days = periodDaysOf(b, cycle);
        final amountText = fils == null ? '' : f.money(fils, const MoneyOptions(mode: MoneyMode.exact));
        final method = methodName(context, _method);

        GzTopBar secureBar() => GzTopBar(
          back: GzTopBarBack.close,
          onBack: _askLeave,
          rule: true,
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconPrimary), const SizedBox(width: GzSpace.s2), GzText(l.hotelProviderGatewayTitle(method), role: GzTextRole.title, color: c.textStrong)],
          ),
        );
        final plainBar = GzTopBar(title: l.hotelProviderPayTitle);
        final infoRefund = Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
          child: GzInfoButton(title: l.hotelProviderRefundTitle, paragraphs: [l.hotelProviderRefundNote]),
        );

        if (blocked) {
          return screen(
            top: plainBar,
            child: Interstitial(
              icon: GzIcons.clock,
              art: GzIllustrationName.hourglass,
              title: l.hotelProviderBlockedTitle,
              body: l.hotelProviderBlockedBody,
              children: [Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s3), child: GzButton(label: l.hotelProviderBackToPlans, variant: GzButtonVariant.secondary, onPressed: nav.pop))],
            ),
          );
        }
        final amount = fils;
        switch (phase) {
          case _Phase.redirecting:
            return screen(
              top: secureBar(),
              child: Interstitial(
                activity: true,
                title: l.hotelProviderRedirectTitle(method),
                body: l.hotelProviderRedirectBody,
                children: [const SizedBox(height: GzSpace.s3), PaySummary(listingTitle: title, cycle: cycle, periodDays: days, amount: amountText)],
              ),
            );
          case _Phase.confirming:
            return screen(top: secureBar(), child: Interstitial(activity: true, title: l.hotelProviderConfirmingTitle, body: l.hotelProviderConfirmingBody));
          case _Phase.bank:
            return screen(
              top: secureBar(),
              child: BankPage(
                method: _method,
                legalAmount: f.money(amount, const MoneyOptions(mode: MoneyMode.exact, legal: true)),
                onCancel: () => _set(_Phase.cancelled),
                onPay: () => _bankPay(k),
                answer: DecoratedBox(
                  decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(l.hotelProviderProtoLabel, role: GzTextRole.label, color: c.textSecondary),
                        const SizedBox(height: GzSpace.s2),
                        GzChipGroup<bool>(
                          label: l.hotelProviderProtoLabel,
                          value: _approved,
                          onChanged: (v) => setState(() => _approved = v ?? _approved),
                          options: [GzChipOption<bool>(value: true, label: l.hotelProviderProtoApproved), GzChipOption<bool>(value: false, label: l.hotelProviderProtoDeclined)],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          case _Phase.paid:
            return screen(
              top: GzTopBar(title: l.hotelProviderPayTitle, back: GzTopBarBack.hide),
              bottom: GzActionBar(
                action: GzActionBarAction(
                  label: renewal ? l.hotelProviderBackToListings : l.hotelProviderViewStatus,
                  iconEnd: GzIcons.chevronRight,
                  onPressed: renewal ? () => nav.reset('HL-PROV-02') : () => nav.replace('HL-PROV-06', params: {'listingId': k.id}),
                ),
              ),
              child: Interstitial(
                art: GzIllustrationName.successPayment,
                tone: InterTone.success,
                title: renewal ? l.hotelProviderRenewedTitle : l.hotelProviderPaidTitle,
                body: renewal ? l.hotelProviderRenewedBody : l.hotelProviderPaidBody,
                children: [
                  const SizedBox(height: GzSpace.s3),
                  PaySummary(listingTitle: title, cycle: cycle, periodDays: days, amount: amountText, paid: true),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
                    child: GzButton(label: l.hotelProviderReceiptLink, variant: GzButtonVariant.tertiary, iconStart: GzIcons.receipt, onPressed: () => _receipt(k, cycle, amount, title)),
                  ),
                  if (renewal && k.endsOn != null)
                    Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s3), child: ProvNote(icon: GzIcons.calendar, figures: true, text: l.hotelProviderRenewedNote(f.date(k.endsOn!.toJson(), DateStyle.short)))),
                ],
              ),
            );
          case _Phase.failed:
            return screen(
              top: plainBar,
              child: Interstitial(
                art: GzIllustrationName.card,
                tone: InterTone.danger,
                title: l.hotelProviderFailedTitle,
                body: l.hotelProviderFailedBody,
                children: [
                  const SizedBox(height: GzSpace.s4),
                  GzButton(label: l.hotelProviderRetry, fullWidth: true, onPressed: () => _pay(k)),
                  const SizedBox(height: GzSpace.s3),
                  GzButton(
                    label: l.hotelProviderSwitchMethod,
                    variant: GzButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () {
                      _set(_Phase.summary);
                      _methods();
                    },
                  ),
                ],
              ),
            );
          case _Phase.cancelled:
            return screen(
              top: plainBar,
              child: Interstitial(
                art: GzIllustrationName.card,
                title: l.hotelProviderCancelledTitle,
                body: l.hotelProviderCancelledBody,
                children: [Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s3), child: GzButton(label: l.hotelProviderBackToPay, variant: GzButtonVariant.secondary, onPressed: () => _set(_Phase.summary)))],
              ),
            );
          case _Phase.summary:
            return screen(
              top: plainBar,
              bottom: GzActionBar(action: GzActionBarAction(label: l.hotelProviderPayAction(amountText), iconEnd: GzIcons.lock, loading: busy, onPressed: () => _pay(k))),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      label: l.hotelProviderPayTotal,
                      child: Row(children: [GzPrice(fils: amount, mode: GzMoneyMode.exact, size: GzPriceSize.kpi), if (isSample) ...[const SizedBox(width: GzSpace.s3), GzBadge(label: l.hotelProviderSampleBadge, variant: GzBadgeVariant.quiet)]]),
                    ),
                    const SizedBox(height: GzSpace.s5),
                    PaySummary(listingTitle: title, cycle: cycle, periodDays: days),
                    const SizedBox(height: GzSpace.s5),
                    GzPaymentMethodRow(method: _method, selected: true, last: true),
                    Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelProviderChangeMethod, variant: GzButtonVariant.tertiary, onPressed: _methods)),
                    infoRefund,
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}

class _PaySkeleton extends StatelessWidget {
  const _PaySkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSkeleton(inlineSize: 140, blockSize: 40),
        SizedBox(height: GzSpace.s5),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
        SizedBox(height: GzSpace.s5),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72),
      ],
    ),
  );
}
