import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers every font declared in the workspace packages (`FontManifest.json`) with the engine, so tests render the REAL
/// ElMessiri / Manrope / Almarai (flutter_test would otherwise draw every glyph with the Ahem square font).
///
/// Call once from `setUpAll` (after `TestWidgetsFlutterBinding.ensureInitialized()`), outside any `testWidgets` body.
/// Package fonts are listed as `packages/ghazal_ui/<Family>`; `TextStyle(fontFamily: 'Manrope', package: 'ghazal_ui')` resolves to that.
Future<List<String>> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  final loaded = <String>[];
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(family);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    try {
      await loader.load();
      loaded.add(family);
    } on Object catch (e) {
      debugPrint('loadAppFonts: could not load $family: $e');
    }
  }
  return loaded;
}
