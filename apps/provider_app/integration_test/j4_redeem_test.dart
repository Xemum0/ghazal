// J4 (partner): the couple is at the hotel with a confirmed booking; reception redeems the voucher by its code.
//
//   Hind is signed in, the hero story is `confirmed` (control surface), Today's Redeem shortcut opens the scanner, the Code mode takes a
//   typed code (a wrong one is refused on the field, nothing changes), the right one shows what the voucher is for, Redeem voucher finishes
//   with the Redeemed sheet (by whom and when), View booking shows the request Redeemed with no decision left, and the server agrees.
// Run: `node apps/provider_app/integration_test/headless.mjs j4` (or on a simulator `flutter test integration_test/j4_redeem_test.dart -d <id>`).
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerRequestsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';

const String kHero = 'bk-GZ-2611-0147';

void main() {
  journeySetUp();

  journey('J4 partner: redeem the voucher by code', (j) async {
    final c = await j.start(persona: 'hotel_manager');
    String t(String Function(AppL10n l) pick) => j.t(pick);
    Future<BookingStatus> serverStatus() async => (await c.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: kHero)).booking.status;

    j.step('the couple confirmed (story point), the manager comes back to the app: Today offers Redeem');
    await j.seeScreen('HL-TODY-01');
    j.control.jumpToStory('confirmed');
    await j.backgroundAndResume();
    expect(await serverStatus(), BookingStatus.confirmed);
    await j.see(find.text(t((l) => l.hotelTodayRedeem)));
    await j.tapText(t((l) => l.hotelTodayRedeem), wait: const Duration(seconds: 2));

    j.step('scanner: switch to typing the code; a code that does not exist is refused on the field and changes nothing');
    await j.seeScreen('HL-BOOK-06');
    await j.see(find.text(t((l) => l.commonRedeemVoucher)));
    await j.tapNamed(t((l) => l.hotelBookingsModeType));
    await j.see(find.text(t((l) => l.hotelBookingsCheckCode)));
    await j.type(0, 'ZZZZ9999');
    await j.tapText(t((l) => l.hotelBookingsCheckCode), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelBookingsErrUnknownField)), why: 'the plain refusal of an unknown code');
    expect(j.screen, 'HL-BOOK-06');
    expect(await serverStatus(), BookingStatus.confirmed, reason: 'a refused code changes nothing');

    j.step('the right code: the quote of what it is for (guest, hall, package, date, price)');
    await j.type(0, 'GV-2611-K7QM');
    await j.tapText(t((l) => l.hotelBookingsCheckCode), wait: const Duration(seconds: 2));
    await j.see(find.text(t((l) => l.hotelBookingsTryAnother)), why: 'a code that can be redeemed shows its quote');
    expect(j.shows('K7QM'), isTrue, reason: 'the voucher code');
    if (!j.isArabic) expect(j.shows('Danah Ballroom'), isTrue, reason: 'the hall of the booking');
    expect(j.showsMatch(RegExp('ريم')), isTrue, reason: 'the guest, as written by her');

    j.step('Redeem voucher: the Redeemed sheet says by whom and when');
    await j.tapText(t((l) => l.commonRedeemVoucher), wait: const Duration(seconds: 3));
    await j.seeScreen('HL-BOOK-07');
    await j.see(find.text(t((l) => l.hotelBookingsRedeemedPlain)));
    if (!j.isArabic) expect(j.shows('Hind Al-Enezi'), isTrue, reason: 'who redeemed it');
    expect(await serverStatus(), BookingStatus.redeemed);

    j.step('View booking: the request is Redeemed and offers no decision');
    await j.tapText(t((l) => l.hotelBookingsViewBooking), wait: const Duration(seconds: 2));
    await j.seeScreen('HL-BOOK-03');
    await j.see(find.text(t((l) => l.commonStatusHotelRedeemed)));
    await j.gone(find.text(t((l) => l.commonRedeemVoucher)));
    await j.gone(find.text(t((l) => l.commonActionAccept)));
  });
}
