// HL-VENU-03 Edit package (web `HL-VENU-03.tsx`): bilingual name and description, audience and halls, the pricing structure with a standard price AND
// a voucher price per set of days (voucher <= standard), guest limits, inclusions, active state and a live "What couples see" preview. What the phone
// does not edit is stated as read-only (dashboard). Param `packageId` (a package id, or `new`).
// Requirements: HA-VMGT-03, HA-VMGT-04, HA-VMGT-09, HA-VMGT-11, HA-VMGT-12, HA-VMGT-13, HA-AUTH-02 (voucher model, ADR 0033).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/package_draft.dart';
import '../application/venue_data.dart';
import '../application/venue_pricing.dart';
import 'widgets/package_parts.dart';
import 'widgets/venue_bits.dart';
import 'widgets/venue_fields.dart';
import 'widgets/venue_labels.dart';

/// The package a static frame shows (web `DEMO_ID`): Ladies' Reception, Weekend.
const String kDemoPackageId = 'V01-ladies-weekend';
const List<int> _guestPresets = <int>[100, 150, 200, 300, 400, 500, 650, 800, 1000];
const int _guestHardCap = 1500;

class HlVenu03Screen extends ConsumerStatefulWidget {
  const HlVenu03Screen({super.key});

  @override
  ConsumerState<HlVenu03Screen> createState() => _HlVenu03ScreenState();
}

class _HlVenu03ScreenState extends ConsumerState<HlVenu03Screen> {
  PackageDraft? _d;
  String _base = '';
  bool _saved = false;

  bool get _dirty => _d != null && _d!.signature != _base;

  PackageDraft _seed(PackageCatalog cat, List<Hall> halls, String requested) {
    if (requested == 'new') return PackageDraft.blank(hallIds: halls.length == 1 ? [halls.first.id] : const []);
    final e = packageOf(cat, requested) ?? packageOf(cat, kDemoPackageId) ?? cat.packages.firstOrNull;
    return e == null ? PackageDraft.blank() : PackageDraft.of(e);
  }

  Future<void> _save() async {
    final d = _d!;
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final res = await ref.read(venueActionsProvider.notifier).savePackage(d.isNew ? null : d.id, d.toInput());
    if (!mounted) return;
    if (!res.isSuccess) return toastResult(context, res);
    _base = d.signature;
    setState(() => _saved = true);
    nav.toast(GzToastSpec(message: d.isNew ? l.hotelVenueToastPkgCreated : l.hotelVenueToastPkgSaved, icon: GzIcons.checkCircle));
    nav.pop();
  }

  Future<void> _archive() async {
    final d = _d!;
    final e = d.source;
    if (e == null) return;
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final name = LocalizedText(ar: d.nameAr, en: d.nameEn).of(context.gz.locale.languageCode);
    final answer = await nav.openDialog(
      GzDialogSpec(
        title: l.hotelVenueArchiveTitle,
        body: l.hotelVenueArchiveBody,
        icon: GzIcons.document,
        confirmLabel: l.hotelVenueArchiveConfirm,
        cancelLabel: l.hotelVenueDeleteKeep,
        tone: GzDialogTone.destructive,
      ),
    );
    if (answer != GzDialogResult.confirm || !mounted) return;
    final actions = ref.read(venueActionsProvider.notifier);
    final res = await actions.savePackage(e.package.id, packageInputOf(e, active: false));
    if (!mounted) return;
    if (!res.isSuccess) return toastResult(context, res);
    _base = d.signature;
    nav.pop();
    nav.toast(
      GzToastSpec(
        message: l.hotelVenueToastArchived(name),
        undo: true,
        action: GzToastAction(label: l.commonActionUndo, onPressed: () => actions.savePackage(e.package.id, packageInputOf(e, active: true))),
      ),
    );
  }

  void _addInclusion() {
    final d = _d!;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => InclusionSheet(have: d.inclusions, onAdd: (items) => setState(() => d.inclusions = [...d.inclusions, ...items])),
      options: GzSheetOptions(title: context.l10n.hotelVenueInclusionSheetTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final value = ref.watch(venueCatalogProvider);
    final hallsValue = ref.watch(venueHallsProvider);
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(lang);
    final requested = nav.params['packageId'] as String? ?? kDemoPackageId;
    final cat = value.value;
    final halls = hallsValue.value?.halls;
    if (_d == null && cat != null && halls != null) {
      _d = _seed(cat, halls, requested);
      _base = _d!.signature;
    }
    final d = _d;
    final isNew = d?.isNew ?? requested == 'new';
    final top = GzTopBar(title: isNew ? l.hotelVenuePkgNew : l.hotelVenuePkgEditTitle, subtitle: venueName);
    if (d == null) {
      return GzScreen(
        top: top,
        child: GzAsyncView<PackageCatalog>(
          value: combineCatalog(value, hallsValue),
          loading: const FormSkeleton(rows: 6),
          onRetry: () {
            ref.invalidate(venueCatalogProvider);
            ref.invalidate(venueHallsProvider);
          },
          data: (_) => const FormSkeleton(rows: 6),
        ),
      );
    }
    final hallList = halls ?? const <Hall>[];
    final multiHall = hallList.length > 1;
    final saving = ref.watch(venueActionsProvider).busy.contains('save:package');
    final reserved = isReservedName(d.nameAr) || isReservedName(d.nameEn);
    final namesMissing = d.nameAr.trim().isEmpty || d.nameEn.trim().isEmpty;
    final noAudience = d.audiences.isEmpty;
    final noHall = multiHall && d.hallIds.isEmpty;
    final tiers = [d.weekday, d.weekend];
    final noTier = !d.bundle && !d.weekday.on && !d.weekend.on;
    final pricesMissing = !d.bundle && tiers.any((t) => t.on && ((needsFlat(d.basis) && t.flat == null) || (needsGuest(d.basis) && t.perGuest == null)));
    final voucherHigher = !d.bundle && tiers.any((t) => t.on && (voucherAbove(t).flat || voucherAbove(t).guest));
    final structure = structureOf(d.basis);
    final ids = d.hallIds.isNotEmpty ? d.hallIds : [for (final h in hallList) h.id];
    final hallCap = ids.map((id) => hallList.where((h) => h.id == id).firstOrNull?.capacity.max ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    final maxBelowMin = d.maxGuests < d.minGuests;
    final maxOverHall = hallCap > 0 && d.maxGuests > hallCap;
    final problem = namesMissing
        ? l.hotelVenueNameRequired
        : reserved
        ? l.hotelVenueReservedName
        : noAudience
        ? l.hotelVenueAudienceNeeded
        : noHall
        ? l.hotelVenueHallsNeeded
        : noTier
        ? l.hotelVenueTierNeeded
        : pricesMissing
        ? l.hotelVenueReasonPrices
        : voucherHigher
        ? l.hotelVenueReasonVoucher
        : (maxBelowMin || maxOverHall)
        ? l.hotelVenueReasonGuests
        : null;
    final displayName = LocalizedText(ar: d.nameAr, en: d.nameEn).of(lang);
    void patch(void Function() fn) => setState(() {
      fn();
      _saved = false;
    });
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmDiscard(context, dirty: true) && context.mounted) nav.pop();
      },
      child: GzScreen(
        top: top,
        bottom: venueSaveBar(context, dirty: _dirty || isNew, problem: problem, saving: saving, saved: _saved && !_dirty, onSave: _save, label: isNew ? l.commonActionSave : null),
        child: VenuePage(
          children: [
            VenueSection(
              title: l.hotelVenueSecName,
              children: [
                BilingualField(
                  label: l.hotelVenueFieldName,
                  ar: d.nameAr,
                  en: d.nameEn,
                  maxLength: 60,
                  onAr: (v) => patch(() => d.nameAr = v),
                  onEn: (v) => patch(() => d.nameEn = v),
                  errorAr: isReservedName(d.nameAr) ? l.hotelVenueReservedName : null,
                  errorEn: isReservedName(d.nameEn) ? l.hotelVenueReservedName : null,
                ),
                BilingualField(
                  label: l.hotelVenueFieldDescription,
                  ar: d.descAr,
                  en: d.descEn,
                  multiline: true,
                  maxLength: 240,
                  onAr: (v) => patch(() => d.descAr = v),
                  onEn: (v) => patch(() => d.descEn = v),
                ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecAudience,
              children: [
                GzChipGroup<Audience>.multiple(
                  label: l.hotelVenueAudienceLabel,
                  values: d.audiences,
                  onChanged: (next) => patch(() => d.audiences = [for (final a in kAudiences) if (next.contains(a)) a]),
                  options: [for (final a in kAudiences) GzChipOption<Audience>(value: a, label: audienceLabel(l, a))],
                ),
                if (multiHall)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GzText(l.hotelVenueHallsLabel, role: GzTextRole.label, color: context.gz.colors.textPrimary),
                      const SizedBox(height: GzSpace.s2),
                      GzChipGroup<String>.multiple(
                        label: l.hotelVenueHallsLabel,
                        values: d.hallIds,
                        onChanged: (next) => patch(() => d.hallIds = [for (final h in hallList) if (next.contains(h.id)) h.id]),
                        options: [for (final h in hallList) GzChipOption<String>(value: h.id, label: h.name.of(lang))],
                      ),
                    ],
                  ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecPricing,
              children: [
                GzIconSegmented<PriceStructure>(
                  label: l.commonPricingStructure,
                  value: structure,
                  disabled: d.bundle,
                  onChanged: (next) => patch(
                    () => d.basis = next == PriceStructure.perPerson ? PricingBasis.perGuest : (d.basis == PricingBasis.perGuest ? PricingBasis.flat : d.basis),
                  ),
                  options: [
                    GzIconSegmentedOption(value: PriceStructure.perPerson, icon: GzIcons.perGuest, label: l.commonPricingPerPerson),
                    GzIconSegmentedOption(value: PriceStructure.package, icon: GzIcons.package, label: l.commonPricingPackage),
                  ],
                ),
                if (structure == PriceStructure.package && !d.bundle)
                  GzSegmentedControl<PricingBasis>(
                    label: l.hotelVenueBasisLabel,
                    value: d.basis,
                    onChanged: (v) => patch(() => d.basis = v),
                    options: [
                      GzSegmentedOption(value: PricingBasis.flat, label: l.hotelVenueBasisFlat),
                      GzSegmentedOption(value: PricingBasis.flatPlusPerGuest, label: l.hotelVenueBasisFlatPlus),
                    ],
                  ),
                if (d.bundle)
                  FactLine(l.hotelVenueBundleNote)
                else ...[
                  TierEditor(weekend: false, model: d.weekday, basis: d.basis, showEmpty: !isNew, onChanged: () => patch(() {})),
                  TierEditor(weekend: true, model: d.weekend, basis: d.basis, showEmpty: !isNew, onChanged: () => patch(() {})),
                  if (noTier) FormError(l.hotelVenueTierNeeded),
                ],
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecGuests,
              children: [
                GuestPicker(label: l.hotelVenueGuestsMin, value: d.minGuests, min: d.guestStep, max: _guestHardCap, step: d.guestStep, presets: _guestPresets, onChanged: (v) => patch(() => d.minGuests = v)),
                GuestPicker(
                  label: l.hotelVenueGuestsMax,
                  value: d.maxGuests,
                  min: d.guestStep,
                  max: _guestHardCap,
                  step: d.guestStep,
                  presets: _guestPresets,
                  onChanged: (v) => patch(() => d.maxGuests = v),
                  error: maxBelowMin ? l.hotelVenueMaxBelowMin : (maxOverHall ? l.hotelVenueMaxOverHall(context.gzFormat.integer(hallCap)) : null),
                ),
              ],
            ),
            VenueSection(
              title: l.hotelVenueSecInclusions,
              children: [
                InclusionChips(items: d.inclusions, onRemove: (i) => patch(() => d.inclusions = [for (var j = 0; j < d.inclusions.length; j++) if (j != i) d.inclusions[j]]), onAdd: _addInclusion),
              ],
            ),
            VenueSection(title: l.hotelVenueSecPreview, children: [PackagePreview(draft: d, name: displayName)]),
            VenueSection(
              title: l.hotelVenueSecStatus,
              children: [
                GzToggleRow(title: l.hotelVenueActiveTitle, divider: false, checked: d.active, onChanged: (v) => patch(() => d.active = v)),
                if (!isNew)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzButton(label: l.hotelVenueArchive, variant: GzButtonVariant.destructive, iconStart: GzIcons.document, onPressed: _archive),
                  ),
              ],
            ),
            const DashboardNote(),
          ],
        ),
      ),
    );
  }
}

/// The catalog and the halls as one value for the loading and error states.
AsyncValue<PackageCatalog> combineCatalog(AsyncValue<PackageCatalog> cat, AsyncValue<HallList> halls) {
  if (cat.hasError && !cat.hasValue) return cat;
  if (halls.hasError && !halls.hasValue) return AsyncValue<PackageCatalog>.error(halls.error!, halls.stackTrace ?? StackTrace.empty);
  return const AsyncValue<PackageCatalog>.loading();
}
