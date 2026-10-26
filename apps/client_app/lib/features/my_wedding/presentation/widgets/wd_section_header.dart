import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The web SectionHeader with a node title (CL-WEDD-03): the khayt thread rule, the display title with the currency unit inline after it
/// (caption, secondary, 8 from the title, on its baseline) or an info glyph, and the one-word See all at inline-end.
class WdSectionHeader extends StatelessWidget {
  const WdSectionHeader({required this.title, this.unit, this.info, this.seeAllLabel, this.onSeeAll, super.key});

  final String title;
  final String? unit;
  final Widget? info;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: GzThreadRule(draw: GzDraw.mount),
        ),
        const SizedBox(height: GzSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
                  ),
                  if (unit != null) ...[const SizedBox(width: GzSpace.s2), GzText(unit!, role: GzTextRole.caption, color: c.textSecondary)],
                  ?info,
                ],
              ),
            ),
            if (onSeeAll != null) ...[
              const SizedBox(width: GzSpace.s4),
              GzButton(
                label: seeAllLabel ?? '',
                variant: GzButtonVariant.tertiary,
                iconEnd: GzIcons.chevronRight,
                flushInline: true,
                onPressed: onSeeAll,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
