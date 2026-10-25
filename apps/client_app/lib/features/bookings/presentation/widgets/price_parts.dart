import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'bk_common.dart';

/// Where the request is: only the venue cell changes (off-app, then settled).
enum PriceStage { pending, approved, confirmed, redeemed }

/// PriceBlock: the frozen quote of a request in glyphs and figures (ADR 0033 D4, ADR 0034). Who is paid what is the whole block, as two
/// cells: the KD 2 voucher to Ghazal (paid, once) and the voucher price to the venue directly (off-app), the larger cell. Under them the
/// deal is one quiet line of facts. Extra lines (add-ons) list only when there is more than one line.
class PriceBlock extends StatelessWidget {
  const PriceBlock({required this.booking, required this.stage, super.key});

  final Booking booking;
  final PriceStage stage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final b = booking;
    final totals = b.totals;
    final hasVoucher = totals.voucherTotal.fils < totals.standardTotal.fils;
    final first = b.lines.firstOrNull;
    final perGuest = first?.unit != null && first!.qty > 1 ? first.unit!.fils : null;
    final extra = b.lines.length > 1;
    final settled = stage == PriceStage.redeemed;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);

    Widget cell({required List<Widget> head, required Widget price, required String semantic}) => Expanded(
      flex: 2,
      child: Semantics(
        container: true,
        label: semantic,
        child: Container(
          padding: GzSpace.panel,
          decoration: BoxDecoration(
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.iconSm),
                child: Row(children: head),
              ),
              const SizedBox(height: GzSpace.s2),
              // Chrome and Flutter size the tabular figures a hair apart (about a pixel on a five-figure total): shrink only
              // when the total does not fit, never otherwise.
              SizedBox(width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: price)),
            ],
          ),
        ),
      ),
    );

    return BkGap(
      children: [
        if (extra)
          Container(
            decoration: BoxDecoration(border: Border(top: hair)),
            child: Column(
              children: [
                for (final line in b.lines)
                  Container(
                    constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                    decoration: BoxDecoration(border: Border(bottom: hair)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GzUserText(context.bi(line.name), role: GzTextRole.bodyS, color: c.textStrong),
                        ),
                        const SizedBox(width: GzSpace.s3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzPrice(fils: line.amount.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
                            if (hasVoucher && line.standardAmount.fils != line.amount.fils) ...[
                              const SizedBox(height: GzSpace.s1),
                              GzStruckMoney(fils: line.standardAmount.fils, mode: GzMoneyMode.exact),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
                semantic: '${l.clientBookingsPriceGhazal}, ${l.clientBookingsPricePaid}',
                head: [
                  GzIcon(GzIcons.ticket, size: GzIconSize.sm, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess),
                ],
                price: GzPrice(fils: totals.voucherFee.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
              ),
              const SizedBox(width: GzSpace.s3),
              cell(
                semantic: '${l.clientBookingsPriceVenue}, ${settled ? l.clientBookingsPriceSettled : l.clientBookingsPriceOffApp}',
                head: [
                  GzIcon(GzIcons.hall, size: GzIconSize.sm, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  if (settled)
                    GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess)
                  else ...[
                    GzIcon(GzIcons.receipt, size: GzIconSize.xs, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    Flexible(
                      child: GzText(l.clientBookingsPriceOffApp, role: GzTextRole.caption, color: c.textSecondary),
                    ),
                  ],
                ],
                price: GzPrice(fils: totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
              ),
            ],
          ),
        ),
        GzFactRow(
          label: l.clientBookingsPriceBasis,
          children: [
            if (hasVoucher)
              GzFactChip(
                icon: GzIcons.offer,
                label: l.clientBookingsPriceStandard,
                valueWidget: GzStruckMoney(fils: totals.standardTotal.fils, mode: GzMoneyMode.exact),
                small: true,
                tone: GzFactTone.muted,
              ),
            if (hasVoucher)
              GzFactChip(
                icon: GzIcons.trendDown,
                label: l.clientBookingsPriceSaving,
                valueWidget: GzPrice(fils: totals.savings.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
                small: true,
                tone: GzFactTone.accent,
              ),
            if (perGuest != null)
              GzFactChip(
                icon: GzIcons.perGuest,
                label: l.clientBookingsPricePerGuest,
                value: f.money(perGuest, const MoneyOptions(mode: MoneyMode.browse)),
                small: true,
                tone: GzFactTone.muted,
              ),
          ],
        ),
      ],
    );
  }
}

/// The price terms behind an info glyph: the one place the two sentences live. At the end of the Price section header.
class PriceInfo extends StatelessWidget {
  const PriceInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GzInfoButton(title: l.clientBookingsPriceInfoTitle, paragraphs: [l.clientBookingsPriceInfoInclusive, l.clientBookingsPriceInfoGhazal]);
  }
}

/// Alternatives: three halls free on the same date, as compact venue rows (Not accepted, Expired, venue cancellation).
class BkAlternatives extends StatelessWidget {
  const BkAlternatives({required this.items, required this.onOpen, super.key});

  final List<VenueResult> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return BkGap(
      children: [
        for (final r in items)
          GzPressable(
            onPressed: () => onOpen(r.venue.id),
            semanticLabel: context.bi(r.venue.name),
            builder: (context, st) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                children: [
                  Container(
                    width: GzSize.thumbLg,
                    height: GzSize.thumbLg,
                    decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.smAll),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: r.venue.cover != null
                        ? SizedBox.expand(child: GzPhoto(src: gzImageSrc(r.venue.cover!.file, r.venue.cover!.baseUrl)))
                        : const GzMonogram(size: GzMonogramSize.sm),
                  ),
                  const SizedBox(width: GzSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzText(context.bi(r.venue.name), role: GzTextRole.d1, color: c.textStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (r.price != null) ...[const SizedBox(height: GzSpace.s1), GzCardPriceLine(price: r.price!)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
