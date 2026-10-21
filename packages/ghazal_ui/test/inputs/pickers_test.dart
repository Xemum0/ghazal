import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart' show GzBead;
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import 'inputs_harness.dart';

/// Pumps and lets the entrance fade finish (a fading body is excluded from semantics until it shows).
Future<void> pumpWarm(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 350}) async {
  await pumpInputs(tester, child, lang: lang, reduceMotion: reduceMotion, width: width);
  await tester.pump(const Duration(milliseconds: 300));
}

const _today = '2026-11-12';
const _jan = GzYm(2027, 1);

Map<String, GzCalendarDayInfo> _days() => const {
  '2027-01-07': GzCalendarDayInfo(status: GzDayStatus.booked, price: 47000),
  '2027-01-15': GzCalendarDayInfo(status: GzDayStatus.held, price: 49000),
  '2027-01-22': GzCalendarDayInfo(status: GzDayStatus.blocked),
  '2027-01-14': GzCalendarDayInfo(price: 49000),
};

Finder day(String label) => find.bySemanticsLabel(RegExp('^$label'));

void main() {
  group('GzCalendar', () {
    testWidgets('Sunday first: the header starts with Sun, January 2027 starts on a Friday, 44 wide at least and 52 high', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWarm(tester, const GzCalendar(defaultMonth: _jan, today: _today, minDate: _today));
      final sun = tester.getCenter(find.bySemanticsLabel('Sunday'));
      final sat = tester.getCenter(find.bySemanticsLabel('Saturday'));
      expect(sun.dx, lessThan(sat.dx));
      final fri1 = tester.getRect(day('Friday 1 January 2027'));
      final thu31 = tester.getRect(day('Sunday 3 January 2027'));
      // Day 1 is the sixth column; day 3 (a Sunday) is the first column of the next row.
      expect(fri1.left, greaterThan(thu31.left + 200));
      expect(fri1.height, GzSize.calCellHeight);
      expect(fri1.width, greaterThanOrEqualTo(GzSize.calCellMinWidth));
      handle.dispose();
    });

    testWidgets('the Thu to Sat band is one tinted block at the inline-end edge: right in English, left in Arabic', (tester) async {
      for (final lang in ['en', 'ar']) {
        await pumpWarm(
          tester,
          const GzCalendar(defaultMonth: _jan, today: _today),
          lang: lang,
        );
        final tint = find.byWidgetPredicate(
          (w) =>
              w is Container && (w.decoration as BoxDecoration?)?.color == GzColors.light.surfaceTintSoft && w.constraints?.maxHeight == 32,
        );
        expect(tint, findsNWidgets(3), reason: '$lang: three tinted weekday headers');
        final rects = [for (var i = 0; i < 3; i++) tester.getRect(tint.at(i))];
        final cx = rects.map((r) => r.center.dx).reduce((a, b) => a + b) / 3;
        if (lang == 'en') {
          expect(cx, greaterThan(350 * 0.6));
        } else {
          expect(cx, lessThan(350 * 0.4));
        }
      }
    });

    testWidgets('single selection: taps choose, a second tap clears; booked, blocked and past days cannot be chosen', (tester) async {
      final handle = tester.ensureSemantics();
      final picks = <String?>[];
      await pumpWarm(tester, GzCalendar(days: _days(), defaultMonth: _jan, today: _today, minDate: _today, onChanged: picks.add));
      await tester.tap(day('Thursday 14 January 2027'));
      await tester.pump();
      expect(picks, ['2027-01-14']);
      await tester.tap(day('Thursday 14 January 2027'));
      await tester.pump();
      expect(picks.last, isNull);
      await tester.tap(day('Thursday 7 January 2027'), warnIfMissed: false);
      await tester.tap(day('Friday 22 January 2027'), warnIfMissed: false);
      await tester.pump();
      expect(picks, hasLength(2));
      await tester.tap(day('Friday 15 January 2027')); // held stays selectable (requests allowed)
      await tester.pump();
      expect(picks.last, '2027-01-15');
      handle.dispose();
    });

    testWidgets('semantics: status, price (Prices view), today and the selected state are spoken', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWarm(
        tester,
        GzCalendar(
          days: _days(),
          defaultMonth: const GzYm(2026, 11),
          today: _today,
          defaultView: GzCalendarView.prices,
          defaultValue: '2026-11-20',
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Thursday 12 November 2026.*Today')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Friday 20 November 2026.*Selected')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Monday 2 November 2026.*Past')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('range: start then end draws the thread between; an earlier second tap restarts; a range may not swallow a booked day', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final ranges = <GzDateRange>[];
      await pumpWarm(tester, GzCalendar.range(days: _days(), defaultMonth: _jan, today: _today, onChanged: ranges.add));
      await tester.tap(day('Sunday 3 January 2027'));
      await tester.pump();
      expect(ranges.last, const GzDateRange(start: '2027-01-03'));
      await tester.tap(day('Wednesday 6 January 2027'));
      await tester.pump();
      expect(ranges.last, const GzDateRange(start: '2027-01-03', end: '2027-01-06'));
      // The thread: one segment per in-range cell (start, 2 middles, end), drawing on over 200 ms.
      final threads = find.byType(TweenAnimationBuilder<double>);
      expect(threads, findsNWidgets(4));
      await tester.tap(day('Monday 4 January 2027')); // a third tap restarts from the tapped day
      await tester.pump();
      expect(ranges.last, const GzDateRange(start: '2027-01-04'));
      await tester.tap(day('Saturday 9 January 2027')); // Jan 7 is booked in between: restart there
      await tester.pump();
      expect(ranges.last, const GzDateRange(start: '2027-01-09'));
      handle.dispose();
    });

    testWidgets(
      'month paging: next goes forward at the inline-end side; the arrows swap sides in Arabic; the first month stops at minDate',
      (tester) async {
        final handle = tester.ensureSemantics();
        final months = <GzYm>[];
        await pumpWarm(tester, GzCalendar(defaultMonth: _jan, today: _today, minDate: '2027-01-01', onMonthChange: months.add));
        final prevEn = tester.getCenter(find.bySemanticsLabel('Previous month')).dx;
        final nextEn = tester.getCenter(find.bySemanticsLabel('Next month')).dx;
        expect(prevEn, lessThan(nextEn));
        await tester.tap(find.bySemanticsLabel('Next month'));
        await tester.pump();
        expect(months.last, const GzYm(2027, 2));
        expect(find.textContaining('February'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Previous month'));
        await tester.pump();
        expect(months.last, _jan);
        // At the first selectable month, previous is disabled.
        final before = months.length;
        await tester.tap(find.bySemanticsLabel('Previous month'), warnIfMissed: false);
        await tester.pump();
        expect(months.length, before);
        handle.dispose();
      },
    );

    testWidgets('Arabic: previous month sits at the start (right), next at the left', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWarm(
        tester,
        const GzCalendar(defaultMonth: _jan, today: _today),
        lang: 'ar',
      );
      final prev = tester.getCenter(find.bySemanticsLabel('الشهر السابق')).dx;
      final next = tester.getCenter(find.bySemanticsLabel('الشهر التالي')).dx;
      expect(prev, greaterThan(next));
      handle.dispose();
    });

    testWidgets('the Availability | Prices toggle appears when days have prices and shows the per-day price with its unit', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWarm(tester, GzCalendar(days: _days(), defaultMonth: _jan, today: _today, priceBasis: 'KD · per guest'));
      expect(find.text('KD · per guest'), findsNothing);
      await tester.tap(find.text('Prices'));
      await settle(tester);
      expect(find.text('KD · per guest'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the legend lists the states of the visible month', (tester) async {
      await pumpWarm(tester, GzCalendar(days: _days(), defaultMonth: _jan, today: _today));
      expect(find.byType(GzCalendarLegendItem), findsNWidgets(4)); // held, booked, blocked, peak
    });
  });

  group('GzTimeSlotPicker', () {
    List<GzTimeSession> sessions() => const [
      GzTimeSession(id: 'afternoon', label: 'Afternoon', start: GzTimeOfDay(12, 0), end: GzTimeOfDay(16, 0), price: 38000),
      GzTimeSession(
        id: 'evening',
        label: 'Evening',
        start: GzTimeOfDay(21, 0),
        end: GzTimeOfDay(2, 0),
        price: 49000,
        status: GzSessionStatus.held,
      ),
      GzTimeSession(
        id: 'full',
        label: 'Full day',
        start: GzTimeOfDay(12, 0),
        end: GzTimeOfDay(2, 0),
        price: 72000,
        status: GzSessionStatus.booked,
      ),
    ];

    testWidgets('choosing a session selects it (ink border, gold bead); held stays selectable, booked does not', (tester) async {
      final picks = <String?>[];
      await pumpWarm(
        tester,
        GzTimeSlotPicker(sessions: sessions(), date: '2027-01-14', priceUnit: 'per guest', onChanged: picks.add),
        width: 700,
      );
      expect(find.byType(GzBead), findsNothing);
      await tester.tap(find.text('Evening'));
      await tester.pump();
      expect(picks, ['evening']);
      expect(find.byType(GzBead), findsOneWidget);
      await tester.tap(find.text('Full day'), warnIfMissed: false);
      await tester.pump();
      expect(picks, ['evening']);
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('On hold'), findsOneWidget);
    });

    testWidgets('semantics: a radio group; the checked item is the chosen one; an after-midnight range is spoken', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWarm(tester, GzTimeSlotPicker(sessions: sessions(), date: '2027-01-14', defaultValue: 'afternoon'), width: 700);
      final n = tester.getSemantics(find.bySemanticsLabel(RegExp('^Afternoon')));
      expect(n.flagsCollection.isChecked, isNotNull);
      expect(find.bySemanticsLabel(RegExp('^Evening.*On hold')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled: nothing can be chosen', (tester) async {
      final picks = <String?>[];
      await pumpWarm(tester, GzTimeSlotPicker(sessions: sessions(), disabled: true, onChanged: picks.add), width: 700);
      await tester.tap(find.text('Afternoon'), warnIfMissed: false);
      expect(picks, isEmpty);
    });
  });

  group('select and date field', () {
    testWidgets('select row: shows the chosen label(s), the count for many, and opens through onTap', (tester) async {
      var taps = 0;
      const opts = [
        GzSelectOption(value: 'a', label: 'Salmiya'),
        GzSelectOption(value: 'b', label: 'Hawalli'),
        GzSelectOption(value: 'c', label: 'Mishref'),
      ];
      await pumpWarm(tester, GzSelectRow<String>(label: 'Area', placeholder: 'Choose an area', options: opts, onTap: () => taps++));
      expect(find.text('Choose an area'), findsOneWidget);
      await tester.tap(find.text('Choose an area'));
      expect(taps, 1);
      await pumpWarm(tester, GzSelectRow<String>(label: 'Area', options: opts, values: const ['a', 'c'], onTap: () => taps++));
      expect(find.text('Salmiya and Mishref'), findsOneWidget);
      await pumpWarm(tester, GzSelectRow<String>(label: 'Area', options: opts, values: const ['a', 'b', 'c'], onTap: () {}));
      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('picker list: Arabic-aware search, aliases, disabled options and the empty state', (tester) async {
      final picked = <String>[];
      await pumpWarm(
        tester,
        GzPickerList<String>(
          searchable: true,
          selected: const ['a'],
          onPick: picked.add,
          options: const [
            GzSelectOption(value: 'a', label: 'السالمية', aliases: 'Salmiyah'),
            GzSelectOption(value: 'b', label: 'حولي'),
            GzSelectOption(value: 'c', label: 'الجهراء', disabled: true),
          ],
        ),
      );
      expect(find.text('حولي'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'salmiyah');
      await tester.pump();
      expect(find.text('حولي'), findsNothing);
      await tester.tap(find.text('السالمية'));
      expect(picked, ['a']);
      await tester.enterText(find.byType(EditableText), 'سالميه'); // no al-, ta marbuta spelled as ha
      await tester.pump();
      expect(find.text('السالمية'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('search normalisation: tashkeel, alef forms, ya and the article', (tester) async {
      expect(gzSearchKey('السَّالمِيَّة'), gzSearchKey('سالميه'));
      expect(gzMatchesSearch('اسالمية', 'إسالمية'), isTrue);
      expect(gzMatchesSearch('٣', 'Hall 3'), isTrue);
    });

    testWidgets('date field: shows the date (and the range), the placeholder when empty, and opens through onTap', (tester) async {
      var taps = 0;
      await pumpWarm(tester, GzDateField(label: 'Wedding date', onTap: () => taps++));
      expect(find.text('Choose a date'), findsOneWidget);
      await tester.tap(find.text('Choose a date'));
      expect(taps, 1);
      await pumpWarm(
        tester,
        const GzDateField.range(
          label: 'Blocked',
          value: GzDateRange(start: '2027-01-03', end: '2027-01-06'),
          onTap: null,
        ),
      );
      expect(find.textContaining('to'), findsWidgets);
    });

    testWidgets('date sheet content: Confirm is disabled with its reason until a date is chosen, then commits the draft', (tester) async {
      final handle = tester.ensureSemantics();
      final confirmed = <String?>[];
      await pumpWarm(tester, GzDateFieldSheetContent(onConfirm: confirmed.add, today: _today, minDate: _today, hijri: false));
      expect(find.text('Choose a date'), findsOneWidget); // the disabled reason under Confirm
      await tester.tap(find.text('Confirm'), warnIfMissed: false);
      expect(confirmed, isEmpty);
      await tester.tap(day('Friday 20 November 2026'));
      await tester.pump();
      expect(find.text('Choose a date'), findsNothing);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(confirmed, ['2026-11-20']);
      handle.dispose();
    });
  });
}
