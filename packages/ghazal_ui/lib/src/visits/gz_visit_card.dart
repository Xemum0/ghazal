import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitAppointment, VisitStatus;

import '../core/core.dart';
import '../foundation.dart';

enum GzVisitAudience { client, hotel }

GzStatus _state(VisitStatus s) => switch (s) {
  VisitStatus.requested => GzStatus.visitRequested,
  VisitStatus.confirmed => GzStatus.visitConfirmed,
  VisitStatus.rescheduleProposed => GzStatus.visitReschedule,
  VisitStatus.arrived => GzStatus.visitArrived,
  VisitStatus.completed => GzStatus.visitCompleted,
  VisitStatus.declined => GzStatus.visitDeclined,
  VisitStatus.cancelled => GzStatus.visitCancelled,
  _ => GzStatus.visitMissed,
};

/// VisitCard: one site visit as a quiet card (ADR 0033 D9). Status pill, the party size, the date and the 30-minute arrival window
/// in the figures voice, who it is with, and one action into the group chat. The client sees the venue ([venueName], and the
/// representative's [representativeName] under it); the partner ([GzVisitAudience.hotel]) sees the client's name from the visit. A
/// finished visit says the chat is read-only. [onOpen] makes the body one 44 dp target. A widget never looks anything up: the
/// caller passes the resolved names in the viewer's language.
class GzVisitCard extends StatelessWidget {
  const GzVisitCard({
    required this.visit,
    this.audience = GzVisitAudience.client,
    this.venueName = '',
    this.representativeName,
    this.onOpenChat,
    this.onOpen,
    super.key,
  });

  final VisitAppointment visit;
  final GzVisitAudience audience;
  final String venueName;
  final String? representativeName;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final v = visit;
    final title = audience == GzVisitAudience.client ? venueName : v.clientName;
    final readOnly =
        v.status == VisitStatus.completed || v.status == VisitStatus.cancelled || v.status == VisitStatus.declined || v.status == VisitStatus.missed;
    final when = f.date(v.slotStart, DateStyle.full);
    final window = f.timeRange(v.slotStart, v.slotEnd);
    final party = GzBidi.strip(f.guests(v.visitors));
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GzStatusPill(status: _state(v.status)),
            const SizedBox(width: GzSpace.s3),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.guests, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s1),
                  Flexible(
                    child: GzText(party, role: GzTextRole.caption, color: c.textSecondary, figures: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s2 + GzSpace.s1),
        GzText(when, role: GzTextRole.uiTitle, color: c.textStrong, figures: true),
        const SizedBox(height: GzSpace.s1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s1),
            GzNum(window, role: GzTextRole.figBodyS, color: c.textSecondary),
          ],
        ),
        const SizedBox(height: GzSpace.s1),
        GzText(title, role: GzTextRole.bodyS, color: c.textStrong),
        if (representativeName != null && audience == GzVisitAudience.client) ...[
          const SizedBox(height: GzSpace.s1),
          GzText(l.uiVisitsCardWith(representativeName!), role: GzTextRole.caption, color: c.textSecondary),
        ],
      ],
    );
    final label = [title, _state(v.status).label(l), when, GzBidi.strip(window), party].join(', ');
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        padding: const EdgeInsets.all(GzSpace.panelPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onOpen != null)
              GzPressable(onPressed: onOpen, semanticLabel: label, child: body)
            else
              Semantics(
                container: true,
                label: label,
                child: ExcludeSemantics(child: body),
              ),
            if (onOpenChat != null) ...[
              const SizedBox(height: GzSpace.s3),
              GzButton(label: l.uiVisitsCardChat, variant: GzButtonVariant.secondary, iconStart: GzIcons.chat, fullWidth: true, onPressed: onOpenChat),
            ],
            if (readOnly && onOpenChat != null) ...[
              const SizedBox(height: GzSpace.s3),
              GzText(l.uiVisitsCardReadOnly, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
