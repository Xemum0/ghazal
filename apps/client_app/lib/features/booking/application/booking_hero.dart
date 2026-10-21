import 'package:client_app/app/state/state.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// The hero story of the prototype (web `HERO_BOOKING`, `design/src/screens/client/booking/_components/flow.ts` STORY): Reem asks Aurelia Gulf
/// Hotel for Danah Ballroom, ladies' reception, Thu 14 Jan 2027, 350 guests, with voucher GV-2611-K7QM. A booking screen opened with no route
/// params and no draft shows it, so the harness and the demo tools can open any step directly.
const String kHeroVenueId = 'V01';
const String kHeroHallId = 'V01-danah';
const String kHeroSessionId = 'V01-danah-evening';
const String kHeroPackageId = 'V01-ladies-weekend';
const LocalDate kHeroDate = LocalDate(2027, 1, 14);
const Audience kHeroAudience = Audience.women;
const int kHeroGuests = 350;
const String kHeroVoucherId = 'vch-GV-2611-K7QM';
const String kHeroBookingId = 'bk-GZ-2611-0147';

/// The hero draft shown while the real draft is empty.
BookingDraft heroDraft() => const BookingDraft(
  venueId: kHeroVenueId,
  hallId: kHeroHallId,
  sessionId: kHeroSessionId,
  packageId: kHeroPackageId,
  eventDate: kHeroDate,
  audience: kHeroAudience,
  guests: kHeroGuests,
  voucherId: kHeroVoucherId,
);
