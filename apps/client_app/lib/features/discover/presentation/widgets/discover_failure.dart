import 'package:flutter/widgets.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The error of a section that failed to load, drawn in place (not a whole-screen takeover): offline reads as the offline state, anything
/// else as the load error with the user-safe sentence of the problem, and one retry.
class DiscoverFailure extends StatelessWidget {
  const DiscoverFailure({required this.error, required this.onRetry, this.retrying = false, this.secondary, super.key});

  final Object error;
  final VoidCallback onRetry;
  final bool retrying;
  final GzStateAction? secondary;

  static ApiProblem problemOf(Object error) => error is ApiProblem ? error : const ApiProblem(status: 0, code: ApiProblemCode.unknown);

  @override
  Widget build(BuildContext context) {
    final p = problemOf(error);
    if (p.isOffline) return GzOfflineState(fill: false, onRetry: onRetry, retrying: retrying, secondary: secondary);
    return GzErrorState(kind: gzProblemKind(p), body: gzProblemMessage(context.gzL10n, p), fill: false, onRetry: onRetry, retrying: retrying, secondary: secondary);
  }
}

/// True when [error] is the offline problem.
bool isOfflineError(Object? error) => error is ApiProblem && error.isOffline;
