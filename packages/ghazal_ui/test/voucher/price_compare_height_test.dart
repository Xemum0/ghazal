import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PriceStructure;
import 'package:ghazal_ui/src/voucher/voucher.dart';

import '../shared/shared_harness.dart';
import 'voucher_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  // Web CL-VCHR-01 (en, signed in): PriceCompare inline in a 316 column is 50 high (price 24, basis row at +30).
  testWidgets('inline price compare is 50 high with the basis row (web CL-VCHR-01)', (tester) async {
    await pumpVoucher(
      tester,
      const Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: 316,
          child: GzPriceCompare(
            standard: 18200,
            voucher: 15400,
            structure: PriceStructure.package,
            guests: 350,
            variant: GzPriceCompareVariant.inline,
          ),
        ),
      ),
      width: 400,
    );
    expect(tester.getSize(find.byType(GzPriceCompare)).height, 50);
  });
}
