// J9 (partner): a service provider's application is not approved, she edits it and sends it again, Ghazal staff accept it, the app continues to listings.
//
//   Owner round 2 (ADR 0038, PA-ACC-07, PA-ACC-08). OQ-R2-11 is open: how a brand-new partner gets a session before the form has no contract
//   answer yet (the API has partner sign-in by email, staff are invited, there is no self sign-up). So the journey starts from the SEEDED applicant
//   `provider_rejected` (Bader, Bader Decor), whose application the staff rejected with a reason; the blank first application is covered by the
//   flow test (`test/features/provider/application_flow_test.dart`, Zahra applying with a second account).
//   Sign in (email, password, the code of the new device): the account is held, so the app lands on the account status, not Today: "Application not
//   approved" with the staff's note and Edit and resubmit. The form comes back prefilled with the note on top; a bad email is marked inline, the
//   licence reference the staff asked for is added, Send application: "Application received", the status says "Application in review" (pending on
//   the server). The staff accept through the mock control, the person comes back to the app, the status refetches: "Application approved",
//   Continue opens Today, More > My listings > New opens the editor (it was held back until now).
// Real entry (`bootstrap()`), in-process mock. Run: `node apps/provider_app/integration_test/headless.mjs j9` (add `--lang ar` for Arabic) or, on
// a simulator, `flutter test integration_test/j9_apply_test.dart -d <id>` from apps/provider_app.
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerAccountRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, PartnerApplication;
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';

void main() {
  journeySetUp();

  journey('J9 partner: application not approved, edit and resubmit, the staff accept, listings open', (j) async {
    final c = await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);
    Future<PartnerApplication?> serverApplication() async =>
        (await c.read(partnerAccountRepositoryProvider).getPartnerMe()).memberships.where((m) => m.application != null).lastOrNull?.application;
    final reasonEn = RegExp('Please add your commercial licence reference');
    final reasonAr = RegExp('يرجى إضافة رقم الترخيص التجاري');

    // ---------------------------------------------------------------------------------------------------------------- sign in
    j.step('sign in as the applicant whose application was rejected (email, password, the code of the new device)');
    await j.seeScreen('HL-ACCS-01');
    if (kJourneyLang == 'ar') {
      await j.tapText('العربية', wait: const Duration(seconds: 1));
      expect(j.locale.languageCode, 'ar');
    }
    await j.type(0, 'bader@bader-decor.example');
    await j.type(1, 'Ghazal#2026');
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-ACCS-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));

    // ---------------------------------------------------------------------------------------------------------------- not approved
    j.step('the account is held: the status says Application not approved with the staff note, never Today');
    await j.seeScreen('HL-ACCS-04', timeout: const Duration(seconds: 20));
    await j.see(find.text(t((l) => l.hotelAccessStatusRejectedTitle)));
    expect(j.showsMatch(j.isArabic ? reasonAr : reasonEn), isTrue, reason: 'the reason the staff gave');
    expect(find.text(t((l) => l.hotelAccessStatusEditResubmit)), findsOneWidget);
    expect((await serverApplication())?.status, ApplicationStatus.rejected);

    j.step('Edit and resubmit: the form comes back prefilled with the staff note on top and no account type step');
    await j.tapText(t((l) => l.hotelAccessStatusEditResubmit), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-PROV-01');
    await j.see(find.text(t((l) => l.hotelProviderFormBarEdit)));
    expect(j.showsMatch(j.isArabic ? reasonAr : reasonEn), isTrue, reason: 'the note of the staff on top of the form');
    expect(find.text(t((l) => l.hotelProviderChooseTitle)), findsNothing);
    final typed = find.byType(EditableText).evaluate().map((e) => (e.widget as EditableText).controller.text).toList();
    expect(typed, contains('Bader Decor'));
    expect(typed, contains('bader@bader-decor.example'));

    // ---------------------------------------------------------------------------------------------------------------- validation, then send
    j.step('a bad email is marked on its field and nothing is sent');
    await j.type(5, 'bader-at-decor');
    await j.tapText(t((l) => l.hotelProviderSubmit), wait: const Duration(seconds: 1));
    await j.see(find.text(t((l) => l.hotelProviderFormEmailError)), why: 'the inline error of the email field');
    expect(find.text(t((l) => l.hotelProviderSubmittedTitle)), findsNothing);
    expect((await serverApplication())?.status, ApplicationStatus.rejected, reason: 'a form that fails validation sends nothing');

    j.step('the right email and the licence reference the staff asked for: Send application');
    await j.type(5, 'bader@bader-decor.example');
    await j.type(7, 'KW-77120');
    await j.tapText(t((l) => l.hotelProviderSubmit), wait: const Duration(seconds: 3));
    await j.see(find.text(t((l) => l.hotelProviderSubmittedTitle)), why: 'Application received');
    final sent = await serverApplication();
    expect(sent?.status, ApplicationStatus.pending, reason: 'back under review, the reason cleared');
    expect(sent?.rejectionReason, isNull);
    expect(sent?.licenceRef, 'KW-77120');

    j.step('Application status: Application in review (the wait), no way to list yet');
    await j.tapText(t((l) => l.hotelProviderSubmittedStatus), wait: const Duration(seconds: 2));
    j.dropShellTeardownErrors(); // the known kit assertion of leaving the tab shell (see journey_world.dart)
    await j.seeScreen('HL-ACCS-04');
    await j.see(find.text(t((l) => l.hotelAccessStatusApplicationTitle)));
    expect(find.text(t((l) => l.hotelAccessSupportAction)), findsOneWidget);

    // ---------------------------------------------------------------------------------------------------------------- the staff accept
    j.step('Ghazal staff accept (the Super Admin web, here the mock control); the person comes back to the app and the status refetches');
    j.control.decidePartnerApplication(sent!.id, accept: true);
    await j.backgroundAndResume();
    await j.see(find.text(t((l) => l.hotelAccessStatusApprovedTitle)), why: 'the decision shows after the app returns');
    expect((await serverApplication())?.status, ApplicationStatus.accepted);

    j.step('Continue: Today of the new account, then More > My listings > New opens the editor');
    await j.tapText(t((l) => l.commonActionContinue), wait: const Duration(seconds: 3));
    await j.seeScreen('HL-TODY-01');
    await j.tapKey('gz:tab.more', wait: const Duration(seconds: 2));
    await j.tapText(t((l) => l.hotelSettingsMoreListings), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-PROV-02');
    await j.tapText(t((l) => l.hotelProviderListNew), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-PROV-03');
    await j.see(find.byType(EditableText), why: 'the editor, no longer held back');
    expect(find.text(t((l) => l.hotelProviderApprovalGuardTitle)), findsNothing);
  });
}
