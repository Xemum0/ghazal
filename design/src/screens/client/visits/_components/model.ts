// Model of the Visits flow (CL-VIST-01..05): the helpers every screen shares. Visits live in the prototype store (the same objects the
// partner app reads); the seeded chats are read through `groupThreadFor`; a visit booked in this session has its chat in `visitChats`.
// What the store does not carry (the messages a client types into a seeded chat, the "on our way" tap, a message still sending) lives in
// the small flow-local store below. Every string that carries a date, a time or a count is built here from GzFormat.
import { useMemo } from 'react'
import { create } from 'zustand'
import type { Message, ThreadMember, VisitAppointment, VisitStatus } from '@gz/contracts'
import { getVenue, getVisit, groupThreadFor, meta, PROTOTYPE_NOW } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { useBi } from '../../../../system'

export const HERO_VISIT = 'visit-aurelia-reem'
export const PAST_VISIT = 'visit-lumi-reem'
/** Visitors a party may bring (CL-VIST-01 stepper). */
export const VISITORS_MIN = 1
export const VISITORS_MAX = 6
/** The note under the slot (one line of typed text). */
export const NOTE_MAX = 140
/** How long the "Visit requested" screen waits before it opens the chat by itself (CL-VIST-02). */
export const REDIRECT_MS = 2000

export type VisitParams = {
  visitId?: string
  venueId?: string
  hallId?: string
  /** CL-VIST-01 restored after the sign-in sheet (ADR 0007 D8): the exact choice comes back. */
  date?: string
  slot?: string
  visitors?: number
  note?: string
}

/** The whole life of a visit as the chat shows it (a confirmed visit becomes `day-of` on its own day). */
export type Phase = 'requested' | 'confirmed' | 'reschedule' | 'day-of' | 'arrived' | 'completed' | 'declined' | 'cancelled' | 'missed'

export const PHASE_OF: Record<VisitStatus, Phase> = {
  requested: 'requested',
  confirmed: 'confirmed',
  reschedule_proposed: 'reschedule',
  arrived: 'arrived',
  completed: 'completed',
  declined: 'declined',
  cancelled: 'cancelled',
  missed: 'missed',
}

/** Statuses after which the chat is read-only (voucher-model 11.2: 24 h after the slot, at once on cancel or decline). */
export const CLOSED: readonly VisitStatus[] = ['completed', 'cancelled', 'declined', 'missed']

// ---------------------------------------------------------------- flow-local store
export type Delivery = 'sending' | 'failed' | 'queued'
type Local = {
  /** Messages typed or tapped in this session, by visit id. */
  extra: Record<string, Message[]>
  /** Messages not yet delivered, by message id. */
  delivery: Record<string, Delivery>
  /** The client tapped "We are on our way". */
  onTheWay: Record<string, boolean>
  /** The hotel already answered the first typed message of this chat. */
  answered: Record<string, boolean>
  push: (visitId: string, message: Message, delivery?: Delivery) => void
  setDelivery: (messageId: string, delivery: Delivery | null) => void
  remove: (visitId: string, messageId: string) => void
  setOnTheWay: (visitId: string) => void
  setAnswered: (visitId: string) => void
  reset: () => void
}

export const useVisitLocal = create<Local>()(set => ({
  extra: {},
  delivery: {},
  onTheWay: {},
  answered: {},
  push: (visitId, message, delivery) =>
    set(s => ({
      extra: { ...s.extra, [visitId]: [...(s.extra[visitId] ?? []), message] },
      delivery: delivery ? { ...s.delivery, [message.id]: delivery } : s.delivery,
    })),
  setDelivery: (messageId, delivery) =>
    set(s => {
      const next = { ...s.delivery }
      if (delivery) next[messageId] = delivery
      else delete next[messageId]
      return { delivery: next }
    }),
  remove: (visitId, messageId) =>
    set(s => {
      const delivery = { ...s.delivery }
      delete delivery[messageId]
      return { extra: { ...s.extra, [visitId]: (s.extra[visitId] ?? []).filter(m => m.id !== messageId) }, delivery }
    }),
  setOnTheWay: visitId => set(s => ({ onTheWay: { ...s.onTheWay, [visitId]: true } })),
  setAnswered: visitId => set(s => ({ answered: { ...s.answered, [visitId]: true } })),
  reset: () => set({ extra: {}, delivery: {}, onTheWay: {}, answered: {} }),
}))

// A session ends when the prototype signs out (sign-out, Restart): the flow forgets everything with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && prev.auth === 'signedIn') useVisitLocal.getState().reset()
})

// ---------------------------------------------------------------- the shared hook
export function useV() {
  const t = useT('client-visits')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang, isRtl } = useLang()
  const live = useDevice().mode === 'live'

  /** `Sat 14 Nov` (the year appears only when it is not the current one): the short date every card and sheet uses. */
  const dayLine = (iso: string): string => f.plain(f.date(iso, 'short'))
  /** `14 Nov`: day and short month, no weekday (rows, the picked day). */
  const dayNum = (iso: string): string => {
    const c = f.civil(iso)
    return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
  }
  /** `5:00 PM`. */
  const clock = (iso: string): string => f.plain(f.time(iso))
  /** `5:00` and `PM` apart (the formatter joins them with a no-break space): a time is a figure and a quiet unit. */
  const clockParts = (iso: string): { hm: string; mer: string } => {
    const s = f.plain(f.time(iso))
    const i = s.lastIndexOf('\u00a0')
    return i < 0 ? { hm: s, mer: '' } : { hm: s.slice(0, i), mer: s.slice(i + 1) }
  }
  /** `5:00–5:30` and `PM`: the arrival window as one figure and one unit (both ends share the unit unless the window crosses noon). */
  const windowParts = (from: string, to: string): { range: string; mer: string } => {
    const a = clockParts(from)
    const b = clockParts(to)
    return a.mer === b.mer ? { range: `${a.hm}\u2013${b.hm}`, mer: b.mer } : { range: `${a.hm} ${a.mer}\u2013${b.hm}`, mer: b.mer }
  }
  /** `Sat 14 Nov · 5:00 PM` for the accessible name of a row. */
  const when = (iso: string): string => `${dayLine(iso)} ${clock(iso)}`
  const firstName = (name: string): string => name.trim().split(/\s+/)[0] ?? name
  return { t, tc, f, bi, lang, isRtl, live, dayLine, dayNum, clock, clockParts, windowParts, when, firstName }
}

// ---------------------------------------------------------------- who is looking
/** The signed-in client's id: the story's client in a static frame (canvas) where nobody is signed in. */
export function useMeId(): string {
  return usePrototype(s => s.user?.id) ?? meta.clientUserId
}

/** Visits of this client (the store's mutable copies, newest slot first). */
export function useMyVisits(): VisitAppointment[] {
  const visits = usePrototype(s => s.visits)
  const me = useMeId()
  return useMemo(() => visits.filter(v => v.clientId === me).sort((a, b) => (a.slotStart < b.slotStart ? 1 : -1)), [visits, me])
}

export function useVisit(visitId: string | undefined): VisitAppointment | undefined {
  const visits = usePrototype(s => s.visits)
  return (visitId ? visits.find(v => v.id === visitId) : undefined) ?? (visitId ? getVisit(visitId) : undefined)
}

/** Upcoming = not closed and the slot has not ended; everything else is Past. */
export function isUpcoming(v: VisitAppointment): boolean {
  return !CLOSED.includes(v.status) && v.slotEnd >= PROTOTYPE_NOW
}

export function venueOf(v: { venueId: string }) {
  return getVenue(v.venueId)
}

/** Hotels and halls offer visits; a governmental facility and a provider never do (A-10). */
export function offersVisits(venueId: string): boolean {
  const venue = getVenue(venueId)
  return Boolean(venue && venue.type !== 'governmental' && venue.visitSlots.length > 0)
}

// ---------------------------------------------------------------- the chat of one visit
export type VisitView = {
  visit: VisitAppointment
  members: ThreadMember[]
  messages: Message[]
  conversationId: string
  closed: boolean
  phase: Phase
}

/** Frame states that show a visit in a particular life stage (the canvas draws one frame per stage). */
const STATE_VISIT: Record<string, { status: VisitStatus; today?: boolean; past?: boolean }> = {
  requested: { status: 'requested' },
  confirmed: { status: 'confirmed' },
  'reschedule-proposed': { status: 'reschedule_proposed' },
  'day-of': { status: 'confirmed', today: true },
  arrived: { status: 'arrived', today: true },
  'completed-read-only': { status: 'completed' },
  declined: { status: 'declined' },
  cancelled: { status: 'cancelled' },
  missed: { status: 'missed', past: true },
}
export const CHAT_STATES = Object.keys(STATE_VISIT)

/**
 * The visit, its three members and the messages the client may read. `state` is a frame state: it draws the hero visit in another stage
 * with its own short conversation (written from messages of this namespace, never invented in the screen).
 */
export function useVisitView(visitId: string | undefined, state?: string): VisitView | null {
  const { t, f, lang, firstName } = useV()
  const live = useVisit(visitId)
  const chats = usePrototype(s => s.visitChats)
  const extra = useVisitLocal(s => s.extra)

  return useMemo(() => {
    const stage = state ? STATE_VISIT[state] : undefined
    const id = stage ? HERO_VISIT : (visitId ?? HERO_VISIT)
    const base = (stage ? getVisit(HERO_VISIT) : live) ?? getVisit(id)
    if (!base) return null
    const seeded = groupThreadFor(base.id, 'client')
    const chat = chats[base.id]
    const heroMembers = groupThreadFor(HERO_VISIT, 'client')?.thread.members ?? []
    const raw = chat?.conversation.members ?? seeded?.thread.members ?? heroMembers
    // A session-booked chat takes its client's name from the signed-in user, which has no Latin form yet: the story client keeps hers.
    const members = raw.map(m => {
      const hero = heroMembers.find(h => h.role === 'client' && h.userId === m.userId)
      return m.role === 'client' && hero && /[\u0600-\u06FF]/.test(m.nameLatin) ? { ...m, nameLatin: hero.nameLatin, monogram: hero.monogram } : m
    })
    const rep = members.find(m => m.role === 'hotel_representative')
    const support = members.find(m => m.role === 'support')
    const me = members.find(m => m.role === 'client')

    if (!stage) {
      const messages = [...(chat?.messages ?? seeded?.messages ?? []), ...(extra[base.id] ?? [])].sort((a, b) => (a.at < b.at ? -1 : a.at > b.at ? 1 : 0))
      const closed = CLOSED.includes(base.status) || base.closedAt !== null
      const phase = PHASE_OF[base.status]
      return { visit: base, members, messages, conversationId: chat?.conversation.id ?? base.conversationId, closed, phase: phase === 'confirmed' && f.isoDay(base.slotStart) === f.isoDay(PROTOTYPE_NOW) ? 'day-of' : phase }
    }

    // A frame state: the same visit moved to another stage. Today's stages sit at 3:30 or 5:00 PM today (the prototype clock is 4:00 PM).
    const today = f.isoDay(PROTOTYPE_NOW)
    const proposedStart = '2026-11-15T18:00:00+03:00'
    const dayOf = (iso: string): string => f.plain(f.date(iso, 'short'))
    const timeOf = (iso: string): string => f.plain(f.time(iso))
    const slotStart = stage.today ? (stage.status === 'arrived' ? `${today}T15:30:00+03:00` : `${today}T17:00:00+03:00`) : stage.past ? '2026-11-08T17:00:00+03:00' : base.slotStart
    const slotEnd = stage.today ? (stage.status === 'arrived' ? `${today}T16:00:00+03:00` : `${today}T17:30:00+03:00`) : stage.past ? '2026-11-08T17:30:00+03:00' : base.slotEnd
    const closes = CLOSED.includes(stage.status)
    const visit: VisitAppointment = {
      ...base,
      status: stage.status,
      slotStart,
      slotEnd,
      proposedSlotStart: stage.status === 'reschedule_proposed' ? proposedStart : null,
      arrivedAt: stage.status === 'arrived' ? `${today}T15:34:00+03:00` : null,
      closedAt: closes ? PROTOTYPE_NOW : null,
    }
    const name = firstName(lang === 'ar' ? (me?.name ?? '') : (me?.nameLatin ?? ''))
    const at = (offsetMin: number) => new Date(Date.parse(PROTOTYPE_NOW) - offsetMin * 60_000).toISOString()
    const say = (n: number, from: Message['from'], text: string, kind: Message['kind'] = 'text', tag = ''): Message => ({
      id: `demo-${n}${tag ? `-${tag}` : ''}`, conversationId: base.conversationId, from, senderName: from === 'venue' ? (rep?.nameLatin ?? null) : from === 'support' ? (support?.nameLatin ?? null) : null,
      at: at(600 - n * 30), kind, text: { en: text, ar: text }, origin: lang, status: 'read', draft: false,
    })
    const msgs: Message[] = [
      say(1, 'system', t('clientVisitsSysOpened'), 'system', 'opened'),
      say(2, 'support', t('clientVisitsDemoSupport', { name })),
      say(3, 'client', t('clientVisitsDemoClient')),
    ]
    if (stage.status === 'confirmed' || stage.status === 'arrived' || stage.status === 'completed' || stage.status === 'missed') {
      msgs.push(say(4, 'venue', t('clientVisitsDemoHotelConfirm', { name, day: dayOf(slotStart), time: timeOf(slotStart) })))
      msgs.push(say(5, 'system', t('clientVisitsSysConfirmed'), 'system', 'confirmed'))
    }
    if (stage.status === 'reschedule_proposed') {
      msgs.push(say(4, 'venue', t('clientVisitsDemoHotelPropose', { name, day: dayOf(proposedStart), time: timeOf(proposedStart) })))
      msgs.push(say(5, 'system', t('clientVisitsSysProposed'), 'system', 'proposed'))
    }
    if (stage.status === 'declined') {
      msgs.push(say(4, 'venue', t('clientVisitsDemoHotelDecline', { name })))
      msgs.push(say(5, 'system', t('clientVisitsSysDeclined'), 'system', 'declined'))
    }
    if (stage.status === 'cancelled') msgs.push(say(4, 'system', t('clientVisitsSysCancelled'), 'system', 'cancelled'))
    if (stage.status === 'arrived') {
      msgs.push(say(6, 'client', t('clientVisitsDemoHere')))
      msgs.push(say(7, 'system', t('clientVisitsSysArrived'), 'system', 'arrived'))
    }
    if (stage.status === 'completed') {
      msgs.push(say(6, 'system', t('clientVisitsSysCompleted'), 'system', 'completed'))
      msgs.push(say(7, 'system', t('clientVisitsSysClosed'), 'system', 'closed'))
    }
    if (stage.status === 'missed') {
      msgs.push(say(6, 'system', t('clientVisitsSysMissed'), 'system', 'missed'))
      msgs.push(say(7, 'system', t('clientVisitsSysClosed'), 'system', 'closed'))
    }
    const phase: Phase = stage.today && stage.status === 'confirmed' ? 'day-of' : PHASE_OF[stage.status]
    return { visit, members, messages: msgs, conversationId: base.conversationId, closed: closes, phase }
  }, [state, visitId, live, chats, extra, t, f, lang, firstName])
}
