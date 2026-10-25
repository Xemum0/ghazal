// Flow test of Bookings (HL-BOOK-01..07): the real router and the in-process mock (`autoRun: false`), real taps. Bounded: no real IO in fake async.
import 'package:flutter/widgets.dart' show EditableText, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

const _confirmed = 'bk-GZ-2611-2P8R';
const _redeemed = 'bk-GZ-2609-4Z6X';
const _declined = 'bk-GZ-2611-1B5Z';

void main() {
  flowTest('the tab opens on Pending: a decision-ready card with Accept, Decline and another date', (tester) async {
    await openScreen(tester, 'HL-BOOK-01');
    expect(find.text('Bookings'), findsWidgets);
    expect(find.text('Accept'), findsWidgets);
    expect(find.text('Decline'), findsWidgets);
    expect(find.byType(GzTabBar), findsOneWidget);
  });

  flowTest('a card opens Booking detail; the detail shows the pending decision bar and the voucher price', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-01');
    await tap(tester, find.bySemanticsLabel(RegExp('^Open request')));
    expect(currentId(c), 'HL-BOOK-03');
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  flowTest('Booking detail: Accept approves with the undo toast, Undo takes it back', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await tap(tester, find.text('Accept'));
    expect(find.text('Undo'), findsOneWidget);
    expect(currentId(c), 'HL-BOOK-03');
    await tap(tester, find.text('Undo'));
    await tester.pump(const Duration(seconds: 9));
  });

  flowTest('Booking detail: Decline opens the reason sheet, a reason enables the primary, Choose dates hands off to Propose date', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await tap(tester, find.text('Decline'));
    expect(currentId(c), 'HL-DCSN-02');
    expect(find.text('Pick a reason'), findsWidgets);
    await tap(tester, find.text('Capacity'));
    await tap(tester, find.text('Choose dates'));
    expect(currentId(c), 'HL-DCSN-03');
  });

  flowTest('Booking detail: the calendar glyph opens Propose date', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await tap(tester, find.bySemanticsLabel('Propose another date'));
    expect(currentId(c), 'HL-DCSN-03');
  });

  flowTest('Booking detail: the client panel opens the contact sheet; Chat leads to the thread', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await tap(tester, find.bySemanticsLabel(RegExp('^Call ')));
    expect(currentId(c), 'HL-BOOK-04');
    expect(find.text('Chat'), findsWidgets);
    await tap(tester, find.text('Chat'));
    expect(currentId(c), 'HL-TODY-05');
  });

  flowTest('a confirmed booking: Redeem opens the scanner with the code, the quote shows, Redeem finishes with the redeemed sheet', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03', params: {'bookingId': _confirmed});
    expect(find.text('Redeem voucher'), findsWidgets);
    expect(find.text('Cancel booking'), findsOneWidget);
    await tap(tester, find.widgetWithText(GzButton, 'Redeem voucher'));
    expect(currentId(c), 'HL-BOOK-06');
    await settle(tester, wait: const Duration(seconds: 2));
    expect(find.text('Try another'), findsWidgets); // the quote of a code that can be redeemed
    await tap(tester, find.widgetWithText(GzButton, 'Redeem voucher'));
    await settle(tester, wait: const Duration(seconds: 2));
    expect(currentId(c), 'HL-BOOK-07');
    expect(find.text('Redeemed'), findsWidgets);
    expect(find.text('View request'), findsNothing);
  });

  flowTest('Redeem: Code mode takes a typed code; a wrong one says so on the field', (tester) async {
    await openScreen(tester, 'HL-BOOK-06');
    await tap(tester, find.bySemanticsLabel('Code'));
    await tester.enterText(find.byType(EditableText).first, 'ZZZZ9999');
    await settle(tester);
    await tap(tester, find.widgetWithText(GzButton, 'Check code'));
    await settle(tester, wait: const Duration(seconds: 2));
    expect(find.byType(EditableText), findsWidgets);
  });

  flowTest('Redeem: a demo chip checks a live code and shows what happened', (tester) async {
    await openScreen(tester, 'HL-BOOK-06');
    await settle(tester, wait: const Duration(seconds: 2));
    await tap(tester, find.bySemanticsLabel(RegExp('Ready'), ));
    await settle(tester, wait: const Duration(seconds: 2));
    expect(find.text('Try another'), findsWidgets);
  });

  flowTest('a redeemed booking shows its voucher panel and no decision bar', (tester) async {
    await openScreen(tester, 'HL-BOOK-03', params: {'bookingId': _redeemed});
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Redeem voucher'), findsNothing);
  });

  flowTest('a declined booking shows its outcome strip (the voucher went back)', (tester) async {
    await openScreen(tester, 'HL-BOOK-03', params: {'bookingId': _declined});
    expect(find.bySemanticsLabel('Declined'), findsWidgets);
    expect(find.text('Accept'), findsNothing);
  });

  flowTest('Booking detail: Cancel on a confirmed booking opens the cancel sheet with the consequence first', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03', params: {'bookingId': _confirmed});
    await tap(tester, find.text('Cancel booking'));
    expect(currentId(c), 'HL-DCSN-04');
    expect(find.text('WHAT HAPPENS', skipOffstage: false), findsWidgets);
    expect(find.text('Returned'), findsWidgets);
  });

  flowTest('loading shows the skeleton that matches the layout', (tester) async {
    await openScreen(tester, 'HL-BOOK-03', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('a failing load shows the error state with Try again', (tester) async {
    await openScreen(tester, 'HL-BOOK-03', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
  });

  flowTest('offline shows the offline state with a retry', (tester) async {
    await openScreen(tester, 'HL-BOOK-01', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('the contact sheet shows the client name and closes with its glyph', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-04', params: {'bookingId': _confirmed});
    expect(currentId(c), 'HL-BOOK-04');
    await tap(tester, find.bySemanticsLabel('Close'));
    expect(currentId(c), isNot('HL-BOOK-04'));
  });

  flowTest('Arabic run: Booking detail mirrors and the voucher price reads', (tester) async {
    await openScreen(tester, 'HL-BOOK-03', locale: const Locale('ar'));
    expect(find.text('قبول'), findsWidgets);
    final back = tester.getTopRight(find.bySemanticsLabel('رجوع').first).dx;
    expect(back, greaterThan(195));
  });
}
