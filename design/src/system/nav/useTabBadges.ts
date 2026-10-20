// Badges of the tab bar, derived from the prototype state and the fixtures (ADR 0007 D4, ADR 0008 D2):
//   client  My Wedding: a dot only when an action is due (an approved request waiting for the client's confirmation inside 24 hours); Messages: unread count
//   hotel   Bookings: pending-request count, capped 9+, danger-tinted (always with text) when any request is in the SLA danger state;
//           Messages: unread count
import { useMemo } from 'react'
import * as mock from '../../mock'
import { useT } from '../../i18n'
import { usePrototype } from '../../shell/state'
import type { AppKind } from '../../shell/device/context'
import type { TabBarBadge } from './TabBar'

const safe = <T,>(read: () => T, fallback: T): T => {
  try {
    return read()
  } catch {
    return fallback
  }
}

export function useTabBadges(app: AppKind): Partial<Record<string, TabBarBadge | null>> {
  const auth = usePrototype(s => s.auth)
  const hotelBookings = usePrototype(s => s.hotelBookings)
  const clientBookings = usePrototype(s => s.clientBookings)
  const pendingIds = useMemo(() => hotelBookings.filter(b => b.status === 'pending' && !b.proposal).map(b => b.id), [hotelBookings])
  const tClient = useT('client-shell')
  const tHotel = useT('hotel-shell')

  return useMemo(() => {
    if (app === 'client') {
      const unread = auth === 'signedIn' ? safe(() => mock.conversationsFor('client').reduce((n, c) => n + c.unread.client, 0), 0) : 0
      const actionDue = auth === 'signedIn' && clientBookings.some(b => b.status === 'approved')
      return {
        'my-wedding': actionDue ? ({ dot: true } as TabBarBadge) : null,
        messages: unread > 0 ? { count: unread, label: tClient('clientShellTabUnread', { count: unread }) } : null,
      }
    }
    const readings = safe(() => mock.requestsFor(mock.meta.hotelVenueId), [])
    const danger = readings.some(r => pendingIds.includes(r.booking.id) && r.sla.state === 'danger')
    const pending = pendingIds.length
    const unread = safe(() => mock.conversationsFor('hotel').reduce((n, c) => n + c.unread.hotel, 0), 0)
    return {
      bookings: pending > 0 ? { count: pending, tone: danger ? 'danger' : 'gold', label: tHotel('hotelShellBadgePending', { count: pending }) } : null,
      messages: unread > 0 ? { count: unread } : null,
    } as Partial<Record<string, TabBarBadge | null>>
  }, [app, auth, pendingIds, clientBookings, tClient, tHotel])
}
