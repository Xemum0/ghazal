import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'thread_progress.dart';

/// The info glyph and its sheet (web `InfoButton`): one paragraph one tap away.
class ObdInfoButton extends StatelessWidget {
  const ObdInfoButton({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => GzIconButton(
        icon: GzIcons.info,
        label: context.l10n.commonA11yInfo,
        onPressed: () => showGzSheet<void>(
          context,
          title: title,
          builder: (context) => GzText(body, role: GzTextRole.body, color: context.gz.colors.textPrimary),
        ),
      );
}

/// The bar of the profile steps CL-ONBD-03 to 06: Back at inline-start, the thread in the middle, the info glyph and a text Skip at
/// inline-end. Safe-top inset, a 56 row, the glyph edge of Back and the text edge of Skip on the 20 gutter (web `StepBar`).
class ObdStepBar extends StatelessWidget {
  const ObdStepBar({required this.step, required this.total, required this.onSkip, super.key});

  /// 1-based step.
  final int step;
  final int total;
  final VoidCallback onSkip;

  static const double _startPad = GzSpace.gutter - (GzSize.touchMin - GzSize.iconMd) / 2;
  static const double _endPad = GzSpace.gutter - GzSpace.s2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: context.gz.colors.surfaceCanvas,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top, start: _startPad, end: _endPad),
        child: SizedBox(
          height: GzSize.controlLg,
          child: Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin),
                child: GzBarButton(key: const ValueKey<String>('gz:bar.back'), icon: GzIcons.back, label: l10n.commonActionBack, onPressed: () => context.gzNav.pop()),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: ObdThreadProgress(count: total, index: step - 1, label: l10n.clientOnboardingStepProgress(step, total))),
              const SizedBox(width: GzSpace.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ObdInfoButton(title: l10n.clientOnboardingInfoTitle, body: l10n.clientOnboardingInfoBody),
                    const SizedBox(width: GzSpace.s1),
                    GzButton(label: l10n.commonActionSkip, variant: GzButtonVariant.tertiary, onPressed: onSkip),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
