import 'dart:math' as math;
import 'dart:ui';

/// The pure geometry of the charts (scales, ticks, label indexes, path points, bar rects, donut arcs). No widgets, no paint:
/// the painters call these once per layout and the tests pin them with golden values (they mirror `internal/kit.tsx`, `Sparkline`,
/// `LineChart`, `BarChart` and `BreakdownChart` of the web system).
abstract final class GzChartGeometry {
  /// `Math.round(v * 10) / 10`: the web rounds every drawn coordinate to a tenth of a px.
  static double round1(double v) => (v * 10).roundToDouble() / 10;

  /// The next round step (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 x 10^n) at or above [raw]: ticks read 0 / 30 / 60, never 0 / 50 / 100 for a
  /// 54 maximum.
  static double niceCeil(double raw) {
    if (raw <= 0) return 1;
    var pow = 1.0;
    while (pow * 10 <= raw) {
      pow *= 10;
    }
    while (pow > raw) {
      pow /= 10;
    }
    final f = raw / pow;
    const steps = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0];
    final step = steps.firstWhere((m) => f <= m, orElse: () => 10);
    return step * pow;
  }

  /// Three value-axis ticks `[0, step, 2 x step]`; [GzTicks.max] is the last tick, so the tallest value always fits.
  static GzTicks niceTicks(num dataMax) {
    final step = niceCeil(math.max(dataMax.toDouble(), 1) / 2);
    return GzTicks([0, step, step * 2], step * 2);
  }

  /// Evenly spaced sample indexes for the explicit axis labels (first and last always included).
  static List<int> labelIndexes(int count, int labels) {
    if (count <= 1) return const [0];
    final k = math.max(2, math.min(labels, count));
    return [for (var i = 0; i < k; i++) ((i * (count - 1)) / (k - 1)).round()];
  }

  /// x of the [i]-th of [n] points between [x0] and [x1]; time runs in reading direction, so [rtl] puts the first point at [x1].
  static double pointX(int i, int n, double x0, double x1, {required bool rtl, bool lastWhenSingle = false}) {
    final t = n <= 1 ? (lastWhenSingle ? 1.0 : 0.0) : i / (n - 1);
    return round1(x0 + (x1 - x0) * (rtl ? 1 - t : t));
  }

  /// y of [v] on a plot of [height] whose top is [max].
  static double valueY(num v, double max, double height) => round1(height - (v / max) * height);

  /// The sparkline points: the bead needs [bead] at both ends, the line leaves [pad] / 2 at the top and bottom.
  static List<Offset> sparkPoints(List<num> values, double width, double height, {required bool rtl, required double bead, required double pad}) {
    final n = values.length;
    if (n == 0) return const [];
    var lo = values.first.toDouble();
    var hi = lo;
    for (final v in values) {
      lo = math.min(lo, v.toDouble());
      hi = math.max(hi, v.toDouble());
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final x0 = bead;
    final x1 = math.max(bead, width - bead);
    final y0 = pad / 2;
    final y1 = math.max(pad, height - pad / 2);
    return [
      for (var i = 0; i < n; i++)
        Offset(pointX(i, n, x0, x1, rtl: rtl, lastWhenSingle: true), round1(y1 - ((values[i] - lo) / span) * (y1 - y0))),
    ];
  }

  /// The line chart points of one series (x on the shared [n] samples, y on the shared [max]).
  static List<Offset> linePoints(List<num> values, int n, double width, double height, double max, {required bool rtl, required double pad}) => [
        for (var i = 0; i < values.length; i++) Offset(pointX(i, n, pad, width - pad, rtl: rtl), valueY(values[i], max, height)),
      ];

  /// The bar rects (plot coordinates, physical left to right): equal slots separated by [gap]; a bar is [barWidth] wide and
  /// centred in its slot, or the whole slot when [barWidth] is null (dense). The first bar is at the right edge in [rtl]. A bar is
  /// never thinner than [minHeight].
  static List<Rect> barRects(List<num> values, double max, double width, double height, {required double gap, double? barWidth, required bool rtl, double minHeight = 2}) {
    final n = values.length;
    if (n == 0) return const [];
    final slot = (width - gap * (n - 1)) / n;
    final bw = barWidth ?? slot;
    return [
      for (var i = 0; i < n; i++)
        () {
          final h = math.max(minHeight, (values[i] / max * height).roundToDouble());
          final left = (rtl ? n - 1 - i : i) * (slot + gap) + (slot - bw) / 2;
          return Rect.fromLTWH(left, height - h, bw, h);
        }(),
    ];
  }

  /// Widths of flex segments: [available] shared in proportion to [values] after [gap] between the [values].length segments.
  static List<double> segmentWidths(List<num> values, double available, double gap) {
    final total = values.fold<double>(0, (a, v) => a + v);
    if (values.isEmpty || total <= 0) return const [];
    final free = available - gap * (values.length - 1);
    return [for (final v in values) free * v / total];
  }

  /// Donut arcs in percent of the circle: `(start, length)` per positive value, the drawn length leaves [gap] percent before the
  /// next part (the web dash array on `pathLength=100`).
  static List<GzArcSpan> donutArcs(List<num> values, {double gap = 1.2}) {
    final total = values.fold<double>(0, (a, v) => a + v);
    if (total <= 0) return const [];
    var cursor = 0.0;
    final out = <GzArcSpan>[];
    for (final v in values) {
      if (v <= 0) continue;
      final len = v / total * 100;
      out.add(GzArcSpan(cursor, math.max(0, len - gap)));
      cursor += len;
    }
    return out;
  }

  /// Radians for a percent of the circle, from 12 o'clock, clockwise (never mirrored: a donut is circular).
  static double percentToRadians(double percent) => -math.pi / 2 + percent / 100 * 2 * math.pi;

  /// A horizontal bar's share of its track: `value / top`, never thinner than [min] when [min] is given (the funnel's last stage).
  static double barShare(num value, num top, {double min = 0}) => math.max(top <= 0 ? 0.0 : value / top, min);

  /// How much of the previous stage a funnel stage kept, in percent with one decimal; null for the first stage or an empty previous.
  static double? stepPercent(List<num> values, int i) {
    if (i <= 0 || i >= values.length || values[i - 1] <= 0) return null;
    return (values[i] / values[i - 1] * 1000).roundToDouble() / 10;
  }

  /// The share text input of a breakdown part: `round(value / total x 100)`.
  static int sharePercent(num value, num total) => (value / (total == 0 ? 1 : total) * 100).round();
}

/// The three value-axis ticks and the last of them (the plot's top).
class GzTicks {
  const GzTicks(this.ticks, this.max);
  final List<double> ticks;
  final double max;
}

/// A donut part: start and length in percent of the circle.
class GzArcSpan {
  const GzArcSpan(this.start, this.length);
  final double start;
  final double length;
}
