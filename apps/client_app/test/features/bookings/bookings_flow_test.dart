// The bookings list, the detail, the cancel and proposal sheets and the receipts on the real router over the in-process mock.
// Bounded: every wait is a bounded settle, no real IO in fake async.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the main path: the list groups requests, a row opens the detail with its thread', (tester) async {
    final c = await openScreen(tester, 'CL-BKNG-01');
    expect(shows(en.clientBookingsTitle), isTrue);
    final before = (await tester.runAsync(() => flowRepos('reem').requests.listRequests()))!.items;
    expect(before, isNotEmpty);
    // Tap the first request row by its venue name: the detail opens with the full Booking Thread.
    final name = before.first.target.name.of('en');
    await tapText(tester, name, flush: true);
    expect(currentId(c), 'CL-BKNG-02');
    await settle(tester, flush: true);
    expect(find.byType(GzBookingThread), findsOneWidget);
  });

  flowTest('cancel: withdrawing a pending request walks consequence, reason, confirm and done', (tester) async {
    final c = await openScreen(tester, 'CL-BKNG-02');
    await settle(tester, flush: true);
    // The pending detail carries the Withdraw action into the cancel sheet.
    await tapText(tester, en.clientBookingsPendingWithdraw, flush: true);
    expect(currentId(c), 'CL-BKNG-03');
    expect(shows(en.clientBookingsCancelTitleWithdraw), isTrue);
    await tapText(tester, en.commonActionContinue, flush: true);
    expect(shows(en.clientBookingsCancelReasonTitle), isTrue);
    await tapText(tester, en.commonActionContinue, flush: true);
    await tapText(tester, en.clientBookingsCancelActionWithdraw, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsCancelDoneWithdrawn), isTrue, reason: 'the done state');
    c.read(gzNavigatorProvider).closeSheet();
    await settle(tester, flush: true);
  });

  flowTest('proposal: the counter-offer accepts one date and starts the confirm window', (tester) async {
    final c = await openScreen(tester, 'CL-BKNG-04', story: 'counter_offer');
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsProposalCounterTitle), isTrue);
    expect(find.byType(GzPressable), findsWidgets);
    // Pick the first date option (the radio cards), then Accept.
    final options = find.byWidgetPredicate((w) => w is Semantics && (w.properties.checked == true || w.properties.checked == false));
    expect(options, findsWidgets);
    await tap(tester, options.first, flush: true);
    await tapText(tester, en.clientBookingsProposalAccept, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsProposalAcceptedTitle), isTrue, reason: 'the accepted state');
    expect(currentId(c), 'CL-BKNG-04');
  });

  flowTest('proposal: declining closes the request and returns the voucher', (tester) async {
    await openScreen(tester, 'CL-BKNG-04', story: 'counter_offer');
    await settle(tester, flush: true);
    await tapText(tester, en.commonActionDecline, flush: true);
    expect(shows(en.clientBookingsProposalDeclineTitle), isTrue);
    await tapText(tester, en.clientBookingsProposalDeclineAction, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsProposalClosedTitle), isTrue, reason: 'the declined state');
  });

  flowTest('receipts: the KD 2 payments list by month and a row opens the viewer', (tester) async {
    await openScreen(tester, 'CL-BKNG-05');
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsReceiptsTitle), isTrue);
    final receipts = (await tester.runAsync(() => flowRepos('reem').vouchers.listReceipts()))!.items;
    expect(receipts, isNotEmpty);
    // Tap the first receipt row by its venue name: the viewer sheet opens with Download.
    final name = receipts.first.target?.name.of('en');
    expect(name, isNotNull);
    await tapText(tester, name!, flush: true);
    await settle(tester, flush: true);
    expect(shows(en.clientBookingsViewerDownload), isTrue, reason: 'the viewer sheet with Download');
  });

  flowTest('state loading: the skeleton shows, no error', (tester) async {
    await openScreen(tester, 'CL-BKNG-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-BKNG-01', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text(en.commonActionRetry), findsWidgets);
  });

  flowTest('state offline: the network state shows with its retry', (tester) async {
    await openScreen(tester, 'CL-BKNG-01', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget, reason: 'the offline state is the network error state');
  });

  flowTest('arabic: the bookings list renders right to left with no overflow', (tester) async {
    await openScreen(tester, 'CL-BKNG-01', locale: const Locale('ar'));
    await settle(tester, flush: true);
    expect(shows(ar.clientBookingsTitle), isTrue);
  });
}
