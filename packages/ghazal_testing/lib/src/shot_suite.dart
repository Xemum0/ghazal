import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fonts.dart';
import 'harness.dart';

const String _ids = String.fromEnvironment('SHOT_IDS');
const String _langs = String.fromEnvironment('SHOT_LANGS', defaultValue: 'ar,en');
const String _widths = String.fromEnvironment('SHOT_W', defaultValue: '390');
const String _heights = String.fromEnvironment('SHOT_H', defaultValue: '844');
const String _scale = String.fromEnvironment('SHOT_SCALE', defaultValue: '2');
const String _textScale = String.fromEnvironment('SHOT_TEXT_SCALE', defaultValue: '1');
const String _state = String.fromEnvironment('SHOT_STATE');
const String _out = String.fromEnvironment('SHOT_OUT');

/// Builds the widget that shows one inventory screen. [path] is the router location of the screen, [state] the optional
/// scenario name (`loading`, `empty`, `error`, ...; scenario plumbing arrives with the mock in phase F1c).
typedef GzShotAppBuilder = Widget Function(String path, String state);

/// The shot test of an app (`apps/<app>/test/shots/shots_test.dart` calls this). Driven by `--dart-define`:
///
/// - `SHOT_IDS`: comma list of inventory ids, or `all` (nothing set: no shot is taken and the suite passes with a note)
/// - `SHOT_LANGS` (`ar,en`), `SHOT_W` (390; a comma list renders several widths), `SHOT_H` (844), `SHOT_SCALE` (2),
///   `SHOT_TEXT_SCALE` (1), `SHOT_STATE` (none), `SHOT_OUT` (default `<cwd>/build/shots`)
///
/// Writes `<id>.<lang>.<w>.png`, with `.<state>` before the extension when a state is set. Shots at width 390 and DPR 2 without a
/// state are also written as `<id>.<lang>.png`, the name the parity tool reads (plan section 6).
void runShotSuite({
  required String app,
  required Map<String, String> paths,
  required GzShotAppBuilder appBuilder,
  List<Override> Function()? overrides,
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requested = _ids.trim().isEmpty
      ? <String>[]
      : (_ids.trim() == 'all' ? paths.keys.toList() : _ids.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
  final langs = _langs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final widths = _widths.split(',').map((e) => double.parse(e.trim())).toList();
  final height = double.parse(_heights);
  final scale = double.parse(_scale);
  final textScale = double.parse(_textScale);
  final out = _out.isEmpty ? p.join(Directory.current.path, 'build', 'shots') : _out;

  setUpAll(loadAppFonts);

  if (requested.isEmpty) {
    test('shots: no SHOT_IDS given (pass --dart-define=SHOT_IDS=CL-DISC-01 or all)', () {});
    return;
  }
  final unknown = requested.where((id) => !paths.containsKey(id)).toList();
  if (unknown.isNotEmpty) {
    test('shots: unknown ids', () => fail('Not in the $app screen registry: ${unknown.join(', ')}'));
    return;
  }

  for (final id in requested) {
    for (final lang in langs) {
      for (final width in widths) {
        final label = '$id.$lang.${width.round()}${_state.isEmpty ? '' : '.$_state'}';
        testWidgets('shot $label', (tester) async {
          await GzHarness.pump(
            tester,
            app: appBuilder(paths[id]!, _state),
            locale: Locale(lang),
            width: width,
            height: height,
            dpr: scale,
            textScale: textScale,
            overrides: overrides?.call() ?? const <Override>[],
          );
          final file = await GzHarness.shoot(tester, p.join(out, '$label.png'));
          if (width == 390 && scale == 2 && _state.isEmpty) {
            file.copySync(p.join(out, '$id.$lang.png'));
          }
          // ignore: avoid_print
          print('SHOT ${file.path}');
        });
      }
    }
  }
}
