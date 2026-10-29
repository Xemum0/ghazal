// The vouchers flow on the real router over the in-process mock: the wallet
// with its three groups, the voucher detail with the code and the history, the
// explainer sheet, the voucher-for-request sheet and the use-again sheet, the
// five states and one Arabic run. Bounded.
//
// Reem's wallet: the hero voucher is bound to its request (In request group),
// the released V05 voucher is ready again (Ready group).
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

/// The hero venue and package on the hero date (Reem's bound voucher quote).
const Map<String, Object?> kHeroQuote = <String, Object?>{
  'venueId': 'V01',
  'hallId': 'V01-danah',
  'packageId': 'V01-ladies-weekend',
  'date': '2027-01-14',
  'guests': 350,
};

void main() {
  flowTest('wallet: the ready group shows the released ticket, which opens its voucher', (tester) async {
    final c = await openScreen(tester, 'CL-VCHR-02');
    expect(find.text('My vouchers'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('voucher.ticket.vch-GV-2611-R4TF')), findsWidgets, reason: 'the released voucher is ready again');
    await scrollTo(tester, find.text('Lumi Marina Hotel'));
    await tapText(tester, 'Lumi Marina Hotel', flush: true);
    expect(currentId(c), 'CL-VCHR-03');
  });

  flowTest('wallet states: loading shows the skeleton, error the retry', (tester) async {
    await openScreen(tester, 'CL-VCHR-02', state: 'loading');
    expect(find.byType(GzSkeleton), findsWidgets);
  });

  flowTest('wallet error: the problem is told with a retry', (tester) async {
    await openScreen(tester, 'CL-VCHR-02', state: 'error', extraSeconds: 6);
    expect(find.byType(GzErrorState), findsOneWidget);
  });

  flowTest('voucher detail: the hero voucher shows its code, its validity and its history', (tester) async {
    await openScreen(tester, 'CL-VCHR-03');
    expect(find.byKey(const ValueKey<String>('voucher.detail')), findsOneWidget);
    expect(shows('GV-2611-K7QM'), isTrue, reason: 'the single-use code');
    expect(find.text('Send request'), findsOneWidget, reason: 'the ready voucher can be sent');
  });

  flowTest('voucher detail in Arabic: the phases and the history read right to left', (tester) async {
    await openScreen(tester, 'CL-VCHR-03', locale: const Locale('ar'));
    expect(find.text('الكوبون'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('voucher.detail')), findsOneWidget);
  });

  flowTest('explainer: the binding plate, the three knots and Pay KD 2 open the pay screen', (tester) async {
    final c = await openScreen(tester, 'CL-VCHR-01', params: kHeroQuote);
    expect(find.byKey(const ValueKey<String>('voucher.quote')), findsOneWidget);
    await tapKey(tester, 'voucher.explainer.pay', flush: true);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-PAYM-01', reason: 'the checkout opens with the quote intact');
  });

  flowTest('voucher for request: the attached voucher is used with one tap', (tester) async {
    final c = await openScreen(tester, 'CL-DISC-01');
    c.read(bookingDraftProvider.notifier).patch(
      (d) => d.copyWith(venueId: 'V05', hallId: 'V05-marina', packageId: 'V05-ladies-weekend', eventDate: const LocalDate(2027, 1, 14), guests: 300, voucherId: 'vch-GV-2611-R4TF'),
    );
    await openSheetOf(tester, c, 'CL-VCHR-04');
    expect(find.byKey(const ValueKey<String>('voucher.request')), findsOneWidget);
    await tapText(tester, 'Use voucher', flush: true);
    expect(c.read(bookingDraftProvider).voucherId, 'vch-GV-2611-R4TF');
  });

  flowTest('use again: the released voucher offers reuse and the support path', (tester) async {
    final c = await openScreen(tester, 'CL-DISC-01');
    await openSheetOf(tester, c, 'CL-VCHR-05', const <String, Object?>{'voucherId': 'vch-GV-2611-R4TF'});
    expect(find.byKey(const ValueKey<String>('voucher.choices')), findsOneWidget, reason: 'reuse and ask support');
    await tapText(tester, 'Ask support', flush: true);
    expect(find.byKey(const ValueKey<String>('voucher.confirm')), findsOneWidget);
    await tapText(tester, 'Open support chat', flush: true);
    await settle(tester, flush: true);
    expect(currentId(c), 'CL-MSGS-02', reason: 'the support chat opens with the request written');
  });
}
