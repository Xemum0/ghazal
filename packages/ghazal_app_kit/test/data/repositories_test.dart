import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/src/data/data.dart';
import 'package:ghazal_app_kit/src/session/session.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'kit_world.dart';

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  test('a guest searches venues through the venues repository provider', () async {
    final c = world.container();
    final page = await c.read(venuesRepositoryProvider).searchVenues(limit: 6);
    expect(page.items, isNotEmpty);
    expect(page.items.length, lessThanOrEqualTo(6));
  });

  test('a guest is refused a gated call with AUTH_REQUIRED', () async {
    final c = world.container();
    await expectLater(
      c.read(vouchersRepositoryProvider).listVouchers(),
      throwsA(isA<ApiProblem>().having((p) => p.code, 'code', ApiProblemCode.authRequired)),
    );
  });

  test('Reem lists her wallet', () async {
    final c = world.container();
    await c.read(sessionProvider.notifier).loadPersona('reem');
    final wallet = await c.read(vouchersRepositoryProvider).listVouchers();
    expect(wallet.items, isNotEmpty);
  });

  test('the hotel manager lists the pending requests of venue V01 (Reem hero request)', () async {
    final c = world.container();
    final session = await c.read(sessionProvider.notifier).loadPersona('hotel_manager');
    expect((session as PartnerSession).venueId, 'V01');
    final inbox = await c.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending);
    expect(inbox.items, isNotEmpty);
  });

  test('an error scenario becomes an ApiProblem with a status above 499', () async {
    final c = world.container();
    world.world.control.setScenario('error');
    await expectLater(
      c.read(venuesRepositoryProvider).searchVenues(limit: 3),
      throwsA(isA<ApiProblem>().having((p) => p.status, 'status', greaterThanOrEqualTo(500))),
    );
  });

  test('the offline scenario becomes ApiProblem.offline', () async {
    final c = world.container();
    world.world.control.setScenario('offline');
    await expectLater(c.read(venuesRepositoryProvider).searchVenues(limit: 3), throwsA(isA<ApiProblem>().having((p) => p.isOffline, 'isOffline', true)));
  });

  test('the empty scenario answers empty pages', () async {
    final c = world.container();
    world.world.control.setScenario('empty');
    final page = await c.read(venuesRepositoryProvider).searchVenues(limit: 3);
    expect(page.items, isEmpty);
  });

  test('the language header follows the locale provider on the next call', () async {
    final c = world.container();
    final env = c.read(clientEnvironmentProvider);
    expect(env.languageCode, 'en');
    c.read(localeProvider.notifier).setLocale(const Locale('ar'));
    expect(env.languageCode, 'ar');
  });

  test('bumping the backend epoch rebuilds the client and every repository provider', () async {
    final c = world.container();
    final before = c.read(repositoriesProvider);
    c.read(backendEpochProvider.notifier).bump();
    expect(identical(c.read(repositoriesProvider), before), isFalse);
  });

  test('a fake repository overrides its provider', () async {
    final fake = _FakeVenues();
    final c = world.container(overrides: [venuesRepositoryProvider.overrideWithValue(fake)]);
    expect(c.read(venuesRepositoryProvider), same(fake));
  });

  test('the 29 voucher-model contract codes parse and have message keys', () {
    const wires = [
      'OPEN_REQUEST_LIMIT', 'VOUCHER_NOT_OFFERED', 'VOUCHER_NOT_USABLE', 'VOUCHER_TARGET_MISMATCH', 'VOUCHER_CHECKOUT_EXPIRED', 'VOUCHER_UNKNOWN',
      'VOUCHER_OTHER_PARTNER', 'VOUCHER_NOT_CONFIRMED', 'VOUCHER_ALREADY_USED', 'CREDIT_NOT_ELIGIBLE', 'REFUND_REQUEST_EXISTS',
      'CONFIRM_WINDOW_ENDED', 'UNDO_WINDOW_ENDED', 'PLAN_RATES_NOT_ANNOUNCED', 'LISTING_NOT_EDITABLE', 'LISTING_STATE_CONFLICT', 'MEDIA_TOO_LARGE',
      'MEDIA_TYPE_UNSUPPORTED', 'REVIEW_ALREADY_REPLIED', 'REVIEW_NOT_ALLOWED', 'VISIT_SLOT_TAKEN', 'VISIT_NOT_ALLOWED', 'VISIT_STATE_CONFLICT',
      'STAFF_LAST_ADMIN', 'INVITATION_EXPIRED', 'EMAIL_ALREADY_INVITED', 'CREDENTIALS_INVALID', 'VENUE_CONTEXT_REQUIRED', 'PRECONDITION_FAILED',
    ];
    expect(wires, hasLength(29));
    for (final w in wires) {
      final code = ApiProblemCode.parse(w);
      expect(code, isNot(ApiProblemCode.unknown), reason: w);
      expect(code.wire, w);
      expect(code.messageKey, startsWith('apiError'));
    }
    expect(ApiProblemCode.voucherNotUsable.messageKey, 'apiErrorVoucherNotUsable');
  });
}

class _FakeVenues implements VenuesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
