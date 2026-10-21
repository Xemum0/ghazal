import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/brief_draft.dart';
import '../../application/discover_regions.dart';

typedef DraftSetter = void Function(BriefDraft Function(BriefDraft d) change);

/// The three views of the date question: the calendar, "Not decided", and "Any month" (twelve month chips).
enum DateView { calendar, undecided, months }

/// The date picker inside the Brief sheet: the system calendar (Sunday-first, Thursday to Saturday peak band, past days closed) with a
/// ruled strip once a day is picked (the date, the Hijri line in the Arabic UI only, the days left); "Not decided"; "Any month". A skipped
/// answer is not a choice: until someone taps "Not decided" the calendar stays in front.
class BriefDatePanel extends ConsumerStatefulWidget {
  const BriefDatePanel({required this.draft, required this.set, this.initialView, super.key});

  final BriefDraft draft;
  final DraftSetter set;
  final DateView? initialView;

  @override
  ConsumerState<BriefDatePanel> createState() => _BriefDatePanelState();
}

class _BriefDatePanelState extends ConsumerState<BriefDatePanel> {
  late GzYm _month;
  late DateView _view;

  @override
  void initState() {
    super.initState();
    final b = widget.draft.brief;
    _month = b.date == null ? _ymOf(ref.read(clockProvider)()) : GzYm(b.date!.year, b.date!.month);
    _view = widget.initialView ?? (b.dateMode == DateMode.flexibleMonth ? DateView.months : DateView.calendar);
  }

  static GzYm _ymOf(DateTime d) => GzYm(d.year, d.month);

  List<GzYm> _months(String today) {
    final start = GzYm(int.parse(today.substring(0, 4)), int.parse(today.substring(5, 7)));
    return <GzYm>[
      for (var i = 0; i < 12; i++) GzYm(start.year + (start.month - 1 + i) ~/ 12, (start.month - 1 + i) % 12 + 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final b = widget.draft.brief;
    final today = f.isoDay(f.now());
    final maxDate = ref.watch(appConfigProvider).value?.availabilityWindow.to.toString();
    String monthText(GzYm m) => f.date(f.kuwaitDate(m.year, m.month, 1), DateStyle.monthYear);
    final chosenMonth = b.dateMode == DateMode.flexibleMonth && b.date != null ? GzYm(b.date!.year, b.date!.month) : null;

    void pickDay(String? iso) => widget.set(
      (d) => d.copyWith(
        later: false,
        brief: iso == null ? d.brief.copyWith(clearDate: true, dateMode: DateMode.undecided) : d.brief.copyWith(date: LocalDate.parse(iso), dateMode: DateMode.exact),
      ),
    );
    void undecided() {
      if (_view == DateView.undecided) {
        widget.set((d) => d.copyWith(later: false));
        setState(() => _view = DateView.calendar);
        return;
      }
      setState(() => _view = DateView.undecided);
      widget.set((d) => d.copyWith(later: true, brief: d.brief.copyWith(clearDate: true, dateMode: DateMode.undecided)));
    }

    final info = b.dateMode == DateMode.exact && b.date != null ? f.dateWithHijri(b.date.toString()) : null;
    return Column(
      key: const ValueKey<String>('discover.brief.date'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: GzSpace.s2,
          runSpacing: GzSpace.s2,
          children: [
            GzChip(key: const ValueKey<String>('discover.brief.undecided'), label: context.gzL10n.commonLabelNotDecided, selected: _view == DateView.undecided, onPressed: undecided),
            GzChip(
              key: const ValueKey<String>('discover.brief.anymonth'),
              label: chosenMonth != null ? monthText(chosenMonth) : l.clientDiscoverBriefDateFlexible,
              iconStart: GzIcons.calendarDots,
              menu: true,
              selected: _view == DateView.months || chosenMonth != null,
              onPressed: () => setState(() => _view = _view == DateView.months ? DateView.calendar : DateView.months),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        if (_view == DateView.calendar || _view == DateView.undecided) ...[
          GzCalendar(
            value: _view == DateView.undecided || b.dateMode != DateMode.exact ? null : b.date?.toString(),
            onChanged: pickDay,
            month: _month,
            onMonthChange: (m) => setState(() => _month = m),
            maxDate: maxDate,
            summary: false,
            legend: false,
            label: l.clientDiscoverBriefDateTitle,
          ),
          if (_view != DateView.undecided && info != null && b.date != null) ...[
            const SizedBox(height: GzSpace.s4),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
              ),
              child: Row(
                children: [
                  GzIcon(GzIcons.calendarCheck, size: GzIconSize.md, color: c.iconAccent),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: GzFigures.spans(context, info.primary, role: GzTextRole.title)),
                          style: context.gz.text(GzTextRole.title).copyWith(color: c.textStrong, decoration: TextDecoration.none),
                        ),
                        if (info.secondary != null)
                          Text.rich(
                            TextSpan(children: GzFigures.spans(context, info.secondary!, role: GzTextRole.caption)),
                            style: context.gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, decoration: TextDecoration.none),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzFactChip(icon: GzIcons.countdown, label: l.clientDiscoverA11yDaysLeft, value: f.digits(context.gzL10n.commonCountDays(f.daysUntil(b.date.toString())))),
                ],
              ),
            ),
          ],
        ],
        if (_view == DateView.months)
          Semantics(
            container: true,
            label: l.clientDiscoverBriefDateFlexible,
            child: Wrap(
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s2,
              children: [
                for (final m in _months(today))
                  GzChip(
                    key: ValueKey<String>('discover.brief.month.${m.year}-${m.month}'),
                    label: monthText(m),
                    selected: chosenMonth == m,
                    onPressed: () => widget.set(
                      (d) => d.copyWith(later: false, brief: d.brief.copyWith(date: LocalDate(m.year, m.month, 1), dateMode: DateMode.flexibleMonth)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The two-level region picker: first the governorate (six), then the areas under it as chips with a hall count; a governorate can be
/// selected whole ("All") or area by area. The search field is the door to CL-DISC-07. Nothing selected means any area.
class BriefAreaPanel extends ConsumerWidget {
  const BriefAreaPanel({required this.draft, required this.set, required this.onOpenRegion, super.key});

  final BriefDraft draft;
  final DraftSetter set;
  final VoidCallback onOpenRegion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final groups = ref.watch(regionGroupsProvider).value ?? const <RegionGroup>[];
    final selected = draft.brief.areaIds;
    void setAreas(List<String> ids) => set((d) => d.copyWith(brief: d.brief.copyWith(areaIds: ids)));
    return Column(
      key: const ValueKey<String>('discover.brief.area'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPressable(
          key: const ValueKey<String>('discover.brief.regionsearch'),
          onPressed: onOpenRegion,
          semanticLabel: l.clientDiscoverRegionPlaceholder,
          borderRadius: GzRadius.mdAll,
          builder: (context, st) => Container(
            constraints: const BoxConstraints(minHeight: GzSize.controlSm),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
            decoration: BoxDecoration(color: c.controlBg, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderControl, width: GzStroke.hair)),
            child: Row(
              children: [
                GzIcon(GzIcons.search, size: GzIconSize.sm, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                GzText(l.clientDiscoverRegionPlaceholder, role: GzTextRole.body, color: c.textSecondary),
              ],
            ),
          ),
        ),
        for (final g in groups) ...[
          const SizedBox(height: GzSpace.s4),
          Builder(
            builder: (context) {
              final ids = <String>[for (final a in g.areas) a.area.id];
              final all = ids.every(selected.contains);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: GzText(g.governorate.name.of(lang), role: GzTextRole.label, color: c.textSecondary)),
                      GzButton(
                        key: ValueKey<String>('discover.brief.all.${g.governorate.id}'),
                        label: all ? l.clientDiscoverBriefAreaClearGroup : l.clientDiscoverBriefAreaAll,
                        variant: GzButtonVariant.tertiary,
                        onPressed: () => setAreas(all ? <String>[for (final id in selected) if (!ids.contains(id)) id] : <String>{...selected, ...ids}.toList()),
                      ),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s2),
                  GzChipGroup<String>.multiple(
                    label: g.governorate.name.of(lang),
                    values: <String>[for (final id in selected) if (ids.contains(id)) id],
                    onChanged: (next) => setAreas(<String>[for (final id in selected) if (!ids.contains(id)) id, ...next]),
                    options: [for (final a in g.areas) GzChipOption<String>(value: a.area.id, label: '${a.area.name.of(lang)} ${f.integer(a.count)}')],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
