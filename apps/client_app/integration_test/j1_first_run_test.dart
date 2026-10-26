// J1 (client): the first run, from the language choice to a sent request.
//
//   language, onboarding (who, date, guests, areas), Home with the Brief, Results, the venue, the guest gate on "Get voucher", the sign-in
//   as Reem (phone + WhatsApp code), the voucher explainer that the sign-in resumes (alone: the Face ID offer and the two Briefs wait in the
//   sheet queue), the KD 2 voucher checkout at the mock gateway, the voucher ready (the first calm moment: the Face ID offer), the request in
//   five steps, "Request sent" and the request itself, then Home (the two Briefs ask there).
//
// Real entry (`bootstrap()`), in-process mock, story clock 12 Nov 2026 16:00; nothing is set up through providers except what the person
// cannot do (the mock's gateway is the mock's own page, a real tap on Submit). The wedding date is 21 Jan 2027, not the hero's 14 Jan:
// Reem already holds a voucher for 14 Jan at Aurelia and Lumi Marina, so the checkout needs a date she has none for.
// Run: `node apps/client_app/integration_test/headless.mjs j1` (add `--lang ar` for Arabic) or, on a simulator,
// `flutter test integration_test/j1_first_run_test.dart -d <id> [--dart-define=JOURNEY_LANG=ar]` from apps/client_app.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/auth/application/auth_actions.dart' show kBiometricPromptId;
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'support/journey_world.dart';

/// The wedding date of this journey (a Thursday with the hotel free).
const String kDate = '2027-01-21';

void main() {
  journeySetUp();

  // semantics on, as for a VoiceOver user: the gate sign-in brings the venue page back with its Booking Thread preview animating below the
  // fold, which broke Flutter 3.47.5's semantics pass in Arabic until `GzDrawOnce` left the semantics tree (a framework error fails the journey)
  journey('J1 client first run: language, onboarding, Home, Results, venue, gate, OTP as Reem, KD 2 checkout, request sent', semantics: true, (j) async {
    final c = await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);

    // ---------------------------------------------------------------------------------------------------------------- language
    j.step('language: the first screen offers both languages and the choice is the language of the app');
    await j.seeScreen('CL-ONBD-01');
    await j.see(find.text(en.clientOnboardingLanguageNativeEn), why: 'the English tile');
    await j.see(find.text(en.clientOnboardingLanguageNativeAr), why: 'the Arabic tile');
    await j.tapText(kJourneyLang == 'ar' ? en.clientOnboardingLanguageNativeAr : en.clientOnboardingLanguageNativeEn, wait: const Duration(milliseconds: 1200));
    expect(j.locale.languageCode, kJourneyLang);
    final direction = Directionality.of(j.tester.element(find.byType(GzScreen).first));
    expect(direction, kJourneyLang == 'ar' ? TextDirection.rtl : TextDirection.ltr, reason: 'the whole screen mirrored in place');
    await j.tapText(t((l) => l.commonActionContinue));

    // ---------------------------------------------------------------------------------------------------------------- onboarding
    j.step('intro: three slides, then Get started');
    await j.seeScreen('CL-ONBD-02');
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide1Title)));
    await j.tapText(t((l) => l.commonActionNext));
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide2Title)));
    await j.tapText(t((l) => l.commonActionNext));
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide3Title)));
    await j.tapText(t((l) => l.clientOnboardingIntroStart));

    j.step('who is planning: a role and a name');
    await j.seeScreen('CL-ONBD-03');
    await j.see(find.text(t((l) => l.clientOnboardingAboutTitle)));
    await j.tapText(t((l) => l.clientOnboardingAboutRoleBride), wait: const Duration(milliseconds: 400));
    await j.type(0, 'Reem');
    await j.tapText(t((l) => l.commonActionContinue));

    j.step('the date: two months on, the 21st');
    await j.seeScreen('CL-ONBD-04');
    await j.see(find.text(t((l) => l.clientOnboardingDateTitle)));
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(j.dayLabel(kDate));
    await j.tapText(t((l) => l.commonActionContinue));

    j.step('guests and budget: the suggested 350 stand');
    await j.seeScreen('CL-ONBD-05');
    await j.see(find.textContaining('350', findRichText: true), why: 'the suggested guest count');
    await j.tapText(t((l) => l.commonActionContinue));

    j.step('areas: Salmiya, then the arrow finishes onboarding');
    await j.seeScreen('CL-ONBD-06');
    await j.tapText(kJourneyLang == 'ar' ? 'السالمية' : 'Salmiya', wait: const Duration(milliseconds: 900));
    await j.tap(find.byWidgetPredicate((w) => w is GzButton && w.iconEnd == GzIcons.arrowRight).last, wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- Home
    j.step('Home: the Brief the person just gave, a count of free halls, the shelves');
    await j.seeScreen('CL-DISC-01');
    await j.see(find.byKey(const ValueKey<String>('discover.briefcard')));
    expect(j.textUnder('discover.row.date'), allOf(contains('21'), contains('2027')), reason: 'the Brief card says the date');
    expect(c.read(searchBriefProvider).date.toString(), kDate);
    expect(c.read(searchBriefProvider).areaIds, <String>['salmiya']);
    await j.see(find.byKey(const ValueKey<String>('discover.shelves')));
    await j.tapKey('discover.cta', wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- Results
    j.step('Results: the hall that is free, its voucher price locked behind the account');
    await j.seeScreen('CL-DISC-03');
    await j.see(find.byKey(const ValueKey<String>('discover.card.V05')), why: 'the free hall of the Brief');
    expect(j.onScreen('discover.voucherlock'), isTrue, reason: 'a guest sees the voucher price behind a lock');
    await j.tapKey('discover.card.V05', wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- venue and gate
    j.step('venue: the detail, with Get voucher as the primary path');
    await j.seeScreen('CL-VENU-01');
    await j.see(find.byKey(const ValueKey<String>('venue.packages')));
    await j.see(find.text(t((l) => l.clientVenueCtaGetVoucher)));
    j.step('gate: a guest asking for the voucher meets the account sheet with the voucher reason');
    await j.tapText(t((l) => l.clientVenueCtaGetVoucher), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-01');
    expect(c.read(gateProvider)?.reason, GateReason.voucher);
    await j.see(find.text(t((l) => l.clientAuthSharedSendCode)));

    // ---------------------------------------------------------------------------------------------------------------- sign in
    j.step('OTP: the phone of Reem, the WhatsApp code, any six digits');
    await j.type(0, '50000012');
    await j.tapText(t((l) => l.clientAuthSharedSendCode), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));
    await j.see(find.byWidgetPredicate((w) => w is GzSheet || w is GzScreen), why: 'the app after the code');
    final session = c.read(sessionProvider);
    expect(session, isA<ClientSession>(), reason: 'the code signed the person in');
    expect((session as ClientSession).user.phone, '+96550000012', reason: 'the number resolved to the hero client');

    j.step('after sign-in: the voucher explainer resumes and stays alone (the Briefs and the Face ID offer wait in the sheet queue)');
    await j.seeScreen('CL-VCHR-01');
    await j.pump(const Duration(seconds: 3)); // well past the 400 ms and 900 ms the prototype stacks them at
    expect(j.screen, 'CL-VCHR-01', reason: 'no sheet opened over the explainer');
    await j.gone(find.text(t((l) => l.clientAuthSharedNotNow)));
    expect(j.onScreen('discover.merge.keep.phone'), isFalse, reason: 'the two Briefs belong to Home');
    expect(c.read(sheetQueueProvider).waiting, <String>['brief-merge', kBiometricPromptId], reason: 'both are waiting for a calm moment');

    // ---------------------------------------------------------------------------------------------------------------- voucher checkout
    j.step('explainer: the binding and the one price, Pay KD 2');
    await j.see(find.text(t((l) => l.clientVouchersExplainerTitle)));
    final payLabel = t((l) => l.clientVouchersPayFee(j.format.money(2000)));
    await j.see(find.text(payLabel), why: 'the primary action names the KD 2 fee');
    await j.tapKey('voucher.explainer.pay', wait: const Duration(seconds: 2));

    j.step('pay: KD 2.000 exactly, the methods, Pay now');
    await j.seeScreen('CL-PAYM-01');
    await j.see(find.byWidgetPredicate((w) => w is GzPrice && w.fils == 2000), why: 'the voucher price, the only money paid in the app');
    await j.see(find.byKey(const ValueKey<String>('pay.methods')));
    await j.tapText(t((l) => l.clientPaymentCtaPay), wait: const Duration(seconds: 3));

    j.step('gateway (the mock\'s hosted page): Submit, then the app verifies and never trusts the redirect');
    await j.seeScreen('CL-PAYM-02');
    await j.see(find.text(t((l) => l.clientPaymentGatewayTitle)));
    await j.tapText(t((l) => l.clientPaymentBankSubmit), wait: const Duration(seconds: 1));
    await j.seeScreen('CL-PAYM-05', timeout: const Duration(seconds: 25));
    await j.see(find.text(t((l) => l.clientPaymentDoneTitle)));
    expect(j.shows('GV-'), isTrue, reason: 'the voucher code is on the ticket');
    j.step('first completed payment: the Face ID offer opens now, the first calm moment (Not now)');
    await j.see(find.text(t((l) => l.clientAuthBioTurnOn)), timeout: const Duration(seconds: 8), why: 'the biometric offer after the payment');
    await j.tapText(t((l) => l.clientAuthSharedNotNow), wait: const Duration(milliseconds: 1500));
    expect(j.screen, 'CL-PAYM-05');

    // ---------------------------------------------------------------------------------------------------------------- the request
    j.step('request: five steps with the voucher already attached');
    await j.tapText(t((l) => l.clientPaymentDoneCta), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BOOK-01');
    await j.see(find.text(t((l) => l.clientBookingEventTitle)));
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-02');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-03');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-04');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-05');
    await j.see(find.text(t((l) => l.clientBookingReviewTitle)));
    j.step('review: the consent first, then Send request');
    await j.tap(find.byType(GzCheckbox), wait: const Duration(milliseconds: 600));
    await j.tapText(t((l) => l.clientBookingSend), wait: const Duration(seconds: 3));

    j.step('sent: Request sent, the reference, the voucher code; the request is pending');
    await j.seeScreen('CL-BOOK-06');
    await j.see(find.text(t((l) => l.clientBookingSentTitle)));
    expect(j.shows('GZ-'), isTrue, reason: 'the request reference');
    expect(j.shows('GV-'), isTrue, reason: 'the voucher it carries');
    expect(c.read(bookingDraftProvider).requestId, isNotNull);
    await j.tapTextIfShown(t((l) => l.clientBookingSentNotifNo), timeout: const Duration(seconds: 3));
    await j.tapText(t((l) => l.clientBookingSentView), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BKNG-02');
    await j.see(find.text(t((l) => l.commonStatusPending)), why: 'the request waits for the hotel');

    j.step('Home: the one screen the Briefs belong to; nothing else is open, so they ask now (keep this phone)');
    await j.tapKey('gz:tab.discover', wait: const Duration(milliseconds: 200));
    await j.see(find.byKey(const ValueKey<String>('discover.merge.keep.phone')), timeout: const Duration(seconds: 8), why: 'the Brief merge sheet');
    expect(j.screen, 'CL-DISC-02', reason: 'the sheet is the top of the stack, over Home');
    await j.tapKey('discover.merge.keep.phone', wait: const Duration(milliseconds: 1500));
    await j.seeScreen('CL-DISC-01');
    expect(c.read(searchBriefProvider).date.toString(), kDate, reason: 'the date the person picked on this phone was kept');
    expect(c.read(sheetQueueProvider).waiting, isEmpty);
    final mine = (await c.read(requestsRepositoryProvider).listRequests()).items.where((r) => r.booking.venueId == 'V05' && r.booking.status == BookingStatus.pending);
    expect(mine, isNotEmpty, reason: 'the request is on the server, pending');
  });
}
