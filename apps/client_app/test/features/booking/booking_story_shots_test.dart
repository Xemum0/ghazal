import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_testing/src/shot_health.dart';

import '../../support/flow_world.dart';

/// The hero story in one of its prepared points, shot like `pnpm fshot` (the harness cannot move the story): the web frames of
/// CL-BOOK-08 / 09 / 10 show the approved, confirmed and lapsed hero request, which the default shot of the mock (pending) cannot.
///
///   STORY_CASES=CL-BOOK-08:approved,CL-BOOK-09:confirmed,CL-BOOK-10:lapsed STORY_LANGS=ar,en flutter test test/features/booking/booking_story_shots_test.dart
void main() {
  final cases = (Platform.environment['STORY_CASES'] ?? '').split(',').where((c) => c.contains(':'));
  final langs = (Platform.environment['STORY_LANGS'] ?? 'ar,en').split(',');
  final width = double.parse(Platform.environment['STORY_W'] ?? '390');
  final params = Platform.environment['STORY_PARAMS'] ?? '';
  final height = double.parse(Platform.environment['STORY_H'] ?? '844');
  final textScale = double.parse(Platform.environment['STORY_TEXT_SCALE'] ?? '1');
  final out = Platform.environment['STORY_OUT'] ?? 'build/shots';
  for (final c in cases) {
    final id = c.split(':')[0];
    final story = c.split(':')[1];
    for (final lang in langs) {
      flowTest('$id $story $lang', (tester) async {
        await openScreen(
          tester,
          id,
          locale: Locale(lang),
          story: story,
          size: Size(width, height),
          textScale: textScale,
          params: params.isEmpty ? const {} : {for (final kv in params.split('&')) kv.split('=')[0]: kv.split('=')[1]},
        );
        await GzHarness.settle(tester);
        await GzHarness.settle(tester); // data that arrives late (a rail) brings its photographs a round later
        Directory(out).createSync(recursive: true); // real IO never completes inside the fake async of a widget test
        final name = '$out/$id.$lang.${width.round()}';
        ShotHealth.capture(tester, id: id, lang: lang, width: width, state: '', errors: const <String>[]).write(out, '$id.$lang.${width.round()}');
        await GzHarness.shoot(tester, '$name.png');
        if (width == 390) await GzHarness.shoot(tester, '$out/$id.$lang.png');
        // ignore: avoid_print
        print('SHOT $name.png');
      });
    }
  }
}
