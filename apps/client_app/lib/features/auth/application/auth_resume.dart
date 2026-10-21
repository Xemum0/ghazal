import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, Venue;

/// The hero story's request (Reem's request to the first venue, Thu 14 Jan 2027, 350 guests): what the gate shows when no draft is open.
abstract final class AuthStory {
  static const String venueId = 'V01';
  static const LocalDate date = LocalDate(2027, 1, 14);
  static const int guests = 350;
}

/// What waits on the other side of the sign-in: the venue, the date and the guests of the interrupted request.
class AuthResume {
  const AuthResume({required this.venue, required this.date, required this.guests});

  final Venue venue;
  final LocalDate date;
  final int guests;
}

/// The booking draft when there is one, the shared story otherwise.
final FutureProvider<AuthResume?> authResumeProvider = FutureProvider<AuthResume?>((ref) async {
  final draft = ref.watch(bookingDraftProvider);
  final id = draft.venueId ?? AuthStory.venueId;
  final detail = await ref.watch(venuesRepositoryProvider).getVenue(venueId: id);
  return AuthResume(venue: detail.venue, date: draft.eventDate ?? AuthStory.date, guests: draft.guests ?? AuthStory.guests);
});
