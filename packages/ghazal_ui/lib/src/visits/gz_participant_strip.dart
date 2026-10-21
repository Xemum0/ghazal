import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, ThreadMember, ThreadRole;

import '../core/core.dart';
import '../foundation.dart';

/// ParticipantStrip: the three members of a visit group chat side by side, each a monogram, a name and a role badge, in the fixed
/// order Client, Hotel representative, Ghazal support. Names show in the viewer's script (Arabic name in Arabic, Latin in English);
/// the avatar is a monogram, never a face. The whole strip is one target that opens the member sheet ([onOpen]); without it the
/// strip is informational. [showOrganisation] adds the organisation line under the hotel representative (the member sheet form).
class GzParticipantStrip extends StatelessWidget {
  const GzParticipantStrip({required this.members, this.meId, this.onOpen, this.showOrganisation = false, super.key});

  final List<ThreadMember> members;

  /// The signed-in person's user id: that member's badge reads "You".
  final String? meId;
  final VoidCallback? onOpen;
  final bool showOrganisation;

  static int _order(ThreadRole r) => switch (r) {
        ThreadRole.client => 0,
        ThreadRole.hotelRepresentative => 1,
        _ => 2,
      };

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final ar = lang == 'ar';
    final sorted = [...members]..sort((a, b) => _order(a.role).compareTo(_order(b.role)));
    final row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin - 2 * GzSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s2),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzAvatar(name: ar ? sorted[i].name : sorted[i].nameLatin, initial: ar ? sorted[i].monogram : null, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                    const SizedBox(height: GzSpace.s1),
                    GzText(ar ? sorted[i].name : sorted[i].nameLatin, role: GzTextRole.caption, color: c.textStrong, textAlign: TextAlign.center, maxLines: 2),
                    const SizedBox(height: GzSpace.s1),
                    _StripBadge(role: sorted[i].role, you: sorted[i].userId == meId),
                    if (showOrganisation && sorted[i].organisation != null) ...[
                      const SizedBox(height: GzSpace.s1),
                      GzText(_text(sorted[i].organisation!, lang), role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onOpen != null) {
      return GzPressable(onPressed: onOpen, semanticLabel: l.uiVisitsStripOpen, child: row);
    }
    return Semantics(container: true, label: l.uiVisitsStripLabel, child: row);
  }

  static String _text(LocalizedText t, String lang) => t.of(lang);
}

/// The role badge as the strip draws it: the same chip as [GzRoleBadge], but its words may wrap to two lines in a 106 dp column
/// ("Hotel representative" at 360), centred (the web `.gz-pstrip .gz-role`).
class _StripBadge extends StatelessWidget {
  const _StripBadge({required this.role, required this.you});

  final ThreadRole role;
  final bool you;

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
            child: GzText(label, role: GzTextRole.pill, color: fg, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
