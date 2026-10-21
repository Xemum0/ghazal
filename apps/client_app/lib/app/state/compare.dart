import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// At most this many venues in the compare tray (ADR 0009).
const int kCompareMax = 3;

enum CompareResult { added, exists, full }

/// The compare tray: venue ids, the first added first (it sits at inline-start). Local to the device, never sent to the server except as the
/// body of the compare call.
@immutable
final class CompareState {
  const CompareState([this.venueIds = const <String>[]]);

  final List<String> venueIds;

  bool get isEmpty => venueIds.isEmpty;
  int get length => venueIds.length;
  bool get isFull => venueIds.length >= kCompareMax;
  bool contains(String venueId) => venueIds.contains(venueId);

  /// Two or more venues can be compared.
  bool get canCompare => venueIds.length >= 2;

  @override
  bool operator ==(Object other) => other is CompareState && listEquals(other.venueIds, venueIds);

  @override
  int get hashCode => Object.hashAll(venueIds);
}

final NotifierProvider<CompareNotifier, CompareState> compareProvider = NotifierProvider<CompareNotifier, CompareState>(CompareNotifier.new);

class CompareNotifier extends Notifier<CompareState> {
  @override
  CompareState build() => const CompareState();

  /// `added`, `exists` (already in the tray, nothing changes) or `full` (three are in; offer `replace`).
  CompareResult add(String venueId) {
    if (state.contains(venueId)) return CompareResult.exists;
    if (state.isFull) return CompareResult.full;
    state = CompareState([...state.venueIds, venueId]);
    return CompareResult.added;
  }

  void remove(String venueId) => state = CompareState([for (final id in state.venueIds) if (id != venueId) id]);

  /// The full-tray "Replace" path: [newId] takes the column of [oldId]. Nothing happens when [newId] is already in the tray.
  void replace(String oldId, String newId) {
    if (state.contains(newId) || !state.contains(oldId)) return;
    state = CompareState([for (final id in state.venueIds) id == oldId ? newId : id]);
  }

  void clear() => state = const CompareState();

  /// Sets the whole tray (the story seed, a deep link), de-duplicated and cut to [kCompareMax].
  void setAll(Iterable<String> venueIds) => state = CompareState(venueIds.toSet().take(kCompareMax).toList());

  /// The toggle of a compare button: removes when in the tray, otherwise adds. Returns the result of the add (or `exists` after a removal).
  CompareResult toggle(String venueId) {
    if (state.contains(venueId)) {
      remove(venueId);
      return CompareResult.exists;
    }
    return add(venueId);
  }
}
