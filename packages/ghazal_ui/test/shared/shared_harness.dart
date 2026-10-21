import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the package fonts under the `packages/ghazal_ui/<Family>` names the text styles resolve to (inside ghazal_ui's own
/// test run the manifest lists bare family names), so geometry assertions use the real Manrope / Almarai metrics.
/// Call from `setUpAll`.
Future<void> loadUiFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(family.startsWith('packages/') ? family : 'packages/ghazal_ui/$family');
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
