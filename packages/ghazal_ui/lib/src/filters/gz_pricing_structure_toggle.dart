import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../inputs/inputs.dart';

/// The choice of a pricing-structure filter (web `PricingStructureValue`): `all` is the neutral "either".
enum GzPricingStructure { all, perPerson, package }

/// PricingStructureToggle (CL-DISC filters, CA-FLT pricing structure; voucher-model section 6): Per person | Packages as a
/// [GzSegmentedControl], so exactly one is chosen; [includeAll] adds the neutral "All" segment first (a filter that may also mean
/// "either"). Controlled with [value], else [defaultValue] seeds it (default: all, or per person without "All").
class GzPricingStructureToggle extends StatelessWidget {
  const GzPricingStructureToggle({this.value, this.defaultValue, this.onChanged, this.includeAll = false, super.key});

  final GzPricingStructure? value;
  final GzPricingStructure? defaultValue;
  final ValueChanged<GzPricingStructure>? onChanged;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    return GzSegmentedControl<GzPricingStructure>(
      options: [
        if (includeAll) GzSegmentedOption(value: GzPricingStructure.all, label: l.commonFilterAll),
        GzSegmentedOption(value: GzPricingStructure.perPerson, label: l.commonPricingPerPerson),
        GzSegmentedOption(value: GzPricingStructure.package, label: l.commonPricingPackages),
      ],
      label: l.commonPricingStructure,
      value: value,
      defaultValue: defaultValue ?? (includeAll ? GzPricingStructure.all : GzPricingStructure.perPerson),
      onChanged: onChanged,
    );
  }
}
