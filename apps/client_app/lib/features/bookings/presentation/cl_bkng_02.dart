import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/bookings_data.dart';
import '../application/bookings_model.dart';
import 'widgets/bk_common.dart';
import 'widgets/detail_block.dart';
import 'widgets/price_parts.dart';
import 'widgets/report_issue_sheet.dart';
import 'widgets/voucher_parts.dart';

/// CL-BKNG-02 Booking detail. Covers CA-STAT-02 to 07, CA-STAT-09 to 14, CA-BOOK-12, CA-CHAT-02, CA-VCH-07, CA-VCH-11.
///
/// One layout, many states (ADR 0003, ADR 0033): the venue, the date and the facts as glyphs and figures; the Booking Thread; the state of
/// the request (glyph or drawing, at most three words, facts); the voucher (code and QR once confirmed); the event; the price; the
/// shortcuts. The primary action follows the status: Confirm booking (approved), Show voucher (confirmed). No payment, balance, refund
/// or invoice section: the event is paid to the venue directly, and the voucher is the only Ghazal money (KD 2).
/// params: bookingId (else the hero request).
class ClBkng02Screen extends ConsumerWidget {
  const ClBkng02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final async = ref.watch(bookingFactsProvider(id));
    final now = ref.watch(clockProvider)();
    final facts = keepStale(async).value;
    final offline = async.hasError && facts != null;
    final variant = facts == null ? null : bookingVariantOf(facts.booking, now);

    DetailActions? go;
    if (facts != null && variant != null) go = _actions(context, facts, variant);
    return GzScreen(
      top: GzTopBar(title: l.clientBookingsDetailTitle, subtitle: facts?.booking.ref),
      bottom: facts == null || variant == null ? null : detailBar(context, facts.booking, variant, go!, offline: offline),
      child: BkAsync<BookingFacts>(
        value: async,
        onRetry: () => ref.invalidate(bookingFactsProvider),
        loading: const _DetailSkeleton(),
        data: (f) =>
            _Detail(facts: f, variant: bookingVariantOf(f.booking, now), now: now, go: _actions(context, f, bookingVariantOf(f.booking, now))),
      ),
    );
  }

  DetailActions _actions(BuildContext context, BookingFacts facts, BookingVariant v) {
    final nav = context.gzNav;
    final l = context.l10n;
    final b = facts.booking;
    final f = context.gzFormat;
    final voucherId = facts.voucher?.id ?? b.voucherId;
    return DetailActions(
      edit: () => nav.push(
        'CL-BOOK-01',
        params: <String, Object?>{
          'editBookingId': b.id,
          'draftId': b.id,
          'venueId': b.venueId,
          'voucherId': voucherId,
          'date': b.eventDate.toString(),
          'edit': true,
          'replyBy': b.respondBy?.toIso8601String(),
        },
      ),
      cancel: () =>
          nav.openSheet('CL-BKNG-03', options: GzSheetOptions(params: <String, Object?>{'bookingId': b.id, 'variant': cancelKindOf(v).name})),
      confirm: () => nav.push('CL-BOOK-08', params: <String, Object?>{'bookingId': b.id}),
      proposal: () => nav.openSheet('CL-BKNG-04', options: GzSheetOptions(params: <String, Object?>{'bookingId': b.id})),
      voucher: () => nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': voucherId, 'bookingId': b.id}),
      visit: () => nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{'venueId': b.venueId})),
      calendar: () => nav.toast(GzToastSpec(message: l.clientBookingsCalendarAdded, tone: GzToastTone.success)),
      issue: () {
        final name = context.bi(facts.target.name);
        final until = bkDayMon(f, issueUntilOf(b, 72));
        nav.openSheetBuilder((_) => ReportIssueSheet(bookingId: b.id, venue: name, until: until));
      },
      similar: () => nav.push('CL-DISC-03'),
      again: () => nav.push('CL-BOOK-01', params: <String, Object?>{'voucherId': voucherId, 'venueId': b.venueId}),
      review: () => nav.push('CL-RVRW-02', params: <String, Object?>{'bookingId': b.id}),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.facts, required this.variant, required this.now, required this.go});

  final BookingFacts facts;
  final BookingVariant variant;
  final DateTime now;
  final DetailActions go;

  PriceStage get _stage => switch (variant) {
    BookingVariant.pending || BookingVariant.pendingDateHeld || BookingVariant.venueProposedDate => PriceStage.pending,
    BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour => PriceStage.approved,
    BookingVariant.confirmed => PriceStage.confirmed,
    BookingVariant.voucherRedeemed || BookingVariant.completed || BookingVariant.issueReported => PriceStage.redeemed,
    _ => PriceStage.pending,
  };

  bool get _ended => const {
    BookingVariant.declined,
    BookingVariant.expiredVenueNoReply,
    BookingVariant.expiredNotConfirmed,
    BookingVariant.cancelledByMe,
    BookingVariant.cancelledByVenue,
  }.contains(variant);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final b = facts.booking;
    final venue = facts.venue;
    final voucher = facts.voucher;
    final name = context.bi(facts.target.name);
    final cover = facts.target.cover;
    final section = b.sections.firstOrNull;
    final session = section == null ? null : bkSession(l, section.start);
    final block = detailStateBlock(context, facts, variant, now, go);
    final showAlt =
        venue != null && const {BookingVariant.declined, BookingVariant.expiredVenueNoReply, BookingVariant.cancelledByVenue}.contains(variant);
    final cancellable = const {BookingVariant.confirmed, BookingVariant.approvedConfirmWindow, BookingVariant.approvedLastHour}.contains(variant);
    final callable =
        venue != null && venue.phone.isNotEmpty && !const {BookingVariant.declined, BookingVariant.expiredVenueNoReply}.contains(variant);
    final visitable = bookingVisitable(facts, variant);
    final hours = venue?.response?.usuallyRepliesHours;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);

    final lines = <BkFactLine>[
      if (facts.hall != null) BkFactLine(icon: GzIcons.hall, label: l.clientBookingsFactHall, value: context.bi(facts.hall!.name), autoDir: true),
      if (facts.packageName != null)
        BkFactLine(icon: GzIcons.package, label: l.clientBookingsFactPackage, value: context.bi(facts.packageName!), autoDir: true),
      if (b.specialRequests != null && b.specialRequests!.isNotEmpty)
        BkFactLine(
          icon: GzIcons.notes,
          label: l.clientBookingsFactNotes,
          value: l.clientBookingsFactNotes,
          onPressed: () => nav.openSheetBuilder(
            (_) => GzUserText(b.specialRequests!, role: GzTextRole.body),
            options: GzSheetOptions(title: l.clientBookingsFactNotes),
          ),
        ),
    ];

    Widget sectionOf(String label, List<Widget> children) => Semantics(
      container: true,
      label: label,
      child: BkPad(child: BkGap(children: children)),
    );

    final sections = <Widget>[
      // header: the venue picture, the serif name, the facts as glyphs and figures
      BkPad(
        child: BkGap(
          children: [
            Row(
              children: [
                Container(
                  width: GzSize.thumbLg,
                  height: GzSize.thumbLg,
                  decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: cover != null
                      ? SizedBox.expand(child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl)))
                      : const GzMonogram(size: GzMonogramSize.sm),
                ),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: GzText(name, role: GzTextRole.d2, color: c.textStrong, header: true),
                ),
              ],
            ),
            Wrap(
              spacing: GzSpace.s5,
              runSpacing: GzSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsFactDate, value: bkDayYear(f, b.eventDate)),
                GzFactChip(
                  icon: GzIcons.usersThree,
                  label: b.service != null ? l.clientBookingsFactQuantity : l.clientBookingsFactGuests,
                  value: f.integer(bookingGuests(b)),
                ),
                if (section != null) GzFactChip(icon: bkAudienceGlyph(section.audience), label: bkAudienceLabel(l, section.audience)),
                if (session != null) GzFactChip(icon: session.icon, label: session.label),
              ],
            ),
          ],
        ),
      ),
      // the Booking Thread: the hero, on paper with a hairline; the status chip at its start
      Semantics(
        container: true,
        label: l.clientBookingsThreadLabel,
        child: Container(
          margin: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.panelPad, GzSpace.panelPad, GzSpace.panelPad, GzSpace.s5),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_ended) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzStatusPill(status: bookingPillOf(variant)),
                ),
                const SizedBox(height: GzSpace.s4),
              ],
              GzBookingThread(booking: b, voucherAt: voucher?.purchasedAt, variant: GzBookingThreadVariant.full, draw: GzDraw.mount),
            ],
          ),
        ),
      ),
      if (block != null) BkPad(child: block),
      if (_ended)
        BkPad(
          child: VoucherOutcome(
            voucher: voucher,
            targetName: name,
            primary: variant == BookingVariant.declined || variant == BookingVariant.cancelledByVenue,
          ),
        )
      else if (voucher != null)
        sectionOf(context.gzL10n.commonVoucher, [
          variant == BookingVariant.confirmed
              ? VoucherTicket(voucher: voucher, targetName: name, onShowFull: go.voucher)
              : VoucherLine(voucher: voucher, onOpen: go.voucher),
        ]),
      if (showAlt) _AltSection(booking: b),
      if (lines.isNotEmpty)
        sectionOf(l.clientBookingsSectionEvent, [GzSectionHeader(title: l.clientBookingsSectionEvent), BkFactLines(lines: lines)]),
      sectionOf(l.clientBookingsSectionPrice, [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: GzSectionHeader(title: l.clientBookingsSectionPrice)),
            const SizedBox(width: GzSpace.s2),
            const PriceInfo(),
          ],
        ),
        PriceBlock(booking: b, stage: _stage),
        Container(
          decoration: BoxDecoration(border: Border(top: hair)),
          child: GzIconListRow(
            flush: true,
            chevron: true,
            last: true,
            icon: GzIcons.receipt,
            title: l.clientBookingsReceipts,
            onPressed: () => nav.push('CL-BKNG-05'),
          ),
        ),
      ]),
      sectionOf(l.clientBookingsSectionContact, [
        Container(
          decoration: BoxDecoration(border: Border(top: hair)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (venue != null)
                GzIconListRow(
                  flush: true,
                  chevron: true,
                  icon: GzIcons.shieldCheck,
                  title: l.clientBookingsTerms,
                  onPressed: () => nav.openSheet('CL-VENU-05', options: GzSheetOptions(params: <String, Object?>{'venueId': b.venueId})),
                ),
              GzIconListRow(
                flush: true,
                chevron: true,
                icon: GzIcons.chat,
                title: l.clientBookingsMessage,
                trailing: hours == null
                    ? null
                    : GzFactChip(
                        icon: GzIcons.timer,
                        label: l.clientBookingsUsuallyReplies,
                        value: f.duration(hours * 3600000),
                        small: true,
                        tone: GzFactTone.muted,
                      ),
                onPressed: () => nav.push('CL-MSGS-02', params: <String, Object?>{'bookingId': b.id, 'venueId': b.venueId}),
              ),
              if (callable)
                GzIconListRow(
                  flush: true,
                  chevron: true,
                  icon: GzIcons.phone,
                  title: f.phone(venue.phone),
                  onPressed: () => nav.toast(GzToastSpec(message: l.clientBookingsCallDisplayOnly)),
                ),
              if (visitable && variant != BookingVariant.confirmed)
                GzIconListRow(
                  flush: true,
                  chevron: true,
                  last: !cancellable,
                  icon: GzIcons.calendarCheck,
                  title: l.clientBookingsBookVisit,
                  onPressed: go.visit,
                ),
              if (cancellable)
                GzIconListRow(
                  flush: true,
                  chevron: true,
                  last: true,
                  tone: GzListRowTone.danger,
                  icon: GzIcons.close,
                  title: variant == BookingVariant.confirmed ? l.clientBookingsCancelBooking : l.clientBookingsApprovedCancel,
                  onPressed: go.cancel,
                ),
            ],
          ),
        ),
      ]),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.section), sections[i]],
        ],
      ),
    );
  }
}

class _AltSection extends ConsumerWidget {
  const _AltSection({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(bookingAlternativesProvider(booking)).value ?? const <VenueResult>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return BkPad(
      child: BkGap(
        children: [
          GzSectionHeader(title: l.clientBookingsSectionAlternatives),
          BkAlternatives(
            items: items,
            onOpen: (id) => context.gzNav.push('CL-VENU-01', params: <String, Object?>{'venueId': id}),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.fromSTEB(GzSpace.gutter, GzSpace.s4, GzSpace.gutter, GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 64, blockSize: 64),
              SizedBox(width: GzSpace.s4),
              GzSkeleton(inlineSize: 200, blockSize: 32),
            ],
          ),
          SizedBox(height: GzSpace.s4),
          Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 240, blockSize: 20)),
          SizedBox(height: GzSpace.section),
          GzSkeleton(blockSize: 20),
          SizedBox(height: GzSpace.s4),
          GzSkeleton(blockSize: 20),
          SizedBox(height: GzSpace.s4),
          GzSkeleton(blockSize: 20),
          SizedBox(height: GzSpace.section),
          GzSkeleton(blockSize: 128),
          SizedBox(height: GzSpace.section),
          GzSkeleton(blockSize: 180),
        ],
      ),
    );
  }
}
