// The voucher rules of docs/product/voucher-model.md sections 4 and 13 as pure functions: the price columns of the seed, the code and
// QR payload, validity and reuse, and the release and refund table (A-03). Numbers come from `PlatformConfig`, never from literals.
import type {
  IsoDate,
  IsoDateTime,
  PlatformConfig,
  VoucherReleaseReason,
  VoucherStatus,
} from '../types.ts'
import { addDays, addHours, diffDays, kuwaitDateOf, instantMs } from './dates.ts'
import { hash32, seeded } from './seeded.ts'

// ---------------------------------------------------------------- the voucher price column (seed construction)

/**
 * Deterministic per-venue discount in basis points inside the owner's bounds (15% to 35%). The same venue always gets the same
 * share; the rounding in `voucherPrice` is then clamped so every rate stays inside the bounds.
 */
export function voucherDiscountBps(targetId: string, bounds: { min: number; max: number }): number {
  // Keep a margin inside the bounds so rounding to the step can never leave them.
  const lo = bounds.min + 200
  const hi = bounds.max - 200
  return lo + Math.floor(seeded('voucher-discount', targetId) * (hi - lo + 1))
}

/** Voucher price of a standard price: discount, rounded to `stepFils`, clamped so the discount stays inside the bounds. */
export function voucherPrice(standardFils: number, bps: number, stepFils: number, bounds: { min: number; max: number }): number {
  const raw = (standardFils * (10000 - bps)) / 10000
  let v = Math.round(raw / stepFils) * stepFils
  const maxV = Math.floor((standardFils * (10000 - bounds.min)) / 10000 / stepFils) * stepFils
  const minV = Math.ceil((standardFils * (10000 - bounds.max)) / 10000 / stepFils) * stepFils
  if (v > maxV) v = maxV
  if (v < minV) v = minV
  return v
}

/** Realised discount in basis points, half-up. */
export function discountBps(standardFils: number, voucherFils: number): number {
  return Math.round(((standardFils - voucherFils) * 10000) / standardFils)
}

// ---------------------------------------------------------------- code and QR

const CROCKFORD = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'

/** Four Crockford base32 characters from the parts (never I, L, O or U). */
export function crockford4(...parts: (string | number)[]): string {
  let h = hash32('crockford', ...parts)
  let out = ''
  for (let i = 0; i < 4; i += 1) {
    out += CROCKFORD[h & 31]
    h >>>= 5
    if (i === 2) h ^= hash32('c2', ...parts) >>> 3
  }
  return out
}

/** GV-YYMM-XXXX with the month of purchase. */
export function voucherCode(purchasedAt: IsoDateTime, ...parts: (string | number)[]): string {
  return `GV-${purchasedAt.slice(2, 4)}${purchasedAt.slice(5, 7)}-${crockford4(...parts)}`
}

export const VOUCHER_CODE = /^GV-(\d{4})-([0-9A-HJKMNP-TV-Z]{4})$/

/** The payload the QR renders: version, code, target and a short check. The app never shows it as text. */
export function qrPayload(code: string, targetId: string): { payload: string; version: 1 } {
  const check = (hash32('qr', code, targetId) & 0xffff).toString(16).toUpperCase().padStart(4, '0')
  return { payload: `gz:v1:${code}:${targetId}:${check}`, version: 1 }
}

// ---------------------------------------------------------------- validity, reuse, saving test

/** Eligibility test of the voucher CTA: the saving must beat the fee (voucher-model section 4.1). */
export function voucherPaysForItself(savingsFils: number, config: Pick<PlatformConfig, 'voucherFeeFils'>): boolean {
  return savingsFils > config.voucherFeeFils
}

/** End of validity: payment plus 60 days, never later than the end of the event date plus 12 hours (A-02). */
export function voucherValidUntil(
  purchasedAt: IsoDateTime,
  eventDate: IsoDate,
  config: Pick<PlatformConfig, 'voucherValidityDays' | 'completionDelayHours'>,
): IsoDateTime {
  const byPolicy = addHours(purchasedAt, config.voucherValidityDays * 24)
  // End of the event day (the sessions end by 02:00 the next morning) plus the completion delay.
  const eventEnd = addHours(`${addDays(eventDate, 1)}T02:00:00+03:00`, config.completionDelayHours)
  return instantMs(byPolicy) <= instantMs(eventEnd) ? byPolicy : eventEnd
}

/** The reuse window opened by a release: 60 days at the same target. */
export function voucherReuseUntil(releasedAt: IsoDateTime, config: Pick<PlatformConfig, 'voucherReuseDays'>): IsoDate {
  return addDays(kuwaitDateOf(releasedAt), config.voucherReuseDays)
}

// ---------------------------------------------------------------- release and refund table (voucher-model section 4.4)

export interface ReleaseOutcome {
  /** The voucher is released back to `active` and reusable at the same target. */
  reusable: boolean
  /** The client may refund the KD 2 (one tap, original method). */
  refundable: boolean
}

/** What a release does to the voucher, by reason. Client-caused releases are reusable but not refundable. */
export function releaseOutcome(reason: VoucherReleaseReason): ReleaseOutcome {
  switch (reason) {
    case 'declined':
    case 'venue_no_response':
    case 'slot_taken':
    case 'approval_revoked':
    case 'venue_cancelled':
    case 'partner_suspended':
      return { reusable: true, refundable: true }
    case 'withdrawn':
    case 'client_no_confirmation':
      return { reusable: true, refundable: false }
  }
}

/** Status after a request ends, from the voucher's side. `cancelled_after_confirm` consumes the voucher. */
export function voucherStatusAfter(kind: 'release' | 'redeemed' | 'completed' | 'cancelled_after_confirm' | 'validity_ended' | 'refunded'): VoucherStatus {
  switch (kind) {
    case 'release':
      return 'active'
    case 'redeemed':
    case 'completed':
    case 'cancelled_after_confirm':
      return 'used'
    case 'validity_ended':
      return 'expired'
    case 'refunded':
      return 'refunded'
  }
}

/** Whether an `active` voucher is past its validity at `now`. */
export function isVoucherExpired(validUntil: IsoDateTime | null, reuseUntil: IsoDate | null, now: IsoDateTime): boolean {
  if (validUntil && instantMs(now) > instantMs(validUntil)) {
    return !(reuseUntil && kuwaitDateOf(now) <= reuseUntil)
  }
  return false
}

/** The 24 h confirm deadline of an approval (owner rule, fixed). */
export function confirmByFor(approvedAt: IsoDateTime, config: Pick<PlatformConfig, 'confirmWindowHours'>): IsoDateTime {
  return addHours(approvedAt, config.confirmWindowHours)
}

/** Days left of a validity or reuse window, for "valid for N more days". */
export function daysLeft(until: IsoDate, now: IsoDateTime): number {
  return diffDays(kuwaitDateOf(now), until)
}
