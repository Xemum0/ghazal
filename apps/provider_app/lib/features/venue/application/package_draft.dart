// The draft of the package editor (HL-VENU-03): what the phone edits of one package, the rest is sent back as it was (`packageInputOf`).
import 'package:ghazal_domain/ghazal_domain.dart';

import 'venue_pricing.dart';

const List<Audience> kAudiences = <Audience>[Audience.women, Audience.men, Audience.mixed];

class PackageDraft {
  PackageDraft({
    required this.id,
    required this.isNew,
    this.nameAr = '',
    this.nameEn = '',
    this.descAr = '',
    this.descEn = '',
    List<Audience>? audiences,
    List<String>? hallIds,
    this.basis = PricingBasis.perGuest,
    TierDraft? weekday,
    TierDraft? weekend,
    this.minGuests = 100,
    this.maxGuests = 500,
    this.guestStep = 10,
    List<LocalizedText>? inclusions,
    this.active = true,
    this.bundle = false,
    this.source,
  }) : audiences = audiences ?? <Audience>[Audience.women],
       hallIds = hallIds ?? <String>[],
       weekday = weekday ?? TierDraft(on: true),
       weekend = weekend ?? TierDraft(),
       inclusions = inclusions ?? <LocalizedText>[];

  factory PackageDraft.blank({List<String> hallIds = const []}) => PackageDraft(id: 'new', isNew: true, hallIds: [...hallIds]);

  factory PackageDraft.of(PackageEditor e) {
    final p = e.package;
    return PackageDraft(
      id: p.id,
      isNew: false,
      nameAr: p.name.ar ?? '',
      nameEn: p.name.en ?? '',
      descAr: p.description.ar ?? '',
      descEn: p.description.en ?? '',
      audiences: [...p.audiences],
      hallIds: [...p.hallIds],
      basis: p.pricingBasis,
      weekday: TierDraft.of(e, PriceTier.weekday),
      weekend: TierDraft.of(e, PriceTier.weekend),
      minGuests: p.minGuests,
      maxGuests: p.maxGuests,
      guestStep: p.guestStep,
      inclusions: [...p.inclusions],
      active: p.active,
      bundle: p.components != null && p.components!.isNotEmpty,
      source: e,
    );
  }

  final String id;
  final bool isNew;
  String nameAr;
  String nameEn;
  String descAr;
  String descEn;
  List<Audience> audiences;
  List<String> hallIds;
  PricingBasis basis;
  TierDraft weekday;
  TierDraft weekend;
  int minGuests;
  int maxGuests;
  final int guestStep;
  List<LocalizedText> inclusions;
  bool active;
  final bool bundle;
  final PackageEditor? source;

  String get signature => [
    nameAr,
    nameEn,
    descAr,
    descEn,
    audiences.map((a) => a.value).join(','),
    hallIds.join(','),
    basis.value,
    weekday.signature,
    weekend.signature,
    minGuests,
    maxGuests,
    inclusions.map((i) => '${i.ar}|${i.en}').join(';'),
    active,
  ].join('/');

  /// The body of the write: the untouched parts of the stored package stay as they were.
  PackageInput toInput() {
    final s = source;
    final structure = structureOf(basis);
    final rules = s == null
        ? rulesAfterEdit(null, weekday, weekend, basis)
        : (bundle ? [for (final r in s.rules) ruleInputOf(r)] : rulesAfterEdit(s, weekday, weekend, basis));
    final p = s?.package;
    return PackageInput(
      hallIds: hallIds,
      name: LocalizedText(ar: nameAr.trim(), en: nameEn.trim()),
      archetype: p?.archetype ?? PackageArchetype.ladiesStandard,
      audiences: audiences,
      pricingBasis: basis,
      priceStructure: structure,
      priceUnit: structure == PriceStructure.perPerson ? WirePriceUnit.perGuest : WirePriceUnit.flat,
      minGuests: minGuests,
      maxGuests: maxGuests,
      guestStep: guestStep,
      complimentaryBps: p?.complimentaryBps ?? 0,
      description: LocalizedText(ar: descAr.trim(), en: descEn.trim()),
      inclusions: inclusions,
      notes: p?.notes,
      components: p?.components,
      active: active,
      rules: rules,
    );
  }
}
