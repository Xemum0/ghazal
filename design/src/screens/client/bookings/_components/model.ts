// Bookings flow model (ADR 0033): turns a request and its voucher into one "view" of what the client sees. A request is the booking
// object; its voucher is bound to it (pending, approved, confirmed) or released (declined, expired, cancelled) or used (redeemed,
// completed). Nothing here invents content: every request and voucher is a fixture (design/src/mock) or the live copy in the prototype
// store. Where a state has no fixture of its own (a venue cancellation, a date held by another request, a reported issue) the closest
// fixture is cloned and ONE fact is changed; those derivations are listed in docs/engineering/requests.md for the fixtures owner.
import {
  bookingTarget,
  clock,
  confirmCountdown,
  engine,
  getBooking,
  getHall,
  getPackage,
  getVenue,
  getVoucher,
  heroBookingAs,
  heroVoucherAs,
  type Booking,
  type IsoDateTime,
  type Voucher,
} from '../../../../mock'
import { releasedVoucher, transition } from '../../../../shell/state/rules'
import type { StatusKey } from '../../../../system'

export type DetailVariant =
  | 'pending'
  | 'pending-date-held'
  | 'approved-confirm-window'
  | 'approved-last-hour'
  | 'confirmed'
  | 'voucher-redeemed'
  | 'venue-proposed-date'
  | 'declined'
  | 'expired-venue-no-reply'
  | 'expired-not-confirmed'
  | 'cancelled-by-me'
  | 'cancelled-by-venue'
  | 'completed'
  | 'issue-reported'

export const DETAIL_VARIANTS: readonly DetailVariant[] = [
  'pending',
  'pending-date-held',
  'approved-confirm-window',
  'approved-last-hour',
  'confirmed',
  'voucher-redeemed',
  'venue-proposed-date',
  'declined',
  'expired-venue-no-reply',
  'expired-not-confirmed',
  'cancelled-by-me',
  'cancelled-by-venue',
  'completed',
  'issue-reported',
]

export const isDetailVariant = (v: unknown): v is DetailVariant => typeof v === 'string' && (DETAIL_VARIANTS as readonly string[]).includes(v)

export const HERO_ID = 'bk-GZ-2611-0147'

export type View = {
  variant: DetailVariant
  booking: Booking
  voucher: Voucher
  /** The instant the screen reads the confirm window from (the prototype clock, or 40 minutes before the deadline in the last-hour state). */
  now: IsoDateTime
  /** The chip the request wears (booking-state-machine section 3). */
  pill: StatusKey
}

export function addMinutesIso(iso: IsoDateTime, minutes: number): IsoDateTime {
  const ms = Date.parse(iso) + minutes * 60_000
  const kuwait = new Date(ms + 3 * 3_600_000).toISOString().replace('Z', '').replace(/\.\d{3}$/, '')
  return `${kuwait}+03:00`
}

export const addHoursIso = (iso: IsoDateTime, hours: number): IsoDateTime => addMinutesIso(iso, hours * 60)

/** The detail variant a stored request is in right now. */
export function variantOfBooking(b: Booking, now: IsoDateTime = clock.now()): DetailVariant {
  switch (b.status) {
    case 'pending':
      if (b.proposal?.status === 'proposed') return 'venue-proposed-date'
      return b.overlays.blockedByHold ? 'pending-date-held' : 'pending'
    case 'approved': {
      const c = confirmCountdown(b, now)
      return c.state === 'ended' ? 'expired-not-confirmed' : c.state === 'last_hour' ? 'approved-last-hour' : 'approved-confirm-window'
    }
    case 'confirmed':
      return 'confirmed'
    case 'redeemed':
      return 'voucher-redeemed'
    case 'completed':
      return b.overlays.issueReported ? 'issue-reported' : 'completed'
    case 'declined':
      return 'declined'
    case 'expired':
      return b.expiredReason === 'client_no_confirmation' ? 'expired-not-confirmed' : 'expired-venue-no-reply'
    case 'cancelled':
      return b.cancelledBy === 'venue' || b.cancelledBy === 'admin' ? 'cancelled-by-venue' : 'cancelled-by-me'
  }
}

export function pillOf(variant: DetailVariant): Pick<View, 'pill'> {
  switch (variant) {
    case 'pending':
    case 'pending-date-held':
      return { pill: 'pending' }
    case 'venue-proposed-date':
      return { pill: 'date_proposed' }
    case 'approved-confirm-window':
    case 'approved-last-hour':
      return { pill: 'approved' }
    case 'confirmed':
      return { pill: 'confirmed' }
    case 'voucher-redeemed':
      return { pill: 'redeemed' }
    case 'completed':
    case 'issue-reported':
      return { pill: 'completed' }
    case 'declined':
      return { pill: 'declined' }
    case 'expired-venue-no-reply':
    case 'expired-not-confirmed':
      return { pill: 'expired' }
    case 'cancelled-by-me':
    case 'cancelled-by-venue':
      return { pill: 'cancelled' }
  }
}

/** A request and its voucher as one view; `variant` is derived from the request unless given. */
export function viewOf(booking: Booking, voucher: Voucher | undefined, variant?: DetailVariant): View {
  const v = variant ?? variantOfBooking(booking)
  const voucherFound = voucher ?? getVoucher(booking.voucherId) ?? heroVoucherAs('pending')
  const now = v === 'approved-last-hour' && booking.confirmBy ? addMinutesIso(booking.confirmBy, -40) : clock.now()
  return { variant: v, booking, voucher: voucherFound, now, ...pillOf(v) }
}

/** The fixture view of one detail variant: the shared story request in that state (static frames, the canvas, `?state=`). */
export function buildView(variant: DetailVariant): View {
  const hero = (k: Parameters<typeof heroBookingAs>[0]) => ({ booking: heroBookingAs(k), voucher: heroVoucherAs(k) })
  switch (variant) {
    case 'pending':
      return viewOf(hero('pending').booking, hero('pending').voucher, variant)
    case 'pending-date-held': {
      const h = hero('pending')
      return viewOf({ ...h.booking, overlays: { ...h.booking.overlays, blockedByHold: true } }, h.voucher, variant)
    }
    case 'approved-confirm-window':
    case 'approved-last-hour': {
      const h = hero('approved')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'confirmed': {
      const h = hero('confirmed')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'voucher-redeemed': {
      const h = hero('redeemed')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'venue-proposed-date': {
      const h = hero('counter_offer')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'declined': {
      const h = hero('declined')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'expired-venue-no-reply': {
      const h = hero('expired')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'expired-not-confirmed': {
      const h = hero('lapsed')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'cancelled-by-me': {
      const h = hero('cancelled')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'cancelled-by-venue': {
      // Derived from the confirmed request: the venue cancels after the client confirmed, the voucher returns and is refundable (R13b).
      const h = hero('confirmed')
      const at = addHoursIso(h.booking.confirmedAt ?? clock.now(), 30)
      const booking = transition(h.booking, 'cancelled', at, 'venue', { cancelledBy: 'venue', reasonCode: 'hall_unavailable' })
      return viewOf(booking, releasedVoucher(h.voucher, 'venue_cancelled', at), variant)
    }
    case 'completed': {
      const h = hero('completed')
      return viewOf(h.booking, h.voucher, variant)
    }
    case 'issue-reported': {
      const h = hero('completed')
      return viewOf({ ...h.booking, overlays: { ...h.booking.overlays, issueReported: true } }, h.voucher, variant)
    }
  }
}

// ---------------------------------------------------------------- facts of a request

export const guestsOf = (b: Booking): number => (b.service ? b.service.quantity : b.sections.reduce((n, s) => n + s.guests, 0))

export function hallOf(b: Booking) {
  const first = b.sections[0]
  return first ? getHall(first.hallId) : undefined
}

export const packageOf = (b: Booking) => {
  const id = b.sections[0]?.packageId ?? b.service?.packageId
  return id ? getPackage(id) : undefined
}

/** Venue or provider the request is addressed to. */
export const targetOf = (b: Booking) => bookingTarget(b)
export const venueOf = (b: Booking) => (b.venueId ? getVenue(b.venueId) : undefined)

// ---------------------------------------------------------------- the list

export type ListGroup = 'needs' | 'pending' | 'confirmed' | 'past'

export function groupOf(variant: DetailVariant): ListGroup {
  switch (variant) {
    case 'approved-confirm-window':
    case 'approved-last-hour':
    case 'venue-proposed-date':
      return 'needs'
    case 'pending':
    case 'pending-date-held':
      return 'pending'
    case 'confirmed':
    case 'voucher-redeemed':
      return 'confirmed'
    default:
      return 'past'
  }
}

/** Pending and approved requests count against the three-open-requests limit of a wedding file. */
export const isOpenRequest = (b: Booking): boolean => b.status === 'pending' || b.status === 'approved'

/** Past-section filter value of a request. */
export type PastKind = 'completed' | 'cancelled' | 'declined' | 'expired'
export function pastKindOf(b: Booking): PastKind | null {
  return b.status === 'completed' || b.status === 'cancelled' || b.status === 'declined' || b.status === 'expired' ? b.status : null
}

/** Ids shown for the open-requests-limit frame: the story request plus two more open requests and the released ones. */
export const LIMIT_FRAME_IDS = ['bk-GZ-2611-0147', 'bk-GZ-2611-9H3D', 'bk-GZ-2611-3K8D', 'bk-GZ-2611-0098'] as const

export function fixtureView(id: string): View | null {
  const b = getBooking(id)
  return b ? viewOf(b, getVoucher(b.voucherId)) : null
}

export { engine }
