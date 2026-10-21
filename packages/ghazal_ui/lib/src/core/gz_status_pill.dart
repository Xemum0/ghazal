import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_format_scope.dart';

/// Which side reads the status: the partner app has its own wording where it differs (Awaiting client, Declined, Lapsed).
enum GzStatusAudience { client, hotel }

/// Treatments (ADR 0003 D7 carried into ADR 0033): waiting on the other side = gold tint, waiting on you = gold outline, done =
/// green, ended without a result = neutral outline, a refused request = danger.
enum GzStatusTone { pending, pendingOutline, success, danger, dangerOutline, neutral, neutralOutline, rose }

/// Every request status of ADR 0033 D3, the chips beside a status, voucher, visit and listing states and every availability state.
/// Always icon plus label, never colour alone.
enum GzStatus {
  // request statuses
  pending(GzStatusTone.pending),
  approved(GzStatusTone.pendingOutline),
  confirmed(GzStatusTone.success),
  redeemed(GzStatusTone.success),
  completed(GzStatusTone.neutral),
  declined(GzStatusTone.danger),
  expired(GzStatusTone.neutralOutline),
  cancelled(GzStatusTone.neutral),
  dateProposed(GzStatusTone.pendingOutline),
  missed(GzStatusTone.neutralOutline),
  lapsed(GzStatusTone.neutralOutline),
  urgent(GzStatusTone.danger),
  requested(GzStatusTone.pending),
  rejected(GzStatusTone.danger),
  reschedulePending(GzStatusTone.pendingOutline),
  // voucher states
  voucherUnpaid(GzStatusTone.pendingOutline),
  voucherActive(GzStatusTone.success),
  voucherBound(GzStatusTone.pending),
  voucherUsed(GzStatusTone.neutral),
  voucherExpired(GzStatusTone.neutralOutline),
  voucherForfeited(GzStatusTone.dangerOutline),
  voucherCreditIssued(GzStatusTone.neutralOutline),
  voucherCredit(GzStatusTone.rose),
  // site visits
  visitRequested(GzStatusTone.pending),
  visitConfirmed(GzStatusTone.success),
  visitReschedule(GzStatusTone.pendingOutline),
  visitArrived(GzStatusTone.success),
  visitCompleted(GzStatusTone.neutral),
  visitDeclined(GzStatusTone.danger),
  visitCancelled(GzStatusTone.neutral),
  visitMissed(GzStatusTone.neutralOutline),
  // listing lifecycle
  listingDraft(GzStatusTone.neutralOutline),
  listingPayment(GzStatusTone.pendingOutline),
  listingReview(GzStatusTone.pending),
  listingApproved(GzStatusTone.success),
  listingRejected(GzStatusTone.danger),
  listingActive(GzStatusTone.success),
  listingExpired(GzStatusTone.neutralOutline),
  listingPaused(GzStatusTone.neutralOutline),
  // availability
  available(GzStatusTone.success),
  held(GzStatusTone.pending),
  booked(GzStatusTone.neutral),
  blocked(GzStatusTone.neutralOutline),
  unavailable(GzStatusTone.neutralOutline),
  past(GzStatusTone.neutralOutline);

  const GzStatus(this.tone);

  final GzStatusTone tone;

  /// The glyph of the status.
  IconData get icon => switch (this) {
        pending || requested || visitRequested || listingReview => GzIcons.clock,
        approved || voucherUnpaid || held => GzIcons.hourglass,
        confirmed || listingApproved || available => GzIcons.check,
        redeemed || voucherActive => GzIcons.ticket,
        completed || voucherUsed || visitCompleted => GzIcons.checkDouble,
        declined || rejected || cancelled || visitCancelled || listingRejected => GzIcons.close,
        expired || missed || lapsed || voucherExpired || listingExpired => GzIcons.clockOff,
        dateProposed || reschedulePending || visitReschedule => GzIcons.calendarDots,
        urgent => GzIcons.warning,
        voucherBound => GzIcons.link,
        voucherForfeited => GzIcons.xCircle,
        voucherCreditIssued || voucherCredit => GzIcons.gift,
        visitConfirmed || booked => GzIcons.calendarCheck,
        visitArrived => GzIcons.pin,
        visitDeclined || unavailable => GzIcons.calendarX,
        visitMissed => GzIcons.userMinus,
        listingDraft => GzIcons.edit,
        listingPayment => GzIcons.card,
        listingActive => GzIcons.megaphone,
        listingPaused => GzIcons.pause,
        blocked => GzIcons.lock,
        past => GzIcons.calendar,
      };

  /// The shared `common` word of the status (client or partner wording).
  String label(GzL10n l, [GzStatusAudience audience = GzStatusAudience.client]) {
    final hotel = audience == GzStatusAudience.hotel;
    return switch (this) {
      pending || requested => hotel ? l.commonStatusHotelPending : l.commonStatusPending,
      approved => hotel ? l.commonStatusHotelApproved : l.commonStatusApproved,
      confirmed => l.commonStatusConfirmed,
      redeemed => hotel ? l.commonStatusHotelRedeemed : l.commonStatusRedeemed,
      completed => l.commonStatusCompleted,
      declined || rejected => hotel ? l.commonStatusHotelDeclined : l.commonStatusDeclined,
      expired => hotel ? l.commonStatusHotelLapsed : l.commonStatusExpired,
      cancelled => l.commonStatusCancelled,
      dateProposed || reschedulePending => l.commonStatusDateProposed,
      missed => l.commonStatusHotelMissed,
      lapsed => l.commonStatusHotelLapsed,
      urgent => l.commonStatusUrgent,
      voucherUnpaid => l.commonVoucherStatusUnpaid,
      voucherActive => l.commonVoucherStatusActive,
      voucherBound => l.commonVoucherStatusBound,
      voucherUsed => l.commonVoucherStatusUsed,
      voucherExpired => l.commonVoucherStatusExpired,
      voucherForfeited => l.commonVoucherStatusForfeited,
      voucherCreditIssued => l.commonVoucherStatusCreditIssued,
      voucherCredit => l.commonVoucherStatusCredit,
      visitRequested => l.commonVisitStatusRequested,
      visitConfirmed => l.commonVisitStatusConfirmed,
      visitReschedule => l.commonVisitStatusReschedule,
      visitArrived => l.commonVisitStatusArrived,
      visitCompleted => l.commonVisitStatusCompleted,
      visitDeclined => l.commonVisitStatusDeclined,
      visitCancelled => l.commonVisitStatusCancelled,
      visitMissed => l.commonVisitStatusMissed,
      listingDraft => l.commonListingStatusDraft,
      listingPayment => l.commonListingStatusPayment,
      listingReview => l.commonListingStatusReview,
      listingApproved => l.commonListingStatusApproved,
      listingRejected => l.commonListingStatusRejected,
      listingActive => l.commonListingStatusActive,
      listingExpired => l.commonListingStatusExpired,
      listingPaused => l.commonListingStatusPaused,
      available => l.commonAvailabilityAvailable,
      held => l.commonAvailabilityHeld,
      booked => l.commonAvailabilityBooked,
      blocked => l.commonAvailabilityBlocked,
      unavailable => l.commonAvailabilityUnavailable,
      past => l.commonAvailabilityPast,
    };
  }
}

class _GzToneColors {
  const _GzToneColors({required this.bg, required this.border, required this.text, required this.icon});

  final Color? bg;
  final Color? border;
  final Color text;
  final Color icon;
}

_GzToneColors _toneColors(GzColors c, GzStatusTone tone) => switch (tone) {
      GzStatusTone.pending => _GzToneColors(bg: c.statusPendingBg, border: null, text: c.statusPendingText, icon: c.iconAccent),
      GzStatusTone.pendingOutline => _GzToneColors(bg: null, border: c.markState, text: c.statusPendingText, icon: c.iconAccent),
      GzStatusTone.success => _GzToneColors(bg: c.statusSuccessBg, border: null, text: c.statusSuccessText, icon: c.iconSuccess),
      GzStatusTone.danger => _GzToneColors(bg: c.statusDangerBg, border: null, text: c.statusDangerText, icon: c.iconDanger),
      GzStatusTone.dangerOutline => _GzToneColors(bg: null, border: c.statusDangerText, text: c.statusDangerText, icon: c.iconDanger),
      GzStatusTone.neutral => _GzToneColors(bg: c.statusNeutralBg, border: null, text: c.statusNeutralText, icon: c.iconSecondary),
      GzStatusTone.neutralOutline => _GzToneColors(bg: null, border: c.borderStrong, text: c.textSecondary, icon: c.iconSecondary),
      GzStatusTone.rose => _GzToneColors(bg: c.surfaceTint, border: null, text: c.statusNeutralText, icon: c.statusNeutralText),
    };

/// StatusPill: min 24 high, radius 4, icon 16 plus a label from the `pill` role. The label strings are the shared `common`
/// words (client or partner wording); [label] overrides for the rare composed case.
class GzStatusPill extends StatelessWidget {
  const GzStatusPill({required this.status, this.audience = GzStatusAudience.client, this.label, this.hours, this.compact = false, super.key});

  final GzStatus status;
  final GzStatusAudience audience;

  /// Replaces the shared label (a composed string such as a countdown).
  final String? label;

  /// `approved` only: hours left in the confirm window, shown as a compact figure after the word (`Approved 23 h`).
  final int? hours;

  /// Inline padding 4 + hairline instead of 8 + hairline: a pill inside a table cell.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final colors = _toneColors(c, status.tone);
    final word = label ?? status.label(context.gzL10n, audience);
    final timeLeft = hours != null && label == null ? context.gzDuration(hours! * 3600000) : null;
    return Semantics(
      label: timeLeft == null ? word : '$word $timeLeft',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: GzRadius.xsAll,
          border: Border.all(color: colors.border ?? c.scrimClear, width: GzStroke.hair),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.pillMin),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: (compact ? GzSpace.s1 : GzSpace.s2) + GzStroke.hair, vertical: GzSpace.s1 + GzStroke.hair),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(status.icon, size: GzIconSize.xs, color: colors.icon),
                const SizedBox(width: GzSpace.s1),
                Flexible(child: GzText(word, role: GzTextRole.pill, color: colors.text, softWrap: false)),
                if (timeLeft != null) ...[
                  const SizedBox(width: GzSpace.s1),
                  GzNum(timeLeft, role: GzTextRole.figCaption, color: colors.text),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// StatusIcon (ADR 0034): a status as a glyph in a tone disk, with the word as its accessible name. Use it inside a row that
/// already names what it is about; with [showLabel] it IS the [GzStatusPill].
class GzStatusIcon extends StatelessWidget {
  const GzStatusIcon({required this.status, this.audience = GzStatusAudience.client, this.large = false, this.showLabel = false, this.label, super.key});

  final GzStatus status;
  final GzStatusAudience audience;

  /// `false` = 24 disk, glyph 16; `true` = 32 disk, glyph 20.
  final bool large;
  final bool showLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (showLabel) return GzStatusPill(status: status, audience: audience, label: label);
    final c = context.gz.colors;
    final colors = _toneColors(c, status.tone);
    final d = large ? GzSize.disk : GzSize.pillMin;
    final tone = status.tone;
    final iconColor = tone == GzStatusTone.rose ? c.iconPrimary : colors.icon;
    return Semantics(
      label: label ?? status.label(context.gzL10n, audience),
      image: true,
      excludeSemantics: true,
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.bg,
          border: Border.all(color: colors.border ?? c.scrimClear, width: GzStroke.hair),
        ),
        child: GzIcon(status.icon, size: large ? GzIconSize.sm : GzIconSize.xs, color: iconColor),
      ),
    );
  }
}
