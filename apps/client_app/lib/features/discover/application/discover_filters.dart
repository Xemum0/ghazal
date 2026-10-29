import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, HallSetting, HomeCategoryId, LocalDate, LuxuryLevel, PriceStructureFilter, ShelfId, VenueType;

import '../../../app/state/state.dart' show SearchBrief;

/// The facility chips of the Filters sheet (CA-FLT-06). Matched on the amenities of the venue detail.
enum DiscoverFacility { parking, valet, bridal, buffet, decor, photography }

/// The orders of the Sort sheet (the contract's `VenueSort`, plus the reversed price).
enum DiscoverSort {
  recommended,
  voucherPrice,
  rating,
  newest,
  price,
  priceDesc,
  distance,
}

/// What the Filters sheet, Results and the map filter on (the Flutter twin of the web `Filters`). `governorateIds == null` follows the Brief's
/// governorates, `[]` means every governorate (the "All governorates" chip), a list is an explicit choice that replaces the Brief's (ADR 0038:
/// the client picks governorates, never exact areas). Ranges are whole numbers (guests, or whole dinars per guest).
@immutable
final class DiscoverFilters {
  const DiscoverFilters({
    this.shelf,
    this.category,
    this.governorateIds,
    this.types = const <VenueType>[],
    this.arrangement,
    this.withinMinutes,
    this.capacity,
    this.structure,
    this.dates,
    this.voucherOnly = false,
    this.voucherPrice,
    this.price,
    this.settings = const <HallSetting>[],
    this.facilities = const <DiscoverFacility>[],
    this.available = false,
    this.minRating,
    this.levels = const <LuxuryLevel>[],
    this.brands = const <String>[],
  });

  static const DiscoverFilters none = DiscoverFilters();

  /// What a Brief with a date starts with: the availability filter on (CL-DISC-04 contentNotes).
  factory DiscoverFilters.defaultsFor(SearchBrief brief) => DiscoverFilters(available: brief.date != null);

  /// A Home shelf's "See all": the list is that shelf's halls, shown as one removable chip.
  final ShelfId? shelf;
  final HomeCategoryId? category;
  final List<String>? governorateIds;
  final List<VenueType> types;
  final Audience? arrangement;
  final int? withinMinutes;
  final (int, int)? capacity;
  final PriceStructureFilter? structure;

  /// A short range from the date filter (CL-DISC-06); a single day is the Brief date and [available].
  final (LocalDate, LocalDate)? dates;
  final bool voucherOnly;
  final (int, int)? voucherPrice;
  final (int, int)? price;
  final List<HallSetting> settings;
  final List<DiscoverFacility> facilities;

  /// Free or on hold on the Brief date (a held hall still accepts a request, ADR 0001).
  final bool available;
  final double? minRating;
  final List<LuxuryLevel> levels;
  final List<String> brands;

  /// Changes some fields; the `clear*` flags set a nullable field back to null.
  DiscoverFilters copyWith({
    ShelfId? shelf,
    HomeCategoryId? category,
    List<String>? governorateIds,
    List<VenueType>? types,
    Audience? arrangement,
    int? withinMinutes,
    (int, int)? capacity,
    PriceStructureFilter? structure,
    (LocalDate, LocalDate)? dates,
    bool? voucherOnly,
    (int, int)? voucherPrice,
    (int, int)? price,
    List<HallSetting>? settings,
    List<DiscoverFacility>? facilities,
    bool? available,
    double? minRating,
    List<LuxuryLevel>? levels,
    List<String>? brands,
    bool clearShelf = false,
    bool clearCategory = false,
    bool clearGovernorateIds = false,
    bool clearArrangement = false,
    bool clearWithin = false,
    bool clearCapacity = false,
    bool clearStructure = false,
    bool clearDates = false,
    bool clearVoucherPrice = false,
    bool clearPrice = false,
    bool clearMinRating = false,
  }) => DiscoverFilters(
    shelf: clearShelf ? null : (shelf ?? this.shelf),
    category: clearCategory ? null : (category ?? this.category),
    governorateIds: clearGovernorateIds ? null : (governorateIds ?? this.governorateIds),
    types: types ?? this.types,
    arrangement: clearArrangement ? null : (arrangement ?? this.arrangement),
    withinMinutes: clearWithin ? null : (withinMinutes ?? this.withinMinutes),
    capacity: clearCapacity ? null : (capacity ?? this.capacity),
    structure: clearStructure ? null : (structure ?? this.structure),
    dates: clearDates ? null : (dates ?? this.dates),
    voucherOnly: voucherOnly ?? this.voucherOnly,
    voucherPrice: clearVoucherPrice ? null : (voucherPrice ?? this.voucherPrice),
    price: clearPrice ? null : (price ?? this.price),
    settings: settings ?? this.settings,
    facilities: facilities ?? this.facilities,
    available: available ?? this.available,
    minRating: clearMinRating ? null : (minRating ?? this.minRating),
    levels: levels ?? this.levels,
    brands: brands ?? this.brands,
  );

  /// The count on the Filters button: everything that is a filter (the Brief is not one).
  int activeCount(SearchBrief brief) {
    var n = 0;
    if (shelf != null) n++;
    if (category != null) n++;
    if (governorateIds != null) n++;
    if (types.isNotEmpty) n++;
    if (arrangement != null) n++;
    if (withinMinutes != null) n++;
    if (capacity != null) n++;
    if (structure != null) n++;
    if (dates != null) n++;
    if (voucherOnly) n++;
    if (voucherPrice != null) n++;
    if (price != null) n++;
    if (settings.isNotEmpty) n++;
    n += facilities.length;
    if (available && brief.date == null) n++;
    if (minRating != null) n++;
    if (levels.isNotEmpty) n++;
    if (brands.isNotEmpty) n++;
    return n;
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoverFilters &&
      other.shelf == shelf &&
      other.category == category &&
      listEquals(other.governorateIds, governorateIds) &&
      listEquals(other.types, types) &&
      other.arrangement == arrangement &&
      other.withinMinutes == withinMinutes &&
      other.capacity == capacity &&
      other.structure == structure &&
      other.dates == dates &&
      other.voucherOnly == voucherOnly &&
      other.voucherPrice == voucherPrice &&
      other.price == price &&
      listEquals(other.settings, settings) &&
      listEquals(other.facilities, facilities) &&
      other.available == available &&
      other.minRating == minRating &&
      listEquals(other.levels, levels) &&
      listEquals(other.brands, brands);

  @override
  int get hashCode => Object.hashAll(<Object?>[
    shelf,
    category,
    governorateIds == null ? null : Object.hashAll(governorateIds!),
    Object.hashAll(types),
    arrangement,
    withinMinutes,
    capacity,
    structure,
    dates,
    voucherOnly,
    voucherPrice,
    price,
    Object.hashAll(settings),
    Object.hashAll(facilities),
    available,
    minRating,
    Object.hashAll(levels),
    Object.hashAll(brands),
  ]);
}

/// The preset a screen opens Results with (route params of `CL-DISC-03`): `shelf`, `category`, `available`, `governorateIds` (a list; empty =
/// every governorate). No params: the Brief decides.
DiscoverFilters discoverPresetFromParams(Map<String, Object?> params, SearchBrief brief) {
  final shelf = params['shelf'];
  final category = params['category'];
  final governorates = params['governorateIds'];
  final available = params['available'];
  if (shelf == null && category == null && governorates == null && available == null) return DiscoverFilters.defaultsFor(brief);
  return DiscoverFilters(
    shelf: shelf is String ? ShelfId.fromJson(shelf) : null,
    category: category is String ? HomeCategoryId.fromJson(category) : null,
    governorateIds: governorates is List ? governorates.cast<String>() : null,
    available: available == true && brief.date != null,
  );
}

/// Filters, order and the name search that Results, the Filters sheet and the map share.
@immutable
final class DiscoverState {
  const DiscoverState({this.filters = DiscoverFilters.none, this.sort = DiscoverSort.recommended, this.query = '', this.seeded = false});

  final DiscoverFilters filters;
  final DiscoverSort sort;
  final String query;

  /// Results has set the filters it was opened with. Until then the map and the sheets read the Brief's defaults.
  final bool seeded;

  /// The filters in force: the seeded ones, else the Brief's defaults.
  DiscoverFilters effective(SearchBrief brief) => seeded ? filters : DiscoverFilters.defaultsFor(brief);

  DiscoverState copyWith({DiscoverFilters? filters, DiscoverSort? sort, String? query, bool? seeded}) => DiscoverState(
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    query: query ?? this.query,
    seeded: seeded ?? this.seeded,
  );
}

final NotifierProvider<DiscoverNotifier, DiscoverState> discoverStateProvider = NotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);

class DiscoverNotifier extends Notifier<DiscoverState> {
  @override
  DiscoverState build() => const DiscoverState();

  /// Results was opened: take its preset, forget the last query and order.
  void seed(DiscoverFilters filters) => state = DiscoverState(filters: filters, seeded: true);

  void replaceFilters(DiscoverFilters filters) => state = state.copyWith(filters: filters, seeded: true);

  void setSort(DiscoverSort sort) => state = state.copyWith(sort: sort);

  void setQuery(String query) => state = state.copyWith(query: query);
}

/// What the date sheet (CL-DISC-06) hands back to the Filters sheet that opened it: the day or short range and the availability switch.
@immutable
final class DatePatch {
  const DatePatch({this.dates, this.available = false});

  final (LocalDate, LocalDate)? dates;
  final bool available;
}

final NotifierProvider<DatePatchNotifier, DatePatch?> datePatchProvider = NotifierProvider<DatePatchNotifier, DatePatch?>(DatePatchNotifier.new);

class DatePatchNotifier extends Notifier<DatePatch?> {
  @override
  DatePatch? build() => null;

  void hand(DatePatch patch) => state = patch;

  void take() => state = null;
}
