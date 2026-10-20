// Flow-local helpers of hotel/decisions (HL-DCSN-01..04): which booking a sheet is about, who is signed in, deadlines, the Undo commit.
// Nothing here formats a string: dates, money and numbers come from useFormat() at the call site.
import { useContext } from 'react'
import { useLang } from '../../../../shell/lang'
import { flat } from '@gz/tokens'
import { bookingTarget, clock, engine, getBooking, getProvider, hotelStaff, meta, users, type Booking, type Hall, type IsoDate, type Session } from '../../../../mock'
import { useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { FrameContext } from '../../../../shell/frame'
import { getLoadedCatalog, useFormat } from '../../../../i18n'

/** The roles of ADR 0008 D12 that matter on these sheets. Admin includes Manager; the demo persona is the Manager. */
export type DecisionRole = 'admin' | 'manager' | 'reception' | 'accountant' | 'marketing'

/** Params every HL-DCSN sheet reads (`useNav().params`). Callers pass only what they know; everything has a story default. */
export type DecisionParams = {
  bookingId?: string
  role?: DecisionRole
  /** HL-DCSN-01: the prototype flag `simulateCompeting` (a second request exists for the date). */
  simulateCompeting?: boolean
  /** HL-DCSN-03 when it is reached from HL-DCSN-02 (the reason travels with the hand-off). */
  from?: 'decline'
  reason?: Booking['rejectReason']
}

/** The pending provider request of the fixture seed (Wudha Al-Roumi, Zahra Flowers): a service request has no hall calendar, so no proposal. */
export const PROVIDER_BOOKING_ID = 'bk-GZ-2611-4W8Q'

export const STORY_BOOKING_ID = meta.story.bookingId
/** Other fixture bookings the frames of these sheets use (docs/product/fixtures.md): a pending request whose proposed dates can sit in a
 * higher price tier (Dana), a confirmed booking the venue cancels (Lulwa) and an approved one still inside its 24 h window (Haya). */
export const DANA_BOOKING_ID = 'bk-GZ-2611-3K8D'
export const LULWA_BOOKING_ID = 'bk-GZ-2611-2P8R'
export const HAYA_BOOKING_ID = 'bk-GZ-2611-9H3D'

/** Frame state (`?state=`) of a static frame; undefined in the live player, where state comes from interaction. */
export function useFrameState(): string | undefined {
  return useContext(FrameContext)?.state
}

export function useDecisionParams(): DecisionParams {
  return useNav<DecisionParams>().params
}

/** The booking a sheet is about: the live copy of the store (so Undo and the other flows' actions show through), else the fixture. */
export function useDecisionBooking(fallbackId: string): Booking {
  const params = useDecisionParams()
  const id = params.bookingId ?? fallbackId
  const live = usePrototype(s => s.hotelBookings.find(b => b.id === id))
  const found = live ?? getBooking(id)
  if (!found) throw new Error(`hotel/decisions: unknown booking ${id}`)
  return found
}

export const useDecisionRole = (): DecisionRole => useDecisionParams().role ?? 'manager'

/** The signed-in staff member (audit trail lines). */
export const signedInStaff = () => hotelStaff.find(s => s.isYou)

/** First name of a person as typed ("ريم الدوسري" -> "ريم"): the sheets speak about the couple by first name. */
export const firstName = (full: string): string => full.trim().split(/\s+/)[0] ?? full

/** The hall, its evening session and the section a booking occupies (the first section carries the date card). Null for a provider request. */
export function hallOf(booking: Booking): { hall: Hall; session: Session | undefined; hallId: string } | null {
  const section = booking.sections[0]
  const target = bookingTarget(booking)
  if (!target.venue || !section) return null
  const hall = target.venue.halls.find(h => h.id === section.hallId) ?? (target.venue.halls[0] as Hall)
  return { hall, session: hall.sessions.find(s => s.id === section.sessionId), hallId: hall.id }
}

/** What a request is for, in one line: the hall of a venue request, the package of a provider request (both bilingual). */
export function subjectOf(booking: Booking): { en: string; ar: string } | null {
  const h = hallOf(booking)
  if (h) return h.hall.name
  const provider = booking.service ? getProvider(booking.service.providerId) : undefined
  return provider?.packages.find(p => p.id === booking.service?.packageId)?.name ?? provider?.name ?? null
}

/** `now + hours` as the instant the formatter reads (the prototype clock, never the system clock). */
export const inHours = (hours: number): string => engine.addHours(clock.now(), hours)

/** Days from the prototype today to a civil date. */
export const daysUntilDate = (date: IsoDate): number => engine.diffDays(clock.today(), date)

/** A counter-offer lasts 48 hours (booking-state-machine section 7, meta.config). */
export const proposalWindowHours = (): number => meta.config.counterOfferValidityHours

/** The fixed confirm window after an approval (owner rule, 24 h, configuration, never partner-editable). */
export const confirmWindowHours = (): number => meta.config.confirmWindowHours

/** How many dates a proposal may carry (ADR 0008 D7: one to three). */
export const MAX_PROPOSED = 3

/** How far ahead the open-dates calendar looks (HL-DCSN-03 empty state: "next 90 days"). */
export const PROPOSAL_HORIZON_DAYS = 90

/**
 * The Undo window of an Accept: the booking stays accepted unless Undo is pressed inside it, then the action is committed (ADR 0008 D6).
 * A module-level timer on purpose: the sheet that started it is gone by then.
 */
export function commitAfterUndoWindow(bookingId: string): void {
  window.setTimeout(() => {
    const s = usePrototype.getState()
    if (s.lastHotelAction?.bookingId === bookingId) s.commitHotelAction()
  }, flat['motion.duration.undo'])
}

/**
 * Bring the bottom of `el` into view inside the sheet's scrolling middle, scrolling no further than needed (a pick or a choice just
 * changed what is below the fold: the proposal list, the refund). Never scrolls the page or the device frame, only the sheet body.
 */
export function revealInSheet(el: HTMLElement | null, smooth = true): void {
  const scroller = el?.closest<HTMLElement>('.gzd-sheet__content')
  if (!el || !scroller) return
  const delta = el.getBoundingClientRect().bottom - scroller.getBoundingClientRect().bottom
  if (delta > 0) scroller.scrollBy({ top: delta + flat['space.4'], behavior: smooth ? 'smooth' : 'auto' })
}

/** One message of this flow's namespace in both languages (a record that outlives the screen: a Booking Thread label is stored bilingual). */
export function bothLangs(key: string, fallback: string): { en: string; ar: string } {
  return {
    en: getLoadedCatalog('en', 'hotel-decisions')?.[key] ?? fallback,
    ar: getLoadedCatalog('ar', 'hotel-decisions')?.[key] ?? fallback,
  }
}

/**
 * A whole number of hours as a compact figure (`24 h`, Arabic `24 س`) built from the formatter's own unit letter: the shared compact
 * duration would turn 24 h into `1 d`, and the confirm and reply windows are always read in hours (24 h, 48 h). Render it through <Fx>.
 */
export function useHoursFig(): (hours: number) => string {
  const f = useFormat()
  return hours => {
    const unit = f.duration(3_600_000).match(/[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+/)?.[0] ?? ''
    return `${f.integer(hours)}\u00a0${unit}`
  }
}

/** The session glyph of the diet (day = sun, afternoon = sunset, evening = moon): the glyph is the value, no word. */
export function sessionGlyph(start: string): 'sun' | 'sunset' | 'moon' {
  const hour = Number(start.split(':')[0])
  return hour < 12 ? 'sun' : hour < 17 ? 'sunset' : 'moon'
}

/** The couple's name in the reading language (users[].nameLatin in English, the Arabic name otherwise), plus the first name the sentences use. */
export function useClientName(booking: Booking): { full: string; first: string } {
  const { lang } = useLang()
  const user = users.find(u => u.id === booking.clientId)
  const full = lang === 'en' ? (user?.nameLatin ?? booking.clientName) : booking.clientName
  return { full, first: firstName(full) }
}
