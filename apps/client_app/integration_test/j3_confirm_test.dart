// J3 (client): the hotel approved the request; the client confirms inside the 24 h window and the booking thread shows it.
//
//   the app is signed in as Reem with her request pending; the hero story is moved to `approved` through the mock's control surface (the
//   hotel's decision happens elsewhere), time moves two hours, the person comes back to the app, the Home card says Approved and the My
//   Wedding tab carries its dot, the request detail shows the confirm window running, Confirm booking asks for the consent first, then the
//   booking is confirmed (voucher code shown "at venue") and the booking thread shows it.
// Run: `node apps/client_app/integration_test/headless.mjs j3` (or on a simulator `flutter test integration_test/j3_confirm_test.dart -d <id>`).
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show requestsRepositoryProvider;

import 'support/journey_world.dart';

void main() {
  journeySetUp();

  journey('J3 client: approved request, confirm inside 24 h, the booking thread shows it', (j) async {
    final c = await j.start(persona: 'reem');
    String t(String Function(AppL10n l) pick) => j.t(pick);

    j.step('Home: the request waits for the hotel (Pending, a countdown), no dot on My Wedding yet');
    await j.seeScreen('CL-DISC-01');
    await j.see(find.byKey(const ValueKey<String>('discover.status')));
    await j.see(find.text(t((l) => l.commonStatusPending)), why: 'the status card of the hero request');
    final weddingDot = find.descendant(of: find.byKey(const ValueKey<String>('gz:tab.my-wedding')), matching: find.byKey(const ValueKey<String>('gz:tab.badge')));
    expect(weddingDot, findsNothing, reason: 'nothing waits for the client yet');

    j.step('the hotel approves (control surface), two hours pass, the person comes back to the app');
    j.control.jumpToStory('approved');
    await j.advance(const Duration(hours: 2));
    await j.backgroundAndResume();
    await j.see(find.text(t((l) => l.commonStatusApproved)), why: 'the status card after the approval');
    await j.see(weddingDot, why: 'the dot of My Wedding: something waits for the client');

    j.step('request detail: Approved, the confirm window running (22 of 24 hours left), the thread, Confirm booking');
    await j.tapKey('discover.status', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BKNG-02');
    await j.see(find.byType(GzBookingThread), why: 'the booking thread');
    await j.see(find.text(t((l) => l.commonStatusApproved)));
    expect(j.showsMatch(RegExp(r'22\s*(h|س)')), isTrue, reason: 'the clock moved two of the 24 hours: 22 h left');
    expect(j.shows('GV-'), isTrue, reason: 'the voucher the request carries');
    await j.see(find.text(t((l) => l.clientBookingConfirmAction)));

    j.step('confirm sheet: the consent comes first (nothing is sent without it)');
    await j.tapText(t((l) => l.clientBookingConfirmAction), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-BOOK-08');
    await j.see(find.byType(GzCheckbox));
    await j.tapText(t((l) => l.clientBookingConfirmAction), wait: const Duration(seconds: 1));
    expect(j.screen, 'CL-BOOK-08', reason: 'without the consent the request stays unconfirmed');
    await j.tap(find.byType(GzCheckbox), wait: const Duration(milliseconds: 600));
    await j.tapText(t((l) => l.clientBookingConfirmAction), wait: const Duration(seconds: 3));

    j.step('done: Booking confirmed, the voucher code to show at the venue');
    await j.seeScreen('CL-BOOK-09');
    await j.see(find.text(t((l) => l.clientBookingDoneHeading)));
    expect(j.shows('GV-'), isTrue, reason: 'the code to show at the venue');
    await j.tapText(t((l) => l.clientBookingDoneView), wait: const Duration(seconds: 2));

    j.step('the booking thread now says Confirmed, the badge is gone, the server agrees');
    await j.seeScreen('CL-BKNG-02');
    await j.see(find.text(t((l) => l.commonStatusConfirmed)));
    await j.see(find.byType(GzBookingThread));
    await j.gone(find.text(t((l) => l.clientBookingConfirmAction)));
    await j.gone(weddingDot);
    final mine = (await c.read(requestsRepositoryProvider).listRequests()).items.where((r) => r.booking.venueId == 'V01' && r.booking.status == BookingStatus.confirmed);
    expect(mine, isNotEmpty, reason: 'the request is confirmed on the server');
  });
}
