// The invitation as a read-only card (HL-ACCS-03) and the message picture inside the Invitation sheet (HL-ACCS-01): the envelope, the venue
// (serif, it is a venue name), the role as a tag with its summary behind an info glyph, then three glyph facts.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show InvitationPreview;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'access_labels.dart';
import 'access_parts.dart';

BoxDecoration _panel(GzColors c) => BoxDecoration(
  color: c.surfaceRaised,
  borderRadius: GzRadius.mdAll,
  border: Border.all(color: c.borderStrong, width: GzStroke.hair),
);

class _Head extends StatelessWidget {
  const _Head({required this.preview, required this.info});

  final InvitationPreview preview;
  final bool info;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final role = staffRoleLabel(l, preview.role);
    return Row(
      children: [
        const GzIllustration(GzIllustrationName.envelope, size: GzIllustrationSize.sm),
        const SizedBox(width: GzSpace.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(preview.accountName.of(lang), role: GzTextRole.d1, color: c.textStrong),
              const SizedBox(height: GzSpace.s1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzTag(label: role, icon: GzIcons.user),
                  if (info)
                    Transform.translate(
                      offset: Offset(context.gz.isRtl ? 8 : -8, 0),
                      child: AccessInfoGlyph(title: role, body: staffRoleSummary(l, preview.role), label: l.hotelAccessSetupRoleInfo),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: child,
    );
  }
}

/// The read-only invitation card of HL-ACCS-03.
class InviteCard extends StatelessWidget {
  const InviteCard({required this.preview, super.key});

  final InvitationPreview preview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final valid = f.date(preview.expiresAt, DateStyle.dayMonth);
    return Semantics(
      container: true,
      label: l.hotelAccessSetupCardLabel,
      child: Container(
        padding: GzSpace.panel,
        decoration: _panel(c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Head(preview: preview, info: true),
            const SizedBox(height: GzSpace.s3),
            _FactLine(
              child: GzFactChip(icon: GzIcons.userPlus, label: l.hotelAccessInviteFrom(preview.invitedBy), value: preview.invitedBy),
            ),
            _FactLine(
              child: GzFactChip(
                icon: GzIcons.mail,
                label: l.hotelAccessSetupInvitedEmail,
                valueWidget: Flexible(child: GzLtr(child: GzText(preview.email, role: GzTextRole.body, maxLines: 1))),
              ),
            ),
            _FactLine(
              child: GzFactChip(icon: GzIcons.calendar, label: l.hotelAccessSetupValidUntil(valid), value: valid),
            ),
          ],
        ),
      ),
    );
  }
}

/// The message picture of the Invitation sheet: envelope, venue, role and a ruled foot with the sender and the link.
class InviteMessage extends StatelessWidget {
  const InviteMessage({required this.preview, this.onOpen, super.key});

  final InvitationPreview preview;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.panelPad, end: GzSpace.panelPad, top: GzSpace.panelPad, bottom: GzSpace.s2),
      decoration: _panel(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Head(preview: preview, info: false),
          const SizedBox(height: GzSpace.s3),
          Container(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: GzFactChip(icon: GzIcons.userPlus, label: l.hotelAccessInviteFrom(preview.invitedBy), value: preview.invitedBy),
                ),
                const SizedBox(width: GzSpace.s3),
                Transform.translate(
                  offset: Offset(context.gz.isRtl ? -8 : 8, 0),
                  child: GzButton(label: l.hotelAccessInviteLink, variant: GzButtonVariant.tertiary, iconStart: GzIcons.mail, onPressed: onOpen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
