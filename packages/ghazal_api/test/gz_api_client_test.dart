import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'fake_adapter.dart';

const _config = GzApiConfig(baseUrl: 'http://mock.ghazal.local/v1', useMock: true);
final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

class _Rig {
  _Rig({AuthTokens? tokens, RetryPolicy retry = RetryPolicy.none, StaticClientEnvironment? env})
      : adapter = FakeAdapter(),
        store = MemoryTokenStore(tokens),
        env = env ?? StaticClientEnvironment(languageCode: 'ar') {
    client = GzApiClient.create(config: _config, environment: this.env, tokens: store, adapter: adapter, retry: retry, onSessionEnded: () => sessionEnded++);
    repos = RestRepositories(client);
  }

  final FakeAdapter adapter;
  final MemoryTokenStore store;
  final StaticClientEnvironment env;
  late final GzApiClient client;
  late final RestRepositories repos;
  int sessionEnded = 0;
}

Map<String, Object?> _page(List<Object?> items, [String? next]) => {'items': items, 'nextCursor': next};

void main() {
  group('headers', () {
    test('every call carries language, device, platform, version and a request id', () async {
      final rig = _Rig();
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.json({'governorates': [], 'areas': [], 'referencePoints': []}));
      await rig.repos.venues.listAreas();
      final h = rig.adapter.requests.single.headers;
      expect(h['Accept-Language'], 'ar');
      expect(h['X-Device-Id'], 'device-test');
      expect(h['X-Platform'], 'ios');
      expect(h['X-App-Version'], '1.0.0');
      expect(h['X-Request-Id'], matches(_uuid));
      expect(h.containsKey('Authorization'), isFalse, reason: 'a guest sends no token');
      expect(h.containsKey('Idempotency-Key'), isFalse, reason: 'reads are not keyed');
    });

    test('the Partner context becomes X-Venue-Id or X-Provider-Id, never on /auth paths', () async {
      final env = StaticClientEnvironment(partnerContext: const PartnerRequestContext(venueId: 'V01'));
      final rig = _Rig(env: env, tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('GET', '/partner/today', (_) => FakeResponse.json(_today()));
      rig.adapter.on('POST', '/auth/otp/request', (_) => FakeResponse.json(_challenge(), status: 202));
      await rig.repos.partnerRequests.getPartnerToday();
      await rig.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login));
      expect(rig.adapter.requests[0].headers['X-Venue-Id'], 'V01');
      expect(rig.adapter.requests[0].headers.containsKey('X-Provider-Id'), isFalse);
      expect(rig.adapter.requests[1].headers.containsKey('X-Venue-Id'), isFalse);
      env.partnerContext = const PartnerRequestContext(providerId: 'vendor-flowers-zahra');
      await rig.repos.partnerRequests.getPartnerToday();
      expect(rig.adapter.requests[2].headers['X-Provider-Id'], 'vendor-flowers-zahra');
    });
  });

  group('bearer token', () {
    test('is sent when signed in and not to public /auth routes', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'));
      rig.adapter.on('GET', '/me', (_) => FakeResponse.json(sessionBody()['user']));
      rig.adapter.on('POST', '/auth/otp/request', (_) => FakeResponse.json(_challenge(), status: 202));
      await rig.repos.profile.getMe();
      await rig.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login));
      expect(rig.adapter.requests[0].headers['Authorization'], 'Bearer access-1');
      expect(rig.adapter.requests[1].headers.containsKey('Authorization'), isFalse);
    });

    test('a 401 TOKEN_EXPIRED triggers ONE refresh for any number of parallel calls, then each call replays once', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'access-old', refreshToken: 'refresh-old'));
      rig.adapter.on('GET', '/requests', (r) => r.headers['Authorization'] == 'Bearer access-new'
          ? FakeResponse.json(_page([]))
          : FakeResponse.problem(401, problemBody(401, 'TOKEN_EXPIRED')));
      rig.adapter.on('GET', '/vouchers', (r) => r.headers['Authorization'] == 'Bearer access-new'
          ? FakeResponse.json(_page([]))
          : FakeResponse.problem(401, problemBody(401, 'TOKEN_EXPIRED')));
      rig.adapter.on('POST', '/auth/refresh', (_) => FakeResponse.json(sessionBody(), delay: const Duration(milliseconds: 30)));
      final results = await Future.wait([rig.repos.requests.listRequests(), rig.repos.vouchers.listVouchers(), rig.repos.requests.listRequests()]);
      expect(results.every((p) => p.items.isEmpty), isTrue);
      expect(rig.adapter.to('POST', '/auth/refresh'), hasLength(1), reason: 'single-flight');
      final body = rig.adapter.to('POST', '/auth/refresh').single.data as Map<String, Object?>;
      expect(body, {'refreshToken': 'refresh-old', 'deviceId': 'device-test'});
      expect(await rig.store.read(), const AuthTokens(accessToken: 'access-new', refreshToken: 'refresh-new'));
      // each of the three calls ran twice: once with the old token, once replayed with the new one
      expect(rig.adapter.to('GET', '/requests'), hasLength(4));
      expect(rig.adapter.to('GET', '/vouchers'), hasLength(2));
      expect(rig.sessionEnded, 0);
    });

    test('a refresh that is refused ends the session once and surfaces the problem', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'access-old', refreshToken: 'refresh-old'));
      rig.adapter.on('GET', '/requests', (_) => FakeResponse.problem(401, problemBody(401, 'TOKEN_EXPIRED')));
      rig.adapter.on('POST', '/auth/refresh', (_) => FakeResponse.problem(401, problemBody(401, 'SESSION_REVOKED')));
      await expectLater(
        rig.repos.requests.listRequests(),
        throwsA(isA<ApiProblem>().having((p) => p.code, 'code', ApiProblemCode.tokenExpired)),
      );
      expect(await rig.store.read(), isNull);
      expect(rig.sessionEnded, 1);
    });

    test('SESSION_REVOKED on an ordinary call clears the session without a refresh attempt', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('GET', '/me', (_) => FakeResponse.problem(401, problemBody(401, 'SESSION_REVOKED')));
      await expectLater(rig.repos.profile.getMe(), throwsA(isA<ApiProblem>().having((p) => p.code, 'code', ApiProblemCode.sessionRevoked)));
      expect(rig.adapter.to('POST', '/auth/refresh'), isEmpty);
      expect(await rig.store.read(), isNull);
      expect(rig.sessionEnded, 1);
    });

    test('AUTH_REQUIRED is the guest gate: it passes through and nothing is refreshed or cleared', () async {
      final rig = _Rig();
      rig.adapter.on('POST', '/vouchers/checkout', (_) => FakeResponse.problem(401, problemBody(401, 'AUTH_REQUIRED')));
      await expectLater(
        rig.repos.vouchers.startVoucherCheckout(body: const VoucherCheckoutInput(targetType: VoucherTargetType.venue, targetId: 'V01', packageId: 'p', eventDate: LocalDate(2027, 1, 14))),
        throwsA(isA<ApiProblem>().having((p) => p.code, 'code', ApiProblemCode.authRequired)),
      );
      expect(rig.adapter.to('POST', '/auth/refresh'), isEmpty);
      expect(rig.sessionEnded, 0);
    });

    test('a network failure during refresh keeps the session', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'access-old', refreshToken: 'refresh-old'));
      rig.adapter.on('GET', '/requests', (_) => FakeResponse.problem(401, problemBody(401, 'TOKEN_EXPIRED')));
      rig.adapter.on('POST', '/auth/refresh', (_) => FakeResponse.network(DioExceptionType.connectionError));
      await expectLater(rig.repos.requests.listRequests(), throwsA(isA<ApiProblem>()));
      expect(await rig.store.read(), isNotNull);
      expect(rig.sessionEnded, 0);
    });
  });

  group('idempotency', () {
    CreateRequestInput input() => const CreateRequestInput(
          targetType: BookingTargetType.venue,
          eventDate: LocalDate(2027, 1, 14),
          voucherId: 'vch-1',
          contact: ContactInput(name: 'Reem', phone: '+96550000012', bookingFor: BookingFor.bride, shared: true),
        );

    test('a generated key per call, the same key when the caller retries with it', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('POST', '/requests', (_) => FakeResponse.problem(409, problemBody(409, 'SLOT_UNAVAILABLE')));
      Future<void> attempt({String? key}) async {
        try {
          await rig.repos.requests.createRequest(body: input(), idempotencyKey: key);
        } on ApiProblem {
          // expected
        }
      }

      await attempt();
      await attempt();
      final k1 = rig.adapter.requests[0].headers['Idempotency-Key']! as String;
      final k2 = rig.adapter.requests[1].headers['Idempotency-Key']! as String;
      expect(k1, matches(_uuid));
      expect(k2, isNot(k1), reason: 'a new intent is a new key');
      await attempt(key: k1);
      expect(rig.adapter.requests[2].headers['Idempotency-Key'], k1, reason: 'a user retry of the same intent reuses the key');
    });

    test('the automatic replay after a token refresh reuses the same key', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'access-old', refreshToken: 'refresh-old'));
      rig.adapter.on('POST', '/requests', (r) => r.headers['Authorization'] == 'Bearer access-new'
          ? FakeResponse.json(_unusedBooking(), status: 201)
          : FakeResponse.problem(401, problemBody(401, 'TOKEN_EXPIRED')));
      rig.adapter.on('POST', '/auth/refresh', (_) => FakeResponse.json(sessionBody()));
      try {
        await rig.repos.requests.createRequest(body: input());
      } on Object {
        // the stub booking body is intentionally minimal; only the headers matter here
      }
      final posts = rig.adapter.to('POST', '/requests').toList();
      expect(posts, hasLength(2));
      expect(posts[0].headers['Idempotency-Key'], posts[1].headers['Idempotency-Key']);
    });

    test('If-Match and the body travel with a request command', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('POST', '/requests/bk-1/cancel', (_) => FakeResponse.problem(409, problemBody(409, 'BOOKING_STATE_CONFLICT', extra: {'currentStatus': 'approved', 'currentVersion': 5})));
      await expectLater(
        rig.repos.requests.cancelRequest(requestId: 'bk-1', ifMatch: versionTag(4), body: const CancelRequestInput(reason: CancelReason.plansChanged)),
        throwsA(isA<ApiProblem>().having((p) => p.params['currentStatus'], 'currentStatus', 'approved').having((p) => p.params['currentVersion'], 'currentVersion', 5)),
      );
      final r = rig.adapter.requests.single;
      expect(r.headers['If-Match'], '"v4"');
      expect(r.data, {'reason': 'plans_changed'});
      expect(r.headers['Idempotency-Key'], matches(_uuid));
    });
  });

  group('problem+json and transport errors', () {
    test('slot unavailable carries params and alternatives', () async {
      final rig = _Rig();
      rig.adapter.on('POST', '/venues/V01/quotes', (_) => FakeResponse.problem(409, problemBody(409, 'SLOT_UNAVAILABLE', extra: {
            'params': {'eventDate': '2027-01-14', 'reason': 'held'},
            'alternatives': [
              {'eventDate': '2027-01-21', 'hallId': 'V01-danah'},
            ],
          })));
      try {
        await rig.repos.venues.quoteVenue(venueId: 'V01', body: VenueQuoteInput(eventDate: const LocalDate(2027, 1, 14), sections: const []));
        fail('should throw');
      } on ApiProblem catch (p) {
        expect(p.status, 409);
        expect(p.code, ApiProblemCode.slotUnavailable);
        expect(p.params['reason'], 'held');
        expect(p.alternatives.single['hallId'], 'V01-danah');
        expect(p.requestId, 'req-1');
      }
    });

    test('validation errors list the failing fields', () async {
      final rig = _Rig();
      rig.adapter.on('POST', '/auth/register', (_) => FakeResponse.problem(422, problemBody(422, 'VALIDATION_FAILED', extra: {
            'errors': [
              {'path': 'name', 'code': 'REQUIRED', 'params': {}},
            ],
          })));
      try {
        await rig.repos.auth.registerAccount(body: const RegisterInput(phone: '+96550000012', name: '', acceptedTerms: true, locale: WireLang.ar));
        fail('should throw');
      } on ApiProblem catch (p) {
        expect(p.code, ApiProblemCode.validationFailed);
        expect(p.errors.single.path, 'name');
      }
    });

    test('an HTTP error without a problem body still becomes an ApiProblem; Retry-After is kept', () async {
      final rig = _Rig();
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.text(502, '<html>bad gateway</html>'));
      rig.adapter.on('POST', '/auth/otp/request', (_) => FakeResponse.problem(429, problemBody(429, 'RATE_LIMITED'), headers: {'retry-after': '60'}));
      await expectLater(rig.repos.venues.listAreas(), throwsA(isA<ApiProblem>().having((p) => p.status, 'status', 502).having((p) => p.code, 'code', ApiProblemCode.unknown)));
      await expectLater(
        rig.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login)),
        throwsA(isA<ApiProblem>().having((p) => p.retryAfterSeconds, 'retryAfterSeconds', 60)),
      );
    });

    test('no answer is the offline or timeout form of ApiProblem', () async {
      final rig = _Rig();
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.network(DioExceptionType.connectionError));
      rig.adapter.on('GET', '/config', (_) => FakeResponse.network(DioExceptionType.receiveTimeout));
      await expectLater(rig.repos.venues.listAreas(), throwsA(isA<ApiProblem>().having((e) => e.isOffline, 'isOffline', isTrue)));
      await expectLater(rig.repos.home.getAppConfig(), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.timeout)));
    });
  });

  group('retry policy', () {
    const fast = RetryPolicy(maxRetries: 2, baseDelay: Duration.zero); // two retries: three tries in total

    test('GET retries 5xx up to three tries then succeeds', () async {
      final rig = _Rig(retry: fast);
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.problem(503, problemBody(503, 'PAYMENT_GATEWAY_ERROR')));
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.network(DioExceptionType.connectionError));
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.json({'governorates': [], 'areas': [], 'referencePoints': []}));
      final areas = await rig.repos.venues.listAreas();
      expect(areas.areas, isEmpty);
      expect(rig.adapter.to('GET', '/areas'), hasLength(3));
    });

    test('GET gives up after the last try and keeps the X-Request-Id', () async {
      final rig = _Rig(retry: fast);
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.problem(500, problemBody(500, 'NOT_FOUND')));
      await expectLater(rig.repos.venues.listAreas(), throwsA(isA<ApiProblem>()));
      final calls = rig.adapter.to('GET', '/areas').toList();
      expect(calls, hasLength(3));
      expect(calls.map((c) => c.headers['X-Request-Id']).toSet(), hasLength(1));
    });

    test('4xx, POST, PATCH and DELETE never retry automatically', () async {
      final rig = _Rig(retry: fast, tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('GET', '/areas', (_) => FakeResponse.problem(404, problemBody(404, 'NOT_FOUND')));
      rig.adapter.on('POST', '/auth/otp/request', (_) => FakeResponse.problem(503, problemBody(503, 'PAYMENT_GATEWAY_ERROR')));
      rig.adapter.on('PATCH', '/me', (_) => FakeResponse.network(DioExceptionType.connectionError));
      rig.adapter.on('DELETE', '/wedding/checklist/items/i1', (_) => FakeResponse.problem(503, problemBody(503, 'PAYMENT_GATEWAY_ERROR')));
      await expectLater(rig.repos.venues.listAreas(), throwsA(isA<ApiProblem>()));
      await expectLater(rig.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login)), throwsA(isA<ApiProblem>()));
      await expectLater(rig.repos.profile.updateMe(body: const UpdateMeInput(name: 'x')), throwsA(isA<ApiProblem>().having((e) => e.isOffline, 'isOffline', isTrue)));
      await expectLater(rig.repos.wedding.deleteChecklistItem(itemId: 'i1'), throwsA(isA<ApiProblem>()));
      for (final p in ['/areas', '/auth/otp/request', '/me', '/wedding/checklist/items/i1']) {
        expect(rig.adapter.requests.where((r) => r.path == p), hasLength(1), reason: p);
      }
    });
  });

  group('generated repositories', () {
    test('lists send repeated keys, cursor and limit, and parse cursor pages of a sealed union', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('GET', '/vouchers', (_) => FakeResponse.json(_page([{'voucher': _boundVoucher(), 'target': null, 'hallName': null, 'packageName': null}], 'cursor-2')));
      final page = await rig.repos.vouchers.listVouchers(status: [VoucherStatus.active, VoucherStatus.bound], cursor: 'cursor-1', limit: 2);
      final r = rig.adapter.requests.single;
      expect(r.uri.query, 'status=active&status=bound&cursor=cursor-1&limit=2');
      expect(page.nextCursor, 'cursor-2');
      expect(page.hasMore, isTrue);
      expect(page.items.single.voucher, isA<Voucher>());
      expect((page.items.single.voucher as Voucher).quoteFils.voucher, 15400000);
    });

    test('filters: arrays repeat, nulls vanish, civil dates stay civil, enums use wire values', () async {
      final rig = _Rig();
      rig.adapter.on('GET', '/venues', (_) => FakeResponse.json(_page([])));
      await rig.repos.venues.searchVenues(
        areaIds: ['salmiya', 'sharq'],
        types: [VenueType.hotel, VenueType.privateHall],
        date: const LocalDate(2027, 1, 14),
        guests: 350,
        audience: Audience.women,
        sort: VenueSort.voucherPrice,
        voucherOnly: true,
      );
      final q = rig.adapter.requests.single.uri.queryParametersAll;
      expect(q['areaIds'], ['salmiya', 'sharq']);
      expect(q['types'], ['hotel', 'private-hall']);
      expect(q['date'], ['2027-01-14']);
      expect(q['guests'], ['350']);
      expect(q['audience'], ['women']);
      expect(q['sort'], ['voucher_price']);
      expect(q['voucherOnly'], ['true']);
      expect(q.containsKey('q'), isFalse);
    });

    test('path parameters are encoded and typed', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('PUT', '/wishlist/venue/V01', (_) => FakeResponse.json({'type': 'venue', 'id': 'V01', 'savedAt': '2026-11-12T16:00:00+03:00', 'lastSeenPrice': null}));
      rig.adapter.on('GET', '/partner/vouchers/GV-2611-K7QM/check', (_) => FakeResponse.json({'ok': false, 'reason': 'not_confirmed', 'usedAt': null, 'voucher': null, 'booking': null}));
      final saved = await rig.repos.wedding.saveWishlistItem(type: SavedType.venue, id: 'V01', body: const SavedItemInput());
      expect(saved.id, 'V01');
      final check = await rig.repos.partnerBookings.checkVoucherCode(code: 'GV-2611-K7QM');
      expect(check.ok, isFalse);
      expect(check.reason, RedeemFailure.notConfirmed);
    });

    test('204 answers are void, and a PDF comes back as bytes', () async {
      final rig = _Rig(tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      rig.adapter.on('POST', '/notifications/n1/read', (_) => FakeResponse.empty(204));
      rig.adapter.on('GET', '/receipts/RC-050039/pdf', (_) => FakeResponse.pdf([37, 80, 68, 70]));
      await rig.repos.notifications.markNotificationRead(notificationId: 'n1');
      expect(await rig.repos.vouchers.getReceiptPdf(receiptNo: 'RC-050039'), [37, 80, 68, 70]);
    });
  });
}

Map<String, Object?> _challenge() => {'challengeId': 'ch_1', 'channel': 'whatsapp', 'destinationHint': '+965 **** 0012', 'expiresInSeconds': 300, 'resendAfterSeconds': 60, 'codeLength': 6};

Map<String, Object?> _today() => {
      'tiles': {'requests': 1, 'awaitingClient': 0, 'vouchersRedeemed': 0, 'vouchersBought': 0, 'openDatesNext30Days': 4, 'softDateCount': 2, 'unreadMessages': 0},
      'needsYou': <Object?>[],
      'events': <Object?>[],
      'activeListings': null,
    };

Map<String, Object?> _unusedBooking() => {'id': 'bk-1'};

Map<String, Object?> _boundVoucher() => {
      'id': 'vch-GV-2611-K7QM', 'kind': 'bound', 'code': 'GV-2611-K7QM', 'clientId': 'user-reem', 'priceFils': 2000, 'status': 'bound',
      'validUntil': '2027-01-11T12:31:00+03:00', 'qr': {'payload': 'gz:v1:GV-2611-K7QM:V01:CBDA', 'version': 1}, 'usedAt': null, 'usedReason': null,
      'redeemedBy': null, 'targetType': 'venue', 'venueOrProviderId': 'V01', 'hallId': 'V01-danah', 'packageId': 'V01-ladies-weekend',
      'eventDate': '2027-01-14', 'guests': 350, 'quoteFils': {'standard': 18200000, 'voucher': 15400000}, 'purchasedAt': '2026-11-12T12:31:00+03:00',
      'reuseUntil': null, 'bookingId': 'bk-1', 'payment': null, 'releasedAt': null, 'releaseReason': null, 'forfeitedAt': null, 'creditEligible': false,
      'refundRequestId': null,
    };
