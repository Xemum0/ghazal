import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/src/data/data.dart';
import 'package:ghazal_app_kit/src/demo/demo_control.dart';
import 'package:ghazal_app_kit/src/session/session.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../data/kit_world.dart';

/// The hotel manager's pending inbox, as a screen's data provider would read it (it watches the repository provider).
final _inbox = FutureProvider<int>((ref) async {
  final page = await ref.watch(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending);
  return page.items.length;
});

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  test('switching persona changes the session and the screens refetch as the new person', () async {
    final c = world.container();
    c.listen(_inbox, (_, _) {});
    await expectLater(c.read(_inbox.future), throwsA(isA<ApiProblem>())); // a guest has no inbox

    await c.read(demoProvider.notifier).switchPersona('hotel_manager');

    final session = c.read(sessionProvider);
    expect(session, isA<PartnerSession>());
    expect((session as PartnerSession).venueId, 'V01');
    expect(c.read(demoProvider).persona, 'hotel_manager');
    expect(await c.read(_inbox.future), greaterThan(0));

    await c.read(demoProvider.notifier).switchPersona('reem');
    expect(c.read(sessionProvider), isA<ClientSession>());
    await c.read(demoProvider.notifier).switchPersona('guest');
    expect(c.read(sessionProvider), isA<GuestSession>());
  });

  test('jumping to a story point moves the hero request, reset brings it back and keeps the persona', () async {
    final c = world.container();
    c.listen(_inbox, (_, _) {});
    final demo = c.read(demoProvider.notifier);
    await demo.switchPersona('hotel_manager');
    final pending = await c.read(_inbox.future);

    demo.jumpTo('approved');
    expect(c.read(demoProvider).point, 'approved');
    expect(await c.read(_inbox.future), pending - 1);

    await demo.resetStory();
    expect(c.read(demoProvider).persona, 'hotel_manager');
    expect(c.read(sessionProvider), isA<PartnerSession>());
    expect(await c.read(_inbox.future), pending);
  });

  test('a forced scenario applies to the next requests until cleared', () async {
    final c = world.container();
    final demo = c.read(demoProvider.notifier);
    await demo.switchPersona('hotel_manager');
    demo.forceScenario('empty');
    expect(c.read(demoProvider).scenario, 'empty');
    expect((await c.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending)).items, isEmpty);

    demo.forceScenario('none');
    expect((await c.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending)).items, isNotEmpty);
  });

  test('advancing the clock moves the story time', () async {
    final c = world.container();
    final before = world.world.control.now;
    c.read(demoProvider.notifier).advance(const Duration(hours: 24));
    expect(world.world.control.now.difference(before), const Duration(hours: 24));
    expect(c.read(demoProvider).storyNow, world.world.control.nowText);
  });

  test('the tools exist outside production with a mock, and nowhere else', () {
    expect(world.container().read(demoToolsAvailableProvider), isTrue);
    expect(world.container(env: const AppEnv(environment: GzEnvironment.prod)).read(demoToolsAvailableProvider), isFalse);
    expect(world.container(withMock: false).read(demoToolsAvailableProvider), isFalse);
  });

  test('the personas, scenarios and story points offered are the mock ones', () {
    expect(kDemoPersonas, ['guest', 'new_client', 'reem', 'hotel_manager', 'hotel_admin', 'provider']);
    expect(kDemoScenarios, hasLength(6));
    expect(kDemoStoryPoints, contains('counter_offer'));
  });
}
