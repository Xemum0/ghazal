import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show homeRepositoryProvider, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingChannel, HomeFeed, HomeShelfItem, ShelfId, VenueDayState, VenueResult;

import '../../../app/state/state.dart' show SearchBrief, clientDataRevisionProvider;

/// The cap of each shelf (the prototype's rails: six free halls, four of the others, three nearby).
const Map<ShelfId, int> kShelfCap = <ShelfId, int>{
  ShelfId.free: 6,
  ShelfId.voucher: 4,
  ShelfId.week: 4,
  ShelfId.recommended: 4,
  ShelfId.trending: 4,
  ShelfId.nearby: 3,
};

/// The voucher fee in fils (KD 2): a shelf of "Voucher prices" lists halls whose saving beats it (ADR 0033 D4).
const int kVoucherFeeFils = 2000;

/// `GET /home` for a Brief (CA-HOME): the status card, the shelves, the categories. One response; the shelves below read their own slice.
final homeFeedProvider = FutureProvider.autoDispose.family<HomeFeed, SearchBrief>((ref, brief) {
  ref.watch(clientDataRevisionProvider);
  ref.watch(sessionProvider.select((s) => s.isSignedIn));
  return ref
      .watch(homeRepositoryProvider)
      .getHome(date: brief.date, guests: brief.guests, audience: brief.audience, areaIds: brief.areaIds.isEmpty ? null : brief.areaIds);
});

/// The shelves of Home, shaped like the prototype's rails (the server will own these rules; `requests.md`): the free shelf lists the
/// Brief's areas only; "Voucher prices" the halls whose saving beats the fee, largest first; Featured one hall that is not booked on the
/// date; For you and Trending skip halls an earlier shelf already showed and halls that are booked; Nearby the three nearest.
Map<ShelfId, List<HomeShelfItem>> shapeShelves(HomeFeed feed, SearchBrief brief) {
  List<HomeShelfItem> raw(ShelfId id) => <HomeShelfItem>[for (final s in feed.shelves) if (s.id == id) ...s.items];
  bool browseOnly(VenueResult r) => r.venue.channel == BookingChannel.externalLink;
  bool open(VenueResult r) => !browseOnly(r) && r.availability != VenueDayState.unavailable;
  bool inAreas(VenueResult r) => brief.areaIds.isEmpty || brief.areaIds.contains(r.venue.areaId);

  final free = brief.date == null
      ? const <HomeShelfItem>[]
      : <HomeShelfItem>[for (final i in raw(ShelfId.free)) if (!browseOnly(i.row) && inAreas(i.row) && i.row.availability == VenueDayState.available) i];
  final used = <String>{for (final i in free) i.row.venue.id};

  final featuredPool = raw(ShelfId.featured);
  final featured = <HomeShelfItem>[
    ...(<HomeShelfItem>[...featuredPool]..sort((a, b) => (b.row.availability != VenueDayState.unavailable ? 1 : 0) - (a.row.availability != VenueDayState.unavailable ? 1 : 0))).take(1),
  ];
  for (final i in featured) {
    used.add(i.row.venue.id);
  }

  final everyone = <HomeShelfItem>[for (final i in raw(ShelfId.recommended)) i];
  final voucher = <HomeShelfItem>[
    for (final i in raw(ShelfId.recommended).followedBy(raw(ShelfId.trending)).followedBy(raw(ShelfId.featured)).followedBy(raw(ShelfId.voucher)).followedBy(raw(ShelfId.nearby)))
      if (!browseOnly(i.row) && (i.row.price?.voucher != null) && (i.row.price?.savings?.fils ?? 0) > kVoucherFeeFils) i,
  ];
  final seen = <String>{};
  final voucherShelf = <HomeShelfItem>[for (final i in voucher) if (seen.add(i.row.venue.id)) i]
    ..sort((a, b) => (b.row.price?.savings?.fils ?? 0).compareTo(a.row.price?.savings?.fils ?? 0));

  final recommended = <HomeShelfItem>[for (final i in everyone) if (open(i.row) && !used.contains(i.row.venue.id)) i].take(kShelfCap[ShelfId.recommended]!).toList();
  for (final i in recommended) {
    used.add(i.row.venue.id);
  }
  final trending = <HomeShelfItem>[for (final i in raw(ShelfId.trending)) if (open(i.row) && !used.contains(i.row.venue.id)) i]
    ..sort((a, b) => b.row.venue.rating.count.compareTo(a.row.venue.rating.count));
  final nearby = <HomeShelfItem>[for (final i in raw(ShelfId.nearby)) if (!browseOnly(i.row) && i.row.distance != null) i]
    ..sort((a, b) => a.row.distance!.minutes.compareTo(b.row.distance!.minutes));

  return <ShelfId, List<HomeShelfItem>>{
    ShelfId.free: free.take(kShelfCap[ShelfId.free]!).toList(),
    ShelfId.featured: featured,
    ShelfId.voucher: voucherShelf.take(kShelfCap[ShelfId.voucher]!).toList(),
    ShelfId.week: raw(ShelfId.week).take(kShelfCap[ShelfId.week]!).toList(),
    ShelfId.recommended: recommended,
    ShelfId.trending: trending.take(kShelfCap[ShelfId.trending]!).toList(),
    ShelfId.nearby: nearby.take(kShelfCap[ShelfId.nearby]!).toList(),
  };
}

/// One shelf as its own `AsyncValue` (its own skeleton). Derived from the one `/home` response, so a shelf with nothing to show reads as an
/// empty list (and draws nothing).
final homeShelfProvider =
    Provider.autoDispose.family<AsyncValue<List<HomeShelfItem>>, (SearchBrief, ShelfId)>((ref, key) {
      final feed = ref.watch(homeFeedProvider(key.$1));
      return feed.whenData((f) => shapeShelves(f, key.$1)[key.$2] ?? const <HomeShelfItem>[]);
    });

/// The venue ids behind a shelf (the "See all" of Home opens Results with exactly these).
Future<Set<String>> shelfVenueIds(Ref ref, ShelfId shelf, SearchBrief brief) async {
  final feed = await ref.watch(homeFeedProvider(brief).future);
  return <String>{for (final i in shapeShelves(feed, brief)[shelf] ?? const <HomeShelfItem>[]) i.row.venue.id};
}
