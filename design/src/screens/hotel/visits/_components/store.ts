// Flow-local prototype memory for the Visits flow: what the shared store does not hold yet (the slot a representative proposed, the decline
// reason, a reassigned representative, messages typed in a seeded visit chat, the visit availability being edited). Nothing is persisted;
// a reload is the story start. Status changes themselves go through the shared store (setVisitStatus), so the client app sees them.
import { create } from 'zustand'
import type { Message, VisitSlotRule } from '../../../../mock'

export type DeclineReason = 'unavailable' | 'closed' | 'other'

export type Delivery = 'sent' | 'sending' | 'failed' | 'queued'
export type Posted = { message: Message; delivery: Delivery }

/** One weekday of the visit availability: closed, or open from `from` to `to` (venue-local `HH:MM`, Kuwait time). */
export type DayWindow = { open: boolean; from: string; to: string }
export type Week = Record<0 | 1 | 2 | 3 | 4 | 5 | 6, DayWindow>
export type Availability = {
  on: boolean
  week: Week
  slotMinutes: 30 | 45 | 60
  /** User id of the default representative, or null (the visit goes to whoever replies first). */
  repId: string | null
  blackouts: { id: string; from: string; to: string }[]
}

export const WEEK_DAYS = [0, 1, 2, 3, 4, 5, 6] as const

/** Seed windows from the venue's weekly visit rules; a day no rule covers is closed. */
export function weekFromRules(rules: readonly VisitSlotRule[]): Week {
  const week = {} as Week
  for (const d of WEEK_DAYS) {
    const rule = rules.find(r => r.days.includes(d))
    week[d] = rule ? { open: true, from: rule.from, to: rule.to } : { open: false, from: '10:00', to: '18:00' }
  }
  return week
}

type VisitsLocal = {
  /** Prototype demo: visits the owner moved to the day of the visit, so Mark arrived and Complete can be surfed. */
  jumped: Record<string, true>
  jumpToDay: (visitId: string) => void
  proposals: Record<string, string>
  propose: (visitId: string, slotStart: string) => void
  declines: Record<string, { reason: DeclineReason; note: string }>
  decline: (visitId: string, reason: DeclineReason, note: string) => void
  reps: Record<string, string>
  assign: (visitId: string, userId: string) => void
  posts: Record<string, Posted[]>
  post: (visitId: string, p: Posted) => void
  patchPost: (visitId: string, messageId: string, patch: Partial<Posted>) => void
  /** Availability: `draft` is what the screen edits, `saved` what couples see. */
  saved: Availability | null
  draft: Availability | null
  init: (a: Availability) => void
  edit: (patch: Partial<Availability>) => void
  setDay: (day: keyof Week, patch: Partial<DayWindow>) => void
  save: () => void
  discard: () => void
}

export const useVisitsLocal = create<VisitsLocal>()(set => ({
  jumped: {},
  jumpToDay: visitId => set(s => ({ jumped: { ...s.jumped, [visitId]: true } })),
  proposals: {},
  propose: (visitId, slotStart) => set(s => ({ proposals: { ...s.proposals, [visitId]: slotStart } })),
  declines: {},
  decline: (visitId, reason, note) => set(s => ({ declines: { ...s.declines, [visitId]: { reason, note } } })),
  reps: {},
  assign: (visitId, userId) => set(s => ({ reps: { ...s.reps, [visitId]: userId } })),
  posts: {},
  post: (visitId, p) => set(s => ({ posts: { ...s.posts, [visitId]: [...(s.posts[visitId] ?? []), p] } })),
  patchPost: (visitId, messageId, patch) =>
    set(s => ({ posts: { ...s.posts, [visitId]: (s.posts[visitId] ?? []).map(p => (p.message.id === messageId ? { ...p, ...patch } : p)) } })),
  saved: null,
  draft: null,
  init: a => set(s => (s.saved ? s : { saved: a, draft: a })),
  edit: patch => set(s => (s.draft ? { draft: { ...s.draft, ...patch } } : s)),
  setDay: (day, patch) => set(s => (s.draft ? { draft: { ...s.draft, week: { ...s.draft.week, [day]: { ...s.draft.week[day], ...patch } } } } : s)),
  save: () => set(s => (s.draft ? { saved: s.draft } : s)),
  discard: () => set(s => ({ draft: s.saved })),
}))

export const sameAvailability = (a: Availability | null, b: Availability | null): boolean => JSON.stringify(a) === JSON.stringify(b)
