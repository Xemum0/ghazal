import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'state_world.dart';

/// A venue id Reem has not saved.
String _unsaved(FavouritesState s) => ['V02', 'V03', 'V04', 'V05', 'V06', 'V07'].firstWhere((id) => !s.venue.contains(id));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StateWorld world;
  setUpAll(() async => world = await StateWorld.load());
  setUp(() async => world.fresh());
  tearDown(StateWorld.disposeAll);

  test('signed out there is nothing to save to: a heart does nothing', () async {
    final c = world.container();
    final n = c.read(favouritesProvider.notifier);
    expect((await c.read(favouritesProvider.future)).total, 0);
    expect(await n.toggle(SavedType.venue, 'V01'), isFalse);
    expect(c.read(favouritesProvider).value!.total, 0);
  });

  test('Reem favourites come from the server and a heart is optimistic and written through', () async {
    final c = world.container();
    await c.read(sessionProvider.notifier).loadPersona('reem');
    final before = await c.read(favouritesProvider.future);
    expect(before.total, greaterThan(0));

    final n = c.read(favouritesProvider.notifier);
    final id = _unsaved(before);
    final pending = n.toggle(SavedType.venue, id); // not awaited: the heart is already on
    expect(c.read(favouritesProvider).value!.contains(SavedType.venue, id), isTrue);
    expect(await pending, isTrue);
    await n.settled;
    final server = await world.repos('reem').wedding.listWishlist();
    expect(server.items.any((e) => e.item.id == id), isTrue);

    expect(await n.toggle(SavedType.venue, id), isFalse);
    await n.settled;
    expect((await world.repos('reem').wedding.listWishlist()).items.any((e) => e.item.id == id), isFalse);
  });

  test('a refused heart rolls back and keeps the reason', () async {
    final c = world.container();
    await c.read(sessionProvider.notifier).loadPersona('reem');
    final before = await c.read(favouritesProvider.future);
    final n = c.read(favouritesProvider.notifier);
    world.control.setScenario('error');
    final result = await n.toggle(SavedType.venue, _unsaved(before));
    expect(result, isFalse);
    expect(c.read(favouritesProvider).value, before);
    expect(n.lastProblem, isNotNull);
    expect(n.lastProblem!.status, greaterThanOrEqualTo(500));
  });

  test('the five states: loading, data, empty and an error that retries', () async {
    final c = world.container();
    await c.read(sessionProvider.notifier).loadPersona('new_client');
    final first = c.read(favouritesProvider);
    expect(first.isLoading, isTrue);
    expect((await c.read(favouritesProvider.future)).total, 0);

    world.control.setScenario('offline');
    c.invalidate(favouritesProvider);
    await expectLater(c.read(favouritesProvider.future), throwsA(isA<Object>()));
    expect(c.read(favouritesProvider).hasError, isTrue);
    world.control.setScenario('none');
    c.invalidate(favouritesProvider);
    expect((await c.read(favouritesProvider.future)).total, 0);
  });
}
