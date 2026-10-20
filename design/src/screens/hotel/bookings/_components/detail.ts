// The model of Booking detail (HL-BOOK-03): which request a frame state or a landing shows, its voucher as the store holds it now, and the
// variants the seed has no record for (a cancellation by the venue, an issue reported by the client). Everything derives from the fixtures
// and the prototype store; nothing is typed here that a fixture could carry.
import { useMemo } from 'react'
import { getBooking, heroBookingAs, reviews, voucherFor, type Booking, type Review, type Voucher } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { STORY_BOOKING_ID, type BookingRole } from './bits'
import { useBookingById, useBookingParams, type BookingParams } from './model'

export const IDS = {
  pending: STORY_BOOKING_ID,
  danger: 'bk-GZ-2611-3K8D',
  awaiting: 'bk-GZ-2611-9H3D',
  confirmed: 'bk-GZ-2611-2P8R',
  redeemed: 'bk-GZ-2609-4Z6X',
  completed: 'bk-GZ-2608-6N8F',
  declined: 'bk-GZ-2611-1B5Z',
  missed: 'bk-GZ-2611-2D6V',
  lapsed: 'bk-GZ-2611-3N7K',
  cancelledClient: 'bk-GZ-2609-3A9P',
} as const

const STATE_ID: Record<string, string> = {
  pending: IDS.pending,
  'pending-danger': IDS.danger,
  'awaiting-client-confirmation': IDS.awaiting,
  confirmed: IDS.confirmed,
  redeemed: IDS.redeemed,
  completed: IDS.completed,
  declined: IDS.declined,
  'expired-missed': IDS.missed,
  'expired-lapsed': IDS.lapsed,
  'cancelled-by-client': IDS.cancelledClient,
  'cancelled-by-venue': IDS.cancelledClient,
  'issue-reported': IDS.completed,
  conflict: IDS.pending,
  offline: IDS.pending,
  loading: IDS.pending,
  error: IDS.pending,
  'role-limited': IDS.confirmed,
}

export type DetailLock = 'offline' | 'role-limited'

export type DetailModel = {
  booking: Booking
  /** The voucher bound to this request, as the store holds it now (a redeem from HL-BOOK-06 flips it). */
  voucher: Voucher | undefined
  role: BookingRole
  lock: DetailLock | null
  held: boolean
  params: BookingParams
  /** The review of this event that still waits for a reply (Completed: "Reply to review"). */
  review: Review | null
}

/** The request that a frame state asks for, including the variants that exist only as a derivation of a seeded request. */
function variantOf(state: string | undefined, base: Booking | undefined): Booking | undefined {
  if (!state || !base) return base
  if (state === 'counter-offer-sent') return heroBookingAs('counter_offer')
  if (state === 'cancelled-by-venue') {
    // The partner cancelled a confirmed booking (R13b): the client's voucher is released and refundable.
    const events = base.events.map((e, i) => (i === base.events.length - 1 ? { ...e, actor: 'venue' as const, actorName: 'Amal Al-Balushi' } : e))
    return { ...base, cancelledBy: 'venue', reasonCode: 'hall_unavailable', events }
  }
  if (state === 'issue-reported') return { ...base, overlays: { ...base.overlays, issueReported: true } }
  return base
}

export function useDetailModel(state: string | undefined): DetailModel {
  const params = useBookingParams()
  const id = state ? (STATE_ID[state] ?? IDS.pending) : (params.bookingId ?? IDS.pending)
  const stored = useBookingById(id)
  const live = usePrototype(s => s.vouchers)
  return useMemo(() => {
    const booking = (variantOf(state, stored) ?? getBooking(IDS.pending)) as Booking
    const review =
      booking.status === 'completed'
        ? (reviews.find(r => r.venueId === booking.venueId && r.eventDate === booking.eventDate && r.ownerReply === null) ?? null)
        : null
    return {
      booking,
      voucher: live.find(v => v.id === booking.voucherId) ?? voucherFor(booking),
      role: state === 'role-limited' ? 'accountant' : (params.role ?? 'manager'),
      lock: state === 'offline' ? 'offline' : state === 'role-limited' ? 'role-limited' : null,
      held: state === 'conflict',
      params,
      review,
    }
  }, [state, stored, params, live])
}
