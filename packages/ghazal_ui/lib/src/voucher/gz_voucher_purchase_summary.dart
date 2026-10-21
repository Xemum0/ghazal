import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate;

import '../core/core.dart';
import '../foundation.dart';

/// VoucherPurchaseSummary (ADR 0033 D1, voucher-model section 5.2): what the KD 2 buys and what it does not. A ruled list of the
/// bound quote, the two prices and the saving, then the ONE amount paid to Ghazal today (exact, three decimals, the figures voice),
/// the plain sentence that the rest is settled with the venue directly, and three rules in words (bound to this venue and quote,
/// reusable here if the venue declines, ask support for a credit voucher). Nothing here is a deposit, a balance or a refund. No panel
/// chrome: the host sheet or screen owns the surface.
class GzVoucherPurchaseSummary extends StatelessWidget {
  const GzVoucherPurchaseSummary({
    required this.targetName,
    required this.eventDate,
    required this.standardFils,
    required this.voucherFils,
    this.packageName,
    this.guests,
    this.feeFils = 2000,
    this.reuseDays = 60,
    super.key,
  });

  /// Venue or provider the voucher binds to.
  final String targetName;
  final String? packageName;
  final LocalDate eventDate;
  final int? guests;

  /// Integer fils.
  final int standardFils;
  final int voucherFils;

  /// The voucher fee in fils (configuration, default KD 2.000).
  final int feeFils;

  /// Reuse window in days (configuration, default 60).
  final int reuseDays;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final gz = context.gz;
    final savings = standardFils > voucherFils ? standardFils - voucherFils : 0;
    final facts = <(String, String)>[
      (l.uiVoucherSummaryDate, f.date(eventDate.toString(), DateStyle.full)),
      if (packageName != null) (l.uiVoucherSummaryPackage, packageName!),
      if (guests != null && guests! > 0) (l.uiVoucherSummaryGuests, GzBidi.strip(f.guests(guests!))),
    ];
    final titleWeight = gz.text(GzTextRole.title).fontWeight;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);

    // Containers, not DecoratedBoxes: the hairline takes room like the web border-box (the list is 1 + 3 x 44 high).
    Widget ruled(List<Widget> rows) => Container(
          decoration: BoxDecoration(border: Border(top: hair)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        );
    Widget row({required List<Widget> children, required bool baseline}) => Container(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          decoration: BoxDecoration(border: Border(bottom: hair)),
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: baseline ? CrossAxisAlignment.baseline : CrossAxisAlignment.center,
            textBaseline: TextBaseline.alphabetic,
            children: children,
          ),
        );
    Widget price(String label, Widget value, {Color? color, bool strong = false}) => row(
          baseline: false,
          children: [
            _TextCell(label, role: GzTextRole.bodyS, color: color ?? (strong ? c.textStrong : c.textPrimary), weight: strong ? titleWeight : null),
            value,
          ],
        );

    final rules = [
      l.uiVoucherSummaryRuleBound,
      l.uiVoucherSummaryRuleReuse(l.uiSharedSpokenDays(reuseDays)),
      l.uiVoucherSummaryRuleCredit,
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.uiVoucherSummaryHead,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  GzText(l.uiVoucherSummaryBoundTo, role: GzTextRole.label, color: c.textSecondary),
                ],
              ),
              const SizedBox(height: GzSpace.s1),
              GzText(targetName, role: GzTextRole.d1, color: c.textStrong, header: true),
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          ruled([
            for (final (k, v) in facts)
              row(
                baseline: true,
                children: [
                  GzText(k, role: GzTextRole.caption, color: c.textSecondary),
                  const SizedBox(width: GzSpace.s4),
                  Flexible(child: GzText(v, role: GzTextRole.bodyS, figures: true, textAlign: TextAlign.end)),
                ],
              ),
          ]),
          const SizedBox(height: GzSpace.s4),
          ruled([
            price(l.commonStandardPrice, GzStruckMoney(fils: standardFils)),
            price(l.commonVoucherPrice, GzPrice(fils: voucherFils, size: GzPriceSize.strong), strong: true),
            price(l.uiVoucherSummarySave, GzPrice(fils: savings, size: GzPriceSize.strong), color: c.textSuccess),
          ]),
          const SizedBox(height: GzSpace.s4),
          DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
            child: Padding(
              padding: const EdgeInsets.all(GzSpace.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(l.uiVoucherSummaryPayToday, role: GzTextRole.title),
                        GzText(l.uiVoucherSummaryPayOnce, role: GzTextRole.caption, color: c.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s4),
                  GzPrice(fils: feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                ],
              ),
            ),
          ),
          const SizedBox(height: GzSpace.s4),
          GzText(
            l.uiVoucherSummaryDirectly(f.money(voucherFils, const MoneyOptions(mode: MoneyMode.browse)), targetName),
            role: GzTextRole.bodyS,
            figures: true,
          ),
          const SizedBox(height: GzSpace.s4),
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 1), child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess)),
                const SizedBox(width: GzSpace.s2),
                Expanded(child: GzText(rules[i], role: GzTextRole.caption, color: c.textSecondary, figures: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A label with an optional weight override (the web `.gz-vps__strong`).
class _TextCell extends StatelessWidget {
  const _TextCell(this.text, {required this.role, required this.color, this.weight});

  final String text;
  final GzTextRole role;
  final Color color;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) => weight == null
      ? GzText(text, role: role, color: color)
      : GzText.rich(TextSpan(text: text, style: TextStyle(fontWeight: weight)), role: role, color: color);
}
