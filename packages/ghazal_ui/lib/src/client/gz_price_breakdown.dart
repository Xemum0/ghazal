import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show PriceLine, QuoteTotals;

import '../core/core.dart';
import '../foundation.dart';

/// Where the request is: only the settlement sentence changes (the web `stage`).
enum GzBreakdownStage { review, pending, approved, confirmed, redeemed }

const _exact = MoneyOptions(mode: MoneyMode.exact);

/// PriceBreakdown (request review, booking detail, voucher summary; ADR 0033 D4, voucher-model section 6): the frozen quote as a ruled
/// list in the figures voice. Every line carries the voucher amount with the standard amount struck through beneath it when the two
/// differ, then the totals (standard struck, voucher total as the headline, the saving), then WHO IS PAID WHAT: the KD 2 voucher to
/// Ghazal (paid, once) and the voucher total to the venue directly after the client confirms. There is no deposit, no balance, no
/// cancellation schedule and no fee that is not already a line.
///
/// Takes the two things a `Quote` and a `Booking` both carry: [lines] and [totals]. [venueName] is the venue or provider the client
/// settles with. [showLines] false = totals and settlement only (sheets).
class GzPriceBreakdown extends StatelessWidget {
  const GzPriceBreakdown({
    required this.lines,
    required this.totals,
    this.stage = GzBreakdownStage.review,
    this.venueName = '',
    this.showLines = true,
    this.showSettlement = true,
    this.loading = false,
    super.key,
  });

  final List<PriceLine> lines;
  final QuoteTotals totals;
  final GzBreakdownStage stage;
  final String venueName;
  final bool showLines;
  final bool showSettlement;
  final bool loading;

  /// A hairline under a row of [GzPriceBreakdown] lines.
  static BoxDecoration _rule(GzColors c) => BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)));

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;

    if (loading) {
      return Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: GzSpace.s4),
              Container(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                decoration: _rule(c),
                child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [GzSkeleton(inlineSize: 160, blockSize: 24), GzSkeleton(inlineSize: 72, blockSize: 24)]),
              ),
            ],
            const SizedBox(height: GzSpace.s4),
            const GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 52),
          ],
        ),
      );
    }

    final hasVoucher = totals.voucherTotal.fils < totals.standardTotal.fils;
    final venueNote = switch (stage) {
      GzBreakdownStage.redeemed => l.uiClientBreakdownVenueRedeemed,
      GzBreakdownStage.confirmed => l.uiClientBreakdownVenueConfirmed,
      _ => l.uiClientBreakdownVenueReview,
    };

    // The web strong price box measures 25 high in English and 28 in Arabic (currency label, figure and quiet fils share one baseline);
    // GzPrice measures 24 and 26.
    Widget strong(int fils) => ConstrainedBox(constraints: BoxConstraints(minHeight: gz.isAr ? 28 : 25), child: GzPrice(fils: fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong));

    Widget line(PriceLine line) {
      final differs = hasVoucher && line.standardAmount.fils != line.amount.fils;
      final unit = line.unit;
      final basis = unit != null && line.qty > 1 ? '${f.integer(line.qty)} × ${f.money(unit.fils, _exact)}' : null;
      return Container(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
        decoration: _rule(c),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(line.name.of(lang), role: GzTextRole.bodyS, figures: true),
                  if (basis != null) GzText(basis, role: GzTextRole.caption, color: c.textSecondary, figures: true),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                strong(line.amount.fils),
                if (differs)
                  ExcludeSemantics(
                    child: gzFigText(context, f.money(line.standardAmount.fils, _exact), role: GzTextRole.figCaption, color: c.textSecondary, decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget settleCell({required String label, required int fils, required String note, bool paid = false}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(label, role: GzTextRole.bodyS, color: c.textSecondary),
          const SizedBox(height: GzSpace.s1),
          strong(fils),
          const SizedBox(height: GzSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (paid) ...[GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess), const SizedBox(width: GzSpace.s1)],
              Expanded(child: GzText(note, role: GzTextRole.caption, color: paid ? c.textSuccess : c.textSecondary)),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: l.uiClientBreakdownLines,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLines) ...[Column(children: [for (final x in lines) line(x)]), const SizedBox(height: GzSpace.s4)],
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasVoucher) ...[
                Row(
                  children: [
                    Expanded(child: GzText(l.uiClientBreakdownStandardTotal, role: GzTextRole.bodyS, color: c.textSecondary)),
                    const SizedBox(width: GzSpace.s4),
                    ExcludeSemantics(
                      child: gzFigText(context, f.money(totals.standardTotal.fils, _exact), role: GzTextRole.figBodyS, color: c.textSecondary, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: GzSpace.s2),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: GzText(hasVoucher ? l.uiClientBreakdownVoucherTotal : l.commonMoneyTotal, role: GzTextRole.title)),
                  const SizedBox(width: GzSpace.s4),
                  GzPrice(fils: totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                ],
              ),
              if (hasVoucher) ...[
                const SizedBox(height: GzSpace.s2),
                Row(
                  children: [
                    GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.iconSuccess),
                    const SizedBox(width: GzSpace.s1),
                    Expanded(child: GzText(l.uiClientBreakdownSave, role: GzTextRole.bodyS, color: c.textSuccess)),
                    const SizedBox(width: GzSpace.s4),
                    strong(totals.savings.fils),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          GzText(l.uiClientBreakdownInclusive, role: GzTextRole.caption, color: c.textSecondary),
          if (showSettlement) ...[
            const SizedBox(height: GzSpace.s4),
            Container(
              padding: const EdgeInsets.only(top: GzSpace.s4),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(l.uiClientBreakdownWho, role: GzTextRole.label),
                  const SizedBox(height: GzSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      settleCell(label: l.uiClientBreakdownGhazal, fils: totals.voucherFee.fils, note: l.uiClientBreakdownGhazalPaid, paid: true),
                      const SizedBox(width: GzSpace.s4),
                      settleCell(
                        label: l.uiClientBreakdownVenue(venueName.isEmpty ? l.commonMoneyTotal : venueName),
                        fils: totals.voucherTotal.fils,
                        note: venueNote,
                        paid: stage == GzBreakdownStage.redeemed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (stage != GzBreakdownStage.redeemed) ...[
            const SizedBox(height: GzSpace.s4),
            Container(
              padding: const EdgeInsets.all(GzSpace.s4),
              decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzIcon(GzIcons.shieldCheck, size: GzIconSize.sm, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzText(l.uiClientBreakdownNoMore, role: GzTextRole.bodyS)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
