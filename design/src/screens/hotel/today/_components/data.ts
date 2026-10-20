// Selectors for the Today flow (voucher model, ADR 0033): the live request queue (the shared store's partner bookings joined to the SLA
// readings), the Needs-you queue for a venue and for a provider, today's events, the strip, the voucher tiles and the notification and
// message lists. Content only from the fixtures and the prototype store; no figure is typed here. There is no money in this flow: Ghazal
// holds no event payment, so there are no revenue, payable or balance selectors any more.
import { useMemo } from 'react'
import type { Bilingual, Booking, Conversation, Listing, Message, Notification, PendingRequest, RequestItem, VisitAppointment, VoucherWindow } from '@gz/contracts'
import {
  analytics,
  bookingsFor,
  calendarClaims,
  conversationsFor,
  engine,
  getBooking,
  getVenue,
  hotelNotifications,
  hotelSettings,
  messagesFor,
  needsYou,
  PROTOTYPE_NOW,
  PROTOTYPE_TODAY,
  requestsFor,
  slaOf,
  softDatesFor,
  windowsFor,
  getHall,
} from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { PROVIDER_ID, VENUE_ID, minutesBetween, type AccountKind } from './bits'
import { useTodayLocal } from './store'

export { VENUE_ID, PROVIDER_ID }

// ---------------------------------------------------------------- the queue

/** Pending requests still waiting for the venue: the fixtures' SLA readings, minus what the prototype has approved or declined. */
export function usePendingRequests(): PendingRequest[] {
  const bookings = usePrototype(s => s.hotelBookings)
  return useMemo(() => {
    const pending = new Set(bookings.filter(b => b.status === 'pending' && !b.proposal).map(b => b.id))
    return requestsFor(VENUE_ID).filter(r => pending.has(r.booking.id))
  }, [bookings])
}

export type Reading = { state: 'neutral' | 'gold' | 'danger' | 'expired'; elapsed: number; minutesLeft: number }

/** What a Needs-you row is about; the row's icon, its tap target and its filter chip follow from it. */
export type NeedKind = 'request' | 'awaiting' | 'visit' | 'message' | 'review' | 'calendar' | 'listing' | 'window'

/** One row of the Needs-you queue, from either account type. A venue request carries its triage card; a provider request or an
 *  approved request waiting for the client carries its booking; a listing decision carries the listing. */
export type NeedItem = {
  id: string
  kind: NeedKind
  request: PendingRequest | null
  booking: Booking | null
  listing: Listing | null
  visit: VisitAppointment | null
  conversationId: string | null
  reviewId: string | null
  /** The voucher-price window about to end (the Marketing role's Needs-you row). */
  window: VoucherWindow | null
  /** Fixture headline for message, review and calendar rows (request and visit rows are composed from their object). */
  title: Bilingual | null
  subtitle: Bilingual | null
  raisedAt: string
  /** The reply window of a request, or the 24 h confirm window of an approved request. */
  sla: Reading | null
}

const blank = (id: string, kind: NeedKind, raisedAt: string): NeedItem => ({
  id,
  kind,
  request: null,
  booking: null,
  listing: null,
  visit: null,
  conversationId: null,
  reviewId: null,
  window: null,
  title: null,
  subtitle: null,
  raisedAt,
  sla: null,
})

/** The 24 h confirm window of an approved request, read like an SLA (it never turns red: the row shows it calmly). */
function confirmReading(b: Booking): Reading | null {
  if (!b.confirmBy) return null
  const total = minutesBetween(b.approvedAt ?? PROTOTYPE_NOW, b.confirmBy)
  const left = minutesBetween(PROTOTYPE_NOW, b.confirmBy)
  const waited = minutesBetween(b.approvedAt ?? PROTOTYPE_NOW, PROTOTYPE_NOW)
  return { state: left <= 0 ? 'expired' : 'neutral', elapsed: total > 0 ? waited / total : 1, minutesLeft: left }
}

/** Order inside the queue: requests by deadline, then what needs a person without a clock, then what only waits for the client. */
const RANK: Record<NeedKind, number> = { request: 0, listing: 1, visit: 2, message: 3, review: 4, window: 5, calendar: 6, awaiting: 7 }

const byQueueOrder = (a: NeedItem, b: NeedItem): number => {
  if (a.kind === 'request' && b.kind === 'request') return (a.sla?.minutesLeft ?? 0) - (b.sla?.minutesLeft ?? 0)
  if (a.kind === 'awaiting' && b.kind === 'awaiting') return (a.sla?.minutesLeft ?? 0) - (b.sla?.minutesLeft ?? 0)
  return RANK[a.kind] - RANK[b.kind]
}

const EXPIRING_DAYS = 7

/**
 * The whole Needs-you queue. A venue: pending requests, visit requests, the unanswered message, a review waiting for a reply, the weekly
 * calendar check, then the requests it approved that wait for the client (they need nothing from the venue, so they sit last).
 * A service provider: pending requests, a listing decision (not approved, or ending soon), then approved requests.
 */
export function useNeedsYou(account: AccountKind = 'venue'): NeedItem[] {
  const bookings = usePrototype(s => s.hotelBookings)
  const visits = usePrototype(s => s.visits)
  const listings = usePrototype(s => s.listings)
  const confirmed = useTodayLocal(s => s.calendarConfirmed)
  const replied = useTodayLocal(s => s.repliedConversations)
  return useMemo(() => {
    const out: NeedItem[] = []

    if (account === 'provider') {
      for (const b of bookingsFor({ providerId: PROVIDER_ID })) {
        if (b.status === 'pending' && b.respondBy) {
          const sla = slaOf({ raisedAt: b.createdAt, dueAt: b.respondBy } as RequestItem)
          out.push({ ...blank(`req-${b.id}`, 'request', b.createdAt), booking: b, sla })
        } else if (b.status === 'approved') {
          out.push({ ...blank(`await-${b.id}`, 'awaiting', b.approvedAt ?? b.createdAt), booking: b, sla: confirmReading(b) })
        }
      }
      for (const l of listings.filter(x => x.providerId === PROVIDER_ID)) {
        const days = l.endsOn ? engine.diffDays(PROTOTYPE_TODAY, l.endsOn) : null
        const expiring = l.status === 'active' && days !== null && days >= 0 && days <= EXPIRING_DAYS
        if (l.status === 'rejected' || expiring) out.push({ ...blank(`lst-${l.id}`, 'listing', l.decidedAt ?? l.submittedAt ?? PROTOTYPE_NOW), listing: l })
      }
      return out.sort(byQueueOrder)
    }

    const pending = new Set(bookings.filter(b => b.status === 'pending' && !b.proposal).map(b => b.id))
    for (const r of requestsFor(VENUE_ID)) {
      if (pending.has(r.booking.id)) out.push({ ...blank(r.item.id, 'request', r.item.raisedAt), request: r, booking: r.booking, sla: r.sla })
    }
    for (const v of visits.filter(x => x.venueId === VENUE_ID && x.status === 'requested')) {
      out.push({ ...blank(`visit-${v.id}`, 'visit', v.requestedAt), visit: v, conversationId: v.conversationId })
    }
    for (const { item } of needsYou(VENUE_ID)) {
      if (item.type === 'message' && item.conversationId && !replied.includes(item.conversationId)) {
        out.push({ ...blank(item.id, 'message', item.raisedAt), conversationId: item.conversationId, title: item.title, subtitle: item.subtitle, booking: item.bookingId ? (getBooking(item.bookingId) ?? null) : null })
      } else if (item.type === 'review_reply') {
        out.push({ ...blank(item.id, 'review', item.raisedAt), reviewId: item.reviewId, title: item.title, subtitle: item.subtitle })
      } else if (item.type === 'calendar_confirm' && !confirmed) {
        out.push({ ...blank(item.id, 'calendar', item.raisedAt), title: item.title, subtitle: item.subtitle })
      }
    }
    for (const b of bookings.filter(x => x.status === 'approved')) {
      out.push({ ...blank(`await-${b.id}`, 'awaiting', b.approvedAt ?? b.createdAt), booking: b, sla: confirmReading(b) })
    }
    // Fixture order for the rows without a clock (message, visit, review, calendar), then the waiting ones.
    return out.sort(byQueueOrder)
  }, [account, bookings, visits, listings, confirmed, replied])
}

export type NeedFilter = 'all' | 'request' | 'visit' | 'message' | 'review' | 'calendar' | 'listing'
export const FILTER_KINDS: Record<Exclude<NeedFilter, 'all'>, NeedKind[]> = {
  request: ['request', 'awaiting'],
  visit: ['visit'],
  message: ['message'],
  review: ['review'],
  calendar: ['calendar'],
  listing: ['listing', 'window'],
}

export const countFor = (items: NeedItem[], filter: NeedFilter): number => (filter === 'all' ? items.length : items.filter(x => FILTER_KINDS[filter].includes(x.kind)).length)

// ---------------------------------------------------------------- today's events

export type DayEvent = {
  id: string
  bookingId: string
  hallId: string
  hallName: { en: string; ar: string }
  audience: 'women' | 'men' | 'mixed'
  guests: number
  clientName: string
  start: string
  end: string
  setup: string
  /** The booking's voucher has been redeemed at the venue (a confirmed booking still waits for it). */
  redeemed: boolean
}

const minusMin = (hhmm: string, mins: number) => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  const t = (((h * 60 + m - mins) % 1440) + 1440) % 1440
  return `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`
}

/** The venue's events on the prototype's today, in start order, with the setup time derived from the session buffer and the voucher state
 *  read from the live store (a redeem on HL-BOOK-06 flips the row). */
export function useEventsToday(): DayEvent[] {
  const bookings = usePrototype(s => s.hotelBookings)
  return useMemo(
    () =>
      calendarClaims
        .filter(c => c.venueId === VENUE_ID && c.date === PROTOTYPE_TODAY && c.kind === 'booking')
        .map(c => {
          const found = getHall(c.hallId)
          const session = found?.hall.sessions[0]
          const start = c.start ?? session?.start ?? '21:00'
          const booking = bookings.find(b => b.id === c.bookingId) ?? (c.bookingId ? getBooking(c.bookingId) : undefined)
          return {
            id: c.id,
            bookingId: c.bookingId ?? '',
            hallId: c.hallId,
            hallName: found?.hall.name ?? { en: '', ar: '' },
            audience: (c.audience ?? 'women') as DayEvent['audience'],
            guests: c.guests ?? 0,
            clientName: c.clientName ?? '',
            start,
            end: c.end ?? session?.end ?? '02:00',
            setup: minusMin(start, session?.bufferBeforeMin ?? 120),
            redeemed: booking ? booking.status === 'redeemed' || booking.status === 'completed' : false,
          }
        })
        .sort((a, b) => a.start.localeCompare(b.start)),
    [bookings],
  )
}

// ---------------------------------------------------------------- the strip

export type StripMarkKind = 'confirmed' | 'pending' | 'open'

/** Seven days from today, one mark per hall: booked or blocked = solid, an approved request waiting for the client (held) = gold, nothing = open. */
export function stripDays(count = 7): { iso: string; marks: StripMarkKind[] }[] {
  const halls = getVenue(VENUE_ID)?.halls ?? []
  return Array.from({ length: count }, (_, i) => {
    const iso = engine.addDays(PROTOTYPE_TODAY, i)
    const marks: StripMarkKind[] = halls.map(h => {
      const claims = calendarClaims.filter(c => c.venueId === VENUE_ID && c.hallId === h.id && c.date === iso)
      if (claims.some(c => c.kind === 'booking' || c.kind === 'block')) return 'confirmed'
      if (claims.length > 0) return 'pending'
      return 'open'
    })
    return { iso, marks }
  })
}

export const softDateCount = (): number => softDatesFor(VENUE_ID).length

// ---------------------------------------------------------------- the voucher tiles (counts only, never money)

export type VenueTiles = { requests: number; redeemed: number; awaiting: number; openDates: number }

/** Hero "Requests this month" with "vouchers redeemed" under it, "Awaiting client confirmation" (live from the store) and "Open dates". */
export function useVenueTiles(): VenueTiles {
  const bookings = usePrototype(s => s.hotelBookings)
  return useMemo(
    () => ({
      requests: analytics.tiles.requests,
      redeemed: analytics.tiles.vouchersRedeemed,
      awaiting: bookings.filter(b => b.status === 'approved').length,
      openDates: analytics.tiles.openDatesNext30Days,
    }),
    [bookings],
  )
}

const monthOf = (iso: string) => iso.slice(0, 7)

export type ProviderTiles = { requests: number; redeemed: number; live: number; inReview: number; notApproved: number; endsOn: string | null }

/** The provider's three tiles: requests this month, vouchers redeemed this month and the listing lifecycle at a glance. */
export function useProviderTiles(): ProviderTiles {
  const listings = usePrototype(s => s.listings)
  return useMemo(() => {
    const mine = bookingsFor({ providerId: PROVIDER_ID })
    const month = monthOf(PROTOTYPE_TODAY)
    const own = listings.filter(l => l.providerId === PROVIDER_ID)
    const live = own.filter(l => l.status === 'active')
    return {
      requests: mine.filter(b => monthOf(b.createdAt) === month).length,
      redeemed: mine.filter(b => b.redeemedAt && monthOf(b.redeemedAt) === month).length,
      live: live.length,
      inReview: own.filter(l => l.status === 'pending_review').length,
      notApproved: own.filter(l => l.status === 'rejected').length,
      endsOn: live.map(l => l.endsOn ?? '').sort().pop() || null,
    }
  }, [listings])
}

/** The listing the review banner is about: the one waiting for a decision. */
export function useListingInReview(): Listing | null {
  const listings = usePrototype(s => s.listings)
  return useMemo(() => listings.find(l => l.providerId === PROVIDER_ID && l.status === 'pending_review') ?? null, [listings])
}

export const viewsLastSevenDays = (): { total: number; previous: number } => {
  const pts = analytics.series.find(s => s.id === 'views')?.points ?? []
  const last = pts.slice(-7).reduce((a, p) => a + p.value, 0)
  const before = pts.slice(-14, -7).reduce((a, p) => a + p.value, 0)
  return { total: last, previous: before }
}

/** Voucher price windows that are running (the Marketing role's list; the old offers). */
export const activeWindows = () => windowsFor(VENUE_ID).filter(w => w.status === 'active')

/** The billing glance of the Accountant role: the plan and when it ends, or the major-hotel exemption. */
export const billing = () => hotelSettings.billing

// ---------------------------------------------------------------- messages and notifications

export function useAwaitingConversation(): Conversation | null {
  const opened = useTodayLocal(s => s.openedConversations)
  const replied = useTodayLocal(s => s.repliedConversations)
  return useMemo(() => conversationsFor('hotel').find(c => c.awaitingReplySince && c.kind !== 'support' && c.kind !== 'visit_group' && !opened.includes(c.id) && !replied.includes(c.id)) ?? null, [opened, replied])
}

export const minutesWaiting = (c: Conversation): number => (c.awaitingReplySince ? minutesBetween(c.awaitingReplySince, PROTOTYPE_NOW) : 0)

/** The conversations of the hotel's inbox: the seed's, plus the group chats the prototype opened for visits booked in this session. */
export function useInboxConversations(): Conversation[] {
  const chats = usePrototype(s => s.visitChats)
  return useMemo(() => {
    const seeded = conversationsFor('hotel')
    const have = new Set(seeded.map(c => c.id))
    const added = Object.values(chats)
      .map(x => x.conversation)
      .filter(c => c.venueId === VENUE_ID && !have.has(c.id))
    return [...added, ...seeded].sort((a, b) => (a.pinned === b.pinned ? (a.lastMessageAt < b.lastMessageAt ? 1 : -1) : a.pinned ? -1 : 1))
  }, [chats])
}

export function lastMessage(conversationId: string): Message | null {
  const stored = Object.values(usePrototype.getState().visitChats).find(x => x.conversation.id === conversationId)
  const list = (stored ? stored.messages : messagesFor(conversationId, 'hotel')).filter(m => !m.draft)
  return list[list.length - 1] ?? null
}

/** The partner's notification list, newest first, with the shared store's read flags applied. A provider's list is composed from their
 *  own requests and listing decisions (the seed's hotel list belongs to the venue). */
export function useHotelNotifications(account: AccountKind = 'venue'): Notification[] {
  const read = usePrototype(s => s.readNotificationIds)
  const listings = usePrototype(s => s.listings)
  return useMemo(() => {
    const base = account === 'provider' ? providerNotifications(listings) : hotelNotifications
    return [...base].sort((a, b) => (a.at < b.at ? 1 : -1)).map(n => ({ ...n, read: n.read || read.includes(n.id) }))
  }, [account, listings, read])
}

const empty: Bilingual = { en: '', ar: '' }

/** Notifications of the service-provider account: requests (from their bookings) and listing decisions (from the review trail). Their
 *  text is composed by the row from the messages (title and body left empty here), so it follows the language. */
function providerNotifications(listings: Listing[]): Notification[] {
  const base = { audience: 'hotel' as const, userId: 'user-zahra', params: {}, channel: 'transactional' as const, conversationId: null, venueId: null, title: empty, body: empty, tag: null, voucherId: null, visitId: null }
  const out: Notification[] = []
  for (const l of listings.filter(x => x.providerId === PROVIDER_ID)) {
    for (const h of l.history) {
      if (h.to === 'pending_review' && h.actor === 'provider') out.push({ ...base, id: `ntf-${h.id}`, kind: 'listing_submitted', at: h.at, read: true, tone: 'neutral', bookingId: null, listingId: l.id, params: { listing: l.title.en } })
      if (h.to === 'approved' && h.actor === 'moderator') out.push({ ...base, id: `ntf-${h.id}`, kind: 'listing_approved', at: h.at, read: true, tone: 'success', bookingId: null, listingId: l.id })
      if (h.to === 'rejected' && h.actor === 'moderator') out.push({ ...base, id: `ntf-${h.id}`, kind: 'listing_rejected', at: h.at, read: false, tone: 'gold', bookingId: null, listingId: l.id })
    }
  }
  for (const b of bookingsFor({ providerId: PROVIDER_ID })) {
    if (b.status === 'pending') out.push({ ...base, id: `ntf-req-${b.id}`, kind: 'new_request', at: b.createdAt, read: false, tone: 'gold', bookingId: b.id, listingId: null })
    if (b.status === 'redeemed' && b.redeemedAt) out.push({ ...base, id: `ntf-red-${b.id}`, kind: 'voucher_redeemed_by_you', at: b.redeemedAt, read: true, tone: 'success', bookingId: b.id, listingId: null })
  }
  return out
}

export { slaOf, getBooking }
