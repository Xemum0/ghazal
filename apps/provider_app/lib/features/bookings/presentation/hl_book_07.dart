// HL-BOOK-07 Voucher redeemed (sheet; web `HL-BOOK-07.tsx`). Requirement IDs: HA-VCH-01, HA-VCH-05, HA-VCH-03.
// The confirmation after a redemption (ADR 0033): the request is now Redeemed, the voucher used, and the venue's next step is simply to honour
// the voucher price it showed. One short success moment (a drawing, no confetti): the voucher price as one figure (the sentence behind an info
// glyph), then the facts of the visit as glyphs and values. Payment to the venue happens off-app: no amount due. "Done" returns to the scanner,
// "View booking" opens HL-BOOK-03 at the voucher panel. Params: `bookingId` (default: a redeemed request of the seed).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart' show partnerStaffProvider;
import '../../../l10n/l10n.dart';
import '../application/bookings_data.dart';
import 'widgets/bk_bits.dart';
import 'widgets/bk_sheet.dart';

class HlBook07Screen extends ConsumerWidget {
  const HlBook07Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final lang = context.gz.locale.languageCode;
    final id = (nav.params['bookingId'] as String?) ?? kFrameBookingIds['redeemed']!;
    final async = ref.watch(bookingDetailProvider(id));
    final staff = ref.watch(partnerStaffProvider).value ?? const <StaffMember>[];

    Widget body(PartnerRequestDetail d) {
      final b = d.booking;
      final first = b.clientName.trim().split(RegExp(r'\s+')).first;
      final guests = b.sections.fold<int>(0, (n, s) => n + s.guests);
      final at = b.redeemedAt;
      // The seed keeps the Latin name; the staff list gives the Arabic one (the web's useStaffName).
      final who = staff.where((s) => s.userId == b.redeemedBy || s.nameLatin == b.redeemedBy).firstOrNull;
      final by = (b.redeemedBy == null || b.redeemedBy!.isEmpty)
          ? l.hotelBookingsActorVenue
          : (who == null ? b.redeemedBy! : (lang == 'ar' ? who.name : who.nameLatin));
      final hall = b.sections.isEmpty ? '' : d.halls.where((h) => h.id == b.sections.first.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ExcludeSemantics(child: GzIllustration(GzIllustrationName.partnerRedeemed, size: GzIllustrationSize.lg)),
          ),
          const SizedBox(height: GzSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: cl.commonVoucherPrice,
                child: GzPrice(fils: b.totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
              ),
              const SizedBox(width: GzSpace.s1),
              GzInfoButton(title: cl.uiSharedVoucher, paragraphs: [l.hotelBookingsRedeemedFine]),
            ],
          ),
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
                Row(
                  children: [
                    ExcludeSemantics(
                      child: GzAvatar(name: b.clientName, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Flexible(
                      child: IntrinsicWidth(
                        child: GzUserText(first, role: GzTextRole.title, color: c.textStrong),
                      ),
                    ),
                    if (d.voucher != null) ...[
                      const SizedBox(width: GzSpace.s3),
                      GzVoucherChip(code: d.voucher!.code, tone: GzVoucherChipTone.quiet),
                    ],
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
                GzFactRow(
                  label: l.hotelBookingsFactsLabel,
                  children: [
                    GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsRowDate, value: dayLine(f, b.eventDate, year: true)),
                    GzFactChip(icon: GzIcons.usersThree, label: l.hotelBookingsFactGuests, value: f.integer(guests)),
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
                GzFactRow(
                  label: l.hotelBookingsFactsLabel,
                  children: [GzFactChip(icon: GzIcons.hall, label: l.hotelBookingsFactHall, value: hall)],
                ),
                const SizedBox(height: GzSpace.s3),
                GzFactRow(
                  label: l.hotelBookingsRowRedeemedBy,
                  children: [
                    GzFactChip(
                      icon: GzIcons.checkCircle,
                      tone: GzFactTone.accent,
                      label: l.hotelBookingsRowRedeemedBy,
                      valueWidget: GzUserText(by, role: GzTextRole.bodyS, color: c.textStrong),
                    ),
                    if (at != null) GzFactChip(icon: GzIcons.clock, label: l.hotelBookingsRowTime, value: '${dayMonthShort(f, at)} ${f.time(at)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return BkSheet(
      title: cl.commonStatusHotelRedeemed,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzButton(label: cl.commonActionDone, size: GzButtonSize.cta, fullWidth: true, onPressed: () => nav.closeSheet()),
          const SizedBox(height: GzSpace.s2),
          GzButton(
            label: l.hotelBookingsViewBooking,
            variant: GzButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () {
              nav.closeSheet();
              nav.push('HL-BOOK-03', params: {'bookingId': id, 'section': 'voucher'});
            },
          ),
        ],
      ),
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 320),
          onRetry: () => ref.invalidate(bookingDetailProvider),
          data: body,
        ),
      ],
    );
  }
}
