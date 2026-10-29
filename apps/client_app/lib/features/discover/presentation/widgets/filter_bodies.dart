import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, Governorate, HallSetting, LuxuryLevel, PriceStructureFilter, VenueResult, VenueType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import '../../application/discover_filters.dart';
import '../../application/discover_search.dart';
import 'brief_panels_b.dart' show Histogram;
import 'discover_labels.dart';
import 'filter_group.dart';

const (int, int) kCapacityBounds = (50, 1500);
const int kCapacityStep = 50;
const (int, int) kPriceBounds = (12, 60);
const (int, int) kVoucherPriceBounds = (10, 50);
const List<String> kBrands = <String>['Aurelia', 'Madar', 'Lumi', 'Rawnaq'];

/// What a filter group body needs to draw and to change the draft.
class FilterCtx {
  const FilterCtx({required this.draft, required this.patch, required this.brief, required this.labels, required this.governorates, required this.roster, required this.askLocation, required this.openDates});

  final DiscoverFilters draft;
  final void Function(DiscoverFilters Function(DiscoverFilters d) change) patch;
  final SearchBrief brief;
  final DiscoverLabels labels;
  final List<Governorate> governorates;
  final List<VenueResult> roster;
  final Future<void> Function(int? minutes) askLocation;
  final VoidCallback openDates;
}

List<T> _toggle<T>(List<T> list, T v) => list.contains(v) ? <T>[for (final x in list) if (x != v) x] : <T>[...list, v];

/// The ids of the groups, in the inventory order.
const List<String> kFilterGroups = <String>['region', 'type', 'arrangement', 'capacity', 'structure', 'date', 'voucher', 'price', 'setting', 'facilities', 'rating', 'level', 'brand'];

IconData filterGroupIcon(String id) => switch (id) {
  'region' => GzIcons.pin,
  'type' => GzIcons.venue,
  'arrangement' => GzIcons.sectionMixed,
  'capacity' => GzIcons.usersThree,
  'structure' => GzIcons.package,
  'date' => GzIcons.calendar,
  'voucher' => GzIcons.ticket,
  'price' => GzIcons.coins,
  'setting' => GzIcons.tent,
  'facilities' => GzIcons.checklist,
  'rating' => GzIcons.star,
  'level' => GzIcons.crown,
  _ => GzIcons.hotel,
};

/// The title of a group; the region one carries the number of governorates lit ("Governorates · 2").
String filterGroupTitle(AppL10n l, String id, {int regions = 0}) => switch (id) {
  'region' => l.clientDiscoverFiltersGroupRegion(regions),
  'type' => l.clientDiscoverFiltersGroupType,
  'arrangement' => l.clientDiscoverFiltersGroupArrangement,
  'capacity' => l.clientDiscoverFiltersGroupCapacity,
  'structure' => l.clientDiscoverFiltersGroupStructure,
  'date' => l.clientDiscoverFiltersGroupDate,
  'voucher' => l.clientDiscoverFiltersGroupVoucher,
  'price' => l.clientDiscoverFiltersGroupPrice,
  'setting' => l.clientDiscoverFiltersGroupSetting,
  'facilities' => l.clientDiscoverFiltersGroupFacilities,
  'rating' => l.clientDiscoverFiltersGroupRating,
  'level' => l.clientDiscoverFiltersGroupLevel,
  _ => l.clientDiscoverFiltersGroupBrand,
};

/// Whether the group holds a choice (its glyph is drawn in ink and a gold bead marks it).
bool filterGroupActive(String id, DiscoverFilters d, SearchBrief brief) => switch (id) {
  'region' => d.governorateIds != null || d.withinMinutes != null,
  'type' => d.types.isNotEmpty,
  'arrangement' => d.arrangement != null,
  'capacity' => d.capacity != null,
  'structure' => d.structure != null,
  'date' => d.dates != null || (d.available && brief.date != null),
  'voucher' => d.voucherOnly || d.voucherPrice != null,
  'price' => d.price != null,
  'setting' => d.settings.isNotEmpty,
  'facilities' => d.facilities.isNotEmpty,
  'rating' => d.minRating != null,
  'level' => d.levels.isNotEmpty,
  _ => d.brands.isNotEmpty,
};

/// What a collapsed group says once it holds a choice (nothing is written for "any").
String filterGroupSummary(BuildContext context, String id, DiscoverFilters d, SearchBrief brief, DiscoverLabels L) {
  final f = context.gzFormat;
  final l = context.l10n;
  final sep = f.isArabic ? '، ' : ', ';
  String list(Iterable<String> xs) => f.list(xs.toList());
  return switch (id) {
    'region' => <String>[
      if (d.withinMinutes != null) L.within(d.withinMinutes!),
      if (d.governorateIds != null) d.governorateIds!.isEmpty ? l.clientDiscoverChipGovernoratesAll : L.governorates(d.governorateIds!),
    ].join(sep),
    'type' => list(d.types.map(L.venueType)),
    'arrangement' => d.arrangement == null ? '' : L.arrangement(d.arrangement!),
    'capacity' => d.capacity == null ? '' : L.capacity(d.capacity!.$1, d.capacity!.$2),
    'structure' => d.structure == null ? '' : L.structure(d.structure!),
    'date' => d.dates != null ? L.dateRange(d.dates!) : (brief.date != null && d.available ? L.day(brief.date.toString()) : ''),
    'voucher' => <String>[if (d.voucherOnly) l.clientDiscoverChipVoucher, if (d.voucherPrice != null) L.moneyRange(d.voucherPrice!.$1, d.voucherPrice!.$2)].join(sep),
    'price' => d.price == null ? '' : L.moneyRange(d.price!.$1, d.price!.$2),
    'setting' => list(d.settings.map(L.setting)),
    'facilities' => list(d.facilities.map(L.facility)),
    'rating' => d.minRating == null ? '' : L.ratingChip(d.minRating!),
    'level' => list(d.levels.map(L.level)),
    _ => list(d.brands),
  };
}

/// The body of one group.
Widget filterGroupBody(BuildContext context, String id, FilterCtx x) {
  final l = context.l10n;
  final c = context.gz.colors;
  final f = context.gzFormat;
  final d = x.draft;
  final L = x.labels;
  final gap = const SizedBox(height: GzSpace.s3);
  switch (id) {
    case 'region':
      // The shared governorate chips (ADR 0038: never an exact area): the filter's own choice, else the Brief's, so they can be switched off.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzGovernorateFilter(
            governorates: x.governorates,
            label: l.clientDiscoverChipRegion,
            values: d.governorateIds ?? x.brief.governorateIds,
            onChanged: (ids) => x.patch((v) => v.copyWith(governorateIds: ids)),
          ),
          gap,
          ChoiceChips<int>(
            label: l.clientDiscoverA11yDrive,
            selected: d.withinMinutes == null ? const <int>[] : <int>[d.withinMinutes!],
            onToggle: (m) => x.askLocation(d.withinMinutes == m ? null : m),
            options: [for (final m in kDistances) (value: m, label: L.within(m), icon: GzIcons.car)],
          ),
        ],
      );
    case 'type':
      return Row(
        children: [
          Expanded(
            child: ChoiceChips<VenueType>(
              label: l.clientDiscoverFiltersGroupType,
              selected: d.types,
              onToggle: (v) => x.patch((o) => o.copyWith(types: _toggle(o.types, v))),
              options: [for (final t in VenueType.values.where((t) => t != VenueType.unknown)) (value: t, label: L.venueType(t), icon: typeIcon(t))],
            ),
          ),
          GzInfoButton(
 key: const ValueKey<String>('discover.info'),
 title: context.gzL10n.commonVenueTypeGovernmental,
 paragraphs: [l.clientDiscoverResultsGovernmentNote],
 ),
        ],
      );
    case 'arrangement':
      return ChoiceChips<Audience>(
        label: l.clientDiscoverFiltersGroupArrangement,
        selected: d.arrangement == null ? const <Audience>[] : <Audience>[d.arrangement!],
        onToggle: (a) => x.patch((o) => o.arrangement == a ? o.copyWith(clearArrangement: true) : o.copyWith(arrangement: a)),
        options: [for (final a in kArrangements) (value: a, label: L.arrangement(a), icon: arrangementIcon(a))],
      );
    case 'capacity':
      final floor = x.brief.guests == null ? kCapacityBounds.$1 : ((x.brief.guests! ~/ kCapacityStep) * kCapacityStep).clamp(kCapacityBounds.$1, kCapacityBounds.$2);
      final v = d.capacity ?? (floor, kCapacityBounds.$2);
      return GzRangeSlider(
        min: kCapacityBounds.$1.toDouble(),
        max: kCapacityBounds.$2.toDouble(),
        step: kCapacityStep.toDouble(),
        label: l.clientDiscoverFiltersGroupCapacity,
        value: (v.$1.toDouble(), v.$2.toDouble()),
        showCaptions: false,
        valueText: (n, _) => f.guests(n.round()),
        formatValue: (context, n, _) => gzFigText(context, f.integer(n.round()), role: GzTextRole.figBodyS, color: c.textStrong),
        onChanged: (r) => x.patch((o) => r.$1.round() == kCapacityBounds.$1 && r.$2.round() == kCapacityBounds.$2 ? o.copyWith(clearCapacity: true) : o.copyWith(capacity: (r.$1.round(), r.$2.round()))),
      );
    case 'structure':
      return ChoiceChips<PriceStructureFilter>(
        label: l.clientDiscoverFiltersGroupStructure,
        selected: d.structure == null ? const <PriceStructureFilter>[] : <PriceStructureFilter>[d.structure!],
        onToggle: (s) => x.patch((o) => o.structure == s ? o.copyWith(clearStructure: true) : o.copyWith(structure: s)),
        options: [
          (value: PriceStructureFilter.perPerson, label: L.structure(PriceStructureFilter.perPerson), icon: GzIcons.perGuest),
          (value: PriceStructureFilter.package, label: L.structure(PriceStructureFilter.package), icon: GzIcons.package),
        ],
      );
    case 'date':
      return Wrap(
        spacing: GzSpace.s3,
        runSpacing: GzSpace.s3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GzChip(
            key: const ValueKey<String>('discover.filters.available'),
            label: x.brief.date == null ? l.clientDiscoverChipDate : L.day(x.brief.date.toString()),
            iconStart: GzIcons.calendarCheck,
            selected: x.brief.date != null && d.available,
            disabled: x.brief.date == null,
            onPressed: () => x.patch((o) => o.copyWith(available: !o.available)),
          ),
          GzChip(key: const ValueKey<String>('discover.filters.calendar'), label: l.clientDiscoverFiltersDateOpen, iconStart: GzIcons.calendar, menu: true, onPressed: x.openDates),
        ],
      );
    case 'voucher':
      final rates = <double>[for (final r in x.roster) ?perGuestKd(r.price, voucher: true)];
      final range = d.voucherPrice ?? kVoucherPriceBounds;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GzChip(
                key: const ValueKey<String>('discover.filters.voucheronly'),
                label: l.clientDiscoverFiltersVoucherTitle,
                iconStart: GzIcons.ticket,
                selected: d.voucherOnly,
                onPressed: () => x.patch((o) => o.copyWith(voucherOnly: !o.voucherOnly)),
              ),
              GzFactChip(icon: GzIcons.venue, label: l.clientDiscoverFiltersVoucherCount, value: f.integer(x.roster.where((r) => r.venue.voucherEnabled).length), tone: GzFactTone.muted),
            ],
          ),
          gap,
          Histogram(values: rates, min: kVoucherPriceBounds.$1.toDouble(), max: kVoucherPriceBounds.$2.toDouble(), range: (range.$1.toDouble(), range.$2.toDouble())),
          const SizedBox(height: GzSpace.s2),
          _moneySlider(context, x, l.clientDiscoverFiltersGroupVoucher, kVoucherPriceBounds, d.voucherPrice, (o, r) => r == null ? o.copyWith(clearVoucherPrice: true) : o.copyWith(voucherPrice: r)),
        ],
      );
    case 'price':
      final rates = <double>[for (final r in x.roster) ?perGuestKd(r.price, voucher: false)];
      final range = d.price ?? kPriceBounds;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Histogram(values: rates, min: kPriceBounds.$1.toDouble(), max: kPriceBounds.$2.toDouble(), range: (range.$1.toDouble(), range.$2.toDouble())),
          const SizedBox(height: GzSpace.s2),
          _moneySlider(context, x, l.clientDiscoverFiltersGroupPrice, kPriceBounds, d.price, (o, r) => r == null ? o.copyWith(clearPrice: true) : o.copyWith(price: r)),
        ],
      );
    case 'setting':
      return ChoiceChips<HallSetting>(
        label: l.clientDiscoverFiltersGroupSetting,
        selected: d.settings,
        onToggle: (s) => x.patch((o) => o.copyWith(settings: _toggle(o.settings, s))),
        options: [for (final s in kSettings) (value: s, label: L.setting(s), icon: settingIcon(s))],
      );
    case 'facilities':
      return ChoiceChips<DiscoverFacility>(
        label: l.clientDiscoverFiltersGroupFacilities,
        selected: d.facilities,
        onToggle: (k) => x.patch((o) => o.copyWith(facilities: _toggle(o.facilities, k))),
        options: [for (final k in DiscoverFacility.values) (value: k, label: L.facility(k), icon: facilityIcon(k))],
      );
    case 'rating':
      return ChoiceChips<double>(
        label: l.clientDiscoverFiltersGroupRating,
        selected: d.minRating == null ? const <double>[] : <double>[d.minRating!],
        onToggle: (r) => x.patch((o) => o.minRating == r ? o.copyWith(clearMinRating: true) : o.copyWith(minRating: r)),
        options: [for (final r in kRatings) (value: r, label: L.ratingChip(r), icon: GzIcons.star)],
      );
    case 'level':
      return ChoiceChips<LuxuryLevel>(
        label: l.clientDiscoverFiltersGroupLevel,
        selected: d.levels,
        onToggle: (v) => x.patch((o) => o.copyWith(levels: _toggle(o.levels, v))),
        options: [for (final v in kLevels) (value: v, label: L.level(v), icon: levelIcon(v))],
      );
    default:
      return ChoiceChips<String>(
        label: l.clientDiscoverFiltersGroupBrand,
        selected: d.brands,
        onToggle: (b) => x.patch((o) => o.copyWith(brands: _toggle(o.brands, b))),
        options: [for (final b in kBrands) (value: b, label: L.brand(b, x.roster), icon: null)],
      );
  }
}

Widget _moneySlider(BuildContext context, FilterCtx x, String label, (int, int) bounds, (int, int)? value, DiscoverFilters Function(DiscoverFilters o, (int, int)? r) set) {
  final c = context.gz.colors;
  final v = value ?? bounds;
  return GzRangeSlider(
    min: bounds.$1.toDouble(),
    max: bounds.$2.toDouble(),
    step: 1,
    label: label,
    value: (v.$1.toDouble(), v.$2.toDouble()),
    showCaptions: false,
    valuesAt: GzRangeValues.below,
    valueText: (n, _) => x.labels.money(n.round()),
    formatValue: (context, n, _) => Text.rich(
      TextSpan(children: GzFigures.spans(context, x.labels.money(n.round()), role: GzTextRole.figBodyS)),
      style: context.gz.text(GzTextRole.figBodyS).copyWith(color: c.textStrong, decoration: TextDecoration.none),
    ),
    onChanged: (r) => x.patch((o) => set(o, r.$1.round() == bounds.$1 && r.$2.round() == bounds.$2 ? null : (r.$1.round(), r.$2.round()))),
  );
}
