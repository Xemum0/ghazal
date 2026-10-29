import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/discover_chips.dart';
import '../application/discover_filters.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart';
import 'widgets/brief_rows.dart';
import 'widgets/discover_failure.dart';
import 'widgets/discover_venue_card.dart';
import 'widgets/home_shelves.dart' show DriveFacts;
import 'widgets/map_canvas.dart';
import 'widgets/rail.dart';
import 'widgets/results_chips.dart';

/// CL-DISC-05 Map. Covers CA-SRCH-01, CA-SRCH-02, CA-HOME-14.
///
/// The full-screen alternative to the list, and the only live map in browse. Price-label pins for the Brief date (the selected pin fills
/// ink), clusters with a count that zoom in on tap, a bottom carousel of cards (72% wide, the next one peeking) that follows the selected
/// pin, and "My location" asked in context (a refusal falls back to the Brief's area). The Brief pill, the Filters count and the List | Map
/// switch stay on top. Dragging offers "Search here". There are no map tiles in the prototype or the mock: the canvas is a brand-toned
/// schematic drawn from the venues' coordinates (the real map comes with the platform map SDK at the end of F4). States: default, loading,
/// location-denied, no-results-in-view, offline, error.
class ClDisc05Screen extends ConsumerStatefulWidget {
  const ClDisc05Screen({super.key});

  @override
  ConsumerState<ClDisc05Screen> createState() => _ClDisc05ScreenState();
}

class _ClDisc05ScreenState extends ConsumerState<ClDisc05Screen> {
  final ScrollController _carousel = ScrollController();
  String? _selected;
  bool _zoomed = false;
  bool _moved = false;
  bool _here = false;
  bool _denied = false;

  static const double _gap = GzSpace.s3;

  GzNavigator get _nav => context.gzNav;

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  void _select(String id, List<VenueResult> rows, double w) {
    setState(() => _selected = id);
    final i = rows.indexWhere((r) => r.venue.id == id);
    if (i >= 0 && _carousel.hasClients) {
      _carousel.animateTo(i * (w + _gap), duration: GzReducedMotion.movement(context, GzMotion.durationSlow), curve: GzMotion.easeStandard);
    }
  }

  bool _onScroll(ScrollNotification n, List<VenueResult> rows, double w) {
    if (n.metrics.axis != Axis.horizontal || rows.isEmpty) return false;
    final i = (n.metrics.pixels.abs() / (w + _gap)).round().clamp(0, rows.length - 1);
    final id = rows[i].venue.id;
    if (id != _selected) setState(() => _selected = id);
    return false;
  }

  Future<void> _locate() async {
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
    if (r == GzDialogResult.confirm) {
      setState(() {
        _here = true;
        _denied = false;
      });
      _nav.toast(GzToastSpec(message: l.clientDiscoverMapLocated, tone: GzToastTone.success));
    } else {
      setState(() => _denied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final mq = MediaQuery.of(context);
    final brief = ref.watch(searchBriefProvider);
    final ds = ref.watch(discoverStateProvider);
    final filters = ds.effective(brief);
    final q = DiscoverQuery(brief: brief, filters: filters, sort: ds.sort, query: ds.seeded ? ds.query : '');
    final rowsAsync = ref.watch(discoverSearchProvider(q));
    final governorates = ref.watch(areasProvider).value?.governorates ?? const [];
    final loading = rowsAsync.isLoading && !rowsAsync.hasValue && !rowsAsync.hasError;
    final errored = rowsAsync.hasError && !rowsAsync.hasValue;
    final offline = errored && isOfflineError(rowsAsync.error);
    final rows = rowsAsync.value ?? const <VenueResult>[];
    final blocked = errored;
    final w = railItemWidth(mq.size.width);
    final sel = rows.where((r) => r.venue.id == _selected).firstOrNull ?? rows.firstOrNull;

    final date = brief.date == null ? null : '${f.integer(brief.date!.day)} ${f.monthName(brief.date!.month, short: true)}';
    final areaNames = briefGovernorateNames(governorates, brief.governorateIds, lang);
    final areaPill = areaNames.length > 1
        ? l.clientDiscoverBriefGovernorateMore(areaNames.first, f.integer(areaNames.length - 1))
        : (areaNames.firstOrNull ?? '');
    final spoken = <String>[
      ?date,
      if (brief.guests != null) f.integer(brief.guests!),
      if (areaNames.isNotEmpty) areaNames.join(f.isArabic ? '، ' : ', '),
    ].join(', ');
    final defaults = clearedFilters(brief);
    final count = filters.activeCount(brief) - (defaults.available && filters.available ? 1 : 0);

    final top = Padding(
      padding: EdgeInsetsDirectional.only(top: mq.padding.top, start: GzSpace.s2, end: GzSpace.s2, bottom: GzSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GzBarButton(
                key: const ValueKey<String>('discover.map.back'),
                icon: GzIcons.back,
                label: context.gzL10n.commonActionBack,
                tone: GzBarButtonTone.disk,
                onPressed: _nav.pop,
              ),
              const SizedBox(width: GzSpace.s1),
              Expanded(
                child: GzPressable(
                  key: const ValueKey<String>('discover.map.pill'),
                  onPressed: () => _nav.openSheet('CL-DISC-02'),
                  semanticLabel: '${l.clientDiscoverResultsBriefHint}: $spoken',
                  borderRadius: GzRadius.pillAll,
                  builder: (context, st) => Container(
                    constraints: const BoxConstraints(minHeight: GzSize.controlMd),
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
                    decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll, boxShadow: GzElevation.e2),
                    child: GzFactRow(
                      scroll: true,
                      children: [
                        GzFactChip(
                          icon: GzIcons.calendar,
                          label: l.clientDiscoverA11yDate,
                          value: date ?? l.clientDiscoverBriefChooseDate,
                          tone: date == null ? GzFactTone.muted : GzFactTone.normal,
                        ),
                        if (brief.guests != null)
                          GzFactChip(icon: GzIcons.usersThree, label: l.clientDiscoverBriefAddGuests, value: f.integer(brief.guests!)),
                        if (areaNames.isNotEmpty) GzFactChip(icon: GzIcons.pin, label: l.clientDiscoverBriefChooseGovernorate, value: areaPill),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s2),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlyphChip(
                  key: const ValueKey<String>('discover.map.filters'),
                  icon: GzIcons.sliders,
                  label: l.clientDiscoverResultsFilters,
                  count: count,
                  elevated: true,
                  onPressed: () => _nav.openSheet('CL-DISC-04'),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(borderRadius: GzRadius.mdAll, boxShadow: GzElevation.e2),
                  // two glyph options, each a 44 target, in the 4 dp track
                  child: SizedBox(
                    width: 2 * GzSize.touchMin + 2 * GzSpace.s1,
                    child: GzIconSegmented<String>(
                      label: l.clientDiscoverMapViewLabel,
                      labels: GzIconSegmentedLabels.none,
                      value: 'map',
                      onChanged: (v) {
                        if (v == 'list') _nav.pop();
                      },
                      options: [
                        GzIconSegmentedOption<String>(value: 'list', icon: GzIcons.list, label: l.clientDiscoverResultsList),
                        GzIconSegmentedOption<String>(value: 'map', icon: GzIcons.map, label: l.clientDiscoverResultsMap),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_moved)
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                child: GzButton(
                  key: const ValueKey<String>('discover.map.searcharea'),
                  label: l.clientDiscoverMapSearchArea,
                  variant: GzButtonVariant.secondary,
                  iconStart: GzIcons.search,
                  onPressed: () {
                    setState(() => _moved = false);
                    _nav.toast(GzToastSpec(message: l.clientDiscoverRefreshed, tone: GzToastTone.success));
                  },
                ),
              ),
            )
          else if (_denied)
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s1),
                  decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll, boxShadow: GzElevation.e2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzIcon(GzIcons.pin, size: GzIconSize.xs, color: c.iconSecondary),
                      const SizedBox(width: GzSpace.s2),
                      GzText(l.clientDiscoverMapDenied(briefGovernorateNames(governorates, brief.governorateIds.isEmpty ? const <String>['hawalli'] : brief.governorateIds, lang).firstOrNull ?? ''), role: GzTextRole.caption, color: c.textPrimary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget cardBox(Widget child) => Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, boxShadow: GzElevation.e2),
      child: child,
    );
    final Widget bottomBody;
    if (loading) {
      bottomBody = Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            key: const ValueKey<String>('discover.map.loading'),
            width: w,
            padding: const EdgeInsetsDirectional.all(GzSpace.s3),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: GzRadius.mdAll,
              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
              boxShadow: GzElevation.e2,
            ),
            child: Row(
              children: [
                const GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 72, blockSize: 88),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzSkeleton(inlineSize: w - 140, blockSize: 24),
                      const SizedBox(height: GzSpace.s2),
                      GzSkeleton(inlineSize: w - 190, blockSize: 16),
                      const SizedBox(height: GzSpace.s2),
                      GzSkeleton(inlineSize: w - 160, blockSize: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (!blocked && rows.isEmpty) {
      bottomBody = cardBox(
        GzEmptyState(
          key: const ValueKey<String>('discover.map.empty'),
          illustration: GzIllustrationName.noResult,
          title: context.gzL10n.commonStateTitleEmpty,
          fill: false,
          action: GzStateAction(
            label: l.clientDiscoverMapNoneAction,
            variant: GzButtonVariant.secondary,
            onPressed: () => ref.read(discoverStateProvider.notifier).replaceFilters(clearedFilters(brief)),
          ),
        ),
      );
    } else if (!blocked) {
      bottomBody = NotificationListener<ScrollNotification>(
        onNotification: (n) => _onScroll(n, rows, w),
        child: Semantics(
          container: true,
          label: l.clientDiscoverMapTitle,
          child: SingleChildScrollView(
            controller: _carousel,
            scrollDirection: Axis.horizontal,
            physics: RailSnapPhysics(extent: w + _gap),
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Container(
                    key: ValueKey<String>('discover.map.card.${rows[i].venue.id}'),
                    width: w,
                    padding: const EdgeInsetsDirectional.all(GzSpace.s3),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: GzRadius.mdAll,
                      border: Border.all(color: rows[i].venue.id == sel?.venue.id ? c.textStrong : c.borderStrong, width: GzStroke.hair),
                      boxShadow: GzElevation.e2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DiscoverVenueCard(row: rows[i], variant: GzVenueCardVariant.compact),
                        if (rows[i].distance != null) ...[
                          const SizedBox(height: GzSpace.s2),
                          DriveFacts(minutes: rows[i].distance!.minutes, km: rows[i].distance!.km),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      bottomBody = const SizedBox.shrink();
    }

    return GzScreen(
      fixed: true,
      child: Stack(
        key: const ValueKey<String>('discover.map.screen'),
        children: [
          Positioned.fill(
            child: MapCanvas(
              rows: rows.isEmpty ? const <VenueResult>[] : rows,
              selectedId: sel?.venue.id,
              onSelect: (id) => _select(id, rows, w),
              here: _here,
              zoomed: _zoomed,
              onZoomedChange: (z) => setState(() => _zoomed = z),
              onMoved: () => setState(() => _moved = true),
              empty: loading || blocked || rows.isEmpty,
            ),
          ),
          PositionedDirectional(start: 0, end: 0, top: 0, child: top),
          if (offline)
            PositionedDirectional(
              start: 0,
              end: 0,
              top: mq.size.height * 0.4,
              child: cardBox(
                GzEmptyState(
                  illustration: GzIllustrationName.wifiOff,
                  title: context.gzL10n.commonStateTitleNetwork,
                  detail: l.clientDiscoverResultsOfflineMap,
                  fill: false,
                  action: GzStateAction(
                    label: l.clientDiscoverMapOfflineAction,
                    variant: GzButtonVariant.secondary,
                    iconStart: GzIcons.list,
                    onPressed: _nav.pop,
                  ),
                ),
              ),
            ),
          if (errored && !offline)
            PositionedDirectional(
              start: 0,
              end: 0,
              top: mq.size.height * 0.4,
              child: cardBox(
                DiscoverFailure(
                  error: rowsAsync.error!,
                  onRetry: () => ref.invalidate(discoverSearchProvider(q)),
                  secondary: GzStateAction(label: l.clientDiscoverMapOfflineAction, iconStart: GzIcons.list, onPressed: _nav.pop),
                ),
              ),
            ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: mq.padding.bottom + GzSpace.s3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!blocked)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: GzIconButton(
                          key: const ValueKey<String>('discover.map.locate'),
                          icon: GzIcons.navigate,
                          label: l.clientDiscoverMapLocate,
                          variant: GzIconButtonVariant.overImage,
                          disk: GzIconButtonDisk.lg,
                          onPressed: _locate,
                        ),
                      ),
                    ),
                  if (!blocked) const SizedBox(height: GzSpace.s3),
                  bottomBody,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
