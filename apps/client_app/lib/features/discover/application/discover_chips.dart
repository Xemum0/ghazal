import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show HallSetting, LuxuryLevel, VenueType;

import '../../../app/state/state.dart' show SearchBrief;
import 'discover_filters.dart';
import 'discover_search.dart';

/// What an applied filter chip stands for (the label and glyph are drawn by the screen, from the kind and its argument).
enum ChipKind {
  shelf,
  category,
  governorates,
  areas,
  type,
  available,
  dates,
  arrangement,
  within,
  capacity,
  structure,
  voucher,
  voucherPrice,
  price,
  setting,
  facility,
  rating,
  level,
  brand,
}

/// One removable chip of the applied filters: [id] is stable for keys and tests; [remove] returns the filters without it.
final class ChipSpec {
  const ChipSpec(this.id, this.kind, this.remove, [this.arg]);

  final String id;
  final ChipKind kind;
  final Object? arg;
  final DiscoverFilters Function(DiscoverFilters) remove;
}

/// The removable chips for the applied filters, in the order people decided them. The Brief itself is the echo above, not a chip.
List<ChipSpec> chipSpecs(DiscoverFilters f, SearchBrief brief) => <ChipSpec>[
  if (f.shelf != null) ChipSpec('shelf', ChipKind.shelf, (x) => x.copyWith(clearShelf: true), f.shelf),
  if (f.category != null) ChipSpec('category', ChipKind.category, (x) => x.copyWith(clearCategory: true), f.category),
  if (f.governorateIds.isNotEmpty) ChipSpec('governorates', ChipKind.governorates, (x) => x.copyWith(governorateIds: const <String>[]), f.governorateIds),
  if (f.areaIds != null) ChipSpec('areas', ChipKind.areas, (x) => x.copyWith(clearAreaIds: true), f.areaIds),
  for (final v in f.types) ChipSpec('type-${v.value}', ChipKind.type, (x) => x.copyWith(types: <VenueType>[for (final y in x.types) if (y != v) y]), v),
  if (f.available && brief.date != null && f.dates == null) ChipSpec('available', ChipKind.available, (x) => x.copyWith(available: false), brief.date),
  if (f.dates != null) ChipSpec('dates', ChipKind.dates, (x) => x.copyWith(clearDates: true), f.dates),
  if (f.arrangement != null) ChipSpec('arrangement', ChipKind.arrangement, (x) => x.copyWith(clearArrangement: true), f.arrangement),
  if (f.withinMinutes != null) ChipSpec('within', ChipKind.within, (x) => x.copyWith(clearWithin: true), f.withinMinutes),
  if (f.capacity != null) ChipSpec('capacity', ChipKind.capacity, (x) => x.copyWith(clearCapacity: true), f.capacity),
  if (f.structure != null) ChipSpec('structure', ChipKind.structure, (x) => x.copyWith(clearStructure: true), f.structure),
  if (f.voucherOnly) ChipSpec('voucher', ChipKind.voucher, (x) => x.copyWith(voucherOnly: false)),
  if (f.voucherPrice != null) ChipSpec('voucher-price', ChipKind.voucherPrice, (x) => x.copyWith(clearVoucherPrice: true), f.voucherPrice),
  if (f.price != null) ChipSpec('price', ChipKind.price, (x) => x.copyWith(clearPrice: true), f.price),
  for (final s in f.settings) ChipSpec('setting-${s.value}', ChipKind.setting, (x) => x.copyWith(settings: <HallSetting>[for (final y in x.settings) if (y != s) y]), s),
  for (final k in f.facilities) ChipSpec('facility-${k.name}', ChipKind.facility, (x) => x.copyWith(facilities: <DiscoverFacility>[for (final y in x.facilities) if (y != k) y]), k),
  if (f.minRating != null) ChipSpec('rating', ChipKind.rating, (x) => x.copyWith(clearMinRating: true), f.minRating),
  for (final l in f.levels) ChipSpec('level-${l.value}', ChipKind.level, (x) => x.copyWith(levels: <LuxuryLevel>[for (final y in x.levels) if (y != l) y]), l),
  for (final b in f.brands) ChipSpec('brand-$b', ChipKind.brand, (x) => x.copyWith(brands: <String>[for (final y in x.brands) if (y != b) y]), b),
];

/// "Clear all" keeps the date availability default (it is the Brief speaking), so the list never silently shows booked halls.
DiscoverFilters clearedFilters(SearchBrief brief) => DiscoverFilters.defaultsFor(brief);

/// The id of the first applied filter whose removal brings halls back (the no-results state names it); null when none does.
final relaxChipProvider = FutureProvider.autoDispose.family<String?, DiscoverQuery>((ref, q) async {
  for (final chip in chipSpecs(q.filters, q.brief)) {
    if (chip.id == 'available') continue;
    final rows = await ref.watch(discoverSearchProvider(q.copyWith(filters: chip.remove(q.filters))).future);
    if (rows.isNotEmpty) return chip.id;
  }
  return null;
});
