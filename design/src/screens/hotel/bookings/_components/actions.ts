// What the Bookings screens can do with a request, wired to the shared prototype store and the sheets of the Decisions flow (ADR 0008 D5-D8,
// ADR 0033 D3).
//   Accept       two taps (open the card, Accept) with the 8 s Undo toast; the compact confirm sheet (HL-DCSN-01) first only when other requests
//                wait on the date or the event is 14 days away or less (ADR 0008 D6). Accepting starts the fixed 24 h confirm window.
//   Decline      the reason sheet (HL-DCSN-02)        Propose another date   HL-DCSN-03 (a counter-offer, the voucher price is held)
//   Cancel       HL-DCSN-04 (revoke an approval or cancel a confirmed booking; shows what happens to the client's voucher)
//   Call         the contact sheet (HL-BOOK-04)       Chat   the request thread (HL-TODY-05)       Redeem   HL-BOOK-06 with the code
import { useMemo } from 'react'
import { flat } from '@gz/tokens'
import { conversationsFor, engine, getVoucher, PROTOTYPE_TODAY, type Booking } from '../../../../mock'
import { useT } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'

export type BookingRef = { id: string; eventDate: string; others?: number }

export function useBookingActions() {
  const nav = useNav()
  const t = useT('hotel-bookings')
  const c = useT('common')
  return useMemo(() => {
    const params = (b: BookingRef, extra: Record<string, unknown> = {}) => ({ bookingId: b.id, ...extra })
    const othersOf = (b: BookingRef): number => {
      if (b.others !== undefined) return b.others
      const all = usePrototype.getState().hotelBookings
      return all.filter(x => x.status === 'pending' && x.eventDate === b.eventDate && x.id !== b.id).length
    }
    return {
      open: (b: BookingRef, extra?: Record<string, unknown>) => nav.push('HL-BOOK-03', params(b, extra)),
      accept: (b: BookingRef) => {
        const urgent = engine.diffDays(PROTOTYPE_TODAY, b.eventDate) <= 14
        if (othersOf(b) > 0 || urgent) {
          nav.openSheet('HL-DCSN-01', { params: params(b) })
          return
        }
        usePrototype.getState().acceptRequest(b.id)
        const approved = usePrototype.getState().hotelBookings.find(x => x.id === b.id)
        // The 8 s Undo window passes: the approval stands.
        window.setTimeout(() => {
          const st = usePrototype.getState()
          if (st.lastHotelAction?.bookingId === b.id) st.commitHotelAction()
        }, flat['motion.duration.undo'])
        const first = approved?.clientName.trim().split(/\s+/)[0] ?? ''
        nav.toast({
          message: t('hotelBookingsAcceptedToast', { name: `⁨${first}⁩` }),
          tone: 'success',
          undo: true,
          action: { label: c('commonActionUndo'), onPress: () => usePrototype.getState().undoLastHotelAction() },
        })
      },
      propose: (b: BookingRef) => nav.openSheet('HL-DCSN-03', { params: params(b) }),
      decline: (b: BookingRef) => nav.openSheet('HL-DCSN-02', { params: params(b) }),
      cancel: (b: BookingRef) => nav.openSheet('HL-DCSN-04', { params: params(b) }),
      call: (b: BookingRef, role?: string) => nav.openSheet('HL-BOOK-04', { params: params(b, role ? { role } : {}) }),
      chat: (b: BookingRef) => nav.push('HL-TODY-05', { bookingId: b.id, conversationId: conversationsFor('hotel').find(x => x.bookingId === b.id)?.id ?? null }),
      /** Opens the redeem screen with the voucher code of this request already in the field. */
      redeem: (b: Booking) => nav.push('HL-BOOK-06', { code: getVoucher(b.voucherId)?.code ?? null, bookingId: b.id }),
      /** The Ghazal support conversation (the same one More > Support opens). */
      support: () => nav.push('HL-TODY-05', { conversationId: 'conv-support-aurelia' }),
    }
  }, [nav, t, c])
}

export const refOf = (b: Booking, others?: number): BookingRef => ({ id: b.id, eventDate: b.eventDate, others })
