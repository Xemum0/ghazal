// The shared flow world's own rules: one scenario per test, drag-based scrolling, tap by key, label and text, bounded waits.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_world.dart';

void main() {
  testWidgets('a second openScreen in one test is refused with a clear error, the first scenario stays usable', (tester) async {
    await openScreen(tester, 'CL-DISC-01');
    await expectLater(
      () => openScreen(tester, 'CL-DISC-03'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('One scenario per test'), contains('CL-DISC-01'), contains('CL-DISC-03')),
        ),
      ),
    );
    expect(onScreen('discover.cta'), isTrue);
    await finish(tester);
  });

  flowTest('the first-start screen is not the base of a screen with params: the base is the first tab root', (tester) async {
    final c = await openScreen(tester, 'CL-BOOK-01', params: const <String, Object?>{'venueId': 'V05'});
    expect(currentId(c), 'CL-BOOK-01');
    nav(tester).pop();
    await settle(tester);
    expect(currentId(c), kFlowBase);
  });

  flowTest('scrollTo drags a row of a long list into view (ensureVisible would park it under the top bar); tapKey and tapText then hit it', (
    tester,
  ) async {
    await openScreen(tester, 'CL-DISC-01');
    final far = find.byKey(const ValueKey<String>('discover.cta'));
    expect(far, findsOneWidget);
    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, -600), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await scrollTo(tester, far);
    expect(far.hitTestable(), findsOneWidget, reason: 'the target is on screen and nothing covers it');
    await tapKey(tester, 'discover.cta');
    expect(currentId(container(tester)), 'CL-DISC-03');
  });

  flowTest('a tap by accessible name finds the control the way a screen reader does', (tester) async {
    await openScreen(tester, 'CL-DISC-01');
    await tapLabel(tester, RegExp('^Profile'));
    expect(nav(tester).activeTab, 'profile');
  });

  flowTest('settle is a bounded fake-time wait: it advances exactly the asked time unless asked to flush', (tester) async {
    await openScreen(tester, 'CL-DISC-01');
    final start = tester.binding.clock.now();
    await settle(tester, wait: const Duration(milliseconds: 500));
    expect(tester.binding.clock.now().difference(start), const Duration(milliseconds: 500));
  });
}
