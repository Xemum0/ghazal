// DecisionBar (web `DecisionBar.tsx`, ADR 0008 D8 and D12, ADR 0033, ADR 0034): the pinned bar of Booking detail. It carries only the action of
// the status; Call and Chat sit on the client panel above, so the bar never repeats them.
//   Pending    the ONE gold Accept at thumb height, Decline, and a calendar glyph for another date (Accept off with a glyph and one word on a
//              held date). Accepting starts the client's fixed 24 h confirm window.
//   Approved   Revoke approval (Admin and Manager, reason required, a reliability strike).
//   Confirmed  Redeem voucher (the ONE gold action, opens HL-BOOK-06 with the code).
//   Completed  Reply, when a review waits. Every other status has no bar. A Reception user never sees Revoke; an Accountant sees no bar.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/detail_model.dart';
import 'booking_actions.dart';
import 'triage_card.dart' show BkSquareButton, BkTextButton;

/// The pinned bar, or null when the status and role leave nothing to do.
Widget? decisionBar(BuildContext context, DetailModel m, BookingActions act) {
  final b = m.booking;
  final l = context.l10n;
  final cl = context.gzL10n;
  final c = context.gz.colors;
  final role = m.role;
  Widget? content;
  if (b.status == BookingStatus.pending && b.proposal == null) {
    if (!canDecide(role)) return null;
    content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.held) ...[
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              children: [
                GzIcon(GzIcons.lock, size: GzIconSize.xs, tone: GzIconTone.secondary),
                const SizedBox(width: GzSpace.s2),
                Expanded(child: GzText(l.hotelBookingsHeldLine, role: GzTextRole.caption, color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s2),
        ],
        SizedBox(
          height: GzSize.controlCta,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GzButton(label: cl.commonActionAccept, size: GzButtonSize.cta, fullWidth: true, iconStart: GzIcons.check, onPressed: m.held ? null : () => act.acceptBooking(b, m.others)),
              ),
              const SizedBox(width: GzSpace.s2),
              BkTextButton(label: cl.commonActionDecline, onPressed: () => act.decline(b)),
              const SizedBox(width: GzSpace.s2),
              BkSquareButton(icon: GzIcons.calendarDots, label: l.hotelBookingsProposeDate, onPressed: () => act.propose(b)),
            ],
          ),
        ),
      ],
    );
  } else if (b.status == BookingStatus.approved) {
    if (!canContact(role) || !canChange(role)) return null;
    content = GzButton(label: l.hotelBookingsRevokeApproval, variant: GzButtonVariant.destructive, fullWidth: true, iconStart: GzIcons.close, onPressed: () => act.cancel(b));
  } else if (b.status == BookingStatus.confirmed) {
    if (!canRedeem(role)) return null;
    content = GzButton(label: cl.commonRedeemVoucher, size: GzButtonSize.cta, fullWidth: true, iconStart: GzIcons.qrCode, onPressed: () => act.redeem(b, code: m.voucher?.code));
  } else if (b.status == BookingStatus.completed && m.review != null) {
    final id = m.review!.id;
    content = GzButton(label: l.hotelBookingsReplyToReview, variant: GzButtonVariant.secondary, fullWidth: true, iconStart: GzIcons.star, onPressed: () => context.gzNav.push('HL-GROW-06', params: {'reviewId': id}));
  }
  if (content == null) return null;
  return Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
    decoration: BoxDecoration(color: c.surfaceCanvas, border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
    child: content,
  );
}
