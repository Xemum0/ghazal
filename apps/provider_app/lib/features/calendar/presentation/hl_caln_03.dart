// HL-CALN-03 Day view, screen (web `HL-CALN-03.tsx`): one date in operational detail. For every hall, the setup, event and teardown on a business-day
// bar, the booking card with Call / Chat, and what can be done with the date (Block, Create offer, Open this date). This is where "tap a date opens
// its day agenda and the related booking" lands. Requirements: HA-CAL-03, HA-CAL-06, HA-CAL-07, HA-CAL-09, HA-DASH-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/calendar_data.dart';
import 'widgets/calendar_bits.dart';
import 'widgets/calendar_chrome.dart';
import 'widgets/hall_day.dart';

class HlCaln03Screen extends ConsumerStatefulWidget {
  const HlCaln03Screen({super.key});

  @override
  ConsumerState<HlCaln03Screen> createState() => _HlCaln03ScreenState();
}

class _HlCaln03ScreenState extends ConsumerState<HlCaln03Screen> {
  String? _date;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final role = ref.watch(calendarRoleProvider);
    final may = canBlock(role);
    final view = ref.watch(calViewProvider);
    final today = ref.watch(calendarTodayProvider);
    final now = ref.watch(clockProvider)();
    final asked = nav.params['date'];
    final date = _date ?? (asked is String ? asked : view.selected);
    final win = monthWindow(ymOf(date));
    final hallsValue = ref.watch(calendarHallsProvider);
    final claimsValue = ref.watch(calendarClaimsProvider(win));
    final halls = hallsValue.value ?? const <Hall>[];
    final shown = view.hall == kAllHalls ? halls : halls.where((h) => h.id == view.hall).toList();
    final claims = claimsValue.value ?? const <CalendarClaim>[];
    final ready = hallsValue.hasValue && claimsValue.hasValue;
    final notifier = ref.read(calViewProvider.notifier);

    void go(String iso) {
      setState(() => _date = iso);
      notifier.select(iso);
    }

    final top = CalTop(onBlock: may && ready ? () => openBlockSheet(nav, start: date, end: date) : null);

    Widget body() => GzAsyncView<List<CalendarClaim>>(
      value: claimsValue,
      loading: const DaySkeleton(),
      onRetry: () => ref.invalidate(calendarClaimsProvider(win)),
      data: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodHead(
            title: f.date(date, DateStyle.short),
            prevLabel: l.hotelCalendarPrevDay,
            nextLabel: l.hotelCalendarNextDay,
            onPrev: () => go(addDays(date, -1)),
            onNext: () => go(addDays(date, 1)),
            onToday: () => go(today),
            away: date != today,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s8),
                  Container(
                    padding: EdgeInsets.only(top: i > 0 ? GzSpace.s6 : 0),
                    decoration: i > 0 ? BoxDecoration(border: Border(top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair))) : null,
                    child: HallDay(
                      date: date,
                      hall: shown[i],
                      allHalls: halls,
                      claims: claims,
                      claim: claimOf(claims, date, shown[i].id),
                      role: role,
                      today: today,
                      now: now,
                      offline: false,
                      onBlock: (hallId) => openBlockSheet(nav, start: date, end: date, hallId: hallId),
                      onOpenDates: () => openBlockSheet(nav, start: date, end: date, mode: 'open'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [top, const ViewSwitch(view: CalViewKind.day), HallChips(halls: halls)]),
        child: Padding(padding: const EdgeInsets.only(bottom: GzSpace.s8), child: body()),
      ),
    );
  }
}
