// Visits flow model: who may do what, which visit a frame draws, and the arithmetic of the visit clock (ADR 0033 D9, voucher-model section 11).
// Visits come from the shared prototype store (the client app's bookVisit writes to the same list), venue-scoped. A frame that needs a status
// the seed does not have derives it from a seed visit (same people, same venue, only the status and the clock-relative slot change); nothing
// is invented in a screen. Every number a person reads comes from useFormat().
import { useMemo } from 'react'
import {
  engine,
  getVenue,
  getVisit,
  groupThreadFor,
  hotelStaff,
  meta,
  PROTOTYPE_NOW,
  PROTOTYPE_TODAY,
  visitDatesFor,
  visitSlotsFor,
  type GroupThread,
  type HotelStaff,
  type Message,
  type StaffRole,
  type VisitAppointment,
  type VisitStatus,
} from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useVisitsLocal } from './store'

export const VENUE_ID: string = meta.hotelVenueId

// ---------------------------------------------------------------- roles (ADR 0008 D12)

export type VisitRole = StaffRole
export const ROLES: readonly VisitRole[] = ['admin', 'manager', 'reception', 'accountant', 'marketing']

/** Admin, Manager and Reception reply to visits; Accountant and Marketing do not see the visit screens at all. */
export const canSee = (role: VisitRole): boolean => role === 'admin' || role === 'manager' || role === 'reception'
/** Admin and Manager read every visit chat and may reassign the representative and set the venue's availability. */
export const isLead = (role: VisitRole): boolean => role === 'admin' || role === 'manager'

export const roleOfParam = (value: unknown): VisitRole => (typeof value === 'string' && (ROLES as readonly string[]).includes(value) ? (value as VisitRole) : 'manager')

/** The staff member who is the assigned representative in the seed (Amal, Reception). */
export const staffById = (userId: string): HotelStaff | undefined => hotelStaff.find(s => s.userId === userId && s.venueId === VENUE_ID)

/** Staff with the visit permission (Admin, Manager, Reception), active only: the pool the representative is picked from. */
export const visitStaff = (): HotelStaff[] => hotelStaff.filter(s => s.venueId === VENUE_ID && s.status === 'active' && canSee(s.role))

// ---------------------------------------------------------------- the visit clock

const MIN = 60_000
const at = (iso: string): number => new Date(iso).getTime()
export const NOW_MS: number = at(PROTOTYPE_NOW)

export const slotDay = (v: VisitAppointment): string => v.slotStart.slice(0, 10)
export const isToday = (v: VisitAppointment): boolean => slotDay(v) === PROTOTYPE_TODAY
export const minutesSinceSlot = (v: VisitAppointment): number => Math.round((NOW_MS - at(v.slotStart)) / MIN)
/** Missed may be flagged from 30 minutes after the slot and within 24 hours after it (HL-VIST-04). */
export const canFlagMissed = (v: VisitAppointment): boolean => {
  const m = minutesSinceSlot(v)
  return m >= 30 && m <= 24 * 60
}
/** "Mark arrived" is offered on the day of the visit only. */
export const canMarkArrived = (v: VisitAppointment): boolean => isToday(v) && v.status === 'confirmed'

export const isDecided = (s: VisitStatus): boolean => s === 'declined' || s === 'cancelled'
export const isPast = (s: VisitStatus): boolean => s === 'completed' || s === 'declined' || s === 'cancelled' || s === 'missed'
/** The group chat is read-only at once on decline or cancel, otherwise 24 hours after the slot. */
export const isChatClosed = (v: VisitAppointment): boolean => {
  if (isDecided(v.status)) return true
  if (v.closedAt && at(v.closedAt) <= NOW_MS) return true
  return NOW_MS >= at(v.slotStart) + 24 * 60 * MIN
}

export type Segment = 'requested' | 'upcoming' | 'past'
export const segmentOf = (v: VisitAppointment): Segment => {
  if (v.status === 'requested') return 'requested'
  if (v.status === 'reschedule_proposed') return 'upcoming'
  if (isPast(v.status)) return 'past'
  // Confirmed or arrived: upcoming until the slot is long gone.
  return NOW_MS >= at(v.slotStart) + 24 * 60 * MIN ? 'past' : 'upcoming'
}

/** First name as typed (the partner sees the first name; the phone only when the client shares it). */
export const firstName = (full: string): string => full.trim().split(/\s+/)[0] ?? full

/** The script of typed text, for `lang` on user text (ADR 0014 D8). */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

// ---------------------------------------------------------------- data

/** Every visit of this venue, nearest slot first (requested ones lead within the same day). */
export function useVenueVisits(): VisitAppointment[] {
  const visits = usePrototype(s => s.visits)
  const jumped = useVisitsLocal(s => s.jumped)
  return useMemo(() => visits.filter(v => v.venueId === VENUE_ID).map(v => moveToDay(v, jumped)).sort((a, b) => at(a.slotStart) - at(b.slotStart)), [visits, jumped])
}

/** Prototype demo: a visit the owner jumped to its day sits at 3:00 PM today (an hour ago, so every day-of action is open). */
const moveToDay = (v: VisitAppointment, jumped: Record<string, true>): VisitAppointment => {
  if (!jumped[v.id] || v.status === 'requested') return v
  const slotStart = engine.at(PROTOTYPE_TODAY, '15:00')
  return { ...v, slotStart, slotEnd: engine.slotEnd(slotStart) }
}

export function useVisitById(id: string | undefined): VisitAppointment | undefined {
  const visits = usePrototype(s => s.visits)
  const jumped = useVisitsLocal(s => s.jumped)
  return useMemo(() => {
    const v = visits.find(x => x.id === id)
    return v ? moveToDay(v, jumped) : undefined
  }, [visits, jumped, id])
}

const seed = (id: string): VisitAppointment => {
  const v = getVisit(id)
  if (!v) throw new Error(`visit ${id} missing from the seed`)
  return v
}

export const HERO_CONFIRMED = 'visit-aurelia-reem'
export const HERO_REQUESTED = 'visit-aurelia-rashed'

export type VisitVariant = 'requested' | 'confirmed' | 'reschedule-proposed' | 'day-of' | 'arrived' | 'completed' | 'declined' | 'cancelled' | 'missed' | 'client-on-the-way' | 'flag-missed'

const slotToday = (time: string): { slotStart: string; slotEnd: string } => {
  const slotStart = engine.at(PROTOTYPE_TODAY, time)
  return { slotStart, slotEnd: engine.slotEnd(slotStart) }
}

/** A seed visit drawn in another status: same client, venue, representative and chat; only the status, the slot and the history differ. */
export function deriveVisit(variant: VisitVariant): VisitAppointment {
  const confirmed = seed(HERO_CONFIRMED)
  const requested = seed(HERO_REQUESTED)
  const log = (base: VisitAppointment, status: VisitStatus, at: string, actor: 'client' | 'hotel_representative' | 'support' | 'system' = 'hotel_representative'): VisitAppointment => ({
    ...base,
    status,
    history: [...base.history, { at, status, actor, actorName: actor === 'hotel_representative' ? 'Amal Al-Balushi' : undefined }],
  })
  switch (variant) {
    case 'requested':
      return requested
    case 'confirmed':
      return confirmed
    case 'reschedule-proposed': {
      const day = visitDatesFor(VENUE_ID).find(d => d !== slotDay(requested))
      const slot = day ? visitSlotsFor(VENUE_ID, day).find(s => s.available) : undefined
      return { ...log(requested, 'reschedule_proposed', PROTOTYPE_NOW), proposedSlotStart: slot?.start ?? null }
    }
    case 'day-of':
    case 'client-on-the-way':
      return { ...confirmed, ...slotToday('17:00'), id: confirmed.id }
    case 'arrived': {
      const base = { ...confirmed, ...slotToday('15:30') }
      return { ...log(base, 'arrived', engine.at(PROTOTYPE_TODAY, '15:36')), arrivedAt: engine.at(PROTOTYPE_TODAY, '15:36') }
    }
    case 'flag-missed':
      return { ...confirmed, ...slotToday('14:30') }
    case 'missed':
      return log({ ...confirmed, ...slotToday('14:30') }, 'missed', engine.at(PROTOTYPE_TODAY, '15:10'))
    case 'completed': {
      const day = engine.addDays(PROTOTYPE_TODAY, -8)
      const start = engine.at(day, '16:30')
      const base = { ...confirmed, slotStart: start, slotEnd: engine.slotEnd(start) }
      const arrivedAt = engine.at(day, '16:35')
      return { ...log(log(base, 'arrived', arrivedAt), 'completed', engine.at(day, '17:20'), 'system'), arrivedAt, closedAt: engine.at(engine.addDays(day, 1), '16:30') }
    }
    case 'declined':
      return { ...log(requested, 'declined', PROTOTYPE_NOW), closedAt: PROTOTYPE_NOW }
    case 'cancelled':
      return { ...log(confirmed, 'cancelled', PROTOTYPE_NOW, 'client'), closedAt: PROTOTYPE_NOW }
  }
}

/** Frame state -> the visit variant that state draws. `null` keeps the live visit. */
export function variantOfState(state: string | undefined, fallback: VisitVariant): VisitVariant {
  switch (state) {
    case 'requested':
    case 'confirmed':
    case 'reschedule-proposed':
    case 'day-of':
    case 'arrived':
    case 'completed':
    case 'declined':
    case 'cancelled':
    case 'missed':
    case 'client-on-the-way':
    case 'flag-missed':
      return state
    case 'arrived-confirmed':
      return 'arrived'
    case 'success':
      return 'missed'
    case 'closed-read-only':
      return 'completed'
    default:
      return fallback
  }
}

/** The proposed slot of a visit in `reschedule_proposed` (the seed field, or what this session proposed). */
export function useProposedSlot(v: VisitAppointment | undefined): string | null {
  const local = useVisitsLocal(s => (v ? s.proposals[v.id] : undefined))
  return v?.proposedSlotStart ?? local ?? null
}

/** The assigned representative's user id: the seed's, or the one an Admin or Manager picked in this session. */
export function useRepresentativeId(v: VisitAppointment | undefined): string {
  const local = useVisitsLocal(s => (v ? s.reps[v.id] : undefined))
  return local ?? v?.representativeId ?? ''
}

// ---------------------------------------------------------------- the group chat

export type ChatLine = { message: Message; delivery: 'sent' | 'sending' | 'failed' | 'queued' }

/** The chat of a visit: the conversation with its three members and the messages the hotel side may read. */
export function useVisitConversation(v: VisitAppointment | undefined): { conversation: GroupThread | null; base: Message[] } {
  const session = usePrototype(s => (v ? s.visitChats[v.id] : undefined))
  return useMemo(() => {
    if (!v) return { conversation: null, base: [] }
    if (session) return { conversation: session.conversation, base: session.messages }
    const seeded = groupThreadFor(v.id, 'hotel')
    return { conversation: seeded?.thread ?? null, base: seeded?.messages ?? [] }
  }, [v, session])
}

export const venueName = (lang: 'ar' | 'en'): string => {
  const venue = getVenue(VENUE_ID)
  return venue ? venue.name[lang] : ''
}
