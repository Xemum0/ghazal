import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show MockBackend, Scenario, storyPoints;

import '../data/api_providers.dart';
import '../data/mock_backend.dart';
import '../session/session_notifier.dart';

/// The personas of the mock the demo tools switch between (`docs/architecture/mock-api.md`).
const List<String> kDemoPersonas = ['guest', 'new_client', 'reem', 'hotel_manager', 'hotel_admin', 'provider'];

/// The scenarios a demo can force for the next requests (`none` is the normal service).
const List<String> kDemoScenarios = [Scenario.none, Scenario.slow, Scenario.error, Scenario.offline, Scenario.empty, Scenario.expired];

/// The prepared states of the hero story (`MockControl.storyPoints`).
List<String> get kDemoStoryPoints => storyPoints;

/// What the demo sheet shows: who the app acts as, the forced scenario, the story clock and the last story point chosen.
final class DemoState {
  const DemoState({this.persona = 'guest', this.scenario = Scenario.none, this.storyNow, this.point});

  final String persona;
  final String scenario;

  /// The story clock as Kuwait time (`2026-11-12T16:00:00+03:00`), null without a mock.
  final String? storyNow;
  final String? point;

  DemoState copyWith({String? persona, String? scenario, String? storyNow, String? point}) =>
      DemoState(persona: persona ?? this.persona, scenario: scenario ?? this.scenario, storyNow: storyNow ?? this.storyNow, point: point ?? this.point);
}

/// The demo tools are available outside production builds, and only with the in-process mock (`USE_MOCK`).
final Provider<bool> demoToolsAvailableProvider = Provider<bool>((ref) => !ref.watch(appEnvProvider).isProd && ref.watch(mockBackendProvider) != null);

/// State and actions of the demo tools (dev builds only): reset the story, switch persona, force a scenario, move the clock, jump to a
/// story point. Every action that changes what the server would answer bumps [backendEpochProvider] so the screens refetch.
final NotifierProvider<DemoNotifier, DemoState> demoProvider = NotifierProvider<DemoNotifier, DemoState>(DemoNotifier.new);

class DemoNotifier extends Notifier<DemoState> {
  MockBackend? get _mock => ref.read(mockBackendProvider);

  @override
  DemoState build() {
    final mock = ref.read(mockBackendProvider);
    return DemoState(persona: mock?.control.persona ?? 'guest', scenario: mock?.control.scenario ?? Scenario.none, storyNow: mock?.control.nowText);
  }

  void _refresh({String? persona, String? point}) {
    final mock = _mock;
    state = state.copyWith(persona: persona, point: point, scenario: mock?.control.scenario, storyNow: mock?.control.nowText);
  }

  /// The mode line of the sheet: true for the in-process mock, false when the app talks to a remote API.
  bool get inProcess => _mock != null;

  /// Becomes [persona]: real tokens of that mock session, the session provider follows, every screen refetches.
  Future<void> switchPersona(String persona) async {
    if (_mock == null) return;
    await ref.read(sessionProvider.notifier).loadPersona(persona);
    _refresh(persona: persona);
    ref.read(backendEpochProvider.notifier).bump();
  }

  /// Seeds the story again and clock back; the current persona signs in again (a reset drops every session).
  Future<void> resetStory() async {
    final mock = _mock;
    if (mock == null) return;
    await mock.control.reset();
    await ref.read(sessionProvider.notifier).loadPersona(state.persona);
    _refresh(point: 'pending');
    ref.read(backendEpochProvider.notifier).bump();
  }

  /// The scenario of the next requests (`slow`, `error`, `offline`, `empty`, `expired`; `none` clears it).
  void forceScenario(String scenario) {
    _mock?.control.setScenario(scenario);
    _refresh();
  }

  /// Moves the story clock forward (`Duration(hours: 1)` or `Duration(hours: 24)`): R06, R09, R12 and every countdown follow.
  void advance(Duration by) {
    _mock?.control.advance(by);
    _refresh();
    ref.read(backendEpochProvider.notifier).bump();
  }

  /// Puts the hero request in one of the prepared states (`pending`, `approved`, `confirmed`, `redeemed`, `completed`, `declined`, `expired`,
  /// `lapsed`, `cancelled`, `counter_offer`).
  void jumpTo(String point) {
    _mock?.control.jumpToStory(point);
    _refresh(point: point);
    ref.read(backendEpochProvider.notifier).bump();
  }
}
