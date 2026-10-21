/// CountdownCard (My Wedding, Home once a booking is confirmed; ADR 0011 D7, direction section 3 "Ink panels"): the one ink panel of a
/// screen. Port of design/src/system/domain-client/CountdownCard.tsx.
///
/// Whole days only, never seconds, never a ticking number. The numeral is the display serif, the unit and one calm sentence sit beside
/// and under it. Milestones (a year, six months, a month, a week, tomorrow, today) change the sentence; tomorrow and today replace the
/// numeral with the word. A gold 2 dp thread shows how far along the wait is (a state). States: plain, milestone 365 / 180 / 30 / 7,
/// tomorrow, today, loading.
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../core/core.dart';
import '../foundation.dart';

enum GzCountdownMilestone { year, half, month, week, tomorrow, today }

/// The milestone a day count lands on (365, 180, 30, 7, 1, 0); anything else is a plain count (null).
GzCountdownMilestone? gzCountdownMilestone(int days) {
  if (days <= 0) return GzCountdownMilestone.today;
  return switch (days) {
    1 => GzCountdownMilestone.tomorrow,
    7 => GzCountdownMilestone.week,
    30 => GzCountdownMilestone.month,
    180 => GzCountdownMilestone.half,
    365 => GzCountdownMilestone.year,
    _ => null,
  };
}

class GzCountdownCard extends StatelessWidget {
  const GzCountdownCard({required this.days, required this.eventDate, this.where, this.progress, this.actionLabel, this.onAction, this.loading = false, super.key});

  /// Whole calendar days to the wedding (`GzFormat.daysUntil`); 0 is today.
  final int days;

  /// The wedding date (civil `YYYY-MM-DD`), spelled out in the facts line.
  final String eventDate;

  /// Venue and hall line after the date.
  final String? where;

  /// 0 to 1: how much of the wait has passed (booking made to wedding day). Null hides the thread.
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    const radius = GzRadius.mdAll;
    if (loading) {
      Widget sk(double w, double h) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceDarkRaised, borderRadius: GzRadius.xsAll),
          child: SizedBox(width: w, height: h),
        ),
      );
      return Semantics(
        container: true,
        label: l.commonStateLoading,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceDark, borderRadius: radius),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s5, vertical: GzSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [sk(96, 16), const SizedBox(height: GzSpace.s3), sk(160, 96), const SizedBox(height: GzSpace.s3), sk(220, 20)],
              ),
            ),
          ),
        ),
      );
    }
    final milestone = gzCountdownMilestone(days);
    final word = milestone == GzCountdownMilestone.today
        ? l.uiClientCountdownToday
        : (milestone == GzCountdownMilestone.tomorrow ? l.uiClientCountdownTomorrow : null);
    final line = switch (milestone) {
      GzCountdownMilestone.today => l.uiClientCountdownTodayLine,
      GzCountdownMilestone.tomorrow => l.uiClientCountdownTomorrowLine,
      GzCountdownMilestone.week => l.uiClientCountdownWeek,
      GzCountdownMilestone.month => l.uiClientCountdownMonth,
      GzCountdownMilestone.half => l.uiClientCountdownHalf,
      GzCountdownMilestone.year => l.uiClientCountdownYear,
      null => l.uiClientCountdownToGo,
    };
    final done = (progress ?? 0).clamp(0.0, 1.0);
    // Flex ratios in whole permille: no widths.
    final grow = (done * 1000).round();
    TextStyle on(GzTextRole role, Color color) => gz.text(role).copyWith(color: color, decoration: TextDecoration.none);

    final numeralStyle = on(GzTextRole.countdown, c.textOnDark);
    final unitStyle = on(GzTextRole.d1, c.textOnDark);
    final numeral = word != null
        ? Text(word, style: on(GzTextRole.d5, c.textOnDark))
        : Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // The numeral is an LTR island by direction, not by isolate marks: the negative letter spacing of the display face would
              // otherwise also shrink the two format characters.
              GzChromeBaseline(style: numeralStyle, child: Text(f.integer(days), style: numeralStyle, textDirection: TextDirection.ltr, maxLines: 1)),
              const SizedBox(width: GzSpace.s4),
              Flexible(child: GzChromeBaseline(style: unitStyle, child: Text(l.uiClientCountdownUnit(days), style: unitStyle))),
            ],
          );
    final factsStyle = on(GzTextRole.bodyS, c.textOnDark);
    return RepaintBoundary(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: l.uiClientCountdownEyebrow,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceDark, borderRadius: radius),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s5, vertical: GzSpace.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(l.uiClientCountdownEyebrow, role: GzTextRole.label, color: c.textOnDarkGold),
                const SizedBox(height: GzSpace.s3),
                numeral,
                const SizedBox(height: GzSpace.s3),
                GzText(line, role: GzTextRole.body, color: c.textOnDarkMuted),
                if (progress != null) ...[
                  const SizedBox(height: GzSpace.s3 + GzSpace.s2),
                  Semantics(
                    image: true,
                    label: '${l.uiClientCountdownProgress}: ${f.percent(done * 100)}',
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height: GzSize.knotBead,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (grow > 0) Expanded(flex: grow, child: SizedBox(height: GzStroke.thread, child: ColoredBox(color: c.markKhayt))),
                            const GzBead(),
                            if (grow < 1000) Expanded(flex: 1000 - grow, child: SizedBox(height: GzStroke.thread, child: ColoredBox(color: c.markTrackOnDark))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: GzSpace.s2 + GzSpace.s3),
                ] else
                  const SizedBox(height: GzSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzIcon(GzIcons.calendar, size: GzIconSize.sm, color: c.iconOnDark),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            ...GzFigures.spans(context, f.date(eventDate, DateStyle.full), role: GzTextRole.bodyS),
                            if (where != null) TextSpan(text: ' · $where', style: TextStyle(color: c.textOnDarkMuted)),
                          ],
                        ),
                        style: factsStyle,
                      ),
                    ),
                  ],
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: GzSpace.s3),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzButton(label: actionLabel!, variant: GzButtonVariant.tertiary, onDark: true, iconEnd: GzIcons.chevronRight, onPressed: onAction),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
