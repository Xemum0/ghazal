import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate, gzProblemMessage, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_common.dart' show WdGap, WdPad, wdCatGlyph, wdCatName;
import '../application/wedding_data.dart';

/// CL-WEDD-03 Budget. Covers CA-TOOL-05, CA-TOOL-06, CA-TOOL-07, CA-TOOL-08, CA-TOOL-09, CA-TOOL-11, CA-ONB-04, CA-AUTH-10.
///
/// Committed versus paid versus remaining (pushed from My Wedding 'CL-WEDD-01'; a guest meets the account sheet ('CL-AUTH-01', opened by
/// requireSignIn) at the first write). What is left is the hero; one segmented bar and its figures say how the rest divides;
/// categories are ranked by what has gone into them, each with its own meter; the voucher (KD 2, Paid) and the venue price (Committed)
/// post themselves to the venue category (read only, they open the booking) and the couple's own expenses sit beside them. Alerts are
/// calm: a gold-ink note at 80%, the functional danger state at 100%. A guest sees a sample and signs in at the first write.
class ClWedd03Screen extends ConsumerWidget {
  const ClWedd03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final async = ref.watch(weddingBudgetProvider);
    final top = GzTopBar(title: l.clientMyWeddingBudgetTitle);
    return GzScreen(
      top: top,
      bottom: guest
          ? null
          : GzActionBar(
              action: GzActionBarAction(label: l.clientMyWeddingBudgetAddExpense, onPressed: () => _add(context, ref)),
            ),
      child: BkBudgetAsync(value: async, onRetry: () => ref.invalidate(weddingBudgetProvider), data: (view) => _body(context, ref, view, guest)),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    if (!ref.requireSignIn(GateReason.planner, resume: GateResume('CL-WEDD-04'))) return;
    context.gzNav.openSheet('CL-WEDD-04');
  }

  Widget _body(BuildContext context, WidgetRef ref, BudgetView view, bool guest) {
    final l = context.l10n;
    if (view.budget.total.fils <= 0) {
      return WdPad(
        child: GzEmptyState(
          illustration: GzIllustrationName.card,
          title: l.clientMyWeddingBudgetEmptyTitle,
          action: GzStateAction(
            label: l.clientMyWeddingBudgetEmptyAction,
            onPressed: () {
              if (guest && !ref.requireSignIn(GateReason.planner, resume: GateResume('CL-WEDD-05'))) return;
              context.gzNav.openSheet('CL-WEDD-05');
            },
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.section),
      child: WdGap(
        gap: GzSpace.section,
        children: [
          WdPad(
            child: WdGap(
              gap: GzSpace.s5,
              children: [
                _BudgetHero(view: view),
                if (_hasAlert(view)) _alert(context, view),
              ],
            ),
          ),
          _categories(context, ref, view, guest),
          _ledger(context, ref),
        ],
      ),
    );
  }

  bool _hasAlert(BudgetView view) {
    for (final cat in view.budget.categories) {
      if (cat.allocated.fils > 0 && (cat.paid.fils + cat.committed.fils) * 100 >= cat.allocated.fils * 80) return true;
    }
    return false;
  }

  /// One alert at the top: the category over its share, else the one that reached 80%.
  Widget _alert(BuildContext context, BudgetView view) {
    final l = context.l10n;
    final f = context.gzFormat;
    BudgetCategory? soft;
    for (final cat in view.budget.categories) {
      final used = cat.paid.fils + cat.committed.fils;
      if (cat.allocated.fils > 0 && used > cat.allocated.fils) {
        return GzBanner(
          message: l.clientMyWeddingBudgetAlertOver(wdCatName(l, cat.id), f.money(used - cat.allocated.fils)),
          tone: GzBannerTone.danger,
          shape: GzBannerShape.card,
        );
      }
      if (cat.allocated.fils > 0 && soft == null && used * 100 >= cat.allocated.fils * 80) soft = cat;
    }
    if (soft == null) return const SizedBox.shrink();
    final used = soft.paid.fils + soft.committed.fils;
    return GzBanner(
      message: l.clientMyWeddingBudgetAlertSoft(wdCatName(l, soft.id), f.percent(used / soft.allocated.fils * 100, maxFraction: 0)),
      tone: GzBannerTone.info,
      shape: GzBannerShape.card,
    );
  }

  Widget _categories(BuildContext context, WidgetRef ref, BudgetView view, bool guest) {
    final l = context.l10n;
    final nav = context.gzNav;
    final cats = [...view.budget.categories]..sort((a, b) => (b.paid.fils + b.committed.fils).compareTo(a.paid.fils + a.committed.fils));
    return WdGap(
      gap: GzSpace.s3,
      children: [
        WdPad(
          child: GzSectionHeader(
            title: l.clientMyWeddingBudgetCategories,
            draw: GzDraw.mount,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(context.gzFormat.moneyParts(0).currency, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
                const SizedBox(width: GzSpace.s2),
                GzButton(
                  variant: GzButtonVariant.tertiary,
                  iconEnd: GzIcons.chevronRight,
                  onPressed: () => nav.push('CL-SERV-01'),
                  label: l.clientMyWeddingToolServices,
                ),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final cat in cats) _CategoryRow(category: cat, total: view.budget.total.fils, guest: guest, last: cat == cats.last)],
        ),
      ],
    );
  }

  Widget _ledger(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(weddingLedgerProvider);
    return WdPad(
      child: WdGap(
        children: [
          GzSectionHeader(title: l.clientMyWeddingBudgetLedger, draw: GzDraw.mount),
          BkBudgetAsync<List<LedgerEntry>>(
            value: async,
            onRetry: () => ref.invalidate(weddingLedgerProvider),
            data: (rows) {
              if (rows.isEmpty) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final r in rows) _LedgerRow(entry: r, last: r == rows.last)],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One budget category: a disk glyph, one short word and the bare spent-against-share figure. Under it a 4 px meter (paid ink,
/// committed gold, the rest on the track). At 80% the figure turns gold-ink with the info glyph; at 100% the functional danger text
/// with the warning glyph. Never colour alone.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.total, required this.guest, this.last = false});

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

/// The budget states: skeleton while loading, the problem with retry, the offline banner over the stale budget.
class BkBudgetAsync<T> extends StatelessWidget {
  const BkBudgetAsync({required this.value, required this.data, this.onRetry, super.key});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v.isLoading && !v.hasValue) {
      return const WdPad(child: WdGap(children: [GzSkeleton(blockSize: 120), GzSkeleton(blockSize: 200)]));
    }
    if (v.hasError && !v.hasValue) {
      final p = v.error;
      return GzErrorState(kind: GzErrorKind.load, body: p is ApiProblem ? gzProblemMessage(context.gzL10n, p) : null, onRetry: onRetry, fill: false);
    }
    final stale = v.value;
    if (stale == null) return const WdPad(child: GzSkeleton(blockSize: 200));
    if (v.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush),
          data(stale),
        ],
      );
    }
    return data(stale);
  }
}

/// The figure the couple came for, then how it divides: Remaining as the hero figure under one word, the total as a coin glyph and a
/// figure with the one-word Edit beside it, one segmented bar (paid ink, committed gold, the rest rose-tint) with a two-glyph legend,
/// so the bar is never the only signal. Over budget swaps the word for the warning glyph and "Over", never colour alone.
class _BudgetHero extends StatelessWidget {
  const _BudgetHero({required this.view});

  final BudgetView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final total = view.budget.total.fils;
    final paid = view.paid.fils;
    final committed = view.committed.fils;
    final remaining = view.remaining.fils;
    final over = remaining < 0;
    final spent = paid + committed;
    final scale = spent > total ? spent : total;
    final rest = scale - spent < 0 ? 0 : scale - spent;
    Widget swatch(Color color) => Container(
      width: GzSpace.s2,
      height: GzSpace.s2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    Widget seg(int flex, Color color) => flex <= 0
        ? const SizedBox.shrink()
        : Expanded(
            flex: flex,
            child: Container(
              height: GzSpace.s2,
              decoration: BoxDecoration(color: color, borderRadius: GzRadius.pillAll),
            ),
          );
    return Semantics(
      container: true,
      label: l.clientMyWeddingBudgetTitle,
      child: WdGap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 0),
                child: Row(
                  children: [
                    if (over)
                      GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.textDanger)
                    else
                      Container(
                        width: GzSpace.s2,
                        height: GzSpace.s2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.borderHairline, width: GzStroke.hair),
                          color: c.surfaceTint,
                        ),
                      ),
                    const SizedBox(width: GzSpace.s1),
                    Expanded(
                      child: GzText(
                        over ? l.clientMyWeddingBudgetOver : l.clientMyWeddingBudgetRemaining,
                        role: GzTextRole.caption,
                        color: over ? c.textDanger : c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GzSpace.s1),
              GzPrice(fils: remaining.abs(), size: GzPriceSize.hero),
              const SizedBox(height: GzSpace.s1),
              Row(
                children: [
                  GzFactChip(
                    icon: GzIcons.coins,
                    label: l.clientMyWeddingBudgetTotalLabel,
                    value: f.money(total),
                    small: true,
                    tone: GzFactTone.muted,
                  ),
                  const Spacer(),
                  GzButton(
                    variant: GzButtonVariant.tertiary,
                    onPressed: () => context.gzNav.openSheet('CL-WEDD-05'),
                    label: context.gzL10n.commonActionEdit,
                  ),
                ],
              ),
            ],
          ),
          Semantics(
            image: true,
            label: l.clientMyWeddingBudgetBarLabel(f.money(paid), f.money(committed), f.money(rest < 0 ? 0 : rest)),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  seg(paid, c.textStrong),
                  const SizedBox(width: GzStroke.thread),
                  seg(committed, c.markKhayt),
                  const SizedBox(width: GzStroke.thread),
                  seg(rest, c.surfaceTint),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: GzSpace.s6,
            runSpacing: GzSpace.s2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatch(c.textStrong),
                  const SizedBox(width: GzSpace.s2),
                  GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSecondary, semanticLabel: l.clientMyWeddingBudgetPaid),
                  const SizedBox(width: GzSpace.s1),
                  GzPrice(fils: paid, size: GzPriceSize.strong),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatch(c.markKhayt),
                  const SizedBox(width: GzSpace.s2),
                  GzIcon(GzIcons.hourglass, size: GzIconSize.sm, color: c.iconAccent, semanticLabel: l.clientMyWeddingBudgetCommitted),
                  const SizedBox(width: GzSpace.s1),
                  GzPrice(fils: committed, size: GzPriceSize.strong),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One payment or expense in the Payments list: a glyph, one word, a status glyph and the amount. A Ghazal-posted automatic row (the
/// voucher: ticket; the venue price: hall) opens Booking detail and is never edited here; a manual expense shows its label and opens
/// its edit sheet. Paid is the check, committed the hourglass, planned the calendar.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, this.last = false});

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
      flush: true,
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
