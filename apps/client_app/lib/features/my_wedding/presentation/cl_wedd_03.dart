import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/wd_budget_rows.dart';
import 'widgets/wd_common.dart' show WdGap, WdPad, wdCatName;
import 'widgets/wd_section_header.dart';
import '../application/wedding_data.dart';

/// CL-WEDD-03 Budget. Covers CA-TOOL-05, CA-TOOL-06, CA-TOOL-07, CA-TOOL-08, CA-TOOL-09, CA-TOOL-11, CA-ONB-04, CA-AUTH-10.
///
/// Committed versus paid versus remaining (pushed from My Wedding 'CL-WEDD-01'). What is left is the hero; one segmented bar and its figures say how the rest divides;
/// categories are ranked by what has gone into them, each with its own meter; the voucher (KD 2, Paid) and the venue price (Committed)
/// post themselves to the venue category (read only, they open the booking) and the couple's own expenses sit beside them. Alerts are
/// calm: a gold-ink note at 80%, the functional danger state at 100%.
class ClWedd03Screen extends ConsumerWidget {
  const ClWedd03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(weddingBudgetProvider);
    final top = GzTopBar(title: l.clientMyWeddingBudgetTitle);
    return GzScreen(
      top: top,
      bottom: GzActionBar(
        action: GzActionBarAction(label: l.clientMyWeddingBudgetAddExpense, onPressed: () => _add(context, ref)),
      ),
      child: BkBudgetAsync(value: async, onRetry: () => ref.invalidate(weddingBudgetProvider), data: (view) => _body(context, ref, view)),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    context.gzNav.openSheet('CL-WEDD-04');
  }

  Widget _body(BuildContext context, WidgetRef ref, BudgetView view) {
    final l = context.l10n;
    if (view.budget.total.fils <= 0) {
      return WdPad(
        child: GzEmptyState(
          illustration: GzIllustrationName.card,
          title: l.clientMyWeddingBudgetEmptyTitle,
          action: GzStateAction(
            label: l.clientMyWeddingBudgetEmptyAction,
            onPressed: () => context.gzNav.openSheet('CL-WEDD-05'),
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
          _categories(context, ref, view),
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

  Widget _categories(BuildContext context, WidgetRef ref, BudgetView view) {
    final l = context.l10n;
    final nav = context.gzNav;
    final cats = [...view.budget.categories]..sort((a, b) => (b.paid.fils + b.committed.fils).compareTo(a.paid.fils + a.committed.fils));
    return WdGap(
      gap: GzSpace.s3,
      children: [
        WdPad(
          child: WdSectionHeader(
            title: l.clientMyWeddingBudgetCategories,
            unit: context.gzFormat.moneyParts(0).currency,
            seeAllLabel: l.clientMyWeddingToolServices,
            onSeeAll: () => nav.push('CL-SERV-01'),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final cat in cats) WdCategoryRow(category: cat, total: view.budget.total.fils, last: cat == cats.last)],
        ),
      ],
    );
  }

  Widget _ledger(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(weddingLedgerProvider);
    // The web ledger list is full-bleed: each row pads itself with the gutter and its rule runs edge to edge.
    return WdGap(
      gap: GzSpace.s3,
      children: [
        WdPad(
          child: WdSectionHeader(
            title: l.clientMyWeddingBudgetLedger,
            info: GzInfoButton(title: l.clientMyWeddingBudgetInfoTitle, paragraphs: [l.clientMyWeddingBudgetInfoBody]),
          ),
        ),
        BkBudgetAsync<List<LedgerEntry>>(
          value: async,
          onRetry: () => ref.invalidate(weddingLedgerProvider),
          data: (rows) {
            if (rows.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final r in rows) WdLedgerRow(entry: r, last: r == rows.last)],
            );
          },
        ),
      ],
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
