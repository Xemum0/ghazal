// HL-CALN-01 Month calendar, tab root (web `HL-CALN-01.tsx`): the month at a glance with the chosen day's agenda beneath it. Entry point for
// blocking, reopening, range select and soft-date mode (the unsold weekend dates worth an offer). Sunday-first, Thu-Sat on the rose-tint band, one
// mark per hall (solid = booked, ring = on hold, dash = blocked, gold bead = a request that claims nothing); the key is behind the (i).
// Block in three taps: Calendar, the date, Block (the lock in the bar opens the sheet on the chosen date). Range select: "Select dates".
// Requirements: HA-CAL-01, HA-CAL-04, HA-CAL-05, HA-CAL-06, HA-CAL-07, HA-CAL-09, HA-DASH-07.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/calendar_data.dart';
import 'widgets/calendar_agenda.dart';
import 'widgets/calendar_bits.dart';
import 'widgets/calendar_chrome.dart';

class HlCaln01Screen extends ConsumerStatefulWidget {
  const HlCaln01Screen({super.key});

  @override
  ConsumerState<HlCaln01Screen> createState() => _HlCaln01ScreenState();
}

class _HlCaln01ScreenState extends ConsumerState<HlCaln01Screen> {
  bool _selecting = false;
  GzDateRange _range = GzDateRange.empty;
  bool _soft = false;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  void _toggleSelect() => setState(() {
    _selecting = !_selecting;
    _range = GzDateRange.empty;
    _soft = false;
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final role = ref.watch(calendarRoleProvider);
    final may = canBlock(role);
    final view = ref.watch(calViewProvider);
    final today = ref.watch(calendarTodayProvider);
    final now = ref.watch(clockProvider)();
    final hallsValue = ref.watch(calendarHallsProvider);
    final claimsValue = ref.watch(calendarClaimsProvider(monthWindow(view.ym)));
    final halls = hallsValue.value ?? const <Hall>[];
    final shown = view.hall == kAllHalls ? halls : halls.where((h) => h.id == view.hall).toList();
    final claims = [for (final cl in claimsValue.value ?? const <CalendarClaim>[]) if (view.hall == kAllHalls || cl.hallId == view.hall) cl];
    final soft = ref.watch(calendarSoftDatesProvider).value ?? const <String>[];
    final nudged = ref.watch(calendarNudgeProvider) || GzNavigatorScope.of(context).params['nudge'] != true;
    final dates = datesOfSpan(_range.start, _range.end);
    final ready = hallsValue.hasValue && claimsValue.hasValue;
    final notifier = ref.read(calViewProvider.notifier);
    final away = view.ym != ymOf(today) || view.selected != today;

    // The calendar updates in place after a block or an open: leave range select behind.
    ref.listen(calendarClaimsProvider(monthWindow(view.ym)), (prev, next) {
      if (prev?.value != null && next.value != null && prev!.value!.length != next.value!.length && (_selecting || _range.start != null)) setState(() => _range = GzDateRange.empty);
    });

    final top = CalTop(
      selecting: _selecting,
      onSelect: may && ready ? _toggleSelect : null,
      onBlock: may && ready ? () => _selecting ? openBlockSheet(_nav, start: _range.start, end: _range.end) : openBlockSheet(_nav, start: view.selected, end: view.selected) : null,
      onEmail: () => _nav.openSheet('HL-CALN-05'),
    );

    Widget? bottom;
    if (_soft) {
      bottom = GzActionBar(action: GzActionBarAction(label: l.hotelCalendarCreateOffer, onPressed: () => _nav.push('HL-GROW-02', params: <String, Object?>{'dates': soft})));
    } else if (_selecting) {
      bottom = RangeBar(
        summary: spanText(f, _range.start, _range.end),
        count: dates.length,
        role: role,
        offline: false,
        onClear: () => setState(() => _range = GzDateRange.empty),
        onBlock: () => openBlockSheet(_nav, start: _range.start, end: _range.end),
        onOpen: () => openBlockSheet(_nav, start: _range.start, end: _range.end, mode: 'open'),
        onOffer: () => _nav.push('HL-GROW-02', params: <String, Object?>{'dates': dates}),
      );
    }

    Widget body() => GzAsyncView<List<CalendarClaim>>(
      value: claimsValue,
      loading: const MonthSkeleton(),
      onRetry: () => ref.invalidate(calendarClaimsProvider(monthWindow(view.ym))),
      data: (_) {
        final title = f.date(f.kuwaitDate(view.ym.year, view.ym.month, 1), DateStyle.monthYear);
        final empty = claims.isEmpty;
        void step(int d) {
          final idx = view.ym.year * 12 + (view.ym.month - 1) + d;
          notifier.setYm(GzYm(idx ~/ 12, (idx % 12) + 1));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role == StaffRole.accountant)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3),
                child: Row(children: [GzIcon(GzIcons.eye, size: GzIconSize.sm, color: c.iconSecondary), const SizedBox(width: GzSpace.s2), GzText(l.hotelCalendarReadOnly, role: GzTextRole.caption, color: c.textSecondary)]),
              ),
            if (!nudged && !_selecting && !_soft) Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4), child: CalNudge(offline: false, onConfirm: () {
              ref.read(calendarNudgeProvider.notifier).confirm();
              _nav.toast(GzToastSpec(message: l.hotelCalendarNudgeDone, tone: GzToastTone.success, icon: GzIcons.checkCircle));
            })),
            if (_selecting && dates.isEmpty) Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3), child: const RangeHint()),
            PeriodHead(
              title: title,
              prevLabel: context.gzL10n.commonCalendarPreviousMonth,
              nextLabel: context.gzL10n.commonCalendarNextMonth,
              onPrev: () => step(-1),
              onNext: () => step(1),
              onToday: () => notifier.select(today),
              away: away,
              info: MonthKey(soft: _soft),
            ),
            Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: GzHotelMonthGrid(
              head: false,
              halls: shown,
              claims: claims,
              month: view.ym,
              onMonthChange: notifier.setYm,
              mode: _selecting ? GzHotelMonthMode.select : GzHotelMonthMode.view,
              selected: view.selected,
              onSelectDate: notifier.select,
              range: _range,
              onRangeChange: (r) => setState(() => _range = r),
              legend: false,
              label: l.hotelCalendarGridLabel(title),
            )),
            if (empty && !_selecting && !_soft)
              Padding(
                padding: const EdgeInsets.only(top: GzSpace.s4),
                child: GzEmptyState(
                  fill: false,
                  illustration: GzIllustrationName.calendar,
                  title: l.hotelCalendarEmptyTitle,
                  action: may ? GzStateAction(label: l.hotelCalendarActionBlock, iconStart: GzIcons.lock, onPressed: () => openBlockSheet(_nav)) : null,
                ),
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s5),
                child: _selecting
                    ? const SizedBox.shrink()
                    : _soft
                    ? _SoftPanel(dates: soft, selected: view.selected, onClose: () => setState(() => _soft = false), onPick: notifier.select)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CalAgenda(
                            date: view.selected,
                            halls: shown,
                            claims: claims,
                            role: role,
                            today: today,
                            now: now,
                            offline: false,
                            onBlock: (hallId) => openBlockSheet(_nav, start: view.selected, end: view.selected, hallId: hallId),
                            onOpenDates: () => openBlockSheet(_nav, start: view.selected, end: view.selected, mode: 'open'),
                          ),
                          if (soft.isNotEmpty) ...[
                            const SizedBox(height: GzSpace.s2),
                            GzIconListRow(
                              flush: true,
                              last: true,
                              icon: GzIcons.calendarPlus,
                              title: l.hotelCalendarSoftTitle,
                              trailing: Semantics(label: l.hotelCalendarSoftRow(soft.length, f.integer(kSoftWindowDays)), child: GzText(f.integer(soft.length), role: GzTextRole.figBodyS, color: c.textPrimary, figures: true)),
                              onPressed: () => setState(() => _soft = true),
                            ),
                          ],
                        ],
                      ),
              ),
          ],
        );
      },
    );

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [top, const ViewSwitch(view: CalViewKind.month), HallChips(halls: halls)],
        ),
        bottom: bottom,
        child: Padding(padding: const EdgeInsets.only(bottom: GzSpace.s8), child: body()),
      ),
    );
  }
}

/// Soft-date mode: the unsold weekend dates of the next 60 days as chips, with the count and a close.
class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.dates, required this.selected, required this.onClose, required this.onPick});

  final List<String> dates;
  final String selected;
  final VoidCallback onClose;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            children: [
              Container(width: GzSize.avatarSm, height: GzSize.avatarSm, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint), child: GzIcon(GzIcons.calendarPlus, size: GzIconSize.md, color: c.iconPrimary)),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzText(l.hotelCalendarSoftTitle, role: GzTextRole.uiTitle, color: c.textStrong)),
              GzText(f.integer(dates.length), role: GzTextRole.figBodyS, color: c.textGoldInk, figures: true),
              GzIconButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: onClose),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s3),
        GzChipGroup<String>(
          label: l.hotelCalendarSoftTitle,
          value: dates.contains(selected) ? selected : null,
          onChanged: (v) {
            if (v != null) onPick(v);
          },
          options: [for (final d in dates) GzChipOption<String>(value: d, label: dayMonthOf(f, d))],
        ),
      ],
    );
  }
}
