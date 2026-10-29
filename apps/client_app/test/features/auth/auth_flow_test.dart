// The sign-in flow through the real router, the session and the in-process mock (ADR 0038, no guest mode): the phone and the WhatsApp code
// sign a returning client in and land on Home; a new number goes through "About you" (name, sex and terms all required, completeProfile)
// and the optional steps; a wrong code; password sign-in, recovery and a new password; the code states; the biometric offer; a signed-out
// client reaches nothing but the first-run screens; the five states; one Arabic run.
// The mock accepts any six digits (000000 locked, 111111 expired, 222222 wrong, docs/architecture/mock-api.md): there is no outbox for a client code.
import 'package:client_app/features/auth/application/auth_flow.dart';
import 'package:client_app/features/auth/application/biometric.dart';
import 'package:client_app/features/auth/presentation/cl_auth_05.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Sex;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  String top(WidgetTester t) => nav(t).currentId;
  AppSession session(WidgetTester t) => container(t).read(sessionProvider);

  Future<void> sendCode(WidgetTester t, String national) async {
    await t.enterText(find.byType(EditableText).first, national);
    await t.pump();
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
  }

  Future<void> enterCode(WidgetTester t, String code, {int ms = 1500}) async {
    await t.enterText(find.byType(EditableText).first, code);
    await settle(t, wait: Duration(milliseconds: ms));
  }

  flowTest('a returning number: the phone and the code sign in and the app lands on Home', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    final c = container(t);
    expect(find.text(en.clientAuthSharedSendCode), findsWidgets);
    // an invalid number says so and goes nowhere
    await t.enterText(find.byType(EditableText).first, '5000');
    await tapText(t, en.clientAuthSharedSendCode, ms: 500);
    expect(top(t), 'CL-AUTH-01');
    expect(find.text(en.clientAuthGateErrorDigits(8)), findsOneWidget);
    await sendCode(t, '50000012');
    expect(top(t), 'CL-AUTH-02');
    expect(c.read(authFlowProvider).challenge, isNotNull);
    // the code: six digits verify at once, the seal shows, then Home
    ignoreRenderErrors = true; // Home belongs to the discover flow
    await enterCode(t, '123456', ms: 500);
    expect(find.text(en.clientAuthOtpSuccessTitle), findsWidgets);
    await settle(t, wait: const Duration(milliseconds: 2000));
    final s = session(t) as ClientSession;
    expect(s.user.phone, '+96550000012', reason: 'the number resolved to the hero client, Reem');
    expect(s.isNewUser, isFalse);
    expect(top(t), 'CL-DISC-01');
  });

  flowTest('a wrong code says so and keeps the person on the code step', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await sendCode(t, '50000012');
    await enterCode(t, '222222', ms: 800);
    expect(find.text(en.clientAuthOtpWrong), findsWidgets);
    expect(top(t), 'CL-AUTH-02');
    expect(session(t).isSignedIn, isFalse);
  });

  flowTest('a new number goes through About you: name, sex and terms are all required, then the optional steps', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    final c = container(t);
    await sendCode(t, '50001234');
    expect(top(t), 'CL-AUTH-02');
    await enterCode(t, '123456', ms: 800);
    await settle(t, wait: const Duration(milliseconds: 1800));
    expect(top(t), 'CL-AUTH-03');
    expect((session(t) as ClientSession).isNewUser, isTrue);
    // nothing given: the name, the sex and the terms each say Required, and the account stays incomplete
    await tapText(t, en.commonActionContinue, ms: 500);
    expect(find.text(en.commonLabelRequired), findsNWidgets(3));
    expect(top(t), 'CL-AUTH-03');
    expect((session(t) as ClientSession).isNewUser, isTrue);
    // a name alone is not enough
    await t.enterText(find.byType(EditableText).first, 'Nora Al-Salem');
    await tapText(t, en.commonActionContinue, ms: 500);
    expect(find.text(en.commonLabelRequired), findsNWidgets(2), reason: 'the sex and the terms are still missing');
    expect(top(t), 'CL-AUTH-03');
    // the sex as one of two tiles, then the terms
    await tapText(t, en.clientAuthNameSexFemale, ms: 300);
    await tapText(t, en.commonActionContinue, ms: 500);
    expect(find.text(en.commonLabelRequired), findsNWidgets(1), reason: 'only the terms are missing');
    await tapText(t, en.clientAuthNameAccept, ms: 300);
    ignoreRenderErrors = true; // the optional steps belong to the onboarding flow
    await tapText(t, en.commonActionContinue, ms: 600);
    expect(find.text(en.clientAuthSharedAccountReady), findsWidgets);
    await settle(t, wait: const Duration(milliseconds: 2000));
    final s = session(t) as ClientSession;
    expect(s.user.name, 'Nora Al-Salem');
    expect(s.user.monogram, 'N');
    expect(s.isNewUser, isFalse, reason: 'completeProfile finished the account');
    expect(top(t), 'CL-ONBD-03', reason: 'the optional wedding steps follow');
    final me = await t.runAsync(() => c.read(profileRepositoryProvider).getMe());
    expect(me!.user.sex, Sex.female, reason: 'the sex is stored on the account');
    expect(me.user.name, 'Nora Al-Salem');
  });

  flowTest('a complete account that signs in while the introduction is on top (Demo tools, a journey) leaves it for Home', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    ignoreRenderErrors = true; // Home belongs to the discover flow
    await t.runAsync(() => container(t).read(sessionProvider.notifier).loadPersona('reem'));
    await settle(t, wait: const Duration(milliseconds: 1500));
    expect(top(t), 'CL-DISC-01');
  });

  flowTest('a signed-out client reaches only the first-run screens: anything else lands on the start of the first run', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    expect(top(t), 'CL-ONBD-02');
    nav(t).push('CL-VENU-01', params: const <String, Object?>{'venueId': 'V01'});
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(top(t), 'CL-ONBD-01', reason: 'a venue is closed until the person signs in: the first run starts again');
    nav(t).push('CL-DISC-01');
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(top(t), 'CL-ONBD-01', reason: 'Home too');
    expect(find.byType(GzTabBar), findsNothing);
  });

  flowTest('the code states: expired offers Resend, a resend restarts the wait, too many attempts is a lock', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await sendCode(t, '50000012');
    await enterCode(t, '111111', ms: 800);
    expect(find.text(en.clientAuthOtpExpired), findsWidgets);
    expect(session(t).isSignedIn, isFalse);
    await tapText(t, en.clientAuthOtpResend, ms: 1200);
    expect(find.text(en.clientAuthOtpResent), findsWidgets);
    expect(find.textContaining('s', findRichText: true), findsWidgets);
    await enterCode(t, '000000', ms: 800);
    expect(find.text(en.clientAuthOtpLocked), findsWidgets);
    expect(find.text(en.clientAuthSharedSupport), findsWidgets);
    await tapText(t, en.clientAuthSharedSupport, ms: 800);
    expect(find.text(en.commonActionOpenWhatsapp), findsWidgets, reason: 'Support opens its dialog with the number');
  });

  flowTest('the resend countdown ticks down and Resend appears at zero', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await sendCode(t, '50000012');
    final wait = container(t).read(authFlowProvider).challenge!.resendAfterSeconds;
    expect(find.text(en.clientAuthOtpResend), findsNothing);
    await settle(t, wait: Duration(milliseconds: (wait + 2)) * 1000);
    expect(find.text(en.clientAuthOtpResend), findsWidgets);
  });

  flowTest('change number goes back to the sign-in screen', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await sendCode(t, '50000012');
    await tapText(t, en.clientAuthOtpChange, ms: 1200);
    expect(top(t), 'CL-AUTH-01');
  });

  flowTest('password sign-in: the right password signs in, a wrong one is blameless, three misses pause it', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await tapText(t, en.clientAuthSharedUsePassword, ms: 1200);
    expect(top(t), 'CL-AUTH-04');
    await t.enterText(find.byType(EditableText).at(0), '50000012');
    for (var i = 0; i < 3; i++) {
      await t.enterText(find.byType(EditableText).at(1), 'garden');
      await tapText(t, en.clientAuthSharedSignIn, ms: 900, last: true);
      if (i < 2) expect(find.text(en.clientAuthPwdInvalid), findsWidgets);
    }
    expect(find.text(en.clientAuthPwdLocked), findsWidgets);
    expect(session(t).isSignedIn, isFalse);
  });

  flowTest('password sign-in with the right password lands on Home', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    await tapText(t, en.clientAuthSharedUsePassword, ms: 1200);
    await t.enterText(find.byType(EditableText).at(0), '50000012');
    await t.enterText(find.byType(EditableText).at(1), 'Ghazal#2026');
    ignoreRenderErrors = true;
    await tapText(t, en.clientAuthSharedSignIn, ms: 1500, last: true);
    expect(session(t), isA<ClientSession>());
    expect(top(t), 'CL-DISC-01');
  });

  flowTest('forgot password: code, then a new password that must be strong, then Password updated', (t) async {
    await openScreen(t, 'CL-AUTH-04');
    await tapText(t, en.clientAuthPwdForgot, ms: 600);
    await t.enterText(find.byType(EditableText).first, '50000012');
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
    expect(find.text(en.clientAuthOtpResent), findsWidgets);
    await tapText(t, en.clientAuthPwdEnterCode, ms: 1200);
    expect(top(t), 'CL-AUTH-02');
    await enterCode(t, '123456', ms: 800);
    await settle(t, wait: const Duration(milliseconds: 1800));
    expect(top(t), 'CL-AUTH-04', reason: 'the code step hands back to the password screen');
    expect(find.text(en.clientAuthPwdResetTitle), findsWidgets);
    // a weak password keeps Save off
    await t.enterText(find.byType(EditableText).first, 'abc');
    await settle(t, wait: const Duration(milliseconds: 300));
    await t.tap(find.text(en.commonActionSave).last, warnIfMissed: false);
    await settle(t, wait: const Duration(milliseconds: 500));
    expect(find.text(en.clientAuthPwdUpdatedTitle), findsNothing);
    await t.enterText(find.byType(EditableText).first, 'Garden2027x');
    await settle(t, wait: const Duration(milliseconds: 300));
    await tapText(t, en.commonActionSave, ms: 1500);
    expect(find.text(en.clientAuthPwdUpdatedTitle), findsWidgets);
  });

  flowTest('offline: the screen says so and keeps the number; the code is not sent', (t) async {
    await openScreen(t, 'CL-AUTH-01');
    flowControl.setScenario('offline');
    await sendCode(t, '50000012');
    await settle(t, wait: const Duration(milliseconds: 6000));
    expect(find.text(en.commonStateOffline), findsWidgets);
    expect(top(t), 'CL-AUTH-01');
  });

  flowTest('biometric: unlock opens Home; the pre-prompt turns it on and says so', (t) async {
    await openScreen(t, 'CL-AUTH-05', persona: 'reem');
    expect(find.text(en.clientAuthBioUnlock), findsWidgets);
    ignoreRenderErrors = true;
    await tapText(t, en.clientAuthBioUnlock, ms: 2500);
    expect(top(t), 'CL-DISC-01');
  });

  flowTest('biometric pre-prompt sheet: Turn on, then the seal with Done', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    nav(t).openSheetBuilder(authBiometricPromptBuilder);
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(find.text(en.clientAuthBioMethod('face')), findsWidgets);
    await tapText(t, en.clientAuthBioTurnOn, ms: 2000);
    expect(find.text(en.clientAuthBioEnabledTitle), findsWidgets);
    expect(container(t).read(authFlowProvider).bioEnabled, isTrue);
    await tapText(t, en.commonActionDone, ms: 800);
    expect(find.text(en.clientAuthBioEnabledTitle), findsNothing);
  });

  flowTest('biometric not matched: the fallback offers the code and the password', (t) async {
    await openScreen(t, 'CL-AUTH-05', overrides: [biometricProvider.overrideWithValue(const _Rejecting())]);
    await tapText(t, en.clientAuthBioUnlock, ms: 2000);
    expect(find.text(en.clientAuthBioFailedTitle), findsWidgets);
    expect(find.text(en.clientAuthSharedUseCode), findsWidgets);
    expect(find.text(en.clientAuthSharedUsePassword), findsWidgets);
  });

  flowTest('Arabic run: the sign-in screen and the code step read in Arabic, mirrored', (t) async {
    await openScreen(t, 'CL-AUTH-01', locale: const Locale('ar'));
    expect(find.text(ar.clientAuthSharedSignIn), findsWidgets);
    expect(find.text(ar.clientAuthSharedSendCode), findsWidgets);
    await t.enterText(find.byType(EditableText).first, '50000012');
    await tapText(t, ar.clientAuthSharedSendCode, ms: 1500);
    expect(top(t), 'CL-AUTH-02');
    expect(find.text(ar.clientAuthOtpTitle), findsWidgets);
    expect(Directionality.of(t.element(find.byType(GzOtpInput))), TextDirection.rtl);
  });
}

class _Rejecting extends BiometricAuthenticator {
  const _Rejecting();

  @override
  String? get method => 'face';

  @override
  Future<bool> authenticate() => Future<bool>.value(false);
}
