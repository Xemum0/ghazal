import type { Bilingual, Id, ImageRef, IsoDate, IsoDateTime } from './common.ts'
import type { ServiceCategoryId } from './services.ts'

// ADR 0033 D7 and D8, voucher-model sections 8 to 10: the Partner app serves two account types (Hotel or wedding hall, Service
// provider). Service providers advertise in the client's "Additional services" section behind a paid plan (weekly, monthly or
// annual) and a manual review: a listing is NEVER published on payment. Major hotels are exempt from every fee, not from review.

export type PartnerAccountType = 'venue' | 'service_provider'

export interface PartnerAccount {
  id: Id
  type: PartnerAccountType
  name: Bilingual
  /** Hall or hotel venues this account runs (type `venue`). */
  venueIds: Id[]
  /** The provider this account runs (type `service_provider`). */
  providerId: Id | null
  /** User who signs in (the persona); null for accounts that have no demo login. */
  ownerUserId: Id | null
  /** Major hotel: no listing fee, no advertising fee, no payment step. Set only by the Super Admin; never visible to clients. */
  feeExempt: boolean
  status: 'invited' | 'active' | 'under_review' | 'suspended'
  createdAt: IsoDateTime
}

export type AdPlanCycle = 'weekly' | 'monthly' | 'annual'

/**
 * ADR 0035 D7: how a partner pays Ghazal. `plan` (weekly, monthly, annual; rates set in the Super Admin panel) is for service providers.
 * `contract` (terms as contracted, no public plan, no price shown in the app) is mostly for hotels and halls. Fixtures never carry a number.
 */
export type PartnerBillingMode = 'plan' | 'contract'

export interface PartnerBilling {
  partnerAccountId: Id
  mode: PartnerBillingMode
  /** One line about the contract, with no price and no date arithmetic (`contract` mode only). */
  contractSummary: Bilingual | null
  /** Chosen plan cycle and when it ends (`plan` mode only). Rates stay null until the Super Admin sets them. */
  plan: { cycle: AdPlanCycle | null; endsOn: IsoDate | null; ratesFils: number | null } | null
}

/**
 * One billing cycle of paid advertising. The rates are NOT decided: `ratesFils` is null everywhere in the seed and every surface
 * says "Rates announced soon" (voucher-model section 9.3). A number appears only after the Super Admin sets it.
 */
export interface AdPlan {
  id: Id
  cycle: AdPlanCycle
  name: Bilingual
  /** Length of a period in days (weekly 7, monthly 30, annual 365). */
  periodDays: 7 | 30 | 365
  /** Rate in fils; null = to be announced. */
  ratesFils: number | null
  currency: 'KWD'
  /** Major hotels and other fee-exempt partners never pay (owner rule). */
  exemptForMajorHotels: true
  active: boolean
}

export type ListingStatus =
  | 'draft'
  | 'payment_pending'
  | 'pending_review'
  | 'approved'
  | 'rejected'
  | 'active'
  | 'expired'
  | 'paused'

export type ListingRejectionCode =
  | 'content_not_compliant'
  | 'wrong_category'
  | 'missing_details'
  | 'unclear_pricing'
  | 'other'

/**
 * `exempt`: major hotel, no fee. `rates_pending`: the provider chose a plan cycle but the plan rates are not announced, so the pay step is
 * disabled ("Payment opens when rates are announced") and no listing in the seed has paid. `paid`, `refund_due`, `refunded` exist for the
 * day rates are set. A listing fee is refunded on a support request, outside the gateway, and the refund is recorded in the platform
 * (`Listing.feeRefund`; ADR 0035 D7 replaced the automatic 14-day rule). `refund_due` = support agreed, not yet recorded as paid out.
 */
export type ListingBillingStatus = 'exempt' | 'rates_pending' | 'paid' | 'refund_due' | 'refunded'

/** One decision of the review trail (HL-PROV-06): who moved the listing from one status to the next. */
export interface ReviewDecision {
  id: Id
  listingId: Id
  at: IsoDateTime
  from: ListingStatus | null
  to: ListingStatus
  actor: 'provider' | 'system' | 'moderator'
  /** Moderator name (Ghazal review team member), never a client. */
  actorName?: string
  codes?: ListingRejectionCode[]
  note?: Bilingual
}

export interface Listing {
  id: Id
  /** The provider the listing advertises. */
  providerId: Id
  partnerAccountId: Id
  /** One of the five primary categories, or a secondary one. */
  categoryId: ServiceCategoryId
  title: Bilingual
  description: Bilingual
  cover: ImageRef | null
  /** The provider packages the listing shows (ids of `ServiceProvider.packages`). */
  packageIds: Id[]
  status: ListingStatus
  planCycle: AdPlanCycle | null
  billing: {
    status: ListingBillingStatus
    /** Amount in fils; null while the plan rates are undecided (always null in the seed). */
    amountFils: number | null
    paidAt: IsoDateTime | null
  }
  submittedAt: IsoDateTime | null
  decidedAt: IsoDateTime | null
  /** Plan period: starts at approval (A-07), never at payment. */
  startsOn: IsoDate | null
  endsOn: IsoDate | null
  /** Rejection reasons and the moderator's note, shown to the provider. */
  rejection: { codes: ListingRejectionCode[]; note: Bilingual } | null
  /** @deprecated ADR 0035 D7 (no automatic 14-day rule); a rejected provider refines the listing and resubmits. Null in new data. */
  planKeptUntil: IsoDate | null
  /** A listing-fee refund the provider asked support for; money moves outside the gateway, the platform only records it. */
  feeRefund: { requestedAt: IsoDateTime; recordedAt: IsoDateTime | null; recordedBy: string | null } | null
  /** Paid placement is labelled "Sponsored" to clients; the base listing is not. */
  sponsored: boolean
  /** The review trail, oldest first. */
  history: ReviewDecision[]
}
