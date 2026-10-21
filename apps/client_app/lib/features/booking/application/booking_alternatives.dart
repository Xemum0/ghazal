import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

/// What a lost date can be replaced with (CL-BOOK-07, CL-BOOK-10): the nearest free dates of the same hall, and similar halls free on the
/// same date. Prices are the lowest the server shows for the guests, in the voucher column when there is one.
@immutable
final class AltDate {
  const AltDate({required this.date, required this.fils});

  final LocalDate date;
  final int fils;
}

@immutable
final class AltHall {
  const AltHall({required this.venue, required this.fils, required this.minutes});

  final VenueSummary venue;
  final int fils;
  final int minutes;
}

@immutable
final class AltQuery {
  const AltQuery({required this.venueId, required this.hallId, required this.date, required this.guests, required this.audience, this.dates = true});

  final String venueId;
  final String? hallId;
  final LocalDate date;
  final int guests;
  final Audience audience;

  /// Also look for free dates of this hall (the confirm screens only need similar halls).
  final bool dates;

  @override
  bool operator ==(Object other) =>
      other is AltQuery &&
      other.venueId == venueId &&
      other.hallId == hallId &&
      other.date == date &&
      other.guests == guests &&
      other.audience == audience &&
      other.dates == dates;

  @override
  int get hashCode => Object.hash(venueId, hallId, date, guests, audience, dates);
}

typedef Alternatives = ({List<AltDate> dates, List<AltHall> halls});

final bookingAlternativesProvider = FutureProvider.autoDispose.family<Alternatives, AltQuery>((ref, q) async {
  final venues = ref.watch(venuesRepositoryProvider);
  // The areas of the Brief, else the areas the couple said they search in (the wedding profile).
  var areaIds = ref.read(searchBriefProvider).areaIds;
  if (areaIds.isEmpty && ref.read(sessionProvider).isSignedIn) {
    try {
      areaIds = (await ref.watch(weddingProfileProvider.future))?.areaIds ?? const <String>[];
    } on Object {
      areaIds = const <String>[];
    }
  }
  final dates = <AltDate>[];
  if (q.dates && q.hallId != null) {
    final days = <AvailabilityDay>[];
    for (var n = 0; n < 3; n++) {
      final first = LocalDate(q.date.year, q.date.month + n, 1);
      final last = LocalDate(q.date.year, q.date.month + n + 1, 1).addDays(-1);
      try {
        days.addAll(
          (await venues.getVenueAvailability(
            venueId: q.venueId,
            from: first,
            to: last,
            hallId: q.hallId,
            guests: q.guests,
            audience: q.audience,
          )).days,
        );
      } on ApiProblem {
        break;
      }
    }
    final here = days.where((d) => d.date == q.date).firstOrNull;
    final free = days.where((d) => d.state == DayState.available && d.fromPrice != null && d.date != q.date).toList();
    final sameTier = free.where((d) => d.date.isAfter(q.date) && (here == null || d.tier == here.tier)).toList();
    final pool = sameTier.length >= 3 ? sameTier : [...sameTier, ...free.where((d) => !sameTier.contains(d) && d.date.isAfter(q.date))];
    for (final d in pool.take(3)) {
      dates.add(AltDate(date: d.date, fils: (d.voucherPrice ?? d.fromPrice!).fils));
    }
  }
  final halls = <AltHall>[];
  try {
    final page = await venues.searchVenues(
      date: q.date,
      guests: q.guests,
      audience: q.audience,
      availableOnDate: true,
      originId: areaIds.isEmpty ? null : 'ref-${areaIds.first}',
      limit: 12,
    );
    for (final r in page.items) {
      final price = r.price;
      if (r.venue.id == q.venueId || r.availability != VenueDayState.available || price is! CardPriceExact) continue;
      halls.add(AltHall(venue: r.venue, fils: (price.voucher ?? price.amount).fils, minutes: r.distance?.minutes ?? 0));
    }
    halls.sort((a, b) => a.minutes.compareTo(b.minutes));
  } on ApiProblem {
    // similar halls are an extra: the dates and the other ways out stay
  }
  return (dates: dates, halls: halls.take(2).toList());
});
