// The gate and the sign-in landing through the REAL router (`buildGzRouter` with a `ref`: redirect and refresh on the session), the real
// navigator and the in-process mock. The FakeNavigator tests of gate_test.dart cannot see a provider cycle or a redirect.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerLoginStatus;
import 'package:ghazal_ui/ghazal_ui.dart' show GzAppKind;

import '../data/kit_world.dart';
import '../nav/nav_fixture.dart';

const GzRouterSpec _clientSpec = GzRouterSpec(
  app: GzAppKind.client,
  tabs: <GzTabSpec>[GzTabSpec('discover', 'CL-DISC-01'), GzTabSpec('saved', 'CL-SAVD-01')],
  chrome: <String, GzScreenChrome>{
    'CL-ONBD-01': GzScreenChrome(),
    'CL-DISC-01': GzScreenChrome(tab: 'discover', tabBar: true),
    'CL-VENU-01': GzScreenChrome(tab: 'discover'),
    'CL-VCHR-01': GzScreenChrome(),
    'CL-SAVD-01': GzScreenChrome(tab: 'saved', tabBar: true),
    'CL-AUTH-01': GzScreenChrome(sheet: true),
    'CL-AUTH-02': GzScreenChrome(),
  },
  paths: <String, String>{
    'CL-ONBD-01': '/onboarding/start',
    'CL-DISC-01': '/discover/home',
    'CL-VENU-01': '/discover/venue',
    'CL-VCHR-01': '/voucher/get',
    'CL-SAVD-01': '/saved/home',
    'CL-AUTH-01': '/auth/gate',
    'CL-AUTH-02': '/auth/code',
  },
  startPath: '/onboarding/start',
  homePath: '/discover/home',
);

const GzRouterSpec _partnerSpec = GzRouterSpec(
  app: GzAppKind.partner,
  tabs: <GzTabSpec>[GzTabSpec('today', 'HL-TODY-01'), GzTabSpec('bookings', 'HL-BOOK-01')],
  chrome: <String, GzScreenChrome>{
    'HL-ACCS-01': GzScreenChrome(),
    'HL-TODY-01': GzScreenChrome(tab: 'today', tabBar: true),
    'HL-BOOK-01': GzScreenChrome(tab: 'bookings', tabBar: true),
  },
  paths: <String, String>{'HL-ACCS-01': '/access/sign-in', 'HL-TODY-01': '/today/home', 'HL-BOOK-01': '/bookings/home'},
  startPath: '/access/sign-in',
  homePath: '/today/home',
  requireSession: true,
  publicPrefixes: <String>['/access'],
);

final _gate = Provider<bool Function(GateReason, GateResume?)>(
  (ref) =>
      (reason, resume) => ref.requireSignIn(reason, resume: resume),
);

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  testWidgets('gate sheet, sign in, resume at the gated route with its params, through the real router (no provider cycle)', (tester) async {
    final rig = await pumpNav(
      tester,
      initialLocation: '/discover/home',
      useSession: true,
      spec: _clientSpec,
      overrides: [mockBackendProvider.overrideWithValue(world.world.mock)],
    );
    final c = rig.container;
    expect(rig.shows('CL-DISC-01'), isTrue);

    expect(c.read(_gate)(GateReason.voucher, const GateResume('CL-VCHR-01', {'venueId': 'V01', 'date': '2027-01-14'})), isFalse);
    await rig.settle();
    expect(rig.nav.currentId, kGateSheetId);
    rig.nav.push('CL-AUTH-02'); // the code step, pushed over the sheet
    await rig.settle();
    expect(rig.nav.currentId, 'CL-AUTH-02');

    final notifier = c.read(sessionProvider.notifier);
    await tester.runAsync(() async {
      await notifier.requestOtp('50000012');
      await notifier.verifyOtp('123456'); // opens the session and runs completeGate
    });
    await rig.settle();

    expect(tester.takeException(), isNull);
    expect(c.read(sessionProvider), isA<ClientSession>());
    expect(c.read(gateProvider), isNull);
    expect(rig.nav.currentId, 'CL-VCHR-01');
    expect(rig.seen.of('CL-VCHR-01').params, {'venueId': 'V01', 'date': '2027-01-14'}, reason: 'the screen was told its params');
    expect(rig.shows('CL-VCHR-01'), isTrue);
    // the sheet and the code screen are gone: popping leaves the screen the guest came from
    rig.nav.pop();
    await rig.settle();
    expect(rig.shows('CL-DISC-01'), isTrue);
  });

  testWidgets('a sign-in landing set before the sign-in call is consumed in the same navigation: partner access lands on Today with params', (
    tester,
  ) async {
    final rig = await pumpNav(
      tester,
      initialLocation: '/access/sign-in',
      useSession: true,
      spec: _partnerSpec,
      overrides: [mockBackendProvider.overrideWithValue(world.world.mock)],
    );
    final c = rig.container;
    expect(rig.shows('HL-ACCS-01'), isTrue);
    final builtBefore = rig.seen.builds['HL-ACCS-01'];

    // the flow names where the sign-in lands (route name + params) before it signs in
    c.read(signInLandingProvider.notifier).set(const GateResume('HL-TODY-01', {'firstRun': true, 'venueId': 'V01'}));
    await tester.runAsync(() async {
      final result = await c.read(sessionProvider.notifier).partnerLogin('hind@aurelia-gulf.example', 'Ghazal#2026');
      expect(result.status, PartnerLoginStatus.codeRequired); // a new device: the emailed code follows
      await c.read(sessionProvider.notifier).partnerVerifyCode('123456');
    });
    await rig.settle();

    expect(tester.takeException(), isNull);
    expect(c.read(sessionProvider).isSignedIn, isTrue);
    expect(rig.shows('HL-TODY-01'), isTrue);
    expect(rig.nav.currentId, 'HL-TODY-01');
    expect(rig.seen.of('HL-TODY-01').params, {'firstRun': true, 'venueId': 'V01'}, reason: 'the screen was told its params');
    expect(c.read(signInLandingProvider), isNull, reason: 'the landing is consumed once');
    expect(rig.seen.builds['HL-ACCS-01'], builtBefore, reason: 'the access screen was not rebuilt on the way out');
  });

  test('gzRedirect: leaving the start screen goes to the landing route when one is named, else to the home tab', () {
    expect(gzRedirect(_partnerSpec, signedIn: true, location: '/access/sign-in'), '/today/home');
    expect(gzRedirect(_partnerSpec, signedIn: true, location: '/access/sign-in', landing: const GateResume('HL-BOOK-01')), '/bookings/home');
    expect(gzRedirect(_partnerSpec, signedIn: true, location: '/access/sign-in', landing: const GateResume('HL-NOPE-01')), '/today/home');
    expect(gzRedirect(_partnerSpec, signedIn: false, location: '/bookings/home'), '/access/sign-in');
  });
}
