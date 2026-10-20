// PLACEHOLDER tokens for phase F0 only. Phase F1a replaces this folder with the generated tokens
// (packages/design-tokens/dist/dart/gz_tokens.dart). Values mirror tokens.json (ref ink / gold / neutral); this is the only
// place in the app packages where hex colours may live (tools/check-dart-rules.sh allows lib/src/tokens/).
import 'dart:ui' show Color;

abstract final class GzPlaceholderColors {
  static const Color canvas = Color(0xFFFFF9F5);
  static const Color paper = Color(0xFFFFFDFB);
  static const Color ink900 = Color(0xFF2E2528);
  static const Color ink700 = Color(0xFF5A4B4F);
  static const Color ink300 = Color(0xFFC9BEBF);
  static const Color gold500 = Color(0xFFD8B26E);
  static const Color gold100 = Color(0xFFF8EFDC);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
}
