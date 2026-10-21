import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_app_kit/src/data/data.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_testing/src/world.dart';

/// One mock world per test process (seeded from disk) and containers over it, the way the app wires it: the in-process mock, memory token
/// store, zero latency, no background timers. Call [KitWorld.fresh] in `setUp` so each test starts at the beginning of the story.
final class KitWorld {
  KitWorld._(this.world);

  final GzWorld world;

  static KitWorld? _cached;

  static Future<KitWorld> load() async => _cached ??= KitWorld._(await GzWorld.load());

  /// Resets the story and every knob; returns the world.
  Future<KitWorld> fresh() async {
    await world.control.reset();
    world.control.setScenario('none');
    world.control.setPersona('guest');
    return this;
  }

  /// A container wired like the app. [overrides] go last (a fake repository, a fixed clock).
  ProviderContainer container({List<Override> overrides = const <Override>[], AppEnv env = const AppEnv(), bool withMock = true}) {
    final c = ProviderContainer(
      overrides: [
        mockBackendProvider.overrideWithValue(withMock ? world.mock : null),
        appEnvProvider.overrideWithValue(env),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
        ...overrides,
      ],
      retry: gzProviderRetry,
    );
    addTearDownContainer(c);
    return c;
  }

  static final List<ProviderContainer> _open = <ProviderContainer>[];

  static void addTearDownContainer(ProviderContainer c) => _open.add(c);

  static void disposeAll() {
    for (final c in _open) {
      c.dispose();
    }
    _open.clear();
  }
}
