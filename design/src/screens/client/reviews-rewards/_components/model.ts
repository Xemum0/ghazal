// Reviews and rewards, the model: which venue and booking a screen is about, who may review, how reviews are filtered and sorted, and
// and the viewer's own review shaped as a fixture review. All content is the shared fixtures.
import type { Booking, Review, Venue } from '../../../../mock'
import {
  bookingsFor,
  getBooking,
  getVenue,
  heroBookingAs,
  meta,
  requireVenue,
  reviewsFor,
  stress,
  users,
} from '../../../../mock'
import type { SentReview } from './store'

// ---------------------------------------------------------------- the venue and the booking a screen is about

/** The completed stay the Booking detail's Completed variant shows (CL-BKNG-02): the signed-in persona's finished event at Aurelia. */
export const COMPLETED_STAY_ID = 'bk-GZ-2608-6N8F'
/** A venue with no reviews at all (stress fixture S03): the "New" state. */
export const NEW_VENUE_ID = 'S03'

export const venueById = (id: string | undefined): Venue => {
  const found = id ? getVenue(id) ?? stress.venues.find(v => v.id === id) : undefined
  return found ?? requireVenue(meta.hotelVenueId)
}

/** The booking a review is about; Aurelia's completed stay unless the caller names another. */
export const bookingById = (id: string | undefined): Booking => (id ? getBooking(id) : undefined) ?? getBooking(COMPLETED_STAY_ID) ?? heroBookingAs('pending')

/**
 * The finished stay a signed-in viewer may review at this venue. Prototype stand-in: the fixtures hold no completed booking for the
 * persona, so the stay the Booking detail shows as Completed (CL-BKNG-02) counts as hers at Aurelia (requests.md carries the ask for
 * a real one). With real data the first line wins and the stand-in goes away.
 */
export function completedStayAt(venueId: string): Booking | null {
  const own = bookingsFor({ clientId: meta.clientUserId, venueId, status: 'completed' })[0]
  if (own) return own
  return venueId === meta.hotelVenueId ? getBooking(COMPLETED_STAY_ID) ?? null : null
}

/** The next event the persona has at this venue (the story request): "Reviews open after your event on ...". */
export function upcomingStayAt(venueId: string): Booking | null {
  return bookingsFor({ clientId: meta.clientUserId, venueId, status: ['pending', 'approved', 'confirmed', 'redeemed'] })[0] ?? null
}

export type Eligibility = 'eligible' | 'upcoming' | 'guest' | 'general'

export function eligibilityAt(venueId: string, signedIn: boolean): { kind: Eligibility; booking: Booking | null } {
  if (!signedIn) return { kind: 'guest', booking: null }
  const done = completedStayAt(venueId)
  if (done) return { kind: 'eligible', booking: done }
  const next = upcomingStayAt(venueId)
  if (next) return { kind: 'upcoming', booking: next }
  return { kind: 'general', booking: null }
}

// ---------------------------------------------------------------- reviews: filter and sort

export type StarFilter = 5 | 4 | 3
export type ReviewFilter = 'photos' | StarFilter
export type ReviewSort = 'recent' | 'highest' | 'lowest'

export const SORTS: readonly ReviewSort[] = ['recent', 'highest', 'lowest']

// The seeded reviews carry no photographs, so the strip, the viewer and the "With photos" chip would never show. Every third review (the
// first, fourth, seventh...) borrows one or two of the venue's own frames (hall, stage, buffet: no people), so a normal browse meets them.
const PHOTO_EVERY = 3

export function venueReviews(venueId: string): Review[] {
  const list = reviewsFor(venueId)
  const gallery = getVenue(venueId)?.gallery ?? []
  if (gallery.length === 0) return list
  return list.map((r, i) => {
    if (r.photos.length > 0 || i % PHOTO_EVERY !== 0) return r
    const first = (i / PHOTO_EVERY) % gallery.length
    const at = (n: number) => gallery[n % gallery.length]!.file
    const files = [at(first), at(first + 1)].slice(0, i % 2 === 0 ? 2 : 1)
    return { ...r, photos: [...new Set(files)] }
  })
}

export function filterReviews(list: readonly Review[], filter: ReviewFilter | null, sort: ReviewSort): Review[] {
  const kept = list.filter(r => {
    if (filter === null) return true
    if (filter === 'photos') return r.photos.length > 0
    // Scores come in half steps. 5 stars is 4.5 and up, 4 stars sits above 3.5 and below 4.5, "3 and below" takes 3.5 and under.
    if (filter === 5) return r.rating >= 4.5
    if (filter === 4) return r.rating > 3.5 && r.rating < 4.5
    return r.rating <= 3.5
  })
  const by = (a: Review, b: Review) => (a.postedAt < b.postedAt ? 1 : -1)
  return [...kept].sort((a, b) => (sort === 'recent' ? by(a, b) : sort === 'highest' ? b.rating - a.rating || by(a, b) : a.rating - b.rating || by(a, b)))
}

// ---------------------------------------------------------------- the viewer's own review

/** First name plus the initial of the family name (ريم د. / Reem D.), the way every reviewer is shown. */
export function reviewerName(userId: string = meta.clientUserId): { en: string; ar: string; monogram: string } {
  const u = users.find(x => x.id === userId)
  const short = (full: string, strip: RegExp): string => {
    const words = full.trim().split(/\s+/)
    const first = words[0] ?? ''
    const last = (words.length > 1 ? words[words.length - 1] : '') ?? ''
    const initial = Array.from(last.replace(strip, ''))[0]
    return initial ? `${first} ${initial.toUpperCase()}.` : first
  }
  return {
    en: short(u?.nameLatin ?? 'Reem Al-Dosari', /^Al-?/i),
    ar: short(u?.name ?? 'ريم الدوسري', /^ال/),
    monogram: u?.monogram ?? 'ر',
  }
}

const HAS_ARABIC = /[\u0600-\u06FF]/

/** The review the viewer sent, shaped as a fixture review so the shared card draws it. Photos still in moderation are hers alone. */
export function ownReview(sent: SentReview, booking: Booking): Review {
  const who = reviewerName()
  const filled = (v: number) => (v > 0 ? v : sent.rating)
  return {
    id: `own-${sent.bookingId}`,
    venueId: sent.venueId,
    author: { en: who.en, ar: who.ar },
    monogram: who.monogram,
    anonymous: sent.anonymous,
    rating: sent.rating,
    categories: { venue: filled(sent.categories.venue), food: filled(sent.categories.food), service: filled(sent.categories.service), value: filled(sent.categories.value) },
    text: { en: sent.text, ar: sent.text },
    origin: HAS_ARABIC.test(sent.text) ? 'ar' : 'en',
    audience: booking.sections[0]?.audience === 'men' ? 'men' : 'women',
    hallId: booking.sections[0]?.hallId ?? null,
    eventDate: booking.eventDate,
    postedAt: sent.sentAt,
    ownerReply: null,
    replyDraft: null,
    verifiedBooking: true,
    photos: sent.media.filter(m => m.status !== 'rejected').map(m => m.file),
  }
}
