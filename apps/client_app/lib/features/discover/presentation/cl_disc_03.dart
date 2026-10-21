import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingChannel, DateMode, LocalDate, VenueDayState, VenueResult, VenueType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/discover_chips.dart';
import '../application/discover_filters.dart';
import '../application/discover_home.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart';
import 'widgets/compare_dock.dart';
import 'widgets/discover_failure.dart';
import 'widgets/discover_labels.dart';
import 'widgets/discover_venue_card.dart';
import 'widgets/results_chips.dart';
import 'widgets/results_misc.dart';
import 'widgets/results_parts.dart';
import 'widgets/sort_sheet.dart';

/// CL-DISC-03 Results. Covers CA-SRCH-01, 14, 16, 17, 20, 21, CA-HOME-06, 08, 16, CA-CARD-01..13, CA-TOOL-01, CA-CMP-01, CA-FLT-01..07, CA-VCH-02, 10.
///
/// The venue list for the Brief. Top: back and the name search (typeahead). Under it the Brief as its facts (one button that opens the Brief
/// sheet), one chip row (Filters with its count, Sort, Region, Date, every other applied filter removable, Clear), the count, then the cards
/// with the two prices of the voucher model: the voucher price as the headline and the standard price beneath (a guest sees a locked voucher
/// line); under a free hall the one action is "Get voucher" or "View". A booked hall offers its free dates; a governmental facility is
/// browse-only. Pull to refresh; the Compare tray and the Map pill float above the bar. States: default, loading, no-results, error,
/// offline, searching, guest.
class ClDisc03Screen extends ConsumerStatefulWidget {
  const ClDisc03Screen({super.key});

  @override
  ConsumerState<ClDisc03Screen> createState() => _ClDisc03ScreenState();
}

class _ClDisc03ScreenState extends ConsumerState<ClDisc03Screen> {
  final FocusNode _barScope = FocusNode(canRequestFocus: false, skipTraversal: true, debugLabel: 'results.bar');
  Map<String, Object?>? _params;
  bool _seeded = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _barScope.addListener(() {
      if (_focused != _barScope.hasFocus && mounted) setState(() => _focused = _barScope.hasFocus);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _params ??= context.gzNav.params;
  }

  @override
  void dispose() {
    _barScope.dispose();
    super.dispose();
  }

  GzNavigator get _nav => context.gzNav;

  DiscoverFilters _preset(SearchBrief brief) => discoverPresetFromParams(_params ?? const <String, Object?>{}, brief);

  /// The preset of this entry until it is stored (the first frame), then what the store holds.
  DiscoverFilters _filters(SearchBrief brief, DiscoverState ds) => _seeded ? ds.filters : _preset(brief);

  void _seed(SearchBrief brief) {
    if (_seeded) return;
    _seeded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(discoverStateProvider.notifier).seed(_preset(brief));
    });
  }

  void _setFilters(DiscoverFilters f) => ref.read(discoverStateProvider.notifier).replaceFilters(f);

  void _unfocus() => FocusScope.of(context).unfocus();

  Future<void> _refresh(DiscoverQuery q) async {
    ref.invalidate(discoverSearchProvider(q));
    try {
      await ref.read(discoverSearchProvider(q).future);
      if (mounted) _nav.toast(GzToastSpec(message: context.l10n.clientDiscoverResultsRefreshed, tone: GzToastTone.success));
    } on Object {
      // the list shows its own error state
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final brief = ref.watch(searchBriefProvider);
    _seed(brief);
    // The couple's profile fills the Brief a moment after the screen opens: a list opened with no preset follows the Brief's date from then on.
    ref.listen<SearchBrief>(searchBriefProvider, (prev, next) {
      final hasPreset = (_params ?? const <String, Object?>{}).keys.any(
        (k) => const <String>['shelf', 'category', 'available', 'areaIds'].contains(k),
      );
      if (hasPreset || prev == null || prev.date != null || next.date == null) return;
      final st = ref.read(discoverStateProvider);
      if (st.seeded && !st.filters.available) _setFilters(st.filters.copyWith(available: true));
    });
    final ds = ref.watch(discoverStateProvider);
    final filters = _filters(brief, ds);
    final query = _seeded ? ds.query : '';
    final q = DiscoverQuery(brief: brief, filters: filters, sort: ds.sort, query: query);
    final rows = ref.watch(discoverSearchProvider(q));
    final areasResponse = ref.watch(areasProvider).value;
    final areas = areasResponse?.areas ?? const [];
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final labels = DiscoverLabels(context, areas: areasResponse, brief: brief);
    final loading = rows.isLoading && !rows.hasValue && !rows.hasError;
    final failed = rows.hasError && !rows.hasValue;
    final offline = failed && isOfflineError(rows.error);
    final data = rows.value ?? const <VenueResult>[];
    final typing = _focused || query.isNotEmpty;

    final defaults = clearedFilters(brief);
    final chips = chipSpecs(filters, brief);
    final extra = chips.where((x) => !(x.id == 'available' && defaults.available)).toList();
    final count = filters.activeCount(brief) - (defaults.available && filters.available ? 1 : 0);
    const quick = <String>['governorates', 'areas', 'dates', 'available'];
    final removable = chips.where((x) => !quick.contains(x.id)).toList();
    final regionChip = chips.where((x) => x.id == 'governorates').firstOrNull ?? chips.where((x) => x.id == 'areas').firstOrNull;
    final dateChip = chips.where((x) => x.id == 'dates').firstOrNull ?? chips.where((x) => x.id == 'available').firstOrNull;
    final range = filters.dates;
    final dateText = range == null ? null : labels.dateRange(range);
    final showGovNote = filters.types.contains(VenueType.governmental) || filters.category?.value == 'government';

    Widget stateBlock(Widget child) => Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
      child: child,
    );

    final slivers = <Widget>[
      if (offline)
        SliverToBoxAdapter(
          child: GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline),
        ),
      if (typing)
        SliverToBoxAdapter(
          child: Typeahead(
            query: query,
            brief: brief,
            onPickArea: (id) {
              _setFilters(filters.copyWith(areaIds: <String>[id], governorateIds: const <String>[]));
              ref.read(discoverStateProvider.notifier).setQuery('');
              _unfocus();
            },
            onPickVenue: (id) {
              _unfocus();
              _nav.push('CL-VENU-01', params: <String, Object?>{'venueId': id, 'from': 'discover'});
            },
            onPickRecent: (text) => ref.read(discoverStateProvider.notifier).setQuery(text),
            onClearRecent: () => ref.read(discoverStateProvider.notifier).setQuery(''),
          ),
        )
      else ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s3, start: GzSpace.gutter, end: GzSpace.gutter),
            child: BriefFacts(brief: brief, areas: areas, onEdit: () => _nav.openSheet('CL-DISC-02')),
          ),
        ),
        SliverToBoxAdapter(
          child: AppliedChipsRow(
            chips: removable,
            labels: labels,
            filterCount: count,
            sortLabel: labels.sort(ds.sort),
            sortSet: ds.sort != DiscoverSort.recommended,
            onFilters: () => _nav.openSheet('CL-DISC-04'),
            onSort: () => _nav.openSheetBuilder((_) => const SortSheet()),
            regionLabel: regionChip == null ? null : labels.chipLabel(regionChip),
            regionActive: regionChip != null,
            onRegion: () => _nav.push('CL-DISC-07', params: const <String, Object?>{'from': 'results'}),
            dateLabel: dateText,
            dateActive: dateChip != null,
            onDate: () => _nav.openSheet('CL-DISC-06'),
            onRemove: (chip) => _setFilters(chip.remove(filters)),
            onClearAll: extra.isNotEmpty || (chips.isNotEmpty && !defaults.available) ? () => _setFilters(clearedFilters(brief)) : null,
          ),
        ),
        if (!signedIn && !loading && !failed && data.isNotEmpty)
          SliverToBoxAdapter(
            child: VoucherLockRow(onPressed: () => ref.requireSignIn(GateReason.voucher, resume: const GateResume('CL-DISC-03'))),
          ),
        if (failed)
          SliverToBoxAdapter(
            child: stateBlock(
              DiscoverFailure(error: rows.error!, onRetry: () => ref.invalidate(discoverSearchProvider(q)), retrying: rows.isLoading),
            ),
          )
        else ...[
          if (loading || data.isNotEmpty || offline)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s3, start: GzSpace.gutter, end: GzSpace.gutter),
                child: Row(
                  children: [
                    if (loading)
                      Semantics(
                        label: context.gzL10n.commonStateLoading,
                        child: const SizedBox(height: GzSpace.s6),
                      )
                    else
                      GzFactChip(icon: GzIcons.hall, label: l.clientDiscoverResultsTitle, value: f.integer(data.length)),
                    if (showGovNote && data.isNotEmpty) ...[
                      const SizedBox(width: GzSpace.s3),
                      GzInfoButton(
                        key: const ValueKey<String>('discover.info'),
                        title: context.gzL10n.commonVenueTypeGovernmental,
                        paragraphs: [l.clientDiscoverResultsGovernmentNote],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (loading)
            const SliverToBoxAdapter(child: ResultsSkeleton())
          else if (data.isEmpty && !offline)
            SliverToBoxAdapter(
              child: _NoResults(query: q, labels: labels, onFilters: _setFilters),
            )
          else
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              sliver: SliverList.separated(
                itemCount: data.length,
                separatorBuilder: (_, _) => const SizedBox(height: GzSpace.s6),
                itemBuilder: (context, i) => _ResultItem(row: data[i], brief: brief),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: GzSpace.s24)),
        ],
      ],
    ];

    final search = GzTopBarSearch(
      placeholder: l.clientDiscoverResultsSearchPlaceholder,
      value: query,
      onChanged: (v) => ref.read(discoverStateProvider.notifier).setQuery(v),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GzPullToRefresh(
            onRefresh: () => _refresh(q),
            child: GzScreen.slivers(
              top: Focus(
                focusNode: _barScope,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: GzTopBar.barPad),
                  child: GzTopBar(variant: GzTopBarVariant.search, search: search),
                ),
              ),
              slivers: slivers,
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: GzSpace.s4,
          child: ColoredBox(
            color: c.surfaceCanvas.withAlpha(0),
            child: CompareDock(
              extra: !typing && !loading && !failed && data.isNotEmpty
                  ? MapPill(onPressed: () => _nav.push('CL-DISC-05', params: const <String, Object?>{'from': 'results'}))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// One result: the card, its trailing action, and the free dates of a booked hall.
class _ResultItem extends ConsumerWidget {
  const _ResultItem({required this.row, required this.brief});

  final VenueResult row;
  final SearchBrief brief;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final booked = brief.date != null && row.availability == VenueDayState.unavailable && row.venue.channel != BookingChannel.externalLink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverVenueCard(row: row, variant: GzVenueCardVariant.list),
        const SizedBox(height: GzSpace.s1),
        DiscoverCardAction(row: row),
        if (booked)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(
              key: ValueKey<String>('discover.freedates.${row.venue.id}'),
              label: l.clientDiscoverResultsSeeFreeDates,
              variant: GzButtonVariant.tertiary,
              iconStart: GzIcons.calendar,
              onPressed: () => nav.openSheet('CL-VENU-03', options: GzSheetOptions(params: <String, Object?>{'venueId': row.venue.id})),
            ),
          ),
      ],
    );
  }
}

/// No results: one filter whose removal brings halls back, named; Clear; the nearest free dates when the Brief has a date.
class _NoResults extends ConsumerWidget {
  const _NoResults({required this.query, required this.labels, required this.onFilters});

  final DiscoverQuery query;
  final DiscoverLabels labels;
  final ValueChanged<DiscoverFilters> onFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final brief = query.brief;
    final relaxId = ref.watch(relaxChipProvider(query)).value;
    final chips = chipSpecs(query.filters, brief);
    final relax = relaxId == null ? null : chips.where((x) => x.id == relaxId).firstOrNull;
    final feed = brief.date == null ? null : ref.watch(homeFeedProvider(brief)).value;
    final near = <LocalDate>[
      for (final d in feed?.nearestFreeDates ?? const <LocalDate>[])
        if (d != brief.date) d,
    ];
    return Padding(
      key: const ValueKey<String>('discover.results.none'),
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: context.gzL10n.commonStateTitleEmptySearch,
            fill: false,
            action: relax == null
                ? null
                : GzStateAction(
                    label: l.clientDiscoverResultsNoneRelax(labels.chipLabel(relax)),
                    variant: GzButtonVariant.secondary,
                    iconStart: labels.chipIcon(relax) ?? GzIcons.close,
                    onPressed: () => onFilters(relax.remove(query.filters)),
                  ),
            secondary: GzStateAction(label: l.clientDiscoverResultsClearAll, onPressed: () => onFilters(clearedFilters(brief))),
          ),
          if (near.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
              child: Semantics(
                container: true,
                label: l.clientDiscoverResultsNoneDates,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  children: [
                    for (final d in near)
                      GzChip(
                        label: labels.day(d.toString()),
                        iconStart: GzIcons.calendar,
                        onPressed: () => ref.read(searchBriefProvider.notifier).update((b) => b.copyWith(date: d, dateMode: DateMode.exact)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
