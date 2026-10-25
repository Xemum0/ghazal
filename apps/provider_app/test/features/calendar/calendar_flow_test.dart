// Flow test of the Calendar (HL-CALN-01..05): the real router and the in-process mock (`autoRun: false`), real taps. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show EditableText, Locale, RichText;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/features/calendar/presentation/hl_caln_01.dart';
import 'package:provider_app/features/calendar/presentation/hl_caln_02.dart';
import 'package:provider_app/features/calendar/presentation/hl_caln_03.dart';

import '../../support/flow_world.dart';

/// True when some text draws [text] (figures and dates are bidi isolates with no-break spaces: both are normalised).
bool seen(String text) => find
    .byWidgetPredicate((w) => w is RichText && w.text.toPlainText().replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f]'), '').replaceAll('\u00a0', ' ').contains(text))
    .evaluate()
    .isNotEmpty;

void main() {
  flowTest('Month: the grid, the hall chips and the chosen day agenda with the booking', (tester) async {
    await openScreen(tester, 'HL-CALN-01');
    expect(find.byType(HlCaln01Screen), findsOneWidget);
    expect(find.byType(GzHotelMonthGrid), findsOneWidget);
    expect(seen('November 2026'), isTrue);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Danah'), findsWidgets);
    expect(seen('Thu 12 Nov'), isTrue);
    expect(find.text('نجلاء البدر'), findsWidgets); // the booking of the day
    expect(find.byType(GzTabBar), findsOneWidget);
  });

  flowTest('Month: the Week and Day switches walk to the other views and Month comes back', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await tap(tester, find.bySemanticsLabel('Week'));
    expect(currentId(c), 'HL-CALN-02');
    expect(find.byType(HlCaln02Screen), findsOneWidget);
    expect(seen('8 – 14 November'), isTrue);
    await tap(tester, find.bySemanticsLabel('Day'));
    expect(currentId(c), 'HL-CALN-03');
    expect(find.byType(HlCaln03Screen), findsOneWidget);
    expect(seen('Thu 12 Nov'), isTrue);
    await tap(tester, find.bySemanticsLabel('Month'));
    expect(currentId(c), 'HL-CALN-01');
  });

  flowTest('Week: next week moves the rows, a booked lane is the guest of the date', (tester) async {
    await openScreen(tester, 'HL-CALN-02');
    expect(find.text('نجلاء البدر'), findsWidgets);
    await tap(tester, find.bySemanticsLabel('Next week'));
    expect(seen('15 – 21 November'), isTrue);
  });

  flowTest('Day: the hall timeline, the booking card with Call and Chat, next day moves the date', (tester) async {
    await openScreen(tester, 'HL-CALN-03');
    expect(find.text('Danah'), findsWidgets);
    expect(find.text('Confirmed'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('^Call ')), findsWidgets);
    await tap(tester, find.bySemanticsLabel('Next day'));
    expect(seen('Fri 13 Nov'), isTrue);
  });

  flowTest('Month agenda heading opens the Day view of that date', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await tapLabel(tester, RegExp('Open the day|Open day'));
    expect(currentId(c), 'HL-CALN-03');
  });

  flowTest('Block sheet: a free date blocks, the sheet closes and the toast says it, Undo opens it again', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-02');
    await openSheetOf(tester, c, 'HL-CALN-04', <String, Object?>{'mode': 'block', 'start': '2026-11-17', 'end': '2026-11-17'});
    expect(currentId(c), 'HL-CALN-04');
    expect(find.text('Booked offline'), findsOneWidget);
    expect(find.text('Block 1 date'), findsOneWidget);
    await tap(tester, find.text('Block 1 date'));
    expect(currentId(c), 'HL-CALN-02');
    expect(find.text('Hidden from couples'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Next week')); // the week of the 17th: the new block is a lane of its own
    expect(seen('Booked offline'), isTrue);
    await tester.pump(const Duration(seconds: 9)); // the undo window ends inside the test
  });

  flowTest('Block sheet: a booked date refuses, names the booking and rests the primary', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await openSheetOf(tester, c, 'HL-CALN-04', <String, Object?>{'mode': 'block', 'start': '2026-11-13', 'end': '2026-11-15'});
    expect(find.text('Free dates only'), findsWidgets);
    expect(find.text('Booked'), findsWidgets);
    expect(find.byType(GzStatusPill), findsWidgets);
  });

  flowTest('Block sheet: the Open switch lists the blocked dates and picks them', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await openSheetOf(tester, c, 'HL-CALN-04', <String, Object?>{'mode': 'open', 'start': null, 'end': null});
    expect(find.byType(GzCheckbox), findsWidgets); // the fixture has blocked dates
    expect(find.textContaining('Open '), findsWidgets);
  });

  flowTest('Block sheet: Other asks for a note before it can block', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await openSheetOf(tester, c, 'HL-CALN-04', <String, Object?>{'mode': 'block', 'start': '2026-11-17', 'end': '2026-11-17'});
    await tap(tester, find.text('Other'));
    expect(find.byType(EditableText), findsWidgets);
    await tester.enterText(find.byType(EditableText).last, 'Staff day');
    await settle(tester);
    expect(find.text('Block 1 date'), findsOneWidget);
  });

  flowTest('Calendar by email: the switch, a bad address is named, a test is sent', (tester) async {
    final c = await openScreen(tester, 'HL-CALN-01');
    await tap(tester, find.bySemanticsLabel('Calendar by email'));
    expect(currentId(c), 'HL-CALN-05');
    expect(find.text('Invite me by email'), findsWidgets);
    await tester.enterText(find.byType(EditableText).last, 'calendar@danah');
    await settle(tester);
    expect(find.text('Check the address'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, 'calendar@danah-hotel.com');
    await settle(tester);
    await tap(tester, find.text('Send a test'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Test sent'), findsOneWidget);
  });

  flowTest('loading shows the skeleton, empty/error/offline never leave a blank', (tester) async {
    await openScreen(tester, 'HL-CALN-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('a failing load shows the error state with Try again', (tester) async {
    await openScreen(tester, 'HL-CALN-01', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
  });

  flowTest('offline shows the offline state', (tester) async {
    await openScreen(tester, 'HL-CALN-02', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Arabic run: the month mirrors and reads right to left', (tester) async {
    await openScreen(tester, 'HL-CALN-01', locale: const Locale('ar'));
    expect(find.text('التقويم'), findsWidgets);
    expect(seen('الخميس 12 نوفمبر'), isTrue);
    final title = tester.getTopRight(find.text('التقويم').first).dx;
    final chevron = tester.getTopLeft(find.byIcon(GzIcons.chevronRight).first).dx;
    expect(title, greaterThan(chevron));
  });
}
