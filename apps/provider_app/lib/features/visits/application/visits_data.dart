// Data of the partner Visits flow: the venue's visits, one visit with its group chat, the staff who can be the representative, the weekly
// availability, who may do what, and the visit clock (ADR 0033 D9, voucher-model section 11). Everything goes through the repositories; the
// hero visits are the ones of the web screens (`design/src/screens/hotel/visits/_components/model.ts`).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerVisitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffRole, VisitAppointment, VisitAvailability, VisitStatus, VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart' show GzStatus;

import '../../../app/state/state.dart';

/// The confirmed visit of the story (Reem at the hall) and the requested one (Rashed): what a screen shows without route params.
const String kHeroConfirmedVisit = 'visit-aurelia-reem';
const String kHeroRequestedVisit = 'visit-aurelia-rashed';

/// Admin, Manager and Reception reply to visits; Accountant and Marketing do not see the visit screens at all.
bool canSeeVisits(StaffRole r) => r == StaffRole.admin || r == StaffRole.manager || r == StaffRole.reception;

/// Admin and Manager read every visit chat and may reassign the representative and set the venue's availability.
bool isVisitLead(StaffRole r) => r == StaffRole.admin || r == StaffRole.manager;

final visitRoleProvider = Provider<StaffRole>((ref) => ref.watch(partnerContextProvider)?.role ?? StaffRole.manager);

/// Every visit of the venue (the API scopes it), nearest slot first.
final venueVisitsProvider = FutureProvider.autoDispose<List<VisitAppointment>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final page = await ref.watch(partnerVisitsRepositoryProvider).listPartnerVisits(limit: 50);
  return [...page.items]..sort((a, b) => a.slotStart.compareTo(b.slotStart));
});

/// One visit with its three-role group chat and its messages (HL-VIST-02, HL-VIST-03, HL-VIST-04).
final partnerVisitThreadProvider = FutureProvider.autoDispose.family<VisitThread, String>((ref, id) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.watch(partnerVisitsRepositoryProvider).getPartnerVisitThread(visitId: id);
});

/// The venue's staff (the pool a representative is picked from).
final visitStaffProvider = partnerStaffProvider;

final visitAvailabilityProvider = FutureProvider.autoDispose<VisitAvailability>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.watch(partnerVisitsRepositoryProvider).getVisitAvailability();
});

/// A representative picked in the app. The API has no reassign call yet (requests.md): the pick is kept per visit for this run.
final representativeOverrideProvider = NotifierProvider<RepresentativeOverride, Map<String, String>>(RepresentativeOverride.new);

class RepresentativeOverride extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const <String, String>{};

  void set(String visitId, String userId) => state = {...state, visitId: userId};
}

/// The visits' own decline reasons, kept for the note under the date (the API keeps the reason in the chat only).
final declineReasonProvider = NotifierProvider<DeclineReasons, Map<String, String>>(DeclineReasons.new);

class DeclineReasons extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const <String, String>{};

  void set(String visitId, String reason) => state = {...state, visitId: reason};
}

// ---------------------------------------------------------------- the visit clock

enum VisitSegment { requested, upcoming, past }

const Duration _day = Duration(hours: 24);

bool visitIsPast(VisitStatus s) => s == VisitStatus.completed || s == VisitStatus.declined || s == VisitStatus.cancelled || s == VisitStatus.missed;

VisitSegment segmentOf(VisitAppointment v, DateTime now) {
  if (v.status == VisitStatus.requested) return VisitSegment.requested;
  if (v.status == VisitStatus.rescheduleProposed) return VisitSegment.upcoming;
  if (visitIsPast(v.status)) return VisitSegment.past;
  return !now.isBefore(v.slotStart.add(_day)) ? VisitSegment.past : VisitSegment.upcoming;
}

bool visitChatClosed(VisitAppointment v, DateTime now) {
  if (v.status == VisitStatus.declined || v.status == VisitStatus.cancelled) return true;
  final closed = v.closedAt;
  if (closed != null && !closed.isAfter(now)) return true;
  return !now.isBefore(v.slotStart.add(_day));
}

int minutesSinceSlot(VisitAppointment v, DateTime now) => now.difference(v.slotStart).inMinutes;

/// Missed may be flagged from 30 minutes after the slot and within 24 hours after it (HL-VIST-04).
bool canFlagMissed(VisitAppointment v, DateTime now) {
  final m = minutesSinceSlot(v, now);
  return m >= 30 && m <= 24 * 60;
}

/// "Mark arrived" is offered on the day of the visit only.
bool canMarkArrived(VisitAppointment v, DateTime now, String Function(DateTime) isoDay) =>
    v.status == VisitStatus.confirmed && isoDay(v.slotStart) == isoDay(now);

/// First name as typed (the partner sees the first name; the phone only when the client shares it).
String firstName(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  return parts.isEmpty || parts.first.isEmpty ? full : parts.first;
}

GzStatus visitPill(VisitStatus s) => switch (s) {
  VisitStatus.requested => GzStatus.visitRequested,
  VisitStatus.confirmed => GzStatus.visitConfirmed,
  VisitStatus.rescheduleProposed => GzStatus.visitReschedule,
  VisitStatus.arrived => GzStatus.visitArrived,
  VisitStatus.completed => GzStatus.visitCompleted,
  VisitStatus.declined => GzStatus.visitDeclined,
  VisitStatus.cancelled => GzStatus.visitCancelled,
  _ => GzStatus.visitMissed,
};

/// What a representative's write gave back: null on success, the problem otherwise.
Future<ApiProblem?> visitWrite(Future<Object?> Function() call) async {
  try {
    await call();
    return null;
  } on ApiProblem catch (p) {
    return p;
  }
}

/// The clock of the app (tests and shots freeze it at the story time).
DateTime visitNow(WidgetRef ref) => ref.read(clockProvider)();
