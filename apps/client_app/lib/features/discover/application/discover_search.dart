import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart' show SearchBrief, clientDataRevisionProvider;
import 'discover_filters.dart';
import 'discover_home.dart' show shelfVenueIds;

/// The reference point distances are measured from (the first area of the reference list): the client chooses governorates, which have none.
const String kDiscoverOrigin = 'ref-salmiya';

/// Everything a result list depends on: the Brief, the filters, the order and the name search.
@immutable
final class DiscoverQuery {
  const DiscoverQuery({required this.brief, required this.filters, this.sort = DiscoverSort.recommended, this.query = ''});

  final SearchBrief brief;
  final DiscoverFilters filters;
  final DiscoverSort sort;
  final String query;

  DiscoverQuery copyWith({SearchBrief? brief, DiscoverFilters? filters, DiscoverSort? sort, String? query}) =>
      DiscoverQuery(brief: brief ?? this.brief, filters: filters ?? this.filters, sort: sort ?? this.sort, query: query ?? this.query);

  @override
  bool operator ==(Object other) => other is DiscoverQuery && other.brief == brief && other.filters == filters && other.sort == sort && other.query == query;

  @override
  int get hashCode => Object.hash(brief, filters, sort, query);
}

/// The Brief's category tiles as the filters the API understands (the home categories of the mock use the same rules).
({List<VenueType> types, List<VenueStyle> styles, List<LuxuryLevel> tiers}) categoryFilters(HomeCategoryId id) => switch (id) {
  HomeCategoryId.luxuryHotels => (types: const <VenueType>[VenueType.hotel], styles: const <VenueStyle>[], tiers: const <LuxuryLevel>[]),
  HomeCategoryId.weddingHalls => (types: const <VenueType>[VenueType.privateHall], styles: const <VenueStyle>[], tiers: const <LuxuryLevel>[]),
  HomeCategoryId.government => (types: const <VenueType>[VenueType.governmental], styles: const <VenueStyle>[], tiers: const <LuxuryLevel>[]),
  HomeCategoryId.beach => (types: const <VenueType>[], styles: const <VenueStyle>[VenueStyle.resort], tiers: const <LuxuryLevel>[]),
  HomeCategoryId.outdoor => (types: const <VenueType>[], styles: const <VenueStyle>[VenueStyle.outdoor, VenueStyle.villa], tiers: const <LuxuryLevel>[]),
  HomeCategoryId.vip => (types: const <VenueType>[], styles: const <VenueStyle>[], tiers: const <LuxuryLevel>[LuxuryLevel.prestige]),
  HomeCategoryId.unknown => (types: const <VenueType>[], styles: const <VenueStyle>[], tiers: const <LuxuryLevel>[]),
};

/// Whole dinars per guest of a card price on [voucher] or standard terms (half dinars rounded, like the prototype), null when the price
/// is not per guest (a flat night, a rental fee).
double? perGuestKd(CardPrice? price, {required bool voucher}) {
  if (price == null) return null;
  final int? fils;
  switch (price) {
    case CardPriceExact():
      fils = _per(voucher ? price.voucher : price.amount, price.guests);
    case CardPriceFromGuests():
      fils = _per(voucher ? price.voucher : price.amount, price.guests);
    case CardPriceFromMinimum():
      fils = (voucher ? price.voucherPerGuest : price.perGuest)?.fils;
    case CardPriceFlatNight() || CardPriceRentalFee():
      fils = null;
  }
  return fils == null ? null : (fils / 500).round() / 2;
}

int? _per(MoneyAmount? total, int guests) => total == null || guests <= 0 ? null : (total.fils / guests).round();

/// The first word of a hotel's own name: its brand (Aurelia, Madar ...). Null for a venue that is not a hotel.
String? hotelBrand(VenueSummary v, String lang) {
  if (v.type != VenueType.hotel) return null;
  final words = v.name.of(lang).split(' ');
  if (lang == 'ar' && words.first == 'فندق' && words.length > 1) return words[1];
  return words.first;
}

/// Whether a venue offers a facility (CA-FLT-06): the web's `hasFacility` over the amenities and halls of the venue detail.
bool venueHasFacility(Venue v, DiscoverFacility key) {
  AmenityState? state(String id) {
    for (final a in v.amenities) {
      if (a.amenityId == id) return a.state;
    }
    return null;
  }

  switch (key) {
    case DiscoverFacility.parking:
      return state('parking') == AmenityState.included;
    case DiscoverFacility.valet:
      return state('valet') == AmenityState.included || state('valet') == AmenityState.extra;
    case DiscoverFacility.bridal:
      final s = state('bridal-suite');
      return s != null && s != AmenityState.notOffered;
    case DiscoverFacility.buffet:
      return state('buffet') == AmenityState.included;
    case DiscoverFacility.decor:
      return <String>['basic-decor', 'kosha', 'florals'].any((id) => state(id) == AmenityState.included);
    case DiscoverFacility.photography:
      return v.halls.any((h) => h.sections.any((s) => s.policy.photography != PhotographyPolicy.none));
  }
}

/// The venue detail behind a result (halls and amenities, which a result row does not carry). Read only when a filter needs it.
final venueFactsProvider = FutureProvider.autoDispose.family<Venue, String>((ref, id) async {
  final detail = await ref.watch(venuesRepositoryProvider).getVenue(venueId: id);
  return detail.venue;
});

/// The venue search for a [DiscoverQuery]: the API's filters go to the API, the ones it cannot do yet (drive time, price ranges, setting,
/// facilities, brand, a shelf's halls) are applied here (`requests.md`). A held hall counts as available (ADR 0001), so availability is
/// decided here too: the API's `availableOnDate` keeps free halls only.
final discoverSearchProvider = FutureProvider.autoDispose.family<List<VenueResult>, DiscoverQuery>((ref, q) async {
  ref.watch(clientDataRevisionProvider);
  final repo = ref.watch(venuesRepositoryProvider);
  final f = q.filters;
  final brief = q.brief;
  final cat = f.category == null ? null : categoryFilters(f.category!);
  final types = <VenueType>{...f.types, ...?cat?.types}.toList();
  final sort = switch (q.sort) {
    DiscoverSort.recommended => VenueSort.recommended,
    DiscoverSort.voucherPrice => VenueSort.voucherPrice,
    DiscoverSort.rating => VenueSort.rating,
    DiscoverSort.newest => VenueSort.newest,
    DiscoverSort.price || DiscoverSort.priceDesc => VenueSort.price,
    DiscoverSort.distance => VenueSort.distance,
  };
  final range = f.dates;
  final rows = <VenueResult>[];
  String? cursor;
  var pages = 0;
  do {
    final page = await repo.searchVenues(
      q: q.query.trim().isEmpty ? null : q.query.trim(),
      governorateIds: f.governorateIds == null || f.governorateIds!.isEmpty ? null : f.governorateIds,
      allAreas: f.governorateIds != null && f.governorateIds!.isEmpty ? true : null,
      briefGovernorateIds: f.governorateIds == null && f.shelf == null && brief.governorateIds.isNotEmpty ? brief.governorateIds : null,
      types: types.isEmpty ? null : types,
      styles: cat == null || cat.styles.isEmpty ? null : cat.styles,
      tiers: <LuxuryLevel>{...f.levels, ...?cat?.tiers}.isEmpty ? null : <LuxuryLevel>{...f.levels, ...?cat?.tiers}.toList(),
      capacityMin: f.capacity?.$1,
      capacityMax: f.capacity?.$2,
      priceStructure: f.structure,
      voucherOnly: f.voucherOnly ? true : null,
      audience: f.arrangement ?? brief.audience,
      minRating: f.minRating,
      availableFrom: range?.$1,
      availableTo: range?.$2,
      date: brief.date,
      guests: brief.guests,
      originId: kDiscoverOrigin,
      sort: sort,
      cursor: cursor,
      limit: 50,
    );
    rows.addAll(page.items);
    cursor = page.nextCursor;
    pages++;
  } while (cursor != null && pages < 6);

  final ids = f.shelf == null ? null : await shelfVenueIds(ref, f.shelf!, brief);
  var out = <VenueResult>[
    for (final r in rows)
      if ((ids == null || ids.contains(r.venue.id)) &&
          (!f.available || brief.date == null || r.availability == VenueDayState.available || r.availability == VenueDayState.held) &&
          (f.withinMinutes == null || (r.distance != null && r.distance!.minutes <= f.withinMinutes!)) &&
          _inRange(perGuestKd(r.price, voucher: false), f.price) &&
          _inRange(perGuestKd(r.price, voucher: true), f.voucherPrice) &&
          (f.brands.isEmpty || f.brands.contains(hotelBrand(r.venue, 'en'))))
        r,
  ];
  if (f.settings.isNotEmpty || f.facilities.isNotEmpty) {
    final facts = await Future.wait(<Future<Venue>>[for (final r in out) ref.watch(venueFactsProvider(r.venue.id).future)]);
    final keep = <VenueResult>[];
    for (var i = 0; i < out.length; i++) {
      final v = facts[i];
      if (f.settings.isNotEmpty && !v.halls.any((h) => f.settings.contains(h.setting))) continue;
      if (f.facilities.any((k) => !venueHasFacility(v, k))) continue;
      keep.add(out[i]);
    }
    out = keep;
  }
  if (q.sort == DiscoverSort.priceDesc) out = out.reversed.toList();
  return out;
});

bool _inRange(double? kd, (int, int)? range) => range == null || (kd != null && kd >= range.$1 && kd <= range.$2);

/// Halls a request can go to on the Brief date, in the Brief's areas: the number of the Home button, the status card and the Brief sheet,
/// and the number Results opens with. A held hall still takes a request, so it counts; a governmental facility never does.
final briefCountProvider = FutureProvider.autoDispose.family<int, SearchBrief>((ref, brief) async {
  final rows = await ref.watch(discoverSearchProvider(DiscoverQuery(brief: brief, filters: DiscoverFilters.defaultsFor(brief))).future);
  return rows.where((r) => r.venue.channel != BookingChannel.externalLink).length;
});
