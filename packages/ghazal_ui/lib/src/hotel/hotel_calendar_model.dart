/// The hotel calendar's model (web `calendar/model.ts`, ADR 0002 D9, ADR 0008 D9) and the small pieces the month and week views share.
/// Claim styles: booked = solid, held = ring (hatched in the week and day views, with its timer), blocked = struck, requested = a gold
/// bead that is informational and never claims the date (ADR 0001 D5). Dates are `YYYY-MM-DD` keys (the Kuwait business day).
library;

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BlockReason, CalendarClaim, ClaimKind, Hall;

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_calendar_model.dart' show GzDateRange, GzYm;
import 'hotel_bits.dart' show gzScriptOf;

/// What a hall carries on a date.
enum GzLaneMark { booked, held, blocked }

/// The mark of a claim; a pending request has none (it never claims the date).
GzLaneMark? gzMarkOf(CalendarClaim c) => switch (c.kind) {
  ClaimKind.booking => GzLaneMark.booked,
  ClaimKind.hold => GzLaneMark.held,
  ClaimKind.block => GzLaneMark.blocked,
  _ => null,
};

/// The first claim of [hallId] on [iso] that claims the date, or null.
CalendarClaim? gzClaimOf(Iterable<CalendarClaim> claims, String iso, String hallId) {
  for (final c in claims) {
    if (c.hallId == hallId && c.date.toString() == iso && gzMarkOf(c) != null) return c;
  }
  return null;
}

/// Pending requests that point at [hallId] on [iso] (a count, informational).
int gzRequestsOf(Iterable<CalendarClaim> claims, String iso, {String? hallId}) =>
    claims.where((c) => c.date.toString() == iso && c.kind == ClaimKind.requested && (hallId == null || c.hallId == hallId)).length;

/// One day of the month grid.
class GzDayFacts {
  const GzDayFacts({required this.iso, required this.lanes, required this.requested, required this.claims, required this.past});

  final String iso;

  /// One entry per hall in the venue's hall order: what that hall carries, or null when it is free.
  final List<GzLaneMark?> lanes;

  /// Pending requests that point at this date (count only, informational).
  final int requested;
  final List<CalendarClaim> claims;
  final bool past;

  /// A day with every hall booked or blocked cannot take a new block (a confirmed booking cannot be blocked over, ADR 0002 D9).
  bool get isFull => lanes.isNotEmpty && lanes.every((l) => l != null);
}

GzDayFacts gzDayFacts(String iso, List<Hall> halls, Iterable<CalendarClaim> claims, String today) {
  final mine = [
    for (final c in claims)
      if (c.date.toString() == iso) c,
  ];
  return GzDayFacts(
    iso: iso,
    lanes: [for (final h in halls) _laneOf(mine, h.id)],
    requested: mine.where((c) => c.kind == ClaimKind.requested).length,
    claims: mine,
    past: iso.compareTo(today) < 0,
  );
}

GzLaneMark? _laneOf(List<CalendarClaim> mine, String hallId) {
  for (final c in mine) {
    if (c.hallId == hallId) {
      final m = gzMarkOf(c);
      if (m != null) return m;
    }
  }
  return null;
}

/// Is [iso] inside [r] (either order, an open end counts as the start alone).
bool gzInSpan(String iso, GzDateRange r) {
  final s = r.start;
  if (s == null) return false;
  final e = r.end ?? s;
  final a = s.compareTo(e) <= 0 ? s : e;
  final b = s.compareTo(e) <= 0 ? e : s;
  return iso.compareTo(a) >= 0 && iso.compareTo(b) <= 0;
}

/// Tap-select: the first tap starts a range, the second ends it (either order), the third starts again.
GzDateRange gzTapSpan(GzDateRange r, String iso) {
  if (r.start == null || r.end != null) return GzDateRange(start: iso);
  return iso.compareTo(r.start!) < 0 ? GzDateRange(start: iso, end: r.start) : GzDateRange(start: r.start, end: iso);
}

/// The `year`/`month` of a key.
GzYm gzYmOf(String iso) => GzYm(int.parse(iso.substring(0, 4)), int.parse(iso.substring(5, 7)));

/// The reason of a block as its word (`Booked offline`, `Maintenance` ...); an unknown reason reads as Other.
String gzBlockReasonWord(GzL10n l, BlockReason? r) => switch (r) {
  BlockReason.offlineBooking => l.uiHotelCalReasonOfflineBooking,
  BlockReason.maintenance => l.uiHotelCalReasonMaintenance,
  BlockReason.privateEvent => l.uiHotelCalReasonPrivateEvent,
  _ => l.uiHotelCalReasonOther,
};

/// The head row of the month grid and the week view: previous at the inline-start, the title in the middle, next at the inline-end
/// (the chevrons mirror in Arabic through the icon registry). A 44 dp target each, gap 8.
class GzHotelCalHead extends StatelessWidget {
  const GzHotelCalHead({required this.title, required this.onPrevious, required this.onNext, super.key});

  final Widget title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    return Row(
      children: [
        GzIconButton(icon: GzIcons.chevronLeft, label: l.commonCalendarPreviousMonth, onPressed: onPrevious),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: Semantics(header: true, liveRegion: true, child: Center(child: title)),
        ),
        const SizedBox(width: GzSpace.s2),
        GzIconButton(icon: GzIcons.chevronRight, label: l.commonCalendarNextMonth, onPressed: onNext),
      ],
    );
  }
}

const String _dotSep = ' \u00b7 ';

/// `Name \u00b7 380 guests` as one run of text (the web flows a `UserText` and `Figures` inline): the guest's name keeps its own script
/// and is bidi-isolated, so in Arabic the name starts at the inline-start and the guest count follows right after it.
class GzClaimWho extends StatelessWidget {
  const GzClaimWho({required this.guests, required this.color, this.name, this.role = GzTextRole.caption, this.maxLines = 2, super.key});

  final String? name;
  final String guests;
  final GzTextRole role;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final base = gz.text(role).copyWith(color: color, decoration: TextDecoration.none);
    final who = name;
    return Text.rich(
      TextSpan(
        children: [
          if (who != null && who.isNotEmpty) ...[
            TextSpan(
              text: '\u2068$who\u2069',
              style: GzType.style(Locale(gzScriptOf(who)), role).copyWith(color: color, decoration: TextDecoration.none),
            ),
            const TextSpan(text: _dotSep),
          ],
          ...GzFigures.spans(context, guests, role: role),
        ],
      ),
      style: base,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
