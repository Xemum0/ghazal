import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate, plannersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DayPart, LocalDate, PlannerRequestInput, PlannerTier, TimeWindow;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/planner_data.dart';
import 'widgets/plan_request_parts.dart';
import 'widgets/planner_day_grid.dart';
import 'widgets/planner_parts.dart';

const List<DayPart> _parts = [DayPart.morning, DayPart.afternoon, DayPart.evening];

/// CL-PLAN-02 Request consultation (screen). Covers CA-PLAN-05, CA-PLAN-04, CA-AUTH-10.
///
/// The package as one tappable row (Change is its chevron), the wedding as two
/// facts, up to three time windows picked on a two-week calendar, how to be
/// reached as three glyphs, optional notes. Send is a hard gate: a guest meets
/// the sign-in sheet, and the request resumes with everything typed. An open
/// request is never duplicated: the screen shows where it stands instead.
/// States: default, validation-error, sending, success, error, offline,
/// guest-gate, open-request-exists.
class ClPlan02Screen extends ConsumerStatefulWidget {
  const ClPlan02Screen({super.key});

  @override
  ConsumerState<ClPlan02Screen> createState() => _ClPlan02ScreenState();
}

class _ClPlan02ScreenState extends ConsumerState<ClPlan02Screen> {
  bool _seeded = false;
  bool _attempted = false;
  bool _sending = false;
  bool _sent = false;
  LocalDate? _day;

  GzNavigator get _nav => context.gzNav;

  bool get _editing => _nav.params['edit'] == true || _nav.params['edit'] == 'true';

  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final params = _nav.params;
    final tierParam = params['tier'];
    final tier = tierParam is String ? PlannerTier.values.where((t) => t.value == tierParam).firstOrNull : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (tier != null && tier != PlannerTier.unknown) ref.read(plannerTierProvider.notifier).set(tier);
      if (_editing) {
        final current = ref.read(currentPlannerRequestProvider).value;
        if (current != null) {
          ref.read(plannerTierProvider.notifier).set(current.tier);
          ref.read(plannerWindowsProvider.notifier).replace({for (final w in current.windows) planWindowKey(w.date, w.part_)});
          ref.read(plannerNoteProvider.notifier).set(current.note);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _seed();
    final l = context.l10n;
    final lg = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final f = context.gzFormat;
    final tier = ref.watch(plannerTierProvider);
    final windows = ref.watch(plannerWindowsProvider);
    final reach = ref.watch(plannerReachProvider);
    final note = ref.watch(plannerNoteProvider);
    final pkgsAsync = ref.watch(plannerPackagesProvider);
    final currentAsync = ref.watch(currentPlannerRequestProvider);
    final problem = currentAsync.hasError && !currentAsync.hasValue
        ? (currentAsync.error is ApiProblem ? currentAsync.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown))
        : null;
    final offline = problem?.isOffline ?? false;
    final pkgs = (pkgsAsync.value ?? const []).where((p) => p.tier != PlannerTier.unknown).toList();
    final pkg = pkgs.where((p) => p.tier == tier).firstOrNull ?? pkgs.firstOrNull;
    final current = currentAsync.value;
    final brief = ref.watch(searchBriefProvider);
    final venueId = current?.venueId ?? 'V01';
    final eventDate = current?.eventDate ?? brief.date ?? LocalDate(2027, 1, 14);
    final days = plannerDays(ref.watch(clockProvider)());
    final LocalDate? activeDay = (_day != null && days.contains(_day)) ? _day : _derivedDay(days, windows);
    final activeParts = {for (final w in windows) parsePlanWindow(w)}.where((w) => w.$1 == activeDay).map((w) => w.$2).toSet();
    final showWindowError = (_attempted && windows.isEmpty);
    final guest = ref.watch(clientUserIdProvider) == null;

    if (_sent) {
      return GzScreen(
        top: GzTopBar(title: l.clientPlannerRequestTitle, back: GzTopBarBack.hide),
        child: GzSuccessState(
          key: const ValueKey<String>('planner.sent'),
          illustration: GzIllustrationName.successRequest,
          title: l.clientPlannerRequestSuccessTitle,
          action: GzStateAction(label: l.clientPlannerViewRequest, variant: GzButtonVariant.primary, onPressed: _toStatus),
        ),
      );
    }

    if (current != null && !_editing && current.status.value != 'meeting_scheduled') {
      return GzScreen(
        top: GzTopBar(title: l.clientPlannerRequestTitle),
        child: GzEmptyState(
          key: const ValueKey<String>('planner.open'),
          illustration: GzIllustrationName.emptyBookings,
          title: l.clientPlannerRequestOpenTitle,
          action: GzStateAction(label: l.clientPlannerViewRequest, variant: GzButtonVariant.primary, onPressed: () => _nav.replace('CL-PLAN-03')),
        ),
      );
    }

    return GzScreen(
      top: GzTopBar(title: l.clientPlannerRequestTitle),
      bottom: GzActionBar(
        action: GzActionBarAction(
          label: guest ? l.clientPlannerGuestSignIn : l.clientPlannerRequestSend,
          loading: _sending,
          onPressed: (offline || _sending || pkg == null) ? null : () => _send(pkg.tier, venueId, eventDate),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) GzBanner(message: lg.commonStateOffline, tone: GzBannerTone.offline),
          if (problem != null && !offline)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
              child: GzBanner(
                message: lg.commonStateTitleGeneric,
                tone: GzBannerTone.danger,
                actionLabel: lg.commonActionRetry,
                onAction: () => ref.invalidate(currentPlannerRequestProvider),
              ),
            ),
          if (pkg != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                child: GzPressable(
                  key: const ValueKey<String>('planner.package'),
                  onPressed: _sending ? null : () => _openPicker(pkgs.map((p) => p.tier).toList()),
                  semanticLabel: '${l.clientPlannerRequestChange}: ${pkg.name.of(lang)}',
                  minWidth: 0,
                  child: Container(
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
                            child: SizedBox.square(
                              dimension: GzSize.thumbLg,
                              child: GzPhoto(src: tierPhotoSrc(pkg.tier), alt: '', borderRadius: GzRadius.smAll),
                            ),
                          ),
                          const SizedBox(width: GzSpace.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: GzText(pkg.name.of(lang), role: GzTextRole.d1, color: context.gz.colors.textStrong),
                                    ),
                                    const SizedBox(width: GzSpace.s2),
                                    TierMarks(count: pkg.marks, label: l.clientPlannerMarks(pkg.marks)),
                                  ],
                                ),
                                const SizedBox(height: GzSpace.s2),
                                PlanPackageFacts(venueId: venueId, date: eventDate),
                              ],
                            ),
                          ),
                          const SizedBox(width: GzSpace.s3),
                          const GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, tone: GzIconTone.secondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Row(
              children: [
                Expanded(
                  child: GzText(l.clientPlannerRequestTimesTitle, role: GzTextRole.title, color: context.gz.colors.textStrong),
                ),
                GzLtr(
                  child: GzText(
                    '${f.integer(windows.length)}/${f.integer(3)}',
                    role: GzTextRole.caption,
                    color: windows.length >= 3 ? context.gz.colors.textGoldInk : context.gz.colors.textSecondary,
                    figures: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: PlannerDayGrid(
              days: days,
              value: activeDay,
              onPick: (d) => setState(() => _day = d),
              name: l.clientPlannerRequestDayLabel,
              labelOf: (day) {
                final count = windows.where((w) => parsePlanWindow(w).$1 == day).length;
                final label = f.date(day.toString(), DateStyle.short);
                return count > 0 ? l.clientPlannerRequestDayWithChoices(label, count) : label;
              },
              marksFor: (day) => [
                for (final part in _parts)
                  if (windows.contains(planWindowKey(day, part))) kPlanPartGlyph[part],
              ],
              enabledFor: (_) => !_sending,
              disabled: _sending,
              aside: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GzIcon(GzIcons.clock, size: GzIconSize.xs, tone: GzIconTone.secondary),
                  const SizedBox(width: GzSpace.s1),
                  GzText(lg.commonLabelKuwaitTime, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Semantics(
              container: true,
              label: l.clientPlannerRequestWindowLabel(f.date((activeDay ?? days.first).toString(), DateStyle.short)),
              child: Row(
                children: [
                  for (final part in _parts) ...[
                    if (part != _parts.first) const SizedBox(width: GzSpace.s2),
                    Expanded(
                      child: PlanPartButton(
                        part: part,
                        on: activeParts.contains(part),
                        disabled: _sending || (windows.length >= 3 && !activeParts.contains(part)),
                        onTap: activeDay == null ? null : () => _toggle(activeDay, part),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showWindowError)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, tone: GzIconTone.danger),
                  const SizedBox(width: GzSpace.s2),
                  GzText(l.clientPlannerRequestWindowsError, role: GzTextRole.bodyS, color: context.gz.colors.textDanger),
                ],
              ),
            ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzIconSegmented<PlannerReach>(
              label: l.clientPlannerRequestReachLabel,
              value: reach,
              options: [
                GzIconSegmentedOption(value: PlannerReach.chat, icon: GzIcons.chat, label: l.clientPlannerRequestReachChat),
                GzIconSegmentedOption(value: PlannerReach.whatsapp, icon: GzIcons.whatsapp, label: l.clientPlannerRequestReachWhatsapp),
                GzIconSegmentedOption(value: PlannerReach.phone, icon: GzIcons.phone, label: l.clientPlannerRequestReachPhone),
              ],
              onChanged: _sending ? null : (v) => ref.read(plannerReachProvider.notifier).set(v),
            ),
          ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzTextArea(
              key: const ValueKey<String>('planner.notes'),
              label: l.clientPlannerRequestNotesLabel,
              optional: true,
              value: note,
              rows: 3,
              disabled: _sending,
              onValueChange: (v) => ref.read(plannerNoteProvider.notifier).set(v),
            ),
          ),
          const SizedBox(height: GzSpace.s6),
        ],
      ),
    );
  }

  LocalDate? _derivedDay(List<LocalDate> days, Set<String> windows) {
    for (final w in windows) {
      final day = parsePlanWindow(w).$1;
      if (days.contains(day)) return day;
    }
    return days.firstOrNull;
  }

  void _toggle(LocalDate day, DayPart part) {
    final ok = ref.read(plannerWindowsProvider.notifier).toggle(planWindowKey(day, part));
    if (!ok && mounted) _nav.toast(GzToastSpec(message: context.l10n.clientPlannerRequestWindowsError));
  }

  void _openPicker(List<PlannerTier> tiers) {
    _nav.openSheetBuilder((_) => PlanPackagePicker(tiers: tiers));
  }

  Future<void> _send(PlannerTier tier, String venueId, LocalDate eventDate) async {
    setState(() => _attempted = true);
    final windows = ref.read(plannerWindowsProvider);
    if (windows.isEmpty) return;
    final params = <String, Object?>{'tier': tier.value};
    if (_editing) params['edit'] = true;
    // A guest meets the account sheet ('CL-AUTH-01', opened by requireSignIn)
    // and resumes here with everything typed; system back returns to 'CL-PLAN-01'.
    if (!ref.requireSignIn(GateReason.planner, resume: GateResume('CL-PLAN-02', params))) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(plannersRepositoryProvider);
      await repo.createPlannerRequest(
        body: PlannerRequestInput(
          tier: tier,
          venueId: venueId,
          eventDate: eventDate,
          windows: [
            for (final w in windows)
              ...(() {
                final p = parsePlanWindow(w);
                return [TimeWindow(date: p.$1, part_: p.$2)];
              })(),
          ],
          note: ref.read(plannerNoteProvider),
        ),
      );
      ref.read(clientDataRevisionProvider.notifier).bump();
      ref.invalidate(currentPlannerRequestProvider);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on ApiProblem catch (problem) {
      if (!mounted) return;
      setState(() => _sending = false);
      _nav.toast(
        GzToastSpec(message: problem.isOffline ? context.gzL10n.commonStateOffline : context.l10n.clientPlannerRetryToast, tone: GzToastTone.danger),
      );
    }
  }

  void _toStatus() {
    _nav.toast(GzToastSpec(message: context.l10n.clientPlannerRequestSentToast, tone: GzToastTone.success));
    _nav.replace('CL-PLAN-03', params: const <String, Object?>{'justSent': true});
  }
}
