// MultiDateCalendar (web `MultiDateCalendar.tsx`): a month grid where a venue picks up to N free dates (HL-DCSN-03). The kit calendar picks one
// date or one range, so this flow-local twin keeps its anatomy (Sunday-first from the formatter, seven equal columns, 52 high cells, the Thu to
// Sat band at the inline-end edge, selected = gold fill with the canvas and gold-600 rings) and adds several picks, a price caption on a picked
// day, busy days struck through, the original date marked and a "taken while open" state (filed in requests.md as `Calendar mode multiple`).
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show CalendarDay, DateStyle, MoneyMode, MoneyOptions;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class YearMonth {
  const YearMonth(this.year, this.month);
  final int year;
  final int month;
  int get index => year * 12 + month - 1;
  YearMonth add(int n) {
    final i = index + n;
    return YearMonth(i ~/ 12, i % 12 + 1);
  }

  @override
  bool operator ==(Object other) => other is YearMonth && other.index == index;
  @override
  int get hashCode => index;
}

class MultiDateCalendar extends StatelessWidget {
  const MultiDateCalendar({
    required this.month,
    required this.onMonthChange,
    required this.free,
    required this.picked,
    required this.max,
    required this.onToggle,
    required this.original,
    required this.minMonth,
    required this.maxMonth,
    required this.today,
    required this.label,
    this.taken = const <String>[],
    super.key,
  });

  final YearMonth month;
  final ValueChanged<YearMonth> onMonthChange;

  /// Free dates of the hall and session with the price each would show (integer fils); a date not here is busy or closed.
  final Map<String, int> free;
  final List<String> picked;
  final int max;
  final ValueChanged<String> onToggle;
  final String original;
  final List<String> taken;
  final YearMonth minMonth;
  final YearMonth maxMonth;
  final String today;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final cl = context.gzL10n;
    final weeks = f.monthGrid(month.year, month.month);
    final headers = f.weekdayHeaders();
    final names = f.weekdayLabels();
    final canPrev = month.index > minMonth.index;
    final canNext = month.index < maxMonth.index;
    final full = picked.length >= max;

    Widget band({required Widget child, required bool peak, bool top = false, bool bottom = false, required bool first, required bool last}) {
      if (!peak) return child;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceTintSoft,
          borderRadius: BorderRadiusDirectional.only(
            topStart: top && first ? const Radius.circular(GzRadius.md) : Radius.zero,
            topEnd: top && last ? const Radius.circular(GzRadius.md) : Radius.zero,
            bottomStart: bottom && first ? const Radius.circular(GzRadius.md) : Radius.zero,
            bottomEnd: bottom && last ? const Radius.circular(GzRadius.md) : Radius.zero,
          ),
        ),
        child: child,
      );
    }

    bool isPeak(List<CalendarDay> row, int i) => i >= 0 && i < row.length && row[i].isPeak;

    Widget header(int i) {
      final row = weeks.first;
      final peak = isPeak(row, i);
      return Expanded(
        child: band(
          peak: peak,
          top: true,
          first: !isPeak(row, i - 1),
          last: !isPeak(row, i + 1),
          child: Semantics(
            label: names[i],
            excludeSemantics: true,
            child: SizedBox(height: GzSpace.s8, child: Center(child: GzText(headers[i], role: GzTextRole.caption, color: c.textSecondary, softWrap: false))),
          ),
        ),
      );
    }

    Widget cell(List<CalendarDay> row, int i, bool lastRow) {
      final d = row[i];
      final peak = d.isPeak;
      Widget inner;
      if (!d.inMonth) {
        inner = const SizedBox(height: GzSize.calCellHeight);
      } else {
        final iso = d.iso;
        final isOriginal = iso == original;
        final isTaken = taken.contains(iso);
        final price = free[iso];
        final isPicked = picked.contains(iso);
        final selectable = price != null && !isOriginal && !isTaken && (isPicked || !full);
        final past = iso.compareTo(today) < 0;
        final struck = !isPicked && (isTaken || (price == null && !isOriginal && !past));
        final figColor = isPicked ? c.textOnGold : (past && price == null ? c.iconDisabled : (struck ? c.borderControl : c.textStrong));
        final spoken = [
          f.plain(f.date(iso)),
          isOriginal ? context.l10n.hotelDecisionsProposeOriginal : (isTaken ? context.l10n.hotelDecisionsProposeTakenBadge : (price != null ? cl.commonAvailabilityFree : (past ? cl.commonAvailabilityPast : cl.commonAvailabilityBooked))),
          if (price != null && !isOriginal) f.plain(f.money(price)),
          if (isPicked) cl.commonCalendarSelected,
        ].join(' · ');
        final label = gz.text(GzTextRole.calDay).copyWith(color: figColor, decoration: struck ? TextDecoration.lineThrough : TextDecoration.none, decorationColor: figColor, decorationThickness: 1);
        Widget face = Container(
          margin: EdgeInsets.all(isPicked ? GzStroke.thread + GzStroke.hair : 0),
          decoration: BoxDecoration(
            color: isPicked ? c.markKhayt : null,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: isPicked ? c.markKhayt : (isTaken ? c.borderError : (isOriginal ? c.borderControl : (iso == today ? c.borderFocus : c.scrimClear))), width: GzStroke.hair),
            boxShadow: isPicked ? [BoxShadow(color: c.surfaceCanvas, spreadRadius: GzStroke.thread)] : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.integer(d.day), style: label, textAlign: TextAlign.center),
                    if (isPicked && price != null) GzText(_money(f, price), role: GzTextRole.calPrice, color: c.textOnGold, figures: true, softWrap: false),
                  ],
                ),
              ),
              if (isOriginal) PositionedDirectional(top: GzSpace.s2, end: GzSpace.s2, child: Container(width: GzSpace.s2, height: GzSpace.s2, decoration: BoxDecoration(color: c.borderControl, shape: BoxShape.circle))),
            ],
          ),
        );
        if (isPicked) {
          face = DecoratedBox(decoration: BoxDecoration(borderRadius: GzRadius.smAll, border: Border.all(color: c.markDecor, width: GzStroke.hair)), child: face);
        }
        inner = SizedBox(
          height: GzSize.calCellHeight,
          child: Semantics(
            button: selectable,
            selected: isPicked,
            enabled: selectable,
            label: spoken,
            excludeSemantics: true,
            onTap: selectable ? () => onToggle(iso) : null,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: selectable ? () => onToggle(iso) : null, child: face),
          ),
        );
      }
      return Expanded(
        child: band(peak: peak, bottom: lastRow, first: !isPeak(row, i - 1), last: !isPeak(row, i + 1), child: inner),
      );
    }

    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GzBarButton(icon: GzIcons.chevronLeft, label: cl.commonCalendarPreviousMonth, onPressed: canPrev ? () => onMonthChange(month.add(-1)) : null),
              Expanded(child: Center(child: GzText(f.date(f.kuwaitDate(month.year, month.month, 1), DateStyle.monthYear), role: GzTextRole.uiTitle, color: c.textStrong, figures: true, header: true))),
              GzBarButton(icon: GzIcons.chevronRight, label: cl.commonCalendarNextMonth, onPressed: canNext ? () => onMonthChange(month.add(1)) : null),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GzSpace.s1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [for (var i = 0; i < headers.length; i++) header(i)]),
                for (var r = 0; r < weeks.length; r++) Row(children: [for (var i = 0; i < weeks[r].length; i++) cell(weeks[r], i, r == weeks.length - 1)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _money(dynamic f, int fils) {
    final p = f.moneyParts(fils, const MoneyOptions(mode: MoneyMode.browse));
    return '${p.integer}${p.fraction}';
  }
}
