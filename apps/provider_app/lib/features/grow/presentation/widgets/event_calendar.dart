// EventCalendar (web `EventCalendar.tsx`): the month grid where the venue picks the event dates a window covers. The shared calendar picks one date or
// one range; a window wants several loose dates, so this flow-local twin keeps its anatomy (Sunday-first, seven columns, 52 high cells at least 44 wide,
// the Thu to Sat band at the inline-end edge, selected = gold fill with two rings) and adds any number of picks, busy days struck and not selectable and
// the venue's open weekend dates marked with a bead. Requested as `GzCalendar` multiple mode (requests.md [P-H3]).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/grow_data.dart';

class EventCalendar extends ConsumerWidget {
  const EventCalendar({
    required this.month,
    required this.onMonthChange,
    required this.picked,
    required this.onToggle,
    required this.minMonth,
    required this.maxMonth,
    required this.today,
    required this.soft,
    required this.label,
    super.key,
  });

  final GzYm month;
  final ValueChanged<GzYm> onMonthChange;
  final List<String> picked;
  final ValueChanged<String> onToggle;
  final GzYm minMonth;
  final GzYm maxMonth;
  final String today;
  final List<String> soft;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final busy = ref.watch(growBusyProvider(key)).value ?? const <String>{};
    final first = gzToIso(month.year, month.month, 1);
    final lead = gzWeekdayOfIso(first);
    final daysIn = DateTime.utc(month.year, month.month + 1, 0).day;
    final rows = ((lead + daysIn) / 7).ceil();
    final canPrev = gzCmpMonth(month, minMonth) > 0;
    final canNext = gzCmpMonth(month, maxMonth) < 0;
    final title = f.date(first, DateStyle.monthYear);
    bool peakCol(int col) => col >= 4;
    Widget band({required int col, required Widget child, required bool top, required bool bottom}) {
      if (!peakCol(col)) return child;
      final first = col == 4;
      final last = col == 6;
      // The band sits at the inline-end edge: its outer corners round only on the first and last columns.
      final startRound = first && top;
      final endRound = last && top;
      final startBottom = first && bottom;
      final endBottom = last && bottom;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceTintSoft,
          borderRadius: BorderRadiusDirectional.only(
            topStart: startRound ? const Radius.circular(12) : Radius.zero,
            topEnd: endRound ? const Radius.circular(12) : Radius.zero,
            bottomStart: startBottom ? const Radius.circular(12) : Radius.zero,
            bottomEnd: endBottom ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: child,
      );
    }

    Widget dayCell(int row, int col) {
      final n = row * 7 + col - lead + 1;
      if (n < 1 || n > daysIn) return const SizedBox(height: GzSize.calCellHeight);
      final iso = gzToIso(month.year, month.month, n);
      final past = iso.compareTo(today) < 0;
      final isBusy = busy.contains(iso);
      final isSel = picked.contains(iso);
      final disabled = past || isBusy;
      final isSoft = soft.contains(iso);
      final isToday = iso == today;
      final fig = GzText(
        f.integer(n),
        role: GzTextRole.figBody,
        color: isSel ? c.textOnGold : (isBusy ? c.borderControl : (past ? c.iconDisabled : c.textStrong)),
      );
      return SizedBox(
        height: GzSize.calCellHeight,
        child: Semantics(
          button: true,
          selected: isSel,
          enabled: !disabled,
          label: '${f.date(iso, DateStyle.full)}${isBusy ? ', ${l.commonAvailabilityBooked}' : ''}${isSoft ? ', ${l.hotelGrowOpenWeekend}' : ''}',
          excludeSemantics: true,
          child: GzPressable(
            onPressed: disabled ? null : () => onToggle(iso),
            minWidth: 0,
            minHeight: 0,
            borderRadius: GzRadius.smAll,
            child: Container(
              margin: isSel ? const EdgeInsets.all(GzStroke.thread) : null,
              decoration: BoxDecoration(
                color: isSel ? c.markKhayt : null,
                borderRadius: GzRadius.smAll,
                border: isSel || isToday ? Border.all(color: isSel ? c.markKhayt : c.borderFocus, width: GzStroke.hair) : null,
                boxShadow: isSel ? [BoxShadow(color: c.markDecor, spreadRadius: GzStroke.thread + GzStroke.hair)] : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  fig,
                  if (isBusy)
                    SizedBox(
                      width: GzSpace.s5,
                      height: GzStroke.hair,
                      child: ColoredBox(color: c.borderControl),
                    ),
                  if (isSoft && !isSel)
                    PositionedDirectional(
                      top: GzSpace.s2,
                      end: GzSpace.s2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: c.textGoldInk, shape: BoxShape.circle),
                        child: const SizedBox(width: GzSpace.s2, height: GzSpace.s2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GzInAction(
                icon: GzIcons.chevronLeft,
                iconSize: GzIconSize.md,
                label: context.gzL10n.commonCalendarPreviousMonth,
                color: canPrev ? c.iconPrimary : c.iconDisabled,
                onPressed: canPrev ? () => onMonthChange(gzAddMonths(month, -1)) : null,
              ),
              const SizedBox(width: GzSpace.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Center(
                    child: GzText(title, role: GzTextRole.uiTitle, color: c.textPrimary, figures: true),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s2),
              GzInAction(
                icon: GzIcons.chevronRight,
                iconSize: GzIconSize.md,
                label: context.gzL10n.commonCalendarNextMonth,
                color: canNext ? c.iconPrimary : c.iconDisabled,
                onPressed: canNext ? () => onMonthChange(gzAddMonths(month, 1)) : null,
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: band(
                          col: col,
                          top: true,
                          bottom: false,
                          child: SizedBox(
                            height: GzSpace.s8,
                            child: Center(
                              child: GzText(f.weekdayName(col, NameStyle.header), role: GzTextRole.caption, color: c.textSecondary, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (var row = 0; row < rows; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: band(col: col, top: false, bottom: row == rows - 1, child: dayCell(row, col)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          Wrap(
            spacing: GzSpace.s4,
            runSpacing: GzSpace.s2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: c.textGoldInk, shape: BoxShape.circle),
                    child: const SizedBox(width: GzSpace.s2, height: GzSpace.s2),
                  ),
                  const SizedBox(width: GzSpace.s2),
                  GzText(l.hotelGrowOpenWeekend, role: GzTextRole.caption, color: c.textSecondary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
