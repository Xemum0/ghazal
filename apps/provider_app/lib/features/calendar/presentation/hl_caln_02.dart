// HL-CALN-02 Week view, screen (web `HL-CALN-02.tsx`): seven day rows for planning the week. For each day, what each hall is doing, so the manager
// sees gaps and clashes faster than in the month grid. Sunday first; Thu-Sat on the rose wash; Block and Create offer sit inline on open lanes.
// Tapping a date opens the Day view; a booked lane opens the booking; "Select dates" is the accessible way to build a range.
// Requirements: HA-CAL-02, HA-CAL-06, HA-CAL-07, HA-CAL-09.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/calendar_data.dart';
import 'widgets/calendar_bits.dart';
import 'widgets/calendar_chrome.dart';
import 'widgets/week_rows.dart';

class HlCaln02Screen extends ConsumerStatefulWidget {
  const HlCaln02Screen({super.key});

  @override
  ConsumerState<HlCaln02Screen> createState() => _HlCaln02ScreenState();
}

class _HlCaln02ScreenState extends ConsumerState<HlCaln02Screen> {
  bool _selecting = false;
  GzDateRange _range = GzDateRange.empty;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final role = ref.watch(calendarRoleProvider);
    final may = canBlock(role);
    final view = ref.watch(calViewProvider);
    final today = ref.watch(calendarTodayProvider);
    final now = ref.watch(clockProvider)();
    final sunday = sundayOf(view.selected);
    final saturday = addDays(sunday, 6);
    final win = (from: sunday, to: saturday);
    final hallsValue = ref.watch(calendarHallsProvider);
    final claimsValue = ref.watch(calendarClaimsProvider(win));
    final halls = hallsValue.value ?? const <Hall>[];
    final shown = view.hall == kAllHalls ? halls : halls.where((h) => h.id == view.hall).toList();
    final claims = [for (final cl in claimsValue.value ?? const <CalendarClaim>[]) if (view.hall == kAllHalls || cl.hallId == view.hall) cl];
    final dates = datesOfSpan(_range.start, _range.end);
    final ready = hallsValue.hasValue && claimsValue.hasValue;
    final notifier = ref.read(calViewProvider.notifier);

    ref.listen(calendarClaimsProvider(win), (prev, next) {
      if (prev?.value != null && next.value != null && prev!.value!.length != next.value!.length) {
        setState(() {
          _selecting = false;
          _range = GzDateRange.empty;
        });
      }
    });

    final m0 = int.parse(sunday.substring(5, 7));
    final m1 = int.parse(saturday.substring(5, 7));
    final d0 = f.integer(int.parse(sunday.substring(8)));
    final d1 = f.integer(int.parse(saturday.substring(8)));
    final title = m0 == m1 ? '$d0 – $d1 ${f.monthName(m0)}' : '$d0 ${f.monthName(m0, short: true)} – $d1 ${f.monthName(m1, short: true)}';

    void tap(String iso) {
      final s = _range.start;
      setState(() {
        if (s == null || _range.end != null) {
          _range = GzDateRange(start: iso);
        } else {
          _range = iso.compareTo(s) < 0 ? GzDateRange(start: iso, end: s) : GzDateRange(start: s, end: iso);
        }
      });
    }

    final top = CalTop(
      selecting: _selecting,
      onSelect: may && ready
          ? () => setState(() {
              _selecting = !_selecting;
              _range = GzDateRange.empty;
            })
          : null,
      onBlock: may && ready ? () => _selecting ? openBlockSheet(_nav, start: _range.start, end: _range.end) : openBlockSheet(_nav) : null,
    );

    final bottom = _selecting
        ? RangeBar(
            summary: spanText(f, _range.start, _range.end),
            count: dates.length,
            role: role,
            offline: false,
            onClear: () => setState(() => _range = GzDateRange.empty),
            onBlock: () => openBlockSheet(_nav, start: _range.start, end: _range.end),
            onOpen: () => openBlockSheet(_nav, start: _range.start, end: _range.end, mode: 'open'),
            onOffer: () => _nav.push('HL-GROW-02', params: <String, Object?>{'dates': dates}),
          )
        : null;

    Widget body() => GzAsyncView<List<CalendarClaim>>(
      value: claimsValue,
      loading: const WeekSkeleton(),
      onRetry: () => ref.invalidate(calendarClaimsProvider(win)),
      data: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodHead(
            title: title,
            prevLabel: l.hotelCalendarPrevWeek,
            nextLabel: l.hotelCalendarNextWeek,
            onPrev: () => notifier.select(addDays(view.selected, -7)),
            onNext: () => notifier.select(addDays(view.selected, 7)),
            onToday: () => notifier.select(today),
            away: sunday != sundayOf(today),
          ),
          if (claims.isEmpty) GzIconListRow(illustration: GzIllustrationName.calendar, title: l.hotelCalendarEmptyTitle),
          WeekRows(
            sunday: sunday,
            halls: shown,
            claims: claims,
            role: role,
            today: today,
            now: now,
            offline: false,
            selecting: _selecting,
            range: _range,
            onTapDate: tap,
            onOpenDay: (iso) {
              notifier.select(iso);
              _nav.push('HL-CALN-03', params: <String, Object?>{'date': iso});
            },
            onBlock: (iso, hallId) => openBlockSheet(_nav, start: iso, end: iso, hallId: hallId),
            onOpenDates: (iso) => openBlockSheet(_nav, start: iso, end: iso, mode: 'open'),
            onOffer: (iso) => _nav.push('HL-GROW-02', params: <String, Object?>{'date': iso}),
            onBooking: (id) => _nav.push('HL-BOOK-03', params: <String, Object?>{'bookingId': id}),
          ),
        ],
      ),
    );

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [top, const ViewSwitch(view: CalViewKind.week), HallChips(halls: halls)]),
        bottom: bottom,
        child: Padding(padding: const EdgeInsets.only(bottom: GzSpace.s8), child: body()),
      ),
    );
  }
}
