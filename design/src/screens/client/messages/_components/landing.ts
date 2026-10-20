// Where a notification lands (CA-NOTI-04). Opening a row marks it read in the shared store (so the bell counts on Home and My Wedding follow)
// and goes to the exact object on the current stack, so Back returns to the centre:
//   request approved, confirm reminder   Booking detail (the Confirm booking action is one tap away; 24 hours)
//   sent, confirmed, declined, expired,  Booking detail                          voucher ready, released, expiring,
//   cancelled, voucher redeemed                                                  refunded: Voucher detail
//   visit requested, confirmed, reminder, group-chat message: the visit group chat
//   message, planner assigned            the thread                              review prompt: Write a review
//   new venue                            Venue detail                            countdown, checklist: My Wedding
// A venue that is no longer listed reports it to the caller, which shows the "no longer listed" sheet with similar halls.
import { useMemo } from 'react'
import type { Notification } from '@gz/contracts'
import { getVenue } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { PLANNER_CONVERSATION } from './model'

export type Landing = { missingVenueId: string | null }

export function useNotificationLanding(): (n: Notification) => Landing {
  const nav = useNav()
  return useMemo(
    () => (n: Notification): Landing => {
      usePrototype.getState().markNotificationRead(n.id)
      const open = (id: string, params?: Record<string, unknown>) => nav.push(id, params)
      const venueKinds = n.kind === 'new_venue'
      if (venueKinds && n.venueId) {
        const venue = getVenue(n.venueId)
        if (!venue || venue.status !== 'published') return { missingVenueId: n.venueId }
        const eventDate = typeof n.params.eventDate === 'string' ? n.params.eventDate : null
        if (eventDate) usePrototype.getState().setBrief({ date: eventDate, dateMode: 'exact' })
        open('CL-VENU-01', { venueId: n.venueId })
        return { missingVenueId: null }
      }
      switch (n.kind) {
        case 'request_approved':
        case 'confirm_reminder':
          open('CL-BKNG-02', { bookingId: n.bookingId, section: 'confirm' })
          break
        case 'request_sent':
        case 'request_confirmed':
        case 'request_declined':
        case 'request_expired':
        case 'booking_cancelled':
        case 'voucher_redeemed':
          open('CL-BKNG-02', { bookingId: n.bookingId })
          break
        case 'voucher_ready':
        case 'voucher_released':
        case 'voucher_expiring':
        case 'credit_voucher_issued':
        case 'voucher_forfeited':
          open('CL-VCHR-03', { voucherId: n.voucherId })
          break
        case 'visit_requested':
        case 'visit_confirmed':
        case 'visit_reminder':
        case 'visit_message':
          open('CL-VIST-03', { visitId: n.visitId, conversationId: n.conversationId ?? undefined })
          break
        case 'message':
          open('CL-MSGS-02', { conversationId: n.conversationId ?? undefined, support: n.conversationId === 'conv-support-reem' || undefined })
          break
        case 'planner_assigned':
          open('CL-MSGS-02', { conversationId: n.conversationId ?? PLANNER_CONVERSATION })
          break
        case 'review_prompt':
          open('CL-RVRW-02', { bookingId: n.bookingId })
          break
        default:
          // Countdowns and checklist reminders land on the My Wedding hero.
          nav.switchTab('my-wedding')
      }
      return { missingVenueId: null }
    },
    [nav],
  )
}
