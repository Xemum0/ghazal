// Pure helpers of the Settings flow (web `settings/_components/model.ts`): what each staff role may open from More, the notification types by
// role, the weekly hours model, the billing status of a partner and the hero constants. No formatting happens here (every number, date and time
// reaches a screen through the shared formatter). Voucher model (ADR 0033): there is no bank, payout or revenue.
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show AdPlanCycle, BillingView, BusinessHours, HoursRule, LocalDate, LocalTime, PartnerBillingMode, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart' show GzIcons;
import 'package:flutter/widgets.dart' show IconData;

/// The conversation of Ghazal Support of the hero venue (the web `conv-support-aurelia`).
const String kSupportConversationId = 'conv-support-aurelia';

/// What a role can open from More. Hidden, never locked.
final class Access {
  const Access({
    this.venue = false,
    this.media = false,
    this.voucherPrices = false,
    this.availability = false,
    this.analytics = false,
    this.reviews = false,
    this.staff = false,
    this.visits = false,
    this.listings = false,
    this.billing = Level.none,
    this.hours = Level.none,
    this.accountType = false,
  });

  final bool venue, media, voucherPrices, availability, analytics, reviews, staff, visits, listings, accountType;
  final Level billing;
  final Level hours;
}

enum Level { none, view, edit }

const Map<StaffRole, Access> kAccess = {
  StaffRole.admin: Access(
    venue: true,
    media: true,
    voucherPrices: true,
    availability: true,
    analytics: true,
    reviews: true,
    staff: true,
    visits: true,
    listings: true,
    billing: Level.edit,
    hours: Level.edit,
    accountType: true,
  ),
  StaffRole.manager: Access(
    venue: true,
    media: true,
    voucherPrices: true,
    availability: true,
    analytics: true,
    reviews: true,
    visits: true,
    listings: true,
    billing: Level.edit,
    hours: Level.view,
    accountType: true,
  ),
  StaffRole.reception: Access(visits: true),
  StaffRole.accountant: Access(billing: Level.view),
  StaffRole.marketing: Access(media: true, voucherPrices: true, analytics: true, listings: true),
};

Access accessOf(StaffRole role) => kAccess[role] ?? const Access();

/// The four roles an Admin can hand out from the app (Admin itself is never assigned here, ADR 0008 D12).
const List<StaffRole> kAssignable = [StaffRole.manager, StaffRole.reception, StaffRole.accountant, StaffRole.marketing];

/// What a role may open, as glyphs; `muted` is read only.
typedef RoleGlyph = ({IconData icon, bool muted});

const Map<StaffRole, List<RoleGlyph>> kRoleGlyphs = {
  StaffRole.manager: [
    (icon: GzIcons.clipboard, muted: false),
    (icon: GzIcons.scan, muted: false),
    (icon: GzIcons.door, muted: false),
    (icon: GzIcons.megaphone, muted: false),
    (icon: GzIcons.receipt, muted: false),
    (icon: GzIcons.chartLine, muted: false),
  ],
  StaffRole.reception: [
    (icon: GzIcons.clipboard, muted: false),
    (icon: GzIcons.scan, muted: false),
    (icon: GzIcons.door, muted: false),
    (icon: GzIcons.chatText, muted: false),
  ],
  StaffRole.accountant: [(icon: GzIcons.receipt, muted: false), (icon: GzIcons.clipboard, muted: true)],
  StaffRole.marketing: [
    (icon: GzIcons.ticket, muted: false),
    (icon: GzIcons.megaphone, muted: false),
    (icon: GzIcons.chartLine, muted: false),
    (icon: GzIcons.image, muted: false),
  ],
};

// ------------------------------------------------------------------------------------------------ notification types

enum NotifType { newRequest, confirmations, cancelled, redemptions, visits, messages, reviews, listing, plan }

const Map<NotifType, List<StaffRole>> kNotifRoles = {
  NotifType.newRequest: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.confirmations: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.cancelled: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.redemptions: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.visits: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.messages: [StaffRole.admin, StaffRole.manager, StaffRole.reception],
  NotifType.reviews: [StaffRole.admin, StaffRole.manager, StaffRole.marketing],
  NotifType.listing: [StaffRole.admin, StaffRole.manager, StaffRole.marketing],
  NotifType.plan: [StaffRole.admin, StaffRole.manager, StaffRole.accountant],
};

const Map<NotifType, IconData> kNotifGlyph = {
  NotifType.newRequest: GzIcons.bell,
  NotifType.confirmations: GzIcons.checkCircle,
  NotifType.cancelled: GzIcons.calendarX,
  NotifType.redemptions: GzIcons.ticket,
  NotifType.visits: GzIcons.door,
  NotifType.messages: GzIcons.chatText,
  NotifType.reviews: GzIcons.star,
  NotifType.listing: GzIcons.megaphone,
  NotifType.plan: GzIcons.timer,
};

/// A service provider has no visits and no venue reviews.
const List<NotifType> kProviderHidden = [NotifType.visits, NotifType.reviews];

/// The alert groups: four quiet blocks with space between them instead of headings.
const List<List<NotifType>> kNotifGroups = [
  [NotifType.newRequest, NotifType.confirmations, NotifType.cancelled],
  [NotifType.redemptions, NotifType.visits],
  [NotifType.messages, NotifType.reviews],
  [NotifType.listing, NotifType.plan],
];

// ------------------------------------------------------------------------------------------------ billing

/// Reminders at 7 and 1 days (PA-ADS-05).
const int kExpiryWarnDays = 7;

enum BillingStatus { exempt, active, expiring, expired, none, contract }

final class Billing {
  const Billing({required this.status, this.cycle, this.endsOn, this.daysLeft});

  final BillingStatus status;
  final AdPlanCycle? cycle;
  final LocalDate? endsOn;
  final int? daysLeft;
}

/// The plan status of the active account from `getPartnerBilling` and today.
Billing billingOf(BillingView b, LocalDate today) {
  if (b.majorHotel || b.feeExempt) return const Billing(status: BillingStatus.exempt);
  if (b.mode == PartnerBillingMode.contract) return const Billing(status: BillingStatus.contract);
  final cycle = b.plan?.cycle;
  final endsOn = b.plan?.endsOn;
  if (cycle == null || endsOn == null) return const Billing(status: BillingStatus.none);
  final left = today.daysUntil(endsOn);
  if (left < 0) return Billing(status: BillingStatus.expired, cycle: cycle, endsOn: endsOn, daysLeft: left);
  if (left <= kExpiryWarnDays) return Billing(status: BillingStatus.expiring, cycle: cycle, endsOn: endsOn, daysLeft: left);
  return Billing(status: BillingStatus.active, cycle: cycle, endsOn: endsOn, daysLeft: left);
}

// ------------------------------------------------------------------------------------------------ weekly hours

typedef DayHours = ({bool open, String from, String to});

/// The seven rows of the fixture's rules (days not covered by a rule are closed). Index 0 is Sunday.
List<DayHours> weekFrom(BusinessHours hours) => [
  for (var d = 0; d < 7; d++)
    () {
      final rule = hours.rules.where((r) => r.days.contains(d)).firstOrNull;
      return rule == null ? (open: false, from: '09:00', to: '22:00') : (open: true, from: rule.open.toString(), to: rule.close.toString());
    }(),
];

/// The rules the week saves as: consecutive days with the same hours share one rule.
List<HoursRule> rulesFrom(List<DayHours> week) {
  final byKey = <String, List<int>>{};
  for (var d = 0; d < 7; d++) {
    if (week[d].open) byKey.putIfAbsent('${week[d].from}|${week[d].to}', () => []).add(d);
  }
  return [
    for (final e in byKey.entries) HoursRule(days: e.value, open: LocalTime.parse(e.key.split('|').first), close: LocalTime.parse(e.key.split('|').last)),
  ];
}

/// Same opening and closing minute: the one input mistake (a later opening than closing runs past midnight and is fine).
bool isInvalidDay(DayHours d) => d.open && d.from == d.to;

bool sameWeek(List<DayHours> a, List<DayHours> b) {
  for (var d = 0; d < 7; d++) {
    if (a[d].open != b[d].open) return false;
    if (a[d].open && (a[d].from != b[d].from || a[d].to != b[d].to)) return false;
  }
  return true;
}

typedef HoursRun = ({int first, int last, int count, bool open, String from, String to});

/// Consecutive days with the same hours become one line: Sun to Thu, Fri and Sat.
List<HoursRun> runsOf(List<DayHours> week) {
  final runs = <HoursRun>[];
  for (var d = 0; d < 7; d++) {
    final day = week[d];
    final last = runs.isEmpty ? null : runs.last;
    if (last != null && last.open == day.open && (!day.open || (last.from == day.from && last.to == day.to))) {
      runs[runs.length - 1] = (first: last.first, last: d, count: last.count + 1, open: last.open, from: last.from, to: last.to);
    } else {
      runs.add((first: d, last: d, count: 1, open: day.open, from: day.from, to: day.to));
    }
  }
  return runs;
}

/// The part of the day a clock reading falls in, drawn as a glyph beside the figure: sun 05:00-15:59, sunset 16:00-18:59, moon the rest.
IconData dayPartOf(String hhmm) {
  final hour = int.parse(hhmm.split(':').first);
  if (hour >= 5 && hour < 16) return GzIcons.sun;
  if (hour >= 16 && hour < 19) return GzIcons.sunset;
  return GzIcons.moon;
}

/// 12-hour pieces of an `HH:MM` (the custom time sheet works in these).
({int hour, int minute, bool pm}) splitClock(String hhmm) {
  final p = hhmm.split(':').map(int.parse).toList();
  return (hour: p[0] % 12 == 0 ? 12 : p[0] % 12, minute: p[1], pm: p[0] >= 12);
}

String joinClock(int hour, int minute, bool pm) {
  final h24 = (hour % 12) + (pm ? 12 : 0);
  return '${h24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const List<int> kMinutes = [0, 15, 30, 45];
const List<int> kHours12 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/// `HH:MM` as an instant on a fixed Kuwait day; only its clock reading is ever shown.
DateTime clockAt(GzFormat f, String hhmm) {
  final p = hhmm.split(':').map(int.parse).toList();
  return f.kuwaitDate(2026, 11, 15, hour: p[0], minute: p[1]);
}

/// The figure of a clock reading without its AM or PM marker (the marker is a glyph on screen and part of the accessible name).
String figureOf(GzFormat f, String hhmm) => f.time(clockAt(f, hhmm)).split(RegExp('[   ]')).first;

/// A closure the week keeps (the fixture's Ramadan and Eids, or one the person adds).
typedef Closure = ({String id, String en, String ar, LocalDate from, LocalDate to, bool approximate});

/// The two Eids offered as adjustable approximate closures (HA-SET-04); they stay marked approximate until announced.
final List<Closure> kSuggestedClosures = [
  (id: 'eid-fitr-1448', en: 'Eid al-Fitr', ar: 'عيد الفطر', from: LocalDate(2027, 3, 9), to: LocalDate(2027, 3, 11), approximate: true),
  (id: 'eid-adha-1448', en: 'Eid al-Adha', ar: 'عيد الأضحى', from: LocalDate(2027, 5, 16), to: LocalDate(2027, 5, 19), approximate: true),
];
