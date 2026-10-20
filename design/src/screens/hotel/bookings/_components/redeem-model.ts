// The model of the redeem screens (HL-BOOK-06, HL-BOOK-07): turning a typed or scanned code into one of the specific, calm outcomes of
// voucher-model 8.2, read from the live prototype store (so a redemption made a moment ago shows as "Already used"), and the sample
// codes the prototype offers so every outcome can be reached by tapping. No client data is read until the code belongs to this partner.
import { meta, type Booking, type Voucher } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { VENUE_ID, staff } from './bits'

export const CODE_PREFIX = 'GV-'

export type RedeemOutcome =
  | { kind: 'ready'; voucher: Voucher; booking: Booking }
  | { kind: 'unknown' }
  /** The code exists but belongs to another partner: nothing about the other party is revealed. */
  | { kind: 'other-partner' }
  | { kind: 'not-confirmed'; booking: Booking | null }
  | { kind: 'already-used'; usedAt: string | null }
  | { kind: 'expired-or-refunded' }

/** `2611-K7QM` from anything the person typed or pasted: upper case, letters and digits only, a leading GV dropped, grouped 4 - 4. */
export function formatTyped(raw: string): string {
  const clean = raw.toUpperCase().replace(/[^A-Z0-9]/g, '').replace(/^GV/, '').slice(0, 8)
  return clean.length > 4 ? `${clean.slice(0, 4)}-${clean.slice(4)}` : clean
}

export const isComplete = (typed: string): boolean => typed.replace('-', '').length === 8

/** The full code (`GV-2611-K7QM`) of the typed part. */
export const fullCode = (typed: string): string => `${CODE_PREFIX}${typed}`

/** The typed part of a full code (`GV-2611-K7QM` -> `2611-K7QM`). */
export const typedPart = (code: string): string => formatTyped(code)

export function checkCode(code: string): RedeemOutcome {
  const s = usePrototype.getState()
  const v = s.vouchers.find(x => x.code === code.trim().toUpperCase())
  if (!v) return { kind: 'unknown' }
  if (v.venueOrProviderId !== VENUE_ID) return { kind: 'other-partner' }
  if (v.status === 'used') return { kind: 'already-used', usedAt: v.usedAt }
  if (v.status === 'expired' || v.status === 'refunded') return { kind: 'expired-or-refunded' }
  const booking = v.bookingId ? (s.hotelBookings.find(x => x.id === v.bookingId) ?? null) : null
  if (!booking || booking.status !== 'confirmed' || v.status !== 'bound') return { kind: 'not-confirmed', booking }
  return { kind: 'ready', voucher: v, booking }
}

export type SampleCodes = { ready: string | null; notConfirmed: string | null; other: string | null; used: string | null; expired: string | null }

/** One code per outcome, from the live store (the prototype's shortcuts and the frame states read them). */
export function sampleCodes(): SampleCodes {
  const s = usePrototype.getState()
  const ours = s.vouchers.filter(v => v.venueOrProviderId === VENUE_ID)
  const readyBooking = s.hotelBookings.find(b => b.status === 'confirmed' && ours.some(v => v.id === b.voucherId && v.status === 'bound'))
  const approved = s.hotelBookings.find(b => b.status === 'approved')
  return {
    ready: readyBooking ? (ours.find(v => v.id === readyBooking.voucherId)?.code ?? null) : null,
    notConfirmed: (approved ? ours.find(v => v.id === approved.voucherId)?.code : null) ?? meta.story.voucherCode,
    other: s.vouchers.find(v => v.venueOrProviderId !== VENUE_ID && v.status !== 'unpaid')?.code ?? null,
    used: ours.find(v => v.status === 'used')?.code ?? null,
    expired: s.vouchers.find(v => v.venueOrProviderId === VENUE_ID && (v.status === 'expired' || v.status === 'refunded'))?.code ?? null,
  }
}

/** The signed-in staff member (the demo persona), for the audit line of a redemption. */
export const youStaff = staff.find(s => s.isYou) ?? staff[0]
