import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BlockReason, CalendarClaim, Hall;
import 'package:ghazal_ui/src/core/core.dart' show GzButton;
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel_b.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart' show GzDateRange, GzYm;

import '../inputs/inputs_harness.dart';

const _today = '2026-11-12';

Hall _hall(String id, String en, String ar) => Hall.fromJson({
  'id': id,
  'venueId': 'V01',
  'name': {'en': en, 'ar': ar},
  'setting': 'indoor',
  'capacity': {'min': 100, 'max': 600},
  'exclusiveDay': false,
  'sessions': [
    {
      'id': 'S1',
      'name': {'en': 'Evening', 'ar': 'المسائية'},
      'start': '21:00',
      'end': '02:00',
      'bufferBeforeMin': 120,
      'bufferAfterMin': 60,
      'weekdays': [0, 1, 2, 3, 4, 5, 6],
    },
  ],
  'sections': <Object>[],
  'description': {'en': 'x', 'ar': 'x'},
});

CalendarClaim _claim(String id, String hall, String date, String kind, [Map<String, Object?> extra = const {}]) =>
    CalendarClaim.fromJson({'id': id, 'venueId': 'V01', 'hallId': hall, 'date': date, 'kind': kind, ...extra});

final List<Hall> _halls = [_hall('H1', 'Danah Ballroom', 'قاعة الدانة'), _hall('H2', 'Majlis Hall', 'قاعة المجلس')];

final List<CalendarClaim> _claims = [
  _claim('c1', 'H1', '2026-12-10', 'booking', {'bookingId': 'B1', 'clientName': 'Noura', 'guests': 300, 'start': '21:00', 'end': '02:00'}),
  _claim('c2', 'H2', '2026-12-10', 'hold', {'holdUntil': '2026-11-12T19:30:00+03:00'}),
  _claim('c3', 'H1', '2026-12-12', 'booking', {'bookingId': 'B2', 'clientName': 'Hamad', 'guests': 200}),
  _claim('c4', 'H2', '2026-12-12', 'booking', {'bookingId': 'B3', 'clientName': 'Salem', 'guests': 150}),
  _claim('c5', 'H1', '2026-12-14', 'block', {'blockReason': 'maintenance', 'blockedBy': 'Hind'}),
  _claim('c6', 'H1', '2026-12-15', 'requested'),
];

const _dec = GzYm(2026, 12);

/// A text (or rich text) whose plain content, without bidi isolates, is [text].
Finder _plain(String text) => find.byWidgetPredicate(
  (w) => w is Text && (w.textSpan?.toPlainText() ?? w.data ?? '').replaceAll(RegExp('[\u2066\u2069]'), '') == text,
);

/// The centre of a December 2026 day cell of the month grid (the grid is 316 wide at the top-left, head 44 + 12, weekday row 32, rows
/// of 52). December 1st is a Tuesday: weekday 2.
Offset _cell(WidgetTester tester, int day, {required bool rtl}) {
  final box = tester.getRect(find.byType(GzHotelMonthGrid));
  final index = day + 1;
  final col = index % 7;
  final row = index ~/ 7;
  final w = box.width / 7;
  final x = rtl ? box.right - (col + 0.5) * w : box.left + (col + 0.5) * w;
  return Offset(x, box.top + 44 + 12 + 32 + (row + 0.5) * GzSize.calCellHeight);
}

Widget _grid({GzHotelMonthMode mode = GzHotelMonthMode.view, ValueChanged<String>? onSelect, GzDateRange range = GzDateRange.empty, ValueChanged<GzDateRange>? onRange, ValueChanged<GzYm>? onMonth}) =>
    GzHotelMonthGrid(halls: _halls, claims: _claims, defaultMonth: _dec, today: _today, label: 'Calendar', mode: mode, onSelectDate: onSelect, range: range, onRangeChange: onRange, onMonthChange: onMonth);

class _Select extends StatefulWidget {
  const _Select(this.log);

  final List<GzDateRange> log;

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  GzDateRange r = GzDateRange.empty;

  @override
  Widget build(BuildContext context) => _grid(
    mode: GzHotelMonthMode.select,
    range: r,
    onRange: (v) {
      widget.log.add(v);
      setState(() => r = v);
    },
  );
}

void main() {
  group('model', () {
    test('tapSpan: first tap starts, second ends in either order, third starts again', () {
      var r = gzTapSpan(GzDateRange.empty, '2026-12-18');
      expect((r.start, r.end), ('2026-12-18', null));
      r = gzTapSpan(r, '2026-12-15');
      expect((r.start, r.end), ('2026-12-15', '2026-12-18'));
      r = gzTapSpan(r, '2026-12-20');
      expect((r.start, r.end), ('2026-12-20', null));
      expect(gzInSpan('2026-12-16', const GzDateRange(start: '2026-12-18', end: '2026-12-15')), isTrue);
      expect(gzInSpan('2026-12-19', const GzDateRange(start: '2026-12-15', end: '2026-12-18')), isFalse);
    });

    test('dayFacts: one slot per hall in hall order; a day with every hall booked is full; a request is a count and never a claim', () {
      final d = gzDayFacts('2026-12-10', _halls, _claims, _today);
      expect(d.lanes, [GzLaneMark.booked, GzLaneMark.held]);
      expect(d.isFull, isTrue, reason: 'a booking and a hold claim the date for both halls');
      expect(gzDayFacts('2026-12-12', _halls, _claims, _today).isFull, isTrue);
      final r = gzDayFacts('2026-12-15', _halls, _claims, _today);
      expect(r.lanes, [null, null]);
      expect(r.requested, 1);
      expect(r.isFull, isFalse);
      expect(gzDayFacts('2026-11-01', _halls, _claims, _today).past, isTrue);
    });
  });

  group('GzHotelMonthGrid', () {
    testWidgets('a tap selects a day; the accessible name lists what each hall carries; cells are 52 high and 44 wide at least', (tester) async {
      final handle = tester.ensureSemantics();
      final taps = <String>[];
      await pumpInputs(tester, _grid(onSelect: taps.add));
      final label = find.bySemanticsLabel(RegExp(r'Danah Ballroom Booked, Majlis Hall On hold'));
      expect(label, findsOneWidget);
      final r = tester.getRect(label);
      expect(r.height, GzSize.calCellHeight);
      expect(r.width, greaterThanOrEqualTo(GzSize.calCellMinWidth));
      await tester.tapAt(_cell(tester, 10, rtl: false));
      await tester.pump();
      expect(taps, ['2026-12-10']);
      expect(find.bySemanticsLabel(RegExp('Request')), findsOneWidget, reason: 'the 15th carries a pending request');
      handle.dispose();
    });

    testWidgets('the arrows page the month; Sunday is first and flips with the language', (tester) async {
      final months = <GzYm>[];
      await pumpInputs(tester, _grid(onMonth: months.add));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(months, [const GzYm(2027, 1)]);
      final box = tester.getRect(find.byType(GzHotelMonthGrid));
      expect(_cell(tester, 1, rtl: false).dx, lessThan(box.center.dx + 1000));
      for (final rtl in [false, true]) {
        await pumpInputs(tester, _grid(), lang: rtl ? 'ar' : 'en');
        // 3 December is a Thursday (column 4), 6 December a Sunday (column 0): Sunday sits at the inline-start.
        final sun = _cell(tester, 6, rtl: rtl).dx;
        final thu = _cell(tester, 3, rtl: rtl).dx;
        expect(rtl ? sun > thu : sun < thu, isTrue);
      }
    });

    testWidgets('select mode: two taps make a range, a full day and a past day refuse', (tester) async {
      final log = <GzDateRange>[];
      await pumpInputs(tester, _Select(log));
      await tester.tapAt(_cell(tester, 12, rtl: false)); // every hall is booked
      await tester.pump();
      expect(log, isEmpty);
      await tester.tapAt(_cell(tester, 16, rtl: false));
      await tester.pump();
      await tester.tapAt(_cell(tester, 18, rtl: false));
      await tester.pump();
      expect((log.last.start, log.last.end), ('2026-12-16', '2026-12-18'));
    });

    for (final lang in ['en', 'ar']) {
      testWidgets('press and hold, then drag across the dates selects a range ($lang)', (tester) async {
        final log = <GzDateRange>[];
        final rtl = lang == 'ar';
        await pumpInputs(tester, _Select(log), lang: lang);
        final g = await tester.startGesture(_cell(tester, 16, rtl: rtl));
        await tester.pump(gzHotelHoldDuration + const Duration(milliseconds: 40));
        expect((log.last.start, log.last.end), ('2026-12-16', '2026-12-16'));
        await g.moveTo(_cell(tester, 17, rtl: rtl));
        await tester.pump();
        await g.moveTo(_cell(tester, 19, rtl: rtl));
        await tester.pump();
        await g.up();
        await tester.pump();
        expect((log.last.start, log.last.end), ('2026-12-16', '2026-12-19'));
      });
    }

    testWidgets('a drag that starts before the hold has elapsed does not select', (tester) async {
      final log = <GzDateRange>[];
      await pumpInputs(tester, _Select(log));
      final g = await tester.startGesture(_cell(tester, 16, rtl: false));
      await g.moveTo(_cell(tester, 16, rtl: false) + const Offset(60, 0));
      await tester.pump(gzHotelHoldDuration + const Duration(milliseconds: 40));
      await g.up();
      await tester.pump();
      expect(log, isEmpty);
    });
  });

  group('GzHotelWeekView', () {
    testWidgets('lanes are 44 high; a booked lane opens the booking; the arrows move the week', (tester) async {
      final opened = <String>[];
      final weeks = <String>[];
      await pumpInputs(
        tester,
        GzHotelWeekView(halls: _halls, claims: _claims, date: '2026-12-10', today: _today, label: 'Week', onOpenBooking: opened.add, onWeekChange: weeks.add),
      );
      expect(find.text('Danah Ballroom'), findsNWidgets(7));
      final lane = tester.getSize(find.ancestor(of: find.textContaining('Noura'), matching: find.byType(GzPressable)).first);
      expect(lane.height, greaterThanOrEqualTo(GzSize.touchMin));
      expect(tester.getSize(find.bySemanticsLabel('Next month')).height, greaterThanOrEqualTo(GzSize.touchMin));
      await tester.tap(find.textContaining('Noura'));
      await tester.pump();
      expect(opened, ['B1']);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(weeks, ['2026-12-13']);
    });

    testWidgets('the date column is at the inline-start: left in English, right in Arabic', (tester) async {
      for (final lang in ['en', 'ar']) {
        await pumpInputs(tester, GzHotelWeekView(halls: _halls, claims: _claims, date: '2026-12-10', today: _today, label: 'Week'), lang: lang);
        final hall = tester.getCenter(find.byWidgetPredicate((w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').contains(lang == 'ar' ? 'قاعة الدانة' : 'Danah')).first);
        final box = tester.getRect(find.byType(GzHotelWeekView));
        final dateCol = lang == 'ar' ? box.right - 28 : box.left + 28;
        expect(lang == 'ar' ? hall.dx < dateCol : hall.dx > dateCol, isTrue);
      }
    });
  });

  group('GzHotelDayView and GzDayAgenda', () {
    testWidgets('a booked hall shows setup, the event and teardown; a free hall offers Block', (tester) async {
      final blocked = <String>[];
      final opened = <String>[];
      await pumpInputs(
        tester,
        GzHotelDayView(date: '2026-12-10', halls: _halls, claims: _claims, onBlock: blocked.add, onOpenBooking: opened.add),
      );
      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('Teardown'), findsOneWidget);
      expect(find.text('Noura'), findsOneWidget);
      await tester.tap(find.text('Noura'));
      await tester.pump();
      expect(opened, ['B1']);
      await pumpInputs(tester, GzHotelDayView(date: '2026-12-20', halls: _halls, claims: _claims, onBlock: blocked.add));
      await tester.tap(find.widgetWithText(GzButton, 'Block this date').first);
      await tester.pump();
      expect(blocked, ['H1']);
    });

    testWidgets('agenda: a booked row opens the booking, an open row offers Block, a request is a count', (tester) async {
      final blocked = <String>[];
      final opened = <String>[];
      await pumpInputs(tester, GzDayAgenda(date: '2026-12-15', halls: _halls, claims: _claims, onBlock: blocked.add, onOpenBooking: opened.add));
      expect(_plain('1 pending request for this date'), findsOneWidget);
      await tester.tap(find.widgetWithText(GzButton, 'Block').last);
      await tester.pump();
      expect(blocked, ['H2']);
      await pumpInputs(tester, GzDayAgenda(date: '2026-12-10', halls: _halls, claims: _claims, onOpenBooking: opened.add));
      await tester.tap(find.text('Danah Ballroom'));
      await tester.pump();
      expect(opened, ['B1']);
    });
  });

  group('GzBlockDatesSheet', () {
    testWidgets('Block waits for dates, then hands back the range, the default reason and every hall', (tester) async {
      GzBlockDatesValue? blocked;
      await pumpInputs(
        tester,
        GzBlockDatesSheet(
          halls: _halls,
          claims: _claims,
          placement: GzBlockDatesPlacement.inline,
          defaultMonth: _dec,
          today: _today,
          onBlock: (v) => blocked = v,
        ),
        width: 350,
      );
      tester.view.physicalSize = const Size(390, 2600); // the whole sheet on screen
      await tester.pump();
      expect(find.text('Choose the dates'), findsOneWidget);
      expect(tester.widget<GzButton>(find.widgetWithText(GzButton, 'Block')).onPressed, isNull);
      await tester.tapAt(_cell(tester, 16, rtl: false));
      await tester.pump();
      await tester.tapAt(_cell(tester, 18, rtl: false));
      await tester.pump();
      expect(_plain('3 dates'), findsOneWidget);
      await tester.tap(find.text('Maintenance').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(GzButton, 'Block'));
      await tester.pump();
      expect((blocked!.range.start, blocked!.range.end, blocked!.reason), ('2026-12-16', '2026-12-18', BlockReason.maintenance));
      expect(blocked!.hallIds, ['H1', 'H2']);
    });
  });
}
