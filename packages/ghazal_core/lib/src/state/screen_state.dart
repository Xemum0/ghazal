import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/api_problem.dart';

/// Every screen handles the same five states (loading, data, empty, error, offline) the same way. A screen switches
/// over this sealed type, so a missing state is a compile error.
sealed class ScreenState<T> {
  const ScreenState();

  /// Maps an [AsyncValue] with an emptiness test: `AsyncData` of an empty value is [ScreenEmpty], an offline problem
  /// is [ScreenOffline] (keeping any previous value), any other error is [ScreenError].
  static ScreenState<T> from<T>(AsyncValue<T> value, {bool Function(T data)? isEmpty}) {
    final prev = value.value;
    return value.when(
      loading: () => const ScreenLoading(),
      data: (d) => (isEmpty?.call(d) ?? false) ? const ScreenEmpty() : ScreenData(d),
      error: (e, _) {
        final problem = e is ApiProblem ? e : null;
        if (problem != null && problem.isOffline) return ScreenOffline(prev);
        return ScreenError(problem ?? const ApiProblem(status: 0, code: ApiProblemCode.unknown));
      },
    );
  }

  /// Exhaustive fold.
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function() empty,
    required R Function(ApiProblem problem) error,
    required R Function(T? stale) offline,
  }) =>
      switch (this) {
        ScreenLoading() => loading(),
        ScreenData<T>(data: final d) => data(d),
        ScreenEmpty() => empty(),
        ScreenError<T>(problem: final p) => error(p),
        ScreenOffline<T>(stale: final s) => offline(s),
      };
}

final class ScreenLoading<T> extends ScreenState<T> {
  const ScreenLoading();
}

final class ScreenData<T> extends ScreenState<T> {
  const ScreenData(this.data);
  final T data;
}

final class ScreenEmpty<T> extends ScreenState<T> {
  const ScreenEmpty();
}

final class ScreenError<T> extends ScreenState<T> {
  const ScreenError(this.problem);
  final ApiProblem problem;
}

/// Offline: actions are disabled in place and say "Offline. Reconnect to ..."; [stale] is the last data, if any.
final class ScreenOffline<T> extends ScreenState<T> {
  const ScreenOffline([this.stale]);
  final T? stale;
}
