// The live previews of the window editor (web `PreviewStrip.tsx`, `PriceLines.tsx`): the client venue card in miniature, the way a couple sees the
// voucher price, and the request price lines for the example booking. Only the real standard price is ever struck through (ADR 0018 D4); a changed
// total swaps instantly, it never counts up (ADR 0017 D7). The KD 2 voucher fee is Ghazal's, never the venue's income: it lives behind the (i).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/grow_data.dart';
import '../../application/grow_model.dart';
import 'grow_bits.dart';

typedef Example = ({int standard, int voucher, int standing, int saving, bool flat, LocalDate date, int guests, String packageId});

/// The example quote of the current draft or window, from the catalog and the platform configuration; null while they load.
Example? exampleOf(WidgetRef ref, int rate, List<String> packageIds, List<String> dates) {
  final cat = ref.watch(growCatalogProvider).value;
  if (cat == null) return null;
  final soft = ref.watch(growSoftDatesProvider).value ?? const <String>[];
  final today = ref.watch(growTodayProvider);
  final weekend = ref.watch(growConfigProvider).value?.weekendTierDays ?? const [4, 5, 6];
  final fallback = soft.isNotEmpty ? LocalDate.parse(soft.first) : today.addDays(14);
  return exampleQuote(cat, packageIds, dates, rate, fallback, weekend);
}

class PreviewStrip extends ConsumerWidget {
  const PreviewStrip({
    required this.rate,
    required this.packageIds,
    required this.dates,
    this.flat = false,
    this.compact = false,
    this.card = false,
    super.key,
  });

  final int rate;
  final List<String> packageIds;
  final List<String> dates;

  /// Quiet variant for the sheet: no panel border.
  final bool flat;

  /// Pinned under the step thread: a 56 square photograph, the name and the price line only.
  final bool compact;

  /// The full card of the editor: a wide photograph with the voucher badge over it, then name, price and facts.
  final bool card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final venue = ref.watch(growVenueProvider).value?.venue;
    final ex = exampleOf(ref, rate, packageIds, dates);
    if (venue == null || ex == null) return const SizedBox.shrink();
    final iso = ex.date.toString();
    final busy = ref.watch(growBusyProvider(iso.substring(0, 7))).value ?? const <String>{};
    final free = !busy.contains(iso);
    final cover = venue.cover;
    final thumb = cover == null ? null : GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl), alt: cover.alt.of(lang));
    final badge = GzBadge(label: l.commonVoucher, variant: card ? GzBadgeVariant.photo : GzBadgeVariant.outline, bead: false, icon: GzIcons.ticket);
    final price = GzPrice(fils: ex.voucher, size: GzPriceSize.card, was: ex.saving > 0 ? ex.standard : null);
    final facts = GzFactRow(
      label: l.hotelGrowPreviewLabel,
      children: [
        if (ex.flat)
          GzFactChip(icon: GzIcons.package, label: l.hotelGrowUnitPackage, small: true, tone: GzFactTone.muted)
        else
          GzFactChip(icon: GzIcons.guests, value: f.integer(ex.guests), label: l.hotelGrowFactGuests, small: true, tone: GzFactTone.muted),
        if (!compact) ...[
          GzFactChip(
            icon: free ? GzIcons.calendarCheck : GzIcons.calendarX,
            valueWidget: GzText(dm(f, iso), role: GzTextRole.figCaption, color: c.textSecondary, figures: true),
            label: free ? l.commonAvailabilityFree : l.commonAvailabilityBooked,
            small: true,
            tone: GzFactTone.muted,
          ),
          if (ex.saving > 0) GrowSaving(fils: ex.saving, label: l.hotelGrowYouSave),
        ],
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!card && !compact) ...[badge, const SizedBox(height: GzSpace.s1)],
        GzText(venue.name.of(lang), role: GzTextRole.d1, color: c.textStrong),
        const SizedBox(height: GzSpace.s1),
        price,
        const SizedBox(height: GzSpace.s1),
        facts,
      ],
    );
    if (card) {
      return Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: GzLayout.aspect16x10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: c.surfacePlaceholder, child: thumb),
                  PositionedDirectional(bottom: GzSpace.s3, start: GzSpace.s3, child: badge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s4, top: GzSpace.s3, bottom: GzSpace.s4),
              child: body,
            ),
          ],
        ),
      );
    }
    final size = compact ? GzSize.thumbMd : GzSize.thumbCompactWidth;
    return Container(
      padding: flat ? null : EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: compact ? GzSpace.s2 : GzSpace.s3),
      decoration: flat
          ? null
          : BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: compact ? GzRadius.smAll : GzRadius.mdAll,
              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
            ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: GzRadius.smAll,
            child: SizedBox(
              width: size,
              height: size,
              child: ColoredBox(color: c.surfacePlaceholder, child: thumb),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The request price a couple sees for the example booking: the standard total, the saving and what couples pay, in exact money.
class PriceLines extends ConsumerWidget {
  const PriceLines({required this.rate, required this.packageIds, required this.dates, super.key});

  final int rate;
  final List<String> packageIds;
  final List<String> dates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final ex = exampleOf(ref, rate, packageIds, dates);
    if (ex == null) return const SizedBox.shrink();
    final fee = ref.watch(growConfigProvider).value?.voucherFeeFils ?? kFallbackFee;
    Widget row(IconData icon, String name, Widget value, {bool total = false}) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
      child: Row(
        children: [
          GzIcon(icon, size: GzIconSize.sm, color: total ? c.iconAccent : c.iconSecondary),
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: GzText(name, role: total ? GzTextRole.body : GzTextRole.bodyS, color: c.textStrong),
          ),
          value,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GrowHead(
          icon: GzIcons.receipt,
          title: l.hotelGrowRequestPrice,
          trailing: GzInfoButton(title: l.hotelGrowFeeTitle, paragraphs: [l.hotelGrowFeeNote(f.money(fee))]),
        ),
        const SizedBox(height: GzSpace.s3),
        GzFactRow(
          label: l.hotelGrowExampleLabel,
          children: [
            if (ex.flat)
              GzFactChip(icon: GzIcons.package, label: l.hotelGrowUnitPackage, small: true, tone: GzFactTone.muted)
            else
              GzFactChip(icon: GzIcons.guests, value: f.integer(ex.guests), label: l.hotelGrowFactGuests, small: true, tone: GzFactTone.muted),
            GzFactChip(
              icon: GzIcons.calendar,
              valueWidget: GzText(dm(f, ex.date.toString()), role: GzTextRole.figCaption, color: c.textSecondary, figures: true),
              label: l.hotelGrowFactDate,
              small: true,
              tone: GzFactTone.muted,
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        row(GzIcons.coins, l.hotelGrowStandardPrice, GzPrice(fils: ex.standard, mode: GzMoneyMode.exact, size: GzPriceSize.strong)),
        row(GzIcons.offer, l.hotelGrowSaving, GrowSaving(fils: ex.saving, label: l.hotelGrowYouSave, exact: true)),
        row(GzIcons.ticket, l.hotelGrowCouplesPay, GzPrice(fils: ex.voucher, mode: GzMoneyMode.exact, size: GzPriceSize.total), total: true),
      ],
    );
  }
}
