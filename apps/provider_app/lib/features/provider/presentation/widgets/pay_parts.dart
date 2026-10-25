// The pieces of HL-PROV-05 Pay for the plan (web `Interstitial.tsx`, `PlanReceipt.tsx`, the Summary and the hosted-page frame of
// `HL-PROV-05.tsx`): a calm in-between page, the summary list, the method picker sheet, the plan receipt (the only Ghazal document a partner
// receives) and the placeholder of the bank's hosted page (a third-party page: never Ghazal's own chrome).
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'plan_rows.dart';

enum InterTone { neutral, danger, success }

/// A calm in-between page: an icon disk (or a drawing, or the activity indicator), a title, the sentence behind an info glyph, then content.
class Interstitial extends StatelessWidget {
  const Interstitial({required this.title, this.icon, this.activity = false, this.art, this.tone = InterTone.neutral, this.body, this.children = const [], super.key});

  final IconData? icon;
  final bool activity;
  final GzIllustrationName? art;
  final InterTone tone;
  final String title;
  final String? body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final (bg, fg) = switch (tone) {
      InterTone.danger => (c.statusDangerBg, c.iconDanger),
      InterTone.success => (c.statusSuccessBg, c.iconSuccess),
      InterTone.neutral => (c.surfaceTint, c.iconPrimary),
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s10, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (art != null)
            GzIllustration(art!)
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s1),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                child: SizedBox(width: GzSize.avatarMd, height: GzSize.avatarMd, child: Center(child: activity ? const GzActivity(size: GzSize.iconMd) : GzIcon(icon!, size: GzIconSize.md, color: fg))),
              ),
            ),
          const SizedBox(height: GzSpace.s3),
          GzText(title, role: GzTextRole.uiXl, color: c.textStrong),
          if (body != null) ...[const SizedBox(height: GzSpace.s3), GzInfoButton(title: context.l10n.hotelProviderDetails, paragraphs: [body!])],
          ...children,
        ],
      ),
    );
  }
}

/// The summary list: listing, plan with its length, and (unless hidden) the amount or what was paid.
class PaySummary extends StatelessWidget {
  const PaySummary({required this.listingTitle, required this.cycle, required this.periodDays, this.amount, this.paid = false, super.key});

  final String listingTitle;
  final AdPlanCycle cycle;
  final int periodDays;
  final String? amount;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final c = context.gz.colors;
    Widget row(IconData icon, String label, Widget value, {bool last = false}) => DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
        child: Row(
          children: [
            GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary, semanticLabel: label),
            const SizedBox(width: GzSpace.s4),
            Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: value)),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(GzIcons.megaphone, l.hotelProviderSumListing, GzText(listingTitle, role: GzTextRole.body, color: c.textStrong, textAlign: TextAlign.end)),
          row(GzIcons.calendar, l.hotelProviderSumPlan, GzText('${planName(g, cycle)} · ${g.commonCountDays(periodDays)}', role: GzTextRole.body, color: c.textStrong, figures: true)),
          if (amount != null) row(GzIcons.coins, paid ? l.hotelProviderSumPaid : l.hotelProviderSumAmount, GzText(amount!, role: GzTextRole.body, color: c.textStrong, figures: true)),
        ],
      ),
    );
  }
}

/// The method picker: five radio rows and Done.
class MethodsSheet extends StatefulWidget {
  const MethodsSheet({required this.value, required this.onPick, required this.onDone, super.key});

  final GzPaymentMethodKey value;
  final ValueChanged<GzPaymentMethodKey> onPick;
  final VoidCallback onDone;

  @override
  State<MethodsSheet> createState() => _MethodsSheetState();
}

class _MethodsSheetState extends State<MethodsSheet> {
  late GzPaymentMethodKey _pick = widget.value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final m in GzPaymentMethodKey.values)
        GzPaymentMethodRow(
          method: m,
          selected: _pick == m,
          last: m == GzPaymentMethodKey.values.last,
          onSelect: () {
            setState(() => _pick = m);
            widget.onPick(m);
          },
        ),
      const SizedBox(height: GzSpace.s4),
      GzSheetFooter(child: GzButton(label: context.l10n.commonActionDone, fullWidth: true, onPressed: widget.onDone)),
    ],
  );
}

String methodName(BuildContext context, GzPaymentMethodKey m) {
  final l = context.l10n;
  return switch (m) {
    GzPaymentMethodKey.knet => l.hotelProviderMethodKnet,
    GzPaymentMethodKey.visa => l.hotelProviderMethodVisa,
    GzPaymentMethodKey.mastercard => l.hotelProviderMethodMastercard,
    GzPaymentMethodKey.applePay => l.hotelProviderMethodApplePay,
    GzPaymentMethodKey.googlePay => l.hotelProviderMethodGooglePay,
  };
}

/// The plan receipt: issuer, number, date, listing, plan, how it was paid and the total. Documents say KWD (legal), Western digits.
class PlanReceipt extends StatelessWidget {
  const PlanReceipt({required this.number, required this.listingTitle, required this.cycle, required this.fils, required this.paidAt, required this.method, super.key});

  final String number;
  final String listingTitle;
  final AdPlanCycle cycle;
  final int fils;
  final DateTime? paidAt;
  final String method;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final when = paidAt == null ? null : '${f.date(paidAt!, DateStyle.compact)} · ${f.time(paidAt!)}';
    Widget row(String k, String v, {bool figures = false}) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [GzText(k, role: GzTextRole.caption, color: c.textSecondary), GzText(v, role: GzTextRole.body, color: c.textStrong, figures: figures)],
      ),
    );
    return Semantics(
      container: true,
      label: l.hotelProviderReceiptTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [GzIcon(GzIcons.receipt, size: GzIconSize.md, color: c.iconPrimary), const SizedBox(width: GzSpace.s3), GzText(l.hotelProviderReceiptIssuer, role: GzTextRole.title, color: c.textStrong)]),
          const SizedBox(height: GzSpace.s4),
          row(l.hotelProviderReceiptNumber, number, figures: true),
          if (when != null) row(l.hotelProviderReceiptDate, when, figures: true),
          row(l.hotelProviderReceiptListing, listingTitle),
          row(l.hotelProviderReceiptPlan, planName(g, cycle)),
          row(l.hotelProviderReceiptVia, method),
          Row(
            children: [
              Expanded(child: GzText(g.commonMoneyTotal, role: GzTextRole.title, color: c.textStrong)),
              GzText(f.money(fils, const MoneyOptions(mode: MoneyMode.exact, legal: true)), role: GzTextRole.priceTotal, color: c.textStrong, figures: true),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          GzText(l.hotelProviderReceiptFoot, role: GzTextRole.caption, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// The bank's hosted page stand-in: merchant, amount, three empty fields and Cancel / Pay. A third-party page, drawn plain on the quiet surface.
class BankPage extends StatelessWidget {
  const BankPage({required this.method, required this.legalAmount, required this.onCancel, required this.onPay, this.answer, super.key});

  final GzPaymentMethodKey method;
  final String legalAmount;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final Widget? answer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final c = context.gz.colors;
    final mark = switch (method) {
      GzPaymentMethodKey.knet => 'KNET',
      GzPaymentMethodKey.visa || GzPaymentMethodKey.mastercard => 'VISA · MC',
      _ => 'PAY',
    };
    Widget fact(String k, String v, {bool figures = false}) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GzText(k, role: GzTextRole.caption, color: c.textSecondary), GzText(v, role: GzTextRole.title, color: c.textStrong, figures: figures)]),
    );
    Widget field(String k) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(k, role: GzTextRole.caption, color: c.textSecondary),
            const SizedBox(height: GzSpace.s1),
            DecoratedBox(
              decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
              child: const SizedBox(height: GzSize.controlMd, width: double.infinity),
            ),
          ],
        ),
      ),
    );
    Widget button(String label, VoidCallback tap, {bool solid = false}) => Expanded(
      child: GzPressable(
        onPressed: tap,
        child: DecoratedBox(
          decoration: BoxDecoration(color: solid ? c.surfaceDark : c.surfaceRaised, borderRadius: GzRadius.xsAll, border: Border.all(color: c.borderControl, width: GzStroke.hair)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.controlMd),
            child: Center(child: GzText(label, role: GzTextRole.button, color: solid ? c.textOnDark : c.textStrong)),
          ),
        ),
      ),
    );
    return ColoredBox(
      color: c.surfaceQuiet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceRaised, border: Border(bottom: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(GzSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
                    child: Directionality(textDirection: TextDirection.ltr, child: GzText(mark, role: GzTextRole.title, color: c.textStrong, figures: true)),
                  ),
                  fact(l.hotelProviderBankMerchant, l.hotelProviderBankMerchantName),
                  fact(l.hotelProviderBankAmount, legalAmount, figures: true),
                  const SizedBox(height: GzSpace.s2),
                  field(l.hotelProviderBankCard),
                  field(l.hotelProviderBankExpiry),
                  field(l.hotelProviderBankPin),
                  const SizedBox(height: GzSpace.s2),
                  Row(children: [button(g.commonActionCancel, onCancel), const SizedBox(width: GzSpace.s3), button(l.hotelProviderBankSubmit, onPay, solid: true)]),
                ],
              ),
            ),
          ),
          if (answer != null) ...[const SizedBox(height: GzSpace.s4), Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: answer)],
        ],
      ),
    );
  }
}
