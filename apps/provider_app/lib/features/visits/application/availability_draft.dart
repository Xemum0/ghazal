// The visit availability being edited (HL-VIST-05, web `visits/_components/store.ts` + `availability.ts`): a draft of the weekly windows, the
// window length and the master switch, converted from and to the API's rules. Blackout dates and the default representative are not in the API
// (requests.md): they live in the draft only.
import 'package:ghazal_domain/ghazal_domain.dart' show LocalTime, VisitAvailability, VisitSlotRule;

class DayWindow {
  const DayWindow({required this.open, required this.from, required this.to});

  final bool open;
  final LocalTime from;
  final LocalTime to;

  DayWindow copyWith({bool? open, LocalTime? from, LocalTime? to}) => DayWindow(open: open ?? this.open, from: from ?? this.from, to: to ?? this.to);

  @override
  bool operator ==(Object other) => other is DayWindow && other.open == open && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(open, from, to);
}

class Blackout {
  const Blackout({required this.id, required this.from, required this.to});

  final String id;
  final String from;
  final String to;

  @override
  bool operator ==(Object other) => other is Blackout && other.id == id && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(id, from, to);
}

const List<int> kWeekDays = [0, 1, 2, 3, 4, 5, 6];
const List<int> kSlotChoices = [30, 45, 60];

class AvailabilityDraft {
  const AvailabilityDraft({required this.on, required this.week, required this.slotMinutes, this.repId, this.blackouts = const <Blackout>[]});

  factory AvailabilityDraft.fromApi(VisitAvailability a) {
    final week = <int, DayWindow>{};
    for (final d in kWeekDays) {
      final rule = a.rules.where((r) => r.days.contains(d)).firstOrNull;
      week[d] = rule == null
          ? const DayWindow(open: false, from: LocalTime(10, 0), to: LocalTime(18, 0))
          : DayWindow(open: true, from: rule.from, to: rule.to);
    }
    final minutes = a.rules.isEmpty ? 30 : a.rules.first.slotMinutes;
    return AvailabilityDraft(on: a.enabled, week: week, slotMinutes: kSlotChoices.contains(minutes) ? minutes : 30);
  }

  final bool on;
  final Map<int, DayWindow> week;
  final int slotMinutes;
  final String? repId;
  final List<Blackout> blackouts;

  AvailabilityDraft copyWith({bool? on, Map<int, DayWindow>? week, int? slotMinutes, String? repId, List<Blackout>? blackouts}) => AvailabilityDraft(
    on: on ?? this.on,
    week: week ?? this.week,
    slotMinutes: slotMinutes ?? this.slotMinutes,
    repId: repId ?? this.repId,
    blackouts: blackouts ?? this.blackouts,
  );

  AvailabilityDraft withDay(int d, DayWindow w) => copyWith(week: {...week, d: w});

  /// One rule per open day (the API groups nothing; a day is its own rule).
  VisitAvailability toApi() => VisitAvailability(
    enabled: on,
    rules: [
      for (final d in kWeekDays)
        if (week[d]!.open) VisitSlotRule(days: [d], from: week[d]!.from, to: week[d]!.to, slotMinutes: slotMinutes),
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is AvailabilityDraft &&
      other.on == on &&
      other.slotMinutes == slotMinutes &&
      other.repId == repId &&
      _same(other.week, week) &&
      _sameList(other.blackouts, blackouts);

  @override
  int get hashCode => Object.hash(on, slotMinutes, repId, Object.hashAll(kWeekDays.map((d) => week[d])), Object.hashAll(blackouts));
}

bool _same(Map<int, DayWindow> a, Map<int, DayWindow> b) => kWeekDays.every((d) => a[d] == b[d]);

bool _sameList(List<Blackout> a, List<Blackout> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

enum DayMistake { order }

/// An open day needs an end after its start. (The business-hours bound of the web needs the settings API: requests.md.)
DayMistake? mistakeOf(DayWindow w) => w.open && w.to.minutesOfDay <= w.from.minutesOfDay ? DayMistake.order : null;

/// Half-hour choices of a day (the venue's business hours are the outer bound on the web; here a working day of the venue).
List<LocalTime> timeChoices(LocalTime current) {
  final out = <LocalTime>[for (var m = 9 * 60; m <= 22 * 60; m += 30) LocalTime(m ~/ 60, m % 60)];
  if (!out.contains(current)) {
    out
      ..add(current)
      ..sort((a, b) => a.compareTo(b));
  }
  return out;
}
