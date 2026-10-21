import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../booking_glyphs.dart';
import 'booking_layout.dart';

/// A standard price struck through (exact figures when [exact]); one LTR island.
class BookingStruck extends ConsumerWidget {
  const BookingStruck({required this.fils, this.role = GzTextRole.figBodyS, this.exact = false, super.key});

  final int fils;
  final GzTextRole role;
  final bool exact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gz = context.gz;
    final parts = ref.watch(gzFormatProvider).moneyParts(fils, MoneyOptions(mode: exact ? MoneyMode.exact : MoneyMode.browse));
    final style = gz
        .text(role)
        .copyWith(
          color: gz.colors.textSecondary,
          decoration: TextDecoration.lineThrough,
          decorationColor: gz.colors.textSecondary,
          decorationThickness: 1,
        );
    Widget part(String v) => Text(v, style: style, softWrap: false); // gz-rules-ok: a struck price needs a decoration GzText does not carry
    return Semantics(
      label: context.gzL10n.commonStandardPrice,
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          // English draws the currency before the figure, Arabic after it (the web `Money inline` in an LTR island)
          children: [
            if (!gz.isAr) ...[part(parts.currency), part('\u2005')],
            part('${parts.integer}${parts.fraction}'),
            if (gz.isAr) ...[part('\u2005'), part(parts.currency)],
          ],
        ),
      ),
    );
  }
}

/// The saving after the voucher fee as a green chip with the trend-down glyph (web `.bk-pkg__save`).
class BookingSavePill extends ConsumerWidget {
  const BookingSavePill({required this.fils, required this.semantic, this.exact = false, super.key});

  final int fils;
  final String semantic;
  final bool exact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.pillMin),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.statusSuccessText, mirror: false),
                const SizedBox(width: GzSpace.s1),
                GzMoney(
                  fils: fils,
                  mode: exact ? GzMoneyMode.exact : GzMoneyMode.browse,
                  inline: true,
                  amountRole: GzTextRole.figLabel,
                  amountColor: c.statusSuccessText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _lineGlyph(PriceLineKind k) => switch (k) {
  PriceLineKind.package => GzIcons.package,
  PriceLineKind.menu => GzIcons.buffet,
  PriceLineKind.extra => GzIcons.sparkle,
  PriceLineKind.venueDiscount => GzIcons.percent,
  _ => GzIcons.receipt,
};

/// The itemised price as ruled lines in the figures voice (exact three decimals, ADR 0010), in the two columns of ADR 0033 D4, spoken in
/// glyphs (ADR 0034): a line is a glyph, what it is made of (guests and the rate per guest as facts, or the name of an extra) and its
/// amount, with the standard amount quiet and struck through beneath it. The closing block is the same composition as a package card:
/// the voucher total as the number that matters, the standard total struck beside the saving after the fee; a quote the voucher would
/// not pay for shows one plain Total. No tax line, no deposit, no fee line that is not already a line.
class BookingQuoteLines extends ConsumerWidget {
  const BookingQuoteLines({required this.quote, this.noTotal = false, super.key});

  final Quote quote;
  final bool noTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    const exactOpt = MoneyOptions(mode: MoneyMode.exact);
    final totals = quote.totals;
    final has = quote.voucherOffered;
    final single = quote.lines.length == 1;
    final hairline = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderStrong, width: GzStroke.hair),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final line in quote.lines)
                () {
                  final credit = line.amount.fils < 0;
                  final named =
                      line.kind == PriceLineKind.extra ||
                      line.kind == PriceLineKind.venueDiscount ||
                      line.kind == PriceLineKind.serviceCharge ||
                      line.kind == PriceLineKind.adjustment;
                  final rated = line.unit != null && line.qty > 1;
                  final struck = has && !credit && line.standardAmount.fils != line.amount.fils;
                  final basisOnly = single && rated && !noTotal;
                  return Container(
                    decoration: BoxDecoration(border: Border(bottom: hairline)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: GzSpace.s3,
                                runSpacing: GzSpace.s1,
                                children: [
                                  GzIcon(_lineGlyph(line.kind), size: GzIconSize.sm, color: c.iconSecondary),
                                  if (named)
                                    GzText(context.bi(line.name), role: GzTextRole.bodyS, figures: true)
                                  else
                                    Semantics(label: context.bi(line.name), child: const SizedBox.shrink()),
                                  if (rated)
                                    GzFactRow(
                                      children: [
                                        GzFactChip(
                                          icon: GzIcons.usersThree,
                                          label: l10n.clientBookingGuestsLabel,
                                          value: f.integer(line.qty),
                                          small: true,
                                          tone: GzFactTone.muted,
                                        ),
                                        GzFactChip(
                                          icon: GzIcons.perGuest,
                                          label: l10n.commonUnitPerGuest,
                                          value: f.money(line.unit!.fils, exactOpt),
                                          small: true,
                                          tone: GzFactTone.muted,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (!basisOnly) ...[
                              const SizedBox(width: GzSpace.s4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  credit
                                      ? GzMoney(fils: line.amount.fils, mode: GzMoneyMode.exact, amountColor: c.textSuccess)
                                      : GzPrice(fils: line.amount.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
                                  if (has && !credit && !single && struck)
                                    BookingStruck(fils: line.standardAmount.fils, role: GzTextRole.figCaption, exact: true),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
        if (!noTotal)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
            child: has
                ? BookingGap(
                    gap: GzSpace.s2,
                    cross: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconSuccess, semanticLabel: l10n.clientBookingVoucherTotalLabel),
                          const SizedBox(width: GzSpace.s2),
                          GzPrice(fils: totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: GzSpace.s3,
                        runSpacing: GzSpace.s1,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: context.gzL10n.commonStandardPrice),
                                const SizedBox(width: GzSpace.s1),
                                BookingStruck(fils: totals.standardTotal.fils, exact: true),
                              ],
                            ),
                          ),
                          BookingSavePill(
                            fils: totals.netSavings,
                            exact: true,
                            semantic: l10n.clientBookingYouSaveNet(f.money(totals.netSavings, exactOpt)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GzText(l10n.commonMoneyTotal, role: GzTextRole.title, color: c.textStrong),
                      GzPrice(fils: totals.standardTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                    ],
                  ),
          ),
      ],
    );
  }
}
