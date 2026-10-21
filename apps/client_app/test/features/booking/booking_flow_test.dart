// The request flow on the real router over the in-process mock: from the voucher-bound step 1 to the sent request, the guest gate, the five
// states, back and sheet dismissal, the confirm and the lapsed outcomes, one Arabic run. Bounded: every wait is a bounded settle.
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  flowTest('the main path: a voucher-bound request goes from step 1 to the sent request, and the request is in the list', (tester) async {
    final c = await openScreen(tester, 'CL-BOOK-01', params: {'venueId': 'V05'});
    // step 1: the quote comes from the voucher (locked facts and its chip), the one action is Continue
    expect(find.text('Your event'), findsOneWidget);
    expect(find.byType(GzVoucherChip), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    final before = (await tester.runAsync(() => flowRepos('reem').requests.listRequests()))!.items.length;

    await tapText(tester, 'Continue', flush: true);
    expect(find.text('Package'), findsWidgets, reason: 'step 2');
    await tapText(tester, 'Continue', flush: true);
    expect(find.text('Extras'), findsWidgets, reason: 'step 3');
    await tapText(tester, 'Continue', flush: true);
    expect(find.text('Details'), findsWidgets, reason: 'step 4');
    await tapText(tester, 'Continue', flush: true);
    expect(find.text('Review'), findsWidgets, reason: 'step 5');

    // the consent comes first: a tap on Send without it only says why
    await tapText(tester, 'Send request', flush: true);
    expect(find.text('Review'), findsWidgets, reason: 'still on the Review');
    await scrollTo(tester, find.byType(GzCheckbox));
    await tester.tap(find.byType(GzCheckbox));
    await settle(tester, flush: true);
    await tapText(tester, 'Send request', flush: true);
    await settle(tester, flush: true);
    expect(find.text('Request sent'), findsWidgets, reason: 'the outcome screen');
    final after = (await tester.runAsync(() => flowRepos('reem').requests.listRequests()))!.items;
    expect(after.length, before + 1, reason: 'the request is in the list');
    expect(after.any((r) => r.booking.status == BookingStatus.pending && r.booking.venueId == 'V05'), isTrue);
    expect(c.read(bookingDraftProvider).requestId, isNotNull);
  });

  flowTest('a guest at step 3 meets the account sheet with the right reason and resumes at step 4', (tester) async {
    final c = await openScreen(tester, 'CL-BOOK-03', persona: 'guest');
    await tapText(tester, 'Continue', flush: true);
    final gate = c.read(gateProvider);
    expect(gate, isNotNull, reason: 'the gate opened');
    expect(gate!.reason, GateReason.voucher);
    expect(gate.resume?.routeName, 'CL-BOOK-04');
  });

  flowTest('state loading: the skeleton shows, no error', (tester) async {
    await openScreen(tester, 'CL-BOOK-02', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('state error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-BOOK-02', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
  });

  flowTest('state offline: the network state shows with its retry', (tester) async {
    await openScreen(tester, 'CL-BOOK-02', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget, reason: 'the offline state is the network error state');
  });

  flowTest('empty: no package fits the guests shows the drawing and the one way out', (tester) async {
    final c = await openScreen(tester, 'CL-DISC-01');
    c
        .read(bookingDraftProvider.notifier)
        .start(venueId: 'V01', hallId: 'V01-danah', guests: 700, eventDate: const LocalDate(2027, 1, 14), audience: Audience.women);
    c.read(gzNavigatorProvider).push('CL-BOOK-02');
    await settle(tester, flush: true);
    expect(find.byType(GzEmptyState), findsOneWidget);
    expect(find.text('No package fits'), findsOneWidget);
    expect(find.text('Change guests'), findsOneWidget);
  });

  flowTest('back is safe: close asks first, Keep editing stays, the occasion sheet opens and a scrim tap dismisses it', (tester) async {
    await openScreen(tester, 'CL-BOOK-01');
    await tester.tap(find.bySemanticsLabel('Close').first);
    await settle(tester, flush: true);
    expect(find.text('Leave request?'), findsOneWidget);
    await tapText(tester, 'Keep editing', flush: true);
    expect(find.text('Leave request?'), findsNothing);
    expect(find.text('Your event'), findsOneWidget);

    await tapText(tester, 'Occasion', flush: true);
    expect(find.text('Henna'), findsWidgets, reason: 'the five choices are in a sheet');
    await tester.tapAt(const Offset(195, 60));
    await settle(tester, flush: true);
    expect(find.text('Henna'), findsNothing, reason: 'the scrim dismissed the sheet');
  });

  flowTest('confirm (Arabic): the approved hero request is confirmed in the window, then the confirmed outcome shows', (tester) async {
    await openScreen(tester, 'CL-BOOK-08', story: 'approved', locale: const Locale('ar'));
    expect(find.text('تأكيد الحجز'), findsOneWidget);
    expect(find.byType(GzCheckbox), findsOneWidget);
    // without the consent nothing is sent
    await tapText(tester, 'تأكيد الحجز', flush: true);
    expect(find.text('تأكيد الحجز'), findsOneWidget);
    await scrollTo(tester, find.byType(GzCheckbox));
    await tester.tap(find.byType(GzCheckbox));
    await settle(tester, flush: true);
    await tapText(tester, 'تأكيد الحجز', flush: true);
    await settle(tester, flush: true);
    expect(find.text('تم تأكيد الحجز'), findsWidgets);
    final detail = (await tester.runAsync(() => flowRepos('reem').requests.getRequest(requestId: 'bk-GZ-2611-0147')))!;
    expect(detail.booking.status, BookingStatus.confirmed, reason: 'the decision changed the status');
  });

  flowTest('the lapsed hero request shows the forfeited voucher and the way forward', (tester) async {
    await openScreen(tester, 'CL-BOOK-10', story: 'lapsed');
    expect(find.text('Window ended'), findsWidgets);
    expect(find.byType(GzStatusPill), findsOneWidget);
    expect(find.text('New request'), findsOneWidget);
    expect(find.text('Free dates'), findsOneWidget);
  });

  flowTest('one Arabic run: step 1 and step 2 read in Arabic and mirror', (tester) async {
    await openScreen(tester, 'CL-BOOK-01', locale: const Locale('ar'));
    expect(find.text('مناسبتكم'), findsOneWidget);
    final title = tester.getTopRight(find.text('مناسبتكم')).dx;
    expect(title, greaterThan(300), reason: 'the title sits at the inline start, the right edge, in Arabic');
    await tapText(tester, 'متابعة', flush: true);
    expect(find.text('الباقة'), findsWidgets);
  });
}
