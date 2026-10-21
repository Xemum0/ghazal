// The next seven days of the strip on Today: one mark per hall (booked or blocked = solid, a request or hold = gold, nothing = open), web
// `stripDays` (`today/_components/data.ts`).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerCalendarRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ClaimKind, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart' show GzStripDay, GzStripMark;

import '../../../app/state/state.dart';

@immutable
final class WeekStrip {
  const WeekStrip({required this.days});

  final List<GzStripDay> days;

  int count(GzStripMark m) => days.fold<int>(0, (n, d) => n + d.marks.where((x) => x == m).length);
}

/// Seven days from the app's today, one mark per hall of the active venue (a service provider has no halls, so no strip).
final FutureProvider<WeekStrip?> weekStripProvider = FutureProvider.autoDispose<WeekStrip?>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final ctx = ref.watch(partnerContextProvider);
  final venueId = ctx?.venueId;
  if (venueId == null) return null;
  final now = ref.read(clockProvider)();
  final today = LocalDate.parse(now.toUtc().add(const Duration(hours: 3)).toIso8601String().substring(0, 10));
  final end = today.addDays(6);
  final venue = await ref.read(venuesRepositoryProvider).getVenue(venueId: venueId);
  final calendar = await ref.read(partnerCalendarRepositoryProvider).getPartnerCalendar(from: today, to: end);
  final halls = venue.venue.halls;
  final days = <GzStripDay>[];
  for (var i = 0; i < 7; i++) {
    final date = today.addDays(i);
    final claims = calendar.days.where((d) => d.date == date).expand((d) => d.claims).toList();
    final marks = <GzStripMark>[
      for (final h in halls)
        () {
          final mine = claims.where((c) => c.hallId == h.id);
          if (mine.any((c) => c.kind == ClaimKind.booking || c.kind == ClaimKind.block)) return GzStripMark.confirmed;
          if (mine.isNotEmpty) return GzStripMark.pending;
          return GzStripMark.open;
        }(),
    ];
    days.add(GzStripDay(iso: date.toString(), marks: marks));
  }
  return WeekStrip(days: days);
});
