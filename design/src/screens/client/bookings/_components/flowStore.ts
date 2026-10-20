// Flow-local memory of the bookings flow plus the live data hooks. The shared prototype store owns the requests and vouchers
// (clientBookings, hotelBookings, vouchers, with sendRequest, cancelRequest, confirmBooking, lapseApproval); this file adds what the
// store has no action for yet: the client's answer to a counter-offer (R05 accept, decline), a reported issue and the receipts the
// client saved to the phone. A request to move these into the shared store is in docs/engineering/requests.md. Nothing is persisted.
import { create } from 'zustand'
import type { Booking, IsoDate, IsoDateTime, Voucher } from '../../../../mock'
import { clock, engine, getVoucher, meta } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { releasedVoucher, transition } from '../../../../shell/state/rules'
import { HERO_ID, addHoursIso, variantOfBooking, viewOf, type View } from './model'

type FlowState = {
  /** Requests the client reported an issue on, by id: the 72 hour "Report an issue" of a completed request. */
  issues: Record<string, { reason: 'price_not_honoured' | 'voucher_not_redeemed' | 'other'; at: IsoDateTime }>
  /** Receipts saved to the phone: document id -> when. They stay readable offline (CL-BKNG-05). */
  saved: Record<string, IsoDateTime>
  reportIssue: (bookingId: string, reason: FlowState['issues'][string]['reason'], at?: IsoDateTime) => void
  save: (docId: string, at?: IsoDateTime) => void
  reset: () => void
}

export const useBookingsFlow = create<FlowState>()(set => ({
  issues: {},
  saved: {},
  reportIssue: (bookingId, reason, at = clock.now()) => set(s => ({ issues: { ...s.issues, [bookingId]: { reason, at } } })),
  save: (docId, at = clock.now()) => set(s => ({ saved: { ...s.saved, [docId]: at } })),
  reset: () => set({ issues: {}, saved: {} }),
}))

// ---------------------------------------------------------------- live data

/** The client's requests in the prototype store, newest first (the list and the open-requests counter read this). */
export function useClientRequests(): View[] {
  const bookings = usePrototype(s => s.clientBookings)
  const vouchers = usePrototype(s => s.vouchers)
  const issues = useBookingsFlow(s => s.issues)
  return bookings.map(b => {
    const flagged = issues[b.id] && b.status === 'completed' ? { ...b, overlays: { ...b.overlays, issueReported: true } } : b
    return viewOf(flagged, vouchers.find(v => v.id === b.voucherId) ?? getVoucher(b.voucherId))
  })
}

/** One request of the store (client copy first, then the partner copy), with its voucher. Null when the id is unknown. */
export function useRequest(id: string | undefined): View | null {
  const bookings = usePrototype(s => s.clientBookings)
  const hotel = usePrototype(s => s.hotelBookings)
  const vouchers = usePrototype(s => s.vouchers)
  const issues = useBookingsFlow(s => s.issues)
  const found = bookings.find(b => b.id === (id ?? HERO_ID)) ?? hotel.find(b => b.id === (id ?? HERO_ID))
  if (!found) return null
  const b = issues[found.id] && found.status === 'completed' ? { ...found, overlays: { ...found.overlays, issueReported: true } } : found
  return viewOf(b, vouchers.find(v => v.id === b.voucherId) ?? getVoucher(b.voucherId))
}

// ---------------------------------------------------------------- the client's answer to a counter-offer (R05)

const putBooking = (s: ReturnType<typeof usePrototype.getState>, next: Booking, voucher: Voucher | null) => ({
  clientBookings: s.clientBookings.map(x => (x.id === next.id ? next : x)),
  hotelBookings: s.hotelBookings.map(x => (x.id === next.id ? next : x)),
  ...(voucher ? { vouchers: s.vouchers.map(x => (x.id === voucher.id ? voucher : x)) } : {}),
})

export const answerProposal = {
  /** R05: the client accepts one proposed date. The request becomes approved on that date; the 24 hour confirm window starts. */
  accept(bookingId: string, date: IsoDate): boolean {
    const s = usePrototype.getState()
    const b = s.clientBookings.find(x => x.id === bookingId) ?? s.hotelBookings.find(x => x.id === bookingId)
    if (!b || b.status !== 'pending' || !b.proposal) return false
    const now = clock.now()
    const next = transition(b, 'approved', now, 'client', {
      eventDate: date,
      respondBy: null,
      approvedAt: now,
      confirmBy: engine.confirmByFor(now, meta.config),
      proposal: { ...b.proposal, status: 'accepted' },
    })
    const v = s.vouchers.find(x => x.id === b.voucherId)
    // The voucher stays bound; its quote moves to the new date at the same (held) voucher price.
    usePrototype.setState(prev => putBooking(prev, next, v ? { ...v, eventDate: date } : null))
    return true
  },
  /** The client declines the dates: the request is cancelled (`counter_offer_declined`) and the voucher is released for reuse at the same venue. */
  decline(bookingId: string): boolean {
    const s = usePrototype.getState()
    const b = s.clientBookings.find(x => x.id === bookingId) ?? s.hotelBookings.find(x => x.id === bookingId)
    if (!b || b.status !== 'pending') return false
    const now = clock.now()
    const next = transition(b, 'cancelled', now, 'client', { cancelledBy: 'client', reasonCode: 'counter_offer_declined', respondBy: null, proposal: b.proposal ? { ...b.proposal, status: 'declined' } : null })
    const v = s.vouchers.find(x => x.id === b.voucherId)
    usePrototype.setState(prev => putBooking(prev, next, v ? releasedVoucher(v, 'withdrawn', now) : null))
    return true
  },
}

export { addHoursIso, variantOfBooking }
