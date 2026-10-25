// The extra editor sheet (web `ExtraSheet.tsx`): bilingual name and short description, price, how it is charged, active.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/venue_data.dart';
import '../../application/venue_pricing.dart';
import 'venue_bits.dart';
import 'venue_fields.dart';

class ExtraSheet extends ConsumerStatefulWidget {
  const ExtraSheet({this.extra, super.key});

  final Extra? extra;

  @override
  ConsumerState<ExtraSheet> createState() => _ExtraSheetState();
}

class _ExtraSheetState extends ConsumerState<ExtraSheet> {
  late String _ar = widget.extra?.name.ar ?? '';
  late String _en = widget.extra?.name.en ?? '';
  late String _dAr = widget.extra?.description.ar ?? '';
  late String _dEn = widget.extra?.description.en ?? '';
  late int? _price = widget.extra?.price.fils;
  late PricingUnit _unit = widget.extra?.pricingUnit ?? PricingUnit.flat;
  late bool _active = widget.extra?.active ?? true;
  bool _dirty = false;

  void _touch(VoidCallback f) => setState(() {
    _dirty = true;
    f();
  });

  Future<void> _save() async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final e = widget.extra;
    final input = ExtraInput(
      category: e?.category ?? ExtraCategory.favours,
      name: LocalizedText(ar: _ar.trim(), en: _en.trim()),
      description: LocalizedText(ar: _dAr.trim(), en: _dEn.trim()),
      pricingUnit: _unit,
      price: MoneyAmount(_price!),
      priceMin: e?.priceMin,
      priceMax: e?.priceMax,
      maxQty: e?.maxQty ?? 1,
      includedInPackageIds: e?.includedInPackageIds,
      audiences: e?.audiences,
      unitLabel: _unit == e?.pricingUnit ? e?.unitLabel : null,
      active: _active,
    );
    final res = await ref.read(venueActionsProvider.notifier).saveExtra(e?.id, input);
    if (!mounted) return;
    toastResult(context, res, success: e == null ? l.hotelVenueToastExtraCreated : l.hotelVenueToastExtraSaved, then: (_) => nav.closeSheet());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final reserved = isReservedName(_ar) || isReservedName(_en);
    final namesMissing = _ar.trim().isEmpty || _en.trim().isEmpty;
    final priceMissing = (_price ?? 0) <= 0;
    final problem = reserved ? l.hotelVenueReservedName : namesMissing ? l.hotelVenueNameRequired : priceMissing ? l.hotelVenueNeedPrice : null;
    final saving = ref.watch(venueActionsProvider).busy.contains('save:extra');
    final e = widget.extra;
    return SheetColumn(
      footer: GzButton(label: l.commonActionSave, fullWidth: true, loading: saving, reason: problem, onPressed: problem == null ? _save : null),
      children: [
        BilingualField(
          label: l.hotelVenueFieldName,
          ar: _ar,
          en: _en,
          maxLength: 60,
          errorAr: isReservedName(_ar) ? l.hotelVenueReservedName : null,
          errorEn: isReservedName(_en) ? l.hotelVenueReservedName : null,
          onAr: (v) => _touch(() => _ar = v),
          onEn: (v) => _touch(() => _en = v),
        ),
        PriceField(
          label: l.hotelVenueFieldPrice,
          fils: (_price ?? 0) > 0 ? _price : null,
          helper: e?.priceMin != null && e?.priceMax != null ? l.hotelVenueExtraRange(f.money(e!.priceMin!.fils), f.money(e.priceMax!.fils)) : null,
          onChanged: (v) => _touch(() => _price = v),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(l.hotelVenueFieldUnit, role: GzTextRole.label, color: context.gz.colors.textPrimary),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<PricingUnit>(
              label: l.hotelVenueFieldUnit,
              value: _unit,
              onChanged: (v) => v == null ? null : _touch(() => _unit = v),
              options: [
                GzChipOption(value: PricingUnit.flat, label: l.hotelVenueUnitEvent),
                GzChipOption(value: PricingUnit.perGuest, label: l.commonUnitPerGuest),
                GzChipOption(value: PricingUnit.perUnit, label: l.hotelVenueUnitUnit),
              ],
            ),
          ],
        ),
        BilingualField(label: l.hotelVenueFieldDescription, ar: _dAr, en: _dEn, multiline: true, maxLength: 140, onAr: (v) => _touch(() => _dAr = v), onEn: (v) => _touch(() => _dEn = v)),
        GzToggleRow(title: l.hotelVenueFieldShow, description: _active ? l.hotelVenueExtraActiveOn : l.hotelVenueExtraActiveOff, divider: false, checked: _active, onChanged: (v) => _touch(() => _active = v)),
        if (problem != null && _dirty) FormError(problem),
      ],
    );
  }
}
