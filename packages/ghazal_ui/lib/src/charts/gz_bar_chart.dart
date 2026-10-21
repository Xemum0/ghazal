import 'package:flutter/widgets.dart';

import '../core/gz_fig_text.dart';
import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// One bar of a [GzBarChart].
class GzBar {
  const GzBar({required this.id, required this.label, required this.value, this.highlight = false, this.hatch = false});

  final String id;

  /// Axis label (a short weekday or day number) and the table row header.
  final String label;
  final num value;

  /// The selected or current bar: gold fill, 1 dp state edge, its value printed above.
  final bool highlight;

  /// A forecast or pending amount: the pattern, not the colour, says so.
  final bool hatch;
}

/// Values over a time axis or a few categories. The order follows reading direction (earliest at the inline-start, the right edge
/// in Arabic, ADR 0014 D5) while the value axis never flips and its labels stay at the inline-start edge. Bars grow once from the
/// baseline. First, middle and last labels are explicit (every bar is labelled when there are 8 or fewer). Web `BarChart`.
class GzBarChart extends StatelessWidget {
  const GzBarChart({
    required this.bars,
    required this.formatAxis,
    required this.title,
    required this.seriesLabel,
    this.formatValue,
    this.description,
    this.hatchLabel,
    this.xLabel,
    this.height = GzSize.chartPlot,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  final List<GzBar> bars;
  final String Function(num value) formatAxis;

  /// Printed above the highlighted bar and in the table twin; default [formatAxis].
  final String Function(num value)? formatValue;
  final String title;
  final String? description;

  /// Series name for the table header and the legend of a hatched bar.
  final String seriesLabel;

  /// Legend entry for hatched bars (`Forecast`); the legend shows only when a bar is hatched.
  final String? hatchLabel;

  /// Label under every bar when there are 8 or fewer; otherwise first, middle and last.
  final String Function(int index)? xLabel;
  final double height;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final n = bars.length;
    final ticks = GzChartGeometry.niceTicks(gzMaxOf([for (final b in bars) b.value]));
    final fmt = formatValue ?? formatAxis;
    String label(int i) => xLabel != null ? xLabel!(i) : bars[i].label;
    final each = n <= 8;
    final hasHatch = bars.any((b) => b.hatch);
    final hasHighlight = bars.any((b) => b.highlight);
    final twin = GzChartTwin(caption: title, headers: ['', seriesLabel], rows: [for (var i = 0; i < n; i++) [label(i), fmt(bars[i].value)]]);
    final legend = hasHatch && hatchLabel != null
        ? [
            GzLegendEntry(id: 'solid', label: seriesLabel, swatch: GzChartSwatch.quiet),
            GzLegendEntry(id: 'hatch', label: hatchLabel!, swatch: GzChartSwatch.gold, pattern: GzFillPattern.hatch, patternTone: GzPatternTone.gold),
          ]
        : const <GzLegendEntry>[];
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            GzChartPlotRow(
              padTop: hasHighlight ? GzSpace.s4 : 0,
              yAxis: GzChartYAxis(ticks: ticks.ticks, format: formatAxis, height: height),
              plot: LayoutBuilder(
                builder: (context, box) {
                  final gap = each ? GzSpace.s2 : GzSpace.s1;
                  final rects = GzChartGeometry.barRects([for (final b in bars) b.value], ticks.max, box.maxWidth, height, gap: gap, barWidth: each ? GzSpace.s6 : null, rtl: rtl, minHeight: GzStroke.thread);
                  final slot = n == 0 ? 0.0 : (box.maxWidth - gap * (n - 1)) / n;
                  return SizedBox(
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _BarPainter(bars, rects, colors, p))),
                        for (var i = 0; i < n; i++)
                          if (bars[i].highlight)
                            Positioned.fromRect(
                              rect: Rect.fromLTWH(rects[i].center.dx - slot / 2, rects[i].top - GzSpace.s1 - gzAxisLabelLine, slot, gzAxisLabelLine),
                              child: Center(
                                child: gzFigText(context, fmt(bars[i].value), role: GzTextRole.figLabel, color: colors.textStrong, weight: context.gz.text(GzTextRole.figBodyS).fontWeight),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
              xAxis: each
                  ? ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < n; i++) ...[
                            if (i > 0) const SizedBox(width: GzSpace.s2),
                            Expanded(
                              child: Text(
                                label(i),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: context.gz.text(GzTextRole.caption).copyWith(
                                      color: bars[i].highlight ? colors.textStrong : colors.textSecondary,
                                      fontWeight: bars[i].highlight ? context.gz.text(GzTextRole.tab).fontWeight : null,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : GzChartXAxis(labels: [for (final i in GzChartGeometry.labelIndexes(n, 3)) label(i)]),
            ),
            if (legend.isNotEmpty) GzChartLegend(entries: legend),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.bars, this.rects, this.colors, this.progress) : super(repaint: progress.grow);

  final List<GzBar> bars;
  final List<Rect> rects;
  final GzColors colors;
  final GzChartProgress progress;
  final Paint _p = Paint();
  static const Radius _r = Radius.circular(GzRadius.xs);

  @override
  void paint(Canvas canvas, Size size) {
    gzPaintGrid(canvas, size, colors);
    final g = progress.grow.value;
    for (var i = 0; i < bars.length; i++) {
      final full = rects[i];
      final h = full.height * g;
      if (h <= 0) continue;
      final r = Rect.fromLTWH(full.left, full.bottom - h, full.width, h);
      final b = bars[i];
      final outer = RRect.fromRectAndCorners(r, topLeft: _r, topRight: _r);
      if (b.highlight) {
        canvas.drawRRect(outer, _p..color = colors.markState);
        final inner = RRect.fromLTRBAndCorners(r.left + GzStroke.hair, r.top + GzStroke.hair, r.right - GzStroke.hair, r.bottom,
            topLeft: const Radius.circular(GzRadius.xs - GzStroke.hair), topRight: const Radius.circular(GzRadius.xs - GzStroke.hair));
        canvas.drawRRect(inner, _p..color = colors.markKhayt);
        if (b.hatch) _hatch(canvas, inner, r);
      } else {
        canvas.drawRRect(outer, _p..color = colors.borderControl);
        if (b.hatch) _hatch(canvas, outer, r);
      }
    }
  }

  void _hatch(Canvas canvas, RRect clip, Rect r) {
    canvas.save();
    canvas.clipRRect(clip);
    canvas.translate(r.left, r.top);
    GzPatternPainter.paint(canvas, r.size, GzFillPattern.hatch, GzPatternTone.gold, colors);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.bars != bars || old.rects != rects || old.colors != colors;
}
