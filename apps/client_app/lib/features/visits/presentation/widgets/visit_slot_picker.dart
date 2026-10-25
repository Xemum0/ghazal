import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, VisitSlot;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_view.dart';

/// The date strip + arrival-window chips of the booking sheets (CL-VIST-01,
/// CL-VIST-05): the next days with slots, then 30-minute windows as chips.
class VisitSlotPicker extends ConsumerWidget {
  const VisitSlotPicker({
    required this.venueId,
    required this.date,
    required this.slot,
    this.takenSlot,
    this.disabled = false,
    required this.onChange,
    super.key,
  });

  final String venueId;
  final String? date;
  final DateTime? slot;
  final DateTime? takenSlot;
  final bool disabled;
  final void Function(String date, DateTime? slot) onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final dates = ref.watch(visitDatesProvider(venueId));
    return GzAsyncView<List<LocalDate>>(
      value: dates,
      loading: const GzSkeleton(blockSize: 96),
      onRetry: () => ref.invalidate(visitDatesProvider(venueId)),
      isEmpty: (d) => d.isEmpty,
      empty: GzEmptyState(fill: false, illustration: GzIllustrationName.emptyVisits, title: l.clientVisitsSlotDay),
      data: (days) {
        final shown = days.take(14).toList();
        final day = date != null && shown.any((d) => _iso(d) == date) ? date : (shown.isEmpty ? null : _iso(shown.first));
        if (day == null) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The day rail builds every day eagerly (a Row in a sideways scroll view): only the chosen day spells its weekday and month.
            Semantics(
              container: true,
              label: l.clientVisitsSlotDay,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // The chosen cell draws a ring outside its box: room so the scroller never clips it.
                padding: const EdgeInsets.all(GzSpace.s1),
                child: Row(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: GzSpace.s2),
                      _DayCell(
                        date: shown[i],
                        selected: _iso(shown[i]) == day,
                        disabled: disabled,
                        onPick: () async {
                          final iso = _iso(shown[i]);
                          try {
                            final list = await ref.read(visitSlotsProvider((venueId: venueId, date: iso)).future);
                            final first = list.where((s) => s.available).firstOrNull;
                            if (context.mounted) onChange(iso, first?.start);
                          } on Object {
                            if (context.mounted) onChange(iso, null);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s4),
            _SlotsGrid(venueId: venueId, date: day, slot: slot, takenSlot: takenSlot, disabled: disabled, onPick: (s) => onChange(day, s)),
          ],
        );
      },
    );
  }

  static String _iso(LocalDate d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// One day of the rail: the number always; the chosen day also spells its
/// weekday and month on gold.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.selected, required this.disabled, required this.onPick});

  final LocalDate date;
  final bool selected;
  final bool disabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final c = context.gz.colors;
    final civil = DateTime.utc(date.year, date.month, date.day);
    final iso = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final fg = selected ? c.textOnGold : c.textStrong;
    final sub = selected ? c.textOnGold : c.textSecondary;
    // Enlarged text does not fit the 48 dp cell: the chosen day sizes itself.
    final dense = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return GzPressable(
      onPressed: disabled ? null : onPick,
      semanticLabel: f.date(iso, DateStyle.full),
      selected: selected,
      minHeight: 0,
      minWidth: 0,
      borderRadius: GzRadius.smAll,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The chosen cell: a 2 dp raised ring, then a hairline gold outline outside it (web `.gzvt-day[data-selected]`).
          if (selected)
            Positioned.fill(
              left: -(GzStroke.thread + GzStroke.hair),
              right: -(GzStroke.thread + GzStroke.hair),
              top: -(GzStroke.thread + GzStroke.hair),
              bottom: -(GzStroke.thread + GzStroke.hair),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GzRadius.sm + GzStroke.thread),
                  border: Border.all(color: c.markDecor, width: GzStroke.hair),
                ),
              ),
            ),
          Container(
            width: dense && selected ? null : GzSpace.s12,
            constraints: const BoxConstraints(minWidth: GzSpace.s12, minHeight: GzSpace.s20),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
            decoration: BoxDecoration(
              color: selected ? c.markKhayt : null,
              borderRadius: GzRadius.smAll,
              border: Border.all(color: selected ? c.markKhayt : c.controlChipBorder, width: GzStroke.hair),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected)
                  GzText(f.weekdayName(civil.weekday % 7, NameStyle.short), role: GzTextRole.caption, color: sub, maxLines: 1, softWrap: false),
                GzText(f.integer(date.day), role: GzTextRole.figTitle, color: fg, figures: true),
                if (selected) GzText(f.monthName(date.month, short: true), role: GzTextRole.caption, color: sub, maxLines: 1, softWrap: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsGrid extends ConsumerStatefulWidget {
  const _SlotsGrid({
    required this.venueId,
    required this.date,
    required this.slot,
    required this.takenSlot,
    required this.disabled,
    required this.onPick,
  });

  final String venueId;
  final String date;
  final DateTime? slot;
  final DateTime? takenSlot;
  final bool disabled;
  final ValueChanged<DateTime> onPick;

  @override
  ConsumerState<_SlotsGrid> createState() => _SlotsGridState();
}

class _SlotsGridState extends ConsumerState<_SlotsGrid> {
  bool _picked = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = widget.venueId;
    final date = widget.date;
    final slots = ref.watch(visitSlotsProvider((venueId: repo, date: date)));
    return GzAsyncView<List<VisitSlot>>(
      value: slots,
      loading: const GzSkeleton(blockSize: 44),
      onRetry: () => ref.invalidate(visitSlotsProvider((venueId: widget.venueId, date: widget.date))),
      isEmpty: (s) => s.isEmpty,
      empty: const SizedBox.shrink(),
      data: (all) {
        final f = context.gzFormat;
        // The first free window of the first day is chosen from the start.
        if (!_picked && widget.slot == null && !widget.disabled) {
          final first = all.where((s) => s.available).firstOrNull;
          if (first != null) {
            _picked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onPick(first.start);
            });
          }
        }
        if (widget.slot != null && widget.date == date) _picked = true;
        (String, String) partsOf(DateTime at) {
          final s = f.time(at.toIso8601String());
          final i = s.lastIndexOf(' ');
          return i < 0 ? (s, '') : (s.substring(0, i), s.substring(i + 1));
        }

        String groupOf(DateTime at) {
          final h = f.civil(at.toIso8601String()).hour;
          return h < 12 ? 'morning' : (h < 17 ? 'afternoon' : 'evening');
        }

        final groups = <String, List<VisitSlot>>{'morning': [], 'afternoon': [], 'evening': []};
        for (final s in all) {
          groups[groupOf(s.start)]!.add(s);
        }
        final shownGroups = groups.entries.where((e) => e.value.isNotEmpty).toList();
        IconData groupIcon(String g) => switch (g) {
          'morning' => GzIcons.sun,
          'afternoon' => GzIcons.sunset,
          _ => GzIcons.moon,
        };
        String groupLabel(String g) => switch (g) {
          'morning' => l.clientVisitsSlotMorning,
          'afternoon' => l.clientVisitsSlotAfternoon,
          _ => l.clientVisitsSlotEvening,
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.takenSlot != null && widget.slot != null && widget.takenSlot!.isAtSameMomentAs(widget.slot!))
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
                child: Row(
                  children: [
                    GzIcon(GzIcons.clockOff, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(
                      child: GzText(
                        '${partsOf(widget.takenSlot!).$1} · ${l.clientVisitsSlotTaken}',
                        role: GzTextRole.bodyS,
                        color: context.gz.colors.textSecondary,
                        figures: true,
                      ),
                    ),
                  ],
                ),
              ),
            for (var gi = 0; gi < shownGroups.length; gi++) ...[
              if (gi > 0) const SizedBox(height: GzSpace.s4),
              // Windows grouped by the part of the day: a glyph over the meridiem once (40 wide), then the chips that carry only the start time.
              Semantics(
                container: true,
                label: groupLabel(shownGroups[gi].key),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                        child: SizedBox(
                          width: GzSize.thumbSm,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GzIcon(groupIcon(shownGroups[gi].key), size: GzIconSize.md, color: context.gz.colors.iconSecondary),
                              GzText(
                                partsOf(shownGroups[gi].value.first.start).$2,
                                role: GzTextRole.caption,
                                color: context.gz.colors.textSecondary,
                                figures: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(
                      child: Wrap(
                        spacing: GzSpace.s2,
                        runSpacing: GzSpace.s2,
                        children: [
                          for (final s in shownGroups[gi].value)
                            GzChip(
                              key: ValueKey<String>('visits.slot.${s.start.toIso8601String()}'),
                              label: partsOf(s.start).$1,
                              figures: true,
                              semanticLabel: f.time(s.start),
                              selected: widget.slot != null && s.start.isAtSameMomentAs(widget.slot!),
                              onPressed: !s.available || widget.disabled ? null : () => widget.onPick(s.start),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
