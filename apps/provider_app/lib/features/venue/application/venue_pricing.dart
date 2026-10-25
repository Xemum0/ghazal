// The two price columns of a package tier (ADR 0033, voucher-model section 6): standard and voucher, on the same basis, integer fils. Mirrors the
// engine's rule (web `pricing.ts`): a voucher column empty on a field falls back to the standard value of that field, and a voucher is offered to
// clients only when the saving on the quote beats the voucher fee.
import 'package:ghazal_domain/ghazal_domain.dart';

/// One set of days of a package: the standard column and the voucher column (both empty = no voucher price).
class TierDraft {
  TierDraft({this.on = false, this.perGuest, this.flat, this.vPerGuest, this.vFlat, this.source});

  factory TierDraft.of(PackageEditor pkg, PriceTier tier) {
    final r = pkg.rules.where((x) => x.tier == tier).firstOrNull;
    if (r == null) return TierDraft();
    return TierDraft(on: true, perGuest: r.perGuest?.fils, flat: r.flat?.fils, vPerGuest: r.voucherPerGuest?.fils, vFlat: r.voucherFlat?.fils, source: r);
  }

  bool on;
  int? perGuest;
  int? flat;
  int? vPerGuest;
  int? vFlat;
  final PriceRule? source;

  TierDraft copy() => TierDraft(on: on, perGuest: perGuest, flat: flat, vPerGuest: vPerGuest, vFlat: vFlat, source: source);

  bool get hasVoucher => vFlat != null || vPerGuest != null;

  String get signature => '$on:$perGuest:$flat:$vPerGuest:$vFlat';

  /// The tier as one column reads it (the voucher column falls back field by field to the standard value).
  TierDraft column(bool voucher) => voucher ? TierDraft(on: on, perGuest: vPerGuest ?? perGuest, flat: vFlat ?? flat) : this;

  bool sameAs(TierDraft o) => on == o.on && perGuest == o.perGuest && flat == o.flat && vPerGuest == o.vPerGuest && vFlat == o.vFlat;
}

bool needsFlat(PricingBasis b) => b == PricingBasis.flat || b == PricingBasis.flatPlusPerGuest;
bool needsGuest(PricingBasis b) => b == PricingBasis.perGuest || b == PricingBasis.flatPlusPerGuest;

int? standardTotal(PricingBasis b, TierDraft t, int guests) {
  if (b == PricingBasis.perGuest) return t.perGuest == null ? null : t.perGuest! * guests;
  if (b == PricingBasis.flat) return t.flat;
  if (t.flat == null || t.perGuest == null) return null;
  return t.flat! + t.perGuest! * guests;
}

int? voucherTotal(PricingBasis b, TierDraft t, int guests) => t.hasVoucher ? standardTotal(b, t.column(true), guests) : null;

({bool flat, bool guest}) voucherAbove(TierDraft t) => (
  flat: t.vFlat != null && t.flat != null && t.vFlat! > t.flat!,
  guest: t.vPerGuest != null && t.perGuest != null && t.vPerGuest! > t.perGuest!,
);

enum VoucherState { none, higher, belowFee, ok }

({VoucherState state, int saving}) voucherState(PricingBasis b, TierDraft t, int guests, int feeFils) {
  if (!t.hasVoucher) return (state: VoucherState.none, saving: 0);
  final above = voucherAbove(t);
  if (above.flat || above.guest) return (state: VoucherState.higher, saving: 0);
  final std = standardTotal(b, t, guests);
  final vch = voucherTotal(b, t, guests);
  if (std == null || vch == null) return (state: VoucherState.none, saving: 0);
  final saving = std - vch;
  return (state: saving > feeFils ? VoucherState.ok : VoucherState.belowFee, saving: saving);
}

PriceStructure structureOf(PricingBasis b) => b == PricingBasis.perGuest ? PriceStructure.perPerson : PriceStructure.package;

/// Names a venue package may never take: the planner tiers. Compared without case.
bool isReservedName(String text) {
  final t = text.trim().toLowerCase();
  return t.isNotEmpty && const ['silver', 'gold', 'royal', 'الفضية', 'الذهبية', 'الملكية'].contains(t);
}

const List<int> kWeekdayTierDays = <int>[0, 1, 2, 3];
const List<int> kWeekendTierDays = <int>[4, 5, 6];

PriceRuleInput ruleInputOf(PriceRule r) => PriceRuleInput(
  id: r.id,
  tier: r.tier,
  weekdays: r.weekdays,
  validFrom: r.validFrom,
  validTo: r.validTo,
  specialDate: r.specialDate,
  priority: r.priority,
  flat: r.flat,
  perGuest: r.perGuest,
  voucherFlat: r.voucherFlat,
  voucherPerGuest: r.voucherPerGuest,
  label: r.label,
);

/// The rules of a package after an edit of its weekday and weekend tiers: every other rule is kept as it was.
List<PriceRuleInput> rulesAfterEdit(PackageEditor? pkg, TierDraft weekday, TierDraft weekend, PricingBasis basis) {
  final out = <PriceRuleInput>[for (final r in pkg?.rules ?? const <PriceRule>[]) if (r.tier != PriceTier.weekday && r.tier != PriceTier.weekend) ruleInputOf(r)];
  PriceRuleInput one(PriceTier tier, TierDraft t, List<int> days) => PriceRuleInput(
    id: t.source?.id,
    tier: tier,
    weekdays: t.source?.weekdays ?? days,
    validFrom: t.source?.validFrom,
    validTo: t.source?.validTo,
    specialDate: t.source?.specialDate,
    priority: t.source?.priority ?? 0,
    flat: needsFlat(basis) && t.flat != null ? MoneyAmount(t.flat!) : null,
    perGuest: needsGuest(basis) && t.perGuest != null ? MoneyAmount(t.perGuest!) : null,
    voucherFlat: needsFlat(basis) && t.vFlat != null ? MoneyAmount(t.vFlat!) : null,
    voucherPerGuest: needsGuest(basis) && t.vPerGuest != null ? MoneyAmount(t.vPerGuest!) : null,
    label: t.source?.label,
  );
  if (weekday.on) out.add(one(PriceTier.weekday, weekday, kWeekdayTierDays));
  if (weekend.on) out.add(one(PriceTier.weekend, weekend, kWeekendTierDays));
  return out;
}
