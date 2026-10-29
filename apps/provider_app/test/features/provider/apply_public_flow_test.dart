// Flow test of the PUBLIC application (round 2b, OQ-R2-11, PA-ACC-07): HL-ACCS-01 "Apply to join" -> HL-PROV-01 signed out (account type, "Your account",
// the business) -> the public `submitPartnerApplication` -> HL-ACCS-02 (mode `application`, the emailed code) -> HL-ACCS-04 under review, and a later
// sign-in of the same account (rejected: the reason and "Edit and resubmit" without the account section). The real router and the in-process mock,
// real taps. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show EditableText, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show PartnerSession, partnerAccountRepositoryProvider, sessionProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/access/presentation/hl_accs_01.dart';
import 'package:provider_app/features/access/presentation/hl_accs_02.dart';
import 'package:provider_app/features/provider/presentation/hl_prov_01.dart';

import '../../support/flow_world.dart';

const String _email = 'nora@lens-house.example';
const String _password = 'Ghazal#2026x';

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(EditableText).at(field), text);
  await tester.pump(const Duration(milliseconds: 100));
}

/// From the sign-in screen to the signed-out form of a provider (or a hall): Apply to join, the type, Continue.
Future<void> _toForm(WidgetTester tester, {bool hall = false}) async {
  await tap(tester, find.text(en.hotelAccessSigninApply));
  await tap(tester, find.text(hall ? en.hotelProviderTypeHallTitle : en.hotelProviderTypeProviderTitle));
  await tap(tester, find.text(en.hotelProviderContinue));
}

/// The fields of the signed-out provider form (English): email, password, repeat, name EN, name AR, Other note, contact, phone, description, licence.
Future<void> _fill(WidgetTester tester, {String email = _email, String password = _password, String repeat = _password}) async {
  await _type(tester, 0, email);
  await _type(tester, 1, password);
  await _type(tester, 2, repeat);
  await _type(tester, 3, 'Lens House');
  await _type(tester, 4, 'بيت العدسة');
  await _type(tester, 6, 'Nora Al-Sabah');
  await _type(tester, 7, '55512345');
  await _type(tester, 8, 'Wedding photography with a ladies-only team.');
  await tapText(tester, 'Hawalli');
  await tap(tester, find.text(en.hotelProviderCatsChoose));
  await tapText(tester, 'Photography');
  await tap(tester, find.text(en.commonActionDone));
}

/// The code the mock emailed for the application (the outbox entry `partner_application_verify`).
String _mailedCode() {
  final mail = flowControl.outbox.where((m) => m['kind'] == 'partner_application_verify');
  expect(mail, hasLength(1), reason: 'one verification email was queued');
  return mail.single['code']! as String;
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(EditableText).first, code);
  await settle(tester, wait: const Duration(milliseconds: 1500));
}

void main() {
  flowTest('HL-ACCS-01: "Apply to join" is a visible outlined 44 dp full-width button under Sign in, with its line above it', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    expect(find.byType(HlAccs01Screen), findsOneWidget);
    final apply = find.ancestor(of: find.text(en.hotelAccessSigninApply), matching: find.byType(GzButton));
    expect(apply, findsOneWidget);
    final box = tester.getRect(apply);
    expect(box.height, greaterThanOrEqualTo(44));
    expect(box.width, closeTo(390 - 2 * 20, 0.5), reason: 'full width inside the 20 dp gutters');
    final line = tester.getRect(find.text(en.hotelAccessSigninApplyLine));
    final signIn = tester.getRect(find.text(en.hotelAccessSigninSubmit).last);
    expect(signIn.bottom, lessThan(line.top), reason: 'the line sits under the gold Sign in');
    expect(line.bottom, lessThan(box.top), reason: 'and above the button');
    expect(box.bottom, lessThanOrEqualTo(844), reason: 'on screen without scrolling');
  });

  flowTest('Back: the form goes back to the account type, the account type back to the sign-in screen', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await tap(tester, find.text(en.hotelAccessSigninApply));
    expect(currentId(c), 'HL-PROV-01');
    expect(find.text(en.hotelProviderChooseTitle), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderTypeProviderTitle));
    await tap(tester, find.text(en.hotelProviderContinue));
    expect(find.text(en.hotelProviderFormAccountTitle), findsOneWidget);
    expect(find.text(en.hotelProviderFormBusinessTitle), findsOneWidget);
    await tapLabel(tester, 'Back');
    expect(find.text(en.hotelProviderChooseTitle), findsOneWidget);
    expect(find.text(en.hotelProviderFormAccountTitle), findsNothing);
    await tapLabel(tester, 'Back');
    expect(currentId(c), 'HL-ACCS-01');
    expect(find.byType(HlAccs01Screen), findsOneWidget);
  });

  flowTest('Form: "Your account" comes first with email, password and repeat; the business section does not ask for the email again', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    expect(find.byType(HlProv01Screen), findsOneWidget);
    final account = tester.getRect(find.text(en.hotelProviderFormAccountTitle));
    final business = tester.getRect(find.text(en.hotelProviderFormBusinessTitle));
    expect(account.top, lessThan(business.top));
    // email, password, repeat | name EN, name AR, Other note, contact, phone, description, licence: no second email field
    expect(find.byType(EditableText), findsNWidgets(10));
    expect(shows('PASSWORD') || shows('Password'), isTrue); // the label role is uppercase in English
    expect(shows(en.hotelProviderAccountRepeat) || shows(en.hotelProviderAccountRepeat.toUpperCase()), isTrue);
    expect(find.text('10+'), findsOneWidget); // the strength thread and its rule chips
  });

  flowTest('Account validation: weak password, passwords that differ and a missing email are said under their fields; nothing is sent', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _type(tester, 1, '123456');
    await _type(tester, 2, '123457');
    expect(find.text(en.hotelAccessSetupMismatch), findsOneWidget, reason: 'the mismatch shows as soon as the repeat is typed');
    expect(find.text(en.hotelAccessSetupStrengthWeak), findsOneWidget);
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderAccountPasswordWeak), findsOneWidget);
    expect(find.text(en.hotelProviderFormEmailError), findsOneWidget);
    expect(find.text(en.hotelProviderFormFix), findsOneWidget);
    expect(currentId(c), 'HL-PROV-01');
    expect(flowControl.outbox.where((m) => m['kind'] == 'partner_application_verify'), isEmpty);
  });

  flowTest('Account validation: a complete business with a weak password is still held on the form', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester, password: 'short1', repeat: 'short1');
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderAccountPasswordWeak), findsOneWidget);
    expect(find.text(en.hotelAccessSetupMismatch), findsNothing);
    expect(currentId(c), 'HL-PROV-01');
    expect(find.byType(HlAccs02Screen), findsNothing);
  });

  flowTest('Duplicate email: the server says it is registered, the message sits under the email field and goes when the email changes', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester, email: 'zahra@zahra-floral.example');
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(find.text(en.hotelProviderAccountEmailUsed), findsOneWidget);
    expect(find.text(en.hotelProviderFormFix), findsOneWidget);
    expect(currentId(c), 'HL-PROV-01');
    expect(flowControl.outbox.where((m) => m['kind'] == 'partner_application_verify'), isEmpty);
    await _type(tester, 0, _email);
    expect(find.text(en.hotelProviderAccountEmailUsed), findsNothing);
  });

  flowTest('Submit: the code screen opens for the account email, a wrong code is refused, the right one lands on the application under review', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester);
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(currentId(c), 'HL-ACCS-02');
    expect(find.byType(HlAccs02Screen), findsOneWidget);
    expect(find.text(en.hotelAccessVerifyApplicationTitle), findsOneWidget);
    expect(shows('@lens-house.example'), isTrue, reason: 'the masked account email');
    final code = _mailedCode();
    expect(c.read(sessionProvider) is PartnerSession, isFalse, reason: 'no session before the code');
    await _enterCode(tester, '222222');
    expect(find.text(en.hotelAccessVerifyWrong), findsOneWidget);
    expect(currentId(c), 'HL-ACCS-02');
    await _enterCode(tester, code);
    await settle(tester, wait: const Duration(seconds: 2));
    expect(currentId(c), 'HL-ACCS-04');
    expect(find.text(en.hotelAccessStatusApplicationTitle), findsOneWidget);
    expect(find.text('Lens House'), findsWidgets);
    final session = c.read(sessionProvider);
    expect(session is PartnerSession, isTrue);
    final me = await tester.runAsync(() => c.read(partnerAccountRepositoryProvider).getPartnerMe());
    expect(me!.memberships, hasLength(1));
    expect(me.memberships.single.application?.status.value, 'pending');
    expect(me.memberships.single.application?.email, _email);
  });

  flowTest('Expired code: Resend leads back to sign in with the email kept', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester);
    await tap(tester, find.text(en.hotelProviderSubmit));
    expect(currentId(c), 'HL-ACCS-02');
    await _enterCode(tester, '111111');
    expect(find.text(en.hotelAccessVerifyExpired), findsOneWidget);
    await tap(tester, find.text(en.hotelAccessVerifyResend));
    expect(currentId(c), 'HL-ACCS-01');
    final fields = find.byType(EditableText).evaluate().map((e) => (e.widget as EditableText).controller.text).toList();
    expect(fields, contains(_email));
  });

  flowTest('Later sign-in: a rejected applicant sees the reason and "Edit and resubmit" opens the form WITHOUT the account section', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester);
    await tap(tester, find.text(en.hotelProviderSubmit));
    await _enterCode(tester, _mailedCode());
    await settle(tester, wait: const Duration(seconds: 2));
    expect(currentId(c), 'HL-ACCS-04');
    // staff refuse it (the Super Admin web is out of scope: the mock control), the person signs out and comes back later
    final me = await tester.runAsync(() => c.read(partnerAccountRepositoryProvider).getPartnerMe());
    final application = me!.memberships.single.application!;
    flowControl.decidePartnerApplication(application.id, accept: false, reason: 'Add your licence number.');
    await tester.runAsync(() => c.read(sessionProvider.notifier).signOut());
    nav(tester).reset('HL-ACCS-01'); // what Settings, Log out does
    await settle(tester, wait: const Duration(seconds: 2));
    expect(currentId(c), 'HL-ACCS-01');
    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await settle(tester);
    await tap(tester, find.text(en.hotelAccessSigninSubmit));
    await settle(tester, wait: const Duration(seconds: 2));
    expect(currentId(c), 'HL-ACCS-04');
    expect(find.text(en.hotelAccessStatusRejectedTitle), findsOneWidget);
    expect(find.text('Add your licence number.'), findsOneWidget);
    await tap(tester, find.text(en.hotelAccessStatusEditResubmit));
    expect(currentId(c), 'HL-PROV-01');
    expect(find.text(en.hotelProviderFormBarEdit), findsOneWidget);
    expect(find.text(en.hotelProviderFormAccountTitle), findsNothing, reason: 'signed in: no account section');
    expect(find.text(en.hotelProviderAccountRepeat), findsNothing);
    final fields = find.byType(EditableText).evaluate().map((e) => (e.widget as EditableText).controller.text).toList();
    expect(fields, contains('Lens House'));
    expect(fields, contains(_email));
  });

  flowTest('A signed-in partner (an account adding a type) keeps the flow without the account section', (tester) async {
    await openScreen(tester, 'HL-PROV-01', persona: 'provider');
    await tap(tester, find.text(en.hotelProviderTypeProviderTitle));
    await tap(tester, find.text(en.hotelProviderContinue));
    expect(find.text(en.hotelProviderFormAccountTitle), findsNothing);
    expect(find.text(en.hotelProviderFormBusinessTitle), findsNothing);
    expect(find.byType(EditableText), findsNWidgets(8)); // the email is the business one
  });

  flowTest('Five states: reference data failing on the signed-out form offers Try again', (tester) async {
    await openScreen(tester, 'HL-ACCS-01', state: 'error');
    await _toForm(tester);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text(en.commonActionRetry), findsWidgets);
  });

  flowTest('Five states: offline on the signed-out form says so', (tester) async {
    await openScreen(tester, 'HL-ACCS-01', state: 'offline');
    await _toForm(tester);
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Five states: while the lists load the signed-out form shows skeleton blocks', (tester) async {
    await openScreen(tester, 'HL-ACCS-01');
    flowControl.setLatency(const Duration(seconds: 20));
    await tap(tester, find.text(en.hotelAccessSigninApply));
    await tap(tester, find.text(en.hotelProviderTypeProviderTitle), ms: 100);
    await tap(tester, find.text(en.hotelProviderContinue), ms: 100);
    expect(find.byType(GzSkeleton), findsWidgets);
    flowControl.setLatency(Duration.zero);
    await tester.pump(const Duration(seconds: 21));
  });

  flowTest('Five states: a send that fails keeps the form, says nothing was sent and offers Retry; the retry goes through', (tester) async {
    final c = await openScreen(tester, 'HL-ACCS-01');
    await _toForm(tester);
    await _fill(tester);
    flowControl.setScenario('error');
    await tap(tester, find.text(en.hotelProviderSubmit), ms: 6000);
    expect(find.text(en.hotelProviderSubmitError), findsOneWidget);
    expect(currentId(c), 'HL-PROV-01');
    flowControl.setScenario('none');
    await tap(tester, find.text(en.hotelProviderRetryShort));
    expect(currentId(c), 'HL-ACCS-02');
    expect(flowControl.outbox.where((m) => m['kind'] == 'partner_application_verify'), hasLength(1));
  });

  flowTest('Arabic run: the sign-in screen offers «قدّم طلب انضمام» and the signed-out form reads right to left', (tester) async {
    await openScreen(tester, 'HL-ACCS-01', locale: const Locale('ar'));
    expect(find.text(ar.hotelAccessSigninApply), findsOneWidget);
    expect(find.text(ar.hotelAccessSigninApplyLine), findsOneWidget);
    await tap(tester, find.text(ar.hotelAccessSigninApply));
    await tap(tester, find.text(ar.hotelProviderTypeHallTitle));
    await tap(tester, find.text(ar.hotelProviderContinue));
    expect(find.text(ar.hotelProviderFormAccountTitle), findsOneWidget);
    expect(find.text(ar.hotelProviderFormBusinessTitle), findsOneWidget);
    await tap(tester, find.text(ar.hotelProviderSubmit));
    expect(find.text(ar.hotelProviderAccountPasswordWeak), findsOneWidget);
    expect(find.text(ar.hotelProviderFormFix), findsOneWidget);
  });
}
