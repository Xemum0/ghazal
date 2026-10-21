import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions, kMinus;
import 'package:ghazal_domain/ghazal_domain.dart' show GatewayMethod, Voucher;

import '../core/core.dart';
import '../foundation.dart';

/// A legal money label (`KWD 2.000`, Western digits, three decimals): documents say KWD, never KD (ADR 0010 D7).
class _Legal extends StatelessWidget {
  const _Legal({required this.fils, this.strong = false});

  final int fils;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final m = context.gzFormat.moneyParts(fils, const MoneyOptions(mode: MoneyMode.exact, legal: true));
    final amount = gz.text(strong ? GzTextRole.priceTotal : GzTextRole.priceStrong).copyWith(color: c.textStrong, decoration: TextDecoration.none);
    final figure = '${m.negative ? kMinus : ''}${m.integer}${m.fraction}';
    return Semantics(
      label: GzBidi.strip(m.text),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            Text(m.currency, style: gz.text(GzTextRole.label).copyWith(color: c.textSecondary, decoration: TextDecoration.none), softWrap: false),
            const SizedBox(width: GzSpace.s1),
            Text(figure, style: amount, softWrap: false),
          ],
        ),
      ),
    );
  }
}

/// ReceiptSheet (CA-PAY, ADR 0035): the layout of the voucher receipt. No VAT line, no credit note. Issuer, receipt number and voucher
/// code are LTR isolates; the line carries quantity and unit; then the total and how it was paid. Documents say KWD (the legal label),
/// Western digits, three decimals. [targetName] is the venue or provider the voucher is tied to (the caller resolves it).
class GzReceiptSheet extends StatelessWidget {
  const GzReceiptSheet({required this.voucher, this.targetName = '', super.key});

  final Voucher voucher;
  final String targetName;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final v = voucher;
    final pay = v.payment;
    final method = switch (pay?.method) {
      GatewayMethod.knet => l.uiClientPaymentKnet,
      GatewayMethod.applePay => l.uiClientPaymentApplePay,
      GatewayMethod.googlePay => l.uiClientPaymentGooglePay,
      GatewayMethod.card => l.uiClientPaymentCardNote,
      _ => '',
    };

    Widget metaRow(String label, Widget value) => Container(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          GzText(label, role: GzTextRole.caption, color: c.textSecondary),
          const SizedBox(width: GzSpace.s3),
          Flexible(child: value),
        ],
      ),
    );
    Widget figure(String text) => gzFigText(context, text, role: GzTextRole.figBodyS, color: c.textStrong);

    final footer = Container(
      padding: const EdgeInsets.only(top: GzSpace.s3),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: GzText(l.uiClientReceiptFooter, role: GzTextRole.caption, color: c.textSecondary),
    );

    return Semantics(
      container: true,
      label: l.uiClientReceiptTitle,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s5),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzText(l.uiClientReceiptTitle, role: GzTextRole.uiTitle, color: c.textStrong, header: true),
            const SizedBox(height: GzSpace.s1),
            GzText(l.uiClientReceiptIssuer, role: GzTextRole.bodyS, color: c.textSecondary),
            const SizedBox(height: GzSpace.s4),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
              child: Column(
                children: [
                  metaRow(l.uiClientReceiptNumber, figure(pay?.receiptNo ?? '')),
                  metaRow(l.uiClientReceiptVoucherCode, figure(v.code)),
                  if (pay != null) metaRow(l.uiClientReceiptIssued, GzText(f.date(f.isoDay(pay.at), DateStyle.full), role: GzTextRole.bodyS, color: c.textStrong, figures: true)),
                  if (method.isNotEmpty) metaRow(l.uiClientReceiptVia, GzText(method, role: GzTextRole.bodyS, color: c.textStrong)),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s4),
            Container(
              padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s1,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GzText(l.uiClientReceiptLine(targetName), role: GzTextRole.bodyS, color: c.textStrong, figures: true),
                  ),
                  GzText(
                    '${f.integer(1)} × ${f.money(v.priceFils, const MoneyOptions(mode: MoneyMode.exact, legal: true))}',
                    role: GzTextRole.caption,
                    color: c.textSecondary,
                    figures: true,
                  ),
                  _Legal(fils: v.priceFils),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                GzText(l.uiClientReceiptTotal, role: GzTextRole.title, color: c.textPrimary),
                const Spacer(),
                _Legal(fils: v.priceFils, strong: true),
              ],
            ),
            const SizedBox(height: GzSpace.s4),
            footer,
          ],
        ),
      ),
    );
  }
}
