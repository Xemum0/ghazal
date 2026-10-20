/// Ghazal UI package. Apps import only this barrel and `package:flutter/widgets.dart`; material_ui and cupertino_ui stay inside.
library;

export 'l10n/generated/gz_localizations.dart';
export 'src/app/gz_app.dart';
export 'src/icons/gz_icon.dart';
export 'src/icons/gz_icons.g.dart';
export 'src/illustrations/gz_illustration.dart';
export 'src/illustrations/gz_illustrations.g.dart' hide GzIllustrationSource;
export 'src/motion/gz_fade_reveal.dart';
export 'src/motion/gz_haptics.dart';
export 'src/motion/gz_pressable.dart';
export 'src/motion/gz_reduced_motion.dart';
export 'src/stub/gz_stub_screen.dart';
export 'src/text/gz_bidi.dart';
export 'src/text/gz_num.dart';
export 'src/text/gz_text.dart';
export 'src/theme/gz_fonts.dart';
export 'src/theme/gz_theme.dart';
// Tokens (generated, packages/design-tokens/scripts/lib/dart.mjs). The reference colour ramps (GzRefColors) are not exported:
// components read semantic roles only (ADR 0023 D7).
export 'src/tokens/generated/gz_colors.g.dart' hide GzRefColors;
export 'src/tokens/generated/gz_dimensions.g.dart';
export 'src/tokens/generated/gz_motion.g.dart';
export 'src/tokens/generated/gz_type.g.dart';
