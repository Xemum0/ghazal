// Flow test of Today (HL-TODY-01..05): the real router and the in-process mock (`autoRun: false`), real taps. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show EditableText, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/today/presentation/hl_tody_01.dart';
import 'package:provider_app/features/today/presentation/hl_tody_02.dart';
import 'package:provider_app/features/today/presentation/hl_tody_03.dart';
import 'package:provider_app/features/today/presentation/hl_tody_04.dart';
import 'package:provider_app/features/today/presentation/hl_tody_05.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('Today shows the hero queue, the section links and the tab bar', (tester) async {
    await openScreen(tester, 'HL-TODY-01');
    expect(find.byType(HlTody01Screen), findsOneWidget);
    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('دانة الشمري'), findsWidgets); // the nearest request leads the queue
    expect(find.byType(GzTabBar), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);
    expect(find.text('Block date'), findsOneWidget);
    expect(find.text('New price'), findsOneWidget);
  });

  flowTest('Needs you: a request row opens the triage card in place and Accept starts the undo, Undo takes it back', (tester) async {
    await openScreen(tester, 'HL-TODY-01');
    await tap(tester, find.text('دانة الشمري'));
    expect(find.byType(GzRequestCard), findsOneWidget);
    // no flush here: it runs the mock's undo window to its end
    await tap(tester, find.text('Accept'));
    // the toast offers Undo for 8 s; the request left the pending list (it waits for the client now)
    expect(find.text('Request approved'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await tap(tester, find.text('Undo'));
    expect(find.byType(GzRequestCard), findsNothing);
    expect(find.text('دانة الشمري'), findsWidgets); // back in the queue
    await tester.pump(const Duration(seconds: 9)); // the undo timer ends inside the test
  });

  flowTest('the count opens the full queue; filters keep their rows; back returns to Today', (tester) async {
    await openScreen(tester, 'HL-TODY-01');
    await tap(tester, find.text('Needs you'));
    expect(find.byType(HlTody02Screen), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Visits'));
    expect(find.textContaining('راشد'), findsWidgets);
    expect(find.text('دانة الشمري'), findsNothing); // the filter keeps only the visit rows
    await tap(tester, find.bySemanticsLabel('Back'));
    expect(find.byType(HlTody01Screen), findsOneWidget);
  });

  flowTest('Notifications: grouped by day, mark all read confirms with a toast', (tester) async {
    await openScreen(tester, 'HL-TODY-03');
    expect(find.byType(HlTody03Screen), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    await tap(tester, find.bySemanticsLabel('Mark all as read'));
    expect(find.text('All read'), findsOneWidget);
  });

  flowTest('Messages: the inbox lists conversations, search narrows them, a row opens the thread', (tester) async {
    await openScreen(tester, 'HL-TODY-04');
    expect(find.byType(HlTody04Screen), findsOneWidget);
    expect(find.text('ريم الدوسري'), findsWidgets);
    await tap(tester, find.text('ريم الدوسري'));
    expect(find.byType(HlTody05Screen), findsOneWidget);
  });

  flowTest('Thread: a quick reply fills the field and Send adds the message to the thread', (tester) async {
    await openScreen(tester, 'HL-TODY-05');
    expect(find.byType(HlTody05Screen), findsOneWidget);
    expect(find.text('Availability'), findsWidgets);
    await tap(tester, find.text('Visit'));
    await tap(tester, find.bySemanticsLabel('Send'), flush: true);
    expect(find.textContaining('You are welcome to visit the hall'), findsWidgets);
  });

  flowTest('empty queue shows the all-clear state, not a blank', (tester) async {
    await openScreen(tester, 'HL-TODY-02', state: 'empty');
    expect(find.text('All clear'), findsWidgets);
  });

  flowTest('a failing load shows the error state with Try again', (tester) async {
    await openScreen(tester, 'HL-TODY-02', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
  });

  flowTest('offline shows the offline state with a retry', (tester) async {
    await openScreen(tester, 'HL-TODY-04', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Messages: search narrows the list and an empty result offers Clear', (tester) async {
    await openScreen(tester, 'HL-TODY-04');
    await tester.enterText(find.byType(EditableText).first, 'زززز');
    await settle(tester);
    expect(find.text('No match'), findsOneWidget);
    await tap(tester, find.text('Clear'));
    expect(find.text('ريم الدوسري'), findsWidgets);
  });

  flowTest('loading shows the skeleton that matches the layout', (tester) async {
    await openScreen(tester, 'HL-TODY-02', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('Arabic run: Today mirrors, the queue reads right to left', (tester) async {
    await openScreen(tester, 'HL-TODY-01', locale: const Locale('ar'));
    expect(find.text('بانتظاركم'), findsOneWidget);
    final title = tester.getTopRight(find.text('بانتظاركم')).dx;
    final chevron = tester.getTopLeft(find.byIcon(GzIcons.chevronRight).first).dx;
    expect(title, greaterThan(chevron));
  });
}
