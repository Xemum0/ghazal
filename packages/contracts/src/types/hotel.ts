import type { Audience, Bilingual, Id, IsoDate, IsoDateTime, Lang, LocalTime, Money } from './common.ts'
import type { BusinessHours } from './venue.ts'

// ---------------------------------------------------------------- staff

export type StaffRole = 'admin' | 'manager' | 'reception' | 'accountant' | 'marketing'

export interface HotelStaff {
  id: Id
  userId: Id
  venueId: Id
  name: string
  nameLatin: string
  monogram: string
  role: StaffRole
  roleLabel: Bilingual
  roleSummary: Bilingual
  phone: string
  status: 'active' | 'invited' | 'deactivated'
  uiLang: Lang
  lastSeenAt: IsoDateTime | null
  invitedAt: IsoDateTime | null
  inviteExpiresAt: IsoDateTime | null
  invitedBy: string | null
  /** The signed-in demo user. */
  isYou: boolean
}

export interface VenueMembership {
  userId: Id
  venueId: Id
  role: StaffRole
  pendingRequests: number
}

// ---------------------------------------------------------------- triage (Today, Needs you)

export type TriageType =
  | 'request'
  /** Approved and waiting for the client's 24 h confirmation (carries the confirm countdown). */
  | 'awaiting_client'
  | 'visit_request'
  | 'message'
  | 'review_reply'
  | 'calendar_confirm'

/** One row of the Needs-you queue (ADR 0008 D4). The SLA state is computed from `raisedAt`, `dueAt` and the clock. */
export interface RequestItem {
  id: Id
  type: TriageType
  venueId: Id
  /** When the item entered the queue (request received, message sent, review posted). */
  raisedAt: IsoDateTime
  /** Deadline: reply-by for requests, confirm-by for `awaiting_client`, null for items without an SLA. */
  dueAt: IsoDateTime | null
  slaHours: number | null
  bookingId: Id | null
  conversationId: Id | null
  reviewId: Id | null
  visitId: Id | null
  /** The voucher bound to the request (carried on request and awaiting_client rows: code chip and voucher price). */
  voucherId: Id | null
  /** Voucher code as shown in the chip (GV-2611-K7QM), LTR isolate. */
  voucherCode: string | null
  /** Headline for non-request rows; request rows are built from the booking. */
  title: Bilingual
  subtitle: Bilingual | null
  /** Manual sort hint after the deadline order (requests first, then these). */
  order: number
}

export type SlaState = 'neutral' | 'gold' | 'danger' | 'expired'

// ---------------------------------------------------------------- calendar

export type ClaimKind = 'booking' | 'hold' | 'block' | 'requested'
export type BlockReason = 'offline_booking' | 'maintenance' | 'private_event' | 'other'

/** What the hotel calendar paints for one hall on one date. Requests never claim (ADR 0001 D5): 'requested' is informational. */
export interface CalendarClaim {
  id: Id
  venueId: Id
  hallId: Id
  date: IsoDate
  kind: ClaimKind
  bookingId: Id | null
  audience: Audience | null
  guests: number | null
  clientName: string | null
  blockReason: BlockReason | null
  blockNote: Bilingual | null
  blockedBy: string | null
  /** Hold timer for kind 'hold'. */
  holdUntil: IsoDateTime | null
  start: LocalTime | null
  end: LocalTime | null
}

export interface DayOverride {
  venueId: Id
  hallId: Id
  date: IsoDate
  /** Force a day open (soft dates, demo dates) or leave the generator alone. */
  state: 'available' | 'unavailable' | 'held'
  reason: string
}

// ---------------------------------------------------------------- analytics

export type KpiId = 'views' | 'clicks' | 'requests' | 'vouchers_bought' | 'vouchers_redeemed' | 'conversion'

export interface KpiPoint {
  date: IsoDate
  /** Counts, or basis points of a percent for conversion (92 = 0.92%). */
  value: number
}

export interface KpiSeries {
  id: KpiId
  unit: 'count' | 'percent'
  points: KpiPoint[]
}

export interface TopPackage {
  packageId: Id
  /** Requests that reached `confirmed` or `redeemed` on this package this month. */
  confirmed: number
}

/** Voucher tiles of Today and analytics (ADR 0033 D7): requests, vouchers redeemed this month, open dates. There is no revenue. */
export interface Analytics {
  venueId: Id
  /** The range the tiles describe ('This month', 1 Nov - 12 Nov 2026). */
  range: { from: IsoDate; to: IsoDate; label: Bilingual }
  /** The 30-day window that every series covers. */
  window: { from: IsoDate; to: IsoDate }
  tiles: {
    views: { value: number; deltaPct: number }
    clicks: number
    requests: number
    approved: number
    confirmed: number
    vouchersBought: number
    vouchersRedeemed: number
    openDatesNext30Days: number
    /** Basis points of a percent: 93 = 0.93%, displayed 0.9%. */
    conversionBps: number
  }
  funnel: { views: number; clicks: number; requests: number; confirmed: number; redeemed: number }
  topPackages: TopPackage[]
  series: KpiSeries[]
}

// ---------------------------------------------------------------- settings

export interface HotelSettings {
  venueId: Id
  hours: BusinessHours
  notificationPrefs: {
    newRequestAlwaysOn: boolean
    messages: boolean
    reviews: boolean
    vouchers: boolean
    visits: boolean
  }
  listingCompleteness: { ar: number; en: number }
  /** Request mode only: the reply window, the fixed confirm window and the voucher settings (HL-VENU-06). */
  bookingRules: {
    responseSlaHours: number
    /** Fixed by the owner's rule: the client confirms within 24 hours of approval. */
    confirmWindowHours: 24
    /** Whether the partner accepts site visits (HL-VIST-05). */
    visitsEnabled: boolean
  }
  /** Billing and fees (HL-SETT-04): no bank information, no payouts. */
  billing: {
    feeExempt: boolean
    /** Major hotel: the badge replaces the plan chooser. */
    majorHotel: boolean
    plan: { cycle: 'weekly' | 'monthly' | 'annual' | null; endsOn: IsoDate | null }
  }
  /** Sister venue shown in the venue switcher (state only). */
  sister: { id: Id; name: Bilingual; role: StaffRole; pending: number } | null
  reliabilityStrikes: number
}

export interface HotelVariants {
  /** HL-DCSN-01 `simulateCompeting`: a second pending request for Thu 14 Jan. */
  competingRequest: { bookingId: Id }
  /** HL-DCSN-03 counter-offer example: the voucher price is held on the proposed date. */
  priceHoldExample: { bookingId: Id; proposedDate: IsoDate; requote: Money; held: Money }
}

/** Partner personas of the Partner app (account type chooser, HL-PROV-01). */
export interface PartnerPersona {
  id: Id
  kind: 'hotel' | 'hotel_non_major' | 'service_provider'
  userId: Id
  partnerAccountId: Id
  /** The staff or owner name and role line shown in More. */
  roleLabel: Bilingual
  /** Demo login phone (display-only). */
  phone: string
}
