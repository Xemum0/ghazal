import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';

/// What a write action of the app state answers: it worked, the server refused it (an [ApiProblem]: the screen shows its message, the
/// `BOOKING_STATE_CONFLICT` sheet, the offline state).
/// Actions never throw an `ApiProblem`; a programming error (an incomplete draft) is a `StateError`.
@immutable
sealed class ActionResult<T> {
  const ActionResult();

  bool get isSuccess => this is ActionSuccess<T>;
  T? get valueOrNull => switch (this) {
        ActionSuccess<T>(:final value) => value,
        _ => null,
      };
  ApiProblem? get problem => switch (this) {
        ActionFailure<T>(:final problem) => problem,
        _ => null,
      };

  R when<R>({required R Function(T value) success, required R Function(ApiProblem problem) failure}) => switch (this) {
        ActionSuccess<T>(:final value) => success(value),
        ActionFailure<T>(:final problem) => failure(problem),
      };
}

final class ActionSuccess<T> extends ActionResult<T> {
  const ActionSuccess(this.value);
  final T value;
}

final class ActionFailure<T> extends ActionResult<T> {
  const ActionFailure(this.problem);
  @override
  final ApiProblem problem;
}

/// What the busy and error state of a write-action notifier looks like: the keys of the actions in flight (`confirm:bk-1`) and the last
/// refusal. A button reads `busy.contains(key)` for its loading state.
@immutable
final class ActionsState {
  const ActionsState({this.busy = const <String>{}, this.lastProblem});

  final Set<String> busy;
  final ApiProblem? lastProblem;

  bool get isBusy => busy.isNotEmpty;
  bool isBusyWith(String key) => busy.contains(key);

  ActionsState copyWith({Set<String>? busy, ApiProblem? lastProblem, bool clearProblem = false}) =>
      ActionsState(busy: busy ?? this.busy, lastProblem: clearProblem ? null : (lastProblem ?? this.lastProblem));

  @override
  bool operator ==(Object other) => other is ActionsState && setEquals(other.busy, busy) && other.lastProblem == lastProblem;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(busy), lastProblem);
}

/// One idempotency key per intent: the same key goes out again while the user retries the same action (a double tap, a retry after
/// a timeout), and a new one after the intent finished, so the server replays instead of doing it twice.
final class IntentKeys {
  final Map<String, String> _open = <String, String>{};
  final Random _random = Random.secure();
  int _seq = 0;

  String keyFor(String intent) => _open.putIfAbsent(intent, () => 'ik-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_seq++}-${_random.nextInt(1 << 32).toRadixString(36)}');

  /// The intent was answered by the server (success or a definite refusal): the next attempt is a new intent.
  void done(String intent) => _open.remove(intent);
}

/// Bumped after every write that changes what lists show (a request sent, a voucher paid, a notification read). Flow providers that load
/// lists `ref.watch` it and refetch: `ref.watch(clientDataRevisionProvider);` at the top of their `build`.
final NotifierProvider<DataRevision, int> clientDataRevisionProvider = NotifierProvider<DataRevision, int>(DataRevision.new);

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
