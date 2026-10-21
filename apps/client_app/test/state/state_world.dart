import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_api/ghazal_api.dart' show RestRepositories;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show MockControl;
import 'package:ghazal_testing/src/world.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzDialogResult, GzDialogSpec, GzNavigator, GzParams, GzSheetOptions, GzToastSpec;
import 'package:shared_preferences/shared_preferences.dart';

/// A navigator that keeps a plain stack, enough to see what the gate opened.
class FakeNavigator implements GzNavigator {
  FakeNavigator(String root) : stack = [(root, const <String, Object?>{})];

  final List<(String, GzParams)> stack;

  @override
  String get currentId => stack.last.$1;
  @override
  GzParams get params => stack.last.$2;
  @override
  bool get canGoBack => stack.length > 1;
  @override
  String? get activeTab => null;
  @override
  void push(String id, {GzParams params = const {}}) => stack.add((id, params));
  @override
  void pop({int count = 1}) {
    for (var i = 0; i < count && stack.length > 1; i++) {
      stack.removeLast();
    }
  }

  @override
  void replace(String id, {GzParams params = const {}}) => stack.last = (id, params);
  @override
  void reset(String id, {GzParams params = const {}}) => stack
    ..clear()
    ..add((id, params));
  @override
  void switchTab(String tabId) {}
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) {
    stack.add((screenId, options.params));
    return screenId;
  }

  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  void closeSheet([String? key]) => pop();
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) async => GzDialogResult.cancel;
  @override
  String toast(GzToastSpec spec) => '';
  @override
  void dismissToast([String? key]) {}
}

/// One mock world per test process and containers over it, wired like the running app (in-process mock, memory tokens, zero latency, no
/// background timers). Call [fresh] in `setUp`: each test starts at the beginning of the story, as a guest.
final class StateWorld {
  StateWorld._(this.world);

  final GzWorld world;
  static StateWorld? _cached;
  static final List<ProviderContainer> _open = <ProviderContainer>[];

  static Future<StateWorld> load() async => _cached ??= StateWorld._(await GzWorld.load());

  MockControl get control => world.control;

  Future<StateWorld> fresh() async {
    await world.control.reset();
    world.control.setScenario('none');
    world.control.setPersona('guest');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return this;
  }

  /// A container like the app's: [prefs] persists the device state (null: nothing persists), [navigator] receives the gate sheet.
  ProviderContainer container({SharedPreferences? prefs, FakeNavigator? navigator, List<Override> overrides = const <Override>[]}) {
    final c = ProviderContainer(
      overrides: [
        mockBackendProvider.overrideWithValue(world.mock),
        appEnvProvider.overrideWithValue(const AppEnv()),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
        gzNavigatorProvider.overrideWithValue(navigator ?? FakeNavigator('CL-DISC-01')),
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      retry: gzProviderRetry,
    );
    _open.add(c);
    return c;
  }

  static void disposeAll() {
    for (final c in _open) {
      c.dispose();
    }
    _open.clear();
  }

  /// The repositories acting as [persona] outside the app container (the partner side of a story: `world.repos('hotel_manager', venueId: 'V01')`).
  RestRepositories repos(String persona, {String? venueId}) => world.repos(persona, venueId: venueId);
}

const String heroId = 'bk-GZ-2611-0147';
