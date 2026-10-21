import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/charts/charts.dart';

void main() {
  group('ticks and labels (golden values, same as the web kit)', () {
    test('niceTicks lands on round numbers and the last tick is the plot top', () {
      expect(GzChartGeometry.niceTicks(54).ticks, [0, 30, 60]);
      expect(GzChartGeometry.niceTicks(54).max, 60);
      expect(GzChartGeometry.niceTicks(4).ticks, [0, 2, 4]);
      expect(GzChartGeometry.niceTicks(1296).ticks, [0, 800, 1600]);
      expect(GzChartGeometry.niceTicks(130).ticks, [0, 80, 160]);
      expect(GzChartGeometry.niceTicks(0).ticks, [0, 0.5, 1]);
    });

    test('niceCeil is exact on powers of ten', () {
      expect(GzChartGeometry.niceCeil(1000), 1000);
      expect(GzChartGeometry.niceCeil(1), 1);
      expect(GzChartGeometry.niceCeil(2.6), 3);
      expect(GzChartGeometry.niceCeil(0), 1);
    });

    test('labelIndexes always include the first and last sample', () {
      expect(GzChartGeometry.labelIndexes(30, 3), [0, 15, 29]);
      expect(GzChartGeometry.labelIndexes(14, 3), [0, 7, 13]);
      expect(GzChartGeometry.labelIndexes(2, 3), [0, 1]);
      expect(GzChartGeometry.labelIndexes(1, 3), [0]);
    });
  });

  group('points', () {
    test('pointX runs in reading direction: the first sample is at the right edge in rtl', () {
      expect(GzChartGeometry.pointX(0, 5, 8, 108, rtl: false), 8);
      expect(GzChartGeometry.pointX(4, 5, 8, 108, rtl: false), 108);
      expect(GzChartGeometry.pointX(0, 5, 8, 108, rtl: true), 108);
      expect(GzChartGeometry.pointX(4, 5, 8, 108, rtl: true), 8);
      expect(GzChartGeometry.pointX(2, 5, 8, 108, rtl: false), 58);
    });

    test('valueY puts the maximum on the top edge and zero on the baseline', () {
      expect(GzChartGeometry.valueY(60, 60, 160), 0);
      expect(GzChartGeometry.valueY(0, 60, 160), 160);
      expect(GzChartGeometry.valueY(30, 60, 160), 80);
    });

    test('sparkPoints keep the bead room, mirror in rtl and round to a tenth', () {
      final ltr = GzChartGeometry.sparkPoints([0, 10], 100, 32, rtl: false, bead: 8, pad: 8);
      expect(ltr, [const Offset(8, 28), const Offset(92, 4)]);
      final rtl = GzChartGeometry.sparkPoints([0, 10], 100, 32, rtl: true, bead: 8, pad: 8);
      expect(rtl, [const Offset(92, 28), const Offset(8, 4)]);
      final flat = GzChartGeometry.sparkPoints([5, 5, 5], 100, 32, rtl: false, bead: 8, pad: 8);
      expect(flat.map((p) => p.dy).toSet().length, 1, reason: 'a constant series is a straight line');
      expect(GzChartGeometry.round1(12.345), 12.3);
    });

    test('linePoints share the sample count and the axis maximum across series', () {
      final pts = GzChartGeometry.linePoints([0, 2, 4], 3, 108, 100, 4, rtl: false, pad: 8);
      expect(pts, [const Offset(8, 100), const Offset(54, 50), const Offset(100, 0)]);
    });
  });

  group('bars, segments, donut, funnel', () {
    test('barRects centre a 24 wide bar in its slot; the first bar is at the right edge in rtl', () {
      final ltr = GzChartGeometry.barRects([2, 4], 4, 100, 80, gap: 8, barWidth: 24, rtl: false);
      expect(ltr[0], const Rect.fromLTWH(11, 40, 24, 40));
      expect(ltr[1], const Rect.fromLTWH(65, 0, 24, 80));
      final rtl = GzChartGeometry.barRects([2, 4], 4, 100, 80, gap: 8, barWidth: 24, rtl: true);
      expect(rtl[0], const Rect.fromLTWH(65, 40, 24, 40));
      expect(rtl[1], const Rect.fromLTWH(11, 0, 24, 80));
    });

    test('a bar is never thinner than the minimum and a dense bar fills its slot', () {
      final r = GzChartGeometry.barRects([0, 4], 4, 100, 80, gap: 4, rtl: false, minHeight: 2);
      expect(r[0].height, 2);
      expect(r[0].width, 48);
    });

    test('segmentWidths share the width after the gaps', () {
      expect(GzChartGeometry.segmentWidths([1, 3], 102, 2), [25, 75]);
      expect(GzChartGeometry.segmentWidths([], 100, 2), isEmpty);
    });

    test('donutArcs start at 12 o\'clock, skip empty parts and leave the gap', () {
      final arcs = GzChartGeometry.donutArcs([29, 0, 1, 70]);
      expect(arcs.length, 3);
      expect(arcs[0].start, 0);
      expect(arcs[0].length, closeTo(27.8, 1e-9));
      expect(arcs[1].start, closeTo(29, 1e-9));
      expect(arcs[1].length, 0, reason: 'a 1 percent part is thinner than the gap');
      expect(arcs[2].start, closeTo(30, 1e-9));
      expect(GzChartGeometry.percentToRadians(0), closeTo(-1.5707963267948966, 1e-12));
      expect(GzChartGeometry.percentToRadians(25), closeTo(0, 1e-12));
    });

    test('funnel steps and shares', () {
      expect(GzChartGeometry.stepPercent([1296, 238, 41], 0), isNull);
      expect(GzChartGeometry.stepPercent([1296, 238, 41], 1), 18.4);
      expect(GzChartGeometry.stepPercent([1296, 238, 41], 2), 17.2);
      expect(GzChartGeometry.stepPercent([0, 5], 1), isNull);
      expect(GzChartGeometry.barShare(9, 1296, min: 0.02), 0.02);
      expect(GzChartGeometry.barShare(648, 1296), 0.5);
      expect(GzChartGeometry.sharePercent(9, 38), 24);
    });
  });
}
