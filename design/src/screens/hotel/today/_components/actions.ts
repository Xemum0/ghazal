// What a hotel manager can do to a request from Today and Needs you (ADR 0008 D5-D7), wired to the shared prototype store.
//   Accept: two taps from the row (expand, Accept) with the 8 s Undo toast; a compact confirm sheet first (HL-DCSN-01) only when
//           other requests wait on the date or the event is 14 days away or less (ADR 0008 D6)
//   Reschedule: the Propose another date sheet (HL-DCSN-03)   Decline: the reason sheet (HL-DCSN-02), required
//   open: Booking detail (HL-BOOK-03)   chat: the conversation   call: the contact sheet (HL-BOOK-04)
import { useMemo } from 'react'
import type { PendingRequest } from '@gz/contracts'
import { conversationsFor, engine, PROTOTYPE_TODAY } from '../../../../mock'
import { useT } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'

export function useRequestActions() {
  const nav = useNav()
  const t = useT('hotel-today')
  const c = useT('common')
  return useMemo(() => {
    const params = (r: PendingRequest) => ({ bookingId: r.booking.id })
    const accept = (r: PendingRequest) => {
      const urgent = engine.diffDays(PROTOTYPE_TODAY, r.booking.eventDate) <= 14
      if (r.otherRequestsSameDate > 0 || urgent) {
        nav.openSheet('HL-DCSN-01', { params: params(r) })
        return
      }
      const store = usePrototype.getState()
      store.acceptRequest(r.booking.id)
      nav.toast({
        message: t('hotelTodayAcceptedToast'),
        tone: 'success',
        undo: true,
        action: { label: c('commonActionUndo'), onPress: () => usePrototype.getState().undoLastHotelAction() },
      })
    }
    return {
      accept,
      reschedule: (r: PendingRequest) => nav.openSheet('HL-DCSN-03', { params: params(r) }),
      decline: (r: PendingRequest) => nav.openSheet('HL-DCSN-02', { params: params(r) }),
      open: (r: PendingRequest) => nav.push('HL-BOOK-03', params(r)),
      chat: (r: PendingRequest) => nav.push('HL-TODY-05', { bookingId: r.booking.id, conversationId: conversationsFor('hotel').find(c => c.bookingId === r.booking.id)?.id ?? null }),
      call: (r: PendingRequest) => nav.openSheet('HL-BOOK-04', { params: params(r) }),
      compare: (r: PendingRequest) => nav.push('HL-BOOK-03', { ...params(r), conflict: true }),
    }
  }, [nav, t, c])
}

