// J1 (client): the first run, from the language choice to a sent request (no guest mode since ADR 0038).
//
//   language, the introduction (Get started goes to the sign-in), the sign-in with a NEW number (phone + WhatsApp code), "About you"
//   (name, sex, terms), the three optional wedding steps (the name comes from the account), Home with the Brief and the Face ID offer,
//   Results by governorate (the Brief sheet's Governorates chips), the venue, the voucher explainer (alone: nothing is gated), the KD 2
//   voucher checkout at the mock gateway, the voucher ready, the request in four steps, "Request sent" and the request itself.
//
// Real entry (`bootstrap()`), in-process mock, story clock 12 Nov 2026 16:00; nothing is set up through providers except what the person
// cannot do (the mock's gateway is the mock's own page, a real tap on Submit). The wedding date is 21 Jan 2027, not the hero's 14 Jan.
// Run: `node apps/client_app/integration_test/headless.mjs j1` (add `--lang ar` for Arabic) or, on a simulator,
// `flutter test integration_test/j1_first_run_test.dart -d <id> [--dart-define=JOURNEY_LANG=ar]` from apps/client_app.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, Sex;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'support/journey_world.dart';

/// The wedding date of this journey (a Thursday with the hotel free).
const String kDate = '2027-01-21';

/// A number the mock has never seen: its first code creates an incomplete account (name and sex are asked next).
const String kNewNumber = '50001234';

void main() {
  journeySetUp();

  // semantics on, as for a VoiceOver user: the venue page with its Booking Thread preview animating below the fold broke Flutter 3.47.5's
  // semantics pass in Arabic until `GzDrawOnce` left the semantics tree (a framework error fails the journey)
  journey('J1 client first run: language, sign-in, About you, optional steps, Home, Results by governorate, venue, KD 2 checkout, request sent', semantics: true, (j) async {
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

    // ---------------------------------------------------------------------------------------------------------------- introduction
    j.step('intro: three slides, then Get started, which opens the sign-in (never Home)');
    await j.seeScreen('CL-ONBD-02');
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide1Title)));
    await j.tapText(t((l) => l.commonActionNext));
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide2Title)));
    await j.tapText(t((l) => l.commonActionNext));
    await j.see(find.text(t((l) => l.clientOnboardingIntroSlide3Title)));
    await j.tapText(t((l) => l.clientOnboardingIntroStart));

    // ---------------------------------------------------------------------------------------------------------------- sign in
    j.step('sign-in: a full screen, the phone first; a new number, the WhatsApp code, any six digits');
    await j.seeScreen('CL-AUTH-01');
    expect(c.read(sessionProvider).isSignedIn, isFalse, reason: 'nothing but the first-run screens is open to a signed-out client');
    await j.see(find.text(t((l) => l.clientAuthSharedSendCode)));
    await j.type(0, kNewNumber);
    await j.tapText(t((l) => l.clientAuthSharedSendCode), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));

    j.step('About you: the name, the sex as one of two tiles and the terms are all required');
    await j.seeScreen('CL-AUTH-03', timeout: const Duration(seconds: 15));
    expect((c.read(sessionProvider) as ClientSession).isNewUser, isTrue, reason: 'the code created an incomplete account');
    await j.tapText(t((l) => l.commonActionContinue), wait: const Duration(milliseconds: 600));
    expect(j.screen, 'CL-AUTH-03', reason: 'nothing given: the person stays and the three fields say Required');
    await j.type(0, 'Nora Al-Salem');
    await j.tapText(t((l) => l.clientAuthNameSexFemale), wait: const Duration(milliseconds: 400));
    await j.tapText(t((l) => l.clientAuthNameAccept), wait: const Duration(milliseconds: 400));
    await j.tapText(t((l) => l.commonActionContinue), wait: const Duration(seconds: 3));

    // ---------------------------------------------------------------------------------------------------------------- optional steps
    j.step('who is planning: the name is prefilled from the account and the role suggested from the sex');
    await j.seeScreen('CL-ONBD-03', timeout: const Duration(seconds: 15));
    expect((c.read(sessionProvider) as ClientSession).isNewUser, isFalse, reason: 'completeProfile finished the account');
    await j.see(find.text(t((l) => l.clientOnboardingAboutTitle)));
    await j.see(find.text('Nora Al-Salem'), why: 'the name came from About you');
    await j.tapText(t((l) => l.commonActionContinue));

    j.step('the date: two months on, the 21st');
    await j.seeScreen('CL-ONBD-04');
    await j.see(find.text(t((l) => l.clientOnboardingDateTitle)));
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(j.dayLabel(kDate));
    await j.tapText(t((l) => l.commonActionContinue));

    j.step('guests and budget, the last of three steps: the suggested 350 stand, Done opens Home');
    await j.seeScreen('CL-ONBD-05');
    await j.see(find.textContaining('350', findRichText: true), why: 'the suggested guest count');
    await j.tapText(t((l) => l.commonActionDone), wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- Home
    j.step('Home: the Brief the person just gave (no region asked), a count of free halls, the shelves');
    await j.seeScreen('CL-DISC-01');
    await j.see(find.byKey(const ValueKey<String>('discover.briefcard')));
    expect(j.textUnder('discover.row.date'), allOf(contains('21'), contains('2027')), reason: 'the Brief card says the date');
    expect(c.read(searchBriefProvider).date.toString(), kDate);
    expect(c.read(searchBriefProvider).governorateIds, isEmpty, reason: 'every governorate until the person narrows');
    await j.see(find.byKey(const ValueKey<String>('discover.shelves')));
    j.step('the first calm screen: the Face ID offer opens (Not now)');
    await j.see(find.text(t((l) => l.clientAuthBioTurnOn)), timeout: const Duration(seconds: 8), why: 'the biometric offer after the sign-in');
    await j.tapText(t((l) => l.clientAuthSharedNotNow), wait: const Duration(milliseconds: 1500));
    expect(j.screen, 'CL-DISC-01');

    // ---------------------------------------------------------------------------------------------------------------- Results by governorate
    j.step('Governorates: the Brief sheet lists chips, never areas; Hawalli narrows the search');
    await j.tapKey('discover.row.area', wait: const Duration(seconds: 1));
    await j.seeScreen('CL-DISC-02');
    await j.see(find.byKey(const ValueKey<String>('discover.brief.area')));
    await j.tapText(kJourneyLang == 'ar' ? 'حولي' : 'Hawalli', wait: const Duration(milliseconds: 600));
    await j.tapKey('discover.brief.done', wait: const Duration(milliseconds: 600));
    await j.tapKey('discover.brief.cta', wait: const Duration(seconds: 2));
    expect(c.read(searchBriefProvider).governorateIds, <String>['hawalli']);

    j.step('Results: the hall that is free in that governorate, its voucher price');
    await j.seeScreen('CL-DISC-03');
    await j.see(find.byKey(const ValueKey<String>('discover.card.V05')), why: 'the free hall of the Brief');
    expect(j.onScreen('discover.voucherlock'), isFalse, reason: 'there is no locked voucher price: everyone here is signed in');
    await j.tapKey('discover.card.V05', wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- venue
    j.step('venue: the detail, with Get voucher as the primary path and no link to other services');
    await j.seeScreen('CL-VENU-01');
    await j.see(find.byKey(const ValueKey<String>('venue.packages')));
    await j.see(find.text(t((l) => l.clientVenueCtaGetVoucher)));
    await j.tapText(t((l) => l.clientVenueCtaGetVoucher), wait: const Duration(seconds: 2));

    j.step('after Get voucher: the explainer opens at once and stays alone (no gate, no sheet over it)');
    await j.seeScreen('CL-VCHR-01');
    await j.pump(const Duration(seconds: 2));
    expect(j.screen, 'CL-VCHR-01', reason: 'no sheet opened over the explainer');

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

    // ---------------------------------------------------------------------------------------------------------------- the request
    j.step('request: four steps with the voucher already attached (event, package, details, review; no extras)');
    await j.tapText(t((l) => l.clientPaymentDoneCta), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BOOK-01');
    await j.see(find.text(t((l) => l.clientBookingEventTitle)));
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-02');
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

    final account = await c.read(profileRepositoryProvider).getMe();
    expect(account.user.sex, Sex.female, reason: 'the sex given at About you is stored on the account');
    final mine = (await c.read(requestsRepositoryProvider).listRequests()).items.where((r) => r.booking.venueId == 'V05' && r.booking.status == BookingStatus.pending);
    expect(mine, isNotEmpty, reason: 'the request is on the server, pending');
  });
}
