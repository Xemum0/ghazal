import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show RegionMatchKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/discover_filters.dart';
import '../application/discover_home.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart';
import 'widgets/brief_rows.dart' show briefAreaNames;
import 'widgets/discover_failure.dart';
import 'widgets/region_list.dart';

/// The drive-time bound "Near me" applies (the Filters sheet offers 15, 30 and 45).
const int kNearMinutes = 30;

/// CL-DISC-07 Search by region. Covers CA-FLT-01, CA-SRCH-03, CA-SRCH-02, CA-FLT-07, CA-HOME-03.
///
/// Region, governorate and location search: a typeahead over governorates, areas and venue names (Arabic-normalised by the server) above the
/// six governorates as expandable groups, each with its areas, venue counts and multi-select checkboxes (a governorate selects all of its
/// areas). "Near me" asks for the location in context and filters by drive time; a refusal falls back to the preferred area. The primary
/// "Show N halls" writes the selection to the Brief's areas and to the Results filter. States: default, typing, no-match, location-denied,
/// loading, offline, error.
class ClDisc07Screen extends ConsumerStatefulWidget {
  const ClDisc07Screen({super.key});

  @override
  ConsumerState<ClDisc07Screen> createState() => _ClDisc07ScreenState();
}

class _ClDisc07ScreenState extends ConsumerState<ClDisc07Screen> {
  List<String> _selected = const <String>[];
  String _query = '';
  bool _near = false;
  bool _denied = false;
  bool _init = false;
  bool _touched = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _selected = _initial(ref.read(searchBriefProvider));
  }

  List<String> _initial(SearchBrief brief) {
    final st = ref.read(discoverStateProvider);
    final filters = st.seeded ? st.filters : null;
    if (filters?.areaIds != null) return filters!.areaIds!;
    return brief.areaIds;
  }

  void _setSelected(List<String> next) => setState(() {
    _touched = true;
    _selected = next;
  });

  void _apply() {
    ref.read(searchBriefProvider.notifier).update((b) => b.copyWith(areaIds: _selected));
    final st = ref.read(discoverStateProvider);
    final base = st.effective(ref.read(searchBriefProvider));
    ref
        .read(discoverStateProvider.notifier)
        .replaceFilters(
          base.copyWith(clearAreaIds: true, governorateIds: const <String>[], withinMinutes: _near ? kNearMinutes : null, clearWithin: !_near),
        );
    _nav.pop();
  }

  Future<void> _askLocation() async {
    if (_near) return setState(() => _near = false);
    final l = context.l10n;
    final r = await _nav.openDialog(
      GzDialogSpec(
        title: l.clientDiscoverLocateDialogTitle,
        icon: GzIcons.pin,
        confirmLabel: l.clientDiscoverLocateAllow,
        cancelLabel: l.clientDiscoverLocateNotNow,
      ),
    );
    if (!mounted) return;
    setState(() {
      _near = r == GzDialogResult.confirm;
      _denied = r != GzDialogResult.confirm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final brief = ref.watch(searchBriefProvider);
    ref.listen<SearchBrief>(searchBriefProvider, (_, next) {
      if (!_touched && mounted) setState(() => _selected = _initial(next));
    });
    final groupsAsync = ref.watch(regionGroupsProvider);
    final areas = ref.watch(areasProvider).value?.areas ?? const [];
    final loading = groupsAsync.isLoading && !groupsAsync.hasValue && !groupsAsync.hasError;
    final errored = groupsAsync.hasError && !groupsAsync.hasValue;
    final offline = errored && isOfflineError(groupsAsync.error);
    final groups = groupsAsync.value ?? const [];
    final typing = _query.trim().isNotEmpty;
    final countAsync = ref.watch(
      discoverSearchProvider(
        DiscoverQuery(
          brief: brief.copyWith(areaIds: _selected),
          filters: DiscoverFilters(areaIds: _selected, available: brief.date != null),
        ),
      ),
    );
    final cta = loading || offline || errored || !countAsync.hasValue
        ? l.clientDiscoverCtaShow
        : f.digits(l.clientDiscoverCtaCount(countAsync.value!.length));
    final preferred = briefAreaNames(areas, brief.areaIds.isEmpty ? const <String>['salmiya'] : brief.areaIds, lang).firstOrNull ?? '';
    final pendingTarget = ref.watch(homeFeedProvider(brief)).value?.statusCard.target?.name.of(lang);
    final recents = <String>[...briefAreaNames(areas, brief.areaIds, lang), ?pendingTarget];

    Widget body;
    if (errored && !offline) {
      body = DiscoverFailure(error: groupsAsync.error!, onRetry: () => ref.invalidate(regionGroupsProvider));
    } else if (typing) {
      final matches = ref.watch(regionSearchProvider(_query));
      body = matches.when(
        loading: () => const SizedBox(height: GzSpace.s16),
        error: (e, _) => DiscoverFailure(error: e, onRetry: () => ref.invalidate(regionSearchProvider(_query))),
        data: (items) {
          if (items.isEmpty) {
            return GzEmptyState(
              illustration: GzIllustrationName.noResult,
              title: context.gzL10n.commonStateTitleEmptySearch,
              fill: false,
              action: GzStateAction(
                label: l.clientDiscoverResultsClearAll,
                variant: GzButtonVariant.secondary,
                iconStart: GzIcons.close,
                onPressed: () => setState(() => _query = ''),
              ),
            );
          }
          return Column(
            key: const ValueKey<String>('discover.region.matches'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final m in items)
                () {
                  final ids = m.kind == RegionMatchKind.governorate
                      ? <String>[
                          for (final g in groups)
                            if (g.governorate.id == m.id) ...g.areas.map((a) => a.area.id),
                        ]
                      : <String>[m.id];
                  final on = m.kind == RegionMatchKind.area && _selected.contains(m.id);
                  return GzPressable(
                    key: ValueKey<String>('discover.match.${m.kind.value}.${m.id}'),
                    onPressed: () {
                      if (m.kind == RegionMatchKind.venue) {
                        _nav.push('CL-VENU-01', params: <String, Object?>{'venueId': m.id, 'from': 'discover'});
                        return;
                      }
                      final all = ids.isNotEmpty && ids.every(_selected.contains);
                      _setSelected(
                        all
                            ? <String>[
                                for (final x in _selected)
                                  if (!ids.contains(x)) x,
                              ]
                            : <String>{..._selected, ...ids}.toList(),
                      );
                      setState(() => _query = '');
                    },
                    semanticLabel: m.name.of(lang),
                    builder: (context, st) => Container(
                      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
                      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
                      child: Row(
                        children: [
                          GzIcon(m.kind == RegionMatchKind.venue ? GzIcons.hall : GzIcons.pin, size: GzIconSize.sm, color: c.iconSecondary),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(
                            child: GzText(m.name.of(lang), role: GzTextRole.body, color: c.textPrimary),
                          ),
                          if (m.kind != RegionMatchKind.venue)
                            GzFactChip(
                              icon: GzIcons.hall,
                              label: l.clientDiscoverResultsTitle,
                              value: f.integer(m.venueCount),
                              tone: GzFactTone.muted,
                            ),
                          if (on) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary)],
                        ],
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      );
    } else {
      body = Column(
        key: const ValueKey<String>('discover.region.default'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzPressable(
            key: const ValueKey<String>('discover.region.near'),
            onPressed: _askLocation,
            semanticLabel: l.clientDiscoverRegionNear,
            borderRadius: GzRadius.mdAll,
            builder: (context, st) => Container(
              constraints: const BoxConstraints(minHeight: GzSize.briefRow),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.panelPad, vertical: GzSpace.s2),
              decoration: BoxDecoration(
                color: st.pressed ? c.surfaceQuiet : c.surfaceRaised,
                borderRadius: GzRadius.mdAll,
                border: Border.all(color: c.borderStrong, width: GzStroke.hair),
              ),
              child: Row(
                children: [
                  GzIcon(GzIcons.navigate, size: GzIconSize.sm, color: c.iconPrimary),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(l.clientDiscoverRegionNear, role: GzTextRole.body, color: c.textPrimary),
                  ),
                  if (_near) GzFactChip(icon: GzIcons.car, label: l.clientDiscoverA11yDrive, value: l.clientDiscoverMinutes(f.integer(kNearMinutes))),
                  if (_near) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary)],
                ],
              ),
            ),
          ),
          if (_denied)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: Row(
                children: [
                  GzIcon(GzIcons.pin, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  Expanded(
                    child: GzText(l.clientDiscoverMapDenied(preferred), role: GzTextRole.caption, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          if (!loading && recents.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s5),
            Semantics(
              container: true,
              label: l.clientDiscoverSearchRecent,
              child: Wrap(
                spacing: GzSpace.s2,
                runSpacing: GzSpace.s2,
                children: [
                  for (final r in recents)
                    GzChip(
                      key: ValueKey<String>('discover.recent.$r'),
                      label: r,
                      iconStart: GzIcons.clock,
                      onPressed: () => setState(() => _query = r),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: GzSpace.s5),
          if (loading)
            Semantics(
              container: true,
              label: context.gzL10n.commonStateLoading,
              child: ExcludeSemantics(
                child: Column(
                  key: const ValueKey<String>('discover.region.loading'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(height: GzSpace.s2),
                      GzSkeleton(inlineSize: i.isOdd ? 180 : 140, blockSize: 24),
                    ],
                  ],
                ),
              ),
            )
          else
            RegionList(
              key: ValueKey<int>(groups.length),
              groups: groups,
              selected: _selected,
              onChange: _setSelected,
              defaultOpen: <String>[
                for (final g in groups)
                  if (g.areas.any((a) => _selected.contains(a.area.id))) g.governorate.id,
              ],
            ),
        ],
      );
    }

    return GzScreen(
      top: Padding(
        padding: const EdgeInsetsDirectional.only(end: GzTopBar.barPad),
        child: GzTopBar(
          variant: GzTopBarVariant.search,
          search: GzTopBarSearch(placeholder: l.clientDiscoverRegionPlaceholder, value: _query, onChanged: (v) => setState(() => _query = v)),
        ),
      ),
      bottom: GzActionBar(
        action: GzActionBarAction(label: cta, onPressed: _apply, disabled: errored || loading),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8, start: GzSpace.gutter, end: GzSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
                child: GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
              ),
            body,
          ],
        ),
      ),
    );
  }
}
