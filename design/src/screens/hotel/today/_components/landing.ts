// Where a partner notification lands (ADR 0008 D13, ADR 0033). The stack is rebuilt "tab root, parent, target" so Back makes sense:
//   new request, client confirmed, confirm window ended, cancelled, voucher redeemed   Bookings tab, then Booking detail
//   new message                                                                         Messages tab, then the thread with its booking context bar
//   visit request                                                                       Visits (HL-VIST-02), the visit detail with its group chat
//   visit chat message                                                                  Messages tab, then the visit group chat (HL-VIST-03)
//   listing submitted, approved, not approved, ending                                   the listing status (HL-PROV-06)
//   new review                                                                          the review with Reply
//   weekly calendar check, staff invitation                                             the Calendar tab / Staff and roles
// Opening a row marks it read in the shared store, so the bell count on Today follows.
import { useMemo } from 'react'
import type { Notification } from '@gz/contracts'
import { needsYou } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { VENUE_ID } from './bits'

export function useNotificationLanding() {
  const nav = useNav()
  return useMemo(
    () => (n: Notification) => {
      usePrototype.getState().markNotificationRead(n.id)
      const booking = (extra: Record<string, unknown> = {}) => {
        nav.switchTab('bookings')
        nav.push('HL-BOOK-03', { bookingId: n.bookingId, ...extra })
      }
      switch (n.kind) {
        case 'new_request':
        case 'client_confirmed':
        case 'client_lapsed':
        case 'voucher_redeemed_by_you':
          return booking()
        case 'booking_cancelled':
          return booking({ offerPrompt: true })
        case 'message':
          nav.switchTab('messages')
          nav.push('HL-TODY-05', { conversationId: n.conversationId, bookingId: n.bookingId })
          return
        case 'visit_request':
          nav.push('HL-VIST-02', { visitId: n.visitId })
          return
        case 'visit_message':
          nav.switchTab('messages')
          nav.push('HL-VIST-03', { visitId: n.visitId })
          return
        case 'listing_submitted':
        case 'listing_approved':
        case 'listing_rejected':
        case 'listing_expiring':
          nav.push('HL-PROV-06', { listingId: n.listingId, account: 'provider' })
          return
        case 'review_received': {
          const review = needsYou(VENUE_ID).find(x => x.item.type === 'review_reply')?.item.reviewId ?? null
          nav.push('HL-GROW-06', { reviewId: review })
          return
        }
        case 'calendar_confirm':
          nav.switchTab('calendar')
          return
        case 'invite':
          nav.push('HL-SETT-03')
          return
        default:
          if (n.bookingId) booking()
      }
    },
    [nav],
  )
}
