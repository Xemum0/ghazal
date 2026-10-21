import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// The state of one hall on one day.
enum GzLaneState { open, booked, held, blocked }

/// One day of a [GzHeatStrip].
class GzHeatDay {
  const GzHeatDay({required this.iso, required this.lanes, this.peak = false});
  final String iso;

  /// One state per hall, in the same order every day.
  final List<GzLaneState> lanes;

  /// Thu, Fri, Sat (the country's peak band).
  final bool peak;
}

/// Legend words of a [GzHeatStrip].
class GzHeatLegend {
  const GzHeatLegend({required this.booked, required this.held, required this.open, required this.peak, this.blocked});
  final String booked;
  final String held;
  final String open;
  final String peak;
  final String? blocked;
}

/// Counts for the legend, already formatted.
class GzHeatCounts {
  const GzHeatCounts({required this.booked, required this.held, required this.open, this.blocked});
  final String booked;
  final String held;
  final String open;
  final String? blocked;
}

/// Occupancy over the coming days as a strip of day cells, one lane per hall: ink when booked, gold-hatched when held, a crossed
/// outline when blocked and a hairline outline when open (a shape, never colour alone). Thu to Sat sit on one contiguous peak
/// wash. Time runs in reading direction (the first day is at the right edge in Arabic). Web `HeatStrip`.
class GzHeatStrip extends StatelessWidget {
  const GzHeatStrip({
    required this.days,
    required this.laneLabels,
    required this.dayLabel,
    required this.legend,
    required this.title,
    this.counts,
    this.description,
    this.laneHeight,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  final List<GzHeatDay> days;

  /// Hall names, one per lane, for the table twin.
  final List<String> laneLabels;
  final String Function(String iso) dayLabel;
  final GzHeatLegend legend;
  final GzHeatCounts? counts;
  final String title;
  final String? description;

  /// Lane height (multiple of 4); default 12, or 16 on a strip of more than 21 days.
  final double? laneHeight;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final lanes = days.isEmpty ? 0 : days.first.lanes.length;
    final laneH = laneHeight ?? (days.length > 21 ? GzSpace.s4 : GzSpace.s3);
    final height = GzSpace.s1 * 2 + lanes * laneH + (lanes > 0 ? (lanes - 1) * GzSpace.s1 : 0);
    final hasBlocked = days.any((d) => d.lanes.contains(GzLaneState.blocked));
    final entries = [
      GzLegendEntry(id: 'booked', label: legend.booked, swatch: GzChartSwatch.strong, value: counts?.booked),
      GzLegendEntry(id: 'held', label: legend.held, swatch: GzChartSwatch.gold, pattern: GzFillPattern.hatch, patternTone: GzPatternTone.gold, value: counts?.held),
      if (legend.blocked != null && hasBlocked)
        GzLegendEntry(id: 'blocked', label: legend.blocked!, swatch: GzChartSwatch.open, pattern: GzFillPattern.cross, value: counts?.blocked),
      GzLegendEntry(id: 'open', label: legend.open, swatch: GzChartSwatch.open, value: counts?.open),
      GzLegendEntry(id: 'peak', label: legend.peak, swatch: GzChartSwatch.tint),
    ];
    String stateWord(GzLaneState s) => switch (s) {
          GzLaneState.booked => legend.booked,
          GzLaneState.held => legend.held,
          GzLaneState.blocked => legend.blocked ?? legend.booked,
          GzLaneState.open => legend.open,
        };
    final twin = GzChartTwin(
      caption: title,
      headers: ['', ...laneLabels],
      rows: [for (final d in days) [dayLabel(d.iso), for (final l in d.lanes) stateWord(l)]],
    );
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _HeatPainter(days, laneH, colors, rtl, peakLayer: true))),
                  Positioned.fill(
                    child: FadeTransition(opacity: p.fade, child: CustomPaint(painter: _HeatPainter(days, laneH, colors, rtl, peakLayer: false))),
                  ),
                ],
              ),
            ),
            GzChartXAxis(labels: [for (final i in GzChartGeometry.labelIndexes(days.length, 3)) dayLabel(days[i].iso)]),
            GzChartLegend(entries: entries),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.days, this.laneH, this.colors, this.rtl, {required this.peakLayer});
  final List<GzHeatDay> days;
  final double laneH;
  final GzColors colors;
  final bool rtl;
  final bool peakLayer;
  final Paint _p = Paint();
  static const Radius _r = Radius.circular(GzRadius.xs);

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final dayW = size.width / n;
    for (var i = 0; i < n; i++) {
      final d = days[i];
      final left = (rtl ? n - 1 - i : i) * dayW;
      if (peakLayer) {
        if (d.peak) canvas.drawRect(Rect.fromLTWH(left, 0, dayW, size.height), _p..color = colors.surfaceTintSoft);
        continue;
      }
      for (var k = 0; k < d.lanes.length; k++) {
        final r = Rect.fromLTWH(left + GzStroke.hair, GzSpace.s1 + k * (laneH + GzSpace.s1), dayW - GzStroke.hair * 2, laneH);
        final rr = RRect.fromRectAndRadius(r, _r);
        switch (d.lanes[k]) {
          case GzLaneState.booked:
            gzPaintMark(canvas, r, colors: colors, fill: colors.textStrong, rrect: rr);
          case GzLaneState.held:
            gzPaintMark(canvas, r, colors: colors, border: colors.markState, rrect: rr, pattern: GzFillPattern.hatch, tone: GzPatternTone.gold);
          case GzLaneState.blocked:
            gzPaintMark(canvas, r, colors: colors, border: colors.borderControl, rrect: rr, pattern: GzFillPattern.cross);
          case GzLaneState.open:
            gzPaintMark(canvas, r, colors: colors, border: colors.borderControl, rrect: rr);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) => old.days != days || old.laneH != laneH || old.colors != colors || old.rtl != rtl;
}
