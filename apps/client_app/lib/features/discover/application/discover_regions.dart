import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show homeRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Area, AreasResponse, AppConfig, BookingChannel, DayState, Governorate, LocalDate, RegionMatch, VenueAvailability, VenueResult;

import '../../../app/state/state.dart' show SearchBrief;
import 'discover_filters.dart';
import 'discover_search.dart';

/// Governorates, areas and reference points (`GET /areas`), read once.
final areasProvider = FutureProvider<AreasResponse>((ref) => ref.watch(venuesRepositoryProvider).listAreas());

/// Every published venue with no Brief and no filter: the roster the counts under areas and governorates, the brands and the price
/// histograms are made from.
final venueRosterProvider = FutureProvider.autoDispose<List<VenueResult>>(
  (ref) => ref.watch(discoverSearchProvider(const DiscoverQuery(brief: SearchBrief.empty, filters: DiscoverFilters.none)).future),
);

/// A governorate with the areas under it that hold at least one hall, and the number of halls behind each.
final class RegionGroup {
  const RegionGroup({required this.governorate, required this.areas, required this.count});

  final Governorate governorate;
  final List<({Area area, int count})> areas;
  final int count;
}

/// The six governorates of Kuwait that hold halls, with their areas (only the ones with a hall) and counts.
final regionGroupsProvider = FutureProvider.autoDispose<List<RegionGroup>>((ref) async {
  final areas = await ref.watch(areasProvider.future);
  final roster = await ref.watch(venueRosterProvider.future);
  final per = <String, int>{};
  for (final r in roster) {
    per.update(r.venue.areaId, (n) => n + 1, ifAbsent: () => 1);
  }
  final out = <RegionGroup>[];
  for (final g in areas.governorates) {
    final inside = <({Area area, int count})>[
      for (final a in areas.areas)
        if (a.governorateId == g.id && per.containsKey(a.id)) (area: a, count: per[a.id]!),
    ];
    if (inside.isEmpty) continue;
    out.add(RegionGroup(governorate: g, areas: inside, count: inside.fold<int>(0, (n, a) => n + a.count)));
  }
  return out;
});

/// The typeahead over governorates, areas and venue names (Arabic-normalised by the server).
final regionSearchProvider = FutureProvider.autoDispose.family<List<RegionMatch>, String>((ref, q) {
  if (q.trim().isEmpty) return Future<List<RegionMatch>>.value(const <RegionMatch>[]);
  return ref.watch(venuesRepositoryProvider).searchRegions(q: q.trim());
});

/// Platform configuration and the server clock (the availability window the calendars end at).
final appConfigProvider = FutureProvider<AppConfig>((ref) => ref.watch(homeRepositoryProvider).getAppConfig());

/// How many halls of the Brief's scope are free on each day of a month: the density marks of the date sheet (CL-DISC-06). The key is the
/// Brief (its areas, guests and audience decide the scope) and the month as `YYYY-MM`.
final dateDensityProvider = FutureProvider.autoDispose.family<Map<String, ({int free, int of})>, (SearchBrief, String)>((ref, key) async {
  final brief = key.$1;
  final month = key.$2;
  final scope = await ref.watch(
    discoverSearchProvider(DiscoverQuery(brief: brief.copyWith(clearDate: true), filters: const DiscoverFilters())).future,
  );
  final ids = <String>[for (final r in scope) if (r.venue.channel != BookingChannel.externalLink) r.venue.id];
  final y = int.parse(month.substring(0, 4));
  final m = int.parse(month.substring(5, 7));
  final from = LocalDate(y, m, 1);
  final to = LocalDate(y, m, DateTime.utc(y, m + 1, 0).day);
  final repo = ref.watch(venuesRepositoryProvider);
  final out = <String, int>{};
  final all = await Future.wait(<Future<VenueAvailability>>[
    for (final id in ids) repo.getVenueAvailability(venueId: id, from: from, to: to, guests: brief.guests, audience: brief.audience),
  ]);
  for (final a in all) {
    for (final d in a.days) {
      out.update(d.date.toString(), (n) => n + (d.state == DayState.available ? 1 : 0), ifAbsent: () => d.state == DayState.available ? 1 : 0);
    }
  }
  return <String, ({int free, int of})>{for (final e in out.entries) e.key: (free: e.value, of: ids.length)};
});
