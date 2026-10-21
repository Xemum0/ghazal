import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/gz_fig_text.dart';
import '../foundation.dart';
import 'gz_chart_geometry.dart';

/// A pattern, not a colour, carries the category: solid, hatch (45 degree lines), dots or cross (web `FillPattern`).
enum GzFillPattern { solid, hatch, dots, cross }

/// Ink on paper, or gold on the pending wash.
enum GzPatternTone { ink, gold }

/// The colour roles of a chart mark (web `--gz-chart-*`): never a ramp step.
enum GzChartSwatch { ink, quiet, strong, accent, gold, open, dashed, tint }

// ------------------------------------------------------------------------------------------------------------------ reveal

/// The two phases of the one-time animate-in: [grow] (draw / grow, 480 ms, the expressive token) then [fade] (tint, bead and
/// dashed lines, 320 ms after the draw). Both are 1 when the chart is not animated or motion is reduced.
class GzChartProgress {
  const GzChartProgress(this.grow, this.fade);
  final Animation<double> grow;
  final Animation<double> fade;
  Listenable get both => Listenable.merge([grow, fade]);
}

/// Plays the chart's animate-in once when it is first built (the first reveal; the web waits for the viewport) and shows the
/// finished chart at once under reduced motion or `animate: false`. The subtree is its own repaint boundary.
class GzChartReveal extends StatefulWidget {
  const GzChartReveal({required this.builder, this.animate = true, super.key});

  final bool animate;
  final Widget Function(BuildContext context, GzChartProgress progress) builder;

  @override
  State<GzChartReveal> createState() => _GzChartRevealState();
}

class _GzChartRevealState extends State<GzChartReveal> with SingleTickerProviderStateMixin {
  static const _grow = GzMotion.durationExpressive;
  static const _fade = GzMotion.durationSlow;
  late final AnimationController _c = AnimationController(vsync: this, duration: _grow + _fade);
  late final GzChartProgress _p;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final split = _grow.inMicroseconds / (_grow + _fade).inMicroseconds;
    _p = GzChartProgress(
      CurvedAnimation(parent: _c, curve: Interval(0, split, curve: GzMotion.easeStandard)),
      CurvedAnimation(parent: _c, curve: Interval(split, 1, curve: GzMotion.easeStandard)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || GzReducedMotion.of(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(child: widget.builder(context, _p));
}

// -------------------------------------------------------------------------------------------------------------- semantics

/// What a chart says to assistive technology instead of its marks: the title, the description and every row of the table twin
/// (the marks are excluded; colour is never the only carrier).
class GzChartTwin {
  const GzChartTwin({required this.caption, required this.headers, required this.rows});

  /// The chart title.
  final String caption;

  /// First header cell (the axis), then one per series.
  final List<String> headers;
  final List<List<String>> rows;

  /// `Row: value, value; Row: value`, in the language's list punctuation.
  String summary({required bool ar}) {
    final sep = ar ? '، ' : ', ';
    return [
      for (final r in rows)
        if (r.isNotEmpty) r.first.isEmpty ? r.skip(1).join(sep) : '${r.first}: ${r.skip(1).where((c) => c.isNotEmpty).join(sep)}',
    ].join(ar ? '؛ ' : '; ');
  }
}

/// One Semantics node per chart: [label] = title, [value] = description + the table twin summary; the marks are excluded.
class GzChartSemantics extends StatelessWidget {
  const GzChartSemantics({required this.title, this.description, this.twin, required this.child, super.key});

  final String title;
  final String? description;
  final GzChartTwin? twin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ar = context.gz.isAr;
    final parts = [if (description != null && description!.isNotEmpty) description!, if (twin != null) twin!.summary(ar: ar)];
    return Semantics(container: true, label: title, value: parts.join(ar ? '. ' : '. '), child: ExcludeSemantics(child: child));
  }
}

// ---------------------------------------------------------------------------------------------------------------- patterns

/// Hatch, dot and cross fills drawn as lines and circles (no shader asset): `paint` fills `(0, 0) .. size` in local coordinates,
/// so the caller clips to the mark and translates to the origin the web pattern is anchored at (the mark's own box).
abstract final class GzPatternPainter {
  static final Paint _fill = Paint();
  static final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  static Color background(GzColors c, GzPatternTone tone) => tone == GzPatternTone.gold ? c.statusPendingBg : c.surfaceRaised;
  static Color ink(GzColors c, GzPatternTone tone) => tone == GzPatternTone.gold ? c.markState : c.textPrimary;

  static void paint(Canvas canvas, Size size, GzFillPattern pattern, GzPatternTone tone, GzColors c) {
    if (pattern == GzFillPattern.solid) return;
    const pitch = GzSize.chartPatternPitch;
    final w = size.width;
    final h = size.height;
    _fill.color = background(c, tone);
    canvas.drawRect(Offset.zero & size, _fill);
    final color = ink(c, tone);
    switch (pattern) {
      case GzFillPattern.hatch:
        _stroke
          ..color = color
          ..strokeWidth = GzStroke.thread;
        final step = pitch * math.sqrt2;
        for (var k = 0; k * step <= w + h; k++) {
          final x = k * step;
          canvas.drawLine(Offset(x, 0), Offset(x - h, h), _stroke);
        }
      case GzFillPattern.cross:
        _stroke
          ..color = color
          ..strokeWidth = GzStroke.hair;
        for (var m = -(h / pitch).ceil(); m * pitch <= w; m++) {
          canvas.drawLine(Offset(m * pitch, 0), Offset(m * pitch + h, h), _stroke);
        }
        for (var m = 0; m * pitch <= w + h; m++) {
          canvas.drawLine(Offset(m * pitch, 0), Offset(m * pitch - h, h), _stroke);
        }
      case GzFillPattern.dots:
        _fill.color = color;
        for (var y = pitch / 2; y < h + pitch; y += pitch) {
          for (var x = pitch / 2; x < w + pitch; x += pitch) {
            canvas.drawCircle(Offset(x, y), GzStroke.icon, _fill);
          }
        }
      case GzFillPattern.solid:
        break;
    }
  }
}

/// A rounded box of a swatch colour: the legend key (16 x 12) and the stacked / heat marks reuse the same fill rules.
GzChartSwatchStyle gzChartSwatchStyle(GzColors c, GzChartSwatch swatch) => switch (swatch) {
      GzChartSwatch.ink => GzChartSwatchStyle(c.textPrimary, null),
      GzChartSwatch.quiet => GzChartSwatchStyle(c.borderControl, null),
      GzChartSwatch.strong => GzChartSwatchStyle(c.textStrong, null),
      GzChartSwatch.accent => GzChartSwatchStyle(c.markState, null),
      GzChartSwatch.gold => GzChartSwatchStyle(c.statusPendingBg, c.markState),
      GzChartSwatch.open => GzChartSwatchStyle(null, c.borderControl),
      GzChartSwatch.dashed => GzChartSwatchStyle(null, c.borderControl),
      GzChartSwatch.tint => GzChartSwatchStyle(c.surfaceTintSoft, c.borderStrong),
    };

class GzChartSwatchStyle {
  const GzChartSwatchStyle(this.fill, this.border);
  final Color? fill;
  final Color? border;
}

/// A rounded rect painted with fill, hairline border INSIDE the box (border-box) and an optional pattern clipped to the padding box.
void gzPaintMark(
  Canvas canvas,
  Rect rect, {
  required GzColors colors,
  Color? fill,
  Color? border,
  GzFillPattern pattern = GzFillPattern.solid,
  GzPatternTone tone = GzPatternTone.ink,
  RRect? rrect,
  Offset? patternOrigin,
}) {
  final outer = rrect ?? RRect.fromRectAndRadius(rect, Radius.zero);
  final p = Paint();
  if (fill != null) canvas.drawRRect(outer, p..color = fill);
  var inner = outer;
  if (border != null) {
    inner = outer.deflate(GzStroke.hair);
    canvas.drawDRRect(outer, inner, Paint()..color = border);
  }
  if (pattern != GzFillPattern.solid) {
    canvas.save();
    canvas.clipRRect(inner);
    final origin = patternOrigin ?? inner.outerRect.topLeft;
    canvas.translate(origin.dx, origin.dy);
    GzPatternPainter.paint(canvas, Size(inner.outerRect.right - origin.dx, inner.outerRect.bottom - origin.dy), pattern, tone, colors);
    canvas.restore();
  }
}

// ----------------------------------------------------------------------------------------------------------------- legend

/// One legend entry: a swatch (colour, pattern or line style), a label and an optional figure after it.
class GzLegendEntry {
  const GzLegendEntry({
    required this.id,
    required this.label,
    required this.swatch,
    this.line = false,
    this.pattern,
    this.patternTone = GzPatternTone.ink,
    this.value,
  });
  final String id;
  final String label;
  final GzChartSwatch swatch;

  /// A 2 dp line rather than a block swatch.
  final bool line;
  final GzFillPattern? pattern;
  final GzPatternTone patternTone;

  /// A figure after the label (count, share), already formatted.
  final String? value;
}

/// Always present when a chart has more than one series, so colour is never the only carrier.
class GzChartLegend extends StatelessWidget {
  const GzChartLegend({required this.entries, super.key});
  final List<GzLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Wrap(
      spacing: GzSpace.s4,
      runSpacing: GzSpace.s2,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Key(entry: e),
              const SizedBox(width: GzSpace.s2),
              Flexible(child: GzText(e.label, role: GzTextRole.caption)),
              if (e.value != null) ...[
                const SizedBox(width: GzSpace.s2),
                gzFigText(context, e.value!, role: GzTextRole.figCaption, color: c.textPrimary),
              ],
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.entry});
  final GzLegendEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final style = gzChartSwatchStyle(c, entry.swatch);
    final line = entry.line || entry.swatch == GzChartSwatch.dashed;
    return SizedBox(
      width: GzSpace.s4,
      height: line ? GzStroke.thread : GzSpace.s3,
      child: CustomPaint(painter: _KeyPainter(entry, style, c)),
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.entry, this.style, this.colors);
  final GzLegendEntry entry;
  final GzChartSwatchStyle style;
  final GzColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (entry.swatch == GzChartSwatch.dashed) {
      final p = Paint()..color = colors.borderControl;
      const dash = 6.0;
      const gap = 4.0;
      for (var x = 0.0; x < size.width; x += dash + gap) {
        canvas.drawRect(Rect.fromLTWH(x, 0, math.min(dash, size.width - x), size.height), p);
      }
      return;
    }
    final round = entry.line ? Radius.zero : const Radius.circular(GzRadius.xs);
    gzPaintMark(
      canvas,
      Offset.zero & size,
      colors: colors,
      fill: style.fill,
      border: style.border,
      rrect: RRect.fromRectAndRadius(Offset.zero & size, round),
      pattern: entry.pattern ?? GzFillPattern.solid,
      tone: entry.patternTone,
    );
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.entry != entry || old.colors != colors;
}

// ------------------------------------------------------------------------------------------------------------------- axes

/// Height of one value-axis label line (the web `LABEL_LINE`): the label column is this much taller than the plot.
const double gzAxisLabelLine = GzSpace.s4;

/// The value axis: labels at the inline-start edge, the first (top) label on the top gridline, the last on the baseline. Numbers
/// are figures islands (Western digits, LTR); the axis never flips.
class GzChartYAxis extends StatelessWidget {
  const GzChartYAxis({required this.ticks, required this.format, required this.height, super.key});
  final List<double> ticks;
  final String Function(num) format;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height + gzAxisLabelLine,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final t in ticks.reversed)
              SizedBox(height: gzAxisLabelLine, child: Center(child: gzFigText(context, format(t), role: GzTextRole.figLabel, color: c.textSecondary))),
          ],
        ),
      ),
    );
  }
}

/// The explicit axis labels (caption, secondary): first at the inline-start, last at the inline-end, evenly spaced between.
class GzChartXAxis extends StatelessWidget {
  const GzChartXAxis({required this.labels, super.key});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final l in labels) GzText(l, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, softWrap: false)],
      ),
    );
  }
}

/// The three gridlines of a plot (hairline, the baseline one stronger), `count` evenly spaced from the top edge to the bottom.
void gzPaintGrid(Canvas canvas, Size size, GzColors c, {int count = 3}) {
  final p = Paint();
  for (var i = 0; i < count; i++) {
    final y = i * (size.height - GzStroke.hair) / (count - 1);
    p.color = i == count - 1 ? c.borderStrong : c.borderHairline;
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, GzStroke.hair), p);
  }
}

/// The y-axis column, a gap, then the plot column (top padded half a label line so labels centre on the end gridlines).
class GzChartPlotRow extends StatelessWidget {
  const GzChartPlotRow({required this.yAxis, required this.plot, required this.xAxis, this.padTop = 0, super.key});
  final Widget yAxis;
  final Widget plot;
  final Widget xAxis;
  final double padTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: padTop),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          yAxis,
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [plot, const SizedBox(height: GzSpace.s2), xAxis]),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------------------------------------------------- table

/// The table twin shown on request (`showTable`): caption, header row and one row per sample. Cells are LTR figures islands.
class GzChartTable extends StatelessWidget {
  const GzChartTable({required this.twin, super.key});
  final GzChartTwin twin;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget cell(String text, {bool figure = false}) => Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s2 + GzStroke.hair, end: GzSpace.s3), // the web cell border adds 1 to the row
          child: figure ? gzFigText(context, text, role: GzTextRole.figCaption, color: c.textPrimary) : GzText(GzBidi.isolateLtr(text), role: GzTextRole.caption),
        );
    final cols = twin.headers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
          child: GzText(twin.caption, role: GzTextRole.caption, color: c.textSecondary),
        ),
        Table(
          // CSS auto layout shares the free width in proportion to content: the longest cell (in characters) is the proxy.
          columnWidths: {
            for (var i = 0; i < cols; i++)
              i: FlexColumnWidth(
                [twin.headers[i], for (final r in twin.rows) if (i < r.length) r[i]].fold<int>(0, (a, t) => t.length > a ? t.length : a) * 7.0 + GzSpace.s3,
              ),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
          children: [
            TableRow(children: [for (final h in twin.headers) cell(h)]),
            for (final r in twin.rows)
              TableRow(children: [for (var i = 0; i < cols; i++) i < r.length ? cell(r[i], figure: i > 0 && r[i].isNotEmpty) : cell('')]),
          ],
        ),
      ],
    );
  }
}

/// The chart column: gap 12, secondary text colour, children stretched.
class GzChartColumn extends StatelessWidget {
  const GzChartColumn({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]]],
    );
  }
}

/// `Math.max` over a list of numbers (0 for none).
double gzMaxOf(Iterable<num> values) => values.fold<double>(0, (a, v) => math.max(a, v.toDouble()));

/// Re-exports the geometry helpers the chart files share.
typedef GzGeo = GzChartGeometry;
