import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider, visitsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, Venue, VisitAppointment, VisitRow, VisitSlot, VisitStatus, VisitThread;

import '../../../app/state/state.dart';

/// A venue's face for the visit sheets and rows.
final venueOfProvider = FutureProvider.autoDispose.family<Venue?, String>((ref, id) async {
  try {
    return (await ref.watch(venuesRepositoryProvider).getVenue(venueId: id)).venue;
  } on Object {
    return null;
  }
});

/// Dates with at least one bookable visit slot (CL-VIST-01).
final visitDatesProvider = FutureProvider.autoDispose.family<List<LocalDate>, String>((ref, venueId) async {
  final r = await ref.watch(visitsRepositoryProvider).listVisitDates(venueId: venueId);
  return r.dates;
});

/// 30-minute arrival windows of one date (CL-VIST-01, CL-VIST-05).
final visitSlotsProvider = FutureProvider.autoDispose.family<List<VisitSlot>, ({String venueId, String date})>((ref, q) async {
  final r = await ref.watch(visitsRepositoryProvider).listVisitSlots(venueId: q.venueId, date: LocalDate.parse(q.date));
  return r.slots;
});

/// One visit with its three-role group chat (CL-VIST-02, CL-VIST-03, CL-VIST-05).
final visitThreadProvider = FutureProvider.autoDispose.family<VisitThread, String>((ref, visitId) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(visitsRepositoryProvider).getVisitThread(visitId: visitId);
});

/// The client's visits (CL-VIST-04).
final myVisitsProvider = FutureProvider.autoDispose<List<VisitRow>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return const <VisitRow>[];
  final page = await ref.watch(visitsRepositoryProvider).listVisits(limit: 50);
  return page.items;
});

/// Upcoming first (by slot), then past.
List<VisitRow> orderVisits(List<VisitRow> rows, DateTime now) {
  final upcoming = rows.where((r) => !visitClosed(r.visit) && !r.visit.slotStart.isBefore(now)).toList()
    ..sort((a, b) => a.visit.slotStart.compareTo(b.visit.slotStart));
  final past = rows.where((r) => !upcoming.contains(r)).toList()
    ..sort((a, b) => b.visit.slotStart.compareTo(a.visit.slotStart));
  return [...upcoming, ...past];
}

bool visitClosed(VisitAppointment v) =>
    v.status == VisitStatus.completed || v.status == VisitStatus.declined || v.status == VisitStatus.cancelled || v.status == VisitStatus.missed;

bool visitIsUpcoming(VisitAppointment v, DateTime now) => !visitClosed(v) && !v.slotStart.isBefore(now);

/// The chat of a visit is read-only: closed at once on cancel or decline, or 24 h after the slot.
bool visitChatClosed(VisitAppointment v, DateTime now) =>
    v.closedAt != null || visitClosed(v) || now.isAfter(v.slotEnd.add(const Duration(hours: 24)));
