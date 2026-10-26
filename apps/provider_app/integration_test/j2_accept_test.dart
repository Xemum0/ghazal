// J2 (partner): Hind, manager of Aurelia Gulf Hotel, signs in, finds the pending request on Today, opens it, accepts, and uses the 8 s undo window.
//
//   email + password (a wrong password first), the code for the new device, the first-run prompts, Today with the queue, the Bookings tab,
//   the hero request (Reem, 14 Jan 2027), Accept: the Approved toast with Undo, the request says Waiting, Undo: it is Pending again on the
//   server; Accept once more and let the 8 s window close for real: the approval stands, Undo is gone.
// Real entry (`bootstrap()`), in-process mock. Run: `node apps/provider_app/integration_test/headless.mjs j2` (add `--lang ar` for Arabic) or,
// on a simulator, `flutter test integration_test/j2_accept_test.dart -d <id>` from apps/provider_app.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerRequestsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';

const String kHero = 'bk-GZ-2611-0147';

void main() {
  journeySetUp();

  journey('J2 partner: sign in, Today, open the pending request, accept, the undo window', (j) async {
    final c = await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);
    Future<BookingStatus> serverStatus() async => (await c.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: kHero)).booking.status;

    // ---------------------------------------------------------------------------------------------------------------- sign in
    j.step('sign in: a wrong password says so in words and keeps the form');
    await j.seeScreen('HL-ACCS-01');
    if (kJourneyLang == 'ar') {
      await j.tapText('العربية', wait: const Duration(seconds: 1)); // the language link of the sign-in screen
      expect(j.locale.languageCode, 'ar');
    }
    await j.see(find.text(t((l) => l.hotelAccessSigninSubmit)));
    await j.type(0, 'hind@aurelia-gulf.example');
    await j.type(1, 'not-the-password');
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelAccessSigninInvalid)), why: 'the plain refusal');
    expect(j.screen, 'HL-ACCS-01');

    j.step('sign in: the right password, then the code of the new device (any six digits)');
    await j.type(1, 'Ghazal#2026');
    await j.tapText(t((l) => l.hotelAccessSigninSubmit), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-ACCS-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));
    await j.seeScreen('HL-TODY-01', timeout: const Duration(seconds: 20));

    // ---------------------------------------------------------------------------------------------------------------- Today
    j.step('first run: the notification prompt and the app-lock prompt are both optional');
    await j.see(find.text(t((l) => l.hotelTodayFirstRunNotifTitle)), why: 'the first-run notifications sheet');
    await j.tapText(t((l) => l.hotelTodayFirstRunNotNow), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelTodayFirstRunLockTitle)), why: 'the app-lock sheet');
    await j.tapText(t((l) => l.commonActionSkip), wait: const Duration(seconds: 2));
    await j.gone(find.text(t((l) => l.hotelTodayFirstRunLockTitle)));

    j.step('Today: the venue, the queue that needs the manager, the calendar strip');
    await j.see(find.byKey(const ValueKey<String>('gz:tab.today')));
    expect(j.screen, 'HL-TODY-01');
    await j.see(find.text(t((l) => l.hotelTodayNeedsYouTitle)));
    expect(find.descendant(of: find.byKey(const ValueKey<String>('gz:tab.bookings')), matching: find.byKey(const ValueKey<String>('gz:tab.badge'))), findsOneWidget, reason: 'the Bookings tab counts the pending requests');

    // ---------------------------------------------------------------------------------------------------------------- Bookings and the request
    j.step('Bookings: the pending requests, the hero request among them');
    await j.tapKey('gz:tab.bookings', wait: const Duration(seconds: 2));
    await j.seeScreen('HL-BOOK-01');
    final card = find.byKey(const ValueKey<String>('triage.$kHero'));
    await j.see(card, why: 'the request of Reem for 14 Jan 2027');
    j.step('open the request: the detail says Pending with Accept and Decline');
    await j.tap(find.descendant(of: card, matching: find.byType(GzPressable)).first, wait: const Duration(seconds: 2));
    await j.seeScreen('HL-BOOK-03');
    await j.see(find.text(t((l) => l.commonStatusHotelPending)));
    await j.see(find.text(t((l) => l.commonActionAccept)));
    await j.see(find.text(t((l) => l.commonActionDecline)));
    expect(j.shows('GZ-2611-0147'), isTrue, reason: 'the reference of the request');
    expect(await serverStatus(), BookingStatus.pending);

    // ---------------------------------------------------------------------------------------------------------------- accept and undo
    j.step('accept: the Approved toast carries Undo for 8 s, the request now waits for the couple');
    await j.tapText(t((l) => l.commonActionAccept), wait: const Duration(milliseconds: 1500));
    await j.see(find.text(t((l) => l.commonActionUndo)), why: 'the undo bar of the approval');
    await j.see(find.text(t((l) => l.commonStatusHotelApproved)), why: 'the request waits for the couple');
    expect(await serverStatus(), BookingStatus.approved);

    j.step('undo inside the window: the request is Pending again, on screen and on the server');
    await j.tapText(t((l) => l.commonActionUndo), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.commonStatusHotelPending)), why: 'back to pending after Undo');
    await j.see(find.text(t((l) => l.commonActionAccept)));
    expect(await serverStatus(), BookingStatus.pending, reason: 'Undo took the approval back');

    j.step('accept again and let the 8 s window close for real: the approval stands, Undo is gone');
    await j.tapText(t((l) => l.commonActionAccept), wait: const Duration(milliseconds: 1500));
    await j.see(find.text(t((l) => l.commonActionUndo)));
    await j.pump(const Duration(seconds: 10));
    await j.gone(find.text(t((l) => l.commonActionUndo)), timeout: const Duration(seconds: 8));
    await j.see(find.text(t((l) => l.commonStatusHotelApproved)));
    await j.see(find.text(t((l) => l.hotelBookingsRevokeApproval)), why: 'after the window the only way back is to revoke');
    expect(await serverStatus(), BookingStatus.approved, reason: 'the window closed on an approved request');
  });
}
