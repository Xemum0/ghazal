// The model of the Bookings tab (web `bookings/_components/model.ts`): which request sits in which segment, the Past chip groups, the date-range
// filter and the search matching. Pure functions over the contract models; nothing here formats a number or a date for display.
import 'package:ghazal_domain/ghazal_domain.dart';

enum BookingSegment { pending, upcoming, past }

enum PastFilter { all, completed, cancelled, declined, expired }

enum DateField { event, request }

/// A closed range of civil days (`YYYY-MM-DD`); a null [start] means no filter.
class FilterRange {
  const FilterRange({this.start, this.end});

  static const FilterRange none = FilterRange();

  final String? start;
  final String? end;

  bool get applied => start != null;

  @override
  bool operator ==(Object other) => other is FilterRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Which Past chip a booking answers to: Expired covers the venue's own silence (Missed) and the client's (Lapsed).
PastFilter pastGroupOf(Booking b) => switch (b.status) {
  BookingStatus.completed => PastFilter.completed,
  BookingStatus.cancelled => PastFilter.cancelled,
  BookingStatus.declined => PastFilter.declined,
  _ => PastFilter.expired,
};

/// The last thing that happened to a booking (most recent first in Past).
DateTime lastEventAt(Booking b) => b.events.isEmpty ? b.createdAt : b.events.last.at;

/// The rows of the five lists of the tab.
class BookingsSplit {
  const BookingsSplit({
    this.pending = const <PartnerRequestRow>[],
    this.waiting = const <PartnerRequestRow>[],
    this.awaiting = const <PartnerRequestRow>[],
    this.confirmed = const <PartnerRequestRow>[],
    this.redeemed = const <PartnerRequestRow>[],
    this.past = const <PartnerRequestRow>[],
  });

  /// Waiting for the venue, nearest deadline first.
  final List<PartnerRequestRow> pending;

  /// A counter-offer is out: waiting for the couple.
  final List<PartnerRequestRow> waiting;

  /// Approved: the client has 24 hours, earliest deadline first.
  final List<PartnerRequestRow> awaiting;
  final List<PartnerRequestRow> confirmed;
  final List<PartnerRequestRow> redeemed;
  final List<PartnerRequestRow> past;

  List<PartnerRequestRow> get all => [...pending, ...waiting, ...awaiting, ...confirmed, ...redeemed, ...past];

  BookingsSplit filtered(bool Function(PartnerRequestRow) keep) => BookingsSplit(
    pending: pending.where(keep).toList(),
    waiting: waiting.where(keep).toList(),
    awaiting: awaiting.where(keep).toList(),
    confirmed: confirmed.where(keep).toList(),
    redeemed: redeemed.where(keep).toList(),
    past: past.where(keep).toList(),
  );
}

BookingsSplit splitRows(Iterable<PartnerRequestRow> rows) {
  final seen = <String>{};
  final all = [
    for (final r in rows)
      if (seen.add(r.booking.id)) r,
  ];
  int byDate(PartnerRequestRow a, PartnerRequestRow b) => a.booking.eventDate.compareTo(b.booking.eventDate);
  List<PartnerRequestRow> of(bool Function(Booking) test) => all.where((r) => test(r.booking)).toList();
  final pending = of((b) => b.status == BookingStatus.pending && b.proposal == null)
    ..sort((a, b) => (a.sla?.minutesLeft ?? 1 << 30).compareTo(b.sla?.minutesLeft ?? 1 << 30));
  final awaiting = of((b) => b.status == BookingStatus.approved)
    ..sort((a, b) => (a.booking.confirmBy ?? DateTime(0)).compareTo(b.booking.confirmBy ?? DateTime(0)));
  const open = {BookingStatus.pending, BookingStatus.approved, BookingStatus.confirmed, BookingStatus.redeemed};
  return BookingsSplit(
    pending: pending,
    waiting: of((b) => b.status == BookingStatus.pending && b.proposal != null),
    awaiting: awaiting,
    confirmed: of((b) => b.status == BookingStatus.confirmed)..sort(byDate),
    redeemed: of((b) => b.status == BookingStatus.redeemed)..sort(byDate),
    past: of((b) => !open.contains(b.status))..sort((a, b) => lastEventAt(b.booking).compareTo(lastEventAt(a.booking))),
  );
}

/// Is the booking inside the range (by event day or by request day)?
bool inRange(Booking b, FilterRange range, DateField field) {
  final start = range.start;
  if (start == null) return true;
  final day = field == DateField.event ? b.eventDate.toString() : b.createdAt.toUtc().add(const Duration(hours: 3)).toIso8601String().substring(0, 10);
  final end = range.end ?? start;
  return day.compareTo(start) >= 0 && day.compareTo(end) <= 0;
}

// ---------------------------------------------------------------- search (client name in either script, reference, or a typed date)

final RegExp _alef = RegExp('[آأإٱ]');

/// Folds a string for matching without changing its length: lower case, alef variants, ya and ta marbuta, Eastern digits.
String foldText(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().replaceAll(_alef, 'ا').runes) {
    if (r == 0x0649) {
      out.write('ي');
    } else if (r == 0x0629) {
      out.write('ه');
    } else if (r >= 0x0660 && r <= 0x0669) {
      out.write(r - 0x0660);
    } else if (r >= 0x06f0 && r <= 0x06f9) {
      out.write(r - 0x06f0);
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

String cleanQuery(String q) => foldText(q.trim().replaceAll('ـ', '').replaceAll(RegExp(r'\s+'), ' '));

const List<List<String>> _monthsEn = [
  ['january', 'jan'], ['february', 'feb'], ['march', 'mar'], ['april', 'apr'], ['may'], ['june', 'jun'],
  ['july', 'jul'], ['august', 'aug'], ['september', 'sep', 'sept'], ['october', 'oct'], ['november', 'nov'], ['december', 'dec'],
];
const List<List<String>> _monthsAr = [
  ['يناير'], ['فبراير'], ['مارس'], ['ابريل', 'أبريل'],
  ['مايو'], ['يونيو'], ['يوليو'], ['اغسطس', 'أغسطس'],
  ['سبتمبر'], ['اكتوبر', 'أكتوبر'], ['نوفمبر'], ['ديسمبر'],
];

/// `14 Jan`, `14 يناير`, `14/1`, `Jan`, `14`: a day, a month, or both (month names in both scripts).
({int? day, int? month})? parseDateQuery(String raw) {
  final q = cleanQuery(raw);
  if (q.isEmpty) return null;
  int? month;
  var rest = q;
  for (var m = 1; m <= 12 && month == null; m++) {
    for (final names in [_monthsEn[m - 1], _monthsAr[m - 1]]) {
      for (final name in names) {
        final key = foldText(name);
        if (key.isNotEmpty && rest.contains(key)) {
          month = m;
          rest = rest.replaceFirst(key, ' ').trim();
          break;
        }
      }
      if (month != null) break;
    }
  }
  final slash = RegExp(r'^(\d{1,2})[/.-](\d{1,2})$').firstMatch(rest);
  if (slash != null) return (day: int.parse(slash.group(1)!), month: int.parse(slash.group(2)!));
  final num = RegExp(r'^\d{1,2}$').firstMatch(rest);
  final day = num == null ? null : int.parse(num.group(0)!);
  if (month == null && day == null) return null;
  if (rest.isNotEmpty && day == null && month != null && rest.replaceAll(RegExp(r'\s'), '').isNotEmpty) return null;
  return (day: day, month: month);
}

({bool name, bool ref, bool date})? matchBooking(Booking b, String raw) {
  final q = cleanQuery(raw);
  if (q.isEmpty) return null;
  final name = foldText(b.clientName).contains(q);
  final refQuery = q.replaceFirst(RegExp(r'^gz-?'), '').replaceAll('-', '');
  final ref = refQuery.length >= 2 && foldText(b.ref).replaceAll('-', '').contains(refQuery);
  final dq = parseDateQuery(raw);
  var date = false;
  if (dq != null) {
    date = (dq.day == null || dq.day == b.eventDate.day) && (dq.month == null || dq.month == b.eventDate.month);
  }
  return name || ref || date ? (name: name, ref: ref, date: date) : null;
}

/// Splits [text] around the first folded occurrence of [query] so a row can set the match in weight 700.
(String, String, String)? splitHit(String text, String query) {
  final q = cleanQuery(query);
  if (q.isEmpty) return null;
  final folded = foldText(text);
  final i = folded.indexOf(q);
  if (i < 0 || folded.length != text.length) return null;
  return (text.substring(0, i), text.substring(i, i + q.length), text.substring(i + q.length));
}

/// One precision per list: exact three decimals when any amount shown has fils, otherwise the browse format.
bool exactMoney(Iterable<int> fils) => fils.any((a) => a % 1000 != 0);
