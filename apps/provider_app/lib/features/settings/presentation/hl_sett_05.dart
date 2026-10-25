// HL-SETT-05 Business hours (web `HL-SETT-05.tsx`): the hours the venue office is reachable, shown to couples, and the closures that apply; the same
// hours decide when a new-request alert makes a sound. A live "Shown to couples as" strip, seven rows starting with Sunday (the opening and the
// closing time as two buttons with an arrow between them, the open switch; a closing time before the opening time runs past midnight and shows
// +1, the same time on both ends is the one mistake), "All days" under the row being edited, closures (Ramadan and the Eids as approximate
// ranges), a pinned Save and a guard against leaving unsaved. Admin edits, Manager views, other roles do not see the screen. Kuwait time.
// Requirements: HA-SET-04, HA-AUTH-02.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerVenueRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show BusinessHours, HoursClosure, LocalDate, LocalizedText, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_data.dart';
import '../application/settings_model.dart';
import 'widgets/hours_parts.dart';
import 'widgets/pref_parts.dart';

class HlSett05Screen extends ConsumerStatefulWidget {
  const HlSett05Screen({super.key});

  @override
  ConsumerState<HlSett05Screen> createState() => _HlSett05ScreenState();
}

class _HlSett05ScreenState extends ConsumerState<HlSett05Screen> {
  List<DayHours>? _week;
  List<Closure> _closures = const [];
  List<DayHours> _savedWeek = const [];
  List<String> _savedIds = const [];
  int? _lastEdited;
  int _seq = 0;

  void _init(BusinessHours h) {
    if (_week != null) return;
    _week = weekFrom(h);
    _savedWeek = [..._week!];
    _closures = [for (var i = 0; i < h.closures.length; i++) (id: 'fixture-$i', en: h.closures[i].label.en ?? '', ar: h.closures[i].label.ar ?? '', from: h.closures[i].from, to: h.closures[i].to, approximate: h.closures[i].approximate)];
    _savedIds = [for (final c in _closures) c.id];
  }

  bool get _dirty => _week != null && (!sameWeek(_week!, _savedWeek) || _closures.length != _savedIds.length || _closures.indexed.any((e) => e.$2.id != _savedIds[e.$1]));
  bool get _invalid => _week != null && _week!.any(isInvalidDay);

  void _setDay(int d, {bool? open, String? from, String? to}) {
    final cur = _week![d];
    setState(() {
      _week = [for (var i = 0; i < 7; i++) i == d ? (open: open ?? cur.open, from: from ?? cur.from, to: to ?? cur.to) : _week![i]];
      _lastEdited = d;
    });
  }

  void _copyToAll(int d) => setState(() {
    final src = _week![d];
    _week = [for (var i = 0; i < 7; i++) (open: src.open, from: src.from, to: src.to)];
  });

  void _pick(int d, bool from) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final title = from ? l.hotelSettingsHoursTimeFrom : l.hotelSettingsHoursTimeTo;
    nav.openSheetBuilder(
      (_) => TimeContent(
        title: title,
        initial: from ? _week![d].from : _week![d].to,
        onSet: (v) {
          _setDay(d, from: from ? v : null, to: from ? null : v);
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: title),
    );
  }

  void _addClosure() {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => ClosureContent(
        onAdd: (label, from, to) {
          setState(() => _closures = [..._closures, (id: 'closure-local-${++_seq}', en: label, ar: label, from: LocalDate.parse(from), to: LocalDate.parse(to), approximate: false)]);
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelSettingsHoursAddTitle),
    );
  }

  Future<void> _save() async {
    final nav = GzNavigatorScope.of(context);
    final gzl = context.gzL10n;
    if (_invalid) return;
    final body = BusinessHours(
      rules: rulesFrom(_week!),
      closures: [for (final c in _closures) HoursClosure(label: LocalizedText(en: c.en.isEmpty ? null : c.en, ar: c.ar.isEmpty ? null : c.ar), from: c.from, to: c.to, approximate: c.approximate)],
    );
    final p = await attempt(() => ref.read(partnerVenueRepositoryProvider).putBusinessHours(body: body));
    if (!mounted) return;
    if (p != null) {
      nav.toast(GzToastSpec(message: p.code == ApiProblemCode.offline ? gzl.commonStateOffline : gzProblemMessage(gzl, p), tone: GzToastTone.danger, icon: GzIcons.offline));
      return;
    }
    setState(() {
      _savedWeek = [..._week!];
      _savedIds = [for (final c in _closures) c.id];
      _lastEdited = null;
    });
    nav.toast(GzToastSpec(message: gzl.commonStateSaved, tone: GzToastTone.success, icon: GzIcons.checkCircle));
  }

  Future<void> _guard() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    if (!_dirty) return nav.pop();
    final answer = await nav.openDialog(
      GzDialogSpec(title: l.hotelSettingsHoursGuardTitle, icon: GzIcons.warningCircle, confirmLabel: l.hotelSettingsHoursGuardLeave, cancelLabel: l.hotelSettingsHoursGuardStay, tone: GzDialogTone.destructive),
    );
    if (answer == GzDialogResult.confirm) nav.pop();
  }

  void _about(bool approx) {
    final l = context.l10n;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => AboutLines(lines: [(GzIcons.clock, l.hotelSettingsHoursAbout), (GzIcons.globe, context.gzL10n.commonLabelKuwaitTime), if (approx) (GzIcons.calendarX, l.hotelSettingsHoursApproxNote)]),
      options: GzSheetOptions(title: l.hotelSettingsHoursAboutTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final ctx = ref.watch(partnerContextProvider);
    final mode = ctx?.isProvider == true ? Level.none : accessOf(ctx?.role ?? StaffRole.manager).hours;
    final edit = mode == Level.edit;
    final value = ref.watch(businessHoursProvider);
    final suggestions = kSuggestedClosures.where((s) => !_closures.any((x) => x.id == s.id)).toList();

    String closureName(Closure x) {
      final t = lang == 'ar' ? x.ar : x.en;
      return t.isEmpty ? l.hotelSettingsHoursClosure : t;
    }

    String closureRange(Closure x) => x.from == x.to ? f.date(x.from.toString(), DateStyle.dayMonth) : l.hotelSettingsHoursClosureRange(f.date(x.from.toString(), DateStyle.dayMonth), f.date(x.to.toString(), DateStyle.dayMonth));

    Widget body(BusinessHours h) {
      _init(h);
      final week = _week!;
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: l.hotelSettingsHoursPreview,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(GzSpace.s4),
                      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(GzIcons.eye, size: GzIconSize.sm, color: c.iconSecondary)),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (i, line) in previewLines(l, f, week).indexed) ...[if (i > 0) const SizedBox(height: GzSpace.s1), GzText(line, color: c.textStrong, figures: true)],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!edit) ...[const SizedBox(height: GzSpace.s3), GzBadge(label: l.hotelSettingsHoursViewOnly, variant: GzBadgeVariant.quiet, bead: false, icon: GzIcons.lock)],
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            Semantics(
              container: true,
              label: l.hotelSettingsHoursWeek,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                child: Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      HoursDayRow(
                        key: ValueKey<String>('hours.day.$d'),
                        weekday: d,
                        day: week[d],
                        invalid: isInvalidDay(week[d]),
                        onOpenChange: edit ? (on) => _setDay(d, open: on) : null,
                        onPickFrom: edit ? () => _pick(d, true) : null,
                        onPickTo: edit ? () => _pick(d, false) : null,
                        onCopy: edit && _lastEdited == d && week[d].open ? () => _copyToAll(d) : null,
                        last: d == 6,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: GzSectionHeader(title: l.hotelSettingsHoursClosures, voice: GzHeaderVoice.partner)),
            const SizedBox(height: GzSpace.s2),
            for (final x in _closures)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                child: Container(
                  constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                  padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                  child: Row(
                    children: [
                      GzIcon(GzIcons.calendarX, size: GzIconSize.sm, color: c.iconSecondary),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GzUserText(closureName(x), role: GzTextRole.title, color: c.textStrong),
                            const SizedBox(height: GzSpace.s1),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: GzSpace.s3,
                              children: [
                                GzText(closureRange(x), role: GzTextRole.figBodyS, color: c.textSecondary, figures: true),
                                if (x.approximate) GzBadge(label: l.hotelSettingsHoursApprox, variant: GzBadgeVariant.quiet, bead: false),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (edit) GzIconButton(icon: GzIcons.trash, label: l.hotelSettingsHoursRemoveClosure(closureName(x)), onPressed: () => setState(() => _closures = _closures.where((e) => e.id != x.id).toList())),
                    ],
                  ),
                ),
              ),
            if (edit)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (suggestions.isNotEmpty)
                      Semantics(
                        container: true,
                        label: l.hotelSettingsHoursSuggested,
                        child: Wrap(
                          spacing: GzSpace.s2,
                          runSpacing: GzSpace.s2,
                          children: [for (final s in suggestions) GzChip(label: lang == 'ar' ? s.ar : s.en, iconStart: GzIcons.plus, onPressed: () => setState(() => _closures = [..._closures, s]))],
                        ),
                      ),
                    const SizedBox(height: GzSpace.s3),
                    GzButton(label: l.hotelSettingsHoursAddClosure, variant: GzButtonVariant.tertiary, iconStart: GzIcons.calendarPlus, onPressed: _addClosure),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final show = edit && value.hasValue;
    final hasApprox = _closures.any((x) => x.approximate);
    return GzScreen(
      top: GzTopBar(
        title: l.hotelSettingsMoreHours,
        onBack: _dirty ? _guard : null,
        actions: mode == Level.none ? const [] : [GzTopBarAction(icon: GzIcons.info, label: l.commonA11yInfo, onPressed: () => _about(hasApprox))],
      ),
      bottom: show ? GzActionBar(action: GzActionBarAction(label: l.hotelSettingsHoursSave, onPressed: _save, disabled: _invalid)) : null,
      child: mode == Level.none
          ? const GzErrorState(kind: GzErrorKind.noAccess)
          : GzAsyncView<BusinessHours>(value: value, loading: const _Skeleton(), onRetry: () => ref.invalidate(businessHoursProvider), data: body),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
            ],
          ),
        ),
      ),
    );
  }
}
