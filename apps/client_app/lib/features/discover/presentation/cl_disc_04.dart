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
import 'widgets/discover_failure.dart';
import 'widgets/discover_labels.dart';
import 'widgets/filter_bodies.dart';
import 'widgets/filter_group.dart';

/// CL-DISC-04 Filters (sheet). Covers CA-SRCH-02 to 14, 16, 18 to 20, CA-FLT-01 to 06.
///
/// One 90% sheet with every filter, grouped by what couples decide first: region, venue type, reception, capacity, pricing, date, voucher
/// price, standard price, setting, facilities, rating, level and hotel brand. Groups collapse to a glyph row; a group that holds a choice
/// shows it as one value line and a gold bead. The footer is pinned: Clear and the one gold CTA with the live count. Edits are a draft:
/// "Show N halls" applies them and returns to Results with removable chips; dismissing discards them. Sort lives in its own small sheet.
/// States: default, loading-count, zero-results, error, offline, group-collapsed.
class ClDisc04Screen extends ConsumerStatefulWidget {
  const ClDisc04Screen({super.key});

  @override
  ConsumerState<ClDisc04Screen> createState() => _ClDisc04ScreenState();
}

class _ClDisc04ScreenState extends ConsumerState<ClDisc04Screen> {
  late DiscoverFilters _draft;
  final Set<String> _open = <String>{'region'};
  bool _init = false;
  bool _touched = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _draft = ref.read(discoverStateProvider).effective(ref.read(searchBriefProvider));
  }

  void _patch(DiscoverFilters Function(DiscoverFilters d) change) => setState(() {
    _touched = true;
    _draft = change(_draft);
  });

  void _apply() {
    ref.read(discoverStateProvider.notifier).replaceFilters(_draft);
    _nav.closeSheet();
  }

  Future<void> _askLocation(int? minutes) async {
    if (minutes == null) return _patch((d) => d.copyWith(clearWithin: true));
    final l = context.l10n;
    final r = await _nav.openDialog(
      GzDialogSpec(
        title: l.clientDiscoverLocateDialogTitle,
        icon: GzIcons.pin,
        confirmLabel: l.clientDiscoverLocateAllow,
        cancelLabel: l.clientDiscoverLocateNotNow,
      ),
    );
    if (r == GzDialogResult.confirm && mounted) _patch((d) => d.copyWith(withinMinutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final brief = ref.watch(searchBriefProvider);
    // The couple's profile fills the Brief a moment after the sheet opens: until the person edits, the draft is what Results holds.
    ref.listen<SearchBrief>(searchBriefProvider, (_, next) {
      if (!_touched && mounted) setState(() => _draft = ref.read(discoverStateProvider).effective(next));
    });
    final areasResponse = ref.watch(areasProvider).value;
    final roster = ref.watch(venueRosterProvider).value ?? const <VenueResult>[];
    ref.listen<DatePatch?>(datePatchProvider, (_, next) {
      if (next == null) return;
      ref.read(datePatchProvider.notifier).take();
      _patch((d) => next.dates != null ? d.copyWith(dates: next.dates, available: false) : d.copyWith(clearDates: true, available: next.available));
    });
    final labels = DiscoverLabels(context, areas: areasResponse, brief: brief);
    final q = DiscoverQuery(brief: brief, filters: _draft);
    final rows = ref.watch(discoverSearchProvider(q));
    final loading = rows.isLoading && !rows.hasValue && !rows.hasError;
    final errored = rows.hasError && !rows.hasValue;
    final offline = errored && isOfflineError(rows.error);
    final count = rows.value?.length ?? 0;
    final zero = rows.hasValue && count == 0;
    final relaxId = zero ? ref.watch(relaxChipProvider(q)).value : null;
    final relax = relaxId == null ? null : chipSpecs(_draft, brief).where((x) => x.id == relaxId).firstOrNull;
    final defaults = DiscoverFilters.defaultsFor(brief);
    final changed = _draft.activeCount(brief) - (_draft.available && brief.date != null ? 1 : 0) > 0 || _draft.available != defaults.available;
    final cta = loading
        ? l.clientDiscoverCtaShow
        : zero
        ? l.clientDiscoverFiltersCtaNone
        : context.gzFormat.digits(l.clientDiscoverFiltersCta(count));
    final ctx = FilterCtx(
      draft: _draft,
      patch: _patch,
      brief: brief,
      labels: labels,
      governorates: areasResponse?.governorates ?? const [],
      roster: roster,
      askLocation: _askLocation,
      openDates: () => _nav.openSheet('CL-DISC-06', options: const GzSheetOptions(params: <String, Object?>{'target': 'filters'})),
    );

    final footer = Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (zero && relax != null) ...[
              Center(
                child: GzButton(
                  key: const ValueKey<String>('discover.filters.relax'),
                  label: l.clientDiscoverResultsNoneRelax(labels.chipLabel(relax)),
                  variant: GzButtonVariant.tertiary,
                  iconStart: labels.chipIcon(relax) ?? GzIcons.close,
                  onPressed: () => _patch(relax.remove),
                ),
              ),
              const SizedBox(height: GzSpace.s2),
            ],
            Row(
              children: [
                GzButton(
                  key: const ValueKey<String>('discover.filters.clear'),
                  label: l.clientDiscoverFiltersClear,
                  variant: GzButtonVariant.tertiary,
                  onPressed: changed
                      ? () => setState(() {
                          _touched = true;
                          _draft = clearedFilters(brief);
                        })
                      : null,
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(
                    key: const ValueKey<String>('discover.filters.cta'),
                    label: cta,
                    fullWidth: true,
                    loading: loading,
                    onPressed: zero || errored ? null : _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      key: const ValueKey<String>('discover.filters'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.controlMd),
          child: Row(
            children: [
              Expanded(
                child: GzText(l.clientDiscoverFiltersTitle, role: GzTextRole.d1, color: c.textStrong, header: true),
              ),
              const SizedBox(width: GzSpace.s3),
              GzBarButton(
                key: const ValueKey<String>('gz:sheet.close'),
                icon: GzIcons.close,
                label: context.gzL10n.commonActionClose,
                onPressed: _nav.closeSheet,
              ),
            ],
          ),
        ),
        if (offline)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
          ),
        if (errored && !offline)
          DiscoverFailure(error: rows.error!, onRetry: () => ref.invalidate(discoverSearchProvider(q)))
        else
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in kFilterGroups)
                  FilterGroup(
                    id: id,
                    title: context.gzFormat.digits(filterGroupTitle(l, id, regions: (_draft.governorateIds ?? brief.governorateIds).length)),
                    icon: filterGroupIcon(id),
                    summary: filterGroupSummary(context, id, _draft, brief, labels),
                    active: filterGroupActive(id, _draft, brief),
                    open: _open.contains(id),
                    onToggle: () => setState(() => _open.contains(id) ? _open.remove(id) : _open.add(id)),
                    child: filterGroupBody(context, id, ctx),
                  ),
              ],
            ),
          ),
        GzSheetFooter(child: footer),
      ],
    );
  }
}
