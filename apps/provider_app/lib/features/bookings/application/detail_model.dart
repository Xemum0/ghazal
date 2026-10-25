// The model of Booking detail (web `detail.ts`, `bits.tsx`): the request as the server holds it, the role of the person looking at it and the
// review that still waits for a reply. The roles of ADR 0008 D12 as plain functions; nothing here formats a string.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerReviewsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

bool canDecide(StaffRole r) => r == StaffRole.admin || r == StaffRole.manager || r == StaffRole.reception;
bool canChange(StaffRole r) => r == StaffRole.admin || r == StaffRole.manager;

/// Redeeming a voucher: Admin, Manager and Reception (voucher-model 8.2); never Accountant or Marketing.
bool canRedeem(StaffRole r) => canDecide(r);
bool canContact(StaffRole r) => r != StaffRole.accountant && r != StaffRole.marketing;

/// The role of the signed-in staff member; a screen opened outside a session (a static frame) is the manager.
StaffRole roleOf(PartnerContextState? ctx) => ctx?.role ?? StaffRole.manager;

class DetailModel {
  const DetailModel({required this.detail, required this.role, required this.params, this.review});

  final PartnerRequestDetail detail;
  final StaffRole role;
  final Map<String, Object?> params;

  /// The review of this event that still waits for a reply (Completed: "Reply to review").
  final Review? review;

  Booking get booking => detail.booking;
  Voucher? get voucher => detail.voucher;

  /// Another couple's request holds the date (the Accept stays off with the held line).
  bool get held => params['conflict'] == true || booking.overlays.blockedByHold == true;
  int get others => detail.otherRequestsSameDate;
  bool get roleLimited => !canDecide(role) || !canContact(role);
}

/// The review of a completed booking's event that still waits for a reply, or null (also null when the role may not reply).
final reviewToReplyProvider = FutureProvider.autoDispose.family<Review?, Booking>((ref, b) async {
  if (b.status != BookingStatus.completed || b.venueId == null) return null;
  try {
    final page = await ref.read(partnerReviewsRepositoryProvider).listPartnerReviews(filter: ReviewFilter.awaitingReply, limit: 50);
    for (final r in page.items) {
      if (r.venueId == b.venueId && r.eventDate == b.eventDate && r.ownerReply == null) return r;
    }
  } on Object {
    return null;
  }
  return null;
});
