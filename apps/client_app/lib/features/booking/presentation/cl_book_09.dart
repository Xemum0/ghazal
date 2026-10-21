import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' hide BookingSection;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_providers.dart' show keepStale;
import '../application/booking_request.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_layout.dart';
import 'widgets/sent_parts.dart';

/// CL-BOOK-09 Booking confirmed: the one celebratory moment of the booking flow. Covers CA-BOOK-12, CA-STAT-13, CA-VCH-07, CA-TOOL-16,
/// CA-TOOL-17, CA-PLAN-01, CA-NOTI-07.
///
/// The request is now a booking at the voucher price. One ink panel: the drawing, the outcome in two words and the Booking Thread with the
/// Confirmation knot tying. Then the voucher as a slim ticket (QR and code first), "Pay venue" with its sentence behind an info glyph, the
/// date, hall and reference as glyph facts, five glyphs to keep and use the booking, "Book a visit", the planner offer once, and "Done".
/// params: bookingId (else the hero request).
class ClBook09Screen extends ConsumerWidget {
  const ClBook09Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final async = ref.watch(bookingRequestProvider((id: id, preferApproved: false)));
    final facts = keepStale(async).value;
    void exit(String tab, {String? thenId, Map<String, Object?> thenParams = const <String, Object?>{}}) =>
        leaveBookingFlow(ref, nav, tab, thenId: thenId, thenParams: thenParams);
    return GzScreen(
      top: GzTopBar(back: GzTopBarBack.close, backLabel: context.gzL10n.commonActionClose, onBack: () => exit('my-wedding'), rule: false),
      bottom: facts == null
          ? null
          : GzActionBar(
              secondary: GzActionBarAction(
                label: l10n.clientBookingDoneView,
                onPressed: () => exit('my-wedding', thenId: 'CL-BKNG-02', thenParams: <String, Object?>{'bookingId': facts.booking.id}),
              ),
              action: GzActionBarAction(label: context.gzL10n.commonActionDone, onPressed: () => exit('my-wedding')),
            ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
        child: BookingAsync<RequestFacts>(
          value: async,
          offlineText: l10n.clientBookingSentOffline,
          onRetry: () => ref.invalidate(bookingRequestProvider),
          loading: const BookingSuccessHero(illustration: GzIllustrationName.successBooking, title: '', child: SizedBox(height: 96)),
          data: (facts) => _Confirmed(facts: facts, exit: exit),
        ),
      ),
    );
  }
}

class _Confirmed extends ConsumerWidget {
  const _Confirmed({required this.facts, required this.exit});

  final RequestFacts facts;
  final void Function(String tab, {String? thenId, Map<String, Object?> thenParams}) exit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final c = context.gz.colors;
    final b = facts.booking;
    final voucher = facts.voucher;
    final venueName = context.bi(facts.targetName);
    final hall = facts.hall;
    final local = ref.watch(bookingFlowLocalProvider);
    final wedding = ref.watch(weddingProfileProvider).value;
    final differs = wedding != null && wedding.weddingDate != b.eventDate;
    final venueId = facts.venueId;

    void say(String message) => nav.toast(GzToastSpec(message: message, tone: GzToastTone.success));
    void directions() {
      Widget row(IconData icon, String title, {bool last = false}) => GzListRow(
        flush: true,
        last: last,
        chevron: true,
        leading: GzIcon(icon, size: GzIconSize.md),
        title: title,
        onPressed: () {
          nav.closeSheet();
          say(l10n.clientBookingMapsToast);
        },
      );
      nav.openSheetBuilder(
        (sheet) => Column(
          children: [
            row(GzIcons.map, l10n.clientBookingMapsGoogle),
            if (defaultTargetPlatform == TargetPlatform.iOS) row(GzIcons.navigate, l10n.clientBookingMapsApple),
            row(GzIcons.pin, l10n.clientBookingMapsWaze, last: true),
          ],
        ),
        options: GzSheetOptions(title: l10n.clientBookingMapsTitle),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingSuccessHero(
          illustration: GzIllustrationName.successBooking,
          title: l10n.clientBookingDoneHeading,
          child: GzBookingThread(booking: b, onDark: true, pop: GzThreadKey.confirmation, draw: GzDraw.mount),
        ),
        StepSection(
          tight: true,
          label: l10n.clientBookingDoneVoucherTitle,
          children: [
            if (voucher != null)
              GzVoucherCard(
                variant: GzVoucherCardVariant.slim,
                voucher: voucher,
                targetName: venueName,
                onCopy: () => say(l10n.clientBookingDoneCopied),
                onShowFull: () => nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': voucher.id}),
              ),
            GzAsideInfo(
              icon: GzIcons.receipt,
              word: l10n.clientBookingDonePayWord,
              title: l10n.clientBookingDonePayTitle,
              paragraphs: [l10n.clientBookingDonePay(venueName)],
            ),
          ],
        ),
        StepSection(
          gap: GzSpace.s3,
          label: l10n.clientBookingDoneHeading,
          children: [
            BookingDateLine(date: b.eventDate),
            GzFactRow(
              children: [
                if (hall != null) GzFactChip(icon: GzIcons.hall, label: l10n.clientBookingSentHall, value: context.bi(hall.name)),
                GzFactChip(icon: GzIcons.document, label: l10n.clientBookingSentReference, value: b.ref, tone: GzFactTone.muted),
                GzFactChip(
                  icon: GzIcons.checklist,
                  label: l10n.clientBookingDoneChecklist,
                  valueWidget: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess),
                  tone: GzFactTone.muted,
                ),
              ],
            ),
            if (differs)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzButton(
                  label: l10n.clientBookingDoneSetDate,
                  variant: GzButtonVariant.tertiary,
                  iconStart: GzIcons.calendarCheck,
                  onPressed: () async {
                    final result = await ref
                        .read(weddingProfileProvider.notifier)
                        .patch(WeddingProfileInput(weddingDate: b.eventDate, dateMode: DateMode.exact));
                    if (result != null) say(l10n.clientBookingDoneDateSet);
                  },
                ),
              ),
          ],
        ),
        StepSection(
          tight: true,
          label: l10n.clientBookingDoneActions,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GzIconButton(
                  variant: GzIconButtonVariant.outline,
                  icon: GzIcons.navigate,
                  label: l10n.clientBookingDoneDirections,
                  onPressed: directions,
                ),
                GzIconButton(
                  variant: GzIconButtonVariant.outline,
                  icon: GzIcons.phone,
                  label: l10n.clientBookingDoneCall,
                  onPressed: () => say(l10n.clientBookingDoneCalling),
                ),
                GzIconButton(
                  variant: GzIconButtonVariant.outline,
                  icon: GzIcons.chat,
                  label: l10n.commonActionMessage,
                  onPressed: () => exit('my-wedding', thenId: 'CL-MSGS-02', thenParams: <String, Object?>{'venueId': venueId}),
                ),
                GzIconButton(
                  variant: GzIconButtonVariant.outline,
                  icon: GzIcons.calendarPlus,
                  label: l10n.clientBookingDoneCalendar,
                  onPressed: () => say(l10n.clientBookingDoneCalendarToast),
                ),
                GzIconButton(
                  variant: GzIconButtonVariant.outline,
                  icon: GzIcons.share,
                  label: context.gzL10n.commonActionShare,
                  onPressed: () => say(l10n.clientBookingDoneShared),
                ),
              ],
            ),
            if (venueId != null)
              GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.door,
                title: l10n.clientBookingDoneVisit,
                chevron: true,
                onPressed: () => nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{'venueId': venueId})),
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
      ],
    );
  }
}
