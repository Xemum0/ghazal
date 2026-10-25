import 'package:flutter/foundation.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// What the venue page is priced for: the venue, the hall and package the person picked on the page, and the Brief (date, guests,
/// audience). Value equality makes it a provider family key.
@immutable
final class VenueKey {
  const VenueKey({required this.venueId, this.hallId, this.packageId, this.date, this.guests, this.audience});

  final String venueId;
  final String? hallId;
  final String? packageId;
  final LocalDate? date;
  final int? guests;
  final Audience? audience;

  @override
  bool operator ==(Object other) =>
      other is VenueKey &&
      other.venueId == venueId &&
      other.hallId == hallId &&
      other.packageId == packageId &&
      other.date == date &&
      other.guests == guests &&
      other.audience == audience;

  @override
  int get hashCode => Object.hash(venueId, hallId, packageId, date, guests, audience);
}

/// What the couple is told about a day (ADR 0002 D8: a closed day and an unavailable one read the same, with no reason).
enum DayStatusKind { none, available, held, unavailable }

/// One priced package of the hall (web `PackageRow`).
@immutable
final class PackageRow {
  const PackageRow({required this.offer, required this.audience, required this.minGuests, required this.belowMinimum, required this.lowestRate});

  final PackageOffer offer;
  final Audience audience;
  final int minGuests;
  final bool belowMinimum;

  /// No date yet: the price is the package's lowest rate, not a quote for a day.
  final bool lowestRate;

  Package get pkg => offer.package;
  PackageBriefPrice? get price => offer.forBrief;
}

/// The two prices of one quote as the page shows them (voucher-model section 6). `eligible` false = the page says nothing about vouchers.
@immutable
final class QuotePrices {
  const QuotePrices({required this.eligible, required this.standard, required this.voucher, required this.savings, required this.billedGuests});

  final bool eligible;
  final int standard;
  final int voucher;
  final int savings;
  final int billedGuests;
}

/// Everything CL-VENU-01 and its sheets show for one venue, one Brief and one pick.
@immutable
final class VenueView {
  const VenueView({
    required this.detail,
    required this.halls,
    required this.hall,
    required this.audience,
    required this.status,
    required this.day,
    required this.rows,
    required this.row,
    required this.quote,
    required this.prices,
    required this.windowTitle,
    required this.owned,
    required this.visitOpen,
    required this.nearest,
    required this.feeFils,
    required this.config,
    required this.areaName,
    required this.governorateName,
    required this.origin,
  });

  final VenueDetail detail;
  final List<Hall> halls;
  final Hall hall;
  final Audience audience;
  final DayStatusKind status;
  final AvailabilityDay? day;
  final List<PackageRow> rows;
  final PackageRow? row;
  final Quote? quote;
  final QuotePrices? prices;
  final LocalizedText? windowTitle;
  final Voucher? owned;
  final bool visitOpen;
  final List<LocalDate> nearest;
  final int feeFils;
  final PlatformConfig config;
  final LocalizedText? areaName;
  final LocalizedText? governorateName;
  final ReferencePoint? origin;

  Venue get venue => detail.venue;
}

// ---------------------------------------------------------------- pure helpers (web model.ts)

HallSection? sectionOf(Hall hall, Audience audience) {
  for (final s in hall.sections) {
    if (s.audience == audience) return s;
  }
  return null;
}

/// Halls that can host this audience and these guests; if none fit, the halls that host the audience; if none, all.
List<Hall> fittingHalls(Venue venue, Audience audience, int? guests) {
  final forAudience = venue.halls.where((h) => sectionOf(h, audience) != null).toList();
  final fits = forAudience.where((h) => guests == null || h.capacity.max >= guests).toList();
  if (fits.isNotEmpty) return fits;
  return forAudience.isNotEmpty ? forAudience : venue.halls;
}

/// The audience the page speaks about: the Brief's, else the first section audience of the venue (ladies first).
Audience audienceFor(Venue venue, Audience? briefAudience) {
  if (briefAudience != null && briefAudience != Audience.unknown) return briefAudience;
  final all = <Audience>[for (final h in venue.halls) for (final s in h.sections) s.audience];
  if (all.contains(Audience.women)) return Audience.women;
  return all.isEmpty ? Audience.women : all.first;
}

DayStatusKind statusOfDay(AvailabilityDay? day, LocalDate? date) {
  if (date == null || day == null) return DayStatusKind.none;
  return switch (day.state) {
    DayState.available => DayStatusKind.available,
    DayState.held => DayStatusKind.held,
    _ => DayStatusKind.unavailable,
  };
}

/// The total the visitor settles with the venue under each column for a row: the voucher total when it is offered, else the standard.
int rowTotal(PackageRow r) {
  final p = r.price;
  if (p == null) return r.pkg.standardFils;
  return p.voucherOffered && p.voucher != null ? p.voucher!.fils : p.standard.fils;
}

/// The package a visitor lands on: the cheapest all-in package sold for the Brief audience. A hall-only package never headlines
/// against all-in ones (ADR 0004 D6).
PackageRow? defaultPackage(List<PackageRow> rows, Audience audience) {
  if (rows.isEmpty) return null;
  final same = rows.where((r) => r.audience == audience).toList();
  final pool = same.isNotEmpty ? same : rows;
  final allIn = pool.where((r) => r.pkg.archetype != PackageArchetype.hallOnly).toList();
  final use = allIn.isNotEmpty ? allIn : pool;
  final sorted = [...use]..sort((a, b) {
      final t = rowTotal(a).compareTo(rowTotal(b));
      return t != 0 ? t : (a.pkg.sortOrder ?? 0).compareTo(b.pkg.sortOrder ?? 0);
    });
  return sorted.first;
}

int effectiveMinGuests(Package pkg, int hallSectionMin) => pkg.minGuests > hallSectionMin ? pkg.minGuests : hallSectionMin;

/// Civil days between two dates (b minus a).
int diffDays(LocalDate a, LocalDate b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// The lowest matching voucher window of a package on a date (one at a time, never stacked), as the engine decides.
VoucherWindow? bestWindow(List<VoucherWindow> windows, {required LocalDate date, required DateTime now, required String packageId}) {
  bool applies(VoucherWindow w) {
    if (w.status == VoucherWindowStatus.ended) return false;
    if (now.isBefore(w.startsAt)) return false;
    if (w.endsAt != null && !now.isBefore(w.endsAt!)) return false;
    if (!w.packageIds.contains(packageId)) return false;
    final dates = w.eventDates;
    if (dates != null && !dates.contains(date)) return false;
    if (w.eventFrom != null && date.isBefore(w.eventFrom!)) return false;
    if (w.eventTo != null && date.isAfter(w.eventTo!)) return false;
    final wds = w.eventWeekdays;
    if (wds != null && !wds.contains(date.weekdayIndex)) return false;
    return true;
  }

  int score(VoucherWindow w) => (w.voucherPerGuest?.fils ?? 0) + (w.voucherFlat?.fils ?? 0);
  VoucherWindow? best;
  for (final w in windows) {
    if (!applies(w)) continue;
    if (best == null || score(w) < score(best)) best = w;
  }
  return best;
}

/// The three nearest free dates by distance in days from [date] (ADR 0002 D8: an unavailable date never says why).
List<LocalDate> nearestFree(List<AvailabilityDay> days, LocalDate date, {int limit = 3}) {
  final free = days.where((d) => d.state == DayState.available && d.date != date).toList()
    ..sort((a, b) {
      final c = diffDays(date, a.date).abs().compareTo(diffDays(date, b.date).abs());
      return c != 0 ? c : a.date.compareTo(b.date);
    });
  return <LocalDate>[for (final d in free.take(limit)) d.date]..sort();
}
