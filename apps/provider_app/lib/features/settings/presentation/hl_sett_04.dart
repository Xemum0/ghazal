// HL-SETT-04 Billing and fees (web `HL-SETT-04.tsx`): what Ghazal charges a partner. One status card with a drawing: the plan (its name, a status
// pill, the end date and the days left as facts), Ending (the same, a timer), Ended (hidden listing), No plan (or "Rates announced soon" while
// there are no rates), a business contract, or for a major hotel the exemption badge. The sentences sit behind the (i) of the card. The Plans row
// opens the plan chooser (HL-PROV-04). There is no bank, no IBAN and no payout: partners are never paid through Ghazal. Admin and Manager change
// the plan, Accountant views, Reception and Marketing do not see the screen. Plan rates are never shown as a number (OQ-V-07).
// Requirements: HA-AUTH-02, HA-BOOK-03, HA-SET-06, PA-ADS-04, PA-ADS-05.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle, BillingView, LocalDate, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_data.dart';
import '../application/settings_model.dart';

class HlSett04Screen extends ConsumerWidget {
  const HlSett04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final ctx = ref.watch(partnerContextProvider);
    final access = accessOf(ctx?.role ?? StaffRole.manager).billing;
    final value = ref.watch(partnerBillingProvider);
    final f = context.gzFormat;
    final today = LocalDate.parse(f.isoDay(ref.watch(clockProvider)()));

    Widget body(BillingView view) {
      final billing = billingOf(view, today);
      final canEdit = access == Level.edit;
      final attention = billing.status == BillingStatus.expiring || billing.status == BillingStatus.expired;
      final ratesSoon = !view.payable;
      void openPlans() => nav.push('HL-PROV-04', params: {'account': ctx?.isProvider == true ? 'provider' : (view.majorHotel ? 'major' : 'hotel'), 'renewal': attention});
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: _StatusCard(view: view, billing: billing, canEdit: canEdit, ratesSoon: ratesSoon, attention: attention),
            ),
            if (billing.status == BillingStatus.active && canEdit) ...[
              const SizedBox(height: GzSpace.s5),
              GzIconListRow(icon: GzIcons.megaphone, title: l.hotelSettingsBillPlanRow, chevron: true, flush: true, last: true, onPressed: openPlans),
            ],
          ],
        ),
      );
    }

    final bar = value.hasValue && access == Level.edit && value.value != null ? _bar(context, value.value!, today, nav, ctx?.isProvider == true) : null;
    return GzScreen(
      top: GzTopBar(title: l.hotelSettingsMoreBilling),
      bottom: bar,
      child: access == Level.none
          ? const GzErrorState(kind: GzErrorKind.noAccess)
          : GzAsyncView<BillingView>(value: value, loading: const _Skeleton(), onRetry: () => ref.invalidate(partnerBillingProvider), data: body),
    );
  }

  Widget? _bar(BuildContext context, BillingView view, LocalDate today, GzNavigator nav, bool provider) {
    final l = context.l10n;
    final billing = billingOf(view, today);
    final attention = billing.status == BillingStatus.expiring || billing.status == BillingStatus.expired;
    if (billing.status == BillingStatus.exempt || billing.status == BillingStatus.contract || !(attention || billing.status == BillingStatus.none)) return null;
    final label = attention ? l.hotelSettingsBillRenew : (!view.payable ? l.hotelSettingsBillSeePlans : l.hotelSettingsBillChoose);
    return GzActionBar(
      action: GzActionBarAction(label: label, onPressed: () => nav.push('HL-PROV-04', params: {'account': provider ? 'provider' : 'hotel', 'renewal': attention})),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.view, required this.billing, required this.canEdit, required this.ratesSoon, required this.attention});

  final BillingView view;
  final Billing billing;
  final bool canEdit;
  final bool ratesSoon;
  final bool attention;

  String _cycle(AppL10n l, AdPlanCycle? c) => switch (c) {
    AdPlanCycle.weekly => l.commonPlanWeekly,
    AdPlanCycle.monthly => l.commonPlanMonthly,
    AdPlanCycle.annual => l.commonPlanAnnual,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final gzl = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final status = billing.status;
    final art = status == BillingStatus.exempt || status == BillingStatus.contract
        ? GzIllustrationName.seal
        : (attention ? GzIllustrationName.hourglass : GzIllustrationName.partnerAds);
    final direct = l.hotelSettingsBillDirectNote;
    final paragraphs = switch (status) {
      BillingStatus.contract => [l.hotelSettingsBillContractBody, direct],
      BillingStatus.exempt => [l.hotelSettingsBillExemptBody, direct],
      BillingStatus.none => [ratesSoon ? l.hotelSettingsBillRatesBody : l.hotelSettingsBillNoneBody, direct],
      BillingStatus.expiring => [l.hotelSettingsBillExpiringNote, direct],
      BillingStatus.expired => [l.hotelSettingsBillExpiredNote, direct],
      BillingStatus.active => [direct],
    };
    final ends = billing.endsOn == null ? '' : f.date(billing.endsOn.toString(), DateStyle.compact);
    final pill = switch (status) {
      BillingStatus.active => GzStatusPill(status: GzStatus.listingActive, label: l.hotelSettingsBillPillActive),
      BillingStatus.expiring => GzStatusPill(status: GzStatus.urgent, label: l.hotelSettingsBillPillExpiring),
      BillingStatus.expired => const GzStatusPill(status: GzStatus.listingExpired),
      _ => null,
    };
    return Semantics(
      container: true,
      label: l.hotelSettingsBillStatusLabel,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s5),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: GzIllustration(art, size: GzIllustrationSize.lg)),
                const Spacer(),
                GzInfoButton(title: l.hotelSettingsMoreBilling, paragraphs: paragraphs),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            if (status == BillingStatus.contract)
              GzBillingCard(billing: view)
            else if (status == BillingStatus.exempt)
              const GzMajorHotelBadge()
            else if (status == BillingStatus.none)
              GzText(ratesSoon ? gzl.commonRatesSoon : l.hotelSettingsBillNone, role: GzTextRole.uiXl, color: c.textStrong)
            else ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s2,
                children: [
                  ?pill,
                  if (status == BillingStatus.expired) GzBadge(label: l.hotelSettingsBillHidden, variant: GzBadgeVariant.quiet, bead: false, icon: GzIcons.eyeOff),
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              GzText(_cycle(l, billing.cycle), role: GzTextRole.uiXl, color: c.textStrong),
              const SizedBox(height: GzSpace.s3),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s5,
                runSpacing: GzSpace.s2,
                children: [
                  GzFactChip(icon: GzIcons.calendar, tone: attention ? GzFactTone.accent : GzFactTone.normal, label: status == BillingStatus.expired ? l.hotelSettingsBillEnded : l.hotelSettingsBillEnds, value: ends),
                  if (billing.daysLeft != null && billing.daysLeft! >= 0)
                    GzFactChip(icon: GzIcons.timer, tone: attention ? GzFactTone.accent : GzFactTone.muted, label: l.hotelSettingsBillDaysLeft, value: f.integer(billing.daysLeft!), unit: l.hotelSettingsBillDaysUnit),
                ],
              ),
            ],
            if (!canEdit) ...[const SizedBox(height: GzSpace.s3), GzBadge(label: l.hotelSettingsBillViewOnly, variant: GzBadgeVariant.quiet, bead: false, icon: GzIcons.lock)],
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 296),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
            ],
          ),
        ),
      ),
    );
  }
}
