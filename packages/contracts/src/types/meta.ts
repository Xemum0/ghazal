import type { Bilingual, Id, IsoDate, IsoDateTime } from './common.ts'
import type { BookingStatus } from './booking.ts'
import type { PriceStructure } from './pricing.ts'
import type { VenueType } from './venue.ts'

/**
 * Configuration numbers of the voucher model (voucher-model sections 4, 5, 13; booking-state-machine section 7). Every number lives
 * here, never as a literal in the UI. Items marked proposed are working assumptions (ADR 0033 D6, proposed-needs-owner).
 */
export interface PlatformConfig {
  /** Owner-given: the voucher costs KD 2.000 (2000 fils). */
  voucherFeeFils: number
  /** Proposed (A-02): 60 days from payment, never past the event date plus 12 hours. */
  voucherValidityDays: number
  /** Proposed (A-02): reuse window at the same target after a release. */
  voucherReuseDays: number
  voucherCheckoutMinutes: number
  /** Proposed (A-03): venue-fault releases stay refundable this many days after expiry. */
  voucherRefundDaysAfterExpiry: number
  /** Owner rule: the client must confirm within 24 hours of approval. Fixed, not partner-configurable. */
  confirmWindowHours: number
  approvalUndoSeconds: number
  counterOfferValidityHours: number
  /** Open requests per wedding file (pending plus approved). */
  maxOpenRequests: number
  defaultReplyHours: number
  /** Event within this many days: 4 h reply window and the Urgent tag. */
  urgentLeadDays: number
  urgentReplyHours: number
  completionDelayHours: number
  issueReportHours: number
  /** Visit group chat: read-only this long after the slot, archived this many days later (A-11). */
  visitChatReadonlyHours: number
  visitChatArchiveDays: number
  /** A rejected listing keeps its paid plan this many days before it is refunded (A-08). */
  listingRejectedRetentionDays: number
  slaDangerPct: number
  slaGoldPct: number
  /** Weekend pricing tier = Thu, Fri, Sat; the calendar's visual weekend is Fri, Sat only (ADR 0004 D3, ADR 0011). */
  weekendTierDays: number[]
  peakBandDays: number[]
  /** Discount bounds of the seed's voucher prices (basis points): the owner asked for 15% to 35% per venue. */
  seedVoucherDiscountBps: { min: number; max: number }
}

export interface HeroStory {
  /** The shared story booking (client request = pending request at the hotel). */
  bookingRef: string
  bookingId: Id
  voucherId: Id
  voucherCode: string
  venueId: Id
  clientId: Id
  /** Status of the stored record at NOW; the prototype walks it through the other states with `heroBookingAs`. */
  statusAtNow: BookingStatus
}

// ---------------------------------------------------------------- filter taxonomy (voucher-model section 7)

export interface VenueTypeOption {
  id: VenueType
  name: Bilingual
  /** Governmental facilities are browse-only: no voucher, no request, no visit (A-13). */
  voucherEligible: boolean
  visits: boolean
}

export interface CapacityBand {
  id: Id
  name: Bilingual
  /** Guests, inclusive; max null = open ended. A venue matches when its hall range overlaps the band. */
  min: number
  max: number | null
}

export interface PriceStructureOption {
  id: PriceStructure | 'either'
  name: Bilingual
}

export interface FilterTaxonomy {
  venueTypes: VenueTypeOption[]
  /** Two-handle capacity range of the filter sheet. */
  capacityRange: { min: number; max: number; step: number }
  capacityBands: CapacityBand[]
  priceStructures: PriceStructureOption[]
  sorts: { id: 'recommended' | 'voucher_price' | 'price' | 'rating' | 'distance' | 'newest'; name: Bilingual }[]
}

export interface Meta {
  /** Fixed prototype clock: Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait. */
  now: IsoDateTime
  today: IsoDate
  timezone: 'Asia/Kuwait'
  /** The 12-month window covered by availability, from NOW's month. */
  availabilityWindow: { from: IsoDate; to: IsoDate }
  heroVenueIds: Id[]
  hotelVenueId: Id
  clientUserId: Id
  hotelUserId: Id
  /** The service-provider partner persona (Zahra Floral Studio). */
  providerUserId: Id
  providerId: Id
  story: HeroStory
  config: PlatformConfig
  /** Approximate occasion markers shown in calendars (labels approximate until announced). */
  occasions: {
    id: Id
    name: { en: string; ar: string }
    from: IsoDate
    to: IsoDate
    approximate: boolean
  }[]
}
