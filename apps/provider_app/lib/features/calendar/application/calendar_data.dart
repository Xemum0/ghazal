// Data of the partner Calendar flow (web `calendar/_components/data.ts` and `store.ts`): the venue's halls, the calendar claims of a window (the
// API refuses a window of more than about a month: every call is one month or one week), the soft dates, what a block would collide with,
// what the viewer is looking at (day, month, hall filter) and the blocks this run made (for Undo and Open). Nothing here formats a string.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show homeRepositoryProvider, partnerCalendarRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BlockBatch, BlockInput, BlockReason, CalendarClaim, CalendarSync, ClaimKind, Hall, LocalDate, Occasion, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart' show GzYm, gzMarkOf, GzLaneMark;

import '../../../app/state/state.dart';

/// Reception, Manager and Admin block and open; Accountant reads only; Marketing sees the calendar with Offer only (ADR 0008 D12).
bool canBlock(StaffRole r) => r == StaffRole.admin || r == StaffRole.manager || r == StaffRole.reception;
bool canOffer(StaffRole r) => r != StaffRole.accountant;

final calendarRoleProvider = Provider<StaffRole>((ref) => ref.watch(partnerContextProvider)?.role ?? StaffRole.manager);

/// Today as `YYYY-MM-DD` on the app's clock (the story clock in shots and tests).
final calendarTodayProvider = Provider<String>((ref) => ref.watch(gzFormatProvider).isoDay(ref.watch(clockProvider)()));

/// The active venue's halls.
final calendarHallsProvider = FutureProvider.autoDispose<List<Hall>>((ref) async {
  final id = ref.watch(partnerContextProvider)?.venueId;
  if (id == null) return const <Hall>[];
  return (await ref.watch(venuesRepositoryProvider).getVenue(venueId: id)).venue.halls;
});

typedef CalWindow = ({String from, String to});

/// Every claim of a window (a month or a week); the hall filter is applied by the screens, so a filter change costs no call.
final calendarClaimsProvider = FutureProvider.autoDispose.family<List<CalendarClaim>, CalWindow>((ref, w) async {
  ref.watch(partnerDataRevisionProvider);
  final cal = await ref.watch(partnerCalendarRepositoryProvider).getPartnerCalendar(from: LocalDate.parse(w.from), to: LocalDate.parse(w.to));
  return [for (final d in cal.days) ...d.claims];
});

/// The unsold weekend dates of the next 60 days (HA-DASH-07).
final calendarSoftDatesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final s = await ref.watch(partnerCalendarRepositoryProvider).getSoftDates();
  return [for (final d in s.dates) d.toString()];
});

final calendarSyncProvider = FutureProvider.autoDispose<CalendarSync>((ref) async => ref.watch(partnerCalendarRepositoryProvider).getCalendarSync());

const int kSoftWindowDays = 60;
const String kAllHalls = 'all';

/// The first and last day of a month as a window.
CalWindow monthWindow(GzYm ym) {
  final first = LocalDate(ym.year, ym.month, 1);
  final last = LocalDate(ym.year, ym.month + 1, 1).addDays(-1);
  return (from: first.toString(), to: last.toString());
}

String sundayOf(String iso) {
  final d = LocalDate.parse(iso);
  return d.addDays(-d.weekdayIndex).toString();
}

String addDays(String iso, int n) => LocalDate.parse(iso).addDays(n).toString();

/// What the viewer is looking at: the chosen day (agenda, week and day views), the month and the hall filter. Shared by the three views.
class CalView {
  const CalView({required this.selected, required this.ym, this.hall = kAllHalls});

  final String selected;
  final GzYm ym;
  final String hall;

  CalView copyWith({String? selected, GzYm? ym, String? hall}) => CalView(selected: selected ?? this.selected, ym: ym ?? this.ym, hall: hall ?? this.hall);
}

GzYm ymOf(String iso) => GzYm(int.parse(iso.substring(0, 4)), int.parse(iso.substring(5, 7)));

class CalViewNotifier extends Notifier<CalView> {
  @override
  CalView build() {
    final today = ref.read(calendarTodayProvider);
    return CalView(selected: today, ym: ymOf(today));
  }

  void select(String iso) => state = state.copyWith(selected: iso, ym: ymOf(iso));
  void setYm(GzYm ym) => state = state.copyWith(ym: ym);
  void setHall(String hall) => state = state.copyWith(hall: hall);
}

final calViewProvider = NotifierProvider<CalViewNotifier, CalView>(CalViewNotifier.new);

/// The blocks this run created, by claim id (the API opens dates again by batch only: requests.md).
class BlockBatches extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const <String, String>{};

  void add(BlockBatch b) => state = {...state, for (final id in b.claimIds) id: b.id};
  void remove(String batchId) => state = {for (final e in state.entries) if (e.value != batchId) e.key: e.value};
}

final blockBatchesProvider = NotifierProvider<BlockBatches, Map<String, String>>(BlockBatches.new);

/// The weekly "is your calendar up to date" card, shared with Needs-you on the web; the card of this flow remembers its own confirm (requests.md).
class CalendarNudge extends Notifier<bool> {
  @override
  bool build() => false;

  void confirm() => state = true;
}

final calendarNudgeProvider = NotifierProvider<CalendarNudge, bool>(CalendarNudge.new);

// ---------------------------------------------------------------- what a date carries

CalendarClaim? claimOf(Iterable<CalendarClaim> claims, String iso, String hallId) {
  for (final c in claims) {
    if (c.hallId == hallId && c.date.toString() == iso && gzMarkOf(c) != null) return c;
  }
  return null;
}

GzLaneMark? markOf(CalendarClaim? c) => c == null ? null : gzMarkOf(c);

int requestsOn(Iterable<CalendarClaim> claims, String iso, Iterable<String> hallIds) =>
    claims.where((c) => c.date.toString() == iso && c.kind == ClaimKind.requested && hallIds.contains(c.hallId)).length;

/// Every hall taken on the date by a booking or a hold: a block cannot go on top.
bool isSoldOut(Iterable<CalendarClaim> claims, String iso, List<Hall> halls) =>
    halls.isNotEmpty && halls.every((h) {
      final m = markOf(claimOf(claims, iso, h.id));
      return m == GzLaneMark.booked || m == GzLaneMark.held;
    });

bool isFullyBlocked(Iterable<CalendarClaim> claims, String iso, List<Hall> halls) => halls.isNotEmpty && halls.every((h) => markOf(claimOf(claims, iso, h.id)) == GzLaneMark.blocked);

/// The effect of a block (web `analyse`): what is free, what a booking or hold refuses, what is already blocked, what is past, what is pending.
class BlockAnalysis {
  BlockAnalysis();

  final List<({String date, String hallId})> free = [];
  final List<CalendarClaim> taken = [];
  final List<({String date, String hallId})> already = [];
  final List<String> past = [];
  final List<({String date, int count})> pending = [];
}

BlockAnalysis analyse(List<String> dates, List<String> hallIds, Iterable<CalendarClaim> claims, String today) {
  final out = BlockAnalysis();
  for (final date in dates) {
    if (date.compareTo(today) < 0) {
      out.past.add(date);
      continue;
    }
    for (final hallId in hallIds) {
      final c = claimOf(claims, date, hallId);
      final m = markOf(c);
      if (c == null) {
        out.free.add((date: date, hallId: hallId));
      } else if (m == GzLaneMark.blocked) {
        out.already.add((date: date, hallId: hallId));
      } else {
        out.taken.add(c);
      }
    }
    final count = requestsOn(claims, date, hallIds);
    if (count > 0) out.pending.add((date: date, count: count));
  }
  return out;
}

/// Blocked claims inside a set of dates (all upcoming blocks when no dates are given), for the Open variant.
List<CalendarClaim> blockedIn(Iterable<CalendarClaim> claims, List<String> hallIds, List<String> dates, String today) {
  final out = claims.where((c) => c.kind == ClaimKind.block && c.date.toString().compareTo(today) >= 0 && hallIds.contains(c.hallId) && (dates.isEmpty || dates.contains(c.date.toString()))).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return out;
}

List<String> datesOfSpan(String? start, String? end) {
  if (start == null) return const <String>[];
  final e = end ?? start;
  final a = start.compareTo(e) <= 0 ? start : e;
  final b = start.compareTo(e) <= 0 ? e : start;
  final out = <String>[];
  var d = LocalDate.parse(a);
  final last = LocalDate.parse(b);
  while (!d.isAfter(last)) {
    out.add(d.toString());
    d = d.addDays(1);
  }
  return out;
}

Future<ApiProblem?> calendarWrite(Future<Object?> Function() call) async {
  try {
    await call();
    return null;
  } on ApiProblem catch (p) {
    return p;
  }
}

BlockInput blockInput(List<String> hallIds, List<String> dates, BlockReason reason, String note, {List<String>? sessionIds}) =>
    BlockInput(hallIds: hallIds, dates: [for (final d in dates) LocalDate.parse(d)], sessionIds: sessionIds, reason: reason, note: note.trim().isEmpty ? null : note.trim());

/// The platform's occasions: the Ramadan and Eid ones become shortcut chips of the block sheet (never fixed dates: they are approximate).
final calendarOccasionsProvider = FutureProvider.autoDispose<List<Occasion>>((ref) async {
  final cfg = await ref.watch(homeRepositoryProvider).getAppConfig();
  return [for (final o in cfg.occasions) if (o.id == 'ramadan-1448' || o.id.startsWith('eid')) o];
});

/// The months a block sheet needs claims of: the shown month, the months of the range and, with no range, the next three months (Open lists them).
List<CalWindow> sheetWindows(GzYm ym, String? start, String? end, String today) {
  final yms = <GzYm>{ym, if (start != null) ymOf(start), if (end != null) ymOf(end)};
  if (start == null) {
    final t = ymOf(today);
    for (var i = 0; i < 3; i++) {
      final idx = t.year * 12 + (t.month - 1) + i;
      yms.add(GzYm(idx ~/ 12, (idx % 12) + 1));
    }
  }
  return [for (final y in yms) monthWindow(y)];
}
