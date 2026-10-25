import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show requestsRepositoryProvider, visitsRepositoryProvider, vouchersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingRow, BookingStatus, Receipt, VisitRow, VisitStatus, Voucher, VoucherPaymentStatus, VoucherStatus, WalletItem, WeddingProfile;
import 'package:ghazal_ui/ghazal_ui.dart' show GzStatus;

import '../../../app/state/state.dart';

/// What the hub and the deletion screen know about the couple's activity: the one live request, the ready vouchers, the visits ahead and
/// what was paid to Ghazal (the KD 2 voucher, ADR 0033).
class ProfileActivity {
  const ProfileActivity({this.request, this.ready = const <WalletItem>[], this.visitsAhead = 0, this.paidFils = 0});

  /// The pending, approved or confirmed request (null when none).
  final BookingRow? request;
  final List<WalletItem> ready;
  final int visitsAhead;
  final int paidFils;

  BookingStatus? get requestStatus => request?.booking.status;

  /// The request as a status glyph of the hub (a redeemed voucher with the event ahead reads as confirmed).
  GzStatus? get glyph => switch (requestStatus) {
    BookingStatus.pending => GzStatus.pending,
    BookingStatus.approved => GzStatus.approved,
    BookingStatus.confirmed || BookingStatus.redeemed => GzStatus.confirmed,
    _ => null,
  };

  /// A request that blocks deletion: approved (confirm or cancel first) or confirmed with the event still ahead.
  bool get blocksDeletion => glyph == GzStatus.approved || glyph == GzStatus.confirmed;

  /// Ready vouchers that may still be turned into a credit voucher by support (shown as "Use voucher").
  List<WalletItem> get creditEligible => <WalletItem>[
    for (final w in ready)
      if (w.voucher is Voucher && (w.voucher as Voucher).creditEligible) w,
  ];
}

/// Read once per revision of the client data (a request, a voucher or a visit changed). Failures of one list do not hide the others.
final FutureProvider<ProfileActivity> profileActivityProvider = FutureProvider<ProfileActivity>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return const ProfileActivity();
  final requests = ref.read(requestsRepositoryProvider);
  final vouchers = ref.read(vouchersRepositoryProvider);
  final visits = ref.read(visitsRepositoryProvider);

  Future<T?> soft<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiProblem catch (e) {
      if (e.isOffline) rethrow;
      return null;
    }
  }

  final reqPage = await soft(() => requests.listRequests(limit: 50));
  final vchPage = await soft(() => vouchers.listVouchers(limit: 50));
  final visPage = await soft(() => visits.listVisits(limit: 50));
  final rcpPage = await soft(() => vouchers.listReceipts(limit: 50));

  // The one live request: approved first (it waits for the client), then confirmed, redeemed, pending.
  BookingRow? request;
  for (final status in const <BookingStatus>[BookingStatus.approved, BookingStatus.confirmed, BookingStatus.redeemed, BookingStatus.pending]) {
    for (final r in reqPage?.items ?? const <BookingRow>[]) {
      if (request == null && r.booking.status == status) request = r;
    }
  }
  final ready = <WalletItem>[
    for (final w in vchPage?.items ?? const <WalletItem>[])
      if (w.voucher.status == VoucherStatus.active) w,
  ];
  const aheadStatuses = <VisitStatus>{VisitStatus.requested, VisitStatus.confirmed, VisitStatus.rescheduleProposed};
  final ahead = (visPage?.items ?? const <VisitRow>[]).where((v) => aheadStatuses.contains(v.visit.status)).length;
  var paid = 0;
  for (final r in rcpPage?.items ?? const <Receipt>[]) {
    if (r.status == VoucherPaymentStatus.succeeded) paid += r.amount.fils;
  }
  return ProfileActivity(request: request, ready: ready, visitsAhead: ahead, paidFils: paid);
});

/// The hub's one read: the activity and the wedding profile together (a skeleton until both are there).
final FutureProvider<(ProfileActivity, WeddingProfile?)> profileHubProvider = FutureProvider<(ProfileActivity, WeddingProfile?)>((ref) async {
  final activity = await ref.watch(profileActivityProvider.future);
  final wedding = await ref.watch(weddingProfileProvider.future);
  return (activity, wedding);
});
