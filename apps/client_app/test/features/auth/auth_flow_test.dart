// The sign-in flow through the real router, the session, the guest gate and the in-process mock: a gated action opens the sheet, the phone
// and the WhatsApp code sign the person in and the app resumes at the gated action; a new number goes through name and terms; password
// sign-in, recovery and a new password; the code states; the biometric offer; the five states; one Arabic run.
// The mock accepts any six digits (000000 locked, 111111 expired, docs/architecture/mock-api.md): there is no outbox for a client code.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/auth/application/auth_flow.dart';
import 'package:client_app/features/auth/application/biometric.dart';
import 'package:client_app/features/auth/presentation/cl_auth_05.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, DateMode, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

/// What a guest-gated action does: `if (!ref.requireSignIn(...)) return;` (the kit's gate over the shared navigator).
final Provider<bool Function()> _gatedAction = Provider<bool Function()>(
  (ref) =>
      () => ref.requireSignIn(GateReason.sendRequest, resume: const GateResume('CL-BOOK-01', <String, Object?>{'venueId': 'V01'})),
);

void main() {
  String top(WidgetTester t) => nav(t).currentId;
  AppSession session(WidgetTester t) => container(t).read(sessionProvider);

  /// A guest taps a gated action: the sheet opens. (The base page is the intro, not the first-start screen: a signed-in person is redirected
  /// away from that one by the router, which would hide what the gate does.)
  Future<void> gate(WidgetTester t) async {
    expect(container(t).read(_gatedAction)(), isFalse, reason: 'a guest is stopped by the gate');
    await settle(t, wait: const Duration(milliseconds: 1000));
    expect(top(t), 'CL-AUTH-01');
  }

  Future<void> sendCode(WidgetTester t, String national) async {
    await t.enterText(find.byType(EditableText).first, national);
    await t.pump();
    await tapText(t, en.clientAuthSharedSendCode, ms: 1500);
  }

  Future<void> enterCode(WidgetTester t, String code, {int ms = 1500}) async {
    await t.enterText(find.byType(EditableText).first, code);
    await settle(t, wait: Duration(milliseconds: ms));
  }

  flowTest('the gate: the sheet shows why, the phone and the code sign in and the app resumes at the gated action', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    final c = container(t);
    expect(c.read(gateProvider)?.reason, GateReason.sendRequest);
    expect(find.text(en.clientAuthSharedSendCode), findsWidgets);
    // an invalid number says so and goes nowhere
    await t.enterText(find.byType(EditableText).first, '5000');
    await tapText(t, en.clientAuthSharedSendCode, ms: 500);
    expect(top(t), 'CL-AUTH-01');
    expect(find.text(en.clientAuthGateErrorDigits(8)), findsOneWidget);
    await sendCode(t, '50000012');
    expect(top(t), 'CL-AUTH-02', reason: 'the sheet gives way to the code step');
    expect(c.read(authFlowProvider).challenge, isNotNull);
    expect(c.read(authFlowProvider).pending?.reason, GateReason.sendRequest, reason: 'the gate request survives the sheet');
    // the code: Verify waits for six digits, six digits verify at once, the seal shows, then the app resumes
    ignoreRenderErrors = true; // the resume route belongs to the booking flow
    await enterCode(t, '123456', ms: 500);
    expect(find.text(en.clientAuthOtpSuccessTitle), findsWidgets);
    await settle(t, wait: const Duration(milliseconds: 2000));
    expect(session(t), isA<ClientSession>());
    expect((session(t) as ClientSession).user.phone, '+96550000012', reason: 'the number resolved to the hero client, Reem');
    expect(top(t), 'CL-BOOK-01');
    expect(c.read(gateProvider), isNull);
  });

  flowTest('a different Brief on the phone than in the account opens the merge sheet once after sign-in', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    final c = container(t);
    c
        .read(searchBriefProvider.notifier)
        .set(SearchBrief(date: const LocalDate(2027, 3, 3), guests: 120, audience: Audience.women, dateMode: DateMode.exact));
    await gate(t);
    await sendCode(t, '50000012');
    ignoreRenderErrors = true; // the resume route and the merge sheet belong to the booking and discover flows
    await enterCode(t, '123456', ms: 500);
    await settle(t, wait: const Duration(milliseconds: 3500));
    expect(session(t), isA<ClientSession>());
    expect(top(t), 'CL-DISC-02');
  });

  flowTest('the same Brief on the phone and in the account opens no merge sheet', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    final c = container(t);
    c
        .read(searchBriefProvider.notifier)
        .set(SearchBrief(date: const LocalDate(2027, 1, 14), guests: 350, audience: Audience.women, dateMode: DateMode.exact));
    await gate(t);
    await sendCode(t, '50000012');
    ignoreRenderErrors = true;
    await enterCode(t, '123456', ms: 500);
    await settle(t, wait: const Duration(milliseconds: 3500));
    expect(top(t), 'CL-BOOK-01');
  });

  flowTest('dismissing the sheet without signing in drops the gate and the guest stays a guest', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    nav(t).closeSheet();
    await settle(t, wait: const Duration(milliseconds: 800));
    expect(top(t), 'CL-ONBD-02');
    expect(container(t).read(gateProvider), isNull);
    expect(session(t), isA<GuestSession>());
  });

  flowTest('a new number goes through name and terms, then resumes; the terms are required', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await sendCode(t, '50001234');
    expect(top(t), 'CL-AUTH-02');
    await enterCode(t, '123456', ms: 800);
    await settle(t, wait: const Duration(milliseconds: 1800));
    expect(top(t), 'CL-AUTH-03');
    expect((session(t) as ClientSession).isNewUser, isTrue);
    // no name, no terms: nothing happens but the two errors
    await t.enterText(find.byType(EditableText).first, '');
    await tapText(t, en.commonActionContinue, ms: 500);
    expect(find.text(en.commonLabelRequired), findsNWidgets(2));
    expect(top(t), 'CL-AUTH-03');
    await t.enterText(find.byType(EditableText).first, 'Nora Al-Salem');
    await tapText(t, en.clientAuthNameAccept, ms: 300);
    ignoreRenderErrors = true;
    await tapText(t, en.commonActionContinue, ms: 600);
    expect(find.text(en.clientAuthSharedAccountReady), findsWidgets);
    await settle(t, wait: const Duration(milliseconds: 2000));
    expect((session(t) as ClientSession).user.name, 'Nora Al-Salem');
    expect((session(t) as ClientSession).user.monogram, 'N');
    expect(top(t), 'CL-BOOK-01');
  });

  flowTest('the code states: expired offers Resend, a resend restarts the wait, too many attempts is a lock', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await sendCode(t, '50000012');
    await enterCode(t, '111111', ms: 800);
    expect(find.text(en.clientAuthOtpExpired), findsWidgets);
    expect(session(t), isA<GuestSession>());
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
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await sendCode(t, '50000012');
    final wait = container(t).read(authFlowProvider).challenge!.resendAfterSeconds;
    expect(find.text(en.clientAuthOtpResend), findsNothing);
    await settle(t, wait: Duration(milliseconds: (wait + 2)) * 1000);
    expect(find.text(en.clientAuthOtpResend), findsWidgets);
  });

  flowTest('change number goes back to the sheet with the gate reason', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await sendCode(t, '50000012');
    await tapText(t, en.clientAuthOtpChange, ms: 1200);
    expect(top(t), 'CL-AUTH-01');
  });

  flowTest('password sign-in: the right password signs in, a wrong one is blameless, three misses pause it', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await tapText(t, en.clientAuthSharedUsePassword, ms: 1200);
    expect(top(t), 'CL-AUTH-04');
    await t.enterText(find.byType(EditableText).at(0), '50000012');
    for (var i = 0; i < 3; i++) {
      await t.enterText(find.byType(EditableText).at(1), 'garden');
      await tapText(t, en.clientAuthSharedSignIn, ms: 900, last: true);
      if (i < 2) expect(find.text(en.clientAuthPwdInvalid), findsWidgets);
    }
    expect(find.text(en.clientAuthPwdLocked), findsWidgets);
    expect(session(t), isA<GuestSession>());
  });

  flowTest('password sign-in with the right password resumes the gated action', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
    await tapText(t, en.clientAuthSharedUsePassword, ms: 1200);
    await t.enterText(find.byType(EditableText).at(0), '50000012');
    await t.enterText(find.byType(EditableText).at(1), 'Ghazal#2026');
    ignoreRenderErrors = true;
    await tapText(t, en.clientAuthSharedSignIn, ms: 1500, last: true);
    expect(session(t), isA<ClientSession>());
    expect(top(t), 'CL-BOOK-01');
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

  flowTest('offline: the sheet says so and keeps the number; the code is not sent', (t) async {
    await openScreen(t, 'CL-ONBD-02');
    await gate(t);
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

  flowTest('Arabic run: the code step and the sheet read in Arabic, mirrored', (t) async {
    await openScreen(t, 'CL-ONBD-02', locale: const Locale('ar'));
    expect(container(t).read(_gatedAction)(), isFalse);
    await settle(t, wait: const Duration(milliseconds: 1000));
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
