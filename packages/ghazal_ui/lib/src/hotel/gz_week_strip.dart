import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;

import '../core/core.dart';
import '../foundation.dart';

/// One mark of a strip day: a hall or session that is confirmed, pending (a request or a hold) or open.
enum GzStripMark { confirmed, pending, open }

/// A day of the strip: its civil date (`2026-11-12`) and at most three marks, one per hall or session.
class GzStripDay {
  const GzStripDay({required this.iso, this.marks = const []});

  final String iso;
  final List<GzStripMark> marks;
}

/// WeekStrip: the 7-day strip of Hotel Today. Seven flex columns, at least 88 high, each with the short weekday, the date in the
/// figures voice and up to three 4 dp marks (confirmed = solid ink, pending = gold, open = a hairline outline). Today has the ink
/// outline; the selected day is the one gold fill (2 dp canvas gap, then a 1 dp gold ring). The legend and every day's semantics
/// carry the counts, so colour is never the only signal. Longer ranges wrap into rows of seven. Web `WeekStrip`.
class GzWeekStrip extends StatelessWidget {
  const GzWeekStrip({
    required this.days,
    required this.label,
    this.today,
    this.selected,
    this.onSelect,
    this.legend = true,
    this.footer,
    super.key,
  });

  final List<GzStripDay> days;

  /// Civil date of today; default the formatter's clock.
  final String? today;
  final String? selected;
  final ValueChanged<String>? onSelect;

  /// The legend with the counts under the strip.
  final bool legend;

  /// Accessible name of the strip ("Next 7 days").
  final String label;

  /// Under the legend (the open-weekends line).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final now = today ?? f.isoDay(f.now());
    final rows = <List<GzStripDay>>[for (var i = 0; i < days.length; i += 7) days.sublist(i, i + 7 > days.length ? days.length : i + 7)];
    int count(GzStripMark m) => days.fold(0, (a, d) => a + d.marks.where((x) => x == m).length);
    String dayName(GzStripDay d) {
      int n(GzStripMark m) => d.marks.where((x) => x == m).length;
      final parts = [
        if (n(GzStripMark.confirmed) > 0) l.uiHotelStripConfirmedCount(n(GzStripMark.confirmed)),
        if (n(GzStripMark.pending) > 0) l.uiHotelStripPendingCount(n(GzStripMark.pending)),
        if (n(GzStripMark.open) > 0) l.uiHotelStripOpenCount(n(GzStripMark.open)),
      ];
      return [
        f.date(d.iso, DateStyle.short),
        if (d.iso == now) l.uiHotelStripToday,
        parts.join(l.uiHotelStripSep),
      ].where((s) => s.isNotEmpty).join(l.uiHotelStripSep);
    }

    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: GzSpace.s1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in rows[r])
                  Expanded(
                    child: _Day(
                      day: d,
                      name: dayName(d),
                      isToday: d.iso == now,
                      isSelected: selected == d.iso,
                      weekday: f.weekdayName(f.civil(d.iso).weekday, NameStyle.header),
                      figure: f.integer(f.civil(d.iso).day),
                      toggle: onSelect != null,
                      onPressed: () => onSelect?.call(d.iso),
                    ),
                  ),
                // A short last row keeps the column width of the seven.
                for (var i = rows[r].length; i < 7 && rows.length > 1; i++) const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
          if (legend) ...[
            const SizedBox(height: GzSpace.s3),
            Wrap(
              spacing: GzSpace.s4,
              runSpacing: GzSpace.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final m in GzStripMark.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(child: _Mark(m, onGold: false)),
                      const SizedBox(width: GzSpace.s2),
                      GzText(_markWord(l, m), role: GzTextRole.caption, color: c.textPrimary),
                      const SizedBox(width: GzSpace.s2),
                      GzNum(f.integer(count(m)), role: GzTextRole.caption, color: c.textPrimary),
                    ],
                  ),
              ],
            ),
          ],
          if (footer != null) ...[const SizedBox(height: GzSpace.s3), footer!],
        ],
      ),
    );
  }
}

String _markWord(GzL10n l, GzStripMark m) => switch (m) {
  GzStripMark.confirmed => l.uiHotelStripConfirmed,
  GzStripMark.pending => l.uiHotelStripPending,
  GzStripMark.open => l.uiHotelStripOpen,
};

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.name,
    required this.isToday,
    required this.isSelected,
    required this.weekday,
    required this.figure,
    required this.toggle,
    required this.onPressed,
  });

  final GzStripDay day;
  final String name;
  final bool isToday;
  final bool isSelected;
  final String weekday;
  final String figure;
  final bool toggle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: name,
      selected: toggle ? isSelected : null,
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: GzSize.weekStrip,
      builder: (context, st) {
        final fg = isSelected ? c.textOnGold : c.textStrong;
        final bg = isSelected ? (st.pressed ? c.markPressed : c.markKhayt) : (st.pressed ? c.surfaceQuiet : null);
        final body = Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: GzSize.weekStrip),
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: isSelected ? c.markKhayt : (isToday ? c.borderFocus : c.scrimClear), width: GzStroke.hair),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: GzText(weekday, role: GzTextRole.caption, color: isSelected ? c.textOnGold : c.textSecondary, softWrap: false),
              ),
              const SizedBox(height: GzSpace.s1),
              ExcludeSemantics(
                child: GzNum(figure, role: GzTextRole.priceStrong, color: fg),
              ),
              const SizedBox(height: GzSpace.s2),
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < day.marks.length && i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: GzSpace.s1),
                      _Mark(day.marks[i], onGold: isSelected),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
        if (!isSelected) return body;
        // The selected day: a 2 dp canvas gap, then a 1 dp ring (box-shadow spread plus outline with offset, drawn outside the box).
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -(GzStroke.thread + GzStroke.hair),
              right: -(GzStroke.thread + GzStroke.hair),
              top: -(GzStroke.thread + GzStroke.hair),
              bottom: -(GzStroke.thread + GzStroke.hair),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GzRadius.sm + GzStroke.thread + GzStroke.hair),
                  border: Border.all(color: c.markDecor, width: GzStroke.hair),
                ),
              ),
            ),
            body,
          ],
        );
      },
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark(this.mark, {required this.onGold});

  final GzStripMark mark;
  final bool onGold;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final solid = onGold ? c.textOnGold : null;
    return Container(
      width: GzSpace.s3,
      height: GzSpace.s1,
      decoration: BoxDecoration(
        borderRadius: GzRadius.pillAll,
        color: switch (mark) {
          GzStripMark.confirmed => solid ?? c.textPrimary,
          GzStripMark.pending => solid ?? c.markKhayt,
          GzStripMark.open => null,
        },
        border: mark == GzStripMark.open ? Border.all(color: onGold ? c.textOnGold : c.borderStrong, width: GzStroke.hair) : null,
      ),
    );
  }
}
