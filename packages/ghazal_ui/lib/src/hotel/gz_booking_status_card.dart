import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, BookingStatus, ProposalStatus, Voucher, VoucherStatus;

import '../client/client.dart' show GzBookingThread, GzBookingThreadVariant;
import '../core/core.dart';
import '../foundation.dart';
import '../voucher/gz_confirm_left.dart';
import '../voucher/gz_voucher_chip.dart';

/// The request status as the pill shows it (partner wording).
GzStatus gzStatusOfBooking(BookingStatus s) => switch (s) {
  BookingStatus.approved => GzStatus.approved,
  BookingStatus.declined => GzStatus.declined,
  BookingStatus.expired => GzStatus.expired,
  BookingStatus.confirmed => GzStatus.confirmed,
  BookingStatus.redeemed => GzStatus.redeemed,
  BookingStatus.completed => GzStatus.completed,
  BookingStatus.cancelled => GzStatus.cancelled,
  BookingStatus.pending || BookingStatus.unknown => GzStatus.pending,
};

/// BookingStatusCard: where a request stands, for the partner (ADR 0033 D3, direction 4): the status pill (partner wording) and the
/// booking reference, the vertical Booking Thread (past knots with absolute times, at most two faint future knots), then the VOUCHER
/// block instead of a payment schedule: the voucher chip with its code, what the client pays the venue directly (the voucher total,
/// the standard price struck through) and, while the request waits on the client, the calm 24 hour confirm line. "Redeem voucher" is
/// offered once the request is confirmed, to the roles that may (Admin, Manager, Reception; ADR 0008 D12). A counter-offer is a
/// chip, never a status. No payment milestones, no cash, no balance: the event is settled between the client and the venue off-app.
class GzBookingStatusCard extends StatelessWidget {
  const GzBookingStatusCard({required this.booking, this.voucher, this.canRedeem = false, this.onRedeem, super.key});

  final Booking booking;

  /// The voucher bound to the request (the request detail carries it; the widget never fetches).
  final Voucher? voucher;

  /// Offer "Redeem voucher" on a confirmed request (roles that may redeem).
  final bool canRedeem;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final totals = booking.totals;
    final hasVoucherPrice = totals.voucherTotal.fils < totals.standardTotal.fils;
    final v = voucher;
    final awaiting = booking.status == BookingStatus.approved && booking.confirmBy != null;
    final redeemedAt = booking.redeemedAt;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s4),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s3,
              runSpacing: GzSpace.s2,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  children: [
                    GzStatusPill(status: gzStatusOfBooking(booking.status), audience: GzStatusAudience.hotel),
                    if (booking.proposal?.status == ProposalStatus.proposed) const GzStatusPill(status: GzStatus.dateProposed),
                  ],
                ),
                GzText.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l.uiHotelStatusRef} '),
                      GzFigures.span(context, booking.ref, role: GzTextRole.caption),
                    ],
                  ),
                  role: GzTextRole.caption,
                  color: c.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s4),
            GzBookingThread(booking: booking, voucherAt: v?.purchasedAt, variant: GzBookingThreadVariant.vertical),
            if (awaiting) ...[const SizedBox(height: GzSpace.s4), _AwaitingLine(deadline: booking.confirmBy!)],
            const SizedBox(height: GzSpace.s4),
            Container(
              padding: const EdgeInsets.only(top: GzSpace.s4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(l.uiHotelStatusVoucher, role: GzTextRole.label, color: c.textPrimary, header: true),
                  if (v != null) ...[
                    const SizedBox(height: GzSpace.s3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s3,
                      runSpacing: GzSpace.s2,
                      children: [
                        GzVoucherChip(
                          code: v.code,
                          tone: v.status == VoucherStatus.used ? GzVoucherChipTone.quiet : GzVoucherChipTone.bound,
                        ),
                        GzNum(v.code, role: GzTextRole.figTitle, color: c.textStrong),
                      ],
                    ),
                  ],
                  const SizedBox(height: GzSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: GzText(l.uiHotelStatusClientPays, role: GzTextRole.title, color: c.textStrong),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      GzPrice(fils: totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                    ],
                  ),
                  if (hasVoucherPrice) ...[
                    const SizedBox(height: GzSpace.s3),
                    GzText.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l.uiHotelStatusStandard} '),
                          GzFigures.span(
                            context,
                            f.money(totals.standardTotal.fils, const MoneyOptions(mode: MoneyMode.exact)),
                            role: GzTextRole.caption,
                            style: const TextStyle(decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ),
                      role: GzTextRole.caption,
                      color: c.textSecondary,
                    ),
                  ],
                  const SizedBox(height: GzSpace.s3),
                  GzText(l.uiHotelStatusDirect, role: GzTextRole.caption, color: c.textSecondary),
                  if (booking.status == BookingStatus.redeemed && redeemedAt != null) ...[
                    const SizedBox(height: GzSpace.s3),
                    Row(
                      children: [
                        GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess),
                        const SizedBox(width: GzSpace.s1),
                        Expanded(
                          child: GzText(
                            booking.redeemedBy != null
                                ? l.uiHotelStatusRedeemed(f.dateTime(redeemedAt, DateStyle.short), booking.redeemedBy!)
                                : l.uiHotelStatusRedeemedNoName(f.dateTime(redeemedAt, DateStyle.short)),
                            figures: true, role: GzTextRole.caption,
                            color: c.textSuccess,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (canRedeem && booking.status == BookingStatus.confirmed) ...[
                    const SizedBox(height: GzSpace.s3),
                    GzButton(label: l.uiHotelStatusRedeem, iconStart: GzIcons.qrCode, fullWidth: true, onPressed: onRedeem ?? () {}),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The calm 24 hour line while the request waits on the client: an hourglass, the deadline and what is left.
class _AwaitingLine extends StatelessWidget {
  const _AwaitingLine({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final left = gzConfirmLeft(f, l, deadline: deadline, now: f.now());
    return Row(
      children: [
        GzIcon(GzIcons.hourglass, size: GzIconSize.xs, color: c.iconAccent),
        const SizedBox(width: GzSpace.s1),
        Expanded(
          child: GzText(
            l.uiHotelStatusAwaiting(f.dateTime(deadline, DateStyle.short), left.text),
            figures: true, role: GzTextRole.caption,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
