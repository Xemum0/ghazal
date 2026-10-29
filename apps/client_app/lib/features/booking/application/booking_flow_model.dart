import 'package:flutter/foundation.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// One package of the hall, priced for the date and guests by the server (a quote of that single package): both columns, the rate and
/// the guests billed. Never computed in a screen (ADR 0010).
@immutable
final class PricedPackage {
  const PricedPackage({required this.pkg, required this.quote});

  final Package pkg;
  final Quote quote;

  QuoteTotals get totals => quote.totals;

  /// The voucher pays for itself (the venue offers it and the saving beats the fee).
  bool get hasVoucher => quote.voucherOffered;
  int get standard => totals.standardTotal.fils;
  int? get voucher => hasVoucher ? totals.voucherTotal.fils : null;

  /// The saving after the voucher fee.
  int get net => hasVoucher ? totals.netSavings : 0;

  /// The total the client pays the venue: the voucher total when there is one.
  int get total => voucher ?? standard;

  PriceLine? get packageLine {
    for (final l in quote.lines) {
      if (l.kind == PriceLineKind.package) return l;
    }
    return quote.lines.isEmpty ? null : quote.lines.first;
  }

  /// Guests billed (the line quantity).
  int? get billed => packageLine?.qty;

  /// The rate per guest in the column the client pays (null for a flat package).
  int? get perGuest {
    final l = packageLine;
    if (l == null || pkg.pricingBasis == PricingBasis.flat) return null;
    return (hasVoucher ? l.unit : l.standardUnit)?.fils ?? l.unit?.fils;
  }
}

@immutable
final class SectionModel {
  const SectionModel({
    required this.hall,
    required this.audience,
    required this.guests,
    required this.minGuests,
    required this.maxGuests,
    required this.options,
    required this.tooSmall,
    required this.chosen,
    required this.effective,
    required this.sessions,
    required this.sessionId,
  });

  final Hall hall;
  final Audience audience;
  final int guests;
  final int minGuests;
  final int maxGuests;

  /// Packages sold in this hall to this audience on this date for these guests, cheapest first.
  final List<PricedPackage> options;

  /// Packages exist for the hall but none takes this many guests.
  final bool tooSmall;
  final PricedPackage? chosen;

  /// What the estimate uses until one is chosen.
  final PricedPackage? effective;
  final List<Session> sessions;
  final String? sessionId;

  Session? get session {
    for (final s in sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }
}

/// The request flow as one derived model (web `FlowModel`): the venue, the date, the single section, the voucher bound to the quote,
/// and the server quote of the effective package.
@immutable
final class FlowModel {
  const FlowModel({
    required this.venue,
    required this.date,
    required this.lead,
    required this.audience,
    required this.guests,
    required this.voucher,
    required this.slaHours,
    required this.section,
    required this.hostingOptions,
    required this.halls,
    required this.quote,
    required this.dateOk,
    required this.openRequests,
    required this.maxOpenRequests,
    required this.voucherFeeFils,
    required this.confirmWindowHours,
    required this.demo,
  });

  final Venue venue;
  final LocalDate date;

  /// Days from today to the event.
  final int lead;
  final Audience audience;
  final int guests;

  /// The voucher bound to this quote, or null (the Review then asks for one).
  final Voucher? voucher;
  final int slaHours;
  final SectionModel section;
  final List<Audience> hostingOptions;
  final List<Hall> halls;
  final Quote? quote;

  /// The first hall is free on the date (else it was taken, held or closed: CL-BOOK-07).
  final bool dateOk;
  final int openRequests;
  final int maxOpenRequests;
  final int voucherFeeFils;
  final int confirmWindowHours;

  /// Opened without a draft: the hero story is shown (consent preset, no write).
  final bool demo;

  bool get bound => voucher != null;

  /// A package is chosen: the number is a quote, not an estimate.
  bool get isFinal => section.chosen != null;

  /// The voucher pays for itself on this quote.
  bool get hasVoucherPrice => quote?.voucherOffered ?? false;

  /// The total the client pays the venue (voucher total when there is one).
  int? get total {
    final q = quote;
    if (q == null) return null;
    return q.voucherOffered ? q.totals.voucherTotal.fils : q.totals.standardTotal.fils;
  }
}
