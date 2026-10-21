import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show CreditVoucher, Voucher;
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/core/gz_format_scope.dart';

/// The prototype story clock: 2026-11-12 16:00 Asia/Kuwait.
final DateTime storyNow = DateTime.parse('2026-11-12T16:00:00+03:00');

/// Pumps [child] (350 wide, the gallery column) under the real host and the shared formatter with the story clock.
Future<void> pumpVoucher(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 1600, DateTime? now}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width + 40, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => GzFormatScope(
          format: GzFormat(locale: Locale(lang), now: () => now ?? storyNow),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A bound voucher as the fixtures serve it (the shape of `Voucher.seed.json`), with [status] and [code] overridable.
Voucher boundVoucher({String status = 'bound', String code = 'GV-2611-K7QM', String? usedAt}) => Voucher.fromJson({
  'id': 'vch-$code',
  'kind': 'bound',
  'code': code,
  'clientId': 'user-reem',
  'targetType': 'venue',
  'venueOrProviderId': 'V01',
  'hallId': 'V01-danah',
  'packageId': 'V01-ladies-weekend',
  'eventDate': '2027-01-14',
  'guests': 350,
  'quoteFils': {'standard': 18200000, 'voucher': 15400000},
  'priceFils': 2000,
  'status': status,
  'purchasedAt': '2026-11-12T10:00:00+03:00',
  'validUntil': '2027-01-11T10:00:00+03:00',
  'reuseUntil': null,
  'qr': {'payload': 'gz:v1:$code:V01:CBDA', 'version': 1},
  'bookingId': null,
  'payment': {'method': 'knet', 'receiptNo': 'RC-1', 'amount': {'fils': 2000, 'currency': 'KWD'}, 'status': 'succeeded', 'at': '2026-11-12T10:01:00+03:00'},
  'releasedAt': null,
  'releaseReason': null,
  'forfeitedAt': null,
  'creditEligible': false,
  'refundRequestId': null,
  'grantedFrom': null,
  'usedAt': usedAt,
  'usedReason': null,
  'redeemedBy': null,
});

CreditVoucher creditVoucher({String status = 'active'}) => CreditVoucher.fromJson({
  'id': 'vch-GV-2611-C4RD',
  'kind': 'credit',
  'code': 'GV-2611-C4RD',
  'clientId': 'user-reem',
  'priceFils': 0,
  'status': status,
  'validUntil': '2027-01-06T10:00:00+03:00',
  'qr': {'payload': 'gz:v1:GV-2611-C4RD:ANY:AB12', 'version': 1},
  'usedAt': null,
  'usedReason': null,
  'redeemedBy': null,
  'grantedAt': '2026-11-07T10:00:00+03:00',
  'grantedFrom': {'requestId': 'rr-1', 'voucherId': 'vch-GV-2610-H9XB', 'grantedBy': 'support'},
  'bookingId': null,
});
