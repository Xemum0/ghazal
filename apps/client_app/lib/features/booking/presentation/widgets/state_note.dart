import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// A state line that has something to do (verify the number, see your open requests): a glyph, a fragment of a few words, one action
/// beneath at inline-start and optionally the info glyph that opens the sentence behind it (web `StateNote`). Rose panel; danger tone
/// for a taken date.
class BookingStateNote extends StatelessWidget {
  const BookingStateNote({
    required this.icon,
    required this.text,
    this.danger = false,
    this.actionLabel,
    this.onAction,
    this.infoTitle,
    this.infoBody,
    super.key,
  });

  final IconData icon;
  final String text;
  final bool danger;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? infoTitle;
  final String? infoBody;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final fg = danger ? c.statusDangerText : c.textStrong;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: danger ? c.statusDangerBg : c.surfaceTint, borderRadius: GzRadius.smAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
          child: Row(
            children: [
              GzIcon(icon, size: GzIconSize.md, color: danger ? c.iconDanger : c.iconPrimary),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: GzSpace.s3,
                  children: [
                    GzText(text, role: GzTextRole.bodyS, color: fg, figures: true),
                    if (actionLabel != null) GzButton(label: actionLabel!, variant: GzButtonVariant.tertiary, onPressed: onAction),
                  ],
                ),
              ),
              if (infoTitle != null && infoBody != null) ...[
                const SizedBox(width: GzSpace.s3),
                GzInfoButton(title: infoTitle!, paragraphs: [infoBody!]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
