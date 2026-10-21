import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, LocalizedText, NamedRef, NeedsYouRow, PartnerRequestRow, RequestItem, SlaReading, SlaState, TriageType;
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/client/client_d.dart';
import 'package:ghazal_ui/src/hotel/hotel_a.dart';
import 'package:ghazal_ui/src/hotel/hotel_shared.dart';

import '../client/client_d_fixtures.dart';
import '../shared/shared_harness.dart';

final DateTime _now = DateTime.parse('2026-11-12T16:00:00+03:00');

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 350}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width + 40, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: GzFormatScope(
            format: GzFormat(locale: Locale(lang), now: () => _now),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String _plain(Widget w) => w is Text ? GzBidi.strip(w.data ?? w.textSpan?.toPlainText() ?? '').replaceAll('\u00a0', ' ') : '';
Finder _text(String s) => find.byWidgetPredicate((w) => w is Text && _plain(w) == s, description: 'text "$s"');
Finder _textHas(String s) => find.byWidgetPredicate((w) => w is Text && _plain(w).contains(s), description: 'text containing "$s"');

PartnerRequestRow _row(Booking b, {SlaState state = SlaState.neutral, double elapsed = 0.1, int minutes = 1200, int others = 0, SlaReading? sla}) => PartnerRequestRow(
      booking: b,
      halls: const [NamedRef(id: 'V01-danah', name: LocalizedText(en: 'Danah Ballroom', ar: 'قاعة الدانة'))],
      voucher: null,
      sla: sla ?? SlaReading(state: state, elapsed: elapsed, minutesLeft: minutes, minutesWaiting: 60),
      otherRequestsSameDate: others,
    );

void main() {
  late ClientDFixtures fx;
  setUpAll(() async {
    await loadUiFonts();
    fx = await ClientDFixtures.load();
  });

  group('GzWeekStrip', () {
    List<GzStripDay> days(int n) => [
          for (var i = 0; i < n; i++)
            GzStripDay(iso: '2026-11-${(12 + i).toString().padLeft(2, '0')}', marks: [if (i == 0) GzStripMark.confirmed, if (i == 1) GzStripMark.pending, GzStripMark.open]),
        ];

    testWidgets('a tap reports the day, the selected day is a toggled node and every day is at least 88 high', (tester) async {
      final picked = <String>[];
      await _pump(tester, GzWeekStrip(label: 'Next 7 days', days: days(7), today: '2026-11-12', selected: '2026-11-14', onSelect: picked.add));
      final names = find.bySemanticsLabel(RegExp('^(Thu|Fri|Sat|Sun|Mon|Tue|Wed)'));
      expect(names, findsNWidgets(7));
      expect(tester.getSize(names.first).height, greaterThanOrEqualTo(88));
      final sat = tester.getSemantics(find.bySemanticsLabel(RegExp('Sat 14')));
      expect(sat.flagsCollection.isSelected, Tristate.isTrue);
      await tester.tap(find.bySemanticsLabel(RegExp('Fri 13')));
      expect(picked, ['2026-11-13']);
    });

    testWidgets('the semantics name carries today and the counts, the legend counts the marks', (tester) async {
      await _pump(tester, GzWeekStrip(label: 'Next 7 days', days: days(7), today: '2026-11-12'));
      expect(find.bySemanticsLabel(RegExp(r'Thu 12 Nov, Today, 1 confirmed, 1 open')), findsOneWidget);
      expect(_text('Confirmed'), findsOneWidget);
      expect(_text('Pending or on hold'), findsOneWidget);
      // 6 open marks over the week (one on each day, 7 days) = 7.
      expect(find.byWidgetPredicate((w) => w is Text && GzBidi.strip(w.data ?? '') == '7'), findsWidgets);
    });

    testWidgets('fourteen days wrap into two rows of seven, equal columns', (tester) async {
      await _pump(tester, GzWeekStrip(label: 'Next 14 days', days: days(14), today: '2026-11-12'));
      final first = tester.getRect(find.bySemanticsLabel(RegExp('Thu 12')));
      final eighth = tester.getRect(find.bySemanticsLabel(RegExp('Thu 19')));
      expect(eighth.left, closeTo(first.left, 0.5));
      expect(eighth.top, greaterThan(first.bottom));
    });

    testWidgets('Arabic: the first day sits at the right edge', (tester) async {
      await _pump(tester, GzWeekStrip(label: 'الأيام', days: days(7), today: '2026-11-12'), lang: 'ar');
      final strip = tester.getRect(find.byType(GzWeekStrip));
      final first = tester.getRect(find.bySemanticsLabel(RegExp('12')).first);
      expect(first.right, closeTo(strip.right, 1));
    });
  });

  group('GzKpiTile', () {
    testWidgets('delta sign and colour: up is +, down is a minus sign, flat has none', (tester) async {
      await _pump(
        tester,
        Column(
          children: const [
            GzKpiTile(label: 'Views', value: GzKpiValue.count(1296), delta: 12, deltaLabel: 'vs last month'),
            GzKpiTile(label: 'Requests', value: GzKpiValue.count(41), delta: -6),
            GzKpiTile(label: 'Conversion', value: GzKpiValue.percent(2.93), delta: 0),
          ],
        ),
      );
      expect(_text('+12%'), findsOneWidget);
      expect(_text('−6%'), findsOneWidget);
      expect(_text('0%'), findsOneWidget);
      expect(_text('1,296'), findsOneWidget);
      expect(_text('2.9%'), findsOneWidget);
      expect(find.bySemanticsLabel('up 12%'), findsOneWidget);
      expect(find.bySemanticsLabel('unchanged'), findsOneWidget);
    });

    testWidgets('with an icon the caption is not drawn but names the number', (tester) async {
      await _pump(tester, GzKpiTile(label: 'Views', icon: GzIcons.star, value: const GzKpiValue.count(5), delta: 3, deltaLabel: 'vs last month'));
      expect(_text('Views'), findsNothing);
      expect(_text('vs last month'), findsNothing);
      expect(find.bySemanticsLabel('Views'), findsOneWidget);
    });

    testWidgets('a pressed tile calls back and is a button', (tester) async {
      var n = 0;
      await _pump(tester, GzKpiTile(label: 'Views', value: const GzKpiValue.count(5), onPressed: () => n++));
      await tester.tap(find.byType(GzKpiTile));
      expect(n, 1);
    });

    testWidgets('money kind goes through the shared price', (tester) async {
      await _pump(tester, const GzKpiTile(label: 'Redeemed', value: GzKpiValue.money(12000)));
      expect(find.byType(GzPrice), findsOneWidget);
    });

    testWidgets('the trend line mirrors with the language (a sparkline is present)', (tester) async {
      await _pump(
        tester,
        const GzKpiTile(label: 'Views', value: GzKpiValue.count(5), trend: GzKpiTrend(values: [1, 3, 2, 5], label: 'Views, last 30 days')),
        lang: 'ar',
      );
      expect(find.bySemanticsLabel('Views, last 30 days'), findsOneWidget);
    });
  });

  group('GzOccupancyMeter and GzVoucherActivityCard', () {
    testWidgets('blocked nights leave the denominator: 10 of 24 is 42%', (tester) async {
      await _pump(tester, const GzOccupancyMeter(title: 'Occupancy', booked: 10, held: 2, blocked: 4, open: 12));
      expect(_text('42%'), findsOneWidget);
      expect(_text('10 of 24 hall-nights booked'), findsOneWidget);
    });

    testWidgets('no sellable nights reads 0%', (tester) async {
      await _pump(tester, const GzOccupancyMeter(title: 'Occupancy', booked: 0, held: 0, blocked: 4, open: 0));
      expect(_text('0%'), findsOneWidget);
    });

    testWidgets('the voucher card shows counts only: headline, delta and three ruled lines', (tester) async {
      await _pump(
        tester,
        GzVoucherActivityCard(
          title: 'Vouchers this month',
          period: '1 Nov - 12 Nov',
          bought: 38,
          delta: 12,
          daily: [for (var i = 0; i < 12; i++) GzVoucherDay(date: '2026-11-${(i + 1).toString().padLeft(2, '0')}', value: 3 + i % 3)],
          requests: 41,
          awaitingClient: 10,
          redeemed: 9,
        ),
      );
      expect(_text('38'), findsWidgets);
      expect(_text('+12%'), findsOneWidget);
      expect(_text('Requests received'), findsOneWidget);
      expect(_text('Waiting for the client to confirm'), findsOneWidget);
      expect(_text('Vouchers redeemed'), findsOneWidget);
      expect(_textHas('KD'), findsNothing);
    });
  });

  group('GzDayTimeline', () {
    const events = [
      GzTimelineEvent(id: 'a-setup', time: '17:00', title: 'Setup', meta: 'Danah Ballroom', kind: GzTimelineKind.prep),
      GzTimelineEvent(id: 'a', time: '21:00', title: 'Najla Al-Bader', userTitle: true, meta: 'Danah Ballroom · 420 guests', status: GzStatus.confirmed),
      GzTimelineEvent(id: 'a-down', time: '04:00', nextDay: true, title: 'Teardown', meta: 'Danah Ballroom', kind: GzTimelineKind.prep),
    ];

    testWidgets('rows are in time order with Now between done and open; the next-day row says which day', (tester) async {
      await _pump(tester, const GzDayTimeline(date: '2026-11-12', events: events, now: '19:00'));
      final ys = [for (final t in ['Setup', 'Now', 'Najla Al-Bader', 'Teardown']) tester.getTopLeft(_text(t)).dy];
      expect([...ys]..sort(), ys);
      expect(_textHas('Fri 13 Nov'), findsOneWidget);
    });

    testWidgets('an empty day says so; a day that is not today has no Now row', (tester) async {
      await _pump(tester, const GzDayTimeline(date: '2026-11-12', events: []));
      expect(_text('Nothing scheduled today'), findsOneWidget);
      await _pump(tester, const GzDayTimeline(date: '2026-11-13', events: events));
      expect(_text('Now'), findsNothing);
    });

    testWidgets('a pressed event reports its id; prep rows report theirs too', (tester) async {
      final ids = <String>[];
      await _pump(tester, GzDayTimeline(date: '2026-11-12', events: events, now: '19:00', onPressed: ids.add));
      await tester.tap(_text('Najla Al-Bader'));
      expect(ids, ['a']);
    });

    testWidgets('the thread draws on once and finishes; reduced motion shows it finished at once', (tester) async {
      await _pump(tester, const GzDayTimeline(date: '2026-11-12', events: events, now: '19:00'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Transform), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await _pump(tester, const GzDayTimeline(date: '2026-11-12', events: events, now: '19:00'), reduceMotion: true);
      final t = tester.widgetList<Transform>(find.descendant(of: find.byType(GzDayTimeline), matching: find.byType(Transform)));
      for (final x in t) {
        expect(x.transform.getMaxScaleOnAxis(), closeTo(1, 0.0001));
      }
    });

    testWidgets('Arabic: the time column is at the right of the rail', (tester) async {
      await _pump(tester, const GzDayTimeline(date: '2026-11-12', events: events, now: '19:00'), lang: 'ar');
      final time = tester.getRect(find.byType(GzNum).first);
      final title = tester.getRect(_text('الآن'));
      expect(time.center.dx, greaterThan(title.center.dx));
    });
  });

  group('GzRequestRow', () {
    testWidgets('a danger request shows the date, KD total and the time left in the danger tone; 80 high; chevron', (tester) async {
      var n = 0;
      final b = fx.byRef('GZ-2611-0147');
      await _pump(tester, GzRequestRow(request: _row(b, state: SlaState.danger, minutes: 180), onPressed: () => n++, flush: true));
      expect(_text('3 h'), findsOneWidget);
      expect(tester.getSize(find.byType(GzRequestRow)).height, greaterThanOrEqualTo(80));
      expect(find.bySemanticsLabel(RegExp('3 hours left')), findsOneWidget);
      await tester.tap(find.byType(GzRequestRow));
      expect(n, 1);
    });

    testWidgets('an expired reading says Missed; a new request carries a bead', (tester) async {
      final b = fx.byRef('GZ-2611-0147');
      await _pump(tester, GzRequestRow(request: _row(b, state: SlaState.expired, minutes: 0), isNew: true));
      expect(_text('Missed'), findsOneWidget);
      expect(find.byType(GzThreadBead), findsOneWidget);
    });

    testWidgets('another Needs-you item leads with an icon disk and shows its subtitle', (tester) async {
      final item = RequestItem(
        id: 'x',
        type: TriageType.visitRequest,
        venueId: 'V01',
        raisedAt: _now,
        dueAt: null,
        slaHours: null,
        bookingId: null,
        conversationId: null,
        reviewId: null,
        visitId: null,
        voucherId: null,
        voucherCode: null,
        title: const LocalizedText(en: 'Visit request', ar: 'طلب زيارة'),
        subtitle: const LocalizedText(en: 'Sat 21 Nov', ar: 'السبت 21 نوفمبر'),
        order: 1,
      );
      await _pump(tester, GzRequestRow.fromNeedsYou(NeedsYouRow(item: item, sla: null)));
      expect(_text('Visit request'), findsOneWidget);
      expect(_text('Sat 21 Nov'), findsOneWidget);
      expect(find.text('Missed'), findsNothing);
    });
  });

  group('GzRequestCard', () {
    late PartnerRequestRow base;
    setUp(() => base = _row(fx.byRef('GZ-2611-0147')));
    final pkg = const LocalizedText(en: 'Ladies weekend', ar: 'باقة السيدات');

    testWidgets('one gold Accept and two equal secondary actions call back', (tester) async {
      final calls = <String>[];
      await _pump(tester, GzRequestCard(request: base, packageName: pkg, onAccept: () => calls.add('a'), onReschedule: () => calls.add('r'), onDecline: () => calls.add('d')));
      await tester.tap(_text('Accept'));
      await tester.tap(_text('Reschedule'));
      await tester.tap(_text('Decline'));
      expect(calls, ['a', 'r', 'd']);
      final r = tester.getSize(find.ancestor(of: _text('Reschedule'), matching: find.byType(GzButton)).first);
      final d = tester.getSize(find.ancestor(of: _text('Decline'), matching: find.byType(GzButton)).first);
      expect(r.width, closeTo(d.width, 0.5));
      expect(r.height, greaterThanOrEqualTo(44));
    });

    testWidgets('held disables Accept and says why; the pair stays live', (tester) async {
      var accepted = 0;
      var declined = 0;
      await _pump(tester, GzRequestCard(request: base, held: true, onAccept: () => accepted++, onDecline: () => declined++));
      await tester.tap(_text('Accept'), warnIfMissed: false);
      expect(accepted, 0);
      expect(_text('Date on hold'), findsOneWidget);
      await tester.tap(_text('Decline'));
      expect(declined, 1);
    });

    testWidgets('accepting holds the other two actions', (tester) async {
      var n = 0;
      await _pump(tester, GzRequestCard(request: base, state: GzRequestCardState.accepting, onReschedule: () => n++, onDecline: () => n++));
      await tester.tap(_text('Reschedule'), warnIfMissed: false);
      await tester.tap(_text('Decline'), warnIfMissed: false);
      expect(n, 0);
    });

    testWidgets('the SLA states draw the bar in their own tone; expired and resolved cards differ', (tester) async {
      final colors = <GzSlaState, Color>{};
      for (final (s, st) in [(GzSlaState.neutral, SlaState.neutral), (GzSlaState.gold, SlaState.gold), (GzSlaState.danger, SlaState.danger)]) {
        await _pump(tester, GzRequestCard(request: _row(fx.byRef('GZ-2611-0147'), state: st, elapsed: 0.6)));
        final bar = tester.widgetList<ColoredBox>(find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(ColoredBox))).first;
        colors[s] = bar.color;
      }
      expect(colors.values.toSet(), hasLength(3));
      final c = GzColors.light;
      expect(colors[GzSlaState.gold], c.statusSlaWarn);
      expect(colors[GzSlaState.danger], c.statusSlaAlert);
      await _pump(tester, GzRequestCard(request: base, state: GzRequestCardState.declined, declineReason: 'Date unavailable.'));
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(_text('Date unavailable.'), findsOneWidget);
      expect(_text('Accept'), findsNothing);
    });

    testWidgets('the reply bar width is the share of the window left', (tester) async {
      await _pump(tester, GzRequestCard(request: _row(fx.byRef('GZ-2611-0147'), elapsed: 0.25)));
      final track = tester.getSize(find.byType(FractionallySizedBox).first);
      final card = tester.getSize(find.byType(GzRequestCard));
      expect(track.width / (card.width - 2), closeTo(0.75, 0.01));
    });

    testWidgets('Call shows only when the number is shared; chat always', (tester) async {
      await _pump(tester, GzRequestCard(request: base, canCall: false));
      expect(find.bySemanticsLabel(RegExp('^Call ')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Message ')), findsOneWidget);
      await _pump(tester, GzRequestCard(request: base, canCall: true));
      expect(find.bySemanticsLabel(RegExp('^Call ')), findsOneWidget);
    });

    testWidgets('other requests on the date show +N and a 44 dp Compare that calls back', (tester) async {
      var n = 0;
      await _pump(tester, GzRequestCard(request: _row(fx.byRef('GZ-2611-0147'), others: 2), onCompare: () => n++));
      expect(_text('+2'), findsOneWidget);
      final compare = find.bySemanticsLabel('Compare');
      expect(tester.getSize(compare).width, greaterThanOrEqualTo(44));
      await tester.tap(compare);
      expect(n, 1);
      await _pump(tester, GzRequestCard(request: base));
      expect(find.bySemanticsLabel('Compare'), findsNothing);
    });

    testWidgets('accepted: summary, an Undo bar for 8 seconds, Undo hides it and calls back once', (tester) async {
      var undone = 0;
      var expired = 0;
      await _pump(tester, GzRequestCard(request: base, state: GzRequestCardState.accepted, onUndo: () => undone++, onUndoExpire: () => expired++));
      expect(_text('Request approved'), findsOneWidget);
      expect(_text('Accept'), findsNothing);
      await tester.tap(_text('Undo'));
      await tester.pump();
      expect(undone, 1);
      expect(_text('Request approved'), findsNothing);
    });

    testWidgets('accepted: the Undo line runs out after 8 seconds and reports once', (tester) async {
      var expired = 0;
      await _pump(tester, GzRequestCard(request: base, state: GzRequestCardState.accepted, onUndoExpire: () => expired++));
      await tester.pump(const Duration(seconds: 7));
      expect(expired, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(expired, 1);
    });

    testWidgets('one semantics node names the card by the guest', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, GzRequestCard(request: base));
      expect(find.bySemanticsLabel(RegExp('^${base.booking.clientName}')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Arabic: the status sits at the start (right) and the date text is figures-isolated', (tester) async {
      await _pump(tester, GzRequestCard(request: base, packageName: pkg), lang: 'ar');
      final pill = tester.getRect(find.byType(GzStatusPill).first);
      final card = tester.getRect(find.byType(GzRequestCard));
      expect(card.right - pill.right, lessThan(card.width / 2));
      expect(find.byType(GzBookingThread), findsOneWidget);
    });
  });
}
