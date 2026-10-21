import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, BookingStatus, NamedRef, ProposalStatus, TargetSummary;

import '../brand/gz_monogram.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import '../voucher/gz_confirm_left.dart';
import '../voucher/gz_voucher_chip.dart';
import 'gz_booking_thread.dart';

enum GzBookingCardVariant { card, row }

/// The status pill of a request status (ADR 0033 D3).
GzStatus gzBookingStatus(BookingStatus s) => switch (s) {
  BookingStatus.pending => GzStatus.pending,
  BookingStatus.approved => GzStatus.approved,
  BookingStatus.declined => GzStatus.declined,
  BookingStatus.expired => GzStatus.expired,
  BookingStatus.confirmed => GzStatus.confirmed,
  BookingStatus.redeemed => GzStatus.redeemed,
  BookingStatus.completed => GzStatus.completed,
  BookingStatus.cancelled => GzStatus.cancelled,
  BookingStatus.unknown => GzStatus.pending,
};

/// Mock photographs are bundled flat (`images/<id>_480.jpg`): the folder and extension of the contract's `file` are dropped; with a
/// real `baseUrl` the photograph comes from it.
String _photoSrc(String file, String? baseUrl) {
  if (baseUrl != null && baseUrl.isNotEmpty) return baseUrl;
  final name = file.split('/').last.replaceFirst(RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false), '');
  return 'asset://ghazal_mock_api/images/$name';
}

/// BookingCard (CL-BKNG list, My Wedding, Home "Your booking"): one request as a panel (ADR 0033). Venue or provider thumbnail and
/// serif name, the hall line, the status pill beside the voucher chip, three key facts (date, guests, voucher price), the compact
/// Booking Thread with its current label, and the reference as an LTR isolate. An approved request carries one calm line with the
/// time left to confirm (hours and minutes, never seconds). The whole card is one target; nothing on it is gold except what the
/// thread itself says.
///
/// Takes the pieces of a `BookingRow` (the list item the API returns): the [booking], its [target] (name, cover) and [halls], plus the
/// bound voucher's [voucherCode] (the chip). The widget never fetches.
/// - `card`: the full panel with facts and the compact thread. `row`: thumbnail, name, date and status only (dense lists, Past).
class GzBookingCard extends StatelessWidget {
  const GzBookingCard({
    required this.booking,
    required this.target,
    this.halls = const [],
    this.voucherCode,
    this.variant = GzBookingCardVariant.card,
    this.onOpen,
    this.loading = false,
    this.previewState,
    super.key,
  });

  final Booking booking;
  final TargetSummary target;
  final List<NamedRef> halls;
  final String? voucherCode;
  final GzBookingCardVariant variant;
  final VoidCallback? onOpen;
  final bool loading;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final card = variant == GzBookingCardVariant.card;

    Widget panel(Widget child, {bool pressed = false}) => Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(
        color: pressed ? c.surfaceQuiet : c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: child,
    );

    if (loading) {
      return panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 56, blockSize: 56),
                SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [GzSkeleton(inlineSize: 180, blockSize: 28), SizedBox(height: GzSpace.s1), GzSkeleton(inlineSize: 120, blockSize: 20)],
                  ),
                ),
              ],
            ),
            if (card) ...[
              const SizedBox(height: GzSpace.s4),
              const GzSkeleton(inlineSize: 96, blockSize: 24),
              const SizedBox(height: GzSpace.s4),
              const SizedBox(width: double.infinity, child: GzSkeleton(blockSize: 52)),
              const SizedBox(height: GzSpace.s4),
              const SizedBox(width: double.infinity, child: GzSkeleton(blockSize: 20)),
            ],
          ],
        ),
      );
    }

    final b = booking;
    final name = target.name.of(lang);
    final hallLine = halls.isEmpty ? null : halls.first.name.of(lang);
    final cover = target.cover;
    final guests = b.service != null ? b.service!.quantity : b.sections.fold<int>(0, (n, s) => n + s.guests);
    final date = f.date(b.eventDate.toString(), card ? DateStyle.compact : DateStyle.full);

    final thumb = Container(
      width: GzSize.thumbMd,
      height: GzSize.thumbMd,
      decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.smAll),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: cover != null
          ? SizedBox.expand(child: GzPhoto(src: _photoSrc(cover.file, cover.baseUrl)))
          : const GzMonogram(size: GzMonogramSize.sm),
    );

    Widget fact(String label, Widget value, {int flex = 1}) => Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(label, role: GzTextRole.caption),
          const SizedBox(height: GzSpace.s1),
          DefaultTextStyle.merge(style: TextStyle(color: c.textStrong), child: value),
        ],
      ),
    );

    final voucherTone = b.status == BookingStatus.redeemed || b.status == BookingStatus.completed ? GzVoucherChipTone.quiet : GzVoucherChipTone.bound;
    final statusRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GzStatusPill(status: gzBookingStatus(b.status)),
              if (b.proposal?.status == ProposalStatus.proposed) const GzStatusPill(status: GzStatus.dateProposed),
              if (voucherCode != null) GzVoucherChip(code: voucherCode!, tone: voucherTone),
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        gzFigText(context, b.ref, role: GzTextRole.figCaption, color: c.textSecondary),
      ],
    );

    Widget body(bool pressed) => panel(
      pressed: pressed,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              thumb,
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzText(name, role: GzTextRole.d1, maxLines: 2),
                    if (hallLine != null) ...[const SizedBox(height: GzSpace.s1), GzText(hallLine, role: GzTextRole.bodyS, color: c.textSecondary)],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: card ? GzSpace.s4 : GzSpace.s3),
          statusRow,
          SizedBox(height: card ? GzSpace.s4 : GzSpace.s3),
          if (card) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fact(l.uiClientBookingCardDate, GzText(date, role: GzTextRole.bodyS, color: c.textStrong, figures: true), flex: 2),
                  const SizedBox(width: GzSpace.s3),
                  const GzDivider(vertical: true),
                  const SizedBox(width: GzSpace.s3),
                  fact(
                    b.service != null ? l.uiClientBookingCardQuantity : l.uiSharedGuests,
                    GzNum(f.integer(guests), role: GzTextRole.bodyS, color: c.textStrong),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  const GzDivider(vertical: true),
                  const SizedBox(width: GzSpace.s3),
                  fact(
                    l.uiClientBookingCardVoucherPrice,
                    // the web price is a flex item with min-width 0 and does not clip: a long amount overflows its column
                    OverflowBox(fit: OverflowBoxFit.deferToChild, alignment: AlignmentDirectional.centerStart, minWidth: 0, maxWidth: double.infinity, child: GzPrice(fils: b.totals.voucherTotal.fils, size: GzPriceSize.card)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s4),
            GzBookingThread(booking: b, variant: GzBookingThreadVariant.compact),
            if (b.status == BookingStatus.approved && b.confirmBy != null) ...[const SizedBox(height: GzSpace.s4), _ConfirmLine(deadline: b.confirmBy!)],
          ] else
            Row(
              children: [
                GzIcon(GzIcons.calendar, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                Flexible(child: GzText(date, role: GzTextRole.caption, figures: true)),
              ],
            ),
        ],
      ),
    );

    return RepaintBoundary(
      child: GzPressable(
        onPressed: onOpen,
        semanticLabel: '$name, ${l.uiClientBookingCardOpen(b.ref)}',
        borderRadius: GzRadius.mdAll,
        minHeight: 0,
        builder: (context, st) => gzPreview(previewState, body(st.pressed || previewState == GzPreviewState.pressed), radius: GzRadius.md),
      ),
    );
  }
}

/// The one calm line under an approved request: when to confirm by and how long is left.
class _ConfirmLine extends StatelessWidget {
  const _ConfirmLine({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final left = gzConfirmLeft(f, l, deadline: deadline, now: f.now());
    final text = l.uiClientBookingCardConfirmBy(f.dateTime(deadline, DateStyle.short), left.text);
    return Row(
      children: [
        GzIcon(GzIcons.hourglass, size: GzIconSize.xs, color: c.iconAccent),
        const SizedBox(width: GzSpace.s2),
        Flexible(child: GzText(text, role: GzTextRole.caption, color: c.textGoldInk, figures: true)),
      ],
    );
  }
}
