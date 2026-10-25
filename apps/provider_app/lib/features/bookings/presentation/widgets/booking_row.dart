// BkBookingRow (web `BkBookingRow.tsx`, HL-BOOK-02, ADR 0034): one booking that no longer waits for a decision. A monogram, the name as typed and the
// voucher price, then ONE line of facts (date, section, session, guests) that ends with the state as a glyph: the time left to confirm, a ticket
// for a voucher not yet redeemed, a check and its day for a redeemed one. A Past row leads with its one-word status pill and the reason as a
// glyph. A search query sets the matched text in weight 700. The whole row is one target that opens Booking detail.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/bookings_model.dart';
import 'bk_bits.dart';

/// A text with the folded match of [query] set in the title weight on a tint (the web `<mark>`).
class HitText extends StatelessWidget {
  const HitText({required this.text, required this.role, this.query, this.color, this.maxLines, super.key});

  final String text;
  final GzTextRole role;
  final String? query;
  final Color? color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final parts = query == null ? null : splitHit(text, query!);
    if (parts == null) return GzUserText(text, role: role, color: color, maxLines: maxLines);
    final gz = context.gz;
    final c = gz.colors;
    final style = GzType.style(Locale(gzScriptOf(text)), role).copyWith(color: color ?? c.textPrimary, decoration: TextDecoration.none);
    final hit = style.copyWith(fontWeight: gz.text(GzTextRole.uiTitle).fontWeight, color: c.textStrong, backgroundColor: c.surfaceTint);
    return Text.rich(
      TextSpan(children: [TextSpan(text: parts.$1), TextSpan(text: parts.$2, style: hit), TextSpan(text: parts.$3)]),
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

class BkBookingRow extends StatelessWidget {
  const BkBookingRow({required this.row, required this.exact, this.query, this.onOpen, this.last = false, this.sectioned = false, super.key});

  final PartnerRequestRow row;
  final bool exact;
  final String? query;
  final VoidCallback? onOpen;
  final bool last;

  /// The row sits under a section that names its state (Awaiting, Confirmed, Redeemed): a glyph that only repeats the section is left out.
  final bool sectioned;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final b = row.booking;
    final now = f.now();
    final refHit = query == null ? null : splitHit(b.ref, query!);
    final actor = b.redeemedBy == null || b.redeemedBy!.isEmpty ? l.hotelBookingsActorVenue : b.redeemedBy!;

    Widget? tail;
    Widget? pill;
    switch (b.status) {
      case BookingStatus.pending:
        final p = b.proposal;
        if (p != null) {
          final left = durationOf(context, minutesBetween(now, p.expiresAt), lead: true);
          tail = RowTail(icon: GzIcons.hourglass, tone: TailTone.gold, label: l.hotelBookingsAwaitingCouple, figure: left.visual);
        }
      case BookingStatus.approved:
        final by = b.confirmBy;
        if (by != null) {
          final left = durationOf(context, minutesBetween(now, by));
          tail = RowTail(icon: GzIcons.hourglass, tone: TailTone.gold, label: l.hotelBookingsConfirmLeft(left.spoken), figure: left.visual);
        }
      case BookingStatus.confirmed:
        tail = sectioned ? null : RowTail(icon: GzIcons.ticket, label: l.hotelBookingsNotRedeemed);
      case BookingStatus.redeemed:
        final at = b.redeemedAt;
        tail = RowTail(
          icon: GzIcons.checkCircle,
          tone: TailTone.success,
          label: at == null ? l.hotelBookingsRedeemedPlain : l.hotelBookingsRedeemedBy(actor, dayMonthShort(f, at)),
          figure: at == null ? null : dayMonthShort(f, at),
        );
      case BookingStatus.completed:
        pill = const GzStatusPill(status: GzStatus.completed, audience: GzStatusAudience.hotel);
      case BookingStatus.cancelled:
        final byVenue = b.cancelledBy == CancelledBy.venue;
        pill = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          children: [
            const GzStatusPill(status: GzStatus.cancelled, audience: GzStatusAudience.hotel),
            RowTail(icon: byVenue ? GzIcons.hotel : GzIcons.user, label: byVenue ? l.hotelBookingsByVenue : l.hotelBookingsByClient),
          ],
        );
      case BookingStatus.declined:
        pill = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          children: [
            const GzStatusPill(status: GzStatus.declined, audience: GzStatusAudience.hotel),
            RowTail(icon: declineIcon(b.rejectReason), label: declineWord(l, b.rejectReason)),
          ],
        );
      case BookingStatus.expired:
        final hours = hoursText(f, silenceHours(b));
        pill = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          children: [
            GzStatusPill(status: b.expiredReason == ExpiredReason.clientNoConfirmation ? GzStatus.lapsed : GzStatus.missed, audience: GzStatusAudience.hotel),
            RowTail(icon: GzIcons.timer, label: l.hotelBookingsSilence(hours), figure: hours),
          ],
        );
      default:
        break;
    }

    return GzPressable(
      onPressed: onOpen ?? () {},
      semanticLabel: '${b.clientName}. ${dayLine(f, b.eventDate, year: true)}',
      borderRadius: BorderRadius.zero,
      scale: 1,
      minHeight: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair)),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: GzAvatar(name: b.clientName, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans)),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: HitText(text: b.clientName, role: GzTextRole.title, query: query, color: c.textStrong, maxLines: 2)),
                      const SizedBox(width: GzSpace.s3),
                      GzPrice(fils: b.totals.voucherTotal.fils, mode: exact ? GzMoneyMode.exact : GzMoneyMode.browse, size: GzPriceSize.strong),
                    ],
                  ),
                  if (refHit != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: HitText(text: b.ref, role: GzTextRole.caption, query: query, color: c.textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: GzSpace.s1),
                  BookingFacts(booking: b, withDate: true, small: true, tail: tail),
                  if (pill != null) ...[const SizedBox(height: GzSpace.s1), Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: pill)],
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            ExcludeSemantics(child: GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, tone: GzIconTone.secondary)),
          ],
        ),
      ),
    );
  }
}
