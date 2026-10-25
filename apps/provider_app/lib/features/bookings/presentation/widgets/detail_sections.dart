// The body sections of Booking detail (web `DetailSections.tsx`, ADR 0034): special requests, the client, the counter-offer when one is out,
// the event (hall photograph, time, section, guests, package, extras), the price at the voucher (one big figure, the standard struck, the
// saving) and the voucher panel once the request is confirmed or used. No payment, cash, invoice or payout section exists: the one sentence
// about what the venue collects directly sits behind an info glyph.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/bookings_data.dart';
import '../../application/detail_model.dart';
import 'bk_bits.dart';
import 'booking_actions.dart';
import 'detail_parts.dart';
import 'triage_card.dart' show BkStruckMoney;

class DetailSpecial extends StatefulWidget {
  const DetailSpecial({required this.text, super.key});

  final String text;

  @override
  State<DetailSpecial> createState() => _DetailSpecialState();
}

class _DetailSpecialState extends State<DetailSpecial> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final long = widget.text.length > 60;
    return BkPanel(
      tone: PanelTone.tint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: GzSpace.s1),
            child: Semantics(label: l.hotelBookingsSpecialRequests, excludeSemantics: true, child: GzIcon(GzIcons.notes, size: GzIconSize.sm, tone: GzIconTone.accent)),
          ),
          const SizedBox(width: GzSpace.s2),
          Expanded(child: GzUserText(widget.text, role: GzTextRole.body, color: c.textStrong, maxLines: _open ? null : 2)),
          if (long)
            GzIconButton(
              icon: _open ? GzIcons.chevronUp : GzIcons.chevronDown,
              iconSize: GzIconSize.sm,
              label: _open ? l.hotelBookingsShowLess : l.hotelBookingsShowMore,
              expanded: _open,
              onPressed: () => setState(() => _open = !_open),
            ),
        ],
      ),
    );
  }
}

class DetailClient extends StatelessWidget {
  const DetailClient({required this.m, required this.act, super.key});

  final DetailModel m;
  final BookingActions act;

  @override
  Widget build(BuildContext context) {
    final b = m.booking;
    final l = context.l10n;
    final c = context.gz.colors;
    final contact = canContact(m.role);
    return BkPanel(
      child: Row(
        children: [
          ExcludeSemantics(child: GzAvatar(name: b.clientName, size: GzAvatarSize.md, voice: GzAvatarVoice.sans)),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              children: [
                IntrinsicWidth(child: GzUserText(b.clientName, role: GzTextRole.title, color: c.textStrong, maxLines: 2)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (b.verifiedPhone) Semantics(label: l.hotelBookingsVerified, excludeSemantics: true, child: GzIcon(GzIcons.verified, size: GzIconSize.xs, tone: GzIconTone.success)),
                    if (b.verifiedPhone && b.firstBooking) const SizedBox(width: GzSpace.s1),
                    if (b.firstBooking) Semantics(label: l.hotelBookingsFirstBooking, excludeSemantics: true, child: GzIcon(GzIcons.sparkle, size: GzIconSize.xs, tone: GzIconTone.accent)),
                  ],
                ),
              ],
            ),
          ),
          if (contact) ...[
            const SizedBox(width: GzSpace.s3),
            GzIconButton(icon: GzIcons.chat, label: l.hotelBookingsMessageName(b.clientName), variant: GzIconButtonVariant.outline, onPressed: () => act.chatBooking(b, conversationId: m.detail.conversationId)),
            if (b.contact.shared) ...[
              const SizedBox(width: GzSpace.s1),
              GzIconButton(icon: GzIcons.phone, label: l.hotelBookingsCallName(b.clientName), variant: GzIconButtonVariant.outline, onPressed: () => act.call(b)),
            ],
          ],
        ],
      ),
    );
  }
}

/// The hall photograph (an empty room, never a person) or its glyph when the hall has no photo yet; 72 x 56, radius 8.
class _HallThumb extends StatelessWidget {
  const _HallThumb({required this.cover});

  final ImageRef? cover;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    return ExcludeSemantics(
      child: Container(
        width: GzSize.thumbCompactWidth,
        height: GzSize.thumbMd,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
        child: cover == null
            ? GzIcon(GzIcons.hall, size: GzIconSize.md, tone: GzIconTone.secondary)
            : GzPhoto(src: gzImageSrc(cover!.file, cover!.baseUrl), alt: cover!.alt.of(lang)),
      ),
    );
  }
}

class DetailEvent extends ConsumerWidget {
  const DetailEvent({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = m.booking;
    final f = context.gzFormat;
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final venue = b.venueId == null ? null : ref.watch(venueDetailProvider(b.venueId!)).value;
    if (b.sections.isEmpty) {
      return BkPanel(
        child: BkLines(
          lines: [
            BkLine(icon: GzIcons.calendar, label: l.hotelBookingsRowServiceDate, child: _bold(c, f.date(b.eventDate.toString(), DateStyle.short))),
          ],
        ),
      );
    }
    final two = b.sections.length > 1;
    final extras = b.lines.where((x) => x.kind == PriceLineKind.extra).toList();
    final lines = <BkLine>[
      for (final s in b.sections)
        BkLine(
          lead: _HallThumb(cover: venue?.venue.halls.where((h) => h.id == s.hallId).map((h) => h.cover).firstOrNull),
          facts: GzFactRow(
            label: l.hotelBookingsFactsLabel,
            children: [
              GzFactChip(icon: sessionIcon(s.start), label: l.hotelBookingsFactTime, value: sessionRange(f, b.eventDate, s.start, s.end)),
              GzFactChip(icon: sectionIcon(s.audience), label: audienceWord(l, s.audience)),
              GzFactChip(icon: GzIcons.usersThree, label: l.hotelBookingsFactGuests, value: f.integer(s.guests)),
              if (s.billableGuests != s.guests) GzFactChip(icon: GzIcons.receipt, tone: GzFactTone.muted, label: l.hotelBookingsBillable(s.billableGuests), value: f.integer(s.billableGuests)),
            ],
          ),
          child: _bold(c, m.detail.halls.where((h) => h.id == s.hallId).map((h) => h.name.of(lang)).firstOrNull ?? ''),
        ),
      for (final s in b.sections)
        BkLine(
          icon: GzIcons.package,
          label: two ? audienceWord(l, s.audience) : l.hotelBookingsRowPackage,
          child: _bold(c, venue?.packages.where((p) => p.package.id == s.packageId).map((p) => p.package.name.of(lang)).firstOrNull ?? ''),
        ),
      for (final x in extras)
        BkLine(
          icon: GzIcons.plus,
          label: l.hotelBookingsRowExtras,
          trailing: x.qty > 1 ? GzText('×${f.integer(x.qty)}', role: GzTextRole.figBodyS, color: c.textStrong, figures: true) : null,
          child: _bold(c, x.name.of(lang)),
        ),
    ];
    return BkPanel(child: BkLines(lines: lines, label: l.hotelBookingsEventTitle));
  }
}

Widget _bold(GzColors c, String text) => GzUserText(text, role: GzTextRole.title, color: c.textStrong);

/// The price at the voucher: what the venue charges the client directly. The standard price sits beside it, struck, with the client's saving.
class DetailPrice extends StatelessWidget {
  const DetailPrice({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context) {
    final b = m.booking;
    final c = context.gz.colors;
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final t = b.totals;
    final saves = t.standardTotal.fils > t.voucherTotal.fils;
    final itemised = b.lines.length > 1 || t.voucherServiceCharge.fils > 0;
    return BkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: GzSize.avatarSm,
                  height: GzSize.avatarSm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
                  child: GzIcon(GzIcons.ticket, size: GzIconSize.sm, tone: GzIconTone.accent),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BkCopyable(
                    value: f.money(t.voucherTotal.fils, const MoneyOptions(mode: MoneyMode.exact)),
                    child: Semantics(label: cl.commonVoucherPrice, child: GzPrice(fils: t.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total)),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              GzInfoButton(
                title: l.hotelBookingsInfoPriceTitle,
                children: [
                  if (itemised)
                    BkLines(
                      label: l.hotelBookingsPriceTitle,
                      lines: [
                        for (final x in b.lines) BkLine(trailing: BkQuietMoney(fils: x.amount.fils), child: GzUserText(x.name.of(lang), role: GzTextRole.title, color: c.textStrong)),
                        if (t.voucherServiceCharge.fils > 0) BkLine(trailing: BkQuietMoney(fils: t.voucherServiceCharge.fils), child: GzUserText(cl.commonMoneyServiceCharge, role: GzTextRole.title, color: c.textStrong)),
                      ],
                    ),
                  GzText(l.hotelBookingsDirectNote, role: GzTextRole.body, color: c.textPrimary),
                ],
              ),
            ],
          ),
          if (saves) ...[
            const SizedBox(height: GzSpace.s3),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s5,
              runSpacing: GzSpace.s2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(GzIcons.offer, size: GzIconSize.xs, tone: GzIconTone.secondary),
                    const SizedBox(width: GzSpace.s1),
                    BkStruckMoney(fils: t.standardTotal.fils, label: cl.commonStandardPrice, exact: true),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(GzIcons.trendDown, size: GzIconSize.xs, tone: GzIconTone.success),
                    const SizedBox(width: GzSpace.s1),
                    BkQuietMoney(fils: t.savings.fils, label: l.hotelBookingsClientSaves, color: c.textSuccess),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A voucher still waiting on the request shows as the chip in the header; the panel is for a voucher that is confirmed, used or released.
bool voucherVisible(DetailModel m) {
  final v = m.voucher;
  if (v == null) return false;
  return v.status == VoucherStatus.used ||
      v.status == VoucherStatus.active ||
      v.status == VoucherStatus.expired ||
      v.status == VoucherStatus.forfeited ||
      v.status == VoucherStatus.creditIssued ||
      m.booking.status == BookingStatus.confirmed;
}

class DetailVoucher extends StatelessWidget {
  const DetailVoucher({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context) {
    final v = m.voucher;
    if (v == null || !voucherVisible(m)) return const SizedBox.shrink();
    final b = m.booking;
    final l = context.l10n;
    final cl = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final changed = v.status != VoucherStatus.bound && v.status != VoucherStatus.unpaid;
    final last4 = v.code.length > 4 ? v.code.substring(v.code.length - 4) : v.code;
    final by = v.redeemedBy ?? b.redeemedBy;
    final at = v.usedAt ?? b.redeemedAt;
    final (GzStatus pill, String word) = switch (v.status) {
      VoucherStatus.used => (GzStatus.voucherUsed, l.hotelBookingsVoucherRedeemed),
      VoucherStatus.active => (GzStatus.voucherActive, l.hotelBookingsVoucherReturned),
      VoucherStatus.expired => (GzStatus.voucherExpired, l.hotelBookingsVoucherExpired),
      VoucherStatus.forfeited => (GzStatus.voucherForfeited, l.hotelBookingsVoucherNotValid),
      VoucherStatus.creditIssued => (GzStatus.voucherCreditIssued, l.hotelBookingsVoucherNotValid),
      _ => (GzStatus.voucherBound, l.hotelBookingsVoucherBound),
    };
    return Semantics(
      container: true,
      label: cl.uiSharedVoucher,
      child: BkPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: GzSize.avatarSm,
                    height: GzSize.avatarSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
                    child: GzIcon(GzIcons.ticket, size: GzIconSize.sm, tone: GzIconTone.accent),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      label: cl.commonVoucherCode,
                      child: GzLtr(child: GzText('GV-····-$last4', role: GzTextRole.figTitle, color: c.textStrong, figures: true, softWrap: false)),
                    ),
                  ),
                ),
                if (changed) GzStatusPill(status: pill, label: word),
              ],
            ),
            if (v.status == VoucherStatus.used && at != null) ...[
              const SizedBox(height: GzSpace.s3),
              GzFactRow(
                label: l.hotelBookingsVoucherRedeemed,
                children: [
                  GzFactChip(icon: GzIcons.user, label: l.hotelBookingsRowRedeemedBy, valueWidget: GzUserText((by == null || by.isEmpty) ? l.hotelBookingsActorVenue : by, role: GzTextRole.bodyS, color: c.textStrong)),
                  GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsRowDate, value: dayMonthShort(f, at)),
                  GzFactChip(icon: GzIcons.clock, label: l.hotelBookingsRowTime, value: f.time(at)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The counter-offer when one is out: the dates the venue proposed and the window the couple has.
class DetailProposal extends ConsumerWidget {
  const DetailProposal({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = m.booking;
    final p = b.proposal;
    if (p == null) return const SizedBox.shrink();
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final ownHall = b.sections.isEmpty ? null : b.sections.first.hallId;
    final venue = b.venueId == null ? null : ref.watch(venueDetailProvider(b.venueId!)).value;
    String hallName(String id) => venue?.venue.halls.where((h) => h.id == id).map((h) => h.name.of(lang)).firstOrNull ?? '';
    return BkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BkLines(
            label: l.hotelBookingsProposalTitle,
            lines: [
              for (final o in p.options)
                BkLine(
                  icon: GzIcons.calendarDots,
                  label: l.hotelBookingsProposalTitle,
                  facts: GzFactRow(
                    label: l.hotelBookingsFactsLabel,
                    children: [
                      if (o.hallId != ownHall) GzFactChip(icon: GzIcons.hall, small: true, label: l.hotelBookingsFactHall, value: hallName(o.hallId)),
                      if (o.delta.fils != 0)
                        Semantics(
                          label: l.hotelBookingsPriceChanged,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [GzIcon(GzIcons.coins, size: GzIconSize.xs, tone: GzIconTone.secondary), const SizedBox(width: GzSpace.s1), BkQuietMoney(fils: o.quotedTotal.fils)],
                          ),
                        ),
                    ],
                  ),
                  child: GzText(f.date(o.eventDate.toString(), DateStyle.short), role: GzTextRole.title, color: c.textStrong, figures: true),
                ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          GzFactRow(
            label: l.hotelBookingsAwaitingCouple,
            children: [GzFactChip(icon: GzIcons.hourglass, tone: GzFactTone.accent, label: l.hotelBookingsProposalWindow, value: stampLine(f, p.expiresAt))],
          ),
        ],
      ),
    );
  }
}
