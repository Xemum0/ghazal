// What a sign-in leaves on screen: the sheet the sign-in promises (the Face ID offer) is asked of the sheet queue and opens at a calm
// moment, 900 ms after the person lands on Home, never over a sheet or a checkout step.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/auth/application/auth_actions.dart' show authBioOfferSheetProvider, kBiometricPromptId;
import 'package:client_app/features/auth/application/auth_flow.dart' show authFlowProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;

import '../../support/flow_world.dart';

void main() {
  String top(WidgetTester t) => nav(t).currentId;

  test('the checkout and the request steps are busy; the payment success and Home are calm', () {
    for (final id in <String>['CL-PAYM-01', 'CL-PAYM-02', 'CL-PAYM-03', 'CL-PAYM-04', 'CL-BOOK-01', 'CL-BOOK-02', 'CL-BOOK-04', 'CL-BOOK-05']) {
      expect(sheetQueueBusyScreen(id), isTrue, reason: id);
    }
    for (final id in <String>['CL-PAYM-05', 'CL-BOOK-06', 'CL-BOOK-09', 'CL-DISC-01', 'CL-VENU-01', 'CL-VCHR-03', 'CL-PROF-05', 'CL-BKNG-02']) {
      expect(sheetQueueBusyScreen(id), isFalse, reason: id);
    }
  });

  /// The person signs in from the sign-in screen with the Face ID offer switched on (it opens 900 ms after the first calm screen).
  Future<void> signInReturning(WidgetTester t) async {
    await openScreen(t, 'CL-AUTH-01', bioOfferDelay: const Duration(milliseconds: 900));
    await t.enterText(find.byType(EditableText).first, '50000012');
    await t.pump();
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
    expect(top(t), 'CL-AUTH-02');
    ignoreRenderErrors = true; // Home belongs to the discover flow
    await t.enterText(find.byType(EditableText).first, '123456');
    await settle(t, wait: const Duration(milliseconds: 500));
  }

  flowTest('sign-in lands on Home and the Face ID offer opens there once, 900 ms later', (t) async {
    await signInReturning(t);
    final c = container(t);
    // the code verified, the seal shown, Home is the calm screen: the offer waits its 900 ms there
    await settle(t, wait: const Duration(milliseconds: 1500));
    expect(top(t), 'CL-DISC-01');
    expect(find.text(en.clientAuthBioTurnOn), findsOneWidget, reason: 'the Face ID offer at the first calm screen');
    expect(c.read(sheetQueueProvider).showing, kBiometricPromptId);
    await tapText(t, en.clientAuthSharedNotNow, ms: 1500);
    expect(find.text(en.clientAuthBioTurnOn), findsNothing);
    expect(c.read(sheetQueueProvider).showing, isNull);
    expect(c.read(authFlowProvider).bioOffered, isTrue);
    expect(top(t), 'CL-DISC-01');
  });

  flowTest('the offer is made once per run of the app: asking again opens nothing', (t) async {
    await signInReturning(t);
    final c = container(t);
    await settle(t, wait: const Duration(milliseconds: 1500));
    await tapText(t, en.clientAuthSharedNotNow, ms: 1500);
    expect(c.read(authFlowProvider).bioOffered, isTrue);
    c.read(sheetQueueProvider.notifier).enqueue(c.read(authBioOfferSheetProvider)!);
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(find.text(en.clientAuthBioTurnOn), findsNothing, reason: 'once per run of the app');
    expect(c.read(sheetQueueProvider).showing, isNull);
  });

  flowTest('signing out forgets what the sign-in promised and sends the client back to the first run', (t) async {
    await signInReturning(t);
    final c = container(t);
    await settle(t, wait: const Duration(milliseconds: 1400)); // the seal, then Home: the offer is asked for and counts its 900 ms
    expect(c.read(sheetQueueProvider).waiting, <String>[kBiometricPromptId], reason: 'the offer waits for its moment');
    await t.runAsync(() => c.read(sessionProvider.notifier).signOut());
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(c.read(sheetQueueProvider).waiting, isEmpty);
    expect(top(t), 'CL-ONBD-01', reason: 'a signed-out client is sent to the start of the first run');
  });
}
