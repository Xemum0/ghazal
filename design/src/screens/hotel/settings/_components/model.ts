// Pure helpers of the Settings flow: the account the viewer works in (hotel or hall, major hotel, service provider), roles and what each
// role may open from More, the billing status of a partner, the weekly hours model and the notification types by role. No formatting happens
// here (every number, date and time reaches the screen through useFormat()). Voucher model (ADR 0033): there is no bank, payout or revenue.
import type { IconName } from '@gz/tokens'
import type { AdPlanCycle, BusinessHours, Listing, StaffRole } from '../../../../mock'

// ---------------------------------------------------------------- the account (ADR 0033 D7)

/** `venue` = a hotel or hall (Aurelia, major, or a non-major hotel); `provider` = a service provider (Zahra Floral Studio). */
export type AccountType = 'venue' | 'provider'

export type Account = {
  type: AccountType
  /** Major hotel: exempt from listing fees (owner rule). Never true for a provider. */
  major: boolean
}

// ---------------------------------------------------------------- roles (ADR 0008 D12, ADR 0033)

export type SettingsRole = StaffRole

/** What a role can open from More. Hidden, never locked. */
export type Access = {
  venue: boolean
  /** Photos are for marketing too. */
  media: boolean
  /** Voucher prices (HL-GROW-01). */
  voucherPrices: boolean
  availability: boolean
  analytics: boolean
  reviews: boolean
  staff: boolean
  /** Visit requests and visit availability (reception handles visits). */
  visits: boolean
  /** Listings and listing performance (a provider's own, or a hotel that also lists). */
  listings: boolean
  /** `view` = Accountant (receipts, read-only); `edit` = Admin and Manager (plan chooser). */
  billing: 'none' | 'view' | 'edit'
  /** `view` = Manager; `edit` = Admin. */
  hours: 'none' | 'view' | 'edit'
  /** Switching or adding an account type is for the people who run the account. */
  accountType: boolean
}

const NONE: Access = { venue: false, media: false, voucherPrices: false, availability: false, analytics: false, reviews: false, staff: false, visits: false, listings: false, billing: 'none', hours: 'none', accountType: false }

export const ACCESS: Record<SettingsRole, Access> = {
  admin: { venue: true, media: true, voucherPrices: true, availability: true, analytics: true, reviews: true, staff: true, visits: true, listings: true, billing: 'edit', hours: 'edit', accountType: true },
  manager: { venue: true, media: true, voucherPrices: true, availability: true, analytics: true, reviews: true, staff: false, visits: true, listings: true, billing: 'edit', hours: 'view', accountType: true },
  reception: { ...NONE, visits: true },
  accountant: { ...NONE, billing: 'view' },
  marketing: { ...NONE, media: true, voucherPrices: true, analytics: true, listings: true },
}

/** The role a frame state draws (live prototype: the all-access owner view, see the flow notes). */
export function roleOfState(state: string | undefined): SettingsRole {
  switch (state) {
    case 'role-reception':
      return 'reception'
    case 'role-accountant':
    case 'role-limited':
    case 'role-view-only':
      return 'accountant'
    case 'role-marketing':
      return 'marketing'
    case 'role-manager':
      return 'manager'
    default:
      return 'admin'
  }
}

/** The four roles an Admin can hand out from the app (Admin itself is never assigned here, ADR 0008 D12). */
export const ASSIGNABLE: readonly Exclude<SettingsRole, 'admin'>[] = ['manager', 'reception', 'accountant', 'marketing']

/**
 * What a role may open, as glyphs (text diet: the plain-words line of each role lives behind the (i) of the staff screen and is the
 * accessible name of the strip). Requests, redeeming, visits, chat, listings, billing, analytics, voucher prices, photos. `muted` = read only.
 */
export type RoleGlyph = { icon: IconName; muted?: boolean }
export const ROLE_GLYPHS: Record<Exclude<SettingsRole, 'admin'>, readonly RoleGlyph[]> = {
  manager: [{ icon: 'clipboard' }, { icon: 'scan' }, { icon: 'door' }, { icon: 'megaphone' }, { icon: 'receipt' }, { icon: 'chart-line' }],
  reception: [{ icon: 'clipboard' }, { icon: 'scan' }, { icon: 'door' }, { icon: 'chat-text' }],
  accountant: [{ icon: 'receipt' }, { icon: 'clipboard', muted: true }],
  marketing: [{ icon: 'ticket' }, { icon: 'megaphone' }, { icon: 'chart-line' }, { icon: 'image' }],
}

// ---------------------------------------------------------------- billing and fees (HL-SETT-04)

/** Reminders at -7 and -1 days (PA-ADS-05). */
export const EXPIRY_WARN_DAYS = 7

export type BillingStatus = 'exempt' | 'active' | 'expiring' | 'expired' | 'none'

export type Billing = {
  status: BillingStatus
  cycle: AdPlanCycle | null
  endsOn: string | null
  /** Whole days left, or null without a period. */
  daysLeft: number | null
  /** A listing needs changes (rejected): the More tab shows its dot for this too. */
  needsChanges: boolean
}

/** Plan status from a period end and today: the plan of the live listing (a provider) or the plan on the account (a hotel). */
export function billingOf(args: { major: boolean; cycle: AdPlanCycle | null; endsOn: string | null; daysLeft: number | null; ended: boolean; needsChanges: boolean }): Billing {
  const { major, cycle, endsOn, daysLeft, ended, needsChanges } = args
  if (major) return { status: 'exempt', cycle: null, endsOn: null, daysLeft: null, needsChanges }
  if (!cycle || !endsOn) return { status: ended ? 'expired' : 'none', cycle, endsOn, daysLeft, needsChanges }
  if (ended || (daysLeft !== null && daysLeft < 0)) return { status: 'expired', cycle, endsOn, daysLeft, needsChanges }
  if (daysLeft !== null && daysLeft <= EXPIRY_WARN_DAYS) return { status: 'expiring', cycle, endsOn, daysLeft, needsChanges }
  return { status: 'active', cycle, endsOn, daysLeft, needsChanges }
}

/** The listing that carries a provider's plan: the live one, else the most recently ended. */
export function planListing(listings: readonly Listing[]): Listing | undefined {
  return listings.find(l => l.status === 'active') ?? [...listings].filter(l => l.status === 'expired').sort((a, b) => (b.endsOn ?? '').localeCompare(a.endsOn ?? ''))[0]
}

// ---------------------------------------------------------------- weekly hours (HA-SET-04)

export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6
export const WEEK: readonly Weekday[] = [0, 1, 2, 3, 4, 5, 6]

export type DayHours = { open: boolean; from: string; to: string }
export type Week = Record<Weekday, DayHours>

export type Closure = { id: string; label: { en: string; ar: string }; from: string; to: string; approximate: boolean }

/** The seven rows from the fixture's rules (days not covered by a rule are closed). */
export function weekFrom(hours: BusinessHours): Week {
  const week = {} as Week
  for (const d of WEEK) {
    const rule = hours.rules.find(r => r.days.includes(d))
    week[d] = rule ? { open: true, from: rule.open, to: rule.close } : { open: false, from: '09:00', to: '22:00' }
  }
  return week
}

/** Same opening and closing minute: the one input mistake (a later opening than closing runs past midnight and is fine). */
export const isInvalidDay = (d: DayHours): boolean => d.open && d.from === d.to

export const sameWeek = (a: Week, b: Week): boolean => WEEK.every(d => a[d].open === b[d].open && (!a[d].open || (a[d].from === b[d].from && a[d].to === b[d].to)))

export type HoursRun = { first: Weekday; last: Weekday; count: number; open: boolean; from: string; to: string }

/** Consecutive days with the same hours become one line: Sun to Thu, Fri and Sat. */
export function runsOf(week: Week): HoursRun[] {
  const runs: HoursRun[] = []
  for (const d of WEEK) {
    const day = week[d]
    const last = runs[runs.length - 1]
    if (last && last.open === day.open && (!day.open || (last.from === day.from && last.to === day.to))) {
      last.last = d
      last.count += 1
    } else {
      runs.push({ first: d, last: d, count: 1, open: day.open, from: day.from, to: day.to })
    }
  }
  return runs
}

/**
 * The part of the day a clock reading falls in, drawn as a glyph beside the figure instead of the AM or PM word: sun (05:00 to 15:59),
 * sunset (16:00 to 18:59), moon (19:00 to 04:59). For any 12-hour figure the AM and the PM reading never share a glyph.
 */
export type DayPart = 'sun' | 'sunset' | 'moon'
export function dayPartOf(hhmm: string): DayPart {
  const hour = Number(hhmm.split(':')[0])
  if (hour >= 5 && hour < 16) return 'sun'
  if (hour >= 16 && hour < 19) return 'sunset'
  return 'moon'
}

/** 12-hour pieces of an `HH:MM` (the custom time sheet works in these). */
export function splitClock(hhmm: string): { hour: number; minute: number; pm: boolean } {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return { hour: h % 12 === 0 ? 12 : h % 12, minute: m, pm: h >= 12 }
}

export function joinClock(hour: number, minute: number, pm: boolean): string {
  const h24 = (hour % 12) + (pm ? 12 : 0)
  return `${String(h24).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
}

export const MINUTES: readonly number[] = [0, 15, 30, 45]
export const HOURS_12: readonly number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

/**
 * The two Eids offered as adjustable approximate closures (the Ramadan range comes from the fixture). Dates are the astronomical
 * estimates for 1448 and stay marked approximate until the country announces them (HA-SET-04).
 */
export const SUGGESTED_CLOSURES: readonly Closure[] = [
  { id: 'eid-fitr-1448', label: { en: 'Eid al-Fitr', ar: 'عيد الفطر' }, from: '2027-03-09', to: '2027-03-11', approximate: true },
  { id: 'eid-adha-1448', label: { en: 'Eid al-Adha', ar: 'عيد الأضحى' }, from: '2027-05-16', to: '2027-05-19', approximate: true },
]

// ---------------------------------------------------------------- notification types by role (HA-NOTI-08, ADR 0008 D12, ADR 0033)

export type NotifType = 'newRequest' | 'confirmations' | 'cancelled' | 'redemptions' | 'visits' | 'messages' | 'reviews' | 'listing' | 'plan'

/** Who can receive which alert. A type a role cannot receive is hidden. New requests are on and fixed for the roles that act on requests. */
export const NOTIF_ROLES: Record<NotifType, readonly SettingsRole[]> = {
  newRequest: ['admin', 'manager', 'reception'],
  confirmations: ['admin', 'manager', 'reception'],
  cancelled: ['admin', 'manager', 'reception'],
  redemptions: ['admin', 'manager', 'reception'],
  visits: ['admin', 'manager', 'reception'],
  messages: ['admin', 'manager', 'reception'],
  reviews: ['admin', 'manager', 'marketing'],
  listing: ['admin', 'manager', 'marketing'],
  plan: ['admin', 'manager', 'accountant'],
}

/** One glyph per alert type (the title stays one word; the sentence about when it fires is behind the (i)). */
export const NOTIF_GLYPH: Record<NotifType, IconName> = {
  newRequest: 'bell',
  confirmations: 'check-circle',
  cancelled: 'calendar-x',
  redemptions: 'ticket',
  visits: 'door',
  messages: 'chat-text',
  reviews: 'star',
  listing: 'megaphone',
  plan: 'timer',
}

/** A service provider has no visits and no venue reviews. */
export const PROVIDER_HIDDEN: readonly NotifType[] = ['visits', 'reviews']

// ---------------------------------------------------------------- receipts (HL-SETT-04)

export type ReceiptEntry = { number: string; at: string; cycle: AdPlanCycle; fils: number; method: 'knet' | 'card' | 'apple_pay' | 'google_pay'; sample: true }

/**
 * NOT-FOR-RELEASE SAMPLE for the `receipts` frame only. Plan rates are an owner decision (OQ-V-07) and are null in the fixtures, so no real
 * receipt exists yet; the amounts below are the provider flow's labelled sample rates and every row and document says "Sample".
 */
export const sampleReceipts = (rates: Record<AdPlanCycle, number>): ReceiptEntry[] => [
  { number: 'GP-2610-0388', at: '2026-10-12T10:20:00+03:00', cycle: 'monthly', fils: rates.monthly, method: 'knet', sample: true },
  { number: 'GP-2609-0214', at: '2026-09-11T18:05:00+03:00', cycle: 'monthly', fils: rates.monthly, method: 'card', sample: true },
]
