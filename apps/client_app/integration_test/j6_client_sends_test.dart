// J6 (client, cross-app 1 of 3): Reem sends a NEW request to Aurelia Gulf Hotel against the standalone mock server; J7 (partner) finds it.
//
//   The server world is reset (clock 12 Nov 2026 16:00, the hero request of 14 Jan 2027 in Danah Ballroom pending, five requests waiting at
//   Aurelia). The app starts through its real bootstrap against the server (it probes it and follows its story clock), the first run goes by,
//   Reem signs in with the WhatsApp code at the voucher gate, and the new request is for the OTHER hall (Majlis Hall) on a DIFFERENT day
//   (Saturday 16 Jan 2027, picked in the calendar sheet because the Brief's 21 Jan is not free in that hall): venue, hall switch, calendar
//   sheet, Get voucher, the KD 2 checkout at the mock gateway, the five booking steps, Send request. The reference, date and hall are
//   printed for J7 and J8 (`CROSS J6 ...`) and the request is read back from the server.
// Run (server first, see docs/engineering/flutter-dev.md "Cross-app"): headless `node apps/client_app/integration_test/headless.mjs j6 --remote`,
// on the iPhone 17e: `flutter test integration_test/j6_client_sends_test.dart -d <id> --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<server>/v1`.
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'support/cross_app.dart';
import 'support/journey_world.dart';
import 'support/server.dart';

/// The Brief of the first run (a Thursday): Majlis Hall is booked that day, so the person opens the calendar sheet.
const String kBriefDate = '2027-01-21';

/// The day of the new request (a Saturday, free in Majlis Hall; the hero request is for 14 Jan in Danah Ballroom).
const String kNewDate = '2027-01-16';
const String kHeroRef = 'GZ-2611-0147';

void main() {
  journeySetUp();

  journey('J6 client (cross-app): first run, Reem signs in, Majlis Hall on 16 Jan 2027, KD 2 voucher, request sent to Aurelia', crossApp: true, semantics: true, (j) async {
    final c = await j.start(resetServer: true);
    String t(String Function(AppL10n l) pick) => j.t(pick);
    final start = await serverNow();
    expect(start, startsWith('2026-11-12T16:00'), reason: 'the server world was just seeded');
    expect(c.read(remoteMockProvider), isNotNull, reason: 'the app found the mock server and follows its story clock');

    // ---------------------------------------------------------------------------------------------------------------- first run
    j.step('language, intro, who, date 21 Jan, guests, area Sharq (the area of Aurelia Gulf Hotel)');
    await j.seeScreen('CL-ONBD-01');
    await j.tapText(kJourneyLang == 'ar' ? en.clientOnboardingLanguageNativeAr : en.clientOnboardingLanguageNativeEn, wait: const Duration(milliseconds: 1200));
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-ONBD-02');
    await j.tapText(t((l) => l.commonActionNext));
    await j.tapText(t((l) => l.commonActionNext));
    await j.tapText(t((l) => l.clientOnboardingIntroStart));
    await j.seeScreen('CL-ONBD-03');
    await j.tapText(t((l) => l.clientOnboardingAboutRoleBride), wait: const Duration(milliseconds: 400));
    await j.type(0, 'Reem');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-ONBD-04');
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(t((l) => l.commonCalendarNextMonth));
    await j.tapNamed(j.dayLabel(kBriefDate));
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-ONBD-05');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-ONBD-06');
    await j.tapText(kJourneyLang == 'ar' ? 'شرق' : 'Sharq', wait: const Duration(milliseconds: 900));
    await j.tap(find.byWidgetPredicate((w) => w is GzButton && w.iconEnd == GzIcons.arrowRight).last, wait: const Duration(seconds: 2));

    // ---------------------------------------------------------------------------------------------------------------- Home, Results, venue
    j.step('Home, then Results: Aurelia Gulf Hotel, the hotel of the Partner app');
    await j.seeScreen('CL-DISC-01');
    await j.tapKey('discover.cta', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-DISC-03');
    await j.see(find.byKey(const ValueKey<String>('discover.card.V01')), why: 'Aurelia Gulf Hotel among the halls of the Brief');
    await j.tapKey('discover.card.V01', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-VENU-01');
    await j.see(find.byKey(const ValueKey<String>('venue.V01.body')));

    j.step('venue: the other hall (Majlis Hall), then the date row opens the calendar sheet');
    await j.tapText(kJourneyLang == 'ar' ? 'قاعة المجلس' : 'Majlis Hall', wait: const Duration(seconds: 2));
    await j.tapNamed(RegExp(RegExp.escape(t((l) => l.clientVenueDateLabel))), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-VENU-03');
    await j.see(find.byKey(const ValueKey<String>('venue.cal.V01')));

    j.step('calendar sheet: the Brief day is not free in Majlis Hall; Saturday 16 Jan is, with the voucher price');
    await j.tapNamed(j.dayLabel(kNewDate), wait: const Duration(seconds: 2));
    await j.see(find.byKey(const ValueKey<String>('venue.cal.focus')));
    await j.see(find.byWidgetPredicate((w) => w is GzStatusPill && w.status == GzStatus.available), why: 'the chosen day is free');
    j.step('Get voucher, as a guest: the account sheet with the voucher reason');
    await j.tapText(t((l) => l.clientVenueCtaGetVoucher), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-01');
    expect(c.read(gateProvider)?.reason, GateReason.voucher);

    // ---------------------------------------------------------------------------------------------------------------- sign in as Reem
    j.step('OTP: the phone of Reem, the WhatsApp code 123456');
    await j.type(0, '50000012');
    await j.tapText(t((l) => l.clientAuthSharedSendCode), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));
    await j.seeScreen('CL-VCHR-01', timeout: const Duration(seconds: 20));
    final session = c.read(sessionProvider);
    expect(session, isA<ClientSession>(), reason: 'the code signed Reem in');
    expect((session as ClientSession).user.phone, '+96550000012');

    // ---------------------------------------------------------------------------------------------------------------- voucher checkout
    j.step('explainer then Pay KD 2, the mock gateway, the voucher is ready');
    await j.see(find.text(t((l) => l.clientVouchersExplainerTitle)));
    await j.tapKey('voucher.explainer.pay', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-PAYM-01');
    await j.see(find.byWidgetPredicate((w) => w is GzPrice && w.fils == 2000), why: 'the only money paid in the app');
    await j.tapText(t((l) => l.clientPaymentCtaPay), wait: const Duration(seconds: 3));
    await j.seeScreen('CL-PAYM-02');
    await j.tapText(t((l) => l.clientPaymentBankSubmit), wait: const Duration(seconds: 1));
    await j.seeScreen('CL-PAYM-05', timeout: const Duration(seconds: 25));
    await j.see(find.text(t((l) => l.clientPaymentDoneTitle)));
    await j.see(find.text(t((l) => l.clientAuthBioTurnOn)), timeout: const Duration(seconds: 8), why: 'the biometric offer after the first payment');
    await j.tapText(t((l) => l.clientAuthSharedNotNow), wait: const Duration(milliseconds: 1500));

    // ---------------------------------------------------------------------------------------------------------------- the request
    j.step('request: five steps with the voucher attached, the consent, Send request');
    await j.tapText(t((l) => l.clientPaymentDoneCta), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BOOK-01');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-02');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-03');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-04');
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-BOOK-05');
    await j.see(find.text(t((l) => l.clientBookingReviewTitle)));
    await j.tap(find.byType(GzCheckbox), wait: const Duration(milliseconds: 600));
    await j.tapText(t((l) => l.clientBookingSend), wait: const Duration(seconds: 3));

    j.step('sent: Request sent with the reference of the NEW request');
    await j.seeScreen('CL-BOOK-06');
    await j.see(find.text(t((l) => l.clientBookingSentTitle)));
    final ref = j.firstMatch(RegExp(r'GZ-\d{4}-[0-9A-Z]{4}'));
    expect(ref, isNotNull, reason: 'the request reference is on the screen');
    expect(ref, isNot(kHeroRef), reason: 'a new request, not the seeded hero request');
    expect(j.shows('Aurelia Gulf Hotel') || j.shows('فندق أوريليا الخليج'), isTrue, reason: 'the hotel of the request');
    expect(j.shows(j.format.plain(j.format.date(kNewDate, DateStyle.compact))), isTrue, reason: 'the day of the request: 16 Jan 2027, not the hero 14 Jan');
    expect(j.shows(kJourneyLang == 'ar' ? 'قاعة المجلس' : 'Majlis Hall'), isTrue, reason: 'the hall of the request');
    await j.tapTextIfShown(t((l) => l.clientBookingSentNotifNo), timeout: const Duration(seconds: 3));
    await j.tapText(t((l) => l.clientBookingSentView), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BKNG-02');
    await j.see(find.text(t((l) => l.commonStatusPending)), why: 'the request waits for the hotel');

    // ---------------------------------------------------------------------------------------------------------------- what the server holds
    j.step('the server holds it: pending at V01, for 16 Jan 2027, next to the hero request');
    final mine = (await c.read(requestsRepositoryProvider).listRequests()).items.map((r) => r.booking).where((b) => b.venueId == 'V01' && b.status == BookingStatus.pending).toList();
    expect(mine.map((b) => b.ref), containsAll(<String>[kHeroRef, ref!]), reason: 'Reem has two requests waiting at Aurelia now');
    final sent = mine.singleWhere((b) => b.ref == ref);
    expect(sent.eventDate.toString(), kNewDate);
    final pendingAtAurelia = ((await serverCall('state'))['counts']! as Map)['Booking'];
    debugPrint('CROSS J6 request=$ref id=${sent.id} date=${sent.eventDate} hall=Majlis serverClock=${await serverNow()} bookings=$pendingAtAurelia');
  });
}
