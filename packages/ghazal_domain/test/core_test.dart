import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

void main() {
  group('LocalDate', () {
    test('parses, prints and does calendar arithmetic without a time zone', () {
      final d = LocalDate.parse('2027-01-14');
      expect(d.toJson(), '2027-01-14');
      expect(d.weekdayIndex, 4); // Thursday (0 = Sunday)
      expect(d.addDays(18).toString(), '2027-02-01');
      expect(LocalDate.parse('2026-11-12').daysUntil(d), 63);
      expect(d.monthKey, '2027-01');
      expect(() => LocalDate.parse('2027-02-30'), throwsFormatException);
      expect(() => LocalDate.parse('14/01/2027'), throwsFormatException);
    });
    test('orders and compares by value', () {
      expect(LocalDate.parse('2027-01-14') == const LocalDate(2027, 1, 14), isTrue);
      expect(LocalDate.parse('2027-01-14').compareTo(LocalDate.parse('2027-01-15')), lessThan(0));
    });
  });

  group('LocalTime', () {
    test('parses HH:mm and crosses midnight by comparison only', () {
      expect(LocalTime.parse('21:00').minutesOfDay, 1260);
      expect(LocalTime.parse('02:00').toString(), '02:00');
      expect(() => LocalTime.parse('24:00'), throwsFormatException);
    });
  });

  group('instants', () {
    test('keep the Kuwait offset on the wire', () {
      final t = parseInstant('2026-11-12T16:00:00+03:00');
      expect(t, DateTime.utc(2026, 11, 12, 13));
      expect(instantToJson(t), '2026-11-12T16:00:00+03:00');
      expect(parseInstant('2026-11-12T13:00:00Z'), t);
      expect(t.kuwaitDate.toString(), '2026-11-12');
      expect(parseInstant('2026-11-12T22:30:00Z').kuwaitDate.toString(), '2026-11-13'); // 01:30 next day in Kuwait
      expect(t.kuwaitTime.toString(), '16:00');
    });
  });

  group('MoneyAmount', () {
    test('is integer fils with exact arithmetic', () {
      final a = MoneyAmount.fromJson({'fils': 18200000, 'currency': 'KWD'});
      expect((a - const MoneyAmount(15400000)).fils, 2800000);
      expect(a.toJson(), {'fils': 18200000, 'currency': 'KWD'});
      expect(() => MoneyAmount.fromJson({'fils': 1.5, 'currency': 'KWD'}), throwsFormatException);
      expect(() => a + const MoneyAmount(1, 'SAR'), throwsArgumentError);
    });
  });

  group('LocalizedText', () {
    test('falls back to the other language', () {
      const t = LocalizedText(en: 'Danah Ballroom');
      expect(t.of('en'), 'Danah Ballroom');
      expect(t.of('ar'), 'Danah Ballroom');
      expect(t.isFallback('ar'), isTrue);
      expect(const LocalizedText(ar: 'قاعة الدانة').of('en'), 'قاعة الدانة');
      expect(const LocalizedText().of('ar'), '');
    });
  });

  group('Page', () {
    test('reads items and cursor', () {
      final p = Page<int>.fromJson({'items': [1, 2], 'nextCursor': 'abc'}, asInt);
      expect(p.items, [1, 2]);
      expect(p.hasMore, isTrue);
      expect(Page<int>.fromJson({'items': <int>[], 'nextCursor': null}, asInt).hasMore, isFalse);
    });
  });

  group('Clock', () {
    test('FixedClock stands still until advanced', () {
      final c = FixedClock.parse('2026-11-12T16:00:00+03:00');
      expect(c.now(), DateTime.utc(2026, 11, 12, 13));
      c.advance(const Duration(hours: 24));
      expect(c.now().kuwaitDate.toString(), '2026-11-13');
      expect(const SystemClock().now().isUtc, isTrue);
    });
  });

  group('enums', () {
    test('unknown values fall back instead of crashing', () {
      expect(BookingStatus.fromJson('pending'), BookingStatus.pending);
      expect(BookingStatus.fromJson('a_status_from_the_future'), BookingStatus.unknown);
      expect(NotificationKind.fromJson('new_request'), NotificationKind.newRequest);
      expect(ErrorCode.fromJson('SLOT_UNAVAILABLE'), ErrorCode.slotUnavailable);
      expect(ErrorCode.fromJson('EMAIL_ALREADY_REGISTERED'), ErrorCode.emailAlreadyRegistered, reason: 'round 2b, the public partner application');
      expect(ErrorCode.fromJson('SOMETHING_NEW'), ErrorCode.unknown);
      expect(BookingStatus.pending.toJson(), 'pending');
    });
  });

  group('unions', () {
    test('WalletVoucher picks the variant by kind', () {
      final bound = WalletVoucher.fromJson(_voucherJson('bound'));
      final credit = WalletVoucher.fromJson(_voucherJson('credit'));
      expect(bound, isA<Voucher>());
      expect(credit, isA<CreditVoucher>());
      expect(bound.kind, 'bound');
      expect(bound.code, 'GV-2611-K7QM');
      expect(() => WalletVoucher.fromJson({..._voucherJson('bound'), 'kind': 'mystery'}), throwsFormatException);
    });
    test('CardPrice picks the variant by mode', () {
      final p = CardPrice.fromJson({
        'mode': 'from_guests',
        'amount': {'fils': 52000, 'currency': 'KWD'},
        'guests': 350,
        'packageId': 'V01-ladies-weekend',
        'tier': 'weekend',
        'voucher': null,
        'savings': null,
      });
      expect(p, isA<CardPriceFromGuests>());
      expect(p.toJson()['mode'], 'from_guests');
    });
  });

  group('models', () {
    test('copyWith can set a nullable field back to null and keeps value equality', () {
      final b = Booking.fromJson(_bookingJson());
      expect(b.confirmBy, isNull);
      final approved = b.copyWith(status: BookingStatus.approved, confirmBy: DateTime.utc(2026, 11, 13, 13));
      expect(approved.confirmBy, DateTime.utc(2026, 11, 13, 13));
      final back = approved.copyWith(confirmBy: null);
      expect(back.confirmBy, isNull);
      expect(back.copyWith(status: BookingStatus.pending), b);
      expect(back.copyWith(status: BookingStatus.pending).hashCode, b.hashCode);
    });
    test('a missing required field names its path', () {
      final json = _bookingJson()..remove('eventDate');
      expect(() => Booking.fromJson(json), throwsA(isA<FormatException>().having((e) => e.message, 'message', allOf(contains('Booking'), contains('eventDate')))));
    });
  });
}

Map<String, Object?> _voucherJson(String kind) => {
      'id': 'vch-GV-2611-K7QM',
      'kind': kind,
      'code': 'GV-2611-K7QM',
      'clientId': 'user-reem',
      'priceFils': 2000,
      'status': 'active',
      'validUntil': '2027-01-11T12:31:00+03:00',
      'qr': {'payload': 'gz:v1:GV-2611-K7QM:V01:CBDA', 'version': 1},
      'usedAt': null,
      'usedReason': null,
      'redeemedBy': null,
      if (kind == 'bound') ...{
        'targetType': 'venue',
        'venueOrProviderId': 'V01',
        'hallId': 'V01-danah',
        'packageId': 'V01-ladies-weekend',
        'eventDate': '2027-01-14',
        'guests': 350,
        'quoteFils': {'standard': 18200000, 'voucher': 15400000},
        'purchasedAt': '2026-11-12T12:31:00+03:00',
        'reuseUntil': null,
        'bookingId': null,
        'payment': null,
        'releasedAt': null,
        'releaseReason': null,
        'forfeitedAt': null,
        'creditEligible': false,
        'refundRequestId': null,
      } else ...{
        'grantedAt': '2026-11-01T10:00:00+03:00',
        'grantedFrom': {'requestId': 'rf-1', 'voucherId': 'v-old', 'grantedBy': 'Support'},
        'bookingId': null,
      },
    };

Map<String, Object?> _bookingJson() {
  const m = {'fils': 15400000, 'currency': 'KWD'};
  return {
    'id': 'bk-1', 'ref': 'GZ-2611-0147', 'version': 1, 'targetType': 'venue', 'venueId': 'V01', 'providerId': null, 'clientId': 'user-reem',
    'clientName': 'Reem', 'weddingId': null, 'status': 'pending', 'createdAt': '2026-11-12T12:40:00+03:00', 'eventDate': '2027-01-14',
    'sections': <Object?>[], 'service': null, 'lines': <Object?>[],
    'totals': {
      'standardSubtotal': m, 'standardServiceCharge': m, 'standardTotal': m, 'voucherSubtotal': m, 'venueDiscount': m,
      'voucherServiceCharge': m, 'voucherTotal': m, 'savings': m, 'voucherFee': m, 'netSavings': 1,
    },
    'voucherId': 'v1', 'respondBy': null, 'approvedAt': null, 'confirmBy': null, 'confirmedAt': null, 'redeemedAt': null, 'redeemedBy': null,
    'completedAt': null, 'slaHours': 24,
    'contact': {'name': 'Reem', 'phone': '+96550000012', 'shared': true, 'bookingFor': 'bride'},
    'specialRequests': null, 'firstBooking': true, 'verifiedPhone': true, 'thread': <Object?>[], 'events': <Object?>[], 'cancelledBy': null,
    'reasonCode': null, 'rejectReason': null, 'expiredReason': null, 'proposal': null, 'overlays': <String, Object?>{}, 'approvedDiscount': null,
    'allowedActions': <Object?>['message'],
  };
}
