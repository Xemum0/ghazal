import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Governorate;

import '../foundation.dart';
import '../inputs/inputs.dart';

const String _all = '__all';

/// GovernorateFilter (CL-DISC results header and filters, CA-FLT region): one row of the governorates of Kuwait with "All Kuwait"
/// first, as a single scrolling rail of 44 dp chips (the screen owns the gutter bleed). The governorates are data (the six of the
/// areas list), never typed here. "All Kuwait" is exclusive: picking it clears the rest, picking a governorate drops it. An empty
/// selection means all. Controlled with [values], else [defaultValues] seeds it.
class GzGovernorateFilter extends StatefulWidget {
  const GzGovernorateFilter({required this.governorates, this.values, this.defaultValues, this.onChanged, super.key});

  final List<Governorate> governorates;

  /// Selected governorate ids; an empty list = all.
  final List<String>? values;
  final List<String>? defaultValues;
  final ValueChanged<List<String>>? onChanged;

  @override
  State<GzGovernorateFilter> createState() => _GzGovernorateFilterState();
}

class _GzGovernorateFilterState extends State<GzGovernorateFilter> {
  late List<String> _inner = List.of(widget.defaultValues ?? const []);

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final ids = widget.values ?? _inner;
    return GzChipGroup<String>.multiple(
      label: l.commonFilterGovernorate,
      layout: GzChipLayout.rail,
      values: ids.isEmpty ? const [_all] : ids,
      options: [
        GzChipOption(value: _all, label: l.uiFiltersGovernorateAll),
        for (final g in widget.governorates) GzChipOption(value: g.id, label: g.name.of(lang)),
      ],
      onChanged: (next) {
        // "All" is exclusive: the last pick decides.
        final last = next.isEmpty ? _all : next.last;
        final out = last == _all ? <String>[] : [for (final x in next) if (x != _all) x];
        if (widget.values == null) setState(() => _inner = out);
        widget.onChanged?.call(out);
      },
    );
  }
}
