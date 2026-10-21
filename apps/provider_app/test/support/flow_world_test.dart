// The partner flow world mirrors the client one: one scenario per test, tap by text and by accessible name, a base page for params.
import 'package:flutter_test/flutter_test.dart';

import 'flow_world.dart';

void main() {
  testWidgets('a second openScreen in one test is refused with a clear error', (tester) async {
    await openScreen(tester, 'HL-TODY-01');
    await expectLater(
      () => openScreen(tester, 'HL-BOOK-01'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('One scenario per test'), contains('HL-TODY-01'), contains('HL-BOOK-01')),
        ),
      ),
    );
    await finish(tester);
  });

  flowTest('a signed-out person opening a tab screen lands on access; Sign in is found by its text', (tester) async {
    final c = await openScreen(tester, 'HL-TODY-01', persona: 'guest');
    expect(currentId(c), 'HL-ACCS-01');
    await tapText(tester, 'Sign in');
    expect(currentId(c), 'HL-ACCS-02', reason: 'the demo form is filled; a new device is sent the code step');
  });
}
