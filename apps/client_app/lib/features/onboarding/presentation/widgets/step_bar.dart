import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'thread_progress.dart';

/// The bar of the optional steps CL-ONBD-03 to 05 (web `StepBar`): Back at inline-start, the thread in the middle, the info glyph and a
/// text Skip at inline-end. It is the shared [GzTopBar] with a title widget, one icon action and a text action.
class ObdStepBar extends StatelessWidget {
  const ObdStepBar({required this.step, required this.total, required this.onSkip, this.back = true, super.key});

  /// 1-based step.
  final int step;
  final int total;
  final VoidCallback onSkip;

  /// The first step has no Back: the sign-in is behind the person once the account exists.
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GzTopBar(
      back: back ? GzTopBarBack.show : GzTopBarBack.hide,
      titleWidget: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
        child: ObdThreadProgress(count: total, index: step - 1, label: l10n.clientOnboardingStepProgress(step, total)),
      ),
      actions: [
        GzTopBarAction(
          icon: GzIcons.info,
          label: l10n.commonA11yInfo,
          onPressed: () => showGzInfoSheet(context, title: l10n.clientOnboardingInfoTitle, paragraphs: [l10n.clientOnboardingInfoBody]),
        ),
      ],
      textAction: GzTopBarTextAction(label: l10n.commonActionSkip, onPressed: onSkip),
    );
  }
}
