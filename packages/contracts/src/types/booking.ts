import type { Audience, Bilingual, Id, IsoDate, IsoDateTime, LocalTime, Money } from './common.ts'
import type { PriceLine, QuoteTotals } from './pricing.ts'

// ADR 0033 D3 and docs/architecture/booking-state-machine.md. A booking is a REQUEST FOR A PRICE: the client binds a paid voucher,
// the partner approves or declines, the client confirms within 24 hours, settles with the partner off-app and the partner redeems the
// voucher. No money moves inside this object: no deposit, balance, commission, payout, cash, refund or invoice.

export type BookingStatus =
  | 'pending'
  | 'approved'
  | 'declined'
  | 'expired'
  | 'confirmed'
  | 'redeemed'
  | 'completed'
  | 'cancelled'

export type CancelledBy = 'client' | 'venue' | 'system' | 'admin'
export type ExpiredReason = 'venue_no_response' | 'client_no_confirmation' | 'slot_taken' | 'client_no_response'
export type RejectReason = 'date_unavailable' | 'capacity_mismatch' | 'package_not_offered' | 'other'

/** Reason registry of booking-state-machine section 12 (cancelled). */
export type CancelReason =
  | 'withdrawn'
  | 'counter_offer_declined'
  | 'plans_changed'
  | 'found_other_venue'
  | 'date_changed'
  | 'budget'
  | 'approval_revoked'
  | 'hall_unavailable'
  | 'safety_or_maintenance'
  | 'authority_order'
  | 'system_error'
  | 'admin_override'
  | 'other'

/** Prototype role of a seeded booking: 'story' rows carry screen-quoted facts, 'background' rows fill calendars and analytics. */
export type SeedRole = 'story' | 'background'

export type BookingTargetType = 'venue' | 'provider'

export interface BookingSection {
  position: 1 | 2
  hallId: Id
  sessionId: Id
  audience: Audience
  guests: number
  /** max(guests, minimum) less complimentary guests (ADR 0004 D2). */
  billableGuests: number
  packageId: Id
  /** Venue-local start and end of the session, copied at request time (the snapshot never changes). */
  start: LocalTime
  end: LocalTime
}

/** What a client asked of a service provider (no halls, no slot claim in the MVP; booking-state-machine section 8). */
export interface ProviderServiceRequest {
  providerId: Id
  listingId: Id
  packageId: Id
  /** Guests or units, per the package's pricing structure. */
  quantity: number
  /** Where the service happens, when known. */
  venueId: Id | null
}

export interface ContactPerson {
  name: string
  /** Display-only fixture number; never a tel: or wa.me link in the prototype. */
  phone: string
  /** Whether the client shared the number with the partner (ADR 0003, OQ-B-19). */
  shared: boolean
  bookingFor: 'bride' | 'groom' | 'family' | 'planner'
}

// ---------------------------------------------------------------- the Booking Thread (booking-state-machine section 10)

export type ThreadNodeKind = 'request' | 'approval' | 'confirmation' | 'redemption' | 'day' | 'completed'
/** 'done' = knotted gold, 'current' = in progress, 'future' = faint (at most two shown), 'closed' = ended without this step. */
export type ThreadNodeState = 'done' | 'current' | 'future' | 'closed'

export interface ThreadKnot {
  node: ThreadNodeKind
  state: ThreadNodeState
  /** Absolute time of a done node, or the deadline of a current/future one. */
  at: IsoDateTime | null
  /** Overrides the standard label. */
  label?: Bilingual
  /** Staff member who recorded it (audit trail). */
  by?: string
}

export interface BookingEvent {
  at: IsoDateTime
  kind: 'transition' | 'overlay' | 'note'
  from: BookingStatus | null
  to: BookingStatus | null
  actor: 'client' | 'venue' | 'system' | 'admin'
  actorName?: string
  note?: Bilingual
}

// ---------------------------------------------------------------- counter-offer (the only proposal kind; no reschedule after confirmation, A-05)

export interface DateProposalOption {
  eventDate: IsoDate
  hallId: Id
  sessionId: Id
  /** Voucher total re-quoted for the date (the voucher price is held). */
  quotedTotal: Money
  delta: Money
}

export interface DateProposal {
  id: Id
  kind: 'counter_offer'
  status: 'proposed' | 'accepted' | 'declined' | 'expired' | 'withdrawn'
  proposedAt: IsoDateTime
  /** 48 hours (booking-state-machine section 7). */
  expiresAt: IsoDateTime
  originalPriceHeld: boolean
  options: DateProposalOption[]
}

export interface Booking {
  id: Id
  /** GZ-YYMM-XXXX (4 Crockford base32 characters), rendered as an LTR isolate. */
  ref: string
  seedRole: SeedRole
  targetType: BookingTargetType
  /** Set when the target is a hall or hotel; null for a provider request. */
  venueId: Id | null
  /** Set when the target is a service provider; null for a venue request. */
  providerId: Id | null
  clientId: Id
  /** Client display name as typed (user text is stored as typed, dir=auto). */
  clientName: string
  weddingId: Id | null
  status: BookingStatus
  createdAt: IsoDateTime
  /** Event date (venue) or service date (provider). */
  eventDate: IsoDate
  /** Hall sections; empty for a provider request. */
  sections: BookingSection[]
  /** Provider request detail; null for a venue request. */
  service: ProviderServiceRequest | null
  /** The frozen quote (ADR 0033 D4): lines carry the voucher column and the standard column. */
  lines: PriceLine[]
  totals: QuoteTotals
  /** The voucher bound to the request (always present from `pending`). */
  voucherId: Id
  /** Partner reply deadline while `pending` (and the missed deadline of a venue_no_response expiry). */
  respondBy: IsoDateTime | null
  /** When the partner approved; starts the 24 h confirm window. */
  approvedAt: IsoDateTime | null
  /** approvedAt + 24 h: the client must confirm by then or the approval lapses (owner rule). */
  confirmBy: IsoDateTime | null
  confirmedAt: IsoDateTime | null
  /** When the partner redeemed the voucher (code or QR). */
  redeemedAt: IsoDateTime | null
  redeemedBy: string | null
  completedAt: IsoDateTime | null
  /** SLA of the request in hours (24 by default, 4 inside 14 days). */
  slaHours: number | null
  contact: ContactPerson
  specialRequests: string | null
  firstBooking: boolean
  verifiedPhone: boolean
  thread: ThreadKnot[]
  events: BookingEvent[]
  cancelledBy: CancelledBy | null
  /** CancelReason value for a cancelled request. */
  reasonCode: CancelReason | null
  rejectReason: RejectReason | null
  expiredReason: ExpiredReason | null
  proposal: DateProposal | null
  /** Overlays that are never statuses (booking-state-machine section 6). */
  overlays: {
    blockedByHold?: boolean
    reviewPrompted?: boolean
    reliabilityStrike?: boolean
    issueReported?: boolean
  }
  /** Venue-approved lower voucher total at approval (never higher), if any (ADR 0004 D3). */
  approvedDiscount: Money | null
}
