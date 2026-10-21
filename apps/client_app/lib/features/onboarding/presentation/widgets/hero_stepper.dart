import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The one number of the guests page: a large stepper centred between two 44 buttons, its figure at the hero size (web `.obd-guests__hero`
/// on the system Stepper: 16 between the controls, a 64 wide figure at fig-xl). The kit stepper has no such variant yet (requests.md).
class ObdHeroStepper extends ConsumerWidget {
  const ObdHeroStepper({required this.value, required this.onChanged, required this.min, required this.max, required this.step, required this.valueText, super.key});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String Function(int) valueText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final l10n = context.gzL10n;
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The web row also holds the (visually hidden) label before the controls: one 16 gap that shifts the group toward the end.
            const SizedBox(width: GzSpace.s4),
            _StepButton(icon: GzIcons.minus, label: l10n.uiInputsStepperDecrease, enabled: value > min, onPressed: () => onChanged((value - step).clamp(min, max))),
            const SizedBox(width: GzSpace.s4),
            SizedBox(
              width: GzSpace.s16,
              child: Center(
                child: Semantics(liveRegion: true, label: valueText(value), excludeSemantics: true, child: GzNum(f.integer(value), role: GzTextRole.figXl, color: c.textStrong)),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            _StepButton(icon: GzIcons.plus, label: l10n.uiInputsStepperIncrease, enabled: value < max, onPressed: () => onChanged((value + step).clamp(min, max))),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.enabled, required this.onPressed});

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      semanticLabel: label,
      onPressed: enabled ? onPressed : null,
      borderRadius: GzRadius.smAll,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: GzRadius.smAll, border: Border.all(color: enabled ? c.borderControl : c.borderHairline, width: GzStroke.hair)),
        child: SizedBox(width: GzSize.touchMin, height: GzSize.touchMin, child: Center(child: GzIcon(icon, size: GzIconSize.md, color: enabled ? c.iconPrimary : c.iconDisabled))),
      ),
    );
  }
}
