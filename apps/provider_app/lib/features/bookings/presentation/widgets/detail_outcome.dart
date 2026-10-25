// The end of Booking detail (web `DetailSections.tsx`): the outcome of a closed request as a quiet strip (a drawing, the facts, the voucher's
// fate behind an info glyph), the one destructive action that is left (cancel a confirmed booking, Admin and Manager) and the history row that
// opens the trail of who did what and when in a sheet.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/detail_model.dart';
import 'bk_bits.dart';
import 'booking_actions.dart';
import 'state_strip.dart';

/// Did the client confirm before the request ended? (a cancelled booking that was confirmed has consumed its voucher).
bool wasConfirmed(Booking b) => b.events.any((e) => e.to == BookingStatus.confirmed);

class DetailOutcome extends StatelessWidget {
  const DetailOutcome({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context) {
    final b = m.booking;
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final when = b.events.isEmpty ? '' : dayMonthShort(f, b.events.last.at);
    GzFactChip date() => GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsRowDate, value: when);
    switch (b.status) {
      case BookingStatus.declined:
        return StateStrip(
          illustration: GzIllustrationName.envelope,
          quietTitle: true,
          title: cl.commonStatusHotelDeclined,
          infoTitle: cl.uiSharedVoucher,
          info: l.hotelBookingsInfoReturned,
          facts: GzFactRow(
            label: l.hotelBookingsFactsLabel,
            children: [GzFactChip(icon: declineIcon(b.rejectReason), label: l.hotelBookingsDeclineReason, value: declineWord(l, b.rejectReason)), date()],
          ),
        );
      case BookingStatus.expired:
        final lapsed = b.expiredReason == ExpiredReason.clientNoConfirmation;
        final hours = hoursText(f, silenceHours(b));
        return StateStrip(
          illustration: GzIllustrationName.hourglass,
          quietTitle: true,
          title: lapsed ? cl.commonStatusHotelLapsed : cl.commonStatusHotelMissed,
          infoTitle: cl.uiSharedVoucher,
          info: l.hotelBookingsInfoReturned,
          facts: GzFactRow(label: l.hotelBookingsFactsLabel, children: [GzFactChip(icon: GzIcons.timer, label: l.hotelBookingsSilence(hours), value: hours), date()]),
        );
      case BookingStatus.cancelled:
        final venue = b.cancelledBy == CancelledBy.venue;
        return StateStrip(
          illustration: GzIllustrationName.calendar,
          quietTitle: true,
          title: cl.commonStatusCancelled,
          infoTitle: cl.uiSharedVoucher,
          info: venue ? l.hotelBookingsInfoVenue : (wasConfirmed(b) ? l.hotelBookingsInfoClientUsed : l.hotelBookingsInfoReturned),
          facts: GzFactRow(
            label: l.hotelBookingsFactsLabel,
            children: [
              GzFactChip(icon: venue ? GzIcons.hotel : GzIcons.user, label: venue ? l.hotelBookingsByVenue : l.hotelBookingsByClient, value: venue ? l.hotelBookingsActorVenue : l.hotelBookingsActorClient),
              date(),
            ],
          ),
        );
      case BookingStatus.completed:
        return StateStrip(
          illustration: GzIllustrationName.seal,
          quietTitle: true,
          title: cl.commonStatusCompleted,
          facts: GzFactRow(label: l.hotelBookingsFactsLabel, children: [GzFactChip(icon: GzIcons.calendarCheck, label: l.hotelBookingsRowDate, value: dayLine(f, b.eventDate, year: true))]),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// What is left to do at the bottom: cancel a confirmed booking (Admin and Manager, reason required) with its terms behind the info glyph.
Widget? detailActions(BuildContext context, DetailModel m, BookingActions act) {
  final b = m.booking;
  if (!(b.status == BookingStatus.confirmed && canChange(m.role))) return null;
  final l = context.l10n;
  return Row(
    children: [
      Expanded(child: GzButton(label: l.hotelBookingsCancelBooking, variant: GzButtonVariant.destructive, fullWidth: true, iconStart: GzIcons.close, onPressed: () => act.cancel(b))),
      const SizedBox(width: GzSpace.s2),
      GzInfoButton(title: l.hotelBookingsCancelInfoTitle, paragraphs: [l.hotelBookingsCancelNote]),
    ],
  );
}

IconData _auditIcon(BookingEvent e) {
  if (e.kind == BookingEventKind.overlay) return GzIcons.calendarDots;
  return switch (e.to) {
    BookingStatus.pending => GzIcons.clock,
    BookingStatus.approved => GzIcons.hourglass,
    BookingStatus.confirmed => GzIcons.check,
    BookingStatus.redeemed => GzIcons.ticket,
    BookingStatus.declined => GzIcons.close,
    BookingStatus.expired => GzIcons.clockOff,
    BookingStatus.cancelled => GzIcons.close,
    BookingStatus.completed => GzIcons.checkDouble,
    _ => GzIcons.check,
  };
}

String _auditLabel(AppL10n l, String lang, Booking b, BookingEvent e) {
  final note = e.note;
  if (note != null) return note.of(lang);
  if (e.kind == BookingEventKind.overlay) return l.hotelBookingsAuditProposal;
  return switch (e.to) {
    BookingStatus.pending => l.hotelBookingsAuditRequested,
    BookingStatus.approved => l.hotelBookingsAuditApproved,
    BookingStatus.confirmed => l.hotelBookingsAuditConfirmed,
    BookingStatus.redeemed => l.hotelBookingsAuditRedeemed,
    BookingStatus.declined => l.hotelBookingsAuditDeclined,
    BookingStatus.expired => b.expiredReason == ExpiredReason.clientNoConfirmation ? l.hotelBookingsAuditLapsed : l.hotelBookingsAuditExpired,
    BookingStatus.cancelled => b.reasonCode == CancelReason.approvalRevoked ? l.hotelBookingsAuditRevoked : l.hotelBookingsAuditCancelled,
    BookingStatus.completed => l.hotelBookingsAuditCompleted,
    _ => l.hotelBookingsAuditUpdated,
  };
}

String _auditWho(AppL10n l, Booking b, BookingEvent e) => switch (e.actor) {
  BookingActor.client => e.actorName ?? b.clientName,
  BookingActor.venue => (e.actorName == null || e.actorName!.isEmpty) ? l.hotelBookingsActorVenue : e.actorName!,
  BookingActor.admin => l.hotelBookingsActorGhazal,
  _ => l.hotelBookingsActorSystem,
};

/// Who did what and when: one row that opens the trail in a sheet, so the screen itself carries no list of events.
class DetailAudit extends StatelessWidget {
  const DetailAudit({required this.b, super.key});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GzIconListRow(
      flush: true,
      last: true,
      icon: GzIcons.clock,
      title: l.hotelBookingsAuditTitle,
      chevron: true,
      onPressed: () => showGzInfoSheet(context, title: l.hotelBookingsAuditTitle, children: [_Trail(b: b)]),
    );
  }
}

class _Trail extends StatelessWidget {
  const _Trail({required this.b});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final events = b.events.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < events.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(border: i == events.length - 1 ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: GzSize.avatarSm,
                      height: GzSize.avatarSm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
                      child: GzIcon(_auditIcon(events[i]), size: GzIconSize.sm, tone: GzIconTone.secondary),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzText(_auditLabel(l, lang, b, events[i]), role: GzTextRole.bodyS, color: c.textStrong),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GzUserText(_auditWho(l, b, events[i]), role: GzTextRole.caption, color: c.textSecondary),
                            GzText(' · ', role: GzTextRole.caption, color: c.textSecondary),
                            GzText('${dayMonthShort(f, events[i].at)} ${f.time(events[i].at)}', role: GzTextRole.caption, color: c.textSecondary, figures: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
