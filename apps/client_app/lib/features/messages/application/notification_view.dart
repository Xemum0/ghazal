import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show NotificationKind;

/// The filter chips of the notification centre.
enum NtfFilter { all, bookings, vouchers, visits, messages, planning }

NtfFilter filterOfKind(NotificationKind k) => switch (k) {
  NotificationKind.voucherReady ||
  NotificationKind.voucherReleased ||
  NotificationKind.voucherRedeemed ||
  NotificationKind.creditVoucherIssued ||
  NotificationKind.voucherForfeited ||
  NotificationKind.voucherExpiring => NtfFilter.vouchers,
  NotificationKind.visitRequested ||
  NotificationKind.visitConfirmed ||
  NotificationKind.visitReminder ||
  NotificationKind.visitMessage => NtfFilter.visits,
  NotificationKind.message || NotificationKind.plannerAssigned => NtfFilter.messages,
  NotificationKind.newVenue || NotificationKind.countdown || NotificationKind.checklistDue => NtfFilter.planning,
  _ => NtfFilter.bookings,
};

/// The OS notification permission as the app knows it (simulated: the pre-prompt asks, the answer is kept for the session).
enum NtfPermission { unknown, granted, denied }

final NotifierProvider<NtfPermissionNotifier, NtfPermission> ntfPermissionProvider = NotifierProvider<NtfPermissionNotifier, NtfPermission>(
  NtfPermissionNotifier.new,
);

class NtfPermissionNotifier extends Notifier<NtfPermission> {
  @override
  NtfPermission build() => NtfPermission.unknown;

  void set(NtfPermission p) => state = p;
}

/// Icon, title key by kind live in the row widget; this says whether the kind names a venue as its subject line.
const Set<NotificationKind> kAboutVenue = <NotificationKind>{
  NotificationKind.requestSent,
  NotificationKind.requestApproved,
  NotificationKind.confirmReminder,
  NotificationKind.requestConfirmed,
  NotificationKind.requestDeclined,
  NotificationKind.requestExpired,
  NotificationKind.bookingCancelled,
  NotificationKind.voucherReady,
  NotificationKind.voucherReleased,
  NotificationKind.voucherRedeemed,
  NotificationKind.voucherExpiring,
  NotificationKind.visitRequested,
  NotificationKind.visitConfirmed,
  NotificationKind.visitReminder,
  NotificationKind.visitMessage,
  NotificationKind.newVenue,
};

@immutable
class NtfLanding {
  const NtfLanding(this.route, [this.params = const <String, Object?>{}, this.tab]);

  final String? route;
  final Map<String, Object?> params;
  final String? tab;
}
