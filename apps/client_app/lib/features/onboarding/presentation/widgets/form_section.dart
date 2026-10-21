import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// One question of a profile step with its own head (web `FormSection`): the 24 x 1 gold khayt, then a glyph and the question in the
/// client serif (d1), a quiet unit and an optional quiet action at inline-end.
class ObdFormSection extends StatelessWidget {
  const ObdFormSection({required this.title, required this.child, this.icon, this.unit, this.action, super.key});

  final String title;
  final IconData? icon;

  /// A quiet unit after the title (the currency): the figures under it carry no currency of their own.
  final String? unit;

  /// A tertiary button at inline-end of the title row.
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: GzThreadRule(draw: GzDraw.inview),
        ),
        const SizedBox(height: GzSpace.s3),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            children: [
              if (icon != null) ...[GzIcon(icon!, size: GzIconSize.md), const SizedBox(width: GzSpace.s2)],
              Flexible(
                flex: 100,
                child: GzText(title, role: GzTextRole.d1, color: c.textStrong, header: true),
              ),
              if (unit != null) ...[const SizedBox(width: GzSpace.s2), GzText(unit!, role: GzTextRole.label, color: c.textSecondary, figures: true)],
              if (action != null) ...[const Spacer(), action!],
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        child,
      ],
    );
  }
}
