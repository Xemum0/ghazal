import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show requestsRepositoryProvider, reviewsRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingDetail, BookingRow, BookingStatus, Review, ReviewSort, Venue;

import '../../../app/state/state.dart';

/// Reviews of one venue (CL-RVRW-01).
final venueReviewsProvider = FutureProvider.autoDispose.family<List<Review>, ({String venueId, ReviewSort sort})>((ref, q) async {
  final page = await ref.watch(reviewsRepositoryProvider).listVenueReviews(venueId: q.venueId, sort: q.sort, limit: 50);
  return page.items;
});

/// A venue's face for the reviews screens.
final reviewVenueProvider = FutureProvider.autoDispose.family<Venue?, String>((ref, id) async {
  try {
    return (await ref.watch(venuesRepositoryProvider).getVenue(venueId: id)).venue;
  } on Object {
    return null;
  }
});

/// A completed booking at this venue (the only way to open the composer).
final reviewEligibilityProvider = FutureProvider.autoDispose.family<BookingDetail?, String>((ref, venueId) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return null;
  final page = await ref.watch(requestsRepositoryProvider).listRequests(limit: 50);
  for (final r in page.items) {
    if (r.booking.venueId == venueId && r.booking.status == BookingStatus.completed) {
      try {
        return await ref.watch(requestsRepositoryProvider).getRequest(requestId: r.booking.id);
      } on Object {
        return null;
      }
    }
  }
  return null;
});

/// An upcoming booking at this venue (reviews open after the event).
final reviewUpcomingProvider = FutureProvider.autoDispose.family<BookingDetail?, String>((ref, venueId) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return null;
  final page = await ref.watch(requestsRepositoryProvider).listRequests(limit: 50);
  BookingRow? best;
  for (final r in page.items) {
    if (r.booking.venueId != venueId) continue;
    if (r.booking.status == BookingStatus.pending || r.booking.status == BookingStatus.approved || r.booking.status == BookingStatus.confirmed) {
      best ??= r;
    }
  }
  if (best == null) return null;
  try {
    return await ref.watch(requestsRepositoryProvider).getRequest(requestId: best.booking.id);
  } on Object {
    return null;
  }
});

List<Review> filterReviews(List<Review> all, ReviewFilter filter, ReviewSort sort) {
  final list = switch (filter) {
    ReviewFilter.photos => all.where((r) => r.photos.isNotEmpty).toList(),
    ReviewFilter.five => all.where((r) => r.rating >= 4.5).toList(),
    // Scores come in half steps: 5 stars is 4.5 and up, 4 stars sits above 3.5 and below 4.5, "3 and below" takes 3.5 and under.
    ReviewFilter.four => all.where((r) => r.rating > 3.5 && r.rating < 4.5).toList(),
    ReviewFilter.low => all.where((r) => r.rating <= 3.5).toList(),
    ReviewFilter.all => [...all],
  };
  list.sort(switch (sort) {
    ReviewSort.highest => (a, b) => b.rating == a.rating ? b.postedAt.compareTo(a.postedAt) : b.rating.compareTo(a.rating),
    ReviewSort.lowest => (a, b) => a.rating == b.rating ? b.postedAt.compareTo(a.postedAt) : a.rating.compareTo(b.rating),
    _ => (a, b) => b.postedAt.compareTo(a.postedAt),
  });
  return list;
}

enum ReviewFilter { all, photos, five, four, low }
