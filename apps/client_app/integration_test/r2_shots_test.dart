// R2 shots (client): not a journey of final-verification; a pause at the screens round 2 added or changed so the simulator can be photographed
// (`xcrun simctl io <id> screenshot`): About you (sex tiles, then the keyboard on the name), the Services hub and the Profile hub with the provider
// note on top, the Brief sheet and the Filters sheet with governorate chips, Results. Each [shot] prints `SHOT <name>` and holds the screen for
// 3.5 s with `--dart-define=JOURNEY_SHOTS=true` (otherwise it is a quick walk). Run: `flutter test integration_test/r2_shots_test.dart -d <id> --dart-define=JOURNEY_LANG=ar --dart-define=JOURNEY_SHOTS=true`.
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/journey_world.dart';
import 'support/tour.dart';

/// `--dart-define=JOURNEY_SHOTS=true` holds the screen for 3.5 s at each [shot] so a watcher can photograph the simulator (`SHOT <name>` is printed).
const bool _kShots = bool.fromEnvironment('JOURNEY_SHOTS');

Future<void> shot(Journey j, String name) async {
  debugPrint('  SHOT $name');
  await j.pump(Duration(milliseconds: _kShots ? 3500 : 200));
}

void main() {
  journeySetUp();

  journey('R2 shots A: sign-in, About you with the sex tiles and the keyboard', (j) async {
    await j.start();
    String t(String Function(AppL10n l) pick) => j.t(pick);
    await j.seeScreen('CL-ONBD-01');
    await j.tapText(kJourneyLang == 'ar' ? en.clientOnboardingLanguageNativeAr : en.clientOnboardingLanguageNativeEn, wait: const Duration(milliseconds: 1200));
    await j.tapText(t((l) => l.commonActionContinue));
    await j.seeScreen('CL-ONBD-02');
    await j.tapText(t((l) => l.commonActionNext));
    await j.tapText(t((l) => l.commonActionNext));
    await j.tapText(t((l) => l.clientOnboardingIntroStart));
    await j.seeScreen('CL-AUTH-01');
    await shot(j, 'cl-auth01');
    await j.type(0, '50001299');
    await shot(j, 'cl-auth01-keyboard');
    expect(j.focusedFieldVisible(), isTrue, reason: 'the phone field is above the keyboard');
    await j.tapText(t((l) => l.clientAuthSharedSendCode), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-AUTH-02');
    await j.type(0, '123456', wait: const Duration(seconds: 3));
    await j.seeScreen('CL-AUTH-03', timeout: const Duration(seconds: 15));
    await shot(j, 'cl-auth03-top');
    await j.tapText(t((l) => l.commonActionContinue), wait: const Duration(milliseconds: 600));
    await shot(j, 'cl-auth03-required');
    await j.type(0, 'Nora Al-Salem');
    expect(j.focusedFieldVisible(), isTrue, reason: 'the name field is above the keyboard');
    await shot(j, 'cl-auth03-keyboard');
    await j.closeKeyboard();
    await j.tapText(t((l) => l.clientAuthNameSexFemale), wait: const Duration(milliseconds: 400));
    await shot(j, 'cl-auth03-sex');
  });

  journey('R2 shots B: Services hub, Profile, governorate chips, Results', (j) async {
    await j.start(persona: 'reem');
    await j.useLanguage(kJourneyLang);
    String t(String Function(AppL10n l) pick) => j.t(pick);
    await j.seeScreen('CL-DISC-01');
    await j.loaded();
    await j.tapText(t((l) => l.clientShellSwitchServices), wait: const Duration(seconds: 2));
    await j.seeScreen('CL-SERV-01');
    await j.loaded();
    await shot(j, 'cl-serv01');
    await j.openTab('profile', 'CL-PROF-01');
    await shot(j, 'cl-prof01');
    await j.tapKey('gz:tab.discover', wait: const Duration(milliseconds: 800)); // the Discover tab still holds the Services hub on its stack
    await j.tapKey('gz:tab.discover', wait: const Duration(milliseconds: 800)); // a second tap pops to its root
    await j.seeScreen('CL-DISC-01');
    await j.tapKey('discover.row.area', wait: const Duration(seconds: 1));
    await j.seeScreen('CL-DISC-02');
    await shot(j, 'cl-disc02-brief');
    await j.tapText(kJourneyLang == 'ar' ? 'حولي' : 'Hawalli', wait: const Duration(milliseconds: 600));
    await shot(j, 'cl-disc02-hawalli');
    await j.tapKey('discover.brief.done', wait: const Duration(milliseconds: 600));
    await j.tapKey('discover.brief.cta', wait: const Duration(seconds: 2));
    await j.seeScreen('CL-DISC-03');
    await j.loaded();
    await shot(j, 'cl-disc03');
    await j.tapKey('discover.chip.filters', wait: const Duration(seconds: 1));
    await j.seeScreen('CL-DISC-04');
    await j.loaded();
    await shot(j, 'cl-disc04-filters');
  });
}
