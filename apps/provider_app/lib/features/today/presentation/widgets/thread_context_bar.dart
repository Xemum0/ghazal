// ContextBar: the booking a conversation belongs to, pinned under the header so staff can answer and decide in one place (web `ContextBar.tsx`,
// HA-BOOK-07). The hall's section symbol, the day and the guests as facts, the request's own status, the voucher chip and, while the request is
// pending, the time left in its SLA tone with Accept and Decline (the same flows as Booking detail, ADR 0008 D6). Tapping the bar opens Booking
// detail. Accept is the one gold action of the screen. No sentence is printed.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, PartnerRequestDetail, SlaState;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'today_bits.dart';

class ThreadContextBar extends StatelessWidget {
  const ThreadContextBar({required this.request, required this.now, this.readOnly = false, this.onOpen, this.onAccept, this.onDecline, super.key});

  final PartnerRequestDetail request;

  /// The app clock (the story clock in the mock).
  final DateTime now;
  final bool readOnly;
  final VoidCallback? onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final booking = request.booking;
    final section = booking.sections.isEmpty ? null : booking.sections.first;
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    final date = dayMonth(f, booking.eventDate.toString());
    final sla = request.sla;
    final pending = booking.status == BookingStatus.pending;
    final accepted = booking.status == BookingStatus.approved && booking.confirmBy != null;
    final voucher = request.voucher;
    final audienceName = section == null ? '' : audienceWord(l, section.audience);
    final summary = section == null ? date : l.hotelTodayContextLine(audienceName, date, f.guests(guests));
    final left = pending && sla != null && sla.state != SlaState.expired
        ? TimeLeft(minutes: sla.minutesLeft, tone: leftToneOf(sla.state), say: l.hotelTodayWindowEnds)
        : null;
    final confirmLeft = accepted
        ? TimeLeft(minutes: booking.confirmBy!.difference(now).inMinutes.clamp(0, 1 << 30), say: l.hotelTodayConfirmWindowEnds)
        : null;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s3),
      decoration: BoxDecoration(color: c.surfaceCanvas, border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzPressable(
            onPressed: onOpen,
            semanticLabel: l.hotelTodayOpenBooking(summary),
            borderRadius: GzRadius.smAll,
            minHeight: GzSize.touchMin,
            scale: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: GzSpace.s3,
                          runSpacing: GzSpace.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (section != null) GzFactChip(icon: audienceIcon(section.audience), label: audienceName),
                            TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: date),
                            if (guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactGuests, value: f.integer(guests)),
                          ],
                        ),
                        const SizedBox(height: GzSpace.s1),
                        Wrap(
                          spacing: GzSpace.s3,
                          runSpacing: GzSpace.s1,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GzStatusPill(status: gzStatusOfBooking(booking.status), audience: GzStatusAudience.hotel),
                            if (voucher != null && (pending || accepted)) GzVoucherChip(code: voucher.code),
                            ?left,
                            ?confirmLeft,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
                ],
              ),
            ),
          ),
          if (pending && !readOnly) ...[
            const SizedBox(height: GzSpace.s2),
            Row(
              children: [
                Expanded(child: GzButton(label: context.gzL10n.commonActionAccept, size: GzButtonSize.sm, iconStart: GzIcons.check, fullWidth: true, onPressed: onAccept)),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzButton(label: context.gzL10n.commonActionDecline, size: GzButtonSize.sm, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: onDecline)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
