import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/wedding_data.dart';
import 'wd_common.dart' show wdCatGlyph, wdCatName;

/// One budget category: a disk glyph, one short word and the bare spent-against-share figure. Under it a 4 px meter (paid ink,
/// committed gold, the rest on the track). At 80% the figure turns gold-ink with the info glyph; at 100% the functional danger text
/// with the warning glyph. Never colour alone.
class WdCategoryRow extends StatelessWidget {
  const WdCategoryRow({required this.category, required this.total, required this.guest, this.last = false, super.key});

  final bool last;

  final BudgetCategory category;
  final int total;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final used = category.paid.fils + category.committed.fils;
    final top = used > category.allocated.fils ? used : category.allocated.fils;
    final share = category.allocated.fils <= 0 ? 0.0 : used / category.allocated.fils;
    final over = category.allocated.fils > 0 && used > category.allocated.fils;
    final soft = !over && share >= 0.8;
    final name = wdCatName(l, category.id);
    String bare(int fils) => f.moneyParts(fils).amount;
    return Semantics(
      container: true,
      label: '$name ${l.clientMyWeddingBudgetUsedLabel(f.percent(category.allocated.fils == 0 ? 0 : share * 100, maxFraction: 0))}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: GzSize.thumbSm,
              height: GzSize.thumbSm,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
              alignment: Alignment.center,
              child: GzIcon(wdCatGlyph(category.icon), size: GzIconSize.md, color: c.textPrimary),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: GzText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                            ),
                            if (category.autoLinked && used > 0) ...[
                              const SizedBox(width: GzSpace.s2),
                              GzIcon(GzIcons.link, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l.clientMyWeddingBudgetLinked),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      if (over)
                        GzIcon(
                          GzIcons.warningCircle,
                          size: GzIconSize.xs,
                          color: c.textDanger,
                          semanticLabel: l.clientMyWeddingBudgetOverByLabel(f.money(used - category.allocated.fils)),
                        ),
                      if (soft)
                        GzIcon(
                          GzIcons.info,
                          size: GzIconSize.xs,
                          color: c.iconAccent,
                          semanticLabel: l.clientMyWeddingBudgetUsedLabel(f.percent(share * 100, maxFraction: 0)),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzText(bare(used), role: GzTextRole.figBodyS, color: over ? c.textDanger : c.textStrong, figures: true),
                          GzText('/${bare(category.allocated.fils)}', role: GzTextRole.figBodyS, color: c.textSecondary, figures: true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s2),
                  SizedBox(
                    height: GzStroke.threadMax,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (category.paid.fils > 0)
                          Expanded(
                            flex: category.paid.fils,
                            child: ColoredBox(color: c.textStrong),
                          ),
                        if (category.committed.fils > 0)
                          Expanded(
                            flex: category.committed.fils,
                            child: ColoredBox(color: c.markKhayt),
                          ),
                        Expanded(
                          flex: (top - used).clamp(1, 1 << 31),
                          child: ColoredBox(color: c.controlTrack),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One payment or expense in the Payments list: a glyph, one word, a status glyph and the amount. A Ghazal-posted automatic row (the
/// voucher: ticket; the venue price: hall) opens Booking detail and is never edited here; a manual expense shows its label and opens
/// its edit sheet. Paid is the check, committed the hourglass, planned the calendar.
class WdLedgerRow extends StatelessWidget {
  const WdLedgerRow({required this.entry, this.last = false, super.key});

  final LedgerEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final title = entry.auto
        ? (entry.voucher ? context.gzL10n.commonVoucher : wdCatName(l, entry.categoryId))
        : (entry.label ?? wdCatName(l, entry.categoryId));
    final (icon, statusIcon, statusColor, statusLabel) = entry.status == ExpenseStatus.paid
        ? (
            entry.auto ? (entry.voucher ? GzIcons.ticket : GzIcons.hall) : GzIcons.receipt,
            GzIcons.checkCircle,
            c.iconSuccess,
            l.clientMyWeddingBudgetPaid,
          )
        : entry.status == ExpenseStatus.committed
        ? (GzIcons.hall, GzIcons.hourglass, c.iconAccent, l.clientMyWeddingBudgetCommitted)
        : (GzIcons.receipt, GzIcons.calendar, c.iconSecondary, l.clientMyWeddingBudgetPlanned);
    final bookingId = entry.bookingId;
    final voucherOnly = entry.auto && entry.voucher && bookingId == null;
    return GzIconListRow(
      chevron: true,
      last: last,
      icon: icon,
      title: title,
      autoDir: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(statusIcon, size: GzIconSize.sm, color: statusColor, semanticLabel: statusLabel),
          const SizedBox(width: GzSpace.s2),
          GzPrice(fils: entry.amountFils, size: GzPriceSize.card),
        ],
      ),
      onPressed: bookingId != null
          ? () => context.gzNav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': bookingId})
          : voucherOnly
          ? () => context.gzNav.push('CL-VCHR-02')
          : entry.auto
          ? null
          : () => context.gzNav.openSheet('CL-WEDD-04', options: GzSheetOptions(params: <String, Object?>{'expenseId': entry.id})),
    );
  }
}
