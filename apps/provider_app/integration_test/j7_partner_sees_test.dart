// J7 (partner, cross-app 2 of 3): Hind, manager of Aurelia Gulf Hotel, finds the request Reem sent in the Client app (J6) and accepts it.
//
//   Runs against the SAME standalone mock server right after J6 (no reset). The app starts through its real bootstrap against the server,
//   Hind signs in (a wrong password first, then the code of the new device: the server was just seeded), the first-run prompts are skipped,
//   Today and the Bookings badge count SIX waiting requests (five seeded plus the new one), the Bookings tab lists the new request (Reem,
//   Majlis Hall, 16 Jan 2027; `--dart-define=EXPECT_REF=GZ-...` makes it the exact reference J6 printed), the detail says Pending, Accept: the
//   Approved toast with Undo, the 8 s window closes for real, the approval stands on the server and the waiting count is five again.
// Run (server and J6 first, see docs/engineering/flutter-dev.md "Cross-app"): headless
// `node apps/provider_app/integration_test/headless.mjs j7 --remote`, on the iPhone 17:
// `flutter test integration_test/j7_partner_sees_test.dart -d <id> --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<server>/v1 [--dart-define=EXPECT_REF=GZ-...]`.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerRequestsRepositoryProvider, remoteMockProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, RequestSegment;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';
import 'support/server.dart';

/// The day J6 asked for (a Saturday; the hero request is for 14 Jan) and the seeded number of waiting requests at Aurelia.
const String kNewDate = '2027-01-16';
const int kSeededPending = 5;

/// The reference J6 printed (`CROSS J6 request=GZ-...`), when the runner passes it on; empty: find the request by its day and its hall.
const String kExpectRef = String.fromEnvironment('EXPECT_REF');

void main() {
  journeySetUp();

  journey('J7 partner (cross-app): sign in, the new request of Reem is pending (6), open it, accept, the approval stands', crossApp: true, (j) async {
    final c = await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);
    expect(c.read(remoteMockProvider), isNotNull, reason: 'the app found the mock server and follows its story clock');
    expect(await serverNow(), startsWith('2026-11-12T16:00'), reason: 'the world of J6: nothing moved the clock');
    final repo = c.read(partnerRequestsRepositoryProvider);

    // ---------------------------------------------------------------------------------------------------------------- sign in
    j.step('sign in: Hind, a wrong password first (the plain refusal), then the right one');
    await j.seeScreen('HL-ACCS-01');
    if (kJourneyLang == 'ar') await j.tapText('العربية', wait: const Duration(seconds: 1));
    await j.type(0, 'hind@aurelia-gulf.example');
    await j.type(1, 'not-the-password');
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelAccessSigninInvalid)), why: 'the plain refusal');
    await j.type(1, 'Ghazal#2026');
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 2));

    j.step('new device: the server asks for the emailed code (a known device goes straight in)');
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (j.screen != 'HL-ACCS-02' && j.screen != 'HL-TODY-01') {
      if (DateTime.now().isAfter(end)) fail('neither the code screen nor Today after the password: ${j.dump()}');
      await j.pump(const Duration(milliseconds: 200));
    }
    if (j.screen == 'HL-ACCS-02') await j.type(0, '123456', wait: const Duration(seconds: 3));
    await j.seeScreen('HL-TODY-01', timeout: const Duration(seconds: 20));

    // ---------------------------------------------------------------------------------------------------------------- Today
    j.step('first run: the two optional prompts, skipped');
    await j.tapTextIfShown(t((l) => l.hotelTodayFirstRunNotNow), timeout: const Duration(seconds: 6));
    await j.tapTextIfShown(t((l) => l.commonActionSkip), timeout: const Duration(seconds: 6));
    await j.see(find.text(t((l) => l.hotelTodayNeedsYouTitle)));

    j.step('the server says six requests wait at Aurelia: the five seeded and the one Reem sent from the Client app');
    final waiting = (await repo.listPartnerRequests(segment: RequestSegment.pending, limit: 50)).items.map((r) => r.booking).toList();
    expect(waiting, hasLength(kSeededPending + 1), reason: 'five seeded, one new');
    final fresh = waiting.where((b) => b.eventDate.toString() == kNewDate && (kExpectRef.isEmpty || b.ref == kExpectRef)).toList();
    expect(fresh, hasLength(1), reason: 'exactly one waiting request for 16 Jan 2027${kExpectRef.isEmpty ? '' : ' with the reference $kExpectRef'}');
    final request = fresh.single;
    debugPrint('CROSS J7 sees request=${request.ref} id=${request.id} client=${request.clientName} date=${request.eventDate} waiting=${waiting.length}');
    final badge = find.descendant(of: find.byKey(const ValueKey<String>('gz:tab.bookings')), matching: find.byKey(const ValueKey<String>('gz:tab.badge')));
    await j.see(badge, why: 'the Bookings tab counts the waiting requests');
    expect(j.textUnder('gz:tab.bookings'), contains('6'), reason: 'the tab bar says 6 waiting (it was 5 in J2)');

    // ---------------------------------------------------------------------------------------------------------------- Bookings
    j.step('Bookings: the new request is listed (Reem, the day, the hall)');
    await j.tapKey('gz:tab.bookings', wait: const Duration(seconds: 2));
    await j.seeScreen('HL-BOOK-01');
    final card = find.byKey(ValueKey<String>('triage.${request.id}'));
    await j.see(card, why: 'the request Reem sent from her phone');
    final text = j.textUnder('triage.${request.id}');
    debugPrint('  . the card reads: $text');
    // the card prints the day without its year (`Sat 16 Jan`)
    expect(text, contains(j.format.plain(j.format.date(kNewDate, DateStyle.short)).replaceFirst(RegExp(r'\s*2027'), '')), reason: 'the card shows the new day, not 14 Jan');

    j.step('open it: Pending, with Accept and Decline, the reference of the request');
    await j.tap(find.descendant(of: card, matching: find.byType(GzPressable)).first, wait: const Duration(seconds: 2));
    await j.seeScreen('HL-BOOK-03');
    await j.see(find.text(t((l) => l.commonStatusHotelPending)));
    await j.see(find.text(t((l) => l.commonActionAccept)));
    await j.see(find.text(t((l) => l.commonActionDecline)));
    expect(j.shows(request.ref), isTrue, reason: 'the reference of the new request');
    expect(j.shows(j.format.plain(j.format.date(kNewDate, DateStyle.compact))) || j.shows(j.format.plain(j.format.date(kNewDate, DateStyle.full))), isTrue, reason: 'the day of the request');

    // ---------------------------------------------------------------------------------------------------------------- accept
    j.step('accept: the Approved toast carries Undo; the 8 s window closes for real and the approval stands');
    await j.tapText(t((l) => l.commonActionAccept), wait: const Duration(milliseconds: 1500));
    await j.see(find.text(t((l) => l.commonActionUndo)), why: 'the undo bar of the approval');
    await j.see(find.text(t((l) => l.commonStatusHotelApproved)), why: 'the request now waits for the couple');
    await j.pump(const Duration(seconds: 10));
    await j.gone(find.text(t((l) => l.commonActionUndo)), timeout: const Duration(seconds: 8));
    await j.see(find.text(t((l) => l.hotelBookingsRevokeApproval)), why: 'after the window the only way back is to revoke');
    final after = (await repo.getPartnerRequest(requestId: request.id)).booking;
    expect(after.status, BookingStatus.approved, reason: 'the server holds the approval');
    expect(after.confirmBy, isNotNull, reason: 'the 24 h confirmation window of the client started');
    final left = (await repo.listPartnerRequests(segment: RequestSegment.pending, limit: 50)).items;
    expect(left, hasLength(kSeededPending), reason: 'five wait again');
    debugPrint('CROSS J7 accepted request=${request.ref} status=${after.status.value} approvedAt=${after.approvedAt} confirmBy=${after.confirmBy} serverClock=${await serverNow()}');
  });
}
