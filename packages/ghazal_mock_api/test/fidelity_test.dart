// The rules the pilot flows needed from the mock beyond the selector cases (selector_equality_test.dart): the three special OTP codes and the wrong
// one, `limit` clamped everywhere, a released voucher moved to another date, extras with a quantity, the rival request, the sister venue and the
// bilingual inviter. Each test names the rule it pins in docs/architecture/mock-api.md.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';

import 'harness.dart';

Future<Response<Object?>> raw(Actor a, String method, String path, {Object? data, Map<String, Object?>? headers, Map<String, Object?>? query}) =>
    a.dio.request<Object?>(
      path,
      data: data,
      queryParameters: query,
      options: Options(method: method, headers: headers, validateStatus: (_) => true),
    );

Json body(Response<Object?> r) => (r.data as Map).cast<String, dynamic>();

void main() {
  late World w;
  setUp(() async => w = await World.create());

  group('OTP codes (client WhatsApp and partner email alike)', () {
    Future<String> challenge(Actor a, String phone) async =>
        body(await raw(a, 'POST', '/auth/otp/request', data: {'phone': phone, 'purpose': 'login'}))['challengeId'] as String;
    Future<Response<Object?>> verify(Actor a, String id, String code) => raw(a, 'POST', '/auth/otp/verify', data: {'challengeId': id, 'code': code});

    test('123456 and any other six digits sign in; 000000 is locked; 111111 is expired', () async {
      final a = w.actor('guest');
      expect((await verify(a, await challenge(a, '+96550000012'), '123456')).statusCode, 200);
      expect((await verify(a, await challenge(a, '+96550000012'), '654321')).statusCode, 200);
      final locked = await verify(a, await challenge(a, '+96550000012'), '000000');
      expect((locked.statusCode, body(locked)['code']), (423, 'OTP_LOCKED'));
      final expired = await verify(a, await challenge(a, '+96550000012'), '111111');
      expect((expired.statusCode, body(expired)['code']), (410, 'OTP_EXPIRED'));
    });

    test('222222 is wrong: OTP_INVALID counts down the attempts, the fifth wrong code locks the challenge for good', () async {
      final a = w.actor('guest');
      final id = await challenge(a, '+96550000012');
      for (var left = 4; left >= 1; left--) {
        final r = await verify(a, id, '222222');
        expect((r.statusCode, body(r)['code']), (400, 'OTP_INVALID'));
        expect((body(r)['params'] as Map)['remainingAttempts'], left);
      }
      final fifth = await verify(a, id, '222222');
      expect((fifth.statusCode, body(fifth)['code']), (423, 'OTP_LOCKED'));
      expect(body(fifth)['retryAfterSeconds'], 900);
      expect((await verify(a, id, '123456')).statusCode, 423, reason: 'a locked challenge stays locked: ask for a new code');
      expect((await verify(a, await challenge(a, '+96550000012'), '123456')).statusCode, 200, reason: 'a new challenge starts again');
    });

    test('a short code is a wrong code (it counts), and a right one still works while attempts remain', () async {
      final a = w.actor('guest');
      final id = await challenge(a, '+96550000012');
      final short = await verify(a, id, '12345');
      expect((short.statusCode, body(short)['code'], (body(short)['params'] as Map)['remainingAttempts']), (400, 'OTP_INVALID', 4));
      expect((await verify(a, id, '123456')).statusCode, 200);
    });

    test('the partner email code follows the same rules', () async {
      final a = w.actor('guest');
      final login = body(
        await raw(a, 'POST', '/auth/partner/login', data: {'email': 'hind@aurelia-gulf.example', 'password': 'Ghazal#2026', 'deviceId': 'dev-otp'}),
      );
      expect(login['status'], 'code_required');
      final id = (login['challenge'] as Map)['challengeId'] as String;
      Future<Response<Object?>> verifyPartner(String code) =>
          raw(a, 'POST', '/auth/partner/verify', data: {'challengeId': id, 'code': code, 'deviceId': 'dev-otp'});
      final wrong = await verifyPartner('222222');
      expect((wrong.statusCode, body(wrong)['code'], (body(wrong)['params'] as Map)['remainingAttempts']), (400, 'OTP_INVALID', 4));
      for (var i = 0; i < 3; i++) {
        await verifyPartner('222222');
      }
      expect(body(await verifyPartner('222222'))['code'], 'OTP_LOCKED');
      expect((await verifyPartner('123456')).statusCode, 423);
    });
  });

  group('limit is clamped, never refused', () {
    test('every list endpoint answers 200 for limit 500 and limit 0, with at most 50 rows', () async {
      final reem = w.actor('reem');
      final hind = w.actor('hotel_manager', venueId: 'V01');
      final calls = <(Actor, String, Map<String, Object?>)>[
        (reem, '/venues', {}),
        (reem, '/vouchers', {}),
        (reem, '/requests', {}),
        (reem, '/notifications', {}),
        (reem, '/conversations', {}),
        (reem, '/venues/V01/reviews', {}),
        (reem, '/venues/V01/nearby', {}),
        (reem, '/receipts', {}),
        (reem, '/visits', {}),
        (hind, '/partner/requests', {'segment': 'past'}),
        (hind, '/partner/vouchers/redeemable', {}),
        (hind, '/partner/vouchers/redeemed', {}),
        (hind, '/partner/visits', {}),
        (hind, '/partner/reviews', {}),
        (hind, '/notifications', {}),
        (hind, '/conversations', {}),
      ];
      for (final (actor, path, query) in calls) {
        for (final limit in [500, 0, -3]) {
          final r = await raw(actor, 'GET', path, query: {...query, 'limit': limit});
          expect(r.statusCode, 200, reason: '$path?limit=$limit');
          final data = r.data;
          final items = data is Map ? (data['items'] as List? ?? const []) : data as List;
          expect(items.length, lessThanOrEqualTo(50), reason: '$path?limit=$limit');
          if (limit <= 0) expect(items.length, lessThanOrEqualTo(1), reason: '$path?limit=$limit clamps to 1');
        }
      }
      final search = await raw(reem, 'GET', '/venues', query: {'limit': 500});
      expect((body(search)['items'] as List).length, 16, reason: 'all sixteen venues fit in one clamped page');
      expect(body(search)['nextCursor'], isNull);
      expect((await raw(reem, 'GET', '/venues', query: {'limit': 'many'})).statusCode, 422, reason: 'a non-integer is still a validation error');
    });
  });

  group('vouchers and requests', () {
    test('a ready voucher moves to another date at the same venue: package, hall and guests stay unless the body changes them, a new quote is taken', () async {
      final a = w.actor('reem');
      final before = body(await raw(a, 'GET', '/vouchers/vch-GV-2611-R4TF'));
      expect((before['voucher'] as Map)['guests'], 300);
      final moved = await raw(
        a,
        'POST',
        '/vouchers/vch-GV-2611-R4TF/rebind',
        data: {'packageId': 'V05-ladies-weekend', 'eventDate': '2027-01-21'},
        headers: {'Idempotency-Key': 'rebind-1'},
      );
      expect(moved.statusCode, 200);
      final v = body(moved);
      expect(
        (v['eventDate'], v['guests'], v['hallId'], v['status'], v['venueOrProviderId']),
        ('2027-01-21', 300, 'V05-marina', 'active', 'V05'),
        reason: 'the 300 guests and the hall are kept; the voucher stays at V05',
      );
      expect(
        ((v['quoteFils'] as Map)['standard'] as int),
        greaterThan((v['quoteFils'] as Map)['voucher'] as int),
        reason: 'a new quote was taken for the new date and it still pays for itself',
      );
      final bigger = body(
        await raw(
          a,
          'POST',
          '/vouchers/vch-GV-2611-R4TF/rebind',
          data: {'packageId': 'V05-ladies-weekend', 'eventDate': '2027-01-21', 'guests': 350},
          headers: {'Idempotency-Key': 'rebind-2'},
        ),
      );
      expect(bigger['guests'], 350);
      final elsewhere = await raw(
        a,
        'POST',
        '/vouchers/vch-GV-2611-R4TF/rebind',
        data: {'packageId': 'V01-ladies-weekend', 'eventDate': '2027-01-21'},
        headers: {'Idempotency-Key': 'rebind-3'},
      );
      expect(elsewhere.statusCode, 422, reason: 'a package of another venue is not this voucher\'s venue');
      final attached = await raw(
        a,
        'POST',
        '/vouchers/vch-GV-2611-K7QM/rebind',
        data: {'packageId': 'V01-ladies-weekend', 'eventDate': '2027-01-21'},
        headers: {'Idempotency-Key': 'rebind-4'},
      );
      expect(
        (attached.statusCode, body(attached)['code']),
        (409, 'VOUCHER_NOT_USABLE'),
        reason: 'a voucher attached to a request moves through the venue\'s counter-offer, not by itself',
      );
    });

    test('extras carry a quantity: a quote prices it, a quantity above the extra\'s maximum is refused', () async {
      final a = w.actor('reem');
      final section = {'hallId': 'V01-danah', 'audience': 'women', 'guests': 350, 'packageId': 'V01-ladies-weekend'};
      Future<Response<Object?>> quote(List<Map<String, Object?>> extras) => raw(
        a,
        'POST',
        '/venues/V01/quotes',
        data: {
          'eventDate': '2027-01-14',
          'sections': [section],
          'extras': extras,
        },
      );
      final base = body(await quote([]));
      final two = body(
        await quote([
          {'extraId': 'V01-x-valet-staff', 'qty': 2},
        ]),
      );
      final four = body(
        await quote([
          {'extraId': 'V01-x-valet-staff', 'qty': 4},
        ]),
      );
      int total(Json q) => ((q['totals'] as Map)['standardTotal'] as Map)['fils'] as int;
      final unit = (total(two) - total(base)) ~/ 2;
      expect(unit, greaterThan(0));
      expect(total(four) - total(base), unit * 4);
      final tooMany = await quote([
        {'extraId': 'V01-x-valet-staff', 'qty': 5},
      ]);
      expect(tooMany.statusCode, 422);
      expect(((body(tooMany)['errors'] as List).first as Map)['path'], '/extras/0/qty');
      expect(
        (await quote([
          {'extraId': 'V05-x-hour', 'qty': 1},
        ])).statusCode,
        422,
        reason: 'an extra of another venue',
      );
      expect(
        (await quote([
          {'extraId': 'V01-x-kosha', 'qty': 0},
        ])).statusCode,
        422,
      );
    });
  });

  group('the partner story', () {
    test('five requests wait at the start; the rival request of Dalal comes in only through the control surface', () async {
      final hind = w.actor('hotel_manager', venueId: 'V01');
      Future<Json> today() async => body(await raw(hind, 'GET', '/partner/today'));
      var t = await today();
      expect((t['tiles'] as Map)['requests'], 5);
      expect((t['needsYou'] as List).length, 10);
      final detail = body(await raw(hind, 'GET', '/partner/requests/bk-GZ-2611-0147'));
      expect(detail['otherRequestsSameDate'], 0, reason: 'nobody else asked for Thursday 14 January yet');
      final rival = w.control.simulateRival();
      expect(rival?['id'], 'bk-GZ-2611-6X3M');
      expect(w.control.simulateRival(), isNull, reason: 'idempotent');
      t = await today();
      expect((t['tiles'] as Map)['requests'], 6);
      expect((t['needsYou'] as List).length, 11);
      expect(body(await raw(hind, 'GET', '/partner/requests/bk-GZ-2611-0147'))['otherRequestsSameDate'], 1);
      await w.control.reset();
      final again = body(await raw(w.actor('hotel_manager', venueId: 'V01'), 'GET', '/partner/today'));
      expect((again['tiles'] as Map)['requests'], 5, reason: 'reset puts the rival back out');
    });

    test('a new message or visit after the story start adds a Needs-you row; the old unanswered message of another couple is not one', () async {
      final hind = w.actor('hotel_manager', venueId: 'V01');
      final ids = [for (final n in (await raw(hind, 'GET', '/partner/needs-you')).data as List) (n as Map)['item']['id']];
      expect(ids, contains('triage-msg-reem'));
      expect(ids.any((i) => '$i'.contains('faisal')), isFalse);
    });

    test('Hind belongs to two venues: Aurelia Gulf (manager) and its sister (reception, two requests waiting)', () async {
      final hind = w.actor('hotel_manager');
      final me = body(await raw(hind, 'GET', '/partner/me'));
      final ms = (me['memberships'] as List).cast<Map<String, dynamic>>();
      expect(ms.map((m) => (m['venueId'], m['role'], m['pendingRequests'])), [('V01', 'manager', 5), ('V-sister-marina', 'reception', 2)]);
      expect(me['active'], isNull, reason: 'nothing chosen yet: the app shows Switch venue');
      final khalid = body(await raw(w.actor('hotel_admin'), 'GET', '/partner/me'));
      expect((khalid['memberships'] as List).length, 1);
    });

    test('the inviter is named in both languages', () async {
      final khalid = w.actor('hotel_admin', venueId: 'V01');
      final list = body(await raw(khalid, 'GET', '/partner/staff'));
      final inv = (list['invitations'] as List).cast<Map<String, dynamic>>().firstWhere((i) => i['id'] == 'inv-sara');
      expect(inv['invitedBy'], 'Khalid Al-Otaibi');
      expect(inv['invitedByName'], {'en': 'Khalid Al-Otaibi', 'ar': 'خالد العتيبي'});
      final sara = (list['staff'] as List).cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == 'staff-sara');
      expect((sara['invitedByName'] as Map)['ar'], 'خالد العتيبي');
      final fresh = body(
        await raw(
          khalid,
          'POST',
          '/partner/staff-invitations',
          data: {'email': 'new.person@aurelia-gulf.example', 'role': 'reception'},
          headers: {'Idempotency-Key': 'inv-1'},
        ),
      );
      expect(fresh['invitedByName'], {'en': 'Khalid Al-Otaibi', 'ar': 'خالد العتيبي'});
    });

    test('partner notifications of the same minute come out in the web\'s order (Fatima before Faisal at 11:00)', () async {
      final hind = w.actor('hotel_manager', venueId: 'V01');
      final ids = [
        for (final n in (body(await raw(hind, 'GET', '/notifications', query: {'limit': 50}))['items'] as List).cast<Map<String, dynamic>>()) n['id'],
      ];
      expect(ids.indexOf('ntf-h-03'), lessThan(ids.indexOf('ntf-h-10')));
    });
  });
}
