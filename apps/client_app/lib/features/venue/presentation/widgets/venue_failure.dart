import 'package:flutter/widgets.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_ui/ghazal_ui.dart';

/// A failed read of a venue sheet's data: the error (or offline) state with a retry, never the "none on this date" empty state.
class VenueSheetFailure extends StatelessWidget {
  const VenueSheetFailure({required this.error, required this.onRetry, super.key});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final problem = error is ApiProblem ? error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown);
    return GzErrorState(
      key: const ValueKey<String>('venue.sheet.error'),
      kind: gzProblemKind(problem),
      body: gzProblemMessage(context.gzL10n, problem),
      fill: false,
      onRetry: onRetry,
    );
  }
}
