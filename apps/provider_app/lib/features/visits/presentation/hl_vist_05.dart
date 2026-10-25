// HL-VIST-05 Visit availability (web `HL-VIST-05.tsx`): when couples can request a visit: a master switch ("Accept visits"; off hides Book a visit on
// the client venue page), seven weekday rows Sunday first (open switch, from and to through a 12-hour time sheet), the window length, the default
// representative and blackout dates. Drives the slots of the client's visit sheet. Admin and Manager only. Pinned Save, a guard against leaving
// unsaved. Requirements: HA-VIS-05, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerVisitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalTime, StaffMember, VisitAvailability;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/availability_draft.dart';
import '../application/visits_data.dart';
import 'widgets/visit_day_row.dart';
import 'widgets/visit_sheets.dart';
import 'widgets/visits_bits.dart';

class HlVist05Screen extends ConsumerStatefulWidget {
  const HlVist05Screen({super.key});

  @override
  ConsumerState<HlVist05Screen> createState() => _HlVist05ScreenState();
}

class _HlVist05ScreenState extends ConsumerState<HlVist05Screen> {
  AvailabilityDraft? _saved;
  AvailabilityDraft? _draft;
  bool _busy = false;
  int _blackoutSeq = 0;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  void _seed(VisitAvailability a) {
    if (_saved != null) return;
    _saved = _draft = AvailabilityDraft.fromApi(a);
  }

  bool get _dirty => _draft != _saved;

  void _edit(AvailabilityDraft Function(AvailabilityDraft d) f) => setState(() => _draft = f(_draft!));

  Future<void> _back() async {
    if (!_dirty) {
      _nav.pop();
      return;
    }
    final l = context.l10n;
    final r = await _nav.openDialog(
      GzDialogSpec(
        title: l.hotelVisitsGuardTitle,
        body: l.hotelVisitsGuardBody,
        icon: GzIcons.warningCircle,
        confirmLabel: l.hotelVisitsGuardLeave,
        cancelLabel: l.hotelVisitsGuardStay,
        tone: GzDialogTone.destructive,
      ),
    );
    if (r == GzDialogResult.confirm) _nav.pop();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final gzL = context.gzL10n;
    final d = _draft!;
    setState(() => _busy = true);
    final p = await visitWrite(() => ref.read(partnerVisitsRepositoryProvider).putVisitAvailability(body: d.toApi()));
    if (!mounted) return;
    setState(() => _busy = false);
    if (p != null) {
      _nav.toast(GzToastSpec(message: gzProblemMessage(gzL, p), tone: GzToastTone.danger));
      return;
    }
    setState(() => _saved = d);
    ref.read(partnerDataRevisionProvider.notifier).bump();
    _nav.toast(GzToastSpec(message: l.hotelVisitsSaved, tone: GzToastTone.success, icon: GzIcons.checkCircle));
  }

  void _pickTime(int day, bool from) {
    final l = context.l10n;
    final f = context.gzFormat;
    final w = _draft!.week[day]!;
    final initial = from ? w.from : w.to;
    LocalTime value = initial;
    _nav.openSheetBuilder(
      (_) => StatefulBuilder(
        builder: (context, set) => VisitSheetShell(
          title: from ? l.hotelVisitsTimeFrom : l.hotelVisitsTimeTo,
          footer: GzButton(
            label: l.hotelVisitsTimeSet,
            size: GzButtonSize.cta,
            fullWidth: true,
            spill: true,
            onPressed: () {
              _edit((d) => d.withDay(day, from ? d.week[day]!.copyWith(from: value) : d.week[day]!.copyWith(to: value)));
              _nav.closeSheet();
            },
          ),
          children: [
            GzChipGroup<LocalTime>(
              label: from ? l.hotelVisitsTimeFrom : l.hotelVisitsTimeTo,
              value: value,
              onChanged: (v) {
                if (v != null) set(() => value = v);
              },
              options: [
                for (final t in timeChoices(initial))
                  GzChipOption<LocalTime>(
                    value: t,
                    label: f.time(f.kuwaitDate(2026, 11, 15, hour: t.hour, minute: t.minute)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addBlackout() {
    final l = context.l10n;
    GzDateRange range = GzDateRange.empty;
    _nav.openSheetBuilder(
      (_) => StatefulBuilder(
        builder: (context, set) => VisitSheetShell(
          title: l.hotelVisitsBlackoutTitle,
          footer: GzButton(
            label: l.hotelVisitsBlackoutAdd,
            size: GzButtonSize.cta,
            fullWidth: true,
            spill: true,
            reason: range.start == null ? l.hotelVisitsBlackoutNeed : null,
            onPressed: range.start == null
                ? null
                : () {
                    final start = range.start!;
                    _blackoutSeq++;
                    _edit(
                      (d) => d.copyWith(
                        blackouts: [
                          ...d.blackouts,
                          Blackout(id: 'blackout-$_blackoutSeq', from: start, to: range.end ?? start),
                        ],
                      ),
                    );
                    _nav.closeSheet();
                  },
          ),
          children: [GzCalendar.range(value: range, onChanged: (r) => set(() => range = r), legend: false, label: l.hotelVisitsBlackoutTitle)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final role = ref.watch(visitRoleProvider);
    final value = ref.watch(visitAvailabilityProvider);
    final lead = isVisitLead(role);
    value.whenData(_seed);
    final d = _draft;
    final mistakes = d == null ? const <DayMistake?>[] : [for (final k in kWeekDays) mistakeOf(d.week[k]!)];
    final invalid = d != null && d.on && mistakes.any((m) => m != null);
    final staff = ref.watch(visitStaffProvider).value ?? const <StaffMember>[];
    final rep = d?.repId == null ? null : staff.where((s) => s.userId == d!.repId).firstOrNull;
    final repName = rep == null ? '' : (lang == 'ar' ? rep.name : rep.nameLatin);
    String range(Blackout b) => b.from == b.to
        ? f.date(b.from, DateStyle.short)
        : l.hotelVisitsBlackoutRange(f.date(b.from, DateStyle.dayMonth), f.date(b.to, DateStyle.short));

    Widget body() {
      if (!lead) return GzErrorState(kind: GzErrorKind.noAccess, title: l.hotelVisitsAvailHiddenTitle, body: l.hotelVisitsAvailHiddenBody);
      return GzAsyncView<VisitAvailability>(
        value: value,
        loading: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            children: [
              GzSkeleton(blockSize: 80),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(blockSize: 64),
            ],
          ),
        ),
        onRetry: () => ref.invalidate(visitAvailabilityProvider),
        data: (_) {
          final dr = _draft!;
          const gap = SizedBox(height: GzSpace.s6);
          return Padding(
            padding: const EdgeInsets.only(top: GzSpace.s2, bottom: GzSpace.s10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                  child: GzToggleRow(
                    title: l.hotelVisitsMasterTitle,
                    checked: dr.on,
                    onChanged: (v) => _edit((x) => x.copyWith(on: v)),
                    divider: false,
                  ),
                ),
                gap,
                if (!dr.on)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                    child: VisitNotice(icon: GzIcons.eyeOff, title: l.hotelVisitsOffTitle, text: l.hotelVisitsOffBody, rose: true),
                  )
                else ...[
                  VisitSection(
                    title: l.hotelVisitsSecDays,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < kWeekDays.length; i++)
                          VisitDayRow(
                            weekday: kWeekDays[i],
                            day: dr.week[kWeekDays[i]]!,
                            mistake: mistakes[i],
                            last: i == kWeekDays.length - 1,
                            onToggle: (open) => _edit((x) => x.withDay(kWeekDays[i], x.week[kWeekDays[i]]!.copyWith(open: open))),
                            onPickFrom: () => _pickTime(kWeekDays[i], true),
                            onPickTo: () => _pickTime(kWeekDays[i], false),
                          ),
                        const SizedBox(height: GzSpace.s2),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: GzButton(
                            label: l.hotelVisitsSeeBusinessHours,
                            variant: GzButtonVariant.tertiary,
                            iconStart: GzIcons.clock,
                            onPressed: () => _nav.push('HL-SETT-05'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap,
                  VisitSection(
                    title: l.hotelVisitsSecSlot,
                    child: GzChipGroup<String>(
                      label: l.hotelVisitsSecSlot,
                      value: '${dr.slotMinutes}',
                      onChanged: (v) {
                        if (v != null) _edit((x) => x.copyWith(slotMinutes: int.parse(v)));
                      },
                      options: [for (final m in kSlotChoices) GzChipOption<String>(value: '$m', label: l.hotelVisitsSlotChip(f.integer(m)))],
                    ),
                  ),
                  gap,
                  VisitSection(
                    title: l.hotelVisitsSecRepDefault,
                    child: GzListRow(
                      flush: true,
                      last: true,
                      title: rep == null ? l.hotelVisitsRepNone : repName,
                      subtitle: rep?.roleLabel.of(lang),
                      leading: rep == null
                          ? null
                          : GzAvatar(name: repName, initial: lang == 'ar' ? rep.monogram : null, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                      chevron: true,
                      autoDir: rep != null,
                      onPressed: () => _nav.openSheetBuilder(
                        (_) => RepSheet(
                          currentId: dr.repId ?? '',
                          onPick: (s) {
                            _edit((x) => x.copyWith(repId: s.userId));
                            _nav.closeSheet();
                          },
                        ),
                      ),
                    ),
                  ),
                  gap,
                  VisitSection(
                    title: l.hotelVisitsSecBlackouts,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final b in dr.blackouts)
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GzText(range(b), role: GzTextRole.body, color: c.textPrimary, figures: true),
                                ),
                                GzIconButton(
                                  icon: GzIcons.trash,
                                  label: l.hotelVisitsBlackoutRemove(f.plain(range(b))),
                                  onPressed: () => _edit((x) => x.copyWith(blackouts: x.blackouts.where((e) => e.id != b.id).toList())),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: GzSpace.s2),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: GzChip(label: l.hotelVisitsBlackoutsAdd, iconStart: GzIcons.plus, onPressed: _addBlackout),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    final showBar = lead && value.hasValue && d != null;
    final dirty = showBar && _dirty;
    return GzScreen(
      top: GzTopBar(title: l.hotelVisitsAvailTitle, onBack: dirty ? _back : null),
      bottom: showBar
          ? GzActionBar(
              action: GzActionBarAction(
                label: l.hotelVisitsSave,
                onPressed: _save,
                loading: _busy,
                disabled: invalid || !dirty,
                reason: invalid ? l.hotelVisitsSaveInvalid : (!dirty ? l.hotelVisitsSaveClean : null),
              ),
            )
          : null,
      child: body(),
    );
  }
}
