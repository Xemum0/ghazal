import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';

/// The in-process mock backend, or null when `USE_MOCK=false`. The default is null; the bootstrap overrides it with the awaited backend
/// (`runGhazalApp`), tests and the shot harness with their own (zero latency, `autoRun: false`).
final Provider<MockBackend?> mockBackendProvider = Provider<MockBackend?>((ref) => null);

/// The seed source of the apps: the package assets through `rootBundle` (declared by `ghazal_mock_api`).
SeedSource bundledMockSeed() => SeedSource.fromLoader((p) => rootBundle.loadString('packages/ghazal_mock_api/assets/$p'));

/// Builds the in-process backend of an app run: latency from [env] (`MOCK_LATENCY_MS`), timers on in the app ([autoRun]), off in tests.
Future<MockBackend> createInProcessMock(AppEnv env, {SeedSource? seed, bool autoRun = true, String persona = 'guest', DateTime? clock}) {
  return MockBackend.create(
    seed: seed ?? bundledMockSeed(),
    latency: Duration(milliseconds: env.mockLatencyMs),
    autoRun: autoRun,
    persona: persona,
    clock: clock,
  );
}
