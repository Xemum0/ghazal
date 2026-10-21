import 'package:flutter/widgets.dart';

import '../brand/brand.dart';
import '../core/gz_fig_text.dart';
import '../foundation.dart';
import 'gz_chart_geometry.dart';
import 'gz_chart_kit.dart';

/// A stage of a [GzFunnelBars].
class GzFunnelStage {
  const GzFunnelStage({required this.id, required this.label, required this.value});
  final String id;
  final String label;
  final num value;
}

/// An item of a [GzRankedBars].
class GzRankedItem {
  const GzRankedItem({required this.id, required this.label, required this.value, this.caption});
  final String id;
  final String label;
  final num value;
  final String? caption;
}

enum _BarRole { quiet, gold, lead }

/// One horizontal bar: a track (surface-quiet, 4 dp radius) and a fill that grows from the inline-start once.
class _HBar extends StatelessWidget {
  const _HBar({required this.share, required this.role, required this.height, required this.progress});
  final double share;
  final _BarRole role;
  final double height;
  final GzChartProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final fill = switch (role) {
      _BarRole.quiet => c.borderControl,
      _BarRole.gold => c.markKhayt,
      _BarRole.lead => c.textStrong,
    };
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(height: height, child: CustomPaint(painter: _HBarPainter(share.clamp(0, 1).toDouble(), fill, c.surfaceQuiet, rtl, progress.grow)));
  }
}

class _HBarPainter extends CustomPainter {
  _HBarPainter(this.share, this.fill, this.track, this.rtl, this.grow) : super(repaint: grow);
  final double share;
  final Color fill;
  final Color track;
  final bool rtl;
  final Animation<double> grow;
  final Paint _p = Paint();
  static const Radius _r = Radius.circular(GzRadius.xs);

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(Offset.zero & size, _r);
    canvas.drawRRect(box, _p..color = track);
    final w = size.width * share * grow.value;
    if (w <= 0) return;
    canvas.save();
    canvas.clipRRect(box);
    final rect = rtl ? Rect.fromLTWH(size.width - w, 0, w, size.height) : Rect.fromLTWH(0, 0, w, size.height);
    final endR = _r;
    canvas.drawRRect(
      RRect.fromRectAndCorners(rect, topLeft: rtl ? endR : Radius.zero, bottomLeft: rtl ? endR : Radius.zero, topRight: rtl ? Radius.zero : endR, bottomRight: rtl ? Radius.zero : endR),
      _p..color = fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HBarPainter old) => old.share != share || old.fill != fill || old.track != track || old.rtl != rtl;
}

Widget _head(BuildContext context, Widget label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Expanded(child: label),
      const SizedBox(width: GzSpace.s3),
      gzFigText(context, value, role: GzTextRole.priceStrong, color: context.gz.colors.textPrimary),
    ],
  );
}

/// Views, clicks, requests, confirmed: horizontal bars growing from the inline-start in proportion to the first stage; each row
/// prints its count in the figures voice and how much of the previous stage it kept. The last stage, the outcome, is the one gold
/// bar. Web `FunnelBars`.
class GzFunnelBars extends StatelessWidget {
  const GzFunnelBars({
    required this.stages,
    required this.formatValue,
    required this.formatStep,
    required this.title,
    required this.valueLabel,
    this.description,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  /// A stage never draws thinner than this share of the track, so the outcome stays visible next to a large first stage.
  static const double minShare = 0.02;

  final List<GzFunnelStage> stages;
  final String Function(num value) formatValue;

  /// `3.4% of clicks`: the step text, given the share (0-100, one decimal) and the previous stage's label.
  final String Function(double percent, String previousLabel) formatStep;
  final String title;
  final String? description;

  /// Table header for the count column.
  final String valueLabel;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final values = [for (final s in stages) s.value];
    final top = gzMaxOf(values) <= 0 ? 1.0 : gzMaxOf(values);
    final steps = [for (var i = 0; i < stages.length; i++) GzChartGeometry.stepPercent(values, i)];
    final twin = GzChartTwin(
      caption: title,
      headers: ['', valueLabel, ''],
      rows: [
        for (var i = 0; i < stages.length; i++) [stages[i].label, formatValue(stages[i].value), steps[i] == null ? '' : formatStep(steps[i]!, stages[i - 1].label)],
      ],
    );
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s4),
                  _head(context, GzText(stages[i].label, role: GzTextRole.bodyS), formatValue(stages[i].value)),
                  const SizedBox(height: GzSpace.s1),
                  _HBar(
                    share: GzChartGeometry.barShare(stages[i].value, top, min: minShare),
                    role: i == stages.length - 1 ? _BarRole.gold : _BarRole.quiet,
                    height: GzSpace.s3,
                    progress: p,
                  ),
                  if (steps[i] != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzText(formatStep(steps[i]!, stages[i - 1].label), role: GzTextRole.caption, color: c.textSecondary),
                  ],
                ],
              ],
            ),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}

/// The same horizontal bar as the funnel, ranked by count. The leader is ink-900 and says so with a gold bead; the rest are
/// ink-500. The name is a name (two lines before an ellipsis, ADR 0014 D8), the count sits at the inline-end in the figures voice.
/// Web `RankedBars`.
class GzRankedBars extends StatelessWidget {
  const GzRankedBars({
    required this.items,
    required this.formatValue,
    required this.title,
    required this.valueLabel,
    this.description,
    this.showTable = false,
    this.animate = true,
    super.key,
  });

  final List<GzRankedItem> items;
  final String Function(num value) formatValue;
  final String title;
  final String? description;
  final String valueLabel;
  final bool showTable;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final top = gzMaxOf([for (final s in items) s.value]) <= 0 ? 1.0 : gzMaxOf([for (final s in items) s.value]);
    final twin = GzChartTwin(caption: title, headers: ['', valueLabel], rows: [for (final s in items) [s.label, formatValue(s.value)]]);
    return GzChartSemantics(
      title: title,
      description: description,
      twin: twin,
      child: GzChartReveal(
        animate: animate,
        builder: (context, p) => GzChartColumn(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s4),
                  _head(
                    context,
                    Row(
                      children: [
                        if (i == 0) ...[const GzThreadBead(), const SizedBox(width: GzSpace.s2)],
                        Expanded(child: GzText(items[i].label, role: GzTextRole.bodyS, maxLines: 2)),
                      ],
                    ),
                    formatValue(items[i].value),
                  ),
                  const SizedBox(height: GzSpace.s1),
                  _HBar(share: GzChartGeometry.barShare(items[i].value, top), role: i == 0 ? _BarRole.lead : _BarRole.quiet, height: GzSpace.s2, progress: p),
                ],
              ],
            ),
            if (showTable) GzChartTable(twin: twin),
          ],
        ),
      ),
    );
  }
}
