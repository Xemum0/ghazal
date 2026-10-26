import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The next two weeks as a Sunday-first calendar strip: the month once above
/// it, seven weekday initials (drawn, not read), then the days as 44+ cells
/// with up to three marks under the figure (session glyphs for chosen
/// windows, one bead for a day with free times). One day is selected (gold
/// fill); a day with nothing to offer is disabled, never greyed away.
class PlannerDayGrid extends StatelessWidget {
  const PlannerDayGrid({
    required this.days,
    required this.value,
    required this.onPick,
    required this.name,
    required this.labelOf,
    this.marksFor,
    this.enabledFor,
    this.disabled = false,
    this.aside,
    super.key,
  });

  final List<LocalDate> days;
  final LocalDate? value;
  final ValueChanged<LocalDate> onPick;

  /// The group's accessible name.
  final String name;

  /// The accessible name of a day: the full date, plus what it holds.
  final String Function(LocalDate day) labelOf;

  /// Under the figure, up to three marks: an [IconData] glyph, or null for the bead.
  final List<IconData?> Function(LocalDate day)? marksFor;

  /// A day that cannot be chosen (no free times). Default: all can.
  final bool Function(LocalDate day)? enabledFor;
  final bool disabled;
  final Widget? aside;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final months = <String>[];
    for (final d in days) {
      final m = f.monthName(d.month, short: true);
      if (months.isEmpty || months.last != m) months.add(m);
    }
    final lead = days.isEmpty ? 0 : DateTime.utc(days.first.year, days.first.month, days.first.day).weekday % 7;
    final cells = <LocalDate?>[...List<LocalDate?>.filled(lead, null), ...days];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return Column(
      key: const ValueKey<String>('planner.days'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < months.length; i++) ...[
                    if (i > 0) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.arrowRight, size: GzIconSize.xs, color: c.iconSecondary)],
                    GzText(months[i], role: GzTextRole.title, color: c.textStrong),
                  ],
                ],
              ),
            ),
            if (aside != null)
              DefaultTextStyle(
                style: TextStyle(color: c.textSecondary),
                child: aside!,
              ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Row(
          children: [
            for (var i = 0; i < f.weekdayHeaders().length; i++) ...[
              if (i > 0) const SizedBox(width: GzStroke.thread),
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: GzText(f.weekdayHeaders()[i], role: GzTextRole.caption, color: c.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Semantics(
          container: true,
          label: name,
          child: Column(
            children: [
              for (var r = 0; r < cells.length / 7; r++)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: r == 0 ? 0 : GzStroke.thread),
                  child: Row(
                    children: [
                      for (var ci = 0; ci < 7; ci++) ...[
                        if (ci > 0) const SizedBox(width: GzStroke.thread),
                        Expanded(child: _cell(context, cells[r * 7 + ci])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, LocalDate? day) {
    final c = context.gz.colors;
    if (day == null) return const SizedBox(height: GzSize.calCellHeight);
    final f = context.gzFormat;
    final on = !(disabled || (enabledFor != null && !enabledFor!(day)));
    final active = day == value;
    final marks = (marksFor?.call(day) ?? const <IconData?>[]).take(3).toList();
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        gzFigText(context, f.integer(day.day), role: GzTextRole.calDay, color: active ? c.textOnGold : c.textStrong),
        SizedBox(
          height: GzSpace.s3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < marks.length; i++) ...[
                if (i > 0) const SizedBox(width: 1),
                if (marks[i] == null)
                  Transform.rotate(
                    angle: 0.785,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: active ? c.textOnGold : c.textGoldInk),
                      child: const SizedBox.square(dimension: 6),
                    ),
                  )
                else
                  GzIcon(marks[i]!, sizeDp: 12, color: active ? c.textOnGold : c.textGoldInk),
              ],
            ],
          ),
        ),
      ],
    );
    // Selected day: gold fill, then a 1 px gold-600 outline 2 px outside the box (the web outline-offset; its canvas ring is invisible on the canvas).
    final box = active
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: c.markKhayt, borderRadius: GzRadius.smAll),
                child: SizedBox(
                  height: GzSize.calCellHeight,
                  child: Center(child: content),
                ),
              ),
              Positioned(
                left: -(GzStroke.thread + GzStroke.hair),
                right: -(GzStroke.thread + GzStroke.hair),
                top: -(GzStroke.thread + GzStroke.hair),
                bottom: -(GzStroke.thread + GzStroke.hair),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(GzRadius.sm + GzStroke.thread),
                      border: Border.all(color: c.markDecor, width: GzStroke.hair),
                    ),
                  ),
                ),
              ),
            ],
          )
        : SizedBox(
            height: GzSize.calCellHeight,
            child: Center(child: content),
          );
    return GzPressable(
      key: ValueKey<String>('planner.day.$day'),
      onPressed: on ? () => onPick(day) : null,
      semanticLabel: labelOf(day),
      selected: active,
      minWidth: 0,
      minHeight: GzSize.calCellHeight,
      borderRadius: GzRadius.smAll,
      child: box,
    );
  }
}
