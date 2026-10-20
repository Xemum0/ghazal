import 'package:flutter/widgets.dart';

import '../tokens/generated/gz_motion.g.dart';

/// Reduced motion (plan section 7): with `MediaQuery.disableAnimations` transforms, draws and pops are removed (1 ms) and only
/// opacity cross-fades remain, at the fast token (120 ms).
abstract final class GzReducedMotion {
  /// True when the platform asks for reduced motion.
  static bool of(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duration for a movement (scale, slide, draw, pop): the token, or instant when motion is reduced.
  static Duration movement(BuildContext context, Duration normal) => of(context) ? GzMotion.durationInstant : normal;

  /// Duration for an opacity fade: the token, or at most the fast token when motion is reduced.
  static Duration fade(BuildContext context, Duration normal) =>
      of(context) && normal > GzMotion.durationFast ? GzMotion.durationFast : normal;

  /// Scale a value (a distance or a scale delta) away entirely when motion is reduced: returns [rest] instead of [moving].
  static double distance(BuildContext context, double moving, {double rest = 0}) => of(context) ? rest : moving;
}
