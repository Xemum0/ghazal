import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/inputs.dart';

/// CapacityRange (CL-DISC filters, CA-FLT capacity range): the guest range a hall must hold, minimum to maximum, as a dual-handle
/// [GzRangeSlider] with guest semantics: the start value sits at the inline-start (the right in Arabic), both values show as LTR
/// figures above the rail, the screen-reader value reads "250 guests", and a one-line summary above states the range. The bounds
/// come from the real hall capacities (never a hard-coded 50 to 1,500) and are passed in.
class GzCapacityRange extends StatefulWidget {
  const GzCapacityRange({required this.min, required this.max, this.step = 10, this.value, this.defaultValue, this.onChanged, this.onChangeEnd, super.key});

  /// Smallest and largest capacity among the venues.
  final int min;
  final int max;
  final int step;
  final GzRange? value;
  final GzRange? defaultValue;
  final ValueChanged<GzRange>? onChanged;
  final ValueChanged<GzRange>? onChangeEnd;

  @override
  State<GzCapacityRange> createState() => _GzCapacityRangeState();
}

class _GzCapacityRangeState extends State<GzCapacityRange> {
  late GzRange _inner = widget.defaultValue ?? (widget.min.toDouble(), widget.max.toDouble());

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final current = widget.value ?? _inner;
    final lo = current.$1 < current.$2 ? current.$1 : current.$2;
    final hi = current.$1 < current.$2 ? current.$2 : current.$1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: GzText(l.uiFiltersCapacitySummary(f.numberRange(lo.round(), hi.round())), role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
        ),
        const SizedBox(height: GzSpace.s2),
        GzRangeSlider(
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          step: widget.step.toDouble(),
          value: current,
          onChanged: (v) {
            setState(() => _inner = v);
            widget.onChanged?.call(v);
          },
          onChangeEnd: widget.onChangeEnd,
          label: l.commonFilterCapacity,
          thumbLabels: (l.uiFiltersCapacityMin, l.uiFiltersCapacityMax),
          captions: (l.uiFiltersCapacityFrom, l.uiFiltersCapacityTo),
          valueText: (n, edge) => f.guests(n.round()),
        ),
      ],
    );
  }
}
