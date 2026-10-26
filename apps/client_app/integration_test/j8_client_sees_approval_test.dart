// J8 (client, cross-app 3 of 3): Reem comes back to the app and finds the hotel's decision (J7 accepted her request); then the server clock moves.
//
//   Runs against the SAME standalone mock server after J6 and J7 (no reset). The app starts through its real bootstrap against the server and
//   restores Reem's session from the keychain (a host run has no keychain between processes: the journey signs her in with the server
//   session of her persona, the way the Demo tools do). Home says Approved and My Wedding carries its dot, the request detail (Majlis Hall,
//   16 Jan 2027, `--dart-define=EXPECT_REF=GZ-...` makes it the exact reference J6 printed) is Approved with the 24 h confirmation window
//   running ("24 h", read from the server's story clock) and the voucher code, with Confirm booking offered.
//   Then the clock of the SERVER is moved from outside, as another phone or curl would: +2 h and the person comes back to the app: 22 h left;
//   +24 h more: the window is over and the app, when it refetches, says the voucher is not valid and the request is gone from the waiting
//   list (forfeited, no money returned).
// Run (server, J6 and J7 first, see docs/engineering/flutter-dev.md "Cross-app"): headless `node apps/client_app/integration_test/headless.mjs j8 --remote`,
// on the iPhone 17e: `flutter test integration_test/j8_client_sees_approval_test.dart -d <id> --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<server>/v1`.
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, BookingStatus, VoucherStatus;

import 'support/cross_app.dart';
import 'support/journey_world.dart';
import 'support/server.dart';

const String kNewDate = '2027-01-16';

/// The reference J6 printed (`CROSS J6 request=GZ-...`), when the runner passes it on; empty: find the request by its day and its hotel.
const String kExpectRef = String.fromEnvironment('EXPECT_REF');

void main() {
  journeySetUp();

  journey('J8 client (cross-app): the hotel approved, 24 h window from the server clock, +2 h, +24 h: the voucher is forfeited', crossApp: true, semantics: true, (j) async {
    final c = await j.start(keepSession: true);
    String t(String Function(AppL10n l) pick) => j.t(pick);
    expect(c.read(remoteMockProvider), isNotNull, reason: 'the app found the mock server and follows its story clock');
    expect(await serverNow(), startsWith('2026-11-12T16:00'), reason: 'the world of J6 and J7: nothing moved the clock yet');

    j.step('the phone: Reem is still signed in (the keychain), or the host signs her in; the app speaks the journey language');
    if (c.read(sessionProvider) is ClientSession) {
      debugPrint('  . session restored from the keychain');
    } else {
      await c.read(sessionProvider.notifier).loadPersona('reem');
    }
    if (j.locale.languageCode != kJourneyLang) await j.useLanguage(kJourneyLang);
    expect(c.read(sessionProvider), isA<ClientSession>());
    Future<Booking> mine() async {
      final all = (await c.read(requestsRepositoryProvider).listRequests()).items.map((r) => r.booking).where((b) => b.venueId == 'V01' && b.eventDate.toString() == kNewDate);
      final found = all.where((b) => kExpectRef.isEmpty || b.ref == kExpectRef).toList();
      expect(found, hasLength(1), reason: 'Reem has exactly one request for 16 Jan 2027 at Aurelia');
      return found.single;
    }

    final request = await mine();
    debugPrint('CROSS J8 request=${request.ref} status=${request.status.value} confirmBy=${request.confirmBy}');
    expect(request.status, BookingStatus.approved, reason: 'the hotel accepted it in J7');

    // ---------------------------------------------------------------------------------------------------------------- Home
    j.step('Home: the request the hotel approved, with the dot on My Wedding');
    await j.seeScreen('CL-DISC-01', timeout: const Duration(seconds: 20));
    final weddingDot = find.descendant(of: find.byKey(const ValueKey<String>('gz:tab.my-wedding')), matching: find.byKey(const ValueKey<String>('gz:tab.badge')));
    await j.see(weddingDot, why: 'the dot of My Wedding: something waits for the client');
    await j.see(find.byKey(const ValueKey<String>('discover.status')));
    await j.see(find.text(t((l) => l.commonStatusApproved)), why: 'the status card says the hotel approved');

    // ---------------------------------------------------------------------------------------------------------------- the request
    j.step('request detail: Approved, the 24 h confirmation window, the voucher, Confirm booking');
    await j.tapKey('discover.status', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BKNG-02');
    await j.see(find.text(t((l) => l.commonStatusApproved)));
    expect(j.shows(request.ref), isTrue, reason: 'the reference of the request Reem sent in J6');
    expect(j.shows(j.format.plain(j.format.date(kNewDate, DateStyle.compact))) || j.shows(j.format.plain(j.format.date(kNewDate, DateStyle.full))), isTrue, reason: 'the day: 16 Jan 2027');
    expect(j.showsMatch(RegExp(r'24\s*(h|س)')), isTrue, reason: 'the window has just opened on the server clock: 24 h left');
    expect(j.shows('GV-'), isTrue, reason: 'the voucher the request carries');
    await j.see(find.text(t((l) => l.clientBookingConfirmAction)));

    // ---------------------------------------------------------------------------------------------------------------- the clock
    j.step('the server clock moves +2 h from outside (another phone, curl); Reem comes back to the app: 22 h left');
    await j.advanceServer(const Duration(hours: 2));
    await j.backgroundAndResume();
    await j.seeMatch(RegExp(r'22\s*(h|س)'), why: 'the countdown read the new server clock');
    expect(j.showsMatch(RegExp(r'24\s*(h|س)')), isFalse, reason: 'no stale 24 h left');
    expect((await mine()).status, BookingStatus.approved, reason: 'two hours in, the window is still open');

    j.step('the server clock moves +24 h: the confirmation window is over; the app refetches and says the voucher is forfeited');
    await j.advanceServer(const Duration(hours: 24));
    await j.backgroundAndResume();
    await j.seeMatch(RegExp(RegExp.escape(t((l) => l.clientBookingsOutcomeForfeitedTitle))), why: 'the app refetched the request and says the voucher is not valid');
    await j.see(find.text(t((l) => l.commonStatusExpired)), why: 'the status of the request is no longer Approved');
    expect(j.shows(t((l) => l.clientBookingsExpiredConfirmTitle)), isTrue, reason: 'the confirmation time ended');
    expect(j.shows(t((l) => l.clientBookingConfirmAction)), isFalse, reason: 'Confirm booking is no longer offered');
    expect(j.shows(t((l) => l.commonStatusApproved)), isFalse, reason: 'no stale Approved pill');
    final after = await mine();
    expect(after.status, BookingStatus.expired, reason: 'the server lapsed the request when the 24 h window ran out');
    final wallet = (await c.read(vouchersRepositoryProvider).listVouchers(limit: 50)).items.map((w) => w.voucher).where((v) => v.id == request.voucherId).toList();
    expect(wallet, hasLength(1), reason: 'the voucher of the request is in the wallet');
    expect(wallet.single.status, VoucherStatus.forfeited, reason: 'forfeited: not valid and it never returns (no money is returned)');
    final waiting = (await c.read(requestsRepositoryProvider).listRequests()).items.map((r) => r.booking).where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.approved);
    expect(waiting.map((b) => b.ref), isNot(contains(request.ref)), reason: 'the request left the waiting lists');
    debugPrint('CROSS J8 after +26 h request=${request.ref} status=${after.status.value} voucher=${wallet.single.status.value} serverClock=${await serverNow()}');
  });
}
