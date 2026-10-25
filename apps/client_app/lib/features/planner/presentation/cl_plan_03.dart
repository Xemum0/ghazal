import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, PlannerRequest, PlannerTier;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/planner_data.dart';
import 'widgets/planner_parts.dart';

/// CL-PLAN-03 Your planner (request status). Covers CA-PLAN-07, CA-PLAN-08, CA-CHAT-03.
/// Entry from 'CL-WEDD-01' (the My Wedding planner module) returns there with
/// system back.
///
/// The three states of the request (sent, planner assigned, meeting
/// scheduled) are one icon thread with one word under the active step. Waiting
/// opens with the hourglass and the request summary; once a planner is
/// assigned she is the screen (monogram, name, role, package, a chat glyph);
/// a scheduled meeting is a card (time as the figure, date, a glyph for video
/// or phone, add to calendar, reschedule). No planner directory, no presence.
/// States: requested-waiting, assigned, meeting-scheduled, meeting-day,
/// loading, error, offline.
class ClPlan03Screen extends ConsumerWidget {
  const ClPlan03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final nav = context.gzNav;
    final frame = nav.params['frame'];
    final async = ref.watch(currentPlannerRequestProvider);
    final problem = async.hasError && !async.hasValue
        ? (async.error is ApiProblem ? async.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown))
        : null;
    final offline = problem?.isOffline ?? false;
    if (problem != null && !offline) {
      return GzScreen(
        top: GzTopBar(title: l.clientPlannerStatusTitle),
        child: GzErrorState(
          key: const ValueKey<String>('planner.status.error'),
          kind: gzProblemKind(problem),
          body: gzProblemMessage(lg, problem),
          fill: false,
          onRetry: () => ref.invalidate(currentPlannerRequestProvider),
        ),
      );
    }
    if (async.isLoading && !async.hasValue) {
      return GzScreen(
        top: GzTopBar(title: l.clientPlannerStatusTitle),
        child: const Column(
          key: ValueKey<String>('planner.status.loading'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSkeleton(variant: GzSkeletonVariant.circle, blockSize: 96),
            SizedBox(height: GzSpace.s3),
            GzSkeletonText(lines: 1),
            SizedBox(height: GzSpace.s4),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
          ],
        ),
      );
    }
    return _StatusBody(request: async.value, frame: frame is String ? frame : null, offline: offline);
  }
}

class _StatusBody extends ConsumerWidget {
  const _StatusBody({required this.request, required this.frame, required this.offline});

  final PlannerRequest? request;
  final String? frame;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final nav = context.gzNav;
    final PlannerTier tier = request?.tier ?? ref.watch(plannerTierProvider);
    final status = _statusOf(request, frame);
    final assigned = status != 'requested';
    final scheduled = status == 'meeting_scheduled';
    final meeting = (scheduled ? request?.meeting : null);
    final plannerAsync = request?.plannerId == null ? null : ref.watch(plannerDetailProvider(request!.plannerId!));
    final plannerName = plannerAsync?.value?.planner.name.of(lang) ?? (assigned ? 'نوف العتيبي' : '');
    // The story planner for frames without a server answer.
    final displayName = plannerName.isEmpty ? (lang == 'ar' ? 'نوف العتيبي' : 'Nouf Al-Otaibi') : plannerName;
    final displayRole = plannerAsync?.value?.planner.role.of(lang) ?? (lang == 'ar' ? 'منسّقة أعراس' : 'Wedding planner');
    final monogram = plannerAsync?.value?.planner.monogram ?? 'ن';
    final pkgs = ref.watch(plannerPackagesProvider).value ?? const [];
    final pkgName = pkgs.where((p) => p.tier == tier).firstOrNull?.name.of(lang) ?? tier.value;

    final steps = [
      GzIconProgressStep(id: 'requested', icon: GzIcons.send, label: l.clientPlannerStatusStepRequested, state: GzKnotState.tied),
      GzIconProgressStep(
        id: 'assigned',
        icon: GzIcons.user,
        label: l.clientPlannerStatusStepAssigned,
        state: assigned ? GzKnotState.tied : GzKnotState.now,
      ),
      GzIconProgressStep(
        id: 'meeting',
        icon: GzIcons.calendarCheck,
        label: l.clientPlannerStatusStepMeeting,
        state: scheduled ? GzKnotState.tied : (assigned ? GzKnotState.now : GzKnotState.open),
      ),
    ];
    final reached = scheduled
        ? 3
        : assigned
        ? 2
        : 1;

    GzActionBar? bar;
    if (scheduled) {
      bar = GzActionBar(
        action: GzActionBarAction(label: lg.commonActionMessage, iconEnd: GzIcons.chat, onPressed: () => _message(context, ref)),
      );
    } else if (assigned) {
      bar = GzActionBar(
        action: GzActionBarAction(
          label: l.clientPlannerStatusSchedule,
          iconEnd: GzIcons.calendarPlus,
          onPressed: offline ? null : () => nav.openSheet('CL-PLAN-04'),
        ),
      );
    }

    final typeName = meeting?.channel == 'phone' ? l.clientPlannerTypePhoneName : l.clientPlannerTypeVideoName;
    final meetingDay = frame == 'today';

    return GzScreen(
      top: GzTopBar(title: l.clientPlannerStatusTitle),
      bottom: bar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) GzBanner(message: lg.commonStateOffline, tone: GzBannerTone.offline),
          if (!assigned)
            GzEmptyState(
              key: const ValueKey<String>('planner.status.waiting'),
              illustration: GzIllustrationName.hourglass,
              title: l.clientPlannerStatusHeadWaiting,
              fill: false,
            ),
          if (assigned)
            Semantics(
              key: const ValueKey<String>('planner.status.planner'),
              container: true,
              label: displayName,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.gz.colors.surfaceRaised,
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: context.gz.colors.borderHairline, width: GzStroke.hair),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(GzSpace.s4),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: GzAvatar(name: displayName, initial: monogram, size: GzAvatarSize.lg),
                      ),
                      const SizedBox(width: GzSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzText(displayName, role: GzTextRole.title, color: context.gz.colors.textStrong),
                            const SizedBox(height: 2),
                            GzText(displayRole, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TierMarks(
                                  count: tier == PlannerTier.silver
                                      ? 1
                                      : tier == PlannerTier.gold
                                      ? 2
                                      : 3,
                                  label: l.clientPlannerMarks(
                                    tier == PlannerTier.silver
                                        ? 1
                                        : tier == PlannerTier.gold
                                        ? 2
                                        : 3,
                                  ),
                                ),
                                const SizedBox(width: GzSpace.s2),
                                Flexible(
                                  child: GzText(pkgName, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!scheduled) ...[
                        const SizedBox(width: GzSpace.s4),
                        GzIconButton(
                          icon: GzIcons.chat,
                          variant: GzIconButtonVariant.outline,
                          label: l.clientPlannerStatusMessageName(displayName),
                          onPressed: () => _message(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: GzSpace.s4),
          GzIconProgress(
            key: const ValueKey<String>('planner.status.thread'),
            steps: steps,
            label: l.clientPlannerStatusThreadLabel,
            describe: lg.commonCounter(reached, steps.length),
          ),
          if (scheduled && meeting != null) ...[
            const SizedBox(height: GzSpace.s4),
            Semantics(
              key: const ValueKey<String>('planner.status.meeting'),
              container: true,
              label: l.clientPlannerStatusMeetingLabel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.gz.colors.surfaceRaised,
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: context.gz.colors.borderHairline, width: GzStroke.hair),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(GzSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GzText(context.gzFormat.time(meeting.at), role: GzTextRole.uiXl, color: context.gz.colors.textStrong, figures: true),
                          if (meetingDay)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const GzThreadBead(),
                                const SizedBox(width: GzSpace.s2),
                                GzText(lg.commonLabelToday, role: GzTextRole.body, color: context.gz.colors.textStrong),
                              ],
                            )
                          else
                            GzText(
                              context.gzFormat.date(meeting.at, DateStyle.short),
                              role: GzTextRole.body,
                              color: context.gz.colors.textStrong,
                              figures: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: GzSpace.s3),
                      GzFactRow(
                        label: '$typeName, ${lg.commonLabelKuwaitTime}',
                        children: [
                          GzFactChip(
                            icon: meeting.channel == 'phone' ? GzIcons.phone : GzIcons.video,
                            label: '$typeName, ${lg.commonLabelKuwaitTime}',
                            small: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: GzSpace.s3),
                      Row(
                        children: [
                          GzIconButton(
                            icon: GzIcons.calendarPlus,
                            variant: GzIconButtonVariant.outline,
                            label: l.clientPlannerStatusAddToCalendar,
                            onPressed: () => nav.toast(GzToastSpec(message: l.clientPlannerStatusCalendarToast, tone: GzToastTone.success)),
                          ),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(
                            child: GzButton(
                              label: lg.commonActionReschedule,
                              variant: GzButtonVariant.tertiary,
                              onPressed: offline ? null : () => nav.openSheet('CL-PLAN-04'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (!assigned) ...[
            const SizedBox(height: GzSpace.s4),
            Builder(
              builder: (context) {
                final pkgs = ref.watch(plannerPackagesProvider).value ?? const [];
                final summary = pkgs.where((p) => p.tier == tier).firstOrNull ?? pkgs.firstOrNull;
                if (summary == null) return const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96);
                return PlannerRequestSummary(pkg: summary, venueId: request?.venueId ?? 'V01', date: request?.eventDate ?? LocalDate(2027, 1, 14));
              },
            ),
            const SizedBox(height: GzSpace.s4),
            Row(
              children: [
                Expanded(
                  child: GzButton(
                    key: const ValueKey<String>('planner.status.edit'),
                    label: lg.commonActionEdit,
                    variant: GzButtonVariant.secondary,
                    iconStart: GzIcons.edit,
                    onPressed: () => nav.push('CL-PLAN-02', params: <String, Object?>{'tier': tier.value, 'edit': true}),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(
                    key: const ValueKey<String>('planner.status.cancel'),
                    label: lg.commonActionCancel,
                    variant: GzButtonVariant.destructive,
                    iconStart: GzIcons.close,
                    onPressed: offline ? null : () => _cancel(context, ref),
                  ),
                ),
              ],
            ),
          ],
          if (assigned && !scheduled) ...[
            const SizedBox(height: GzSpace.s4),
            const GzEmptyState(key: ValueKey<String>('planner.status.next'), illustration: GzIllustrationName.emptyBookings, fill: false),
          ],
          const SizedBox(height: GzSpace.s6),
        ],
      ),
    );
  }

  String _statusOf(PlannerRequest? request, String? frame) {
    if (frame == 'requested') return 'requested';
    if (frame == 'assigned') return 'assigned';
    if (frame == 'scheduled' || frame == 'today') return 'meeting_scheduled';
    return switch (request?.status.value) {
      'assigned' => 'assigned',
      'meeting_scheduled' => 'meeting_scheduled',
      _ => 'requested',
    };
  }

  void _message(BuildContext context, WidgetRef ref) {
    final request = ref.read(currentPlannerRequestProvider).value;
    final plannerId = request?.plannerId ?? 'planner-nouf';
    final userId = ref.read(clientUserIdProvider) ?? 'user-reem';
    context.gzNav.push('CL-MSGS-02', params: <String, Object?>{'conversationId': 'conv-planner-$plannerId-$userId'});
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final nav = context.gzNav;
    final answer = await nav.openDialog(
      GzDialogSpec(
        title: l.clientPlannerStatusCancelTitle,
        body: l.clientPlannerStatusCancelBody,
        confirmLabel: l.clientPlannerStatusCancelConfirm,
        cancelLabel: l.clientPlannerStatusCancelKeep,
        tone: GzDialogTone.destructive,
      ),
    );
    if (answer != GzDialogResult.confirm) return;
    // No cancel endpoint exists in the contract yet (see requests.md): the
    // screen drops the local draft and returns to the packages.
    ref.read(plannerWindowsProvider.notifier).clear();
    ref.read(plannerNoteProvider.notifier).set('');
    nav.toast(GzToastSpec(message: l.clientPlannerStatusCancelledToast));
    nav.replace('CL-PLAN-01');
  }
}
