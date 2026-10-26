import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show PlannerMeeting, PlannerTier;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'plan_panel.dart';
import 'planner_parts.dart' show TierMarks;

/// The planner as a person (web `PlannerIdentity`): monogram, name, role, her package as thread marks and a word; `action` at inline-end.
class PlanPlannerPanel extends StatelessWidget {
  const PlanPlannerPanel({
    required this.name,
    required this.role,
    required this.monogram,
    required this.tier,
    required this.tierName,
    this.action,
    super.key,
  });

  final String name;
  final String role;
  final String monogram;
  final PlannerTier tier;
  final String tierName;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final marks = switch (tier) {
      PlannerTier.silver => 1,
      PlannerTier.gold => 2,
      _ => 3,
    };
    return Semantics(
      container: true,
      label: name,
      child: PlanPanel(
        child: Row(
          children: [
            ExcludeSemantics(
              child: GzAvatar(name: name, initial: monogram, size: GzAvatarSize.lg),
            ),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(name, role: GzTextRole.title, color: c.textStrong),
                  const SizedBox(height: GzStroke.thread),
                  GzText(role, role: GzTextRole.caption, color: c.textSecondary),
                  const SizedBox(height: GzStroke.thread),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TierMarks(count: marks, label: l.clientPlannerMarks(marks)),
                        const SizedBox(width: GzSpace.s2),
                        Flexible(
                          child: GzText(tierName, role: GzTextRole.caption, color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: GzSpace.s4), action!],
          ],
        ),
      ),
    );
  }
}

/// The three-knot thread of the status screen (web `IconProgress` with `.gzp3-thread`): the last column hugs its knot and its one word
/// ends flush with the knot's outer edge, so the thread runs edge to edge (the shared `GzIconProgress` gives every column an equal share).
class PlanThread extends StatelessWidget {
  const PlanThread({required this.steps, required this.label, required this.describe, super.key});

  final List<GzIconProgressStep> steps;
  final String label;
  final String describe;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final titleWeight = gz.text(GzTextRole.title).fontWeight;
    final cols = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final last = i == steps.length - 1;
      final shown = s.state == GzKnotState.now;
      final iconColor = switch (s.state) {
        GzKnotState.now => c.iconAccent,
        GzKnotState.open => c.iconDisabled,
        _ => c.iconPrimary,
      };
      final col = Semantics(
        label: s.label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: GzSize.iconLg,
              height: GzSize.iconMd,
              child: Center(
                child: GzIcon(s.icon, size: GzIconSize.md, color: iconColor),
              ),
            ),
            const SizedBox(height: GzSpace.s1),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: GzSpace.s1),
              child: Row(
                children: [
                  GzThreadKnot(state: s.state),
                  if (!last) ...[
                    const SizedBox(width: GzSpace.s1),
                    Expanded(
                      child: SizedBox(
                        height: GzStroke.thread,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: c.markTrack)),
                            if (steps[i + 1].state != GzKnotState.open)
                              Positioned.fill(
                                child: GzDrawOnce(
                                  enabled: true,
                                  delay: GzMotion.durationFast * i,
                                  child: ColoredBox(color: c.markKhayt),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (shown) ...[
              const SizedBox(height: GzSpace.s1),
              SizedBox(
                width: GzSize.iconLg,
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: double.infinity,
                  alignment: last ? AlignmentDirectional.topEnd : AlignmentDirectional.topStart,
                  fit: OverflowBoxFit.deferToChild,
                  child: Text(
                    s.label,
                    softWrap: false,
                    style: gz.text(GzTextRole.caption).copyWith(color: c.textStrong, fontWeight: titleWeight, decoration: TextDecoration.none),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      cols.add(last ? col : Expanded(child: col));
    }
    return Semantics(
      container: true,
      label: '$label: $describe',
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
    );
  }
}

/// The scheduled meeting (web `.gzp3-meeting`): time as the figure with the date on its baseline, a ruled foot with the channel glyph at
/// inline-start and add-to-calendar + Reschedule at inline-end.
class PlanMeetingCard extends StatelessWidget {
  const PlanMeetingCard({required this.meeting, required this.today, required this.typeName, required this.onCalendar, this.onReschedule, super.key});

  final PlannerMeeting meeting;
  final bool today;
  final String typeName;
  final VoidCallback onCalendar;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: l.clientPlannerStatusMeetingLabel,
      child: PlanPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                GzText(f.time(meeting.at), role: GzTextRole.uiXl, color: c.textStrong, figures: true),
                const SizedBox(width: GzSpace.s4),
                if (today)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GzThreadBead(),
                      const SizedBox(width: GzSpace.s1),
                      GzText(lg.commonLabelToday, role: GzTextRole.body, color: c.textGoldInk),
                    ],
                  )
                else
                  GzText(f.date(meeting.at, DateStyle.short), role: GzTextRole.body, color: c.textPrimary, figures: true),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            Container(
              padding: const EdgeInsets.only(top: GzSpace.s3),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GzFactChip(icon: meeting.channel == 'phone' ? GzIcons.phone : GzIcons.video, label: '$typeName, ${lg.commonLabelKuwaitTime}'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzIconButton(
                        icon: GzIcons.calendarPlus,
                        variant: GzIconButtonVariant.outline,
                        label: l.clientPlannerStatusAddToCalendar,
                        onPressed: onCalendar,
                      ),
                      const SizedBox(width: GzSpace.s2),
                      GzButton(label: lg.commonActionReschedule, variant: GzButtonVariant.tertiary, onPressed: onReschedule),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
