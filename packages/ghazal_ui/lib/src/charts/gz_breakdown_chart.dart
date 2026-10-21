import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// The fill role of a breakdown part.
enum GzSegmentTone { ink, quiet, strong, gold, accent, open }

/// How a [GzBreakdownChart] draws the whole.
enum GzBreakdownVariant { stacked, donut }

/// One part of a [GzBreakdownChart].
class GzSegment {
  const GzSegment({required this.id, required this.label, required this.value, this.pattern = GzFillPattern.solid, this.tone = GzSegmentTone.ink});

  final String id;
  final String label;
  final num value;
  final GzFillPattern pattern;
  final GzSegmentTone tone;

  GzPatternTone get patternTone => tone == GzSegmentTone.gold || tone == GzSegmentTone.accent ? GzPatternTone.gold : GzPatternTone.ink;

  GzChartSwatch get swatch => switch (tone) {
        GzSegmentTone.ink => GzChartSwatch.ink,
        GzSegmentTone.quiet => GzChartSwatch.quiet,
        GzSegmentTone.strong => GzChartSwatch.strong,
        GzSegmentTone.gold => GzChartSwatch.gold,
        GzSegmentTone.accent => GzChartSwatch.accent,
        GzSegmentTone.open => GzChartSwatch.open,
      };
}

/// The donut centre: the hero figure and what it is.
class GzDonutCenter {
  const GzDonutCenter({required this.value, required this.caption});
  final String value;
  final String caption;
}

/// How a whole splits into a few named parts. `stacked` (default on a phone) is one 16 dp bar that grows from the inline-start;
/// `donut` is for a single hero share, starts at 12 o'clock and runs clockwise in both languages (circular, never mirrored).
/// Parts are told apart by pattern AND label, never by colour alone; the legend prints each part's value and share.
/// Web `BreakdownChart` (`DonutOrStackedBar`).
class GzBreakdownChart extends StatelessWidget {
  const GzBreakdownChart({
    required this.segments,
    required this.formatValue,
    required this.formatShare,
    required this.title,
    this.description,
    this.variant = GzBreakdownVariant.stacked,
    this.center,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  final List<GzSegment> segments;

  /// How a part's value reads in the legend and the table.
  final String Function(num value) formatValue;

  /// The share text of a part (`58%`), from the rounded percent.
  final String Function(num share) formatShare;
  final String title;
  final String? description;
  final GzBreakdownVariant variant;
  final GzDonutCenter? center;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    String share(GzSegment s) => formatShare(GzChartGeometry.sharePercent(s.value, total));
    final entries = [
      for (final s in segments)
        GzLegendEntry(id: s.id, label: s.label, swatch: s.swatch, pattern: s.pattern, patternTone: s.patternTone, value: '${formatValue(s.value)} · ${share(s)}'),
    ];
    final twin = GzChartTwin(caption: title, headers: ['', title], rows: [for (final s in segments) [s.label, '${formatValue(s.value)} (${share(s)})']]);
    final positive = [for (final s in segments) if (s.value > 0) s];
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            if (variant == GzBreakdownVariant.stacked)
              LayoutBuilder(
                builder: (context, box) => SizedBox(
                  height: GzSpace.s4,
                  child: CustomPaint(painter: _StackPainter(positive, box.maxWidth, colors, rtl, p)),
                ),
              )
            else
              Center(child: _Donut(positive: positive, center: center, colors: colors, p: p)),
            GzChartLegend(entries: entries),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}

Color? _fill(GzColors c, GzSegmentTone t) => switch (t) {
      GzSegmentTone.ink => c.textPrimary,
      GzSegmentTone.quiet => c.borderControl,
      GzSegmentTone.strong => c.textStrong,
      GzSegmentTone.accent => c.markState,
      GzSegmentTone.gold => c.statusPendingBg,
      GzSegmentTone.open => null,
    };

Color? _edge(GzColors c, GzSegmentTone t) => switch (t) {
      GzSegmentTone.gold => c.markState,
      GzSegmentTone.open => c.borderControl,
      _ => null,
    };

class _StackPainter extends CustomPainter {
  _StackPainter(this.segments, this.width, this.colors, this.rtl, this.progress) : super(repaint: progress.grow) {
    final widths = GzChartGeometry.segmentWidths([for (final s in segments) s.value], width, GzStroke.thread);
    var cursor = 0.0;
    for (final w in widths) {
      slots.add((cursor, w));
      cursor += w + GzStroke.thread;
    }
  }

  final List<GzSegment> segments;
  final double width;
  final GzColors colors;
  final bool rtl;
  final GzChartProgress progress;
  final List<(double, double)> slots = [];
  static const Radius _r = Radius.circular(GzRadius.xs);

  @override
  void paint(Canvas canvas, Size size) {
    final g = progress.grow.value;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final (start, full) = slots[i];
      final w = full * g;
      final left = rtl ? width - start - w : start;
      final rect = Rect.fromLTWH(left, 0, w, size.height);
      final first = i == 0;
      final last = i == segments.length - 1;
      // Inline-start corners on the first part, inline-end corners on the last (physical left / right depends on direction).
      final leftR = (rtl ? last : first) ? _r : Radius.zero;
      final rightR = (rtl ? first : last) ? _r : Radius.zero;
      gzPaintMark(
        canvas,
        rect,
        colors: colors,
        fill: _fill(colors, s.tone),
        border: _edge(colors, s.tone),
        pattern: s.pattern,
        tone: s.patternTone,
        rrect: RRect.fromRectAndCorners(rect, topLeft: leftR, bottomLeft: leftR, topRight: rightR, bottomRight: rightR),
      );
    }
  }

  @override
  bool shouldRepaint(_StackPainter old) => old.segments != segments || old.width != width || old.colors != colors || old.rtl != rtl;
}

class _Donut extends StatelessWidget {
  const _Donut({required this.positive, required this.center, required this.colors, required this.p});
  final List<GzSegment> positive;
  final GzDonutCenter? center;
  final GzColors colors;
  final GzChartProgress p;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: GzSize.chartDonut,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FadeTransition(opacity: p.fade, child: CustomPaint(painter: _DonutPainter(positive, colors))),
          ),
          if (center != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzNum(center!.value, role: GzTextRole.fig3xl, color: colors.textStrong),
                GzText(center!.caption, role: GzTextRole.caption, color: colors.textSecondary),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.colors) {
    const size = GzSize.chartDonut;
    const ring = GzSize.chartDonutRing;
    const r = (size - ring) / 2;
    final outer = Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: r + ring / 2);
    final inner = Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: r - ring / 2);
    final arcs = GzChartGeometry.donutArcs([for (final s in segments) s.value]);
    for (final a in arcs) {
      final a0 = GzChartGeometry.percentToRadians(a.start);
      final sweep = a.length / 100 * 2 * math.pi;
      paths.add(
        Path()
          ..arcTo(outer, a0, sweep, true)
          ..arcTo(inner, a0 + sweep, -sweep, false)
          ..close(),
      );
    }
  }

  final List<GzSegment> segments;
  final GzColors colors;
  final List<Path> paths = [];

  @override
  void paint(Canvas canvas, Size size) {
    const ring = GzSize.chartDonutRing;
    const c = Offset(GzSize.chartDonut / 2, GzSize.chartDonut / 2);
    canvas.drawCircle(
      c,
      (GzSize.chartDonut - ring) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..color = colors.borderHairline,
    );
    for (var i = 0; i < paths.length; i++) {
      final s = segments[i];
      if (s.pattern == GzFillPattern.solid) {
        final color = s.tone == GzSegmentTone.gold ? colors.markState : _fill(colors, s.tone) ?? colors.borderControl;
        canvas.drawPath(paths[i], Paint()..color = color);
      } else {
        canvas.save();
        canvas.clipPath(paths[i]);
        GzPatternPainter.paint(canvas, const Size.square(GzSize.chartDonut), s.pattern, s.patternTone, colors);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.segments != segments || old.colors != colors;
}
