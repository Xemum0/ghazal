// Small pieces shared by the Bookings screens (web `bookings/_components/bits.tsx`, `facts.tsx`): the day lines, the two readings of a
// duration, the glyphs of a section and a session, the facts row of a booking and the glyph-and-figure tail of a list row. Nothing here types
// a digit, a price or a date: everything numeric comes from the shared formatter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// `Thu 10 Dec` (ADR 0011 D7, absolute); the year only when the date is more than ten months from today (a card never repeats it).
String dayLine(GzFormat f, LocalDate d, {bool year = false}) {
  if (year && f.daysUntil(d.toString()).abs() > 300) return f.date(d.toString(), DateStyle.short);
  return dayShort(f, d.toString());
}

String dayShort(GzFormat f, String iso) {
  final c = f.civil(iso);
  return '${f.weekdayName(c.weekday, NameStyle.short)} ${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// `13 Nov`: a day and a month only (a redemption day, a range end).
String dayMonthShort(GzFormat f, Object iso) {
  final c = f.civil(iso is DateTime ? iso : iso.toString());
  return '${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// `13 Nov 12:40 PM`: a deadline, day and month then the clock, no weekday.
String stampLine(GzFormat f, DateTime at) {
  final c = f.civil(at);
  return '${f.integer(c.day)} ${f.monthName(c.month, short: true)} ${f.time(at).replaceAll(' ', ' ')}';
}

/// Two readings of one duration (ADR 0011 D3): the compact visual line (`3 h`, `20 h 40 m`) and the spoken form for screen readers.
({String visual, String spoken}) durationOf(BuildContext context, int minutes, {bool lead = false}) {
  final f = context.gzFormat;
  final l = context.l10n;
  final total = minutes < 0 ? 0 : minutes;
  var visual = f.duration(total * 60000);
  final tail = RegExp(r'[ \u00a0\u202f]\u2066?[0\u0660]\u2069?\u00a0(?:m|\u062f|h|\u0633)$');
  for (var i = 0; i < 2; i++) {
    visual = visual.replaceFirst(tail, '');
  }
  if (lead) visual = visual.split(' ').take(2).join(' ');
  final d = total ~/ 1440;
  final h = (total % 1440) ~/ 60;
  final m = total % 60;
  final parts = <String>[
    if (d > 0) l.commonCountDays(d),
    if (h > 0) l.commonCountHours(h),
    if (d == 0 && (m > 0 || total == 0)) l.commonCountMinutes(m),
  ];
  final spoken = parts.length > 1 ? l.hotelBookingsDurJoin(parts[0], parts[1]) : (parts.isEmpty ? '' : parts.first);
  return (visual: visual, spoken: spoken);
}

/// A whole number of hours with the formatter's own unit letter (`24 h`, Arabic `24 س`).
String hoursText(GzFormat f, int hours) {
  final unit = RegExp(r'[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+').firstMatch(f.duration(3600000))?.group(0) ?? '';
  return '${f.integer(hours)} $unit';
}

int minutesBetween(DateTime from, DateTime to) {
  final m = (to.difference(from).inSeconds / 60).round();
  return m < 0 ? 0 : m;
}

IconData sectionIcon(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

String audienceWord(AppL10n l, Audience a) => switch (a) {
  Audience.men => l.hotelBookingsAudienceMen,
  Audience.mixed => l.hotelBookingsAudienceMixed,
  _ => l.hotelBookingsAudienceWomen,
};

/// The session of the day as a glyph by its start hour: sun (day), sunset (afternoon), moon (evening).
IconData sessionIcon(LocalTime start) => start.hour < 15 ? GzIcons.sun : (start.hour < 18 ? GzIcons.sunset : GzIcons.moon);

String sessionWord(AppL10n l, LocalTime start) => start.hour < 15 ? l.hotelBookingsSessionDay : (start.hour < 18 ? l.hotelBookingsSessionAfternoon : l.hotelBookingsSessionEvening);

IconData declineIcon(RejectReason? r) => switch (r) {
  RejectReason.capacityMismatch => GzIcons.usersThree,
  RejectReason.packageNotOffered => GzIcons.package,
  RejectReason.other => GzIcons.more,
  _ => GzIcons.calendarX,
};

String declineWord(AppL10n l, RejectReason? r) => switch (r) {
  RejectReason.capacityMismatch => l.hotelBookingsDeclineCapacity,
  RejectReason.packageNotOffered => l.hotelBookingsDeclinePackage,
  RejectReason.other => l.hotelBookingsDeclineOther,
  _ => l.hotelBookingsDeclineDate,
};

/// The hours a silence lasted: the venue's reply window, or the client's fixed 24 hour confirm window.
int silenceHours(Booking b) => b.expiredReason == ExpiredReason.clientNoConfirmation ? 24 : (b.slaHours ?? 24);

/// `[calendar] Thu 14 Jan  [women]  [moon]  [users] 350`: one row, the order of the policy, an absent fact is omitted.
class BookingFacts extends StatelessWidget {
  const BookingFacts({required this.booking, this.withDate = false, this.noGuests = false, this.small = false, this.tail, super.key});

  final Booking booking;
  final bool withDate;
  final bool noGuests;
  final bool small;

  /// More facts at the end of the row (a time left, a redemption day).
  final Widget? tail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final audiences = <Audience>{for (final s in booking.sections) s.audience};
    final sessions = <IconData, String>{for (final s in booking.sections) sessionIcon(s.start): sessionWord(l, s.start)};
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    return GzFactRow(
      label: l.hotelBookingsFactsLabel,
      children: [
        if (withDate) GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsFactDate, value: dayLine(f, booking.eventDate, year: true), small: small),
        for (final a in audiences) GzFactChip(icon: sectionIcon(a), label: audienceWord(l, a), small: small),
        for (final e in sessions.entries) GzFactChip(icon: e.key, label: e.value, small: small),
        if (!noGuests && guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelBookingsFactGuests, value: f.integer(guests), small: small),
        ?tail,
      ],
    );
  }
}

enum TailTone { neutral, gold, success }

/// One glyph and one figure at the end of a row: the state in the shape of a fact. [label] is its spoken name.
class RowTail extends StatelessWidget {
  const RowTail({required this.icon, required this.label, this.tone = TailTone.neutral, this.figure, super.key});

  final IconData icon;
  final String label;
  final TailTone tone;
  final String? figure;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final color = switch (tone) {
      TailTone.gold => c.textGoldInk,
      TailTone.success => c.textSuccess,
      _ => c.textSecondary,
    };
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(icon, size: GzIconSize.xs, color: color),
          if (figure != null) ...[
            const SizedBox(width: GzSpace.s1),
            GzText(figure!, role: GzTextRole.figBodyS, color: color, figures: true, softWrap: false),
          ],
        ],
      ),
    );
  }
}

/// A whole number of days with the formatter's own unit letter (`57 d`, Arabic `57 ي`): the countdown to a confirmed event.
String dayCountText(GzFormat f, int days) {
  final unit = RegExp(r'[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+').firstMatch(f.duration(86400000))?.group(0) ?? '';
  return '${f.integer(days)} $unit';
}

/// `HH:MM` venue-local time on a civil date as an instant the formatter understands.
DateTime clockInstant(GzFormat f, LocalDate date, LocalTime t) => f.kuwaitDate(date.year, date.month, date.day, hour: t.hour, minute: t.minute);

/// `9:00 PM - 2:00 AM`: a session on a civil date; an end before the start falls on the next day. Two clock times and a dash.
String sessionRange(GzFormat f, LocalDate date, LocalTime start, LocalTime end) {
  final endDate = end.compareTo(start) < 0 ? date.addDays(1) : date;
  return '${f.time(clockInstant(f, date, start))} – ${f.time(clockInstant(f, endDate, end))}';
}
