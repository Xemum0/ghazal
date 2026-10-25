import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/bookings_model.dart';
import 'bk_common.dart';

/// BookingRow (CL-BKNG-01): one request in the list, in glyphs and figures (ADR 0034). Thumbnail and serif venue name, then the facts as
/// `[calendar] 14 Jan`, the reception symbol and the session glyph, the status chip with the voucher price, then (while live) the compact
/// Booking Thread, whose one line already carries the word and the absolute time. A finished request says what became of the voucher
/// with a ticket glyph and one outcome glyph. The whole card is one target.
class BookingRowCard extends StatelessWidget {
  const BookingRowCard({required this.row, required this.now, required this.onOpen, this.attention = false, super.key});

  final BookingRow row;
  final DateTime now;
  final VoidCallback onOpen;

  /// Drawn as a "Needs you" row: the quiet tint, no gold fill.
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final b = row.booking;
    final variant = bookingVariantOf(b, now);
    final live = bookingGroupOf(variant) != BookingGroup.past;
    final section = b.sections.firstOrNull;
    final cover = row.target.cover;
    final name = context.bi(row.target.name);
    final date = bkDayMon(f, b.eventDate);
    final session = section == null ? null : bkSession(l, section.start);

    // Beyond the thread: a reply deadline for a venue-proposed date, and for a finished request what became of the voucher.
    Widget? mark;
    switch (variant) {
      case BookingVariant.completed || BookingVariant.issueReported:
        mark = _VoucherMark(used: true, label: l.clientBookingsRowVoucherUsed);
      case BookingVariant.cancelledByMe:
        final used = b.confirmedAt != null;
        mark = _VoucherMark(used: used, label: used ? l.clientBookingsRowVoucherUsed : l.clientBookingsRowVoucherBack);
      case BookingVariant.declined || BookingVariant.expiredVenueNoReply || BookingVariant.expiredNotConfirmed || BookingVariant.cancelledByVenue:
        mark = _VoucherMark(used: false, label: l.clientBookingsRowVoucherBack);
      default:
    }
    final foot = variant == BookingVariant.venueProposedDate && b.proposal != null
        ? GzFactChip(
            icon: GzIcons.timer,
            tone: GzFactTone.accent,
            label: l.clientBookingsRowReplyBy,
            value: bkStamp(f, b.proposal!.expiresAt),
            small: true,
          )
        : null;

    return GzPressable(
      key: ValueKey<String>('bookings.row.${b.id}'),
      onPressed: onOpen,
      semanticLabel: '$name, $date',
      builder: (context, st) => Container(
        padding: GzSpace.panel,
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : (attention ? c.surfaceTintSoft : c.surfaceRaised),
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: BkGap(
          children: [
            Row(
              children: [
                Container(
                  width: GzSize.thumbMd,
                  height: GzSize.thumbMd,
                  decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.smAll),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: cover != null
                      ? SizedBox.expand(child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl)))
                      : const GzMonogram(size: GzMonogramSize.sm),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzText(name, role: GzTextRole.d1, color: c.textStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: GzSpace.s1),
                      GzFactRow(
                        children: [
                          GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsFactDate, value: date, small: true, tone: GzFactTone.muted),
                          if (section != null)
                            GzFactChip(
                              icon: bkAudienceGlyph(section.audience),
                              label: bkAudienceLabel(l, section.audience),
                              small: true,
                              tone: GzFactTone.muted,
                            ),
                          if (session != null) GzFactChip(icon: session.icon, label: session.label, small: true, tone: GzFactTone.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: GzSpace.s2,
                    runSpacing: GzSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [GzStatusPill(status: bookingPillOf(variant)), ?mark],
                  ),
                ),
                const SizedBox(width: GzSpace.s2),
                GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: context.gzL10n.commonVoucherPrice),
                const SizedBox(width: GzSpace.s1),
                GzPrice(fils: b.totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
              ],
            ),
            if (live) GzBookingThread(booking: b, variant: GzBookingThreadVariant.compact),
            ?foot,
          ],
        ),
      ),
    );
  }
}

/// A ticket glyph and one outcome glyph: the voucher came back (undo) or was used up (double check). The word is the accessible name.
class _VoucherMark extends StatelessWidget {
  const _VoucherMark({required this.used, required this.label});

  final bool used;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s1),
          GzIcon(used ? GzIcons.checkDouble : GzIcons.undo, size: GzIconSize.xs, color: c.iconSecondary),
        ],
      ),
    );
  }
}
