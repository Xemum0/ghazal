import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadRole;

import '../foundation.dart';

/// RoleBadge: the text chip that names who a person is in a visit group chat (Client, Hotel representative, Ghazal support).
/// Text only, no glyph that could pass for a face (ADR 0015); the role is also the accessible name. Three quiet tones: client =
/// hairline, hotel representative = neutral tint, support = rose tint. [you] swaps the chip to "You" on the viewer's own phone.
/// Non-interactive: 24 high, no 44 dp target.
class GzRoleBadge extends StatelessWidget {
  const GzRoleBadge({required this.role, this.you = false, this.wrap = false, super.key});

  final ThreadRole role;
  final bool you;

  /// The words may wrap to two lines and are centred (a narrow column such as the participant strip). Default: one line, and a label
  /// wider than its box spills past the padding (the web chip is `white-space: nowrap` with visible overflow).
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final label = you
        ? l.commonRoleYou
        : switch (role) {
            ThreadRole.client => l.commonRoleClient,
            ThreadRole.hotelRepresentative => l.commonRoleHotelRep,
            _ => l.commonRoleSupport,
          };
    final (Color? bg, Color? border, Color fg) = switch (role) {
      ThreadRole.client => (null, c.borderStrong, c.textPrimary),
      ThreadRole.hotelRepresentative => (c.statusNeutralBg, null, c.statusNeutralText),
      _ => (c.surfaceTint, null, c.textStrong),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.xsAll, border: Border.all(color: border ?? c.scrimClear, width: GzStroke.hair)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.pillMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + GzStroke.hair, vertical: GzSpace.s1 + GzStroke.hair),
            child: wrap
                ? GzText(label, role: GzTextRole.pill, color: fg, textAlign: TextAlign.center)
                : GzText(label, role: GzTextRole.pill, color: fg, softWrap: false, overflow: TextOverflow.visible),
          ),
        ),
      ),
    );
  }
}
