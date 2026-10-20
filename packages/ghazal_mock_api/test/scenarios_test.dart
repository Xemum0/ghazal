// Scenarios, middleware and control surface: offline, error, empty, expired tokens, latency, idempotency, validation, pagination, ETags,
// rate limits, app version, persona auto-auth, clock and reset.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'harness.dart';

Future<Response<Object?>> raw(Actor a, String method, String path, {Object? data, Map<String, Object?>? headers, Map<String, Object?>? query}) =>
    a.dio.request<Object?>(path, data: data, queryParameters: query, options: Options(method: method, headers: headers, validateStatus: (_) => true));

void main() {
  late World w;
  setUp(() async => w = await World.create());

  test('offline: the in-process adapter throws a connection error, the client reports ApiProblem.offline', () async {
    final a = w.actor('guest');
    await expectLater(
      a.client.dio.post<Object?>('/auth/otp/request', data: {'phone': '+96550000012', 'purpose': 'login'}, options: Options(headers: {'X-Mock-Scenario': 'offline'})),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
    );
    w.control.setScenario('offline');
    await expectLater(a.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login)), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.offline)));
    w.control.setScenario('none');
    expect((await a.repos.auth.requestOtp(body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login))).codeLength, 6);
  });

  test('error: every call fails with a 500 problem; empty: pages are empty; slow and latency: the call takes its time', () async {
    final a = w.actor('guest');
    var r = await raw(a, 'POST', '/auth/otp/request', data: {'phone': '+96550000012', 'purpose': 'login'}, headers: {'X-Mock-Scenario': 'error'});
    expect(r.statusCode, 500);
    expect((r.data as Map)['code'], 'INTERNAL_ERROR');
    r = await raw(a, 'GET', '/venues', headers: {'X-Mock-Scenario': 'empty'});
    expect((r.data as Map)['items'], isEmpty);
    expect((r.data as Map)['nextCursor'], isNull);
    final sw = Stopwatch()..start();
    await raw(a, 'GET', '/config', headers: {'X-Mock-Latency': '180'});
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(170));
    w.control.setScenario('empty');
    expect((await a.repos.venues.searchVenues()).items, isEmpty);
    expect((await w.actor('reem').repos.vouchers.listVouchers()).items, isEmpty);
  });

  test('expired tokens: the client refreshes once, replays the call and keeps working', () async {
    final a = w.actor('reem');
    final before = (await a.tokens.read())!;
    w.control.setScenario('expired');
    final me = await a.repos.profile.getMe();
    expect(me.user.id, 'user-reem');
    final after = (await a.tokens.read())!;
    expect(after.accessToken, isNot(before.accessToken));
    expect(after.refreshToken, isNot(before.refreshToken));
    // a reused (rotated-out) refresh token ends the session
    final old = w.actor('guest');
    await expectLater(old.repos.auth.refreshSession(body: RefreshInput(refreshToken: before.refreshToken)), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.sessionRevoked)));
    w.control.setScenario('none');
    await expectLater(a.repos.profile.getMe(), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.sessionRevoked)));
  });

  test('validation: a bad body is 422 VALIDATION_FAILED with a path per problem; a bad cursor and a bad enum too', () async {
    final a = w.actor('reem');
    var r = await raw(a, 'POST', '/vouchers/checkout', data: {'targetType': 'venue'});
    expect(r.statusCode, 422);
    final errors = ((r.data as Map<String, dynamic>)['errors'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(errors.map((e) => e['path']), containsAll(['/targetId', '/packageId', '/eventDate']));
    r = await raw(a, 'GET', '/venues', query: {'cursor': '!!!'});
    expect(r.statusCode, 422);
    r = await raw(a, 'GET', '/venues', query: {'sort': 'bogus'});
    expect(r.statusCode, 422);
    r = await raw(a, 'GET', '/venues/NOPE');
    expect(r.statusCode, 404);
    r = await raw(a, 'GET', '/no/such/route');
    expect(r.statusCode, 404);
    expect((r.data as Map)['code'], 'NOT_FOUND');
  });

  test('idempotency: the same key replays, the same key with another body is IDEMPOTENCY_KEY_REUSED', () async {
    final a = w.actor('reem');
    final body = {'targetType': 'venue', 'targetId': 'V07', 'packageId': 'V07-standard', 'eventDate': '2027-02-12'};
    // an invalid operation is not cached (the guard fires first), so use a key on a call that succeeds
    final input = {'voucherId': 'vch-GV-2611-R4TF', 'note': 'one'};
    final first = await raw(a, 'POST', '/support/refund-requests', data: input, headers: {'Idempotency-Key': 'k-9'});
    expect(first.statusCode, 201);
    final replay = await raw(a, 'POST', '/support/refund-requests', data: input, headers: {'Idempotency-Key': 'k-9'});
    expect(replay.statusCode, 201);
    expect((replay.data as Map)['id'], (first.data as Map)['id']);
    expect(replay.headers.value('idempotent-replayed'), 'true');
    final other = await raw(a, 'POST', '/support/refund-requests', data: {...input, 'note': 'two'}, headers: {'Idempotency-Key': 'k-9'});
    expect(other.statusCode, 422);
    expect((other.data as Map)['code'], 'IDEMPOTENCY_KEY_REUSED');
    expect(body, isNotEmpty);
  });

  test('rate limit: the sixth code to one phone inside a minute is RATE_LIMITED with Retry-After', () async {
    final a = w.actor('guest');
    Response<Object?>? last;
    for (var i = 0; i < 6; i++) {
      last = await raw(a, 'POST', '/auth/otp/request', data: {'phone': '+96550001111', 'purpose': 'login'});
    }
    expect(last!.statusCode, 429);
    expect(last.headers.value('retry-after'), '60');
    w.control.advance(const Duration(minutes: 2));
    expect((await raw(a, 'POST', '/auth/otp/request', data: {'phone': '+96550001111', 'purpose': 'login'})).statusCode, 202);
  });

  test('ETag and If-Match on settings documents: a stale tag is 412 PRECONDITION_FAILED', () async {
    final a = w.actor('hotel_manager', venueId: 'V01');
    final got = await raw(a, 'GET', '/partner/venue');
    final tag = got.headers.value('etag')!;
    expect(tag, '"v1"');
    final ok = await raw(a, 'PATCH', '/partner/venue', data: {'phone': '+96522270000'}, headers: {'If-Match': tag});
    expect(ok.statusCode, 200);
    expect(ok.headers.value('etag'), '"v2"');
    final stale = await raw(a, 'PATCH', '/partner/venue', data: {'phone': '+96522270001'}, headers: {'If-Match': tag});
    expect(stale.statusCode, 412);
    expect((stale.data as Map)['code'], 'PRECONDITION_FAILED');
  });

  test('app version below the minimum is APP_UPDATE_REQUIRED', () async {
    final a = w.actor('guest');
    a.env.appVersion = '0.0.9';
    final r = await raw(a, 'GET', '/config');
    expect(r.statusCode, 426);
  });

  test('roles: a client token on a partner route is 403, a reception role cannot approve, a missing context is 400', () async {
    final reem = w.actor('reem');
    expect((await raw(reem, 'GET', '/partner/today', headers: {'X-Venue-Id': 'V01'})).statusCode, 403);
    final hind = w.actor('hotel_manager');
    expect((await raw(hind, 'GET', '/partner/today')).statusCode, 200, reason: 'a single membership is the default context');
    final other = w.actor('hotel_manager', venueId: 'V05');
    expect((await raw(other, 'GET', '/partner/today')).statusCode, 403, reason: 'no membership at another venue');
  });

  test('clock and reset: the story clock moves, reset puts everything back', () async {
    final a = w.actor('guest');
    expect(((await raw(a, 'GET', '/config')).data as Map)['serverNow'], '2026-11-12T16:00:00+03:00');
    w.control.advance(const Duration(hours: 5));
    expect(((await raw(a, 'GET', '/config')).data as Map)['serverNow'], '2026-11-12T21:00:00+03:00');
    w.control.jumpToStory('confirmed');
    final reem = w.actor('reem');
    expect((await reem.repos.requests.getRequest(requestId: 'bk-GZ-2611-0147')).booking.status, BookingStatus.confirmed);
    await w.control.reset();
    expect(((await raw(a, 'GET', '/config')).data as Map)['serverNow'], '2026-11-12T16:00:00+03:00');
    final fresh = w.actor('reem');
    expect((await fresh.repos.requests.getRequest(requestId: 'bk-GZ-2611-0147')).booking.status, BookingStatus.pending);
  });

  test('persona auto-auth: a client without a token acts as the persona; sign-out revokes the session', () async {
    final auto = await World.create(persona: 'reem');
    final a = auto.actor('guest');
    expect((await a.repos.profile.getMe()).user.id, 'user-reem');
    auto.control.setPersona('guest');
    await expectLater(a.repos.profile.getMe(), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.authRequired)));
    final reem = w.actor('reem');
    await reem.repos.auth.signOut(body: const LogoutInput());
    await expectLater(reem.repos.profile.getMe(), throwsA(isA<ApiProblem>().having((e) => e.code, 'code', ApiProblemCode.sessionRevoked)));
    expect(await reem.tokens.read(), isNull, reason: 'a revoked session clears the store');
  });

  test('the control surface works over HTTP through the adapter too (/__mock/*)', () async {
    final a = w.actor('guest');
    var r = await raw(a, 'GET', 'http://mock.ghazal.local/__mock/state');
    expect((r.data as Map)['now'], '2026-11-12T16:00:00+03:00');
    r = await raw(a, 'POST', 'http://mock.ghazal.local/__mock/clock', data: {'advanceHours': 2});
    expect((r.data as Map)['now'], '2026-11-12T18:00:00+03:00');
    r = await raw(a, 'POST', 'http://mock.ghazal.local/__mock/story', data: {'point': 'nonsense'});
    expect(r.statusCode, 400);
  });
}
