import type { Bilingual, Id, IsoDate, IsoDateTime, Money } from './common.ts'

// ADR 0033 D2 and docs/product/voucher-model.md section 4: one single-use code and QR per voucher, bound at purchase to ONE venue
// or provider and to its quote. Money here is the only client payment in the product (KD 2.000, `meta.config.voucherFeeFils`).

export type VoucherStatus = 'unpaid' | 'active' | 'bound' | 'used' | 'expired' | 'forfeited' | 'credit_issued'

/**
 * ADR 0035 D5. `bound`: bought for one venue or provider (the normal voucher). `credit`: granted by Ghazal support after a request,
 * unbound (usable at ANY hall, hotel or service), 60 days; it is never paid for and never turns into money.
 */
export type VoucherKind = 'bound' | 'credit'

export type VoucherTargetType = 'venue' | 'provider'

/**
 * Why a bound voucher returned to `active` (booking-state-machine section 12). A client that lets the 24 h confirm window lapse does NOT
 * release the voucher: it is `forfeited` (ADR 0035 D4).
 */
export type VoucherReleaseReason =
  | 'declined'
  | 'venue_no_response'
  | 'withdrawn'
  | 'slot_taken'
  | 'approval_revoked'
  | 'venue_cancelled'
  | 'partner_suspended'

export type VoucherUsedReason = 'redeemed' | 'completed' | 'cancelled_after_confirm'

export type GatewayMethod = 'knet' | 'apple_pay' | 'card' | 'google_pay'

/** The voucher payment (the gateway receipt). Documents say KWD, Western digits (ADR 0010). No VAT line exists (ADR 0035 D2). */
export interface VoucherPayment {
  method: GatewayMethod
  /** RC-000123, gapless sequence per issuer and kind. */
  receiptNo: string
  amount: Money
  status: 'succeeded' | 'failed' | 'pending'
  at: IsoDateTime
}

/**
 * A request to Ghazal support for a credit voucher (ADR 0035 D5). No money goes back: a granted request creates a `credit` voucher in
 * the client's wallet and turns the original voucher into `credit_issued`. Lives in the client's support conversation.
 */
export type RefundRequestStatus = 'requested' | 'granted' | 'declined'

export interface RefundRequest {
  id: Id
  /** The voucher the client asks support about. */
  voucherId: Id
  clientId: Id
  status: RefundRequestStatus
  requestedAt: IsoDateTime
  /** The client's note, in the language typed. */
  note: Bilingual | null
  /** The support thread the request was written in. */
  conversationId: Id
  decidedAt: IsoDateTime | null
  /** Support representative who decided. */
  decidedBy: string | null
  /** The credit voucher granted; null unless `granted`. */
  creditVoucherId: Id | null
  /** Short reason shown to the client when declined. */
  declineReason: Bilingual | null
}

/** Fields every voucher carries, bound or credit. */
interface VoucherCommon {
  id: Id
  /** GV-YYMM-XXXX (four Crockford base32 characters, month of purchase or grant), rendered as an LTR isolate. */
  code: string
  clientId: Id
  /** The voucher price: 2000 fils (KD 2.000), no VAT. For a credit voucher the value of the voucher it replaces. */
  priceFils: number
  status: VoucherStatus
  /** Validity end: 60 days from payment (or from the grant), never past the event date plus 12 hours; null while `unpaid`. */
  validUntil: IsoDateTime | null
  /** Signed payload the QR renders ('gz:v1:<code>:<target>:<check>'); the app never shows it as text. */
  qr: { payload: string; version: 1 }
  usedAt: IsoDateTime | null
  usedReason: VoucherUsedReason | null
  /** Staff member who redeemed it (audit trail). */
  redeemedBy: string | null
}

/** A voucher bought for ONE venue or provider and its quote (ADR 0033 D2, ADR 0035 D3). The shape every prototype screen works with. */
export interface Voucher extends VoucherCommon {
  kind: 'bound'
  targetType: VoucherTargetType
  /** The venue (V01) or the provider (vendor-flowers-zahra) the voucher is bound to. */
  venueOrProviderId: Id
  /** Hall of the bound quote; null for a provider. */
  hallId: Id | null
  packageId: Id
  /** Event date of the bound quote. */
  eventDate: IsoDate
  /** Guest count (venue) or quantity (provider) of the bound quote. */
  guests: number | null
  /** The bound quote in integer fils: what the client pays the venue without and with the voucher. */
  quoteFils: { standard: number; voucher: number }
  /** Null while `unpaid`. */
  purchasedAt: IsoDateTime | null
  /** While released: the 60-day reuse window at the same target. */
  reuseUntil: IsoDate | null
  /** The live request while `bound`, or the request that consumed it. */
  bookingId: Id | null
  payment: VoucherPayment | null
  /** Set while the voucher sits released (`active` after a release). */
  releasedAt: IsoDateTime | null
  releaseReason: VoucherReleaseReason | null
  /** Set when the 24 h confirm window lapsed: the voucher is not valid and never comes back (`forfeited`). */
  forfeitedAt: IsoDateTime | null
  /** The client may ask support for a credit voucher (venue-fault release): never money. */
  creditEligible: boolean
  /** The support request that concerns this voucher, if the client sent one (`credit_issued` when granted). */
  refundRequestId: Id | null
}

/**
 * A credit voucher granted by Ghazal support after a request (ADR 0035 D5): UNBOUND, usable at any hall, hotel or service, valid 60 days
 * from the grant, never paid for and never turned into money. Status is `active`, `used` or `expired`.
 */
export interface CreditVoucher extends VoucherCommon {
  kind: 'credit'
  grantedAt: IsoDateTime
  /** The support request it answers and the voucher it replaces (now `credit_issued`). */
  grantedFrom: { requestId: Id; voucherId: Id; grantedBy: string }
  /** Set once the client claims it at a venue or service; the claim then follows the normal request flow. */
  bookingId: Id | null
}

/** Anything in the wallet. */
export type WalletVoucher = Voucher | CreditVoucher
