import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_button.dart';
import 'gz_divider.dart';
import 'gz_draw_once.dart';

/// `client` = display serif d2; `partner` = UI title 20/28 (the partner app keeps the serif for names and the greeting).
enum GzHeaderVoice { client, partner }

/// SectionHeader (direction section 3, "Section head"): the 24 x 1 gold khayt, then the title, an optional eyebrow label (at most
/// two per screen) and `See all` as a tertiary button at inline-end. The khayt draws on once as the header is first built.
/// The title is a heading for assistive technology.
class GzSectionHeader extends StatelessWidget {
  const GzSectionHeader({
    required this.title,
    this.eyebrow,
    this.voice = GzHeaderVoice.client,
    this.onSeeAll,
    this.seeAllLabel,
    this.action,
    this.draw = GzDraw.inview,
    super.key,
  });

  final String title;

  /// Small label above the title (direction: at most two per screen, never on every section).
  final String? eyebrow;
  final GzHeaderVoice voice;

  /// Shows the See all button.
  final VoidCallback? onSeeAll;

  /// Replace `See all` (a section with a count, "See all 38").
  final String? seeAllLabel;

  /// One more control at inline-end of the title row (an info button or one icon button).
  final Widget? action;
  final GzDraw draw;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: draw)),
        const SizedBox(height: GzSpace.s3),
        if (eyebrow != null) ...[
          GzText(eyebrow!, role: GzTextRole.label, color: c.textSecondary),
          const SizedBox(height: GzSpace.s3),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GzText(title, role: voice == GzHeaderVoice.client ? GzTextRole.d2 : GzTextRole.uiTitle, color: c.textStrong, header: true),
            ),
            if (action != null) ...[const SizedBox(width: GzSpace.s4), action!],
            if (onSeeAll != null) ...[
              const SizedBox(width: GzSpace.s4),
              GzButton(
                label: seeAllLabel ?? context.gzL10n.commonActionSeeAll,
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
