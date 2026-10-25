// Flow test of Decisions (HL-DCSN-01..04): the real router and the in-process mock (`autoRun: false`), real taps. Bounded, no real IO in fake async.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

const _confirmed = 'bk-GZ-2611-2P8R';
const _hero = <String, Object?>{'bookingId': 'bk-GZ-2611-0147'};

void main() {
  flowTest('Accept sheet: the consequence reads first, Accept approves and shows the Approved state with the undo hint', (tester) async {
    final c = await openScreen(tester, 'HL-DCSN-01', params: _hero);
    expect(currentId(c), 'HL-DCSN-01');
    expect(find.text('Accept request'), findsWidgets);
    expect(find.text('Accept'), findsWidgets);
    await tap(tester, find.text('Accept').last);
    expect(find.text('Approved'), findsWidgets);
    expect(find.text('Undo'), findsWidgets);
    await tester.pump(const Duration(seconds: 9));
  });

  flowTest('Decline sheet: the primary waits for a reason, a reason lets it decline and the sheet closes', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await openSheetOf(tester, c, 'HL-DCSN-02', _hero);
    expect(find.text('Pick a reason'), findsWidgets);
    expect(find.text('Voucher returns'), findsWidgets);
    await tap(tester, find.text('Capacity'));
    await tap(tester, find.text('Suggest dates'));
    await tap(tester, find.text('Decline').last, flush: true);
    expect(currentId(c), isNot('HL-DCSN-02'));
  });

  flowTest('Decline sheet: Choose dates hands off to Propose date', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await openSheetOf(tester, c, 'HL-DCSN-02', _hero);
    await tap(tester, find.text('Date'));
    await tap(tester, find.text('Choose dates'));
    expect(currentId(c), 'HL-DCSN-03');
  });

  flowTest('Propose date: Send proposal waits for a date, a free date enables it, sending shows Proposal sent and Done closes', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await openSheetOf(tester, c, 'HL-DCSN-03', _hero);
    expect(find.text('Propose date'), findsWidgets);
    expect(find.text('Pick a date'), findsWidgets);
    await tapLabel(tester, RegExp('Free'), ms: 400);
    expect(find.text('Pick a date'), findsNothing);
    await tap(tester, find.text('Send proposal'), flush: true);
    expect(find.text('Proposal sent'), findsWidgets);
    await tap(tester, find.text('Done'));
    expect(currentId(c), isNot('HL-DCSN-03'));
  });

  flowTest('Cancel sheet: consequence first, a reason and the confirm dialog cancel a confirmed booking', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await openSheetOf(tester, c, 'HL-DCSN-04', {'bookingId': _confirmed});
    expect(find.text('WHAT HAPPENS', skipOffstage: false), findsWidgets);
    await tap(tester, find.text('Unavailable'));
    await tap(tester, find.text('Cancel booking').last);
    expect(find.text('Cancel booking?'), findsWidgets);
    await tap(tester, find.text('Cancel booking').last, flush: true);
    expect(currentId(c), 'HL-DCSN-04');
    expect(find.text('Keep booking'), findsNothing);
  });

  flowTest('Cancel sheet: Keep booking only closes the sheet', (tester) async {
    final c = await openScreen(tester, 'HL-BOOK-03');
    await openSheetOf(tester, c, 'HL-DCSN-04', {'bookingId': _confirmed});
    await tap(tester, find.text('Keep booking'));
    expect(currentId(c), isNot('HL-DCSN-04'));
  });

  flowTest('loading shows a skeleton', (tester) async {
    await openScreen(tester, 'HL-DCSN-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('a failing load shows the error state with Try again', (tester) async {
    await openScreen(tester, 'HL-DCSN-02', state: 'error');
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('offline shows the offline state', (tester) async {
    await openScreen(tester, 'HL-DCSN-01', state: 'offline');
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('Arabic run: the Accept sheet reads in Arabic', (tester) async {
    await openScreen(tester, 'HL-DCSN-01', locale: const Locale('ar'));
    expect(find.text('قبول'), findsWidgets);
  });
}
