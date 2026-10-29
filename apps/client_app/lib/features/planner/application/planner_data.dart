import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show plannersRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show DayPart, LocalDate, PlannerDetail, PlannerPackage, PlannerRequest, PlannerTier, Venue;

import '../../../app/state/state.dart';

/// The tier the family picked on CL-PLAN-01 (Silver | Gold | Royal). Seeded
/// Gold like the story draft; CL-PLAN-02 opens with the tier it was given.
final NotifierProvider<PlannerTierChoice, PlannerTier> plannerTierProvider = NotifierProvider<PlannerTierChoice, PlannerTier>(PlannerTierChoice.new);

class PlannerTierChoice extends Notifier<PlannerTier> {
  @override
  PlannerTier build() => PlannerTier.gold;

  void set(PlannerTier tier) => state = tier;
}

/// The three planner packages (Silver, Gold, Royal) from the server.
final plannerPackagesProvider = FutureProvider.autoDispose<List<PlannerPackage>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  return ref.read(plannersRepositoryProvider).listPlannerPackages();
});

/// The couple's open consultation request, or null when there is none (a client who never
/// asked). A transport failure is rethrown so
/// the screens can show error and offline; "no such request" reads as null.
final currentPlannerRequestProvider = FutureProvider.autoDispose<PlannerRequest?>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (ref.watch(clientUserIdProvider) == null) return null;
  try {
    return await ref.read(plannersRepositoryProvider).getCurrentPlannerRequest();
  } on ApiProblem catch (problem) {
    if (problem.isOffline) rethrow;
    return null;
  }
});

/// The assigned planner and the packages she serves, once a request exists.
final plannerDetailProvider = FutureProvider.autoDispose.family<PlannerDetail?, String>((ref, plannerId) async {
  ref.watch(clientDataRevisionProvider);
  try {
    return await ref.read(plannersRepositoryProvider).getPlanner(plannerId: plannerId);
  } on ApiProblem catch (problem) {
    if (problem.isOffline) rethrow;
    return null;
  }
});

/// The hall of a context line or a request summary, by venue id.
final plannerVenueProvider = FutureProvider.autoDispose.family<Venue?, String>((ref, venueId) async {
  try {
    final detail = await ref.read(venuesRepositoryProvider).getVenue(venueId: venueId);
    return detail.venue;
  } on ApiProblem {
    return null;
  }
});

/// How the family wants to be reached about the consultation.
enum PlannerReach { chat, whatsapp, phone }

/// The consultation draft (CL-PLAN-02): up to three `date|part` windows, the
/// reach channel and the note. Kept in providers (not screen state) so the
/// hard gate resumes with everything typed after sign-in.
final NotifierProvider<PlannerWindows, Set<String>> plannerWindowsProvider = NotifierProvider<PlannerWindows, Set<String>>(PlannerWindows.new);

class PlannerWindows extends Notifier<Set<String>> {
  /// The story windows (Sun 15 Nov evening, Mon 16 Nov afternoon), like the
  /// prototype draft that opens with what Reem asked.
  static const Set<String> story = <String>{'2026-11-15|evening', '2026-11-16|afternoon'};

  @override
  Set<String> build() => Set<String>.of(story);

  /// Toggles one window; adding past three is refused (the screen says why).
  bool toggle(String key) {
    if (state.contains(key)) {
      state = Set<String>.of(state)..remove(key);
      return true;
    }
    if (state.length >= 3) return false;
    state = Set<String>.of(state)..add(key);
    return true;
  }

  void clear() => state = <String>{};

  void replace(Set<String> windows) => state = Set<String>.of(windows);
}

final NotifierProvider<PlannerReachChoice, PlannerReach> plannerReachProvider = NotifierProvider<PlannerReachChoice, PlannerReach>(
  PlannerReachChoice.new,
);

class PlannerReachChoice extends Notifier<PlannerReach> {
  @override
  PlannerReach build() => PlannerReach.chat;

  void set(PlannerReach reach) => state = reach;
}

final NotifierProvider<PlannerNote, String> plannerNoteProvider = NotifierProvider<PlannerNote, String>(PlannerNote.new);

class PlannerNote extends Notifier<String> {
  @override
  String build() => 'نحتاج مساعدة في تصميم الكوشة والتنسيق مع الفندق';

  void set(String note) => state = note;
}

/// `YYYY-MM-DD|part`, the window the two-week calendar stores.
String planWindowKey(LocalDate date, DayPart part) => '$date|${part.value}';

/// Splits a stored window back into its day and part.
(LocalDate, DayPart) parsePlanWindow(String key) {
  final cut = key.split('|');
  return (LocalDate.parse(cut[0]), DayPart.fromJson(cut.length > 1 ? cut[1] : 'evening'));
}

/// The next 14 civil days after today (the earliest consultation is tomorrow).
List<LocalDate> plannerDays(DateTime now) {
  final kuwait = now.toUtc().add(const Duration(hours: 3));
  final today = LocalDate(kuwait.year, kuwait.month, kuwait.day);
  return <LocalDate>[for (var i = 1; i <= 14; i++) today.addDays(i)];
}
