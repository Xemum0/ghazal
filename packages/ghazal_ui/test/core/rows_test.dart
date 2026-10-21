import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'core_harness.dart';

BoxDecoration _rowDecoration(WidgetTester tester) {
  final box = tester.widgetList<Container>(find.descendant(of: find.byType(GzListRow), matching: find.byType(Container))).firstWhere((c) => c.constraints != null && c.decoration is BoxDecoration);
  return box.decoration! as BoxDecoration;
}

void main() {
  group('flush rows are square', () {
    testWidgets('GzListRow: an interactive row keeps the control radius, a flush one has radius 0 so the hairline runs straight', (tester) async {
      await pumpCore(tester, SizedBox(width: 390, child: GzListRow(title: 'Date', onPressed: () {})));
      expect(_rowDecoration(tester).borderRadius, GzRadius.smAll);
      await pumpCore(tester, SizedBox(width: 390, child: GzListRow(title: 'Date', flush: true, onPressed: () {})));
      expect(_rowDecoration(tester).borderRadius, isNull);
      // flush also drops the gutter inside the row: the title starts at the row edge
      expect(tester.getTopLeft(find.text('Date')).dx, 0);
    });

    testWidgets('GzIconListRow passes flush through (square, no gutter), and the pressed fill is square too', (tester) async {
      await pumpCore(tester, SizedBox(width: 390, child: GzIconListRow(title: 'Guests', icon: GzIcons.user, flush: true, onPressed: () {})));
      expect(_rowDecoration(tester).borderRadius, isNull);
      final pressable = tester.widget<GzPressable>(find.byType(GzPressable).first);
      expect(pressable.borderRadius, isNull);
      expect(tester.getSize(find.byType(GzPressable).first).width, 390);
    });

    testWidgets('a non-interactive row has no radius either way', (tester) async {
      await pumpCore(tester, const SizedBox(width: 390, child: GzListRow(title: 'Date')));
      expect(_rowDecoration(tester).borderRadius, isNull);
    });
  });

  group('GzStruckMoney', () {
    // 18,200 KD in fils; the web Review prints `KD 18,200.000` in English and the figure before the currency in Arabic.
    const fils = 18200000;

    Rect rectOfText(WidgetTester tester, bool Function(String) match) {
      final t = tester.widgetList<Text>(find.descendant(of: find.byType(GzStruckMoney), matching: find.byType(Text))).firstWhere((w) => match(w.data ?? ''));
      return tester.getRect(find.byWidget(t));
    }

    testWidgets('English, exact mode: currency then three decimals, struck through, spoken as the label given', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, const GzStruckMoney(fils: fils, mode: GzMoneyMode.exact, semanticLabel: 'Standard price'));
      expect(find.textContaining('18,200.000'), findsOneWidget);
      final cur = rectOfText(tester, (t) => t == 'KD');
      final fig = rectOfText(tester, (t) => t.contains('18,200.000'));
      expect(cur.right, lessThanOrEqualTo(fig.left));
      for (final t in tester.widgetList<Text>(find.descendant(of: find.byType(GzStruckMoney), matching: find.byType(Text)))) {
        expect(t.style?.decoration, TextDecoration.lineThrough);
      }
      expect(find.bySemanticsLabel('Standard price'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('browse mode drops a zero fraction, exact keeps it', (tester) async {
      await pumpCore(tester, const GzStruckMoney(fils: fils));
      expect(find.textContaining('18,200.000'), findsNothing);
      expect(find.textContaining('18,200'), findsOneWidget);
    });

    testWidgets('Arabic: the Money order puts the currency first by default; arabicFigureFirst puts the figure first, then the currency', (tester) async {
      await pumpCore(tester, const GzStruckMoney(fils: fils, mode: GzMoneyMode.exact), lang: 'ar');
      var cur = rectOfText(tester, (t) => t.contains('د.ك'));
      var fig = rectOfText(tester, (t) => t.contains('18,200.000'));
      expect(cur.right, lessThanOrEqualTo(fig.left));
      await pumpCore(tester, const GzStruckMoney(fils: fils, mode: GzMoneyMode.exact, arabicFigureFirst: true), lang: 'ar');
      cur = rectOfText(tester, (t) => t.contains('د.ك'));
      fig = rectOfText(tester, (t) => t.contains('18,200.000'));
      expect(fig.right, lessThanOrEqualTo(cur.left));
      // English ignores the flag
      await pumpCore(tester, const GzStruckMoney(fils: fils, mode: GzMoneyMode.exact, arabicFigureFirst: true));
      cur = rectOfText(tester, (t) => t == 'KD');
      fig = rectOfText(tester, (t) => t.contains('18,200.000'));
      expect(cur.right, lessThanOrEqualTo(fig.left));
    });
  });
}
