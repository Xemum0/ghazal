import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';


/// The wedding file of the signed-in client, as one call: the profile, the countdown, the checklist progress, the budget summary, the
/// open requests and the planner request. A guest has none (the hub shows its teaser). Throws the `ApiProblem` for the error and
/// offline states (never a silent empty file).
final FutureProvider<WeddingOverview?> weddingOverviewProvider = FutureProvider<WeddingOverview?>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return null;
  return ref.watch(weddingRepositoryProvider).getWeddingOverview();
});

/// The rules-based checklist (PRD defaults with due dates counted back from the wedding date, plus the couple's own tasks). A guest sees
/// the sample list (the mock answers one); writes are guest-gated by the screens.
final FutureProvider<ChecklistView> weddingChecklistProvider = FutureProvider<ChecklistView>((ref) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(weddingRepositoryProvider).getChecklist();
});

/// The budget: committed versus paid versus remaining, ranked categories, the automatic rows (the KD 2 voucher as Paid, the venue price
/// as Committed) and the couple's manual expenses.
final FutureProvider<BudgetView> weddingBudgetProvider = FutureProvider<BudgetView>((ref) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(weddingRepositoryProvider).getBudget();
});

/// The phase of the wedding file, as the hub shows it (ADR 0007 D4). Simplified from the web's phase machine to what the app can read:
/// no profile or no date, pre-venue (no open request), pending (an open pending request), awaiting-confirm (an approved request),
/// confirmed, or post-event (a completed booking).
enum WeddingPhase { guest, noDate, preVenue, pending, awaitingConfirm, confirmed, weddingWeek, dayOf, postEvent }

/// The hero request of the hub: the open request that matters most (approved first, then pending, then confirmed).
BookingRow? hubBooking(List<BookingRow> rows) {
  BookingRow? firstWhere(bool Function(Booking b) test) => rows.where((r) => test(r.booking)).firstOrNull;
  return firstWhere((b) => b.status == BookingStatus.approved) ??
      firstWhere((b) => b.status == BookingStatus.pending) ??
      firstWhere((b) => b.status == BookingStatus.confirmed) ??
      rows.firstOrNull;
}

WeddingPhase weddingPhaseOf({required bool guest, required WeddingProfile? profile, required List<BookingRow> rows, required DateTime now}) {
  if (guest) return WeddingPhase.guest;
  if (profile == null) return WeddingPhase.noDate;
  final open = rows.where((r) => r.booking.status == BookingStatus.pending || r.booking.status == BookingStatus.approved);
  if (open.any((r) => r.booking.status == BookingStatus.approved)) return WeddingPhase.awaitingConfirm;
  if (open.any((r) => r.booking.status == BookingStatus.pending)) return WeddingPhase.pending;
  if (rows.any((r) => r.booking.status == BookingStatus.completed)) return WeddingPhase.postEvent;
  if (rows.any((r) => r.booking.status == BookingStatus.confirmed)) return WeddingPhase.confirmed;
  final days = weddingDaysLeft(profile.weddingDate, now);
  if (days == 0) return WeddingPhase.dayOf;
  if (days <= 7) return WeddingPhase.weddingWeek;
  return WeddingPhase.preVenue;
}

/// The paid voucher waiting for its request (bound to a hall, no request yet): the voucher-ready lead of the hub.
final FutureProvider<WalletItem?> unboundVoucherProvider = FutureProvider<WalletItem?>((ref) async {
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return null;
  try {
    final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
    return page.items.where((w) => w.voucher.bookingId == null && (w.voucher.status == VoucherStatus.active || w.voucher.status == VoucherStatus.bound)).firstOrNull;
  } on ApiProblem {
    return null;
  }
});

/// One row of the Payments ledger: a Ghazal-posted automatic row (the KD 2 voucher as Paid, the venue price as Committed, both
/// read only) or a manual expense of the couple.
class LedgerEntry {
  const LedgerEntry({required this.id, required this.auto, required this.categoryId, this.label, required this.amountFils, required this.status, this.bookingId, this.voucher = false});

  final String id;
  final bool auto;

  /// The budget category (venue and catering for automatic rows).
  final BudgetCategoryId categoryId;
  final String? label;
  final int amountFils;
  final ExpenseStatus status;
  final String? bookingId;

  /// The automatic row is the voucher itself (ticket glyph, "Voucher"); otherwise the venue price (hall glyph, category name).
  final bool voucher;
}

/// The Payments ledger: the automatic rows first (the paid voucher, the committed venue price of the open request), then the manual
/// expenses of the couple.
final FutureProvider<List<LedgerEntry>> weddingLedgerProvider = FutureProvider<List<LedgerEntry>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <LedgerEntry>[];
  final budget = await ref.watch(weddingRepositoryProvider).getBudget();
  final rows = <LedgerEntry>[];
  try {
    final wallet = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
    final paid = wallet.items.where((w) => w.voucher.status == VoucherStatus.bound || w.voucher.status == VoucherStatus.active || w.voucher.status == VoucherStatus.used).firstOrNull;
    if (paid != null && paid.voucher.priceFils > 0) {
      rows.add(LedgerEntry(id: 'auto-voucher', auto: true, categoryId: BudgetCategoryId.venueCatering, amountFils: paid.voucher.priceFils, status: ExpenseStatus.paid, bookingId: paid.voucher.bookingId, voucher: true));
    }
  } on ApiProblem {
    // No voucher, no voucher row.
  }
  try {
    final requests = await ref.watch(requestsRepositoryProvider).listRequests(limit: 50);
    final open = requests.items.where((r) => r.booking.status == BookingStatus.pending || r.booking.status == BookingStatus.approved || r.booking.status == BookingStatus.confirmed).firstOrNull;
    if (open != null && open.booking.totals.voucherTotal.fils > 0) {
      rows.add(
        LedgerEntry(id: 'auto-venue', auto: true, categoryId: BudgetCategoryId.venueCatering, amountFils: open.booking.totals.voucherTotal.fils, status: ExpenseStatus.committed, bookingId: open.booking.id),
      );
    }
  } on ApiProblem {
    // No request, no venue row.
  }
  return [
    ...rows,
    for (final e in budget.budget.expenses)
      LedgerEntry(id: e.id, auto: false, categoryId: e.categoryId, label: e.label, amountFils: e.amount.fils, status: e.status, bookingId: e.bookingId),
  ];
});

/// Whole days from [now] to the wedding date (never negative).
int weddingDaysLeft(LocalDate? weddingDate, DateTime now) {
  if (weddingDate == null) return 0;
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(weddingDate.year, weddingDate.month, weddingDate.day);
  final days = target.difference(today).inDays;
  return days < 0 ? 0 : days;
}

/// One action of Next up: a glyph, one word and one fact, and where it opens.
class NextUp {
  const NextUp({required this.icon, required this.title, required this.fact, required this.factLabel, required this.route, this.params = const <String, Object?>{}, this.sheet = false});

  final IconData icon;
  final String title;
  final String fact;
  final String factLabel;
  final String route;
  final Map<String, Object?> params;

  /// Opened as a sheet (a visit), not pushed.
  final bool sheet;
}
