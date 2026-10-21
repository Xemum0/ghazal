import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// The line colour of a sparkline: ink, or the one state accent.
enum GzSparkTone { ink, accent }

/// The trend of one series in a KPI tile: a 2 dp ink line, a flat tint under it, one diamond bead on the latest value. It carries
/// no numbers (the tile does) and mirrors in Arabic: earlier is at the inline-start, the right edge there (ADR 0014 D5). It draws on
/// once; reduced motion shows the finished line. Web `Sparkline`.
class GzSparkline extends StatelessWidget {
  const GzSparkline({
    required this.values,
    required this.label,
    this.description,
    this.height = GzSize.chartSpark,
    this.area = true,
    this.endMark = true,
    this.tone = GzSparkTone.ink,
    this.animate = true,
    super.key,
  });

  final List<num> values;

  /// Accessible name: what the line is ("Views, last 30 days").
  final String label;

  /// Spoken summary with the first and last values.
  final String? description;
  final double height;
  final bool area;
  final bool endMark;
  final GzSparkTone tone;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GzChartSemantics(
      title: label,
      description: description,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth.isFinite ? box.maxWidth : 0.0;
            final pts = values.length > 1 ? GzChartGeometry.sparkPoints(values, width, height, rtl: rtl, bead: GzSize.knotBead, pad: GzSpace.s2) : const <Offset>[];
            return SizedBox(
              height: height,
              width: width,
              child: CustomPaint(painter: _SparkPainter(pts, height, colors, tone, area, endMark, rtl, p)),
            );
          },
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.pts, this.height, this.colors, this.tone, this.area, this.endMark, this.rtl, this.progress) : super(repaint: progress.both) {
    if (pts.length > 1) {
      line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        line.lineTo(pts[i].dx, pts[i].dy);
      }
      areaPath = Path.from(line)
        ..lineTo(pts.last.dx, height)
        ..lineTo(pts.first.dx, height)
        ..close();
      final b = pts.last;
      bead = Path()
        ..moveTo(b.dx, b.dy - GzSize.knotBead * 0.7071067811865476)
        ..lineTo(b.dx + GzSize.knotBead * 0.7071067811865476, b.dy)
        ..lineTo(b.dx, b.dy + GzSize.knotBead * 0.7071067811865476)
        ..lineTo(b.dx - GzSize.knotBead * 0.7071067811865476, b.dy)
        ..close();
    }
  }

  final List<Offset> pts;
  final double height;
  final GzColors colors;
  final GzSparkTone tone;
  final bool area;
  final bool endMark;
  final bool rtl;
  final GzChartProgress progress;
  Path line = Path();
  Path areaPath = Path();
  Path bead = Path();
  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final fade = progress.fade.value;
    final grow = progress.grow.value;
    if (area && fade > 0) {
      _p
        ..style = PaintingStyle.fill
        ..color = colors.surfaceTint.withValues(alpha: colors.surfaceTint.a * fade);
      canvas.drawPath(areaPath, _p);
    }
    // Draw-on from the inline-start: reveal the plot from the first point's side (no per-frame path extraction).
    canvas.save();
    final start = pts.first.dx;
    final end = pts.last.dx;
    final x = start + (end - start) * grow;
    canvas.clipRect(Rect.fromLTRB(rtl ? x - GzStroke.thread : start - GzStroke.thread, -GzSpace.s2, rtl ? start + GzStroke.thread : x + GzStroke.thread, height + GzSpace.s2));
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.thread
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = tone == GzSparkTone.accent ? colors.markState : colors.textPrimary;
    canvas.drawPath(line, _p);
    canvas.restore();
    if (endMark && fade > 0) {
      _p
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = GzStroke.thread
        ..color = colors.surfaceCanvas.withValues(alpha: fade);
      canvas.drawPath(bead, _p);
      _p
        ..style = PaintingStyle.fill
        ..color = colors.markKhayt.withValues(alpha: fade);
      canvas.drawPath(bead, _p);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.pts != pts || old.colors != colors || old.tone != tone || old.area != area || old.endMark != endMark;
}
