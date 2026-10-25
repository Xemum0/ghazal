// HL-GROW-03 Voucher price window, step 2 of 2 (web `HL-GROW-03.tsx`): the event dates the window covers and when it runs, then publish, with the client
// card still on screen (pinned under the step thread) and the request price a couple will see. Windows are dated; there are no usage limits per code and
// no coupon codes (ADR 0033 D4).
// Requirements: HA-OFFR-01, HA-OFFR-02, HA-OFFR-06, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/grow_data.dart';
import '../application/grow_model.dart';
import 'widgets/date_pick.dart';
import 'widgets/event_calendar.dart';
import 'widgets/grow_bits.dart';
import 'widgets/preview_parts.dart';

class HlGrow03Screen extends ConsumerStatefulWidget {
  const HlGrow03Screen({super.key});

  @override
  ConsumerState<HlGrow03Screen> createState() => _HlGrow03ScreenState();
}

class _HlGrow03ScreenState extends ConsumerState<HlGrow03Screen> {
  GzYm? _month;
  bool _failed = false;
  bool _seeded = false;

  /// Free dates of the next 60 days on the days the shortcut stands for.
  List<String> _shortcut(Shortcut k, String today, Map<String, Set<String>> busy) {
    final out = <String>[];
    for (var i = 0; i <= 60; i++) {
      final d = gzAddDaysIso(today, i);
      final wd = gzWeekdayOfIso(d);
      if ((k == Shortcut.weekdays) != (wd <= 3)) continue;
      if (busy[d.substring(0, 7)]?.contains(d) ?? false) continue;
      out.add(d);
    }
    return out;
  }

  Future<void> _publish(PackageCatalog cat, GrowDraft draft, String today, List<int> weekend, LocalizedText title) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final session = ref.read(growSessionProvider);
    final flat = bounds(cat, draft, LocalDate.parse(draft.eventDates.first), weekend).flat;
    final body = inputOf(draft, cat, LocalDate.parse(today), ref.read(clockProvider)(), title, flat);
    final res = await ref.read(growActionsProvider.notifier).publish(body);
    if (!mounted) return;
    res.when(
      success: (made) {
        setState(() => _failed = false);
        final origin = session.originList;
        ref.read(growSessionProvider.notifier)
          ..reset(emptyDraftFor(cat))
          ..highlight(made.id);
        nav.pop(count: 2);
        final shown = made.title.of(lang);
        nav.toast(
          GzToastSpec(
            message: made.status == VoucherWindowStatus.scheduled ? l.hotelGrowToastScheduled(shown) : l.hotelGrowToastPublished(shown),
            tone: GzToastTone.success,
            action: GzToastAction(
              label: l.hotelGrowView,
              onPressed: () {
                ref.read(growSessionProvider.notifier).requestOpen(made.id);
                if (!origin) nav.push('HL-GROW-01');
              },
            ),
          ),
        );
      },
      failure: (p) {
        setState(() => _failed = true);
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final cat = ref.watch(growCatalogProvider).value;
    final draft = ref.watch(growSessionProvider.select((s) => s.draft));
    final windows = ref.watch(growWindowsProvider).value ?? const <VoucherWindow>[];
    final soft = ref.watch(growSoftDatesProvider).value ?? const <String>[];
    final todayD = ref.watch(growTodayProvider);
    final today = todayD.toString();
    final weekend = ref.watch(growConfigProvider).value?.weekendTierDays ?? const [4, 5, 6];
    final busyMonths = <String, Set<String>>{};
    for (var i = 0; i < 3; i++) {
      final m = gzAddMonths(gzMonthOfIso(today), i);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      busyMonths[key] = ref.watch(growBusyProvider(key)).value ?? const <String>{};
    }
    final session = ref.read(growSessionProvider.notifier);
    if (!_seeded && cat != null) {
      _seeded = true;
      final d0 = ref.read(growSessionProvider).draft;
      if (d0.packageIds.isEmpty && d0.voucherKd.isEmpty && !d0.dirty) Future.microtask(() => mounted ? session.reset(emptyDraftFor(cat)) : null);
    }
    final saving = ref.watch(growActionsProvider).busy.contains('publish');
    final month = _month ?? gzMonthOfIso(draft.eventDates.isNotEmpty ? draft.eventDates.first : today);
    final top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTopBar(title: l.hotelGrowEditorTitle),
        const StepThread(step: 2),
        if (cat != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s3),
            child: PreviewStrip(compact: true, rate: draftFils(draft), packageIds: draft.packageIds, dates: draft.eventDates),
          ),
      ],
    );
    if (cat == null) {
      return GzScreen(
        top: top,
        child: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 320),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
            ],
          ),
        ),
      );
    }
    final rate = draftFils(draft);
    final openWeekends = _shortcut(Shortcut.openWeekends, today, busyMonths);
    final weekdays = _shortcut(Shortcut.weekdays, today, busyMonths);
    List<String> shortcutList(Shortcut k) => k == Shortcut.openWeekends ? openWeekends : weekdays;
    void setShortcut(Shortcut? k) => session.patch((d) => d.copyWith(shortcut: k, eventDates: k == null ? const [] : shortcutList(k)));
    void toggleDate(String iso) => session.patch((d) {
      final has = d.eventDates.contains(iso);
      final from = d.shortcut != null ? <String>[] : d.eventDates;
      return d.copyWith(
        shortcut: null,
        eventDates: has
            ? [
                for (final x in from)
                  if (x != iso) x,
              ]
            : ([...from, iso]..sort()),
      );
    });
    final startDate = draft.startsOn ?? today;
    final scheduled = draft.startsOn != null && draft.startsOn!.compareTo(today) > 0;
    final clashes = overlaps(windows, cat, draft, rate);
    final clash = clashes.firstOrNull;
    final noDates = draft.eventDates.isEmpty;
    final endBeforeStart = !draft.untilEnd && draft.endsOn != null && startDate.compareTo(draft.endsOn!) > 0;
    final noEnd = !draft.untilEnd && draft.endsOn == null;
    final blocked = noDates ? l.hotelGrowReasonDates : ((endBeforeStart || noEnd) ? l.hotelGrowReasonEnd : null);
    final showErrors = draft.dirty || draft.eventDates.isNotEmpty;
    final titles = suggestedTitles();
    final title = LocalizedText(
      en: (draft.titleTouched ? draft.titleEn : titles.en).trim(),
      ar: (draft.titleTouched ? draft.titleAr : titles.ar).trim(),
    );
    return GzScreen(
      top: top,
      bottom: GzActionBar(
        action: GzActionBarAction(
          label: _failed ? l.commonActionRetry : (scheduled ? l.hotelGrowSchedule : l.hotelGrowPublish),
          iconEnd: _failed ? GzIcons.refresh : (scheduled ? GzIcons.calendarCheck : GzIcons.check),
          loading: saving,
          disabled: !_failed && blocked != null,
          reason: _failed ? null : blocked,
          onPressed: blocked != null ? null : () => _publish(cat, draft, today, weekend, title),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failed) ...[
              GrowNote(
                danger: true,
                text: NoteText(l.hotelGrowPublishFailedTitle, danger: true),
                info: GzInfoButton(title: l.hotelGrowPublishFailedTitle, paragraphs: [l.hotelGrowPublishFailed]),
              ),
              const SizedBox(height: GzSpace.section),
            ],
            GrowHead(icon: GzIcons.calendarDots, title: l.hotelGrowDatesTitle),
            const SizedBox(height: GzSpace.s3),
            GzChipGroup<Shortcut>(
              label: l.hotelGrowShortcuts,
              deselectable: true,
              value: draft.shortcut,
              onChanged: setShortcut,
              options: [
                GzChipOption(value: Shortcut.openWeekends, icon: GzIcons.calendarDots, label: l.hotelGrowOpenWeekends),
                GzChipOption(value: Shortcut.weekdays, icon: GzIcons.calendar, label: l.hotelGrowWeekdays),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            if (draft.shortcut != null)
              Row(
                children: [
                  GzFactChip(
                    icon: GzIcons.calendarCheck,
                    value: f.integer(shortcutList(draft.shortcut!).length),
                    label: l.hotelGrowDatesChosen(shortcutList(draft.shortcut!).length),
                    tone: GzFactTone.accent,
                  ),
                  const Spacer(),
                  GzButton(
                    label: l.hotelGrowChooseDates,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.calendar,
                    onPressed: () => setShortcut(null),
                  ),
                ],
              )
            else ...[
              EventCalendar(
                month: month,
                onMonthChange: (m) => setState(() => _month = m),
                picked: draft.eventDates,
                onToggle: toggleDate,
                minMonth: gzMonthOfIso(today),
                maxMonth: gzMonthOfIso(gzAddDaysIso(today, 360)),
                today: today,
                soft: soft,
                label: l.hotelGrowDatesTitle,
              ),
              const SizedBox(height: GzSpace.s3),
              Row(
                children: [
                  if (noDates)
                    Expanded(
                      child: showErrors
                          ? Semantics(
                              liveRegion: true,
                              child: Row(
                                children: [
                                  GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                                  const SizedBox(width: GzSpace.s1),
                                  Expanded(
                                    child: GzText(l.hotelGrowNoDatesError, role: GzTextRole.bodyS, color: c.textDanger),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    )
                  else
                    GzFactChip(
                      icon: GzIcons.calendarCheck,
                      value: f.integer(draft.eventDates.length),
                      label: l.hotelGrowDatesChosen(draft.eventDates.length),
                      tone: GzFactTone.accent,
                    ),
                  if (!noDates) const Spacer(),
                  if (!noDates)
                    GzButton(
                      label: l.hotelGrowClearDates,
                      variant: GzButtonVariant.tertiary,
                      onPressed: () => session.patch((d) => d.copyWith(eventDates: const [])),
                    )
                  else if (soft.isNotEmpty)
                    GzButton(
                      label: l.hotelGrowUseOpenDates,
                      variant: GzButtonVariant.tertiary,
                      iconStart: GzIcons.calendarPlus,
                      onPressed: () => session.patch((d) => d.copyWith(shortcut: null, eventDates: [...soft])),
                    ),
                ],
              ),
            ],
            if (clash != null) ...[
              const SizedBox(height: GzSpace.s4),
              GrowNote(
                icon: GzIcons.offer,
                text: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: GzSpace.s2,
                  children: [
                    GzText(clash.window.title.of(lang), role: GzTextRole.bodyS, color: c.textPrimary),
                    GzPrice(fils: windowRate(clash.window), size: GzPriceSize.strong),
                  ],
                ),
                info: GzInfoButton(
                  title: l.hotelGrowOverlapTitle,
                  paragraphs: [
                    l.hotelGrowOverlap(
                      clash.window.title.of(lang),
                      f.money(windowRate(clash.window)),
                      f.list([for (final d in clash.dates.take(3)) f.date(d, DateStyle.short)]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: GzSpace.section),
            GrowHead(icon: GzIcons.timer, title: l.hotelGrowRunsTitle),
            const SizedBox(height: GzSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DatePick(
                    label: l.hotelGrowStartsLabel,
                    value: startDate,
                    today: today,
                    minDate: today,
                    onChanged: (d) => session.patch((x) => x.copyWith(startsOn: d)),
                  ),
                ),
                if (!draft.untilEnd) ...[
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: DatePick(
                      label: l.hotelGrowEndsLabel,
                      value: draft.endsOn,
                      today: today,
                      minDate: startDate,
                      onChanged: (d) => session.patch((x) => x.copyWith(endsOn: d)),
                      error: showErrors && endBeforeStart ? l.hotelGrowEndBeforeStart : (showErrors && noEnd ? l.hotelGrowEndRequired : null),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            GzToggleRow(
              title: l.hotelGrowUntilEnd,
              divider: false,
              checked: draft.untilEnd,
              onChanged: (on) => session.patch((x) => x.copyWith(untilEnd: on, endsOn: on ? null : x.endsOn)),
            ),
            const SizedBox(height: GzSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzStatusPill(
                status: scheduled ? GzStatus.requested : GzStatus.confirmed,
                audience: GzStatusAudience.hotel,
                label: scheduled ? l.hotelGrowScheduledPill : l.commonListingStatusActive,
              ),
            ),
            const SizedBox(height: GzSpace.section),
            PriceLines(rate: rate, packageIds: draft.packageIds, dates: draft.eventDates),
          ],
        ),
      ),
    );
  }
}
