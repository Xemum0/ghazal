import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage, plannersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, LocalTime, MeetingInput, PlannerRequest;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/planner_data.dart';
import 'widgets/planner_day_grid.dart';

/// CL-PLAN-04 Schedule a meeting (sheet). Covers CA-PLAN-06.
///
/// A Sunday-first two-week calendar (only days with free times can be chosen,
/// a gold bead marks them), the 30-minute slots of the chosen day (taken slots
/// are hidden, not greyed), Video or Call as two glyphs, and one gold Confirm.
/// Kuwait time sits on the month line. Confirming ties the third knot of the
/// request thread and drops the meeting card into the planner chat. The
/// confirmation is one drawing, "Meeting set", the date, the time and the call
/// type as three facts, Done and Calendar. States: default, loading-slots,
/// no-slots, confirming, success, slot-taken, offline-disabled.
class ClPlan04Screen extends ConsumerStatefulWidget {
  const ClPlan04Screen({super.key});

  @override
  ConsumerState<ClPlan04Screen> createState() => _ClPlan04ScreenState();
}

/// Closing the sheet (scrim, drag, Done) reveals 'CL-PLAN-03' underneath; the
/// meeting card there refetches through clientDataRevisionProvider.
class _ClPlan04ScreenState extends ConsumerState<ClPlan04Screen> {
  LocalDate? _day;
  LocalTime? _time;
  bool _video = true;
  bool _confirming = false;
  bool _done = false;

  GzNavigator get _nav => context.gzNav;

  String? get _frame {
    final v = _nav.params['frame'];
    return v is String ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final c = context.gz.colors;
    final nav = _nav;
    final async = ref.watch(currentPlannerRequestProvider);
    final problem = async.hasError && !async.hasValue
        ? (async.error is ApiProblem ? async.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown))
        : null;
    final offline = (problem?.isOffline ?? false) || _frame == 'offline';
    if (problem != null && !offline) {
      return Column(
        key: const ValueKey<String>('planner.meeting'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzSheetPinnedHeader(
            child: GzSheetHeader(title: l.clientPlannerMeetingTitle, onClose: nav.closeSheet),
          ),
          GzErrorState(
            key: const ValueKey<String>('planner.meeting.error'),
            kind: gzProblemKind(problem),
            body: gzProblemMessage(lg, problem),
            fill: false,
            onRetry: () => ref.invalidate(currentPlannerRequestProvider),
          ),
        ],
      );
    }
    if (async.isLoading && !async.hasValue && _frame != 'no-slots') {
      return Column(
        key: const ValueKey<String>('planner.meeting'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzSheetPinnedHeader(
            child: GzSheetHeader(title: l.clientPlannerMeetingTitle, onClose: nav.closeSheet),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: GzSpace.s4),
            child: Column(
              children: [
                GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
                SizedBox(height: GzSpace.s3),
                GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 44),
              ],
            ),
          ),
        ],
      );
    }
    final request = async.value;
    if (_done && request?.meeting != null) return _success(context, request!);

    final slots = _slotsOf(request);
    // The full fortnight stays on screen; only days with free times can be
    // chosen (a day with nothing to offer is disabled, never greyed away).
    final days = plannerDays(ref.watch(clockProvider)());
    final noSlots = _frame == 'no-slots' || slots.isEmpty;
    var day = _day;
    if (day == null || !slots.any((s) => s.$1 == day)) day = slots.firstOrNull?.$1;
    final times = day == null ? const <LocalTime>[] : slots.where((s) => s.$1 == day).firstOrNull?.$2 ?? const <LocalTime>[];
    var chosen = _time != null && times.contains(_time) ? _time : null;
    // The frame opens on the story's slot: an existing meeting pre-picks its
    // day and time until the family picks another (the web player's live
    // behaviour; the taken frame took that slot, so it stays unpicked).
    final existing = request?.meeting;
    if (chosen == null && _day == null && _time == null && existing != null) {
      final civil = context.gzFormat.civil(existing.at);
      final atDay = LocalDate(civil.year, civil.month, civil.day);
      final atTime = LocalTime(civil.hour, civil.minute);
      if (slots.any((s) => s.$1 == atDay && s.$2.contains(atTime))) {
        day = atDay;
        chosen = atTime;
      }
    }

    if (noSlots) {
      return Column(
        key: const ValueKey<String>('planner.meeting'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzSheetPinnedHeader(
            child: GzSheetHeader(title: l.clientPlannerMeetingTitle, onClose: nav.closeSheet),
          ),
          GzEmptyState(
            key: const ValueKey<String>('planner.meeting.empty'),
            illustration: GzIllustrationName.emptyBookings,
            title: l.clientPlannerMeetingNoSlotsTitle,
            fill: false,
            action: GzStateAction(
              label: lg.commonActionMessage,
              variant: GzButtonVariant.primary,
              onPressed: () {
                nav.closeSheet();
                nav.push('CL-MSGS-02', params: <String, Object?>{'conversationId': _conversationOf(ref, request)});
              },
            ),
          ),
        ],
      );
    }

    final confirmDay = day;
    final confirmTime = chosen;
    final requestId = request?.id;
    return Column(
      key: const ValueKey<String>('planner.meeting'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GzSpace.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.controlMd),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: GzAvatar(name: _plannerName(ref, request, context), size: GzAvatarSize.sm),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(l.clientPlannerMeetingTitle, role: GzTextRole.d1, color: c.textStrong, header: true),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzBarButton(icon: GzIcons.close, label: lg.commonActionClose, onPressed: nav.closeSheet),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: GzSpace.s5),
        if (offline)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s5),
            child: Row(
              children: [
                const GzIcon(GzIcons.offline, size: GzIconSize.sm, tone: GzIconTone.secondary),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(lg.commonStateOffline, role: GzTextRole.bodyS, color: c.textSecondary),
                ),
              ],
            ),
          ),
        PlannerDayGrid(
          days: days,
          value: day,
          onPick: (d) => setState(() {
            _day = d;
            _time = null;
          }),
          name: l.clientPlannerMeetingDayLabel,
          labelOf: (d) {
            final label = context.gzFormat.date(d.toString(), DateStyle.short);
            return slots.any((s) => s.$1 == d) ? label : l.clientPlannerMeetingDayNoSlots(label);
          },
          enabledFor: (d) => slots.any((s) => s.$1 == d),
          marksFor: (d) => [if (d != day && slots.any((s) => s.$1 == d)) null],
          disabled: _confirming,
          aside: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GzIcon(GzIcons.clock, size: GzIconSize.xs, tone: GzIconTone.secondary),
              const SizedBox(width: GzSpace.s1),
              GzText(lg.commonLabelKuwaitTime, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s5),
        if (_frame == 'taken')
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: Row(
              children: [
                const GzIcon(GzIcons.info, size: GzIconSize.sm, tone: GzIconTone.secondary),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(l.clientPlannerMeetingTaken, role: GzTextRole.bodyS, color: c.textSecondary),
                ),
              ],
            ),
          ),
        Semantics(
          container: true,
          label: l.clientPlannerMeetingTimeLabel,
          child: GzChipGroup<LocalTime>(
            key: const ValueKey<String>('planner.meeting.times'),
            label: l.clientPlannerMeetingTimeLabel,
            options: [for (final t in times) GzChipOption<LocalTime>(value: t, label: _timeLabel(context, day!, t))],
            value: chosen,
            onChanged: (_confirming || offline) ? null : (v) => setState(() => _time = v),
          ),
        ),
        const SizedBox(height: GzSpace.s5),
        GzIconSegmented<bool>(
          label: l.clientPlannerMeetingTypeLabel,
          value: _video,
          options: [
            GzIconSegmentedOption(value: true, icon: GzIcons.video, label: l.clientPlannerTypeVideo),
            GzIconSegmentedOption(value: false, icon: GzIcons.phone, label: l.clientPlannerTypePhone),
          ],
          onChanged: (_confirming || offline) ? null : (v) => setState(() => _video = v),
        ),
        const SizedBox(height: GzSpace.s5),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: GzButton(
              key: const ValueKey<String>('planner.meeting.confirm'),
              label: l.clientPlannerMeetingConfirm,
              variant: GzButtonVariant.primary,
              fullWidth: true,
              loading: _confirming,
              onPressed: (confirmDay == null || confirmTime == null || requestId == null || _confirming || offline)
                  ? null
                  : () => _confirm(requestId, confirmDay, confirmTime),
            ),
          ),
        ),
      ],
    );
  }

  /// (day, times) with the story time removed on the slot-taken frame.
  List<(LocalDate, List<LocalTime>)> _slotsOf(PlannerRequest? request) {
    final raw = request?.slots ?? const [];
    if (raw.isEmpty) return const [];
    final taken = _frame == 'taken' ? request?.meeting?.at : null;
    return [
      for (final s in raw)
        (
          s.date,
          [
            for (final t in s.times)
              if (taken == null ||
                  !(taken.year == s.date.year &&
                      taken.month == s.date.month &&
                      taken.day == s.date.day &&
                      taken.hour == t.hour &&
                      taken.minute == t.minute))
                t,
          ],
        ),
    ];
  }

  String _timeLabel(BuildContext context, LocalDate day, LocalTime t) {
    final at = DateTime.utc(day.year, day.month, day.day, t.hour - 3, t.minute);
    return context.gzFormat.time(at);
  }

  String _plannerName(WidgetRef ref, PlannerRequest? request, BuildContext context) {
    final detail = request?.plannerId == null ? null : ref.watch(plannerDetailProvider(request!.plannerId!)).value;
    final lang = context.gz.locale.languageCode;
    return detail?.planner.name.of(lang) ?? (lang == 'ar' ? 'نوف العتيبي' : 'Nouf Al-Otaibi');
  }

  String _conversationOf(WidgetRef ref, PlannerRequest? request) {
    final plannerId = request?.plannerId ?? 'planner-nouf';
    final userId = ref.read(clientUserIdProvider) ?? 'user-reem';
    return 'conv-planner-$plannerId-$userId';
  }

  Future<void> _confirm(String requestId, LocalDate day, LocalTime time) async {
    setState(() => _confirming = true);
    try {
      await ref
          .read(plannersRepositoryProvider)
          .schedulePlannerMeeting(
            requestId: requestId,
            body: MeetingInput(date: day, time: time),
          );
      ref.read(clientDataRevisionProvider.notifier).bump();
      ref.invalidate(currentPlannerRequestProvider);
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _done = true;
      });
    } on ApiProblem catch (problem) {
      if (!mounted) return;
      setState(() => _confirming = false);
      _nav.toast(
        GzToastSpec(message: problem.isOffline ? context.gzL10n.commonStateOffline : context.l10n.clientPlannerRetryToast, tone: GzToastTone.danger),
      );
    }
  }

  Widget _success(BuildContext context, PlannerRequest request) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final nav = _nav;
    final at = request.meeting!.at;
    final typeName = _video ? l.clientPlannerTypeVideoName : l.clientPlannerTypePhoneName;
    final f = context.gzFormat;
    return Column(
      key: const ValueKey<String>('planner.meeting.done'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSuccessState(illustration: GzIllustrationName.successVisit, title: l.clientPlannerMeetingSuccessTitle),
        const SizedBox(height: GzSpace.s3),
        GzFactRow(
          label: l.clientPlannerMeetingTitle,
          children: [
            GzFactChip(
              icon: GzIcons.calendar,
              label: l.clientPlannerMeetingDayLabel,
              valueWidget: gzFigText(context, f.date(at, DateStyle.short), role: GzTextRole.figBodyS),
            ),
            GzFactChip(
              icon: GzIcons.clock,
              label: l.clientPlannerMeetingTimeLabel,
              valueWidget: gzFigText(context, f.time(at), role: GzTextRole.figBodyS),
            ),
            GzFactChip(icon: _video ? GzIcons.video : GzIcons.phone, label: '$typeName, ${lg.commonLabelKuwaitTime}'),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            Expanded(
              child: GzButton(label: lg.commonActionDone, variant: GzButtonVariant.primary, onPressed: nav.closeSheet),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzButton(
                label: l.clientPlannerMeetingCalendar,
                variant: GzButtonVariant.tertiary,
                iconStart: GzIcons.calendarPlus,
                onPressed: () => nav.toast(GzToastSpec(message: l.clientPlannerStatusCalendarToast, tone: GzToastTone.success)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
