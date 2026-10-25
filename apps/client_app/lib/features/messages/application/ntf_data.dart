import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Area, LocalizedText, NearbyVenue;

/// The name of a venue (the subject line of a notification row); null when the venue cannot be read (no longer listed).
final venueNameProvider = FutureProvider.family<LocalizedText?, String>((ref, id) async {
  try {
    return (await ref.watch(venuesRepositoryProvider).getVenue(venueId: id)).venue.name;
  } on Object {
    return null;
  }
});

/// The nearest halls of a venue that has left Ghazal.
final nearbyVenuesProvider = FutureProvider.family<List<NearbyVenue>, String>(
  (ref, id) => ref.watch(venuesRepositoryProvider).listNearbyVenues(venueId: id),
);

/// The areas by id (for the area fact of a nearby hall).
final areaByIdProvider = FutureProvider<Map<String, Area>>((ref) async {
  final r = await ref.watch(venuesRepositoryProvider).listAreas();
  return <String, Area>{for (final a in r.areas) a.id: a};
});
