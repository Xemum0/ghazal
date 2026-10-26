// What a gate sign-in leaves on screen: the sheets the sign-in promises (the Brief merge, the Face ID offer) are asked of the sheet queue and
// open one at a time at a calm moment, never over the voucher explainer the sign-in resumed. The prototype stacks them (merge +400 ms and
// Face ID +900 ms over the explainer, `CL-DISC-01.tsx` and `auth/_components/flow.ts`); the app does not.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/auth/application/auth_actions.dart' show authBioOfferSheetProvider, kBiometricPromptId;
import 'package:client_app/features/auth/application/auth_flow.dart' show authFlowProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, DateMode, LocalDate;

import '../../support/flow_world.dart';

void main() {
  String top(WidgetTester t) => nav(t).currentId;

  test('the checkout and the request steps are busy; the payment success and Home are calm', () {
    for (final id in <String>['CL-PAYM-01', 'CL-PAYM-02', 'CL-PAYM-03', 'CL-PAYM-04', 'CL-BOOK-01', 'CL-BOOK-02', 'CL-BOOK-03', 'CL-BOOK-04', 'CL-BOOK-05']) {
      expect(sheetQueueBusyScreen(id), isTrue, reason: id);
    }
    for (final id in <String>['CL-PAYM-05', 'CL-BOOK-06', 'CL-BOOK-09', 'CL-DISC-01', 'CL-VENU-01', 'CL-VCHR-03', 'CL-PROF-05', 'CL-BKNG-02']) {
      expect(sheetQueueBusyScreen(id), isFalse, reason: id);
    }
  });

  Future<void> signInAtTheVoucherGate(WidgetTester t) async {
    final c = await openScreen(
      t,
      'CL-VENU-01',
      persona: 'guest',
      params: const <String, Object?>{'venueId': 'V05'},
      bioOfferDelay: const Duration(milliseconds: 900),
    );
    c
        .read(searchBriefProvider.notifier)
        .set(SearchBrief(date: const LocalDate(2027, 1, 21), guests: 350, audience: Audience.women, dateMode: DateMode.exact));
    await settle(t, wait: const Duration(milliseconds: 1500), flush: true);
    await tapText(t, en.clientVenueCtaGetVoucher, ms: 1500);
    expect(top(t), 'CL-AUTH-01');
    await t.enterText(find.byType(EditableText).first, '50000012');
    await t.pump();
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
    expect(top(t), 'CL-AUTH-02');
    await t.enterText(find.byType(EditableText).first, '123456');
    await settle(t, wait: const Duration(milliseconds: 500));
  }

  flowTest('gate sign-in over the venue: the explainer is alone for as long as it is open, then the offer, then the Briefs at Home', (t) async {
    await signInAtTheVoucherGate(t);
    final c = container(t);
    // the code verified, the auth screens left at once and the explainer resumed over the venue
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(top(t), 'CL-VCHR-01');
    expect(onScreen('voucher.explainer'), isTrue);
    // well past the +400 ms of the Briefs and the +900 ms of the offer: nothing opened over it
    await settle(t, wait: const Duration(milliseconds: 3000));
    expect(top(t), 'CL-VCHR-01', reason: 'no sheet stacked over the explainer');
    expect(find.text(en.clientAuthBioTurnOn), findsNothing);
    expect(onScreen('discover.brief.merge'), isFalse);
    expect(c.read(sheetQueueProvider).waiting, <String>['brief-merge', kBiometricPromptId]);
    expect(c.read(sheetQueueProvider).showing, isNull);

    // the person closes the explainer: the venue is a calm screen, the offer opens 900 ms later; the Briefs belong to Home and keep waiting
    nav(t).pop(); // the resumed explainer is a pushed sheet, not one `openSheet` tracks
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(find.text(en.clientAuthBioTurnOn), findsOneWidget, reason: 'the Face ID offer at the first calm screen');
    expect(c.read(sheetQueueProvider).showing, kBiometricPromptId);
    expect(c.read(sheetQueueProvider).waiting, <String>['brief-merge']);
    expect(onScreen('discover.brief.merge'), isFalse);
    await tapText(t, en.clientAuthSharedNotNow, ms: 1500);
    expect(find.text(en.clientAuthBioTurnOn), findsNothing);
    expect(c.read(sheetQueueProvider).showing, isNull);
    expect(c.read(authFlowProvider).bioOffered, isTrue);
    expect(top(t), 'CL-VENU-01');

    // Home becomes the visible screen: the two Briefs, once
    nav(t).reset('CL-DISC-01');
    await settle(t, wait: const Duration(milliseconds: 2000));
    expect(top(t), 'CL-DISC-02');
    expect(onScreen('discover.brief.merge'), isTrue);
    expect(c.read(sheetQueueProvider).waiting, isEmpty);
  });

  flowTest('the offer is made once per run of the app: asking again opens nothing', (t) async {
    await signInAtTheVoucherGate(t);
    final c = container(t);
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(top(t), 'CL-VCHR-01');
    nav(t).pop(); // the resumed explainer is a pushed sheet, not one `openSheet` tracks
    await settle(t, wait: const Duration(milliseconds: 2500));
    await tapText(t, en.clientAuthSharedNotNow, ms: 1500);
    expect(c.read(authFlowProvider).bioOffered, isTrue);
    c.read(sheetQueueProvider.notifier).enqueue(c.read(authBioOfferSheetProvider)!);
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(find.text(en.clientAuthBioTurnOn), findsNothing, reason: 'once per run of the app');
    expect(c.read(sheetQueueProvider).showing, isNull);
  });

  flowTest('signing out forgets what the sign-in promised', (t) async {
    await signInAtTheVoucherGate(t);
    final c = container(t);
    await settle(t, wait: const Duration(milliseconds: 2500));
    expect(c.read(sheetQueueProvider).waiting, isNotEmpty);
    await t.runAsync(() => c.read(sessionProvider.notifier).signOut());
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(c.read(sheetQueueProvider).waiting, isEmpty);
  });
}
