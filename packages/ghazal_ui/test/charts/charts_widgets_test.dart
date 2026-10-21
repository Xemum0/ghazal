import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/charts/charts.dart';

import 'charts_harness.dart';

String _fmt(num v) => '${v.round()}';

GzLineChart _line({bool showTable = false}) => GzLineChart(
      title: 'Requests per day',
      description: 'Between 2 and 4.',
      formatAxis: _fmt,
      xLabel: (i) => ['First', 'Mid', 'Last'][i == 0 ? 0 : (i == 4 ? 2 : 1)],
      xLabels: 3,
      showTable: showTable,
      series: const [GzLineSeries(id: 'a', label: 'Requests', values: [2, 3, 4, 3, 4], area: true)],
    );

void main() {
  testWidgets('the chart is one semantics node: title, description and every row; the marks are excluded', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChart(
      tester,
      GzBarChart(
        title: 'Vouchers by week',
        description: 'Peak in week two.',
        seriesLabel: 'Vouchers',
        formatAxis: _fmt,
        bars: const [GzBar(id: 'a', label: 'W1', value: 41), GzBar(id: 'b', label: 'W2', value: 54, highlight: true)],
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Vouchers by week'));
    expect(node.value, contains('Peak in week two.'));
    expect(node.value, contains('W1: 41'));
    expect(node.value, contains('W2: 54'));
    expect(find.bySemanticsLabel('W1'), findsNothing, reason: 'axis labels are not separate nodes');
    handle.dispose();
  });

  testWidgets('sparkline names itself and states first and last values', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, const SizedBox(width: 170, child: GzSparkline(values: [1, 3, 2, 5], label: 'Views, 30 days', description: '1 to 5')));
    final node = tester.getSemantics(find.bySemanticsLabel('Views, 30 days'));
    expect(node.value, '1 to 5');
    handle.dispose();
  });

  testWidgets('time axis labels: first at the left in English, at the right in Arabic; the value axis never flips', (tester) async {
    await pumpChart(tester, _line());
    await tester.pumpAndSettle();
    double x(String t) => tester.getCenter(find.text(t)).dx;
    expect(x('First'), lessThan(x('Mid')));
    expect(x('Mid'), lessThan(x('Last')));
    final yEn = tester.getCenter(find.textContaining('4').first);
    expect(yEn.dx, lessThan(60), reason: 'the value axis is at the inline-start (left in English)');

    await pumpChart(tester, _line(), lang: 'ar');
    await tester.pumpAndSettle();
    expect(x('First'), greaterThan(x('Mid')));
    expect(x('Mid'), greaterThan(x('Last')));
    final yAr = tester.getCenter(find.textContaining('4').first);
    expect(yAr.dx, greaterThan(290), reason: 'the value axis is at the inline-start (right in Arabic)');
  });

  testWidgets('value axis reads top to bottom: max, mid, zero', (tester) async {
    await pumpChart(tester, _line());
    await tester.pumpAndSettle();
    double y(String t) => tester.getCenter(find.textContaining(t).first).dy;
    expect(y('4'), lessThan(y('2')));
    expect(y('2'), lessThan(y('0')));
  });

  testWidgets('bar chart labels every bar when there are 8 or fewer, else first, middle and last', (tester) async {
    await pumpChart(
      tester,
      GzBarChart(
        title: 't',
        seriesLabel: 's',
        formatAxis: _fmt,
        bars: [for (var i = 0; i < 5; i++) GzBar(id: '$i', label: 'L$i', value: i + 1)],
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(find.text('L$i'), findsOneWidget);
    }
    await pumpChart(
      tester,
      GzBarChart(
        title: 't',
        seriesLabel: 's',
        formatAxis: _fmt,
        bars: [for (var i = 0; i < 14; i++) GzBar(id: '$i', label: 'L$i', value: i + 1)],
      ),
    );
    expect(find.text('L0'), findsOneWidget);
    expect(find.text('L7'), findsOneWidget);
    expect(find.text('L13'), findsOneWidget);
    expect(find.text('L3'), findsNothing);
  });

  testWidgets('the table twin is shown on request and carries every value', (tester) async {
    await pumpChart(tester, _line(showTable: true));
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('Requests'), findsWidgets);
    await pumpChart(tester, _line());
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('the legend appears for more than one series and for hatched bars', (tester) async {
    await pumpChart(
      tester,
      GzLineChart(
        title: 't',
        formatAxis: _fmt,
        xLabel: (i) => 'd$i',
        series: const [
          GzLineSeries(id: 'a', label: 'Now', values: [1, 2, 3]),
          GzLineSeries(id: 'b', label: 'Before', values: [3, 2, 1], dashed: true),
        ],
      ),
    );
    expect(find.byType(GzChartLegend), findsOneWidget);
    expect(find.text('Before'), findsOneWidget);
    await pumpChart(tester, _line());
    expect(find.byType(GzChartLegend), findsNothing);
  });

  testWidgets('breakdown prints value and share per part (the legend, not colour alone)', (tester) async {
    await pumpChart(
      tester,
      GzBreakdownChart(
        title: 'Nights',
        formatValue: _fmt,
        formatShare: (s) => '$s%',
        segments: const [
          GzSegment(id: 'a', label: 'Booked', value: 9, tone: GzSegmentTone.strong),
          GzSegment(id: 'b', label: 'Hold', value: 29, tone: GzSegmentTone.gold, pattern: GzFillPattern.hatch),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('24%'), findsOneWidget);
    expect(find.textContaining('76%'), findsOneWidget);
  });

  testWidgets('funnel prints the step share; the first stage prints none', (tester) async {
    await pumpChart(
      tester,
      GzFunnelBars(
        title: 'Funnel',
        valueLabel: 'Count',
        formatValue: _fmt,
        formatStep: (p, prev) => '$p% of $prev',
        stages: const [
          GzFunnelStage(id: 'v', label: 'Views', value: 1296),
          GzFunnelStage(id: 'c', label: 'Clicks', value: 238),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('18.4% of Views'), findsOneWidget);
    expect(find.textContaining('of Clicks'), findsNothing);
  });

  group('animate in once', () {
    GzChartProgress? seen;
    Widget probe() => GzChartReveal(
          builder: (context, p) {
            seen = p;
            return const SizedBox(width: 10, height: 10);
          },
        );

    testWidgets('plays draw then fade over 480 + 320 ms and then stops asking for frames', (tester) async {
      await pumpChart(tester, probe());
      expect(seen!.grow.value, 0);
      await tester.pump(const Duration(milliseconds: 240));
      expect(seen!.grow.value, inExclusiveRange(0, 1));
      expect(seen!.fade.value, 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(seen!.grow.value, 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(seen!.fade.value, 1);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing loops');
    });

    testWidgets('reduced motion shows the finished chart on the first frame', (tester) async {
      await pumpChart(tester, probe(), reduceMotion: true);
      expect(seen!.grow.value, 1);
      expect(seen!.fade.value, 1);
    });

    testWidgets('animate: false shows the finished chart on the first frame', (tester) async {
      await pumpChart(tester, GzChartReveal(animate: false, builder: (context, p) {
        seen = p;
        return const SizedBox();
      }));
      expect(seen!.grow.value, 1);
    });
  });

  testWidgets('every chart sits in its own repaint boundary', (tester) async {
    await pumpChart(tester, const SizedBox(width: 170, child: GzSparkline(values: [1, 2, 3], label: 's')));
    expect(find.descendant(of: find.byType(GzSparkline), matching: find.byType(RepaintBoundary)), findsWidgets);
  });
}
