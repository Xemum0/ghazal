import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate;
import 'package:ghazal_ui/src/client/client_c.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'client_c_fixtures.dart';

final _today = LocalDate.parse('2026-11-16');

void main() {
  setUpAll(loadUiFonts);

  group('GzChecklistProgress', () {
    testWidgets('says "2 of 9 done" and one image node', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, const SizedBox(width: 350, child: GzChecklistProgress(done: 2, total: 9)));
      expect(find.textContaining('2'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Checklist progress: 2 of 9 done')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the gold fill is the share done of the 350 dp track, zero total does not throw', (tester) async {
      await pumpCore(tester, const SizedBox(width: 350, child: GzChecklistProgress(done: 1, total: 4)));
      final boxes = tester.widgetList<Expanded>(find.byType(Expanded)).where((e) => e.flex == 250 || e.flex == 750).toList();
      expect(boxes.map((e) => e.flex).toSet(), {250, 750});
      await pumpCore(tester, const SizedBox(width: 350, child: GzChecklistProgress(done: 0, total: 0)));
      expect(tester.takeException(), isNull);
    });
  });

  group('GzChecklistItem', () {
    testWidgets('tapping the box asks to tick; a done item asks to untick', (tester) async {
      final calls = <bool>[];
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(), today: _today, onToggle: calls.add)));
      await tester.tap(find.byType(GzPressable).first);
      expect(calls, [true]);
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(done: true, doneAt: '2026-11-12T16:00:00+03:00'), today: _today, onToggle: calls.add)));
      await tester.tap(find.byType(GzPressable).first);
      expect(calls, [true, false]);
    });

    testWidgets('a task the system completes shows a lock and cannot be ticked by hand', (tester) async {
      final calls = <bool>[];
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(auto: true, due: null, category: null), today: _today, onToggle: calls.add)));
      expect(find.text('Completes when your booking is confirmed'), findsOneWidget);
      expect(find.byIcon(GzIcons.lock), findsOneWidget);
      await tester.tap(find.byType(GzPressable).first);
      expect(calls, isEmpty);
    });

    testWidgets('overdue says so in words with a glyph; a future date says Due', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(due: '2026-11-15'), today: _today)));
      expect(find.textContaining('Overdue since'), findsOneWidget);
      expect(find.byIcon(GzIcons.warningCircle), findsOneWidget);
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(due: '2026-11-19'), today: _today)));
      expect(find.textContaining('Due'), findsOneWidget);
      expect(find.byIcon(GzIcons.warningCircle), findsNothing);
    });

    testWidgets('the trailing action opens the category; hidden when done; row is 64 and the box target 44', (tester) async {
      var opened = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(), today: _today, onChoose: () => opened++, actionLabel: 'Photography')));
      expect(tester.getSize(find.byType(GzChecklistItem)).height, greaterThanOrEqualTo(64));
      expect(tester.getSize(find.byType(GzPressable).first), const Size(44, 44));
      await tester.tap(find.byType(GzIconButton));
      expect(opened, 1);
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(done: true), today: _today, onChoose: () => opened++)));
      expect(find.byType(GzIconButton), findsNothing);
    });

    testWidgets('the box sits at inline-start: left in English, right in Arabic', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(), today: _today)), size: const Size(350, 800));
      expect(tester.getTopLeft(find.byType(GzPressable).first).dx, 0);
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(), today: _today)), lang: 'ar', size: const Size(350, 800));
      expect(tester.getTopRight(find.byType(GzPressable).first).dx, 350);
    });

    testWidgets('semantics: one checkbox node with the task as its name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, SizedBox(width: 350, child: GzChecklistItem(item: checkItem(done: true), today: _today)));
      expect(find.bySemanticsLabel(RegExp('Photographer')), findsWidgets);
      handle.dispose();
    });
  });

  group('GzBudgetSummary', () {
    testWidgets('shows the total, three stats and category rows; no alert while inside the budget', (tester) async {
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzBudgetSummary(budget: budget()))), size: const Size(390, 1600));
      expect(find.text('Wedding budget'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Committed'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Category venue_catering'), findsOneWidget);
      expect(find.textContaining('Linked to your booking'), findsOneWidget);
      expect(find.byIcon(GzIcons.warningCircle), findsNothing);
    });

    testWidgets('a category over its share raises the alert in words, with the over amount on the row', (tester) async {
      final over = budget(categories: [budgetCategory('flowers_decor', allocated: 6000000, paid: 4920000, committed: 1600000)]);
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzBudgetSummary(budget: over))), size: const Size(390, 1600));
      expect(find.textContaining('is over its share of the budget'), findsOneWidget);
      expect(find.textContaining('Over by'), findsOneWidget);
    });

    testWidgets('plans above the total budget say so, in Arabic too', (tester) async {
      final over = budget(total: 6000000, categories: [budgetCategory('venue_catering', allocated: 32000000, committed: 15400000)]);
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzBudgetSummary(budget: over))), size: const Size(390, 1600), lang: 'ar');
      expect(find.text('خططكم أعلى من إجمالي الميزانية.'), findsOneWidget);
    });
  });
}
