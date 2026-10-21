import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// Where the roster's hall prices fall for the couple's guest count, drawn above the budget slider (web `PriceHistogram`): ten bins across
/// the slider's range, bars inside the chosen range darker. A plain row, so the minimum sits at inline-start and it mirrors in Arabic like
/// the slider under it. Decorative for assistive technology: the slider and the band chips carry the value.
class ObdPriceHistogram extends StatelessWidget {
  const ObdPriceHistogram({required this.prices, required this.min, required this.max, required this.range, super.key});

  /// Hall prices in dinars.
  final List<int> prices;
  final double min;
  final double max;

  /// The chosen range in dinars.
  final (double, double) range;

  static const int _bins = 10;
  static const double _maxBar = 48;
  static const double _barStep = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final width = (max - min) / _bins;
    final counts = List<int>.filled(_bins, 0);
    for (final p in prices) {
      counts[math.min(((p - min) / width).floor(), _bins - 1).clamp(0, _bins - 1)]++;
    }
    final tallest = math.max(1, counts.reduce(math.max));
    return ExcludeSemantics(
      child: SizedBox(
        height: GzSpace.s12,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _bins; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s1),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: (min + i * width + width > range.$1 && min + i * width < range.$2 && counts[i] > 0)
                            ? c.iconSecondary
                            : c.borderHairline,
                        borderRadius: const BorderRadiusDirectional.only(
                          topStart: Radius.circular(GzRadius.xs),
                          topEnd: Radius.circular(GzRadius.xs),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: counts[i] == 0 ? _barStep / 2 : math.max(_barStep, (((counts[i] / tallest) * _maxBar) / _barStep).round() * _barStep),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
