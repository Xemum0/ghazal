// Pieces of the visit detail (web `DetailBar.tsx`, `Timeline.tsx`): the pinned decision bar by status and the visit's own timeline.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitAppointment, VisitStatus, VisitStatusChange, VisitActor;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_data.dart';
import 'visit_actions.dart';

/// The pinned bar of the visit detail, by status and role: Requested = the ONE gold Confirm then Another time and Decline; Confirmed = Open
/// chat, and on the day Mark arrived takes the gold; Arrived = Open chat; a missed visit a lead may correct. Past visits have no bar.
class VisitBar extends StatelessWidget {
  const VisitBar({required this.visit, required this.lead, required this.now, required this.act, required this.isoDay, super.key});

  final VisitAppointment visit;
  final bool lead;
  final DateTime now;
  final VisitUi act;
  final String Function(DateTime) isoDay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final v = visit;
    final children = <Widget>[];
    if (v.status == VisitStatus.requested) {
      children.add(
        GzButton(
          label: l.hotelVisitsConfirm,
          size: GzButtonSize.cta,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.check,
          onPressed: () => act.confirm(v),
        ),
      );
      children.add(
        Row(
          children: [
            Expanded(
              child: GzButton(
                label: l.hotelVisitsProposeShort,
                variant: GzButtonVariant.secondary,
                size: GzButtonSize.md,
                fullWidth: true,
                spill: true,
                onPressed: () => act.propose(v),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzButton(
                label: l.commonActionDecline,
                variant: GzButtonVariant.secondary,
                size: GzButtonSize.md,
                fullWidth: true,
                spill: true,
                onPressed: () => act.decline(v, after: GzNavigatorScope.of(context).pop),
              ),
            ),
          ],
        ),
      );
    } else if (v.status == VisitStatus.confirmed && canMarkArrived(v, now, isoDay)) {
      children.add(
        GzButton(
          label: l.hotelVisitsMarkArrived,
          size: GzButtonSize.cta,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.pin,
          onPressed: () => act.arrival(v),
        ),
      );
      children.add(
        GzButton(
          label: l.hotelVisitsOpenChat,
          variant: GzButtonVariant.secondary,
          size: GzButtonSize.md,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.chat,
          onPressed: () => act.chat(v),
        ),
      );
    } else if (v.status == VisitStatus.confirmed || v.status == VisitStatus.rescheduleProposed) {
      children.add(
        GzButton(
          label: l.hotelVisitsOpenChat,
          size: GzButtonSize.cta,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.chat,
          onPressed: () => act.chat(v),
        ),
      );
    } else if (v.status == VisitStatus.arrived) {
      children.add(
        GzButton(
          label: l.hotelVisitsOpenChat,
          size: GzButtonSize.cta,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.chat,
          onPressed: () => act.chat(v),
        ),
      );
    } else if (v.status == VisitStatus.missed && lead && canFlagMissed(v, now)) {
      children.add(
        GzButton(
          label: l.hotelVisitsCorrectMissed,
          variant: GzButtonVariant.secondary,
          size: GzButtonSize.md,
          fullWidth: true,
          spill: true,
          iconStart: GzIcons.pin,
          onPressed: () => act.arrival(v),
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    final inset = GzBottomChrome.tabBarOf(context) ? 0.0 : MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3 + inset),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), children[i]],
        ],
      ),
    );
  }
}

/// What happened to the visit, oldest first, from its own history: a quiet rail with ink dots (never gold), what, who and when.
class VisitTimeline extends StatelessWidget {
  const VisitTimeline({required this.visit, required this.repName, super.key});

  final VisitAppointment visit;
  final String repName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    String what(VisitStatus s) => switch (s) {
      VisitStatus.requested => l.hotelVisitsTlRequested,
      VisitStatus.confirmed => l.hotelVisitsTlConfirmed,
      VisitStatus.rescheduleProposed => l.hotelVisitsTlReschedule,
      VisitStatus.arrived => l.hotelVisitsTlArrived,
      VisitStatus.completed => l.hotelVisitsTlCompleted,
      VisitStatus.declined => l.hotelVisitsTlDeclined,
      VisitStatus.cancelled => l.hotelVisitsTlCancelled,
      _ => l.hotelVisitsTlMissed,
    };
    String who(VisitStatusChange h) => switch (h.actor) {
      VisitActor.client => firstName(visit.clientName),
      VisitActor.support => l.hotelVisitsActorSupport,
      VisitActor.system => l.hotelVisitsActorSystem,
      _ => repName.isNotEmpty ? repName : (h.actorName ?? l.hotelVisitsActorHotel),
    };
    final rows = visit.history;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: GzSpace.s4,
                  child: Column(
                    children: [
                      Container(
                        width: GzSize.knotBead,
                        height: GzSize.knotBead,
                        margin: const EdgeInsets.only(top: GzSpace.s2),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.textStrong),
                      ),
                      if (i < rows.length - 1)
                        Expanded(
                          child: Container(
                            width: GzStroke.hair,
                            margin: const EdgeInsets.only(top: GzSpace.s1),
                            color: c.borderStrong,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : GzSpace.s5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(what(rows[i].status), role: GzTextRole.title, color: c.textStrong),
                        Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                child: GzUserText(who(rows[i]), role: GzTextRole.caption, color: c.textSecondary),
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                              ),
                              WidgetSpan(
                                child: GzText(' · ', role: GzTextRole.caption, color: c.textSecondary),
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                              ),
                              WidgetSpan(
                                child: GzText(
                                  f.dateTime(rows[i].at, DateStyle.short),
                                  role: GzTextRole.caption,
                                  color: c.textSecondary,
                                  figures: true,
                                ),
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
