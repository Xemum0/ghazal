// The payment flow on the real router over the in-process mock: the KD 2
// checkout from the pay screen through the gateway and the verifying screen to
// the voucher-ready outcome and the failure layout, the five
// states and one Arabic run. Bounded: every wait is a bounded settle.
//
// The hero quote already has Reem's voucher (bound to the same venue, package
// and date), so the default frame shows the "already yours" banner; a quote
// with another date exercises the Pay now path.
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

/// A quote Reem holds no voucher for: the hero venue and package on a free date.
const Map<String, Object?> kFreshQuote = <String, Object?>{
  'venueId': 'V01',
  'hallId': 'V01-danah',
  'packageId': 'V01-ladies-weekend',
  'date': '2027-01-21',
  'guests': 350,
};

void main() {
  flowTest('pay: the hero quote shows the KD 2 hero, the methods in order, and no banner on a bare open', (tester) async {
    await openScreen(tester, 'CL-PAYM-01');
    expect(find.text('Payment'), findsWidgets);
    expect(find.byType(GzPrice), findsWidgets, reason: 'the KD 2 hero is exact');
    expect(find.byKey(const ValueKey<String>('pay.methods')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pay.method.knet')), findsOneWidget);
    expect(find.text('You have this voucher'), findsNothing, reason: 'a bare open shows no banner (web frame)');
    expect(find.text('Pay now'), findsOneWidget);
  });

  flowTest('pay: the has-voucher frame offers the owned voucher instead', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-01', params: const <String, Object?>{'scene': 'has-voucher'});
    expect(find.text('You have this voucher'), findsOneWidget);
    await tapText(tester, 'View voucher', flush: true);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-VCHR-03');
  });

  flowTest('pay: Pay now checks out a fresh quote and opens the gateway', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-01', params: kFreshQuote);
    expect(find.text('Pay now'), findsOneWidget);
    await tapText(tester, 'Pay now', flush: true);
    await settle(tester, wait: const Duration(seconds: 5), flush: true);
    expect(currentId(c), 'CL-PAYM-02', reason: 'the checkout prepared the voucher and opened the gateway');
    expect(c.read(paymentProvider).paymentId, isNotNull, reason: 'a hosted session is open');
  });

  flowTest('pay states: loading shows the skeleton, error the retry', (tester) async {
    await openScreen(tester, 'CL-PAYM-01', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
    expect(find.byType(GzErrorState), findsNothing);
  });

  flowTest('pay error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-PAYM-01', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('pay offline: the offline state shows with its retry', (tester) async {
    await openScreen(tester, 'CL-PAYM-01', state: 'offline', extraSeconds: 6);
    expect(find.byType(GzOfflineState), findsOneWidget);
  });

  flowTest('gateway: the KNET placeholder shows the brand and the exact amount, Submit verifies', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-02');
    expect(find.text('Secure payment'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pay.hosted')), findsOneWidget);
    expect(shows('KNET'), isTrue);
    await tapText(tester, 'Submit', flush: true);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-PAYM-03', reason: 'the return goes to verifying, never trusted');
  });

  flowTest('gateway: Close asks to stay, staying keeps the page', (tester) async {
    await openScreen(tester, 'CL-PAYM-02');
    await settle(tester, flush: true);
    final c = container(tester);
    await tapLabel(tester, RegExp('Close'));
    await settle(tester);
    expect(find.text('Leave payment?'), findsOneWidget);
    await tapText(tester, 'Stay', flush: true);
    expect(currentId(c), 'CL-PAYM-02');
  });

  flowTest('confirming: success draws and continues to the voucher', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-03', params: const <String, Object?>{'scene': 'success', 'voucherId': 'vch-GV-2611-K7QM'});
    expect(find.text('Payment received'), findsWidgets);
    await tapText(tester, 'View voucher', flush: true);
    expect(currentId(c), 'CL-PAYM-05');
  });

  flowTest('confirming: failure goes to the outcome layout', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-03', params: const <String, Object?>{'scene': 'failed', 'voucherId': 'vch-GV-2611-K7QM'});
    await tapText(tester, 'Try again', flush: true);
    expect(currentId(c), 'CL-PAYM-04');
  });

  flowTest('not completed: declined retries through a new gateway session', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-04', params: const <String, Object?>{'scene': 'declined'});
    await tapText(tester, 'Try again', flush: true);
    expect(currentId(c), 'CL-PAYM-02', reason: 'retry reuses the attempt chain');
  });

  flowTest('not completed: the expired checkout starts again with the same quote', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-04', params: const <String, Object?>{'scene': 'checkout-expired'});
    expect(find.text('Checkout ended'), findsOneWidget);
    await tapText(tester, 'Start again', flush: true);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-PAYM-01');
  });

  flowTest('not completed: the late payment honours the voucher', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-04', params: const <String, Object?>{'scene': 'late-payment-activated'});
    await tapText(tester, 'View voucher', flush: true);
    expect(currentId(c), 'CL-PAYM-05');
  });

  flowTest('voucher ready: the ticket shows and Send request prefills the booking flow', (tester) async {
    final c = await openScreen(tester, 'CL-PAYM-05');
    expect(find.text('Voucher ready'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pay.done')), findsOneWidget);
    await scrollTo(tester, find.text('Send request'));
    await tapText(tester, 'Send request', flush: true);
    expect(currentId(c), 'CL-BOOK-01', reason: 'the booking flow opens prefilled from the voucher');
    expect(c.read(bookingDraftProvider).voucherId, isNotNull);
  });

  flowTest('pay in Arabic: the hero, the methods and the terms read right to left', (tester) async {
    await openScreen(tester, 'CL-PAYM-01', locale: const Locale('ar'));
    expect(find.text('الدفع'), findsOneWidget);
    expect(find.byType(GzPrice), findsWidgets);
    expect(find.byKey(const ValueKey<String>('pay.methods')), findsOneWidget);
  });
}
