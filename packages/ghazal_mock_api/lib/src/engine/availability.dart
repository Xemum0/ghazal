/// Availability and per-day prices (ADR 0002 D8, ADR 0004 D7). Deterministic: the occupancy of a hall on a date is a pure function of the
/// ids and the date (seed occupancy pattern). Port of engine/availability.ts.
library;

import 'dates.dart';
import 'json.dart';
import 'money.dart';
import 'pricing.dart';
import 'seeded.dart';

class AvailabilityContext {
  AvailabilityContext({
    required this.venue,
    required this.hall,
    required this.packages,
    required this.rules,
    required this.windows,
    required this.claims,
    required this.overrides,
    required this.now,
    required this.voucherFeeFils,
    required this.generate,
  });

  final Json venue;
  final Json hall;
  final List<Json> packages;
  final List<Json> rules;

  /// Time-boxed voucher prices of the venue.
  final List<Json> windows;
  final List<Json> claims;
  final List<Json> overrides;
  final String now;
  final int voucherFeeFils;

  /// Use the seeded occupancy generator for days that no claim or override decides.
  final bool generate;
}

/// Closed for the client: past, or inside the minimum lead time.
const minLeadDays = 2;

const _ramadan = ('2027-02-08', '2027-03-08');
const _eidFitrStrong = ('2027-03-09', '2027-03-21');
const _eidAdhaStrong = ('2027-05-01', '2027-05-19');
const _summer = ('2027-05-20', '2027-09-30');
const _weekdayBase = [0.2, 0.15, 0.15, 0.2, 0.8, 0.74, 0.52];

bool _within(String d, (String, String) r) => d.compareTo(r.$1) >= 0 && d.compareTo(r.$2) <= 0;

/// Probability that a hall is already booked on a date, by weekday, season and venue demand.
double bookedProbability(Json venue, String date) {
  if (_within(date, _ramadan)) return 0.05;
  final wd = weekdayOf(date);
  var p = _weekdayBase[wd];
  final peakNight = wd == 4 || wd == 5 || wd == 6;
  if (_within(date, _summer)) {
    p = peakNight ? 0.28 : 0.08;
  } else if (_within(date, _eidFitrStrong) && peakNight) {
    p = 0.7;
  } else if (_within(date, _eidAdhaStrong) && peakNight) {
    p = 0.82;
  } else if (monthNumber(date) == 10 || (date.compareTo('2027-04-01') >= 0 && date.compareTo('2027-04-30') <= 0)) {
    p *= 0.85;
  }
  final demand = (venue['demand'] as num).toDouble();
  final v = p * demand;
  return v < 0 ? 0 : (v > 0.95 ? 0.95 : v);
}

/// Seeded occupancy of one hall on one date (and, for multi-session halls, one session): `free`, `booked` or `held`.
String generatedOccupancy(Json venue, Json hall, String date, [String? sessionId]) {
  final r = seeded(['occ', hall.str('id'), date, sessionId ?? '-']);
  if (r < bookedProbability(venue, date)) return 'booked';
  final wd = weekdayOf(date);
  final peakNight = wd == 4 || wd == 5 || wd == 6;
  if (peakNight && seeded(['hold', hall.str('id'), date, sessionId ?? '-']) < 0.06) return 'held';
  return 'free';
}

const _occState = {'free': 'available', 'booked': 'unavailable', 'held': 'held'};

/// `{state, reason, sessions}` of a hall on a date. A day is available when at least one session is free.
Json dayDecision(AvailabilityContext ctx, String date) {
  List<Json> allSessions(String state) => [for (final s in ctx.hall.list('sessions')) {'sessionId': s['id'], 'state': state}];
  Json closed(String reason) => {'state': 'closed', 'reason': reason, 'sessions': allSessions('closed')};
  final today = kuwaitDateOf(ctx.now);
  if (date.compareTo(today) < 0) return closed('past');
  if (diffDays(today, date) < minLeadDays) return closed('lead_time');
  final months = ctx.hall['seasonMonths'];
  if (months is List && !months.contains(monthNumber(date))) return closed('out_of_season');

  final hallId = ctx.hall.str('id');
  for (final o in ctx.overrides) {
    if (o['hallId'] == hallId && o['date'] == date) {
      final s = o['state'] == 'available' ? 'available' : (o['state'] == 'held' ? 'held' : 'unavailable');
      return {'state': s, 'reason': s == 'available' ? null : (s == 'held' ? 'held' : 'booked'), 'sessions': allSessions(s)};
    }
  }
  // claims
  Json? decision;
  for (final c in ctx.claims) {
    if (c['hallId'] != hallId || c['date'] != date) continue;
    if (c['kind'] == 'booking') return {'state': 'unavailable', 'reason': 'booked', 'sessions': allSessions('unavailable')};
    if (c['kind'] == 'block') return {'state': 'unavailable', 'reason': 'blocked', 'sessions': allSessions('unavailable')};
    if (c['kind'] == 'hold') decision = {'state': 'held', 'reason': 'held'};
  }
  if (decision != null) return {...decision, 'sessions': allSessions('held')};

  if (ctx.generate) {
    final sessions = ctx.hall.list('sessions');
    final multi = !ctx.hall.flag('exclusiveDay') && sessions.length > 1;
    if (multi) {
      final wd = weekdayOf(date);
      final out = <Json>[
        for (final s in sessions)
          if (!s.ints('weekdays').contains(wd)) {'sessionId': s['id'], 'state': 'closed'} else {'sessionId': s['id'], 'state': _occState[generatedOccupancy(ctx.venue, ctx.hall, date, s.str('id'))]}
      ];
      final open = out.where((x) => x['state'] != 'closed').toList();
      if (open.any((x) => x['state'] == 'available')) return {'state': 'available', 'reason': null, 'sessions': out};
      if (open.any((x) => x['state'] == 'held')) return {'state': 'held', 'reason': 'held', 'sessions': out};
      return {'state': 'unavailable', 'reason': 'booked', 'sessions': out};
    }
    final occ = generatedOccupancy(ctx.venue, ctx.hall, date);
    return {'state': _occState[occ], 'reason': occ == 'booked' ? 'booked' : (occ == 'held' ? 'held' : null), 'sessions': allSessions(_occState[occ]!)};
  }
  return {'state': 'available', 'reason': null, 'sessions': allSessions('available')};
}

/// Lowest eligible package price (both columns) for the date, brief and audience (ADR 0004 D6/D7): `{amount, voucher, packageId, tier}` or null.
/// [brief] keys: `audience`, `guests`.
Json? priceForDay(AvailabilityContext ctx, String date, Json brief) {
  final sections = ctx.hall.list('sections');
  final String audience = (brief['audience'] as String?) ?? (sections.isNotEmpty ? sections.first.str('audience') : 'women');
  final matching = sections.where((s) => s['audience'] == audience);
  if (matching.isEmpty) return null;
  final section = matching.first;
  final hallId = ctx.hall.str('id');
  final eligible = ctx.packages
      .where((pkg) => pkg.flag('active') && pkg['components'] == null && pkg.strings('audiences').contains(audience) && pkg.strings('hallIds').contains(hallId))
      .toList();
  final hasAllIn = eligible.any((p) => p['archetype'] != 'hall_only');
  Json? best;
  for (final pkg in eligible) {
    if (hasAllIn && pkg['archetype'] == 'hall_only') continue;
    final minEff = effectiveMinGuests(pkg, section.integer('minGuests'));
    final guests = (brief['guests'] as num?)?.toInt() ?? minEff;
    final maxG = pkg.integer('maxGuests') < section.integer('maxGuests') ? pkg.integer('maxGuests') : section.integer('maxGuests');
    if (guests > maxG) continue;
    final p = packagePrice(
      pkg: pkg,
      rules: ctx.rules,
      windows: ctx.windows,
      eventDate: date,
      now: ctx.now,
      hallId: hallId,
      guests: guests,
      hallMinGuests: section.integer('minGuests'),
      serviceChargeBps: ctx.venue.obj('policies').integer('serviceChargeBps'),
      voucherFeeFils: ctx.voucherFeeFils,
    );
    if (p == null) continue;
    if (best == null || filsOf(p.obj('standard')) < filsOf(best.obj('amount'))) {
      best = {'amount': p['standard'], 'voucher': p.flag('voucherEligible') ? p['voucher'] : null, 'packageId': pkg['id'], 'tier': p['tier']};
    }
  }
  return best;
}

String _fallbackTier(String date) {
  final wd = weekdayOf(date);
  return wd == 4 || wd == 5 || wd == 6 ? 'weekend' : 'weekday';
}

/// One month of one hall (days as `AvailabilityDay`, plus `internalReason`). Government halls (external channel) have no live availability: [].
List<Json> availabilityFor(AvailabilityContext ctx, String month, [Json brief = const {}]) {
  if (ctx.venue['channel'] == 'external_link') return [];
  return [
    for (final date in datesInMonth(month))
      () {
        final day = dayDecision(ctx, date);
        final price = day['state'] == 'closed' ? null : priceForDay(ctx, date, brief);
        return <String, dynamic>{
          'date': date,
          'hallId': ctx.hall['id'],
          'state': day['state'],
          'tier': price != null ? price['tier'] : _fallbackTier(date),
          'sessions': day['sessions'],
          'fromPrice': price?['amount'],
          'voucherPrice': price?['voucher'],
          'packageId': price?['packageId'],
          'internalReason': day['reason'],
        };
      }()
  ];
}

/// True when the date can take a request: at least one session of the hall is free or merely held (ADR 0002 D8).
bool isRequestable(Json day) => day['state'] == 'available' || day['state'] == 'held';

/// Rule used for a package on a date, exposed for tests.
Json? ruleFor(AvailabilityContext ctx, String packageId, String date) => resolveRule(ctx.rules, packageId, date);
