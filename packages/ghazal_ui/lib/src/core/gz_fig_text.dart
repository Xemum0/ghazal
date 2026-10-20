import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// A number that is the whole element, in the figures voice (Manrope tabular lining digits, an LTR island), with a chosen
/// weight, colour and decoration. [GzNum] is the same thing with the role's own weight; this adds the overrides the core
/// components need (the rating figure takes the price weight, a struck price a line-through).
Widget gzFigText(
  BuildContext context,
  String value, {
  required GzTextRole role,
  FontWeight? weight,
  Color? color,
  TextDecoration? decoration,
}) {
  final gz = context.gz;
  final base = gz.text(role);
  final figure = gz.text(role.figureRole ?? role);
  final style = GzFigures.inlineStyle(gz.locale, role).copyWith(
    fontWeight: weight ?? base.fontWeight,
    color: color ?? gz.colors.textPrimary,
    height: figure.height,
    decoration: decoration ?? TextDecoration.none,
    decorationThickness: decoration == null ? null : 1,
    decorationColor: color,
  );
  return Text(GzBidi.isolateLtr(value), style: style, maxLines: 1, softWrap: false, semanticsLabel: GzBidi.strip(value));
}
