import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/bookings_data.dart';
import '../../application/bookings_model.dart';
import 'bk_common.dart';
import 'state_parts.dart';

/// What the state block and the pinned bar need from the detail screen.
class DetailActions {
  const DetailActions({
    required this.edit,
    required this.cancel,
    required this.confirm,
    required this.proposal,
    required this.voucher,
    required this.visit,
    required this.calendar,
    required this.issue,
    required this.similar,
    required this.again,
    required this.review,
  });

  final VoidCallback edit;
  final VoidCallback cancel;
  final VoidCallback confirm;
  final VoidCallback proposal;
  final VoidCallback voucher;
  final VoidCallback visit;
  final VoidCallback calendar;
  final VoidCallback issue;
  final VoidCallback similar;
  final VoidCallback again;
  final VoidCallback review;
}

/// A struck day (the date that was asked for, before the venue proposed another).
class _Struck extends StatelessWidget {
  const _Struck(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        softWrap: false,
        style: gz
            .text(GzTextRole.figCaption)
            .copyWith(color: gz.colors.textSecondary, decoration: TextDecoration.lineThrough, decorationColor: gz.colors.textSecondary),
      ),
    );
  }
}

/// The state of the request under the Booking Thread (web `block`): a glyph or drawing, at most three words, facts and the actions.
Widget? detailStateBlock(BuildContext context, BookingFacts facts, BookingVariant v, DateTime now, DetailActions go) {
  final l = context.l10n;
  final f = context.gzFormat;
  final common = context.gzL10n;
  final b = facts.booking;
  final name = context.bi(facts.target.name);
  final visitable = facts.venue != null && facts.venue!.type != VenueType.governmental && _visitableVariants.contains(v);

  Widget whenFact(DateTime? at, String label, IconData icon) => GzFactRow(
    children: at == null ? const <Widget>[] : [GzFactChip(icon: icon, label: label, value: bkStamp(f, at), small: true, tone: GzFactTone.muted)],
  );
  final lastEvent = b.events.isEmpty ? null : b.events.last.at;
  GzButton edit() => GzButton(fullWidth: true, spill: true, label: common.commonActionEdit, variant: GzButtonVariant.secondary, iconStart: GzIcons.edit, onPressed: go.edit);
  GzButton withdraw() => GzButton(
    fullWidth: true,
    spill: true,
    label: l.clientBookingsPendingWithdraw,
    variant: GzButtonVariant.destructive,
    iconStart: GzIcons.undo,
    onPressed: go.cancel,
  );

  switch (v) {
    case BookingVariant.pending:
      return Row(
        children: [
          Expanded(child: edit()),
          const SizedBox(width: GzSpace.s3),
          Expanded(child: withdraw()),
          const SizedBox(width: GzSpace.s3),
          GzInfoButton(title: l.clientBookingsPendingTitle, paragraphs: [l.clientBookingsPendingBody]),
        ],
      );
    case BookingVariant.pendingDateHeld:
      return StateStrip(
        icon: GzIcons.hourglass,
        tone: StripTone.pending,
        title: l.clientBookingsPendingHeldTitle,
        info: GzInfoButton(title: l.clientBookingsPendingHeldTitle, paragraphs: [l.clientBookingsPendingHeld]),
        actions: [edit(), withdraw()],
      );
    case BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour:
      return b.confirmBy == null ? null : ConfirmTimer(deadline: b.confirmBy!, now: now);
    case BookingVariant.confirmed:
      return StateStrip(
        icon: GzIcons.checkCircle,
        tone: StripTone.success,
        plain: true,
        facts: const PaySteps(),
        info: GzInfoButton(title: l.clientBookingsConfirmedInfoTitle, paragraphs: [l.clientBookingsConfirmedPay(name)]),
        actions: [
          GzButton(fullWidth: true, spill: true, label: l.clientBookingsAddToCalendar, variant: GzButtonVariant.secondary, iconStart: GzIcons.calendarPlus, onPressed: go.calendar),
          if (visitable)
            GzButton(fullWidth: true, spill: true, label: l.clientBookingsBookVisit, variant: GzButtonVariant.secondary, iconStart: GzIcons.calendarCheck, onPressed: go.visit),
        ],
      );
    case BookingVariant.voucherRedeemed:
      return StateStrip(
        icon: GzIcons.ticket,
        tone: StripTone.success,
        illustration: GzIllustrationName.voucher,
        facts: GzFactRow(
          children: [
            if (b.redeemedAt != null) GzFactChip(icon: GzIcons.calendarCheck, label: l.clientBookingsRedeemedOn, value: bkDayYear(f, b.redeemedAt!)),
            GzFactChip(
              icon: GzIcons.coins,
              label: l.clientBookingsRedeemedPrice,
              valueWidget: GzPrice(fils: b.totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
            ),
          ],
        ),
      );
    case BookingVariant.venueProposedDate:
      final expires = b.proposal?.expiresAt;
      return StateStrip(
        icon: GzIcons.calendarDots,
        tone: StripTone.pending,
        facts: GzFactRow(
          children: [
            GzFactChip(
              icon: GzIcons.calendarX,
              label: l.clientBookingsProposedWas,
              valueWidget: _Struck(bkDayMon(f, b.eventDate)),
              small: true,
              tone: GzFactTone.muted,
            ),
            if (expires != null)
              GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.clientBookingsProposedReply, value: bkStamp(f, expires), small: true),
          ],
        ),
      );
    case BookingVariant.declined:
      final why = switch (b.rejectReason) {
        RejectReason.capacityMismatch => l.clientBookingsDeclinedCapacity,
        RejectReason.packageNotOffered => l.clientBookingsDeclinedPackage,
        RejectReason.other => l.clientBookingsDeclinedOther,
        _ => l.clientBookingsDeclinedDate,
      };
      return StateStrip(icon: GzIcons.close, tone: StripTone.danger, illustration: GzIllustrationName.envelope, title: why);
    case BookingVariant.expiredVenueNoReply:
      return StateStrip(
        icon: GzIcons.clockOff,
        illustration: GzIllustrationName.hourglass,
        title: l.clientBookingsExpiredTitle,
        facts: b.respondBy == null ? null : whenFact(b.respondBy, l.clientBookingsExpiredDeadline, GzIcons.clockOff),
      );
    case BookingVariant.expiredNotConfirmed:
      return StateStrip(
        icon: GzIcons.clockOff,
        illustration: GzIllustrationName.clock,
        title: l.clientBookingsExpiredConfirmTitle,
        facts: b.confirmBy == null ? null : whenFact(b.confirmBy, l.clientBookingsExpiredDeadline, GzIcons.clockOff),
        info: GzInfoButton(title: l.clientBookingsExpiredConfirmTitle, paragraphs: [l.clientBookingsExpiredConfirm(bkDayFull(f, b.eventDate))]),
      );
    case BookingVariant.cancelledByMe:
      return StateStrip(
        icon: GzIcons.close,
        illustration: GzIllustrationName.calendar,
        title: l.clientBookingsCancelledByYou,
        facts: lastEvent == null ? null : whenFact(lastEvent, l.clientBookingsCancelledOn, GzIcons.calendar),
      );
    case BookingVariant.cancelledByVenue:
      return StateStrip(
        icon: GzIcons.close,
        illustration: GzIllustrationName.calendar,
        title: l.clientBookingsCancelledByVenue,
        facts: lastEvent == null ? null : whenFact(lastEvent, l.clientBookingsCancelledOn, GzIcons.calendar),
      );
    case BookingVariant.completed:
      return StateStrip(
        icon: GzIcons.checkDouble,
        illustration: GzIllustrationName.rings,
        actions: [
          GzButton(label: l.clientBookingsIssueOpen, variant: GzButtonVariant.tertiary, iconStart: GzIcons.flag, onPressed: go.issue),
          GzFactChip(icon: GzIcons.timer, label: l.clientBookingsIssueUntil, value: issueUntilText(f, b), small: true, tone: GzFactTone.muted),
        ],
      );
    case BookingVariant.issueReported:
      return StateStrip(
        icon: GzIcons.flag,
        illustration: GzIllustrationName.chat,
        title: l.clientBookingsIssueReportedTitle,
        info: GzInfoButton(title: l.clientBookingsIssueReportedTitle, paragraphs: [l.clientBookingsIssueReportedBody]),
      );
  }
}

const Set<BookingVariant> _visitableVariants = {
  BookingVariant.pending,
  BookingVariant.pendingDateHeld,
  BookingVariant.venueProposedDate,
  BookingVariant.approvedConfirmWindow,
  BookingVariant.approvedLastHour,
  BookingVariant.confirmed,
};

/// True when the visit button belongs to this variant.
bool bookingVisitable(BookingFacts facts, BookingVariant v) =>
    facts.venue != null && facts.venue!.type != VenueType.governmental && _visitableVariants.contains(v);

/// The last day a problem can be reported: 72 hours after the event (the day after, plus the report window).
DateTime issueUntilOf(Booking b, int reportHours) {
  final done = b.completedAt;
  if (done != null) return done.add(Duration(hours: reportHours));
  final d = b.eventDate;
  return DateTime(d.year, d.month, d.day, 12).add(Duration(hours: 24 + reportHours));
}

String issueUntilText(GzFormat f, Booking b) => bkDayMon(f, issueUntilOf(b, 72));

/// The pinned primary action of the state, or null.
Widget? detailBar(BuildContext context, Booking b, BookingVariant v, DetailActions go, {required bool offline}) {
  final l = context.l10n;
  final c = context.gz.colors;
  switch (v) {
    case BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour:
      return GzActionBar(
        summaryValue: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: context.gzL10n.commonVoucherPrice),
            const SizedBox(width: GzSpace.s1),
            GzPrice(fils: b.totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
          ],
        ),
        action: GzActionBarAction(label: context.gzL10n.commonConfirmBooking, onPressed: offline ? null : go.confirm, disabled: offline),
      );
    case BookingVariant.confirmed:
      return GzActionBar(
        action: GzActionBarAction(label: l.clientBookingsShowVoucher, onPressed: go.voucher),
      );
    case BookingVariant.venueProposedDate:
      return GzActionBar(
        action: GzActionBarAction(label: l.clientBookingsChooseDate, onPressed: go.proposal),
      );
    case BookingVariant.expiredVenueNoReply:
      return GzActionBar(
        action: GzActionBarAction(label: l.clientBookingsSendSimilar, onPressed: go.similar),
      );
    case BookingVariant.expiredNotConfirmed:
      return GzActionBar(
        action: GzActionBarAction(label: l.clientBookingsSendNew, onPressed: go.again),
      );
    case BookingVariant.completed:
      return GzActionBar(
        action: GzActionBarAction(label: l.clientBookingsWriteReview, onPressed: go.review),
      );
    default:
      return null;
  }
}
