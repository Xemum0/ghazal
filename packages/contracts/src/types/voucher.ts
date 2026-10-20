import type { Id, IsoDate, IsoDateTime, Money } from './common.ts'

// ADR 0033 D2 and docs/product/voucher-model.md section 4: one single-use code and QR per voucher, bound at purchase to ONE venue
// or provider and to its quote. Money here is the only client payment in the product (KD 2.000, `meta.config.voucherFeeFils`).

export type VoucherStatus = 'unpaid' | 'active' | 'bound' | 'used' | 'expired' | 'refunded'

export type VoucherTargetType = 'venue' | 'provider'

/** Why a bound voucher returned to `active` (booking-state-machine section 12). */
export type VoucherReleaseReason =
  | 'declined'
  | 'venue_no_response'
  | 'withdrawn'
  | 'client_no_confirmation'
  | 'slot_taken'
  | 'approval_revoked'
  | 'venue_cancelled'
  | 'partner_suspended'

export type VoucherRefundReason = 'venue_fault_release' | 'system_error' | 'admin_override' | 'duplicate_payment'

export type VoucherUsedReason = 'redeemed' | 'completed' | 'cancelled_after_confirm'

export type GatewayMethod = 'knet' | 'apple_pay' | 'card' | 'google_pay'

/** The voucher payment (the gateway receipt). Documents say KWD, Western digits (ADR 0010). */
export interface VoucherPayment {
  method: GatewayMethod
  /** RC-000123, gapless sequence per issuer and kind. */
  receiptNo: string
  amount: Money
  status: 'succeeded' | 'failed' | 'pending'
  at: IsoDateTime
}

export interface VoucherRefund {
  amount: Money
  /** Always the original method. */
  method: GatewayMethod
  status: 'calculated' | 'submitted' | 'processing' | 'completed'
  reason: VoucherRefundReason
  initiatedAt: IsoDateTime
  completedAt: IsoDateTime | null
  /** Soft arrival copy: KNET 1-3 working days, cards and wallets up to 10. */
  arrival: 'knet_1_3_days' | 'card_up_to_10_days'
  creditNoteNo: string | null
}

export interface Voucher {
  id: Id
  /** GV-YYMM-XXXX (four Crockford base32 characters, month of purchase), rendered as an LTR isolate. */
  code: string
  clientId: Id
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
  /** The voucher price paid to Ghazal: 2000 fils (KD 2.000). */
  priceFils: number
  status: VoucherStatus
  /** Null while `unpaid`. */
  purchasedAt: IsoDateTime | null
  /** Validity end: 60 days from payment, never past the event date plus 12 hours; null while `unpaid`. */
  validUntil: IsoDateTime | null
  /** While released: the 60-day reuse window at the same target. */
  reuseUntil: IsoDate | null
  /** Signed payload the QR renders ('gz:v1:<code>:<target>:<check>'); the app never shows it as text. */
  qr: { payload: string; version: 1 }
  /** The live request while `bound`, or the request that consumed it. */
  bookingId: Id | null
  payment: VoucherPayment | null
  /** Set while the voucher sits released (`active` after a release). */
  releasedAt: IsoDateTime | null
  releaseReason: VoucherReleaseReason | null
  /** Refundable now (venue-fault release, or an unexpired voucher the client may refund per voucher-model 4.4). */
  refundEligible: boolean
  refundUntil: IsoDate | null
  refund: VoucherRefund | null
  usedAt: IsoDateTime | null
  usedReason: VoucherUsedReason | null
  /** Staff member who redeemed it (audit trail). */
  redeemedBy: string | null
}
