// The Grow flow's pure helpers (web `grow/_components/model.ts`; voucher model, ADR 0033): the rates of a package on a date, the example quote behind
// the live preview (standard against voucher, integer fils), the overlap check (only the best voucher price applies) and the draft of a window.
// No strings here: words come from the l10n layer, numbers from the formatter.
import 'package:ghazal_domain/ghazal_domain.dart';

/// The example booking behind every preview: 350 guests.
const int kGuests = 350;
const int kFallbackFee = 2000;
const String kStandingId = 'standing';
const List<int> kWeekdays = <int>[0, 1, 2, 3];

enum GrowTab { active, scheduled, ended }

GrowTab tabOf(VoucherWindow w) => switch (w.status) {
  VoucherWindowStatus.scheduled => GrowTab.scheduled,
  VoucherWindowStatus.ended => GrowTab.ended,
  _ => GrowTab.active,
};

/// Standard and standing voucher rate of a package in its own unit (per guest or flat).
class Rates {
  const Rates(this.standard, this.voucher, this.flat);
  final int standard;
  final int? voucher;
  final bool flat;
}

/// Packages that carry a voucher price: the only ones a window can lower further.
List<Package> voucherPackages(PackageCatalog c) => [
  for (final e in c.packages)
    if (e.package.active && e.package.voucherFils != null) e.package,
];

Rates ratesOn(PackageEditor e, LocalDate date, List<int> weekendDays) {
  final flat = e.package.priceUnit == WirePriceUnit.flat;
  final wanted = weekendDays.contains(date.weekdayIndex) ? PriceTier.weekend : PriceTier.weekday;
  final rule =
      e.rules.where((r) => r.tier == wanted).firstOrNull ??
      e.rules.where((r) => r.tier == PriceTier.weekday || r.tier == PriceTier.weekend).firstOrNull;
  final std = (flat ? rule?.flat?.fils : rule?.perGuest?.fils) ?? e.package.standardFils;
  final vch = (flat ? rule?.voucherFlat?.fils : rule?.voucherPerGuest?.fils) ?? e.package.voucherFils;
  return Rates(std, vch, flat);
}

/// The rate a window sets, in the unit of its packages.
int windowRate(VoucherWindow w) => w.voucherPerGuest?.fils ?? w.voucherFlat?.fils ?? 0;

PackageEditor? editorOf(PackageCatalog c, String? id) => c.packages.where((e) => e.package.id == id).firstOrNull;

/// A representative event date of a window (for the standard price it is compared with).
LocalDate sampleDate(VoucherWindow w, LocalDate today) {
  final dates = w.eventDates;
  if (dates != null && dates.isNotEmpty) return dates.first;
  final from = w.eventFrom != null && w.eventFrom!.isAfter(today) ? w.eventFrom! : today;
  final to = w.eventTo ?? from.addDays(60);
  final days = w.eventWeekdays;
  for (var d = from; !d.isAfter(to); d = d.addDays(1)) {
    if (days == null || days.contains(d.weekdayIndex)) return d;
  }
  return from;
}

/// The standard rate of the first package of a window on its sample date: what the window's price is set against.
({int standard, bool flat, LocalDate date}) standardOf(VoucherWindow w, PackageCatalog c, LocalDate today, List<int> weekendDays) {
  final id = w.packageIds.isNotEmpty ? w.packageIds.first : voucherPackages(c).firstOrNull?.id;
  final date = sampleDate(w, today);
  final e = editorOf(c, id);
  if (e == null) return (standard: 0, flat: false, date: date);
  final r = ratesOn(e, date, weekendDays);
  return (standard: r.standard, flat: r.flat, date: date);
}

/// The example quote behind the preview: one package, one date, 350 guests, totals in integer fils.
({int standard, int voucher, int standing, int saving, bool flat, LocalDate date, int guests, String packageId}) exampleQuote(
  PackageCatalog c,
  List<String> packageIds,
  List<String> dates,
  int voucherRate,
  LocalDate fallbackDate,
  List<int> weekendDays,
) {
  final pool = voucherPackages(c);
  final id = packageIds.isNotEmpty ? packageIds.first : (pool.firstOrNull?.id ?? '');
  final date = dates.isNotEmpty ? LocalDate.parse(dates.first) : fallbackDate;
  final e = editorOf(c, id);
  final r = e == null ? const Rates(0, null, false) : ratesOn(e, date, weekendDays);
  final mult = r.flat ? 1 : kGuests;
  final standard = r.standard * mult;
  final voucher = (voucherRate * mult) < standard ? voucherRate * mult : standard;
  final standing = (r.voucher ?? r.standard) * mult;
  return (
    standard: standard,
    voucher: voucher,
    standing: standing,
    saving: standard - voucher > 0 ? standard - voucher : 0,
    flat: r.flat,
    date: date,
    guests: kGuests,
    packageId: id,
  );
}

// ---------------------------------------------------------------- the draft of a new window

enum Shortcut { openWeekends, weekdays }

class GrowDraft {
  const GrowDraft({
    this.packageIds = const [],
    this.hallIds = const [],
    this.voucherKd = '',
    this.titleEn = '',
    this.titleAr = '',
    this.titleTouched = false,
    this.eventDates = const [],
    this.shortcut,
    this.startsOn,
    this.endsOn,
    this.untilEnd = true,
    this.prefilled = false,
    this.dirty = false,
  });

  /// Empty = every package that has a voucher price.
  final List<String> packageIds;
  final List<String> hallIds;

  /// What was typed: dinars with up to three decimals, digits and one dot only.
  final String voucherKd;
  final String titleEn;
  final String titleAr;
  final bool titleTouched;
  final List<String> eventDates;
  final Shortcut? shortcut;
  final String? startsOn;
  final String? endsOn;
  final bool untilEnd;
  final bool prefilled;
  final bool dirty;

  GrowDraft copyWith({
    List<String>? packageIds,
    List<String>? hallIds,
    String? voucherKd,
    String? titleEn,
    String? titleAr,
    bool? titleTouched,
    List<String>? eventDates,
    Object? shortcut = _keep,
    Object? startsOn = _keep,
    Object? endsOn = _keep,
    bool? untilEnd,
    bool? prefilled,
    bool? dirty,
  }) => GrowDraft(
    packageIds: packageIds ?? this.packageIds,
    hallIds: hallIds ?? this.hallIds,
    voucherKd: voucherKd ?? this.voucherKd,
    titleEn: titleEn ?? this.titleEn,
    titleAr: titleAr ?? this.titleAr,
    titleTouched: titleTouched ?? this.titleTouched,
    eventDates: eventDates ?? this.eventDates,
    shortcut: identical(shortcut, _keep) ? this.shortcut : shortcut as Shortcut?,
    startsOn: identical(startsOn, _keep) ? this.startsOn : startsOn as String?,
    endsOn: identical(endsOn, _keep) ? this.endsOn : endsOn as String?,
    untilEnd: untilEnd ?? this.untilEnd,
    prefilled: prefilled ?? this.prefilled,
    dirty: dirty ?? this.dirty,
  );
}

const Object _keep = Object();

String kdOf(int fils) {
  final s = (fils / 1000).toString();
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

/// The typed price in fils (0 when empty or unreadable).
int draftFils(GrowDraft d) {
  final n = double.tryParse(d.voucherKd);
  return n == null ? 0 : (n * 1000).round();
}

/// Keep digits and one dot, at most three decimals, at most five integer digits.
String cleanKd(String raw) {
  final s = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  final parts = s.split('.');
  final intPart = parts.first;
  final rest = parts.skip(1).join();
  final frac = rest.length > 3 ? rest.substring(0, 3) : rest;
  var head = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (head.length > 5) head = head.substring(0, 5);
  return parts.length > 1 ? '${head.isEmpty ? '0' : head}.$frac' : head;
}

/// The packages a draft covers (all voucher packages when none is picked).
List<String> coveredPackages(PackageCatalog c, GrowDraft d) => d.packageIds.isNotEmpty ? d.packageIds : [for (final p in voucherPackages(c)) p.id];

/// The lowest standard and standing voucher rate across the covered packages on the example date: the bounds of the typed price.
({int standard, int standing, bool flat}) bounds(PackageCatalog c, GrowDraft d, LocalDate fallback, List<int> weekendDays) {
  final date = d.eventDates.isNotEmpty ? LocalDate.parse(d.eventDates.first) : fallback;
  final rates = [
    for (final id in coveredPackages(c, d))
      if (editorOf(c, id) != null) ratesOn(editorOf(c, id)!, date, weekendDays),
  ];
  if (rates.isEmpty) return (standard: 0, standing: 0, flat: false);
  int least(Iterable<int> xs) => xs.reduce((a, b) => a < b ? a : b);
  return (standard: least(rates.map((r) => r.standard)), standing: least(rates.map((r) => r.voucher ?? r.standard)), flat: rates.first.flat);
}

enum PriceProblem { empty, over }

PriceProblem? priceProblem(PackageCatalog c, GrowDraft d, LocalDate fallback, List<int> weekendDays) {
  final fils = draftFils(d);
  if (d.voucherKd.isEmpty || fils <= 0) return PriceProblem.empty;
  return fils > bounds(c, d, fallback, weekendDays).standard ? PriceProblem.over : null;
}

enum PriceWarning { noEffect, belowFee }

/// Soft warnings that do not block: the price is not below the standing voucher price, or the saving is not above the voucher fee.
PriceWarning? priceWarning(PackageCatalog c, GrowDraft d, LocalDate fallback, List<int> weekendDays, int fee) {
  if (priceProblem(c, d, fallback, weekendDays) != null) return null;
  final b = bounds(c, d, fallback, weekendDays);
  final fils = draftFils(d);
  final mins = [for (final id in coveredPackages(c, d)) editorOf(c, id)?.package.minGuests ?? kGuests];
  final smallest = mins.isEmpty ? kGuests : mins.reduce((a, b) => a < b ? a : b);
  final mult = b.flat ? 1 : (smallest < 1 ? 1 : smallest);
  if (fils >= b.standing) return PriceWarning.noEffect;
  if ((b.standard - fils) * mult <= fee) return PriceWarning.belowFee;
  return null;
}

/// A fresh draft: the first voucher package at its standing price (the default of the editor).
GrowDraft emptyDraftFor(PackageCatalog c) {
  final p = voucherPackages(c).where((x) => x.id == 'V01-ladies-weekday').firstOrNull ?? voucherPackages(c).firstOrNull;
  return GrowDraft(packageIds: p == null ? const [] : [p.id], voucherKd: kdOf(p?.voucherFils ?? 0));
}

/// The editor draft a Duplicate starts from: same packages, price and titles; no dates, nothing carried over from usage.
GrowDraft draftFromWindow(VoucherWindow w) =>
    GrowDraft(packageIds: w.packageIds, voucherKd: kdOf(windowRate(w)), titleEn: w.title.en ?? '', titleAr: w.title.ar ?? '', titleTouched: true);

/// Builds the body of the write from a finished draft.
VoucherWindowInput inputOf(GrowDraft d, PackageCatalog c, LocalDate today, DateTime now, LocalizedText title, bool flat) {
  final rate = MoneyAmount(draftFils(d));
  final start = d.startsOn != null && LocalDate.parse(d.startsOn!).isAfter(today) ? DateTime.parse('${d.startsOn}T00:00:00+03:00') : now;
  final end = !d.untilEnd && d.endsOn != null ? DateTime.parse('${d.endsOn}T23:59:00+03:00') : null;
  final weekdays = d.shortcut == Shortcut.weekdays;
  final sorted = [...d.eventDates]..sort();
  return VoucherWindowInput(
    title: title,
    packageIds: coveredPackages(c, d),
    voucherPerGuest: flat ? null : rate,
    voucherFlat: flat ? rate : null,
    eventFrom: weekdays ? today : null,
    eventTo: weekdays ? today.addDays(60) : null,
    eventDates: weekdays ? null : [for (final s in sorted) LocalDate.parse(s)],
    eventWeekdays: weekdays ? kWeekdays : null,
    startsAt: start,
    endsAt: end,
  );
}

// ---------------------------------------------------------------- overlap: only the best voucher price applies

bool windowCoversDate(VoucherWindow w, LocalDate date, String packageId) {
  if (w.status == VoucherWindowStatus.ended) return false;
  if (w.packageIds.isNotEmpty && !w.packageIds.contains(packageId)) return false;
  if (w.eventDates != null && !w.eventDates!.any((d) => d.compareTo(date) == 0)) return false;
  if (w.eventFrom != null && date.isBefore(w.eventFrom!)) return false;
  if (w.eventTo != null && date.isAfter(w.eventTo!)) return false;
  if (w.eventWeekdays != null && !w.eventWeekdays!.contains(date.weekdayIndex)) return false;
  return true;
}

/// Existing windows that already give a better (lower or equal) voucher price on some of the chosen dates: only the best one applies.
List<({VoucherWindow window, List<String> dates})> overlaps(List<VoucherWindow> windows, PackageCatalog c, GrowDraft d, int fils) {
  final out = <({VoucherWindow window, List<String> dates})>[];
  final pkgs = coveredPackages(c, d);
  for (final w in windows) {
    if (w.status == VoucherWindowStatus.ended || windowRate(w) > fils) continue;
    final hit = [
      for (final s in d.eventDates)
        if (pkgs.any((p) => windowCoversDate(w, LocalDate.parse(s), p))) s,
    ];
    if (hit.isNotEmpty) out.add((window: w, dates: hit));
  }
  return out;
}

/// Per-window performance for the actions sheet: the fixtures count vouchers bought per window only; requests and confirmed are derived so the
/// chain always holds (vouchers >= requests >= confirmed). Filed in docs/engineering/requests.md for a real field.
({int vouchers, int requests, int confirmed}) windowPerformance(VoucherWindow w) {
  final v = w.vouchersBought ?? 0;
  final requests = (v * 0.75).round();
  return (vouchers: v, requests: requests, confirmed: (requests * 0.4).round());
}
