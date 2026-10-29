// J10 (partner): a brand-new service provider finds "Apply to join" on the sign-in screen, makes her account and sends the application, verifies her
// email with the code, waits under review, the staff accept and she continues to listings.
//
//   Round 2b (OQ-R2-11, PA-ACC-07): from the signed-out sign-in screen the button "Apply to join" opens the account type, the form starts with "Your
//   account" (email, password, repeat) and then the business; a weak password is said on its field and nothing is sent; Send application asks the
//   public `submitPartnerApplication` and opens the code screen; the code is read from the mock's outbox (`partner_application_verify`), a wrong code
//   is refused, the right one lands on "Application in review". The staff accept through the mock control (the Super Admin web is out of scope);
//   the person returns, the status refetches ("Application approved"), Continue opens Today. She logs out and signs in again with the email and
//   password she chose: no status in between, Today, and More > My listings > New opens the editor (it was held back until the decision).
// Real entry (`bootstrap()`), in-process mock. Run: `node apps/provider_app/integration_test/headless.mjs j10` (add `--lang ar` for Arabic) or, on a
// simulator, `flutter test integration_test/j10_apply_public_test.dart -d <id>` from apps/provider_app.
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerAccountRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, PartnerApplication;
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';

const String _email = 'noura@lens-house.example';
const String _password = 'Ghazal#2026x';

void main() {
  journeySetUp();

  journey('J10 partner: Apply to join from the sign-in screen, verify the email, wait, the staff accept, listings open', (j) async {
    final c = await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);
    Future<PartnerApplication?> serverApplication() async =>
        (await c.read(partnerAccountRepositoryProvider).getPartnerMe()).memberships.where((m) => m.application != null).lastOrNull?.application;
    String mailedCode() {
      final mail = j.control.outbox.where((m) => m['kind'] == 'partner_application_verify').toList();
      expect(mail, hasLength(1), reason: 'one verification email was queued for the application');
      expect(mail.single['to'], _email);
      return mail.single['code']! as String;
    }

    // ---------------------------------------------------------------------------------------------------------------- the way in
    j.step('signed out: the sign-in screen shows Apply to join under Sign in, no sign-up hidden anywhere');
    await j.seeScreen('HL-ACCS-01');
    if (kJourneyLang == 'ar') {
      await j.tapText('العربية', wait: const Duration(seconds: 1));
      expect(j.locale.languageCode, 'ar');
    }
    await j.see(find.text(t((l) => l.hotelAccessSigninApply)), why: 'a visible button, not a link in a sentence');
    await j.see(find.text(t((l) => l.hotelAccessSigninApplyLine)));
    await j.tapText(t((l) => l.hotelAccessSigninApply), wait: const Duration(seconds: 2));

    j.step('the account type: a service provider, Continue');
    await j.seeScreen('HL-PROV-01');
    await j.see(find.text(t((l) => l.hotelProviderChooseTitle)));
    await j.tapText(t((l) => l.hotelProviderTypeProviderTitle));
    await j.tapText(t((l) => l.hotelProviderContinue), wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- the form
    j.step('the form starts with Your account, then Your business; the email is asked once');
    await j.see(find.text(t((l) => l.hotelProviderFormAccountTitle)));
    await j.see(find.text(t((l) => l.hotelProviderFormBusinessTitle)));
    expect(find.byType(EditableText), findsNWidgets(10), reason: 'email, password, repeat, two names, Other note, contact, phone, description, licence');

    j.step('a weak password and a different repeat are said on their fields; nothing is sent');
    await j.type(0, _email);
    await j.type(1, '123456');
    await j.type(2, '123457');
    await j.tapText(t((l) => l.hotelProviderSubmit), wait: const Duration(seconds: 1));
    await j.see(find.text(t((l) => l.hotelProviderAccountPasswordWeak)));
    await j.see(find.text(t((l) => l.hotelAccessSetupMismatch)));
    expect(j.screen, 'HL-PROV-01');
    expect(j.control.outbox.where((m) => m['kind'] == 'partner_application_verify'), isEmpty, reason: 'a form that fails validation sends nothing');

    j.step('the right password and the business: names, a category, the governorate, contact, phone, description');
    await j.type(1, _password);
    await j.type(2, _password);
    await j.type(3, j.isArabic ? 'بيت العدسة' : 'Lens House'); // the current language first
    await j.type(4, j.isArabic ? 'Lens House' : 'بيت العدسة');
    await j.tapText(t((l) => l.hotelProviderCatsChoose), wait: const Duration(seconds: 1));
    await j.tapText(j.isArabic ? 'تنسيق الزهور' : 'Floral arrangements');
    await j.tapText(t((l) => l.commonActionDone), wait: const Duration(seconds: 1));
    await j.tapText(j.isArabic ? 'حولي' : 'Hawalli');
    await j.type(6, 'Noura Al-Sabah');
    await j.type(7, '55512345');
    await j.type(8, 'Wedding florals for kosha, entrance and tables.');

    // ---------------------------------------------------------------------------------------------------------------- the code
    j.step('Send application: the account exists unverified, the code screen opens for the account email');
    await j.tapText(t((l) => l.hotelProviderSubmit), wait: const Duration(seconds: 3));
    await j.seeScreen('HL-ACCS-02');
    await j.see(find.text(t((l) => l.hotelAccessVerifyApplicationTitle)));
    expect(j.showsMatch(RegExp('@lens-house.example')), isTrue, reason: 'the masked account email');
    final code = mailedCode();

    j.step('a wrong code is refused on the cells; the code from the outbox opens the application under review');
    await j.type(0, '222222', wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelAccessVerifyWrong)));
    await j.type(0, code, wait: const Duration(seconds: 3));
    await j.seeScreen('HL-ACCS-04', timeout: const Duration(seconds: 20));
    await j.see(find.text(t((l) => l.hotelAccessStatusApplicationTitle)));
    expect(find.text(j.isArabic ? 'بيت العدسة' : 'Lens House'), findsWidgets);
    final sent = await serverApplication();
    expect(sent?.status, ApplicationStatus.pending);
    expect(sent?.email, _email);

    // ---------------------------------------------------------------------------------------------------------------- the staff accept
    j.step('Ghazal staff accept (the Super Admin web, here the mock control); the person returns and the status refetches');
    j.control.decidePartnerApplication(sent!.id, accept: true);
    await j.backgroundAndResume();
    await j.see(find.text(t((l) => l.hotelAccessStatusApprovedTitle)), why: 'the decision shows after the app returns');
    expect((await serverApplication())?.status, ApplicationStatus.accepted);
    await j.tapText(t((l) => l.commonActionContinue), wait: const Duration(seconds: 3));
    await j.seeScreen('HL-TODY-01');

    // ---------------------------------------------------------------------------------------------------------------- log out, sign in, listings
    j.step('log out, then sign in with the email and password she chose: straight to Today, no status in between');
    await j.tapKey('gz:tab.more', wait: const Duration(seconds: 2));
    await j.seeScreen('HL-SETT-01');
    await j.tapKey('more.logout', wait: const Duration(seconds: 1));
    await j.tapText(t((l) => l.hotelSettingsMoreLogout), wait: const Duration(seconds: 2));
    j.dropShellTeardownErrors(); // the known kit assertion of leaving the tab shell (see journey_world.dart)
    await j.seeScreen('HL-ACCS-01');
    await j.type(0, _email);
    await j.type(1, _password);
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 3));
    await j.seeScreen('HL-TODY-01', timeout: const Duration(seconds: 20));
    await j.see(find.text(t((l) => l.hotelTodayFirstRunNotifTitle)), why: 'a new sign-in: the first-run prompts are optional');
    await j.tapText(t((l) => l.hotelTodayFirstRunNotNow), wait: const Duration(seconds: 2));
    await j.tapText(t((l) => l.commonActionSkip), wait: const Duration(seconds: 2));
    await j.gone(find.text(t((l) => l.hotelTodayFirstRunLockTitle)));

    j.step('More > My listings > New opens the editor, no longer held back');
    await j.tapKey('gz:tab.more', wait: const Duration(seconds: 2));
    await j.tapText(t((l) => l.hotelSettingsMoreListings), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-PROV-02');
    await j.tapText(t((l) => l.hotelProviderListNew), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-PROV-03');
    await j.see(find.byType(EditableText), why: 'the editor');
    expect(find.text(t((l) => l.hotelProviderApprovalGuardTitle)), findsNothing);
  });
}
