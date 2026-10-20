/// The foundation every component group builds on: theme, tokens, text, motion, icons, illustrations and the words of ghazal_ui.
/// Group code imports this (and its own group files), never `ghazal_ui.dart`, so one group can compile and be tested while another
/// is still being written.
library;

export '../l10n/generated/gz_localizations.dart';
export '../l10n/gz_l10n_context.dart';
export 'icons/gz_icon.dart';
export 'icons/gz_icons.g.dart';
export 'illustrations/gz_illustration.dart';
export 'illustrations/gz_illustrations.g.dart' hide GzIllustrationSource;
export 'motion/gz_fade_reveal.dart';
export 'motion/gz_haptics.dart';
export 'motion/gz_pressable.dart';
export 'motion/gz_reduced_motion.dart';
export 'text/gz_bidi.dart';
export 'text/gz_num.dart';
export 'text/gz_text.dart';
export 'theme/gz_fonts.dart';
export 'theme/gz_theme.dart';
export 'tokens/generated/gz_colors.g.dart' hide GzRefColors;
export 'tokens/generated/gz_dimensions.g.dart';
export 'tokens/generated/gz_motion.g.dart';
export 'tokens/generated/gz_type.g.dart';
