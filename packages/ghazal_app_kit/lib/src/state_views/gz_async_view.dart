import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'problem_message.dart';

/// Maps an `AsyncValue` to the five screen states of `ScreenState` (loading, data, empty, error, offline) the same way on every screen, and
/// cross-fades between them (200 ms, a 120 ms fade when motion is reduced).
///
/// - loading: [loading] or a skeleton; while a retry runs after an error the error stays and its button shows the activity.
/// - data: [data]; when [isEmpty] says so, [empty] or the generic empty state.
/// - error: `GzErrorState` with the sentence of the `ApiProblem` (`gzProblemMessage`) and a retry through [onRetry].
/// - offline (`ApiProblem.offline`): `GzOfflineState`.
class GzAsyncView<T> extends StatelessWidget {
  const GzAsyncView({
    required this.value,
    required this.data,
    this.isEmpty,
    this.empty,
    this.loading,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retrying = value.isLoading && value.hasError;
    final ScreenState<T> state = retrying
        ? ScreenState.from<T>(AsyncValue<T>.error(value.error!, value.stackTrace ?? StackTrace.empty), isEmpty: isEmpty)
        : ScreenState.from<T>(value, isEmpty: isEmpty);
    final (Object key, Widget child) = state.when(
      loading: () => ('loading', loading ?? const GzDefaultLoading()),
      data: (d) => ('data', data(d)),
      empty: () => ('empty', empty ?? const GzDefaultEmpty()),
      error: (p) => ('error', _error(context, p, retrying)),
      offline: (_) => ('offline', GzOfflineState(onRetry: onRetry, retrying: retrying)),
    );
    return AnimatedSwitcher(
      duration: GzReducedMotion.fade(context, GzMotion.durationBase),
      switchInCurve: GzMotion.easeStandard,
      switchOutCurve: GzMotion.easeExit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        fit: StackFit.passthrough,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey<Object>(key), child: child),
    );
  }

  Widget _error(BuildContext context, ApiProblem p, bool retrying) {
    final l10n = context.gzL10n;
    return GzErrorState(
      kind: gzProblemKind(p),
      body: gzProblemMessage(l10n, p),
      onRetry: onRetry,
      retrying: retrying,
    );
  }
}

/// The generic empty state of [GzAsyncView]: "Nothing here".
class GzDefaultEmpty extends StatelessWidget {
  const GzDefaultEmpty({super.key});

  @override
  Widget build(BuildContext context) => GzEmptyState(icon: GzIcons.search, title: context.gzL10n.commonStateTitleEmpty);
}

/// The generic loading state of [GzAsyncView]: a quiet skeleton (nothing loops, direction section 5) announced as "Loading".
class GzDefaultLoading extends StatelessWidget {
  const GzDefaultLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GzSkeleton(variant: GzSkeletonVariant.block),
              const SizedBox(height: GzSpace.s4),
              const GzSkeleton(inlineSize: GzSpace.s20 * 3),
              const SizedBox(height: GzSpace.s3),
              const GzSkeleton(inlineSize: GzSpace.s20 * 2),
              const SizedBox(height: GzSpace.s6),
              const GzSkeleton(variant: GzSkeletonVariant.block),
            ],
          ),
        ),
      ),
    );
  }
}
