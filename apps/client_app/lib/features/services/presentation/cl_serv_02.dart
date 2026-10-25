import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/services_providers.dart';
import 'services_glyphs.dart';
import 'widgets/serv_vendor_tile.dart';

/// CL-SERV-02 Vendors. Covers CA-SVC-02, CA-SVC-03, CA-SVC-09, CA-SVC-17, CA-TOOL-02, CA-VCH-02.
///
/// Vendors in one category with name, rating, starting price and photos, plus area, price and rating filters and sort.
/// Provider card: 4:5 cover, name, area, rating with count, price line "Voucher from KD 400 · Standard from KD 450" with
/// the unit; heart saves to Saved > Services; "Sponsored" only on paid placements.
class ClServ02Screen extends ConsumerStatefulWidget {
  const ClServ02Screen({super.key});

  @override
  ConsumerState<ClServ02Screen> createState() => _ClServ02State();
}

class _ClServ02State extends ConsumerState<ClServ02Screen> {
  String? _catId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final params = ServicesParams.of(context.gzNav.params);
    final cats = ref.watch(servicesCategoriesProvider);
    final all = cats.value ?? const <ServiceCategory>[];
    final catId = _catId ?? params.categoryId ?? kHeroCategoryId;
    final category = categoryById(all, catId) ?? (all.isEmpty ? null : all.first);
    final filter = ref.watch(servicesFilterProvider(catId));
    final list = ref.watch(servicesFilteredProvider(ServQuery(catId, filter)));
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final siblings = [
      for (final c in all)
        if (c.groupId == category?.groupId) c,
    ];

    Future<void> refresh() async {
      final refreshed = context.l10n.clientServicesListRefreshed;
      final nav = context.gzNav;
      ref.invalidate(servicesCategoriesProvider);
      ref.invalidate(servicesCountsProvider);
      ref.invalidate(servicesFilteredProvider(ServQuery(catId, filter)));
      try {
        await ref.read(servicesFilteredProvider(ServQuery(catId, filter)).future);
        if (!mounted) return;
        nav.toast(GzToastSpec(message: refreshed, tone: GzToastTone.success));
      } on Object {
        // the screen shows its own error state
      }
    }

    final title = category == null ? l.clientServicesListTitle : context.bi(category.name);

    return GzPullToRefresh(
      onRefresh: refresh,
      child: GzScreen(
        top: GzTopBar(
          variant: GzTopBarVariant.largeTitle,
          title: title,
          actions: [
            GzTopBarAction(
              icon: GzIcons.filter,
              label: l.clientServicesFilterLabel,
              count: filter.appliedCount == 0 ? null : filter.appliedCount,
              onPressed: () => _openFilters(context, ref, catId),
            ),
          ],
        ),
        child: GzAsyncView<List<ServiceCategory>>(
          value: cats,
          onRetry: () => ref.invalidate(servicesCategoriesProvider),
          loading: const _ListSkeleton(),
          data: (_) {
            final items = list.value ?? const <ServiceProvider>[];
            final filteredEmpty = !list.isLoading && list.hasValue && items.isEmpty;
            return Column(
              key: ValueKey<String>('services.list.$catId'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (siblings.length > 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s1, start: GzSpace.gutter, end: GzSpace.gutter),
                    child: GzIconSegmented<String>(
                      label: l.clientServicesListSiblings,
                      labels: GzIconSegmentedLabels.none,
                      value: catId,
                      onChanged: (v) => setState(() => _catId = v),
                      options: [
                        for (final s in siblings)
                          GzIconSegmentedOption<String>(value: s.id.value, icon: servicesGlyphOf(s.icon), label: context.bi(s.name)),
                      ],
                    ),
                  ),
                if (list.isLoading && items.isEmpty)
                  const _ListSkeleton()
                else if (list.hasError && items.isEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.section),
                    child: GzEmptyState(
                      illustration: GzIllustrationName.noResult,
                      title: l.clientServicesListNoResultsTitle,
                      action: GzStateAction(
                        label: l.commonActionRetry,
                        variant: GzButtonVariant.primary,
                        onPressed: () => ref.invalidate(servicesFilteredProvider(ServQuery(catId, filter))),
                      ),
                    ),
                  )
                else if (filteredEmpty && !filter.isDefault)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.section),
                    child: GzEmptyState(
                      illustration: GzIllustrationName.noResult,
                      title: l.clientServicesListNoResultsTitle,
                      action: GzStateAction(
                        label: l.clientServicesListClear,
                        variant: GzButtonVariant.secondary,
                        onPressed: () => ref.read(servicesFilterProvider(catId).notifier).clear(),
                      ),
                    ),
                  )
                else if (filteredEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.section),
                    child: GzEmptyState(
                      illustration: GzIllustrationName.emptyResults,
                      title: l.clientServicesListEmptyTitle,
                      action: siblings.length > 1
                          ? GzStateAction(
                              label: context.bi(siblings.where((s) => s.id.value != catId).firstOrNull?.name ?? siblings.first.name),
                              variant: GzButtonVariant.secondary,
                              onPressed: () => setState(() => _catId = siblings.where((s) => s.id.value != catId).firstOrNull?.id.value ?? catId),
                            )
                          : null,
                    ),
                  )
                else
                  Padding(
                    // 16 under the switch, then the grid's own 8; rows 24 apart, tiles 16 apart (web `gzs-list`).
                    padding: const EdgeInsetsDirectional.only(
                      top: GzSpace.s4 + GzSpace.s2,
                      start: GzSpace.gutter,
                      end: GzSpace.gutter,
                      bottom: GzSpace.section,
                    ),
                    child: Semantics(
                      container: true,
                      label: l.clientServicesListGridLabel(title),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < items.length; i += 2)
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : GzSpace.listGap),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ServVendorTile(vendor: items[i], guest: guest, catId: catId),
                                    ),
                                    const SizedBox(width: GzSpace.s4),
                                    Expanded(
                                      child: i + 1 < items.length
                                          ? ServVendorTile(vendor: items[i + 1], guest: guest, catId: catId)
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openFilters(BuildContext context, WidgetRef ref, String catId) {
    final l = context.l10n;
    ref.read(_sheetDraftProvider.notifier).update((_) => ref.read(servicesFilterProvider(catId)));
    context.gzNav.openSheetBuilder(
      (_) => _FilterSheet(catId: catId),
      options: GzSheetOptions(title: l.clientServicesFilterTitle),
    );
  }
}

/// Two rows of plates standing in for the grid.
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: GzSpace.s4),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Row(
          children: [
            Expanded(child: GzSkeleton(blockSize: 320)),
            SizedBox(width: GzSpace.s3),
            Expanded(child: GzSkeleton(blockSize: 320)),
          ],
        ),
      ),
      SizedBox(height: GzSpace.s3),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Row(
          children: [
            Expanded(child: GzSkeleton(blockSize: 320)),
            SizedBox(width: GzSpace.s3),
            Expanded(child: GzSkeleton(blockSize: 320)),
          ],
        ),
      ),
    ],
  );
}

/// The filter sheet: sort, areas, up-to prices and the minimum rating. A chosen chip is chosen again to clear it.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.catId});

  final String catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final draft = ref.watch(_sheetDraftProvider);
    final list = ref.watch(servicesFilteredProvider(ServQuery(catId, const ServFilter())));
    final items = list.value ?? const <ServiceProvider>[];
    final areas = ref.watch(servicesAreasProvider).value;
    final areaIds = {for (final v in items) v.areaId}.toList();
    final ceilings = {for (final v in items) v.from.fils}.toList()..sort();
    final current = ref.watch(servicesFilterProvider(catId));

    void apply(ServFilter v) => ref.read(servicesFilterProvider(catId).notifier).set(v);

    return Column(
      key: const ValueKey<String>('services.filters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientServicesFilterTitle, onClose: () => context.gzNav.closeSheet()),
        ),
        const SizedBox(height: GzSpace.s3),
        GzSegmentedControl<ProviderSort>(
          label: l.clientServicesSheetSortLabel,
          value: draft.sort,
          onChanged: (v) => ref.read(_sheetDraftProvider.notifier).update((d) => d.copyWith(sort: v)),
          options: [
            GzSegmentedOption(value: ProviderSort.recommended, label: l.clientServicesSortRecommended),
            GzSegmentedOption(value: ProviderSort.price, label: l.clientServicesSortPrice),
            GzSegmentedOption(value: ProviderSort.rating, label: l.clientServicesSortRating),
          ],
        ),
        if (areaIds.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s4),
          GzChipGroup<String>(
            label: l.clientServicesArea,
            options: [
              for (final id in areaIds)
                GzChipOption<String>(
                  value: id,
                  label: context.bi(areas?.areas.where((a) => a.id == id).firstOrNull?.name ?? LocalizedText(en: id, ar: id)),
                ),
            ],
            value: draft.areaIds.isEmpty ? null : draft.areaIds.first,
            onChanged: (v) => ref
                .read(_sheetDraftProvider.notifier)
                .update((d) => d.copyWith(areaIds: v == null || d.areaIds.contains(v) ? const <String>[] : <String>[v])),
          ),
        ],
        if (ceilings.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s4),
          GzChipGroup<int>(
            label: l.clientServicesFrom,
            options: [
              for (final c in ceilings)
                GzChipOption<int>(
                  value: c,
                  label: f.money(c),
                  labelWidget: GzNum(f.money(c), role: GzTextRole.figBodyS),
                  semanticLabel: l.clientServicesSheetUpTo(f.money(c)),
                ),
            ],
            value: draft.maxFils,
            onChanged: (v) => ref.read(_sheetDraftProvider.notifier).update((d) => d.copyWith(maxFils: v == d.maxFils ? null : v)),
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        GzChipGroup<double>(
          label: l.clientServicesFilterLabel,
          options: [
            for (final r in [4.5, 4.0])
              GzChipOption<double>(
                value: r,
                label: f.plain(f.number(r, const DecimalOptions(minFraction: 1, maxFraction: 1))),
                labelWidget: GzNum(f.plain(f.number(r, const DecimalOptions(minFraction: 1, maxFraction: 1))), role: GzTextRole.figBodyS),
                semanticLabel: l.clientServicesSheetRatingAtLeast(f.integer(r.round())),
              ),
          ],
          value: draft.minRating,
          onChanged: (v) => ref.read(_sheetDraftProvider.notifier).update((d) => d.copyWith(minRating: v == d.minRating ? null : v)),
        ),
        if (items.any((v) => v.femaleTeamForLadies)) ...[
          const SizedBox(height: GzSpace.s4),
          GzChip(
            label: l.clientServicesListFemaleTeam,
            iconStart: GzIcons.sectionWomen,
            selected: draft.femaleTeamOnly,
            onPressed: () => ref.read(_sheetDraftProvider.notifier).update((d) => d.copyWith(femaleTeamOnly: !d.femaleTeamOnly)),
          ),
        ],
        const SizedBox(height: GzSpace.s5),
        Row(
          children: [
            if (!current.isDefault) ...[
              Expanded(
                child: GzButton(
                  label: l.clientServicesListClear,
                  variant: GzButtonVariant.secondary,
                  onPressed: () => ref.read(servicesFilterProvider(catId).notifier).clear(),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
            ],
            Expanded(
              child: GzButton(
                label: l.clientServicesSheetShow(f.integer(items.length)),
                onPressed: () {
                  apply(draft);
                  context.gzNav.closeSheet();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
      ],
    );
  }
}

/// The sheet draft: the committed filters, edited freely until Show.
final _sheetDraftProvider = NotifierProvider.autoDispose<_SheetDraftNotifier, ServFilter>(_SheetDraftNotifier.new);

class _SheetDraftNotifier extends Notifier<ServFilter> {
  @override
  ServFilter build() => const ServFilter();

  void update(ServFilter Function(ServFilter) f) => state = f(state);
}

// Edges (inventory navigatesTo): 'CL-SERV-03' (a card opens the profile), 'CL-SERV-01' (back returns to the hub).
