import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show GatewayMethod;
import 'package:ghazal_ui/src/client/client_d.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'client_d_fixtures.dart';

late ClientDFixtures fx;

Widget _row(GzPaymentMethodKey m, {bool selected = false, VoidCallback? onSelect, bool unavailable = false, String? note}) => SizedBox(
  width: 350,
  child: GzPaymentMethodRow(method: m, selected: selected, onSelect: onSelect, unavailable: unavailable, note: note),
);

void main() {
  setUpAll(() async {
    await loadUiFonts();
    fx = await ClientDFixtures.load();
  });

  group('GzPaymentMethodRow', () {
    test('Visa and Mastercard are one gateway method (card); the others map one to one', () {
      expect(gzToGatewayMethod(GzPaymentMethodKey.visa), GatewayMethod.card);
      expect(gzToGatewayMethod(GzPaymentMethodKey.mastercard), GatewayMethod.card);
      expect(gzToGatewayMethod(GzPaymentMethodKey.knet), GatewayMethod.knet);
      expect(gzToGatewayMethod(GzPaymentMethodKey.applePay), GatewayMethod.applePay);
      expect(gzToGatewayMethod(GzPaymentMethodKey.googlePay), GatewayMethod.googlePay);
    });

    testWidgets('the default note names the method; a given note replaces it; there is no cash row', (tester) async {
      await pumpCore(tester, _row(GzPaymentMethodKey.knet, onSelect: () {}));
      expect(find.text('KNET'), findsWidgets); // the label and the typeset mark
      expect(find.text('Kuwaiti bank cards'), findsOneWidget);
      await pumpCore(tester, _row(GzPaymentMethodKey.visa, onSelect: () {}, note: 'Recommended after a KNET limit'));
      expect(find.text('Recommended after a KNET limit'), findsOneWidget);
      expect(find.text('Credit or debit card'), findsNothing);
      expect(find.textContaining('Cash'), findsNothing);
    });

    testWidgets('selecting calls back; unavailable does not fire and says why', (tester) async {
      var picked = 0;
      await pumpCore(tester, _row(GzPaymentMethodKey.knet, onSelect: () => picked++));
      await tester.tap(find.byType(GzPaymentMethodRow));
      expect(picked, 1);
      await pumpCore(tester, _row(GzPaymentMethodKey.applePay, onSelect: () => picked++, unavailable: true));
      await tester.tap(find.byType(GzPaymentMethodRow));
      expect(picked, 1);
      expect(find.text('Not available on this device'), findsOneWidget);
    });

    testWidgets('one radio node: checked when selected, with the word, a row of at least 64 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, _row(GzPaymentMethodKey.knet, selected: true, onSelect: () {}));
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('KNET, Kuwaiti bank cards, Selected')));
      expect(node.getSemanticsData().flagsCollection.isChecked.toString(), contains('isTrue'));
      expect(tester.getSize(find.byType(GzPaymentMethodRow)).height, greaterThanOrEqualTo(GzSize.rowMin));
      handle.dispose();
    });

    testWidgets('the mark tile stays left-to-right in Arabic and the labels are Arabic', (tester) async {
      await pumpCore(tester, _row(GzPaymentMethodKey.knet, onSelect: () {}), lang: 'ar');
      expect(find.text('كي نت'), findsOneWidget);
      final mark = find.text('KNET');
      expect(mark, findsOneWidget);
      expect(Directionality.of(tester.element(mark)), TextDirection.ltr);
    });
  });

  group('GzReceiptSheet', () {
    Widget sheet() => SizedBox(
      width: 350,
      child: GzReceiptSheet(voucher: fx.heroVouchers['approved']!, targetName: 'Aurelia Gulf Hotel'),
    );

    testWidgets('issuer, receipt number, voucher code, line and total: KWD with three decimals, no VAT, no deposit', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, sheet());
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.textContaining('RC-050039', findRichText: true), findsOneWidget);
      expect(find.textContaining('GV-2611-K7QM', findRichText: true), findsOneWidget);
      expect(find.textContaining('Voucher for Aurelia Gulf Hotel', findRichText: true), findsOneWidget);
      final spoken = tester.getSemantics(find.bySemanticsLabel(RegExp('Receipt'))).label;
      expect(RegExp(r'KWD\s2\.000').allMatches(spoken).length, 2); // the line and the total
      expect(find.textContaining('KNET'), findsOneWidget);
      for (final w in ['VAT', 'Deposit', 'Balance', 'Refund']) {
        expect(find.textContaining(w, findRichText: true), findsNothing, reason: w);
      }
      handle.dispose();
    });

    testWidgets('Arabic receipt keeps the number, code and KWD as left-to-right runs', (tester) async {
      await pumpCore(tester, sheet(), lang: 'ar');
      expect(find.text('إيصال'), findsOneWidget);
      expect(find.textContaining('RC-050039', findRichText: true), findsOneWidget);
      expect(find.textContaining('كوبون خاص بـ', findRichText: true), findsOneWidget);
    });
  });
}
