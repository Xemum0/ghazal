import 'dart:async';

import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_providers.dart';
import '../application/booking_request.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_info.dart';
import 'widgets/booking_layout.dart';
import 'widgets/sent_parts.dart';

/// CL-BOOK-06 Request sent: the outcome of a request and the screen that keeps the wait between request and reply calm.
/// Covers CA-BOOK-10, CA-BOOK-12, CA-STAT-03, CA-PLAN-01, CA-NOTI-02, CA-CHAT-02, CA-VCH-08.
///
/// One ink panel with the drawing (the success moment, 640 ms, no confetti), the outcome in two words and the Booking Thread. Below it the
/// request as facts (venue, date, hall, guests, voucher total, reference), the voucher as one row, the planner offer (once) and the ways
/// out. The sentences live behind one info glyph. One primary: View request. params: bookingId (else the hero request).
class ClBook06Screen extends ConsumerStatefulWidget {
  const ClBook06Screen({super.key});

  @override
  ConsumerState<ClBook06Screen> createState() => _ClBook06State();
}

class _ClBook06State extends ConsumerState<ClBook06Screen> {
  Timer? _prompt;

  @override
  void initState() {
    super.initState();
    // The OS pre-prompt comes once, after the first request, a beat after the success moment (never at launch, never on a demo open).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.gzNav.params['bookingId'] == null || ref.read(bookingFlowLocalProvider).notifPrompted) return;
      _prompt = Timer(const Duration(milliseconds: 2200), _promptNotifications);
    });
  }

  @override
  void dispose() {
    _prompt?.cancel();
    super.dispose();
  }

  void _promptNotifications() {
    if (!mounted) return;
    final nav = context.gzNav;
    final l10n = context.l10n;
    ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(notifPrompted: true));
    nav.openSheetBuilder(
      (sheet) => BookingNotifPrompt(
        onYes: () {
          nav.closeSheet();
          nav.toast(GzToastSpec(message: l10n.clientBookingSentNotifToast, tone: GzToastTone.success));
        },
        onNo: nav.closeSheet,
      ),
      options: GzSheetOptions(title: l10n.clientBookingSentNotifTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final async = ref.watch(bookingRequestProvider((id: id, preferApproved: false)));
    final facts = keepStale(async).value;
    final failed = async.hasError && facts == null;
    void exit(String tab, {String? thenId, Map<String, Object?> thenParams = const <String, Object?>{}}) =>
        leaveBookingFlow(ref, nav, tab, thenId: thenId, thenParams: thenParams);
    return GzScreen(
      top: GzTopBar(back: GzTopBarBack.close, backLabel: context.gzL10n.commonActionClose, onBack: () => exit('discover'), rule: false),
      bottom: failed || facts == null
          ? null
          : GzActionBar(
              secondary: GzActionBarAction(
                label: l10n.commonActionMessage,
                onPressed: () => exit('messages', thenId: 'CL-MSGS-02', thenParams: <String, Object?>{'venueId': facts.venueId}),
              ),
              action: GzActionBarAction(
                label: l10n.clientBookingSentView,
                onPressed: () => exit('my-wedding', thenId: 'CL-BKNG-02', thenParams: <String, Object?>{'bookingId': facts.booking.id}),
              ),
            ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
        child: BookingAsync<RequestFacts>(
          value: async,
          offlineText: l10n.clientBookingSentOffline,
          onRetry: () => ref.invalidate(bookingRequestProvider),
          loading: const BookingSuccessHero(illustration: GzIllustrationName.successRequest, title: '', child: SizedBox(height: 96)),
          data: (facts) => _Sent(facts: facts, exit: exit),
        ),
      ),
    );
  }
}

class _Sent extends ConsumerWidget {
  const _Sent({required this.facts, required this.exit});

  final RequestFacts facts;
  final void Function(String tab, {String? thenId, Map<String, Object?> thenParams}) exit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final local = ref.watch(bookingFlowLocalProvider);
    final b = facts.booking;
    final voucher = facts.voucher;
    final venueName = context.bi(facts.targetName);
    final hall = facts.hall;
    final guests = facts.guests;
    final urgent = (b.slaHours ?? 24) <= 4;
    final venueId = facts.venueId;
    final confirmHours = ref.watch(bookingConfigProvider).value?.confirmWindowHours ?? 24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingSuccessHero(
          illustration: GzIllustrationName.successRequest,
          title: l10n.clientBookingSentTitle,
          child: GzBookingThread(booking: b, onDark: true, pop: GzThreadKey.request, draw: GzDraw.mount),
        ),
        StepSection(
          gap: GzSpace.s3,
          label: l10n.clientBookingSentTitle,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                children: [
                  Expanded(
                    child: GzText(venueName, role: GzTextRole.d1, color: c.textStrong),
                  ),
                  BookingInfoButton(
                    title: l10n.clientBookingSentInfoTitle,
                    paragraphs: [l10n.clientBookingSentBody(venueName, confirmHours), l10n.clientBookingSentWithdraw],
                  ),
                ],
              ),
            ),
            GzFactRow(
              children: [
                GzFactChip(icon: GzIcons.calendar, label: l10n.clientBookingSentDate, value: f.date(b.eventDate.toString(), DateStyle.compact)),
                if (hall != null) GzFactChip(icon: GzIcons.hall, label: l10n.clientBookingSentHall, value: context.bi(hall.name)),
                if (guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l10n.clientBookingSentGuests, value: f.integer(guests)),
              ],
            ),
            GzFactRow(
              children: [
                GzFactChip(
                  icon: GzIcons.ticket,
                  label: l10n.clientBookingSentVoucherPrice,
                  valueWidget: bookingMoneyValue(context, f, b.totals.voucherTotal.fils, exact: true),
                  tone: GzFactTone.accent,
                ),
                GzFactChip(icon: GzIcons.document, label: l10n.clientBookingSentReference, value: b.ref, tone: GzFactTone.muted),
                if (urgent)
                  GzFactChip(
                    icon: GzIcons.timer,
                    label: l10n.clientBookingReplyFast,
                    value: f.digits(l10n.commonCountHours(b.slaHours ?? 4)),
                    tone: GzFactTone.accent,
                  ),
              ],
            ),
            if (voucher != null)
              GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.ticket,
                title: voucher.code,
                chevron: true,
                onPressed: () => exit('my-wedding', thenId: 'CL-VCHR-03', thenParams: <String, Object?>{'voucherId': voucher.id}),
              ),
          ],
        ),
        if (!local.plannerDismissed)
          StepSection(
            tight: true,
            label: l10n.clientBookingPlannerTitle,
            children: [
              BookingPlannerOffer(
                onYes: () => exit(
                  'my-wedding',
                  thenId: 'CL-PLAN-01',
                  thenParams: <String, Object?>{'from': 'booking', 'venueId': venueId, 'date': b.eventDate.toString()},
                ),
                onNo: () => ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(plannerDismissed: true)),
              ),
            ],
          ),
        StepSection(
          bottom: 0,
          label: context.gzL10n.commonActionClose,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              children: [
                StartBleed(
                  child: GzButton(
                    label: l10n.clientBookingSentDiscover,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.home,
                    onPressed: () => exit('discover'),
                  ),
                ),
                GzButton(
                  label: l10n.clientBookingSentWedding,
                  variant: GzButtonVariant.tertiary,
                  iconStart: GzIcons.heart,
                  onPressed: () => exit('my-wedding'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
