import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/discover_filters.dart';
import '../application/discover_home.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart';
import 'widgets/discover_failure.dart';
import 'widgets/home_shelves.dart' show shelfDayLabel;

/// The longest range the date filter takes (a short run of wedding nights).
const int kDateRangeMaxDays = 7;

/// CL-DISC-06 Dates for your search (sheet). Covers CA-FLT-05, CA-SRCH-14, CA-HOME-02, CA-FLT-07.
///
/// A filterable availability calendar for search, not tied to one venue: pick a day, or drag out a short range (up to seven days), and
/// Results shows only the venues with a free hall on it. Sunday-first custom calendar, the Thursday to Saturday band at the inline-end
/// edge, month arrows that mirror, and a density mark on every day by shape and never by colour alone. "Not decided yet" and "Any month"
/// mirror the Brief sheet. The pinned footer states the live count; applying writes the Brief date and the Results filter, "Clear" resets.
/// A day with no free hall offers the nearest dates that have one. States: default, loading-density, range-selected, flexible-month,
/// no-venues-on-date, offline, error.
class ClDisc06Screen extends ConsumerStatefulWidget {
  const ClDisc06Screen({super.key});

  @override
  ConsumerState<ClDisc06Screen> createState() => _ClDisc06ScreenState();
}

class _ClDisc06ScreenState extends ConsumerState<ClDisc06Screen> {
  GzDateRange _range = GzDateRange.empty;
  GzYm _month = const GzYm(2026, 11);
  bool _months = false;
  LocalDate? _flex;
  bool _init = false;
  bool _touched = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _loadFromBrief(ref.read(searchBriefProvider), ref.read(discoverStateProvider));
  }

  /// The range the filter already holds, else the Brief's exact day.
  void _loadFromBrief(SearchBrief brief, DiscoverState ds) {
    final held = ds.seeded ? ds.filters.dates : null;
    if (held != null) {
      _range = GzDateRange(start: held.$1.toString(), end: held.$2.toString());
    } else if (brief.date != null && brief.dateMode == DateMode.exact) {
      _range = GzDateRange(start: brief.date.toString(), end: brief.date.toString());
    }
    final start = _range.start;
    final clock = ref.read(clockProvider)();
    _month = start != null ? GzYm(int.parse(start.substring(0, 4)), int.parse(start.substring(5, 7))) : GzYm(clock.year, clock.month);
  }

  void _pick(GzDateRange next) {
    _touched = true;
    var end = next.end;
    if (next.start != null && end != null) {
      final limit = LocalDate.parse(next.start!).addDays(kDateRangeMaxDays - 1).toString();
      if (limit.compareTo(end) < 0) end = limit;
    }
    setState(() {
      _flex = null;
      _range = GzDateRange(start: next.start, end: end);
    });
  }

  /// Hands the filter side of the choice to whoever opened the sheet: the Filters draft, or the Results filters themselves.
  void _hand(DatePatch patch) {
    if (_nav.params['target'] == 'filters') {
      ref.read(datePatchProvider.notifier).hand(patch);
      return;
    }
    final st = ref.read(discoverStateProvider);
    final base = st.effective(ref.read(searchBriefProvider));
    ref
        .read(discoverStateProvider.notifier)
        .replaceFilters(
          patch.dates != null ? base.copyWith(dates: patch.dates, available: false) : base.copyWith(clearDates: true, available: patch.available),
        );
  }

  void _apply(String? from, String? to) {
    final brief = ref.read(searchBriefProvider.notifier);
    if (_flex != null) {
      brief.update((b) => b.copyWith(date: _flex, dateMode: DateMode.flexibleMonth));
      _hand(const DatePatch());
    } else if (from != null && to != null) {
      final a = LocalDate.parse(from);
      final z = LocalDate.parse(to);
      brief.update((b) => b.copyWith(date: a, dateMode: DateMode.exact));
      _hand(from == to ? const DatePatch(available: true) : DatePatch(dates: (a, z)));
    }
    _nav.closeSheet();
  }

  void _clear() {
    setState(() {
      _touched = true;
      _range = GzDateRange.empty;
      _flex = null;
    });
    ref.read(searchBriefProvider.notifier).update((b) => b.copyWith(clearDate: true, dateMode: DateMode.undecided));
    _hand(const DatePatch());
  }

  void _undecided() => setState(() {
    _touched = true;
    _range = GzDateRange.empty;
    _flex = null;
    _months = false;
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final brief = ref.watch(searchBriefProvider);
    ref.listen<SearchBrief>(searchBriefProvider, (_, next) {
      if (!_touched && mounted) setState(() => _loadFromBrief(next, ref.read(discoverStateProvider)));
    });
    final today = f.isoDay(f.now());
    final maxDate = ref.watch(appConfigProvider).value?.availabilityWindow.to.toString();
    final from = _range.start;
    final to = _range.end ?? _range.start;
    final single = from != null && from == to;
    final key = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final density = ref.watch(dateDensityProvider((brief, key)));
    final loading = density.isLoading && !density.hasValue && !density.hasError;
    final errored = density.hasError && !density.hasValue;
    final offline = errored && isOfflineError(density.error);
    final days = <String, GzCalendarDayInfo>{
      for (final e in (density.value ?? const <String, ({int free, int of})>{}).entries)
        if (e.key.compareTo(today) >= 0)
          e.key: GzCalendarDayInfo(
            status: e.value.free == 0
                ? GzDayStatus.booked
                : (e.value.free >= (e.value.of / 2).ceil().clamp(2, 1 << 20) ? GzDayStatus.available : GzDayStatus.held),
          ),
    };
    // the live count for the day or the range, by the same search Results runs
    final countQuery = from == null
        ? null
        : DiscoverQuery(
            brief: single ? brief.copyWith(date: LocalDate.parse(from)) : brief,
            filters: single || to == null
                ? const DiscoverFilters(available: true)
                : DiscoverFilters(dates: (LocalDate.parse(from), LocalDate.parse(to))),
          );
    final countAsync = countQuery == null ? null : ref.watch(discoverSearchProvider(countQuery));
    final count = countAsync?.value?.length;
    final near = single && count == 0
        ? (ref.watch(homeFeedProvider(brief.copyWith(date: LocalDate.parse(from)))).value?.nearestFreeDates ?? const <LocalDate>[])
              .where((d) => d.toString() != from)
              .take(3)
              .toList()
        : const <LocalDate>[];
    String monthText(GzYm m) => f.date(f.kuwaitDate(m.year, m.month, 1), DateStyle.monthYear);
    final start = GzYm(int.parse(today.substring(0, 4)), int.parse(today.substring(5, 7)));
    final months = <GzYm>[for (var i = 0; i < 12; i++) GzYm(start.year + (start.month - 1 + i) ~/ 12, (start.month - 1 + i) % 12 + 1)];
    final flexYm = _flex == null ? null : GzYm(_flex!.year, _flex!.month);

    final cta = loading || offline || errored || from == null
        ? l.clientDiscoverDatesApply
        : count == 0
        ? l.clientDiscoverDatesNone
        : f.digits(l.clientDiscoverCtaCount(count ?? 0));

    final footer = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s3),
        GzButton(
          key: const ValueKey<String>('discover.dates.cta'),
          label: _flex != null ? l.clientDiscoverDatesApply : cta,
          fullWidth: true,
          loading: loading,
          onPressed: errored || (_flex == null && count == 0) ? null : () => _apply(from, to),
        ),
        const SizedBox(height: GzSpace.s2),
        Center(
          child: GzButton(
            key: const ValueKey<String>('discover.dates.clear'),
            label: l.clientDiscoverDatesClear,
            variant: GzButtonVariant.tertiary,
            onPressed: _clear,
          ),
        ),
      ],
    );

    return Column(
      key: const ValueKey<String>('discover.dates.sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GzSheetFill(),
        GzSheetPinnedHeader(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.controlMd),
              child: Row(
                children: [
                  Expanded(
                    child: GzText(l.clientDiscoverDatesTitle, role: GzTextRole.d1, color: c.textStrong, header: true),
                  ),
                  if (!_months && !loading && !offline && !errored)
                    GzIconButton(
                      key: const ValueKey<String>('discover.dates.info'),
                      icon: GzIcons.info,
                      label: context.gzL10n.commonCalendarAvailability,
                      onPressed: () => _nav.openSheetBuilder((ctx) => _Legend(title: context.gzL10n.commonCalendarAvailability, nav: _nav)),
                    ),
                  GzBarButton(
                    key: const ValueKey<String>('gz:sheet.close'),
                    icon: GzIcons.close,
                    label: context.gzL10n.commonActionClose,
                    onPressed: _nav.closeSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (offline)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
          ),
        if (errored && !offline)
          DiscoverFailure(error: density.error!, onRetry: () => ref.invalidate(dateDensityProvider((brief, key))))
        else ...[
          Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [
              GzChip(
                key: const ValueKey<String>('discover.dates.undecided'),
                label: context.gzL10n.commonLabelNotDecided,
                selected: !_months && from == null && _flex == null && !loading,
                onPressed: _undecided,
              ),
              GzChip(
                key: const ValueKey<String>('discover.dates.anymonth'),
                label: flexYm != null ? monthText(flexYm) : l.clientDiscoverDatesFlexible,
                iconStart: GzIcons.calendarDots,
                menu: true,
                selected: _months || _flex != null,
                onPressed: () => setState(() => _months = !_months),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          if (!_months) ...[
            GzCalendar.range(
              value: _range,
              onChanged: _pick,
              days: days,
              month: _month,
              onMonthChange: (m) => setState(() => _month = m),
              maxDate: maxDate,
              isSelectable: (iso, status) => status != GzDayStatus.closed && iso.compareTo(today) >= 0,
              summary: false,
              legend: false,
              label: l.clientDiscoverDatesTitle,
            ),
            if (near.isNotEmpty) ...[
              const SizedBox(height: GzSpace.s3),
              Semantics(
                container: true,
                label: l.clientDiscoverResultsNoneDates,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < near.length; i++) ...[
                        if (i > 0) const SizedBox(width: GzSpace.s2),
                        GzChip(
                          label: shelfDayLabel(context, near[i].toString()),
                          iconStart: GzIcons.calendar,
                          onPressed: () => _pick(GzDateRange(start: near[i].toString(), end: near[i].toString())),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ] else
            Wrap(
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s2,
              children: [
                for (final m in months)
                  GzChip(
                    key: ValueKey<String>('discover.dates.month.${m.year}-${m.month}'),
                    label: monthText(m),
                    selected: flexYm == m,
                    onPressed: () => setState(() {
                      _touched = true;
                      _flex = LocalDate(m.year, m.month, 1);
                      _range = GzDateRange.empty;
                    }),
                  ),
              ],
            ),
        ],
        GzSheetFooter(child: footer),
      ],
    );
  }
}

/// The legend and the limit, behind the info glyph: the same three marks the days carry (plain figure, bead, struck figure), one word each.
class _Legend extends StatelessWidget {
  const _Legend({required this.title, required this.nav});

  final String title;
  final GzNavigator nav;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    Widget sample(String kind, String word, int n) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
      child: Row(
        children: [
          SizedBox(
            width: GzSpace.s8,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kind == 'few') ...[
                    Transform.rotate(
                      angle: 0.785398,
                      child: Container(width: GzSize.knotBead, height: GzSize.knotBead, color: c.iconAccent),
                    ),
                    const SizedBox(width: GzSpace.s1),
                  ],
                  Text(
                    f.plain(f.integer(n)),
                    style: context.gz
                        .text(GzTextRole.calDay)
                        .copyWith(
                          color: kind == 'none' ? c.textSecondary : c.textStrong,
                          decoration: kind == 'none' ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s4),
          GzText(word, role: GzTextRole.body, color: c.textPrimary),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetHeader(title: title, onClose: nav.closeSheet),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sample('many', l.clientDiscoverDatesMany, 13),
              sample('few', l.clientDiscoverDatesFew, 14),
              sample('none', l.clientDiscoverDatesNoneLegend, 12),
              const SizedBox(height: GzSpace.s1),
              GzText(l.clientDiscoverDatesHint(kDateRangeMaxDays), role: GzTextRole.body, color: c.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}
