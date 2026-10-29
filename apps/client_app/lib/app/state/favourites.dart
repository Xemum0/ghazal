import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show weddingRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, GzLogger;
import 'package:ghazal_domain/ghazal_domain.dart' show MoneyAmount, SavedEntry, SavedItemInput, SavedType;

import 'client_scope.dart';

final GzLogger _log = GzLogger('favourites');

/// The hearts: venue, vendor (service provider) and package ids, the wishlist of the signed-in client (it lives on the server).
@immutable
final class FavouritesState {
  const FavouritesState({this.venue = const <String>{}, this.vendor = const <String>{}, this.package = const <String>{}});

  static const FavouritesState empty = FavouritesState();

  final Set<String> venue;
  final Set<String> vendor;
  final Set<String> package;

  Set<String> idsOf(SavedType kind) => switch (kind) {
        SavedType.venue => venue,
        SavedType.vendor => vendor,
        SavedType.package => package,
        SavedType.unknown => const <String>{},
      };

  bool contains(SavedType kind, String id) => idsOf(kind).contains(id);
  int get total => venue.length + vendor.length + package.length;

  FavouritesState withKind(SavedType kind, Set<String> ids) => FavouritesState(
        venue: kind == SavedType.venue ? ids : venue,
        vendor: kind == SavedType.vendor ? ids : vendor,
        package: kind == SavedType.package ? ids : package,
      );

  static FavouritesState fromEntries(Iterable<SavedEntry> entries) {
    final sets = <SavedType, Set<String>>{for (final k in SavedType.values) k: <String>{}};
    for (final e in entries) {
      sets[e.item.type]!.add(e.item.id);
    }
    return FavouritesState(venue: sets[SavedType.venue]!, vendor: sets[SavedType.vendor]!, package: sets[SavedType.package]!);
  }

  @override
  bool operator ==(Object other) =>
      other is FavouritesState && setEquals(other.venue, venue) && setEquals(other.vendor, vendor) && setEquals(other.package, package);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(venue), Object.hashAllUnordered(vendor), Object.hashAllUnordered(package));
}

/// The client's favourites. Loading: the wishlist of the account. Hearts are optimistic: the state changes at once and rolls back when the
/// server refuses.
final AsyncNotifierProvider<FavouritesNotifier, FavouritesState> favouritesProvider =
    AsyncNotifierProvider<FavouritesNotifier, FavouritesState>(FavouritesNotifier.new);

class FavouritesNotifier extends AsyncNotifier<FavouritesState> {
  final List<Future<void>> _inFlight = <Future<void>>[];

  /// The last refusal of a heart write (the heart was rolled back), for a toast.
  ApiProblem? lastProblem;

  @override
  Future<FavouritesState> build() async {
    final userId = ref.watch(clientUserIdProvider);
    if (userId == null) return FavouritesState.empty;
    return FavouritesState.fromEntries((await ref.read(weddingRepositoryProvider).listWishlist()).items);
  }

  /// Completes when every heart write in flight has been answered (tests, a screen that waits before navigating).
  Future<void> get settled async {
    while (_inFlight.isNotEmpty) {
      await Future.wait(List<Future<void>>.of(_inFlight));
    }
  }

  /// Flips one heart and returns its state afterwards (`true` = saved). The state changes before the first await when the favourites
  /// are loaded. A refusal restores the old state, the returned value then equals the old state and [lastProblem] holds the reason.
  Future<bool> toggle(SavedType kind, String id, {MoneyAmount? lastSeenPrice}) async {
    if (kind == SavedType.unknown) return false;
    final current = state.value ?? await future;
    final had = current.contains(kind, id);
    final ids = had ? (Set<String>.of(current.idsOf(kind))..remove(id)) : (Set<String>.of(current.idsOf(kind))..add(id));
    if (ref.read(clientUserIdProvider) == null) return false; // no session: nothing to save to
    final next = current.withKind(kind, ids);
    state = AsyncData(next);
    final repo = ref.read(weddingRepositoryProvider);
    final write = had
        ? repo.removeWishlistItem(type: kind, id: id)
        : repo.saveWishlistItem(type: kind, id: id, body: SavedItemInput(lastSeenPrice: lastSeenPrice));
    final tracked = write.then<void>((_) {}, onError: (Object _) {});
    _inFlight.add(tracked);
    try {
      await write;
      lastProblem = null;
      return !had;
    } on ApiProblem catch (p) {
      _log.warning('heart write refused: ${p.code.wire}');
      lastProblem = p;
      final latest = state.value ?? next;
      final restored = Set<String>.of(latest.idsOf(kind));
      had ? restored.add(id) : restored.remove(id);
      state = AsyncData(latest.withKind(kind, restored));
      return had;
    } finally {
      _inFlight.remove(tracked);
    }
  }
}

/// Is this item hearted? (false while loading). `ref.watch(isFavouriteProvider((SavedType.venue, 'V01')))`.
final isFavouriteProvider = Provider.family<bool, (SavedType, String)>(
  (ref, key) => ref.watch(favouritesProvider.select((a) => a.value?.contains(key.$1, key.$2) ?? false)),
);
