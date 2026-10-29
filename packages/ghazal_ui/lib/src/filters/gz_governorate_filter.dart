import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Governorate;

import '../foundation.dart';
import '../inputs/inputs.dart';

/// GovernorateFilter (CA-FLT-08, ADR 0038): the one region control of the Client app. Wrapping, multi-select chips, one per governorate
/// of the configured list (Kuwait's six official ones to start), each a pin glyph and the name. Nothing selected means every
/// governorate: there is no "All" chip and no sentence. The title with the count ("Governorates · 2") belongs to the surface that hosts
/// the group (the Brief panel, the Filters group, the Vendors filters), each with its own ICU key. Port of
/// design/src/system/domain-filters/GovernorateFilter.tsx; the chip is the shared [GzChipGroup] chip (44 high, radius 8, hairline;
/// selected = ink border, gold bead, weight 500), the glyph an `xs` pin with an 8 dp gap.
///
/// The governorates are data (the `GET /areas` list), never typed here. Controlled with [values], else [defaultValues] seeds it.
/// [only] offers just those ids (the Vendors filter lists the governorates where the category has providers); [layout] is `wrap`
/// (a sheet or a panel, the default) or `rail` (one scrolling line; the screen owns the gutter bleed). [label] is the accessible name
/// of the group and defaults to "Governorate".
class GzGovernorateFilter extends StatefulWidget {
  const GzGovernorateFilter({
    required this.governorates,
    this.values,
    this.defaultValues,
    this.onChanged,
    this.layout = GzChipLayout.wrap,
    this.only,
    this.label,
    super.key,
  });

  final List<Governorate> governorates;

  /// Selected governorate ids; an empty list = every governorate.
  final List<String>? values;
  final List<String>? defaultValues;
  final ValueChanged<List<String>>? onChanged;
  final GzChipLayout layout;

  /// Offer only these governorate ids; null offers every configured one.
  final Iterable<String>? only;
  final String? label;

  @override
  State<GzGovernorateFilter> createState() => _GzGovernorateFilterState();
}

class _GzGovernorateFilterState extends State<GzGovernorateFilter> {
  late List<String> _inner = List.of(widget.defaultValues ?? const []);

  @override
  Widget build(BuildContext context) {
    final lang = context.gz.locale.languageCode;
    final only = widget.only?.toSet();
    final ids = widget.values ?? _inner;
    return GzChipGroup<String>.multiple(
      label: widget.label ?? context.gzL10n.commonFilterGovernorate,
      layout: widget.layout,
      values: ids,
      options: [
        for (final g in widget.governorates)
          if (only == null || only.contains(g.id)) GzChipOption(value: g.id, label: g.name.of(lang), icon: GzIcons.pin),
      ],
      onChanged: (next) {
        if (widget.values == null) setState(() => _inner = next);
        widget.onChanged?.call(next);
      },
    );
  }
}
