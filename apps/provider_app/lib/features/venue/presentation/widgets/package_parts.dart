// The pieces of the package editor (web `PackageParts.tsx`): a day-tier price block with both prices, the "What couples see" preview, the
// inclusion chips and the sheet that adds an inclusion. Prices are integer fils; the voucher rule is the engine's (`venue_pricing.dart`).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions, NameStyle, PricePrefix;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/package_draft.dart';
import '../../application/venue_data.dart';
import '../../application/venue_pricing.dart';
import 'venue_bits.dart';
import 'venue_fields.dart';

const int _fallbackFee = 2000;
const MoneyOptions _browse = MoneyOptions(mode: MoneyMode.browse);

/// `Weekday · Sun to Wed` / `Weekend · Thu to Sat`.
String tierDays(BuildContext context, bool weekend) {
  final f = context.gzFormat;
  final l = context.l10n;
  final from = f.weekdayName(weekend ? 4 : 0, NameStyle.short);
  final to = f.weekdayName(weekend ? 6 : 3, NameStyle.short);
  return weekend ? l.hotelVenueDaysWeekend(from, to) : l.hotelVenueDaysWeekday(from, to);
}

// ---------------------------------------------------------------- tiers

/// One set of days: a switch, and when it is on two price groups on the basis the structure asks for (voucher <= standard; empty = none).
class TierEditor extends ConsumerWidget {
  const TierEditor({required this.weekend, required this.model, required this.basis, required this.showEmpty, required this.onChanged, super.key});

  final bool weekend;
  final TierDraft model;
  final PricingBasis basis;
  final bool showEmpty;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final title = tierDays(context, weekend);
    final flat = needsFlat(basis);
    final guest = needsGuest(basis);
    final fee = ref.watch(venueConfigProvider).value?.voucherFeeFils ?? _fallbackFee;
    final guests = ref.watch(sampleBookingProvider).value?.sections.firstOrNull?.guests ?? 350;
    final above = voucherAbove(model);
    final st = voucherState(basis, model, guests, fee);
    Widget group(IconData icon, String name, List<Widget> kids, {bool tint = false}) => Container(
      padding: tint ? const EdgeInsetsDirectional.all(GzSpace.s4) : null,
      decoration: tint ? BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.smAll) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              Expanded(child: GzText(name, role: GzTextRole.label, color: c.textStrong)),
            ],
          ),
          for (final k in kids) ...[const SizedBox(height: GzSpace.s3), k],
        ],
      ),
    );
    void set(void Function() fn) {
      fn();
      onChanged();
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: model.on ? c.borderControl : c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: GzText(title, role: GzTextRole.title, color: c.textStrong)),
              GzSwitch(label: l.hotelVenueDaysSwitch(title), checked: model.on, onChanged: (v) => set(() => model.on = v)),
            ],
          ),
          if (model.on) ...[
            const SizedBox(height: GzSpace.s4),
            group(GzIcons.coins, l.hotelVenueStd, [
              if (flat) PriceField(label: l.hotelVenueStdFlat, fils: model.flat, onChanged: (v) => set(() => model.flat = v), error: showEmpty && model.flat == null ? l.hotelVenueNeedPrice : null),
              if (guest)
                PriceField(label: l.hotelVenueStdPerGuest, fils: model.perGuest, onChanged: (v) => set(() => model.perGuest = v), error: showEmpty && model.perGuest == null ? l.hotelVenueNeedPrice : null),
            ]),
            const SizedBox(height: GzSpace.s4),
            group(
              GzIcons.ticket,
              l.hotelVenueVch,
              [
                if (flat) PriceField(label: l.hotelVenueVchFlat, fils: model.vFlat, onChanged: (v) => set(() => model.vFlat = v), error: above.flat ? l.hotelVenueVoucherAboveFlat : null),
                if (guest) PriceField(label: l.hotelVenueVchPerGuest, fils: model.vPerGuest, onChanged: (v) => set(() => model.vPerGuest = v), error: above.guest ? l.hotelVenueVoucherAboveGuest : null),
                if (st.state == VoucherState.belowFee) FactLine(l.hotelVenueVchBelowFee(f.money(fee, _browse)), icon: GzIcons.warningCircle),
                if (st.state == VoucherState.ok) FactLine(l.hotelVenueVchSaving(f.money(st.saving, _browse)), icon: GzIcons.checkCircle),
              ],
              tint: true,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- preview

class _Quote {
  const _Quote(this.std, this.vch);
  final int std;
  final int? vch;
}

/// "What couples see": the three price lines of the client card, recomputed on every edit. A tier whose saving does not beat the voucher fee
/// shows the standard price alone, exactly as the client app does.
class PackagePreview extends ConsumerWidget {
  const PackagePreview({required this.draft, required this.name, super.key});

  final PackageDraft draft;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final sample = ref.watch(sampleBookingProvider).value;
    final config = ref.watch(venueConfigProvider).value;
    final fee = config?.voucherFeeFils ?? _fallbackFee;
    final weekendDays = config?.weekendTierDays ?? const [4, 5, 6];
    final date = sample?.eventDate ?? const LocalDate(2027, 1, 14);
    final sampleGuests = sample?.sections.firstOrNull?.guests ?? 350;
    final guests = sampleGuests.clamp(draft.minGuests, draft.maxGuests > draft.minGuests ? draft.maxGuests : draft.minGuests);
    final basis = draft.basis;
    final day = weekendDays.contains(date.weekdayIndex) ? draft.weekend : draft.weekday;
    _Quote? quote(TierDraft t, int n) {
      final std = standardTotal(basis, t, n);
      if (std == null) return null;
      final ok = voucherState(basis, t, n, fee).state == VoucherState.ok;
      return _Quote(std, ok ? voucherTotal(basis, t, n) : null);
    }

    final offered = [if (draft.weekday.on) (false, draft.weekday), if (draft.weekend.on) (true, draft.weekend)];
    final priced = [for (final (w, t) in offered) (weekend: w, at: quote(t, guests), min: quote(t, draft.minGuests))].where((p) => p.at != null && p.min != null).toList()
      ..sort((a, b) => (a.at!.vch ?? a.at!.std).compareTo(b.at!.vch ?? b.at!.std));
    final lowest = priced.firstOrNull;
    final onDate = day.on ? quote(day, guests) : null;
    final lines = <({String label, IconData icon, _Quote? q, String Function(_Quote) head, String? tail, String off})>[
      (
        label: l.hotelVenuePvDate,
        icon: GzIcons.calendar,
        q: onDate,
        head: (q) => f.priceForGuests(q.vch ?? q.std, guests),
        tail: '${f.date(date.toJson(), DateStyle.short)} · ${l.commonAvailabilityFree}',
        off: l.hotelVenuePvOff,
      ),
      (
        label: l.hotelVenuePvGuests,
        icon: GzIcons.guests,
        q: lowest?.at,
        head: (q) => f.priceForGuests(q.vch ?? q.std, guests, PricePrefix.from),
        tail: lowest == null ? null : (lowest.weekend ? l.commonTierWeekend : l.commonTierWeekday),
        off: l.hotelVenueTierNeeded,
      ),
      (label: l.hotelVenuePvNone, icon: GzIcons.user, q: lowest?.min, head: (q) => f.fromPriceMin(q.vch ?? q.std, draft.minGuests), tail: null, off: l.hotelVenueTierNeeded),
    ];
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(name.isEmpty ? l.hotelVenuePvNoName : name, role: GzTextRole.title, color: c.textStrong),
          const SizedBox(height: GzSpace.s3),
          for (final ln in lines)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderStrong, width: GzStroke.hair)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(label: ln.label, excludeSemantics: true, child: GzIcon(ln.icon, size: GzIconSize.xs, color: c.iconSecondary)),
                  const SizedBox(height: GzSpace.s1),
                  if (ln.q == null)
                    GzText(ln.off, role: GzTextRole.bodyS, color: c.textSecondary)
                  else ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s2,
                      children: [
                        if (ln.q!.vch != null) GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
                        GzText(ln.head(ln.q!), role: GzTextRole.title, color: c.textStrong, figures: true),
                        if (ln.tail != null) GzText(ln.tail!, role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
                      ],
                    ),
                    if (ln.q!.vch != null) GzText(l.hotelVenuePvStandard(f.money(ln.q!.std, _browse)), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- inclusions

class InclusionChips extends StatelessWidget {
  const InclusionChips({required this.items, required this.onRemove, required this.onAdd, super.key});

  final List<LocalizedText> items;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    Widget chip({required Widget child, required Color color}) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.smAll,
        border: Border.all(color: color, width: GzStroke.hair),
      ),
      child: child,
    );
    return Wrap(
      spacing: GzSpace.s2,
      runSpacing: GzSpace.s2,
      children: [
        for (var i = 0; i < items.length; i++)
          chip(
            color: c.controlChipBorder,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.s3),
                    child: GzText(items[i].of(lang), role: GzTextRole.bodyS, color: c.textPrimary),
                  ),
                ),
                GzPressable(
                  onPressed: () => onRemove(i),
                  semanticLabel: l.hotelVenueInclusionRemove(items[i].of(lang)),
                  child: SizedBox(width: GzSize.touchMin, height: GzSize.touchMin, child: Center(child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.iconSecondary))),
                ),
              ],
            ),
          ),
        chip(
          color: c.controlChipBorder,
          child: GzPressable(
            onPressed: onAdd,
            semanticLabel: l.hotelVenueInclusionAdd,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.plus, size: GzIconSize.xs, color: c.textGoldInk),
                  const SizedBox(width: GzSpace.s2),
                  GzText(l.hotelVenueInclusionAdd, role: GzTextRole.bodyS, color: c.textGoldInk),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final FutureProvider<List<AmenityDef>> _poolProvider = FutureProvider.autoDispose<List<AmenityDef>>((ref) async {
  final t = await ref.read(venuesRepositoryProvider).getFilterTaxonomy();
  return [
    for (final a in t.amenities)
      if (a.group == AmenityGroup.space || a.group == AmenityGroup.service || a.group == AmenityGroup.production) a,
  ];
});

/// Add to the package: pick from the facilities taxonomy (bilingual already) or write a free entry in both languages.
class InclusionSheet extends ConsumerStatefulWidget {
  const InclusionSheet({required this.have, required this.onAdd, super.key});

  final List<LocalizedText> have;
  final ValueChanged<List<LocalizedText>> onAdd;

  @override
  ConsumerState<InclusionSheet> createState() => _InclusionSheetState();
}

class _InclusionSheetState extends ConsumerState<InclusionSheet> {
  List<String> _picked = const [];
  String _ar = '';
  String _en = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final taken = {for (final h in widget.have) h.en};
    final pool = [
      for (final a in ref.watch(_poolProvider).value ?? const <AmenityDef>[])
        if (!taken.contains(a.label.en)) a,
    ];
    final half = _ar.trim().isNotEmpty != _en.trim().isNotEmpty;
    final own = _ar.trim().isNotEmpty && _en.trim().isNotEmpty;
    final ready = (_picked.isNotEmpty || own) && !half;
    return SheetColumn(
      footer: GzButton(
        label: l.commonActionAdd,
        fullWidth: true,
        reason: half ? l.hotelVenueInclusionBoth : null,
        onPressed: !ready
            ? null
            : () {
                widget.onAdd([for (final a in pool) if (_picked.contains(a.id)) a.label, if (own) LocalizedText(ar: _ar.trim(), en: _en.trim())]);
                nav.closeSheet();
              },
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzText(l.hotelVenueInclusionPick, role: GzTextRole.label, color: c.textSecondary),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<String>.multiple(
              label: l.hotelVenueInclusionPick,
              values: _picked,
              onChanged: (v) => setState(() => _picked = v),
              options: [for (final a in pool) GzChipOption<String>(value: a.id, label: a.label.of(lang))],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzText(l.hotelVenueInclusionOwn, role: GzTextRole.label, color: c.textSecondary),
            const SizedBox(height: GzSpace.s2),
            BilingualField(label: l.hotelVenueInclusionOwnLabel, ar: _ar, en: _en, onAr: (v) => setState(() => _ar = v), onEn: (v) => setState(() => _en = v), maxLength: 60, required: false),
            if (half) ...[const SizedBox(height: GzSpace.s2), FormError(l.hotelVenueInclusionBoth)],
          ],
        ),
      ],
    );
  }
}
