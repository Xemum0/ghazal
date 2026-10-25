// VisitQueueCard (web `VisitQueueCard.tsx`): one visit of the queue. The client's first name on a monogram, the date and the arrival window in
// the figures voice, how many come, the note as a quiet quote and, for a request that waits for a reply, "Confirm" (gold, one per card) and
// "Another time" inline. The body is one 44+ target that opens the detail; the actions are separate.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitAppointment, VisitStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_data.dart';

class VisitQueueCard extends StatelessWidget {
  const VisitQueueCard({
    required this.visit,
    required this.requestedTab,
    required this.locked,
    required this.onOpen,
    required this.onConfirm,
    required this.onPropose,
    super.key,
  });

  final VisitAppointment visit;
  final bool requestedTab;
  final bool locked;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final v = visit;
    final name = firstName(v.clientName);
    final decide = requestedTab && v.status == VisitStatus.requested;
    final visitors = l.hotelVisitsVisitors(v.visitors);
    final body = GzPressable(
      onPressed: onOpen,
      semanticLabel: l.hotelVisitsOpenVisit(name, f.plain(f.dateTime(v.slotStart, DateStyle.short))),
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: GzSize.touchMin,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GzAvatar(name: name, initial: lang == 'ar' ? name.substring(0, 1) : null, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                    GzText(
                      decide ? l.hotelVisitsRequestedAgo(f.ago(v.requestedAt)) : visitors,
                      role: GzTextRole.caption,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
              if (!decide) ...[const SizedBox(width: GzSpace.s3), GzStatusPill(status: visitPill(v.status), audience: GzStatusAudience.hotel)],
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          GzText(f.date(v.slotStart, DateStyle.short), role: GzTextRole.uiTitle, color: c.textStrong, figures: true),
          const SizedBox(height: GzSpace.s2),
          Wrap(
            spacing: GzSpace.s4,
            runSpacing: GzSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s1),
                  GzText(f.timeRange(v.slotStart, v.slotEnd), role: GzTextRole.figBodyS, color: c.textSecondary, figures: true),
                ],
              ),
              if (decide)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(GzIcons.guests, size: GzIconSize.xs, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    GzText(visitors, role: GzTextRole.bodyS, color: c.textSecondary),
                  ],
                ),
            ],
          ),
          if (v.note != null && v.note!.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s2),
            Container(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s3),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: c.borderStrong, width: GzStroke.hair),
                ),
              ),
              child: GzUserText(v.note!, role: GzTextRole.bodyS, color: c.textPrimary, maxLines: 2),
            ),
          ],
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (decide) ...[
            const SizedBox(height: GzSpace.s4),
            Row(
              children: [
                Expanded(
                  child: GzButton(
                    label: l.hotelVisitsConfirm,
                    size: GzButtonSize.md,
                    iconStart: GzIcons.check,
                    fullWidth: true,
                    spill: true,
                    onPressed: locked ? null : onConfirm,
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(
                    label: l.hotelVisitsPropose,
                    variant: GzButtonVariant.secondary,
                    size: GzButtonSize.md,
                    fullWidth: true,
                    spill: true,
                    onPressed: locked ? null : onPropose,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
