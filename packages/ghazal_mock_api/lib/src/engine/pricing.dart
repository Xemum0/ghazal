/// ADR 0004 pricing engine extended by ADR 0033 D4: the same steps run once per price column, standard and voucher.
/// Order: tier > billable guests > lines > service charge > totals > savings > voucher eligibility. Integer fils, half-up per line.
/// Port of engine/pricing.ts; inputs and outputs are the wire shape (maps), so the shared engine cases compare byte for byte.
library;

import 'dates.dart';
import 'json.dart';
import 'money.dart';

/// Tier precedence: first match wins, no stacking (ADR 0004 D2).
const tierRank = {'special_date': 60, 'holiday': 50, 'peak': 40, 'season': 30, 'weekend': 20, 'weekday': 10};

bool ruleMatches(Json rule, String date) {
  final from = rule.strOrNull('validFrom');
  final to = rule.strOrNull('validTo');
  if (from != null && date.compareTo(from) < 0) return false;
  if (to != null && date.compareTo(to) > 0) return false;
  if (rule['tier'] == 'special_date') return rule['specialDate'] == date;
  final wds = rule['weekdays'];
  if (wds is List && !wds.contains(weekdayOf(date))) return false;
  return true;
}

/// The winning price rule of a package or extra on a date, or null when the item is not sold that day.
Json? resolveRule(Iterable<Json> rules, String scopeId, String date) {
  Json? best;
  for (final r in rules) {
    if (r['scopeId'] != scopeId || !ruleMatches(r, date)) continue;
    if (best == null ||
        tierRank[r['tier']]! > tierRank[best['tier']]! ||
        (tierRank[r['tier']] == tierRank[best['tier']] && r.integer('priority') > best.integer('priority'))) {
      best = r;
    }
  }
  return best;
}

int effectiveMinGuests(Json pkg, int hallSectionMin) => pkg.integer('minGuests') > hallSectionMin ? pkg.integer('minGuests') : hallSectionMin;

({int billed, int complimentary, int billable}) billableGuests(int guests, int minGuests, int complimentaryBps) {
  final billed = guests > minGuests ? guests : minGuests;
  final complimentary = floorDiv(billed * complimentaryBps, 10000);
  return (billed: billed, complimentary: complimentary, billable: billed - complimentary);
}

// ---------------------------------------------------------------- voucher price windows

bool windowApplies(Json w, {required String eventDate, required String now, required String packageId}) {
  if (w['status'] == 'ended') return false;
  if (now.compareTo(w.str('startsAt')) < 0) return false;
  final ends = w.strOrNull('endsAt');
  if (ends != null && now.compareTo(ends) >= 0) return false;
  if (!w.strings('packageIds').contains(packageId)) return false;
  final dates = w['eventDates'];
  if (dates is List && !dates.contains(eventDate)) return false;
  final from = w.strOrNull('eventFrom');
  final to = w.strOrNull('eventTo');
  if (from != null && eventDate.compareTo(from) < 0) return false;
  if (to != null && eventDate.compareTo(to) > 0) return false;
  final wds = w['eventWeekdays'];
  if (wds is List && !wds.contains(weekdayOf(eventDate))) return false;
  return true;
}

/// The lowest matching window of a package on a date (one at a time, never stacked), or null.
Json? bestWindow(Iterable<Json> windows, {required String eventDate, required String now, required String packageId}) {
  Json? best;
  int score(Json w) => filsOf(w.objOrNull('voucherPerGuest')) + filsOf(w.objOrNull('voucherFlat'));
  for (final w in windows) {
    if (!windowApplies(w, eventDate: eventDate, now: now, packageId: packageId)) continue;
    if (best == null || score(w) < score(best)) best = w;
  }
  return best;
}

/// The two columns of one rule on a date: the standard amounts and the voucher amounts (window rate when lower).
typedef RuleColumns = ({Json? flat, Json? perGuest, Json? voucherFlat, Json? voucherPerGuest, bool hasVoucher, String? windowId});

RuleColumns columnsOf(Json rule, Iterable<Json> windows, {required String eventDate, required String now, required String packageId}) {
  var vFlat = rule.objOrNull('voucherFlat');
  var vPer = rule.objOrNull('voucherPerGuest');
  String? windowId;
  final w = bestWindow(windows, eventDate: eventDate, now: now, packageId: packageId);
  if (w != null) {
    final wf = w.objOrNull('voucherFlat');
    final wp = w.objOrNull('voucherPerGuest');
    final lowerFlat = wf != null && (vFlat == null || filsOf(wf) < filsOf(vFlat));
    final lowerPer = wp != null && (vPer == null || filsOf(wp) < filsOf(vPer));
    if (lowerFlat) vFlat = wf;
    if (lowerPer) vPer = wp;
    if (lowerFlat || lowerPer) windowId = w.str('id');
  }
  return (
    flat: rule.objOrNull('flat'),
    perGuest: rule.objOrNull('perGuest'),
    voucherFlat: vFlat,
    voucherPerGuest: vPer,
    hasVoucher: vFlat != null || vPer != null,
    windowId: windowId,
  );
}

// ---------------------------------------------------------------- quote

const _labelHallFee = {'en': 'Hall fee', 'ar': 'إيجار القاعة'};
const _labelVenueDiscount = {'en': 'Venue discount', 'ar': 'خصم من القاعة'};
const _labelServiceCharge = {'en': 'Service charge', 'ar': 'رسوم الخدمة'};

class _Dual {
  _Dual({
    required this.kind,
    required this.section,
    required this.name,
    required this.qty,
    required this.stdUnit,
    required this.stdAmount,
    required this.vchUnit,
    required this.vchAmount,
    this.ruleId,
  });
  final String kind;
  final int? section;
  final Json name;
  final int qty;
  final Json? stdUnit, vchUnit;
  final Json stdAmount, vchAmount;
  final String? ruleId;
}

/// One venue quote. [sections] items: `{hallId, audience, guests, package (Json), hallMinGuests}`; [extras] items: `{extra (Json), qty}`.
/// Throws [StateError] when a package is not sold on the date (the handler checks availability first).
Json quote({
  required String venueId,
  required String eventDate,
  required String now,
  required List<Json> sections,
  required List<Json> rules,
  required List<Json> extras,
  List<Json> voucherWindows = const [],
  Json? venueDiscount,
  required int serviceChargeBps,
  required int voucherFeeFils,
}) {
  final dual = <_Dual>[];
  var firstSectionBillable = 0;
  for (var idx = 0; idx < sections.length; idx++) {
    final s = sections[idx];
    final pkg = s.obj('package');
    final section = idx + 1;
    final rule = resolveRule(rules, pkg.str('id'), eventDate);
    if (rule == null) throw StateError('Package ${pkg['id']} is not sold on $eventDate');
    final cols = columnsOf(rule, voucherWindows, eventDate: eventDate, now: now, packageId: pkg.str('id'));
    final min = effectiveMinGuests(pkg, s.integer('hallMinGuests'));
    final g = billableGuests(s.integer('guests'), min, pkg.integer('complimentaryBps'));
    if (idx == 0) firstSectionBillable = g.billable;
    final basis = pkg.str('pricingBasis');
    if ((basis == 'flat' || basis == 'flat_plus_per_guest') && cols.flat != null) {
      final vFlat = cols.voucherFlat ?? cols.flat!;
      dual.add(
        _Dual(
          kind: 'package',
          section: section,
          name: basis == 'flat' ? pkg.obj('name') : _labelHallFee,
          qty: 1,
          stdUnit: cols.flat,
          stdAmount: cols.flat!,
          vchUnit: vFlat,
          vchAmount: vFlat,
          ruleId: rule.str('id'),
        ),
      );
    }
    if ((basis == 'per_guest' || basis == 'flat_plus_per_guest') && cols.perGuest != null) {
      final vPer = cols.voucherPerGuest ?? cols.perGuest!;
      dual.add(
        _Dual(
          kind: basis == 'per_guest' ? 'package' : 'menu',
          section: section,
          name: pkg.obj('name'),
          qty: g.billable,
          stdUnit: cols.perGuest,
          stdAmount: mulMoney(cols.perGuest!, g.billable),
          vchUnit: vPer,
          vchAmount: mulMoney(vPer, g.billable),
          ruleId: rule.str('id'),
        ),
      );
    }
  }
  for (final e in extras) {
    final extra = e.obj('extra');
    final rule = resolveRule(rules, extra.str('id'), eventDate);
    final unit = rule?.objOrNull('flat') ?? rule?.objOrNull('perGuest') ?? extra.obj('price');
    final q = extra['pricingUnit'] == 'per_guest' ? firstSectionBillable : e.integer('qty');
    final vUnit = rule?.objOrNull('voucherFlat') ?? rule?.objOrNull('voucherPerGuest') ?? unit;
    dual.add(
      _Dual(
        kind: 'extra',
        section: null,
        name: extra.obj('name'),
        qty: q,
        stdUnit: unit,
        stdAmount: mulMoney(unit, q),
        vchUnit: vUnit,
        vchAmount: mulMoney(vUnit, q),
        ruleId: rule?.str('id'),
      ),
    );
  }

  final standardSubtotal = addMoney(dual.map((l) => l.stdAmount));
  final voucherSubtotal = addMoney(dual.map((l) => l.vchAmount));
  final requested = venueDiscount ?? zero();
  final discount = filsOf(requested) > filsOf(voucherSubtotal) ? voucherSubtotal : requested;
  final afterDiscount = subMoney(voucherSubtotal, discount);
  final standardServiceCharge = serviceChargeBps > 0 ? shareMoney(standardSubtotal, serviceChargeBps) : zero();
  final voucherServiceCharge = serviceChargeBps > 0 ? shareMoney(afterDiscount, serviceChargeBps) : zero();
  final standardTotal = addMoney([standardSubtotal, standardServiceCharge]);
  final voucherTotal = addMoney([afterDiscount, voucherServiceCharge]);
  final rawSavings = filsOf(standardTotal) - filsOf(voucherTotal);
  final savings = fils(rawSavings > 0 ? rawSavings : 0);
  final voucherFee = fils(voucherFeeFils);
  final voucherEligible = filsOf(savings) > filsOf(voucherFee);

  final lines = <Json>[
    for (final l in dual)
      {
        'kind': l.kind,
        'section': l.section,
        'name': l.name,
        'qty': l.qty,
        'unit': voucherEligible ? l.vchUnit : l.stdUnit,
        'amount': voucherEligible ? l.vchAmount : l.stdAmount,
        'standardUnit': l.stdUnit,
        'standardAmount': l.stdAmount,
        if (l.ruleId != null) 'ruleId': l.ruleId,
      },
  ];
  if (voucherEligible && filsOf(discount) > 0) {
    lines.add({
      'kind': 'venue_discount',
      'section': null,
      'name': _labelVenueDiscount,
      'qty': 1,
      'unit': null,
      'amount': negMoney(discount),
      'standardUnit': null,
      'standardAmount': zero(),
    });
  }
  final appliedSc = voucherEligible ? voucherServiceCharge : standardServiceCharge;
  if (filsOf(appliedSc) > 0 || filsOf(standardServiceCharge) > 0) {
    lines.add({
      'kind': 'service_charge',
      'section': null,
      'name': _labelServiceCharge,
      'qty': 1,
      'unit': null,
      'amount': appliedSc,
      'standardUnit': null,
      'standardAmount': standardServiceCharge,
    });
  }
  final totals = <String, dynamic>{
    'standardSubtotal': standardSubtotal,
    'standardServiceCharge': standardServiceCharge,
    'standardTotal': standardTotal,
    'voucherSubtotal': voucherSubtotal,
    'venueDiscount': discount,
    'voucherServiceCharge': voucherServiceCharge,
    'voucherTotal': voucherTotal,
    'savings': savings,
    'voucherFee': voucherFee,
    'netSavings': filsOf(savings) - filsOf(voucherFee),
  };
  return {'venueId': venueId, 'eventDate': eventDate, 'lines': lines, 'totals': totals, 'voucherEligible': voucherEligible};
}

// ---------------------------------------------------------------- single-package price (cards, calendar, compare)

/// All-in price of one package on a date for the guests (null when the package is not sold that day). Keys: `standard`, `voucher`, `savings`,
/// `voucherEligible`, `perGuest`, `flat`, `voucherPerGuest`, `voucherFlat`, `billable`, `billed`, `tier`, `ruleId`, `windowId`.
Json? packagePrice({
  required Json pkg,
  required List<Json> rules,
  List<Json> windows = const [],
  required String eventDate,
  required String now,
  required String hallId,
  required int guests,
  required int hallMinGuests,
  required int serviceChargeBps,
  required int voucherFeeFils,
}) {
  final rule = resolveRule(rules, pkg.str('id'), eventDate);
  if (rule == null) return null;
  final cols = columnsOf(rule, windows, eventDate: eventDate, now: now, packageId: pkg.str('id'));
  final min = effectiveMinGuests(pkg, hallMinGuests);
  final g = billableGuests(guests, min, pkg.integer('complimentaryBps'));
  final basis = pkg.str('pricingBasis');
  final hasFlat = basis == 'flat' || basis == 'flat_plus_per_guest';
  final hasPer = basis == 'per_guest' || basis == 'flat_plus_per_guest';
  Json total(Json? flat, Json? per) {
    final base = addMoney([hasFlat && flat != null ? flat : zero(), hasPer && per != null ? mulMoney(per, g.billable) : zero()]);
    return serviceChargeBps > 0 ? addMoney([base, shareMoney(base, serviceChargeBps)]) : base;
  }

  final standard = total(cols.flat, cols.perGuest);
  final voucher = cols.hasVoucher ? total(cols.voucherFlat ?? cols.flat, cols.voucherPerGuest ?? cols.perGuest) : null;
  final savings = voucher != null ? fils(filsOf(standard) - filsOf(voucher) > 0 ? filsOf(standard) - filsOf(voucher) : 0) : null;
  return {
    'standard': standard,
    'voucher': voucher,
    'savings': savings,
    'voucherEligible': savings != null && filsOf(savings) > voucherFeeFils,
    'perGuest': cols.perGuest,
    'flat': cols.flat,
    'voucherPerGuest': cols.voucherPerGuest,
    'voucherFlat': cols.voucherFlat,
    'billable': g.billable,
    'billed': g.billed,
    'tier': rule['tier'],
    'ruleId': rule['id'],
    'windowId': cols.windowId,
  };
}

/// Days from a date to an event, for the urgent rule (event within 14 days: 4 h reply window).
int leadDays(String now, String eventDate) => diffDays(kuwaitDateOf(now), eventDate);

// ---------------------------------------------------------------- a service provider's package (no halls, no calendar claim)

/// Quote one provider package: quantity times the unit price in both columns. Same totals shape and the same eligibility test as a venue quote.
Json quoteProviderPackage({required String providerId, required Json pkg, required int qty, Json? venueDiscount, required int voucherFeeFils}) {
  final price = pkg.obj('price');
  final standardAmount = mulMoney(price, qty);
  final voucherUnit = pkg.objOrNull('voucherPrice') ?? price;
  final voucherAmount = mulMoney(voucherUnit, qty);
  final requested = venueDiscount ?? zero();
  final discount = filsOf(requested) > filsOf(voucherAmount) ? voucherAmount : requested;
  final voucherTotal = subMoney(voucherAmount, discount);
  final rawSavings = filsOf(standardAmount) - filsOf(voucherTotal);
  final savings = fils(rawSavings > 0 ? rawSavings : 0);
  final voucherFee = fils(voucherFeeFils);
  final eligible = filsOf(savings) > filsOf(voucherFee);
  final lines = <Json>[
    {
      'kind': 'package',
      'section': null,
      'name': pkg.obj('name'),
      'qty': qty,
      'unit': eligible ? voucherUnit : price,
      'amount': eligible ? voucherAmount : standardAmount,
      'standardUnit': price,
      'standardAmount': standardAmount,
      'ruleId': pkg.str('id'),
    },
  ];
  if (eligible && filsOf(discount) > 0) {
    lines.add({
      'kind': 'venue_discount',
      'section': null,
      'name': {'en': 'Provider discount', 'ar': 'خصم من المزوّد'},
      'qty': 1,
      'unit': null,
      'amount': negMoney(discount),
      'standardUnit': null,
      'standardAmount': zero(),
    });
  }
  final totals = <String, dynamic>{
    'standardSubtotal': standardAmount,
    'standardServiceCharge': zero(),
    'standardTotal': standardAmount,
    'voucherSubtotal': voucherAmount,
    'venueDiscount': discount,
    'voucherServiceCharge': zero(),
    'voucherTotal': voucherTotal,
    'savings': savings,
    'voucherFee': voucherFee,
    'netSavings': filsOf(savings) - filsOf(voucherFee),
  };
  return {'venueId': providerId, 'eventDate': '', 'lines': lines, 'totals': totals, 'voucherEligible': eligible};
}
