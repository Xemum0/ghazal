import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PriceStructure;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/voucher_quote.dart';
import '../voucher_fmt.dart';
import 'voucher_parts.dart';

/// The choice a voucher is bound to, as one plate (web `QuotePlate`, CA-VCH-03): the venue or provider (photograph or monogram, name),
/// the hall and the package as facts, the date, then the two prices and the saving through `GzPriceCompare`. No caption: the plate IS
/// the binding. [noPrices] (the saving does not beat the voucher price) shows the choice without prices.
class QuotePlate extends StatelessWidget {
  const QuotePlate({required this.quote, this.noPrices = false, super.key});

  final VoucherQuote quote;
  final bool noPrices;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final name = voucherText(context, quote.name);
    final hall = quote.hallName == null ? null : voucherText(context, quote.hallName);
    final pkg = quote.packageName == null ? null : voucherText(context, quote.packageName);
    return Semantics(
      container: true,
      label: l.clientVouchersQuoteLabel,
      child: Container(
        key: const ValueKey<String>('voucher.quote'),
        padding: GzSpace.panel,
        decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                VoucherThumb(name: name, cover: quote.cover, monogram: quote.monogram),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzText(name, role: GzTextRole.d1, color: c.textStrong),
                      if (hall != null) ...[
                        const SizedBox(height: GzSpace.s1),
                        GzFactRow(children: [GzFactChip(icon: GzIcons.hall, label: l.clientVouchersLabelHall, value: hall, tone: GzFactTone.muted)]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            GzFactRow(
              children: [
                GzFactChip(icon: GzIcons.calendar, label: l.clientVouchersLabelEvent, value: f.dayLong(quote.eventDate.toString())),
                if (pkg != null) GzFactChip(icon: GzIcons.package, label: l.clientVouchersLabelPackage, value: pkg, tone: GzFactTone.muted),
              ],
            ),
            if (!noPrices) ...[
              const SizedBox(height: GzSpace.s3),
              Container(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                child: GzPriceCompare(
                  standard: quote.standardFils,
                  voucher: quote.voucherFils,
                  structure: PriceStructure.package,
                  guests: quote.isProvider ? null : quote.guests,
                  fee: quote.feeFils,
                  variant: GzPriceCompareVariant.inline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The plate while the quote loads (web `quote.loading`).
class QuotePlateSkeleton extends StatelessWidget {
  const QuotePlateSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Container(
          padding: GzSpace.panel,
          decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 56, blockSize: 56),
                  SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [GzSkeleton(blockSize: 28), SizedBox(height: GzSpace.s1), GzSkeleton(inlineSize: 120, blockSize: 20)]),
                  ),
                ],
              ),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(inlineSize: 200, blockSize: 20),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
            ],
          ),
        ),
      ),
    );
  }
}

/// How the voucher works as three knots on the thread (web `Steps`, ADR 0034): pay the fee now (the knot about to be tied), send the
/// request at the voucher price, pay the venue directly (off-app). Nothing is recorded yet, so only the first knot is "now".
class VoucherSteps extends StatelessWidget {
  const VoucherSteps({required this.feeText, this.provider = false, super.key});

  final String feeText;
  final bool provider;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    return GzIconProgress(
      label: l.clientVouchersStepsLabel,
      describe: f.list([l.clientVouchersPayFee(feeText), l.clientVouchersStepRequest, l.clientVouchersStepDirect]),
      labels: GzProgressLabels.all,
      draw: GzDraw.off,
      steps: [
        GzIconProgressStep(id: 'pay', icon: GzIcons.card, label: feeText, state: GzKnotState.now),
        GzIconProgressStep(id: 'request', icon: GzIcons.send, label: l.clientVouchersStepRequest, state: GzKnotState.open),
        GzIconProgressStep(id: 'direct', icon: provider ? GzIcons.receipt : GzIcons.hall, label: l.clientVouchersStepDirect, state: GzKnotState.open),
      ],
    );
  }
}
