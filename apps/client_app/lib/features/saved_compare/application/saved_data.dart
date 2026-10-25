import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show plannersRepositoryProvider, servicesRepositoryProvider, venuesRepositoryProvider, vouchersRepositoryProvider, weddingRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

/// The hero Brief of the story (Reem: the date, the women's guests): what a Saved or Compare frame shows when nothing else is chosen.
/// The real Brief comes from [searchBriefProvider]; this file never invents one.

/// A saved package: a hall package (with the hall it belongs to) or a planner tier.
@immutable
sealed class SavedPackage {
  const SavedPackage();
  String get id;
}

final class SavedHallPackage extends SavedPackage {
  const SavedHallPackage(this.pkg, this.venue);
  final Package pkg;
  final VenueSummary venue;
  @override
  String get id => pkg.id;
}

final class SavedPlannerPackage extends SavedPackage {
  const SavedPlannerPackage(this.pkg);
  final PlannerPackage pkg;
  @override
  String get id => pkg.id;
}

/// Everything the Saved tab shows, in the order it was saved, with the Brief's prices and availability.
@immutable
final class SavedBundle {
  const SavedBundle({this.venues = const [], this.vendors = const [], this.packages = const [], this.lastSeen = const {}});

  final List<VenueResult> venues;
  final List<ServiceProvider> vendors;
  final List<SavedPackage> packages;

  /// Venue id to the standard price the family last saw (drives "Saving changed").
  final Map<String, MoneyAmount> lastSeen;

  int get total => venues.length + vendors.length + packages.length;
}

/// The saved items of the account (the guest's device hearts for a guest), priced on the Brief. Refetched when the Brief or any
/// server data changes; a heart removed or put back does not refetch (the screen filters by the hearts).
final FutureProvider<SavedBundle> savedBundleProvider = FutureProvider.autoDispose<SavedBundle>((ref) async {
  ref.watch(clientDataRevisionProvider);
  final brief = ref.watch(searchBriefProvider);
  final userId = ref.watch(clientUserIdProvider);
  final wedding = ref.read(weddingRepositoryProvider);
  final venues = ref.read(venuesRepositoryProvider);
  final fav = await ref.read(favouritesProvider.future);
  if (userId != null) {
    final fetched = await wedding.listWishlist(date: brief.date, guests: brief.guests, audience: brief.audience);
    // The Saved tab lists items in the order they were saved (the API answers newest first).
    final items = [...fetched.items]..sort((a, b) => a.item.savedAt.compareTo(b.item.savedAt));
    final planners = await ref.read(plannersRepositoryProvider).listPlannerPackages();
    final roster = <String, VenueSummary>{};
    final packages = <SavedPackage>[];
    final lastSeen = <String, MoneyAmount>{};
    for (final e in items) {
      final seen = e.item.lastSeenPrice;
      if (e.venue != null && seen != null) lastSeen[e.venue!.venue.id] = seen;
      if (e.venue != null) roster[e.venue!.venue.id] = e.venue!.venue;
    }
    for (final e in items) {
      if (e.item.type != SavedType.package) continue;
      final planner = planners.where((p) => p.id == e.item.id).firstOrNull;
      if (planner != null) {
        packages.add(SavedPlannerPackage(planner));
        continue;
      }
      final p = e.package;
      if (p == null) continue;
      if (roster.isEmpty || !roster.containsKey(p.venueId)) {
        for (final r in (await venues.searchVenues(limit: 50)).items) {
          roster.putIfAbsent(r.venue.id, () => r.venue);
        }
      }
      final v = roster[p.venueId];
      if (v == null) continue;
      packages.add(SavedHallPackage(p, v));
    }
    return SavedBundle(
      venues: [
        for (final e in items)
          if (e.venue != null) e.venue!,
      ],
      vendors: [
        for (final e in items)
          if (e.provider != null) e.provider!,
      ],
      packages: packages,
      lastSeen: lastSeen,
    );
  }
  // a guest: the hearts live on the device, so the data is looked up by id
  final rows = <VenueResult>[];
  if (fav.venue.isNotEmpty) {
    final page = await venues.searchVenues(date: brief.date, guests: brief.guests, audience: brief.audience, limit: 50);
    final byId = {for (final r in page.items) r.venue.id: r};
    rows.addAll([
      for (final id in fav.venue)
        if (byId[id] != null) byId[id]!,
    ]);
  }
  final services = ref.read(servicesRepositoryProvider);
  final vendors = <ServiceProvider>[];
  for (final id in fav.vendor) {
    try {
      vendors.add(await services.getServiceProvider(providerId: id));
    } on Object {
      continue;
    }
  }
  final planners = fav.package.isEmpty ? const <PlannerPackage>[] : await ref.read(plannersRepositoryProvider).listPlannerPackages();
  return SavedBundle(
    venues: rows,
    vendors: vendors,
    packages: [for (final id in fav.package) ...planners.where((p) => p.id == id).map(SavedPlannerPackage.new)],
  );
});

/// Venue (or provider) ids the signed-in client holds a ready (paid, unbound) voucher for: the ticket glyph under the heart.
final FutureProvider<Map<String, String>> readyVouchersProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return const <String, String>{};
  final page = await ref.read(vouchersRepositoryProvider).listVouchers(status: const [VoucherStatus.active], limit: 50);
  final out = <String, String>{};
  for (final item in page.items) {
    final v = item.voucher;
    if (v is Voucher && v.status == VoucherStatus.active) out.putIfAbsent(v.venueOrProviderId, () => v.id);
  }
  return out;
});

/// Rank of the "free halls first" order.
int availabilityRank(VenueResult r, SearchBrief brief) {
  if (brief.date == null) return 0;
  return switch (r.availability) {
    VenueDayState.available => 0,
    VenueDayState.held => 1,
    VenueDayState.unavailable => 2,
    _ => 3,
  };
}

/// The compare columns of the tray: price and availability of up to three halls on the Brief (the one server call of Compare).
final compareColumnsProvider = FutureProvider.autoDispose.family<CompareResponse, (List<String>, SearchBrief)>((ref, key) {
  ref.watch(clientDataRevisionProvider);
  final brief = key.$2;
  final area = brief.areaIds.isEmpty ? 'salmiya' : brief.areaIds.first;
  return ref
      .read(venuesRepositoryProvider)
      .compareVenues(
        body: CompareInput(venueIds: key.$1, date: brief.date, guests: brief.guests, audience: brief.audience, originId: 'ref-$area'),
      );
});

/// The first Brief area as the reference point id ("Drive from ...").
String compareOriginId(SearchBrief brief) => 'ref-${brief.areaIds.isEmpty ? 'salmiya' : brief.areaIds.first}';

/// Which Saved segment to open next (the services hub asks for Services before it switches to the tab).
enum SavedSegment { venues, services, packages }

final NotifierProvider<PendingSavedSegment, SavedSegment?> pendingSavedSegmentProvider = NotifierProvider<PendingSavedSegment, SavedSegment?>(
  PendingSavedSegment.new,
);

class PendingSavedSegment extends Notifier<SavedSegment?> {
  @override
  SavedSegment? build() => null;

  void ask(SavedSegment? segment) => state = segment;
}

/// Every published hall priced on the Brief, by id: the thumbnails, names and card prices of the compare tray and of the Replace sheet.
final FutureProvider<Map<String, VenueResult>> briefRosterProvider = FutureProvider.autoDispose<Map<String, VenueResult>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  final brief = ref.watch(searchBriefProvider);
  final repo = ref.read(venuesRepositoryProvider);
  final out = <String, VenueResult>{};
  String? cursor;
  var pages = 0;
  do {
    final page = await repo.searchVenues(date: brief.date, guests: brief.guests, audience: brief.audience, cursor: cursor, limit: 50);
    for (final r in page.items) {
      out[r.venue.id] = r;
    }
    cursor = page.nextCursor;
    pages++;
  } while (cursor != null && pages < 4);
  return out;
});

/// Area id to its name (the area line under a hall's name).
final FutureProvider<Map<String, LocalizedText>> savedAreaNamesProvider = FutureProvider<Map<String, LocalizedText>>((ref) async {
  final areas = await ref.read(venuesRepositoryProvider).listAreas();
  return {for (final a in areas.areas) a.id: a.name};
});
