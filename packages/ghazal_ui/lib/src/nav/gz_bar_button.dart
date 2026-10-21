import 'package:flutter/widgets.dart';

import '../core/core.dart';

/// `plain` = glyph on the bar; `disk` = canvas disk with the ring-fab hairline that floats over photography (direction section 5).
enum GzBarButtonTone { plain, disk }

/// BarButton: the icon target of a bar or a photo control. A 44 x 44 [GzIconButton] (disk 44) with an optional small gold count at
/// the target's top inline-end (hotel bell, client notifications).
class GzBarButton extends StatelessWidget {
  const GzBarButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.tone = GzBarButtonTone.plain,
    this.count,
    this.pressed,
    this.iconActive,
    super.key,
  });

  final IconData icon;

  /// Accessible name; an icon alone is not a name.
  final String label;
  final VoidCallback? onPressed;
  final GzBarButtonTone tone;

  /// Count shown as a small gold badge (9+ above nine).
  final int? count;

  /// Toggle state; the filled glyph comes from [iconActive].
  final bool? pressed;
  final IconData? iconActive;

  @override
  Widget build(BuildContext context) {
    final button = GzIconButton(
      icon: icon,
      iconActive: iconActive,
      label: label,
      onPressed: onPressed,
      variant: tone == GzBarButtonTone.disk ? GzIconButtonVariant.overImage : GzIconButtonVariant.plain,
      disk: GzIconButtonDisk.lg,
      active: pressed,
    );
    final n = count;
    if (n == null || n <= 0) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(top: 0, end: 0, child: ExcludeSemantics(child: IgnorePointer(child: GzCountBadge(count: n, max: 9, ring: true)))),
      ],
    );
  }
}
