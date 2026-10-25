// HL-GROW-01 Voucher prices (web `HL-GROW-01.tsx`): the venue's voucher-price settings by state (Active, Scheduled, Ended): the standing voucher prices
// of every package ("Always on") and the time-boxed windows that lower the voucher price for chosen event dates. Windows replace offers, flash sales
// and venue coupon codes (ADR 0033 D4). The place to duplicate or end a window; with nothing active it turns the open weekend dates into the next step.
// Requirements: HA-OFFR-05, HA-OFFR-06, HA-OFFR-02, HA-OFFR-03, HA-AUTH-02, HA-VMGT-11.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/grow_data.dart';
import '../application/grow_model.dart';
import 'widgets/grow_bits.dart';
import 'widgets/window_parts.dart';

class HlGrow01Screen extends ConsumerStatefulWidget {
  const HlGrow01Screen({super.key});

  @override
  ConsumerState<HlGrow01Screen> createState() => _HlGrow01ScreenState();
}

class _HlGrow01ScreenState extends ConsumerState<HlGrow01Screen> {
  GrowTab _tab = GrowTab.active;
  bool _opened = false;

  void _tryOpenRequested() {
    final id = ref.read(growSessionProvider).openWindow;
    final windows = ref.read(growWindowsProvider).value;
    if (id == null || windows == null || _opened) return;
    _opened = true;
    ref.read(growSessionProvider.notifier).requestOpen(null);
    final w = windows.where((x) => x.id == id).firstOrNull;
    if (w != null) setState(() => _tab = tabOf(w));
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _openSheet(id) : null);
  }

  void _openSheet(String id) {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    if (id == kStandingId) {
      String? key;
      key = nav.openSheetBuilder(
        (_) => StandingActions(
          onEdit: () {
            nav.closeSheet(key);
            nav.push('HL-VENU-02');
          },
        ),
        options: GzSheetOptions(title: l.hotelGrowStandingTitle),
      );
      return;
    }
    final w = ref.read(growWindowsProvider).value?.where((x) => x.id == id).firstOrNull;
    if (w == null) return;
    String? key;
    key = nav.openSheetBuilder(
      (_) => WindowActions(id: id, onDuplicate: () => _duplicate(key, w), onEnd: () => _end(key, w)),
      options: GzSheetOptions(title: windowTitle(context, w)),
    );
  }

  void _duplicate(String? key, VoucherWindow w) {
    final nav = GzNavigatorScope.of(context);
    nav.closeSheet(key);
    final session = ref.read(growSessionProvider.notifier);
    session.reset(draftFromWindow(w));
    session.setOrigin(list: true);
    nav.push('HL-GROW-02', params: {'from': 'list', 'duplicateOf': w.id});
  }

  Future<void> _end(String? key, VoucherWindow w) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final title = windowTitle(context, w);
    nav.closeSheet(key);
    final answer = await nav.openDialog(
      GzDialogSpec(
        title: l.hotelGrowEndTitle(title),
        body: l.hotelGrowEndBody,
        icon: GzIcons.warning,
        tone: GzDialogTone.destructive,
        confirmLabel: l.hotelGrowEndConfirm,
        cancelLabel: l.hotelGrowEndKeep,
      ),
    );
    if (answer != GzDialogResult.confirm) return;
    final res = await ref.read(growActionsProvider.notifier).end(w.id);
    res.when(
      success: (_) => nav.toast(GzToastSpec(message: l.hotelGrowToastEnded(title), tone: GzToastTone.success)),
      failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger)),
      gated: () {},
    );
  }

  void _newWindow({required bool prefill, required List<String> soft, required PackageCatalog cat}) {
    final nav = GzNavigatorScope.of(context);
    final session = ref.read(growSessionProvider.notifier);
    final base = emptyDraftFor(cat);
    session.reset(prefill ? base.copyWith(eventDates: [...soft], prefilled: true) : base);
    session.setOrigin(list: true);
    nav.push('HL-GROW-02', params: prefill ? {'from': 'list', 'dates': soft} : {'from': 'list'});
  }

  void _rules() {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        child: GzText(l.hotelGrowBestOnly, role: GzTextRole.body, color: context.gz.colors.textPrimary),
      ),
      options: GzSheetOptions(title: l.hotelGrowRulesTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final windowsValue = ref.watch(growWindowsProvider);
    final catValue = ref.watch(growCatalogProvider);
    final soft = ref.watch(growSoftDatesProvider).value ?? const <String>[];
    final highlight = ref.watch(growSessionProvider.select((s) => s.highlight));
    ref.listen(growSessionProvider.select((s) => s.openWindow), (_, next) {
      if (next != null) {
        _opened = false;
        _tryOpenRequested();
      }
    });
    ref.listen(growWindowsProvider, (_, _) => _tryOpenRequested());
    final windows = windowsValue.value ?? const <VoucherWindow>[];
    final cat = catValue.value;
    final shown = [
      for (final w in windows)
        if (tabOf(w) == _tab) w,
    ];
    final emptyActive = _tab == GrowTab.active && shown.isEmpty && windowsValue.hasValue;
    final ready = windowsValue.hasValue && cat != null;
    final bar = !ready
        ? null
        : GzActionBar(
            action: emptyActive && soft.isNotEmpty
                ? GzActionBarAction(
                    label: l.hotelGrowLowerPrice,
                    iconEnd: GzIcons.chevronRight,
                    onPressed: () => _newWindow(prefill: true, soft: soft, cat: cat),
                  )
                : GzActionBarAction(
                    label: l.hotelGrowNewWindow,
                    iconEnd: GzIcons.plus,
                    onPressed: () => _newWindow(prefill: false, soft: soft, cat: cat),
                  ),
          );
    return GzPullToRefresh(
      onRefresh: () async {
        ref.invalidate(growWindowsProvider);
        await ref.read(growWindowsProvider.future);
      },
      child: GzScreen(
        top: GzTopBar(
          title: l.hotelGrowListTitle,
          actions: [GzTopBarAction(icon: GzIcons.info, label: l.commonA11yInfo, onPressed: _rules)],
        ),
        bottom: bar,
        child: GzAsyncView<List<VoucherWindow>>(
          value: windowsValue,
          loading: const _ListSkeleton(),
          onRetry: () => ref.invalidate(growWindowsProvider),
          data: (_) {
            const pad = EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: pad,
                  child: GzIconTabs<GrowTab>(
                    label: l.hotelGrowTabsLabel,
                    value: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                    items: [
                      GzIconTabItem(value: GrowTab.active, icon: GzIcons.bolt, label: l.hotelGrowTabActive),
                      GzIconTabItem(value: GrowTab.scheduled, icon: GzIcons.hourglass, label: l.hotelGrowTabScheduled),
                      GzIconTabItem(value: GrowTab.ended, icon: GzIcons.calendarCheck, label: l.hotelGrowTabEnded),
                    ],
                  ),
                ),
                if (_tab == GrowTab.active || shown.isNotEmpty) ...[
                  if (_tab == GrowTab.active && shown.isNotEmpty && soft.isNotEmpty && cat != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3),
                      child: _Insight(
                        count: soft.length,
                        onTap: () => _newWindow(prefill: true, soft: soft, cat: cat),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_tab == GrowTab.active) StandingRow(onOpen: () => _openSheet(kStandingId)),
                        for (final w in shown) WindowRow(key: ValueKey(w.id), window: w, isNew: w.id == highlight, onOpen: () => _openSheet(w.id)),
                      ],
                    ),
                  ),
                  if (_tab == GrowTab.active && shown.isEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GzEmptyState(fill: false, illustration: GzIllustrationName.emptyVouchers, title: l.hotelGrowEmptyTitle),
                          if (soft.isNotEmpty) ...[
                            const SizedBox(height: GzSpace.s4),
                            Container(
                              margin: pad,
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
                              decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                                    child: GzIcon(GzIcons.calendarDots, size: GzIconSize.sm, color: c.iconPrimary),
                                  ),
                                  const SizedBox(width: GzSpace.s3),
                                  Expanded(
                                    child: Wrap(
                                      spacing: GzSpace.s2,
                                      runSpacing: GzSpace.s2,
                                      children: [for (final d in soft) GzTag(label: dm(f, d), icon: GzIcons.calendar)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ] else
                  GzEmptyState(
                    fill: false,
                    illustration: _tab == GrowTab.scheduled ? GzIllustrationName.calendar : GzIllustrationName.shelf,
                    title: _tab == GrowTab.scheduled ? l.hotelGrowNoScheduledTitle : l.hotelGrowNoEndedTitle,
                    action: GzStateAction(label: l.hotelGrowShowActive, onPressed: () => setState(() => _tab = GrowTab.active)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    return GzPressable(
      onPressed: onTap,
      semanticLabel: l.hotelGrowSoftInsight(count, 60),
      minHeight: GzSize.rowMin,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s4, top: GzSpace.s2, bottom: GzSpace.s2),
        decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
        child: Row(
          children: [
            const GzIllustration(GzIllustrationName.calendar, size: GzIllustrationSize.sm),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(f.integer(count), role: GzTextRole.figXl, color: c.textStrong, figures: true),
                  GzText(l.hotelGrowOpenDates, role: GzTextRole.caption, color: c.textSecondary),
                ],
              ),
            ),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
          for (var i = 0; i < 3; i++)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzSkeleton(variant: GzSkeletonVariant.line, inlineSize: 176, blockSize: 24),
                  SizedBox(height: GzSpace.s1),
                  GzSkeleton(variant: GzSkeletonVariant.line, inlineSize: 96, blockSize: 24),
                  SizedBox(height: GzSpace.s1),
                  GzSkeleton(variant: GzSkeletonVariant.line, inlineSize: 216, blockSize: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
