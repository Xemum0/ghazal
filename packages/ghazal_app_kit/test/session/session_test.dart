import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_app_kit/src/data/data.dart';
import 'package:ghazal_app_kit/src/session/session.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../data/kit_world.dart';

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  test('a guest signs in with a code, the session is a client, signing out returns to a guest', () async {
    final c = world.container();
    expect(c.read(sessionProvider), isA<GuestSession>());
    final notifier = c.read(sessionProvider.notifier);

    final challenge = await notifier.requestOtp('5000 0012');
    expect(challenge.codeLength, 6);
    final session = await notifier.verifyOtp('123456');

    expect(c.read(sessionProvider), same(session));
    expect(session.user.id, isNotEmpty);
    expect(session.user.monogram, isNotEmpty);
    expect(session.isNewUser, isFalse);
    expect(await c.read(tokenStoreProvider).read(), isNotNull);
    // the repositories now answer as that client
    final wallet = await c.read(vouchersRepositoryProvider).listVouchers();
    expect(wallet.items, isNotEmpty);

    await notifier.signOut();
    expect(c.read(sessionProvider), isA<GuestSession>());
    expect(await c.read(tokenStoreProvider).read(), isNull);
  });

  test('a wrong code keeps the challenge open for a retry; a locked code is an ApiProblem', () async {
    final c = world.container();
    final notifier = c.read(sessionProvider.notifier);
    await notifier.requestOtp('50000012');
    await expectLater(notifier.verifyOtp('000000'), throwsA(isA<ApiProblem>().having((p) => p.code, 'code', ApiProblemCode.otpLocked)));
    expect(c.read(sessionProvider), isA<GuestSession>());
    expect(notifier.challenge, isNotNull);
    expect(await notifier.verifyOtp('123456'), isA<ClientSession>());
  });

  test('an unknown number becomes a new client', () async {
    final c = world.container();
    final notifier = c.read(sessionProvider.notifier);
    await notifier.requestOtp('50001234');
    final session = await notifier.verifyOtp('123456');
    expect(session.isNewUser, isTrue);
  });

  test('a refresh the server rejects signs the app out', () async {
    final c = world.container();
    final notifier = c.read(sessionProvider.notifier);
    await notifier.loadPersona('reem');
    expect(c.read(sessionProvider), isA<ClientSession>());

    final tokens = (await c.read(tokenStoreProvider).read())!;
    await c.read(tokenStoreProvider).write(AuthTokens(accessToken: tokens.accessToken, refreshToken: 'never-issued'));
    world.world.control.setScenario('expired'); // the next call answers TOKEN_EXPIRED, the refresh is then refused
    await expectLater(c.read(profileRepositoryProvider).getMe(), throwsA(isA<ApiProblem>()));
    // endedByServer runs without awaiting inside the interceptor: let it finish
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(sessionProvider), isA<GuestSession>());
    expect(await c.read(tokenStoreProvider).read(), isNull);
  });

  test('partner login on a new device asks for the emailed code, then opens a hotel session', () async {
    final c = world.container();
    final notifier = c.read(sessionProvider.notifier);
    final result = await notifier.partnerLogin('hind@aurelia-gulf.example', 'Ghazal#2026');
    expect(result.status, PartnerLoginStatus.codeRequired);
    expect(c.read(sessionProvider), isA<GuestSession>());

    final session = await notifier.partnerVerifyCode('123456');
    expect(session.accountType, PartnerAccountType.venue);
    expect(session.role, StaffRole.manager);
    expect(session.venueId, 'V01');
    expect(c.read(sessionProvider), same(session));

    // the partner context travels with every call: the inbox answers
    final inbox = await c.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending);
    expect(inbox.items, isNotEmpty);
  });

  test('a service provider session carries the provider context', () async {
    final c = world.container();
    final session = await c.read(sessionProvider.notifier).loadPersona('provider');
    expect(session, isA<PartnerSession>());
    final partner = session as PartnerSession;
    expect(partner.isProvider, isTrue);
    expect(partner.providerId, isNotNull);
    expect(partner.venueId, isNull);
  });

  test('restore opens the session kept in the token store', () async {
    final c = world.container();
    await c.read(sessionProvider.notifier).loadPersona('reem');
    final second = world.container(overrides: [tokenStoreProvider.overrideWithValue(c.read(tokenStoreProvider))]);
    expect(second.read(sessionProvider), isA<GuestSession>());
    await second.read(sessionProvider.notifier).restore();
    expect(second.read(sessionProvider), isA<ClientSession>());
  });
}
