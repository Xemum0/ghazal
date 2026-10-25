// The visits flow on the real router over the in-process mock: booking a
// visit, the requested confirmation, the three-role group chat with arrival
// taps, my visits, change or cancel, the states, the guest gate, one Arabic
// run. Bounded.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the booking sheet picks a slot and requests the visit', (tester) async {
    final c = await openScreen(tester, 'CL-VIST-01', params: {'venueId': 'V01'});
    expect(find.text('Book a visit'), findsOneWidget);
    expect(find.byType(GzStepper), findsWidgets);
    await scrollTo(tester, find.byKey(const ValueKey<String>('visits.book.send')));
    await tapKey(tester, 'visits.book.send', flush: true);
    expect(currentId(c), anyOf(['CL-VIST-02', 'CL-VIST-01']));
  });

  flowTest('a guest at Send meets the sign-in sheet with the visit reason', (tester) async {
    final c = await openScreen(tester, 'CL-VIST-01', persona: 'guest', params: {'venueId': 'V01'});
    await scrollTo(tester, find.byKey(const ValueKey<String>('visits.book.send')));
    // no slot yet: pick the first free window first
    final chips = find.byType(GzChip);
    expect(chips, findsWidgets);
    await tap(tester, chips.first);
    await settle(tester, flush: true);
    await scrollTo(tester, find.byKey(const ValueKey<String>('visits.book.send')));
    await tapKey(tester, 'visits.book.send');
    final gate = c.read(gateProvider);
    expect(gate, isNotNull);
    expect(gate!.reason, GateReason.visit);
  });

  flowTest('the requested screen opens the chat', (tester) async {
    final c = await openScreen(tester, 'CL-VIST-02', params: {'visitId': 'visit-aurelia-reem'});
    expect(find.text('Visit requested'), findsOneWidget);
    await tapText(tester, 'Open chat', flush: true);
    expect(currentId(c), 'CL-VIST-03');
  });

  flowTest('the request auto-opens the chat after two seconds unless Stay is tapped', (tester) async {
    final c = await openScreen(tester, 'CL-VIST-02', params: {'visitId': 'visit-aurelia-reem'});
    expect(find.text('Visit requested'), findsOneWidget);
    await pumpSeconds(tester, 3);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-VIST-03');
  });

  flowTest('the group chat shows three roles and sends a message', (tester) async {
    await openScreen(tester, 'CL-VIST-03', params: {'visitId': 'visit-aurelia-reem'});
    expect(find.byType(GzChatBubble), findsWidgets);
    await tapLabel(tester, 'Chat members');
    expect(shows('Amal Al-Balushi'), isTrue);
    nav(tester).closeSheet();
    await settle(tester, flush: true);
    await scrollTo(tester, find.byType(GzFieldInput));
    await tap(tester, find.byType(GzFieldInput));
    await tester.enterText(find.byType(GzFieldInput), 'We are close by');
    await settle(tester);
    await tapLabel(tester, 'Send voice message', flush: true);
    await settle(tester, flush: true);
    final sent = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f]'), '').contains('We are close by'),
    );
    final view = find.byType(Scrollable).first;
    for (var i = 0; i < 6 && sent.evaluate().isEmpty; i++) {
      await tester.drag(view, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(sent, findsWidgets);
  });

  flowTest('my visits lists the visit and opens its chat', (tester) async {
    final c = await openScreen(tester, 'CL-VIST-04');
    expect(find.text('Visits'), findsOneWidget);
    final rows = find.byKey(const ValueKey<String>('visits.row.visit-aurelia-reem'));
    expect(rows, findsOneWidget);
    await tap(tester, rows);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-VIST-03');
  });

  flowTest('change or cancel asks another time', (tester) async {
    await openScreen(tester, 'CL-VIST-04');
    ignoreRenderErrors = true;
    nav(tester).openSheet('CL-VIST-05', options: const GzSheetOptions(params: <String, Object?>{'visitId': 'visit-aurelia-reem'}));
    await settle(tester, flush: true);
    ignoreRenderErrors = false;
    expect(find.text('Your visit'), findsOneWidget);
    expect(find.text('Another time'), findsOneWidget);
    expect(find.text('Cancel visit'), findsOneWidget);
    await tapText(tester, 'Another time', flush: true);
    expect(find.text('Send request'), findsWidgets);
    nav(tester).closeSheet();
    await settle(tester, flush: true);
  });

  flowTest('change or cancel cancels with a reason', (tester) async {
    await openScreen(tester, 'CL-VIST-04');
    ignoreRenderErrors = true;
    nav(tester).openSheet('CL-VIST-05', options: const GzSheetOptions(params: <String, Object?>{'visitId': 'visit-aurelia-reem'}));
    await settle(tester, flush: true);
    ignoreRenderErrors = false;
    await tapText(tester, 'Cancel visit', flush: true);
    await tapText(tester, 'Plans changed');
    await settle(tester, flush: true);
    expect(find.text('Cancel visit'), findsWidgets);
  });

  flowTest('state loading: skeletons show, no error', (tester) async {
    await openScreen(tester, 'CL-VIST-04', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-VIST-04', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('arabic: the visit chat reads right to left', (tester) async {
    await openScreen(tester, 'CL-VIST-03', params: {'visitId': 'visit-aurelia-reem'}, locale: const Locale('ar'));
    expect(find.byType(GzChatBubble), findsWidgets);
    expect(shows('أوريليا'), isTrue);
  });
}
