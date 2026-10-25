// Headless shot harness entry (verification channel of the project; plan section 6). Run through `pnpm fshot`, for example:
//   pnpm fshot --app client --screen CL-DISC-01 --lang ar
// Defines: SHOT_IDS (ids or all), SHOT_LANGS, SHOT_W, SHOT_H, SHOT_SCALE, SHOT_TEXT_SCALE, SHOT_STATE, SHOT_OUT, SHOT_PERSONA (also as an
// environment variable). Renders the REAL app (`ClientApp` over the generated router) in the in-process mock as Reem, signed in, except
// onboarding and auth (a first-time guest); a state is a mock scenario (loading, empty, error, offline, expired) or `guest`.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_testing/src/world.dart' show GzWorld;

import 'package:client_app/app/app.dart';
import 'package:client_app/app/screen_registry.dart';
import 'package:client_app/app/state/state.dart';

/// The web frames of the compare tray, the full table and the card badge open with the story's three halls in the set
/// (`clientState.compareVenueIds`: V01, V05, V07); the set is device state, so the shot seeds it here and no production code fakes it.
class _StoryCompare extends CompareNotifier {
  @override
  CompareState build() => const CompareState(<String>['V01', 'V05', 'V07']);
}

const _compareSeeded = <String>{'CL-SAVD-02', 'CL-SAVD-03', 'CL-SAVD-04', 'CL-SAVD-01', 'CL-VENU-01', 'CL-VENU-06'};

/// The route params a web static frame carries by default (the story's own values; a live app has them from the Brief or the link):
/// the stay flag of the visit frame, and the story's venue of the quote request (live it comes from the booking draft).
Map<String, Object?>? _frameParams(String id, Map<String, Object?>? given) => switch (id) {
  'CL-VIST-02' when given?['stay'] == null => <String, Object?>{...?given, 'stay': true},
  // The web frame reviews the persona's finished stay at the hero venue (a prototype stand-in); the mock has it as the completed story.
  'CL-RVRW-02' when given?['bookingId'] == null => <String, Object?>{...?given, 'bookingId': 'bk-GZ-2611-0147', 'venueId': 'V01'},
  'CL-SERV-04' when given?['venueId'] == null => <String, Object?>{...?given, 'venueId': 'V01'},
  _ => given,
};

/// Screens whose web frame is drawn at a story point other than the hero request's default (approved).
const _frameStory = <String, String>{'CL-BOOK-09': 'confirmed', 'CL-BOOK-10': 'lapsed', 'CL-BOOK-08': 'approved', 'CL-BKNG-04': 'counter_offer', 'CL-RVRW-01': 'completed', 'CL-RVRW-02': 'completed'};

void main() {
  late GzWorld world;
  setUpAll(() async => world = await GzWorld.load());
  runShotSuite(
    app: 'client',
    paths: {for (final e in kScreenRegistry.entries) e.key: e.value.path},
    appBuilder: (path, state) => const ClientApp(),
    prepare: (shot) async {
      final setup = await prepareShotWorld(mock: world.mock, screenId: shot.id, state: shot.state, persona: shot.persona, story: shot.story ?? _frameStory[shot.id]);
      return GzShotWorldSetup(
        overrides: [
          ...setup.overrides,
          if (_compareSeeded.contains(shot.id)) compareProvider.overrideWith(_StoryCompare.new),
          clientRouterOverride(initialLocation: shot.path, initialExtra: _frameParams(shot.id, shot.params)),
        ],
        flush: setup.flush,
      );
    },
  );
}
