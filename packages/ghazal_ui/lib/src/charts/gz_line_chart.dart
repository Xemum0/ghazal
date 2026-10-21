import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// Stroke colour of a line series.
enum GzLineTone { ink, accent, quiet }

/// One series of a [GzLineChart].
class GzLineSeries {
  const GzLineSeries({required this.id, required this.label, required this.values, this.tone = GzLineTone.ink, this.dashed = false, this.area = false});

  final String id;

  /// Legend and table header ("This month", "Previous 30 days").
  final String label;
  final List<num> values;
  final GzLineTone tone;

  /// Dashed stroke: the comparison series (a pattern, not only a colour).
  final bool dashed;

  /// Flat tint under the line (the main series only).
  final bool area;
}

/// One to three series over time. The area under the main line is a flat tint (no gradient), a second series is accent gold or a
/// dashed ink comparison line, the latest point is a bead. The time axis runs in reading direction (earliest at the right edge in
/// Arabic), the value axis never flips and its labels sit at the inline-start edge, digits stay Western and LTR, the first and last
/// date are labelled, `showTable` prints the table twin. The line draws on once. Web `LineChart`.
class GzLineChart extends StatelessWidget {
  const GzLineChart({
    required this.series,
    required this.xLabel,
    required this.formatAxis,
    required this.title,
    this.formatValue,
    this.description,
    this.xLabels = 3,
    this.height = GzSize.chartPlot,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  final List<GzLineSeries> series;

  /// Text of the x axis at each index (a date): the explicit labels and the table twin.
  final String Function(int index) xLabel;

  /// Value text on the axis (and in the table unless [formatValue]).
  final String Function(num value) formatAxis;
  final String Function(num value)? formatValue;
  final String title;
  final String? description;

  /// How many labels on the time axis, first and last included.
  final int xLabels;
  final double height;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    var n = 0;
    for (final s in series) {
      if (s.values.length > n) n = s.values.length;
    }
    final ticks = GzChartGeometry.niceTicks(gzMaxOf([for (final s in series) ...s.values]));
    final fmt = formatValue ?? formatAxis;
    final twin = GzChartTwin(
      caption: title,
      headers: ['', for (final s in series) s.label],
      rows: [
        for (var i = 0; i < n; i++) [xLabel(i), for (final s in series) i < s.values.length ? fmt(s.values[i]) : ''],
      ],
    );
    final legend = [
      for (final s in series)
        GzLegendEntry(
          id: s.id,
          label: s.label,
          line: true,
          swatch: s.dashed
              ? GzChartSwatch.dashed
              : switch (s.tone) {
                  GzLineTone.accent => GzChartSwatch.accent,
                  GzLineTone.quiet => GzChartSwatch.quiet,
                  GzLineTone.ink => GzChartSwatch.ink,
                },
        ),
    ];
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            GzChartPlotRow(
              yAxis: GzChartYAxis(ticks: ticks.ticks, format: formatAxis, height: height),
              plot: LayoutBuilder(
                builder: (context, box) {
                  final width = box.maxWidth;
                  final marks = [
                    for (final s in series)
                      _Mark(s, GzChartGeometry.linePoints(s.values, n, width, height, ticks.max, rtl: rtl, pad: GzSize.knotBead), colors, height),
                  ];
                  return SizedBox(height: height, child: CustomPaint(painter: _LinePainter(marks, colors, rtl, p, width)));
                },
              ),
              xAxis: GzChartXAxis(labels: [for (final i in GzChartGeometry.labelIndexes(n, xLabels)) xLabel(i)]),
            ),
            if (series.length > 1) GzChartLegend(entries: legend),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}

class _Mark {
  _Mark(this.series, this.pts, GzColors c, double height) {
    color = switch (series.tone) {
      GzLineTone.accent => c.markState,
      GzLineTone.quiet => c.borderControl,
      GzLineTone.ink => c.textPrimary,
    };
    if (pts.isEmpty) return;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    if (series.area) {
      areaPath = Path.from(path)
        ..lineTo(pts.last.dx, height)
        ..lineTo(pts.first.dx, height)
        ..close();
    }
    if (series.dashed) {
      for (final PathMetric m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += GzSpace.s2 + GzSpace.s1) {
          dashes.addPath(m.extractPath(d, (d + GzSpace.s2).clamp(0, m.length)), Offset.zero);
        }
      }
    } else {
      const r = GzSize.knotBead * 0.7071067811865476;
      final b = pts.last;
      bead = Path()
        ..moveTo(b.dx, b.dy - r)
        ..lineTo(b.dx + r, b.dy)
        ..lineTo(b.dx, b.dy + r)
        ..lineTo(b.dx - r, b.dy)
        ..close();
    }
  }

  final GzLineSeries series;
  final List<Offset> pts;
  late final Color color;
  final Path path = Path();
  Path? areaPath;
  Path? bead;
  final Path dashes = Path();
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.marks, this.colors, this.rtl, this.progress, this.width) : super(repaint: progress.both);

  final List<_Mark> marks;
  final GzColors colors;
  final bool rtl;
  final GzChartProgress progress;
  final double width;
  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    gzPaintGrid(canvas, size, colors);
    final fade = progress.fade.value;
    final grow = progress.grow.value;
    for (final m in marks) {
      final area = m.areaPath;
      if (area != null && fade > 0) {
        _p
          ..style = PaintingStyle.fill
          ..color = colors.surfaceTint.withValues(alpha: colors.surfaceTint.a * fade);
        canvas.drawPath(area, _p);
      }
    }
    for (final m in marks) {
      if (m.pts.length < 2) continue;
      if (m.series.dashed) {
        if (fade <= 0) continue;
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = GzStroke.thread
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round
          ..color = m.color.withValues(alpha: m.color.a * fade);
        canvas.drawPath(m.dashes, _p);
        continue;
      }
      final start = m.pts.first.dx;
      final end = m.pts.last.dx;
      final x = start + (end - start) * grow;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(rtl ? x - GzStroke.thread : start - GzStroke.thread, -GzSpace.s2, rtl ? start + GzStroke.thread : x + GzStroke.thread, size.height + GzSpace.s2));
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = GzStroke.thread
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = m.color;
      canvas.drawPath(m.path, _p);
      canvas.restore();
    }
    for (final m in marks) {
      final bead = m.bead;
      if (bead == null || fade <= 0) continue;
      _p
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.butt
        ..color = colors.surfaceCanvas.withValues(alpha: fade);
      canvas.drawPath(bead, _p);
      _p
        ..style = PaintingStyle.fill
        ..color = (m.series.tone == GzLineTone.accent ? colors.markState : colors.markKhayt).withValues(alpha: fade);
      canvas.drawPath(bead, _p);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.marks != marks || old.colors != colors || old.rtl != rtl;
}
