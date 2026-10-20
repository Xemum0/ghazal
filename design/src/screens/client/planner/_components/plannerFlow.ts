// Flow-local prototype memory of the planner flow (CL-PLAN-01..04): the consultation draft, the request once sent, its assignment
// and the chosen meeting. The shared prototype store has no planner slice (requests.md carries the ask); until it does, this small
// store keeps the four screens consistent in the player. Nothing is persisted: a reload is the story start.
// Everything displayed still comes from the shared fixtures (planner packages, the planner, the story request); this file only
// remembers what the viewer chose.
import { create } from 'zustand'
import type { PlannerTier } from '@gz/contracts'
import { PROTOTYPE_NOW, plannerPackages, plannerRequest, planners } from '../../../../mock'
import type { GzFormat } from '../../../../i18n'

export type Reach = 'chat' | 'whatsapp' | 'phone'
export type MeetingType = 'video' | 'phone'
export type WindowPart = 'morning' | 'afternoon' | 'evening'

/** A chosen window is stored as `YYYY-MM-DD|part`. */
export const windowKey = (date: string, part: WindowPart): string => `${date}|${part}`
export const parseWindow = (key: string): { date: string; part: WindowPart } => {
  const [date = '', part = 'evening'] = key.split('|')
  return { date, part: part as WindowPart }
}
export const WINDOW_PARTS: readonly WindowPart[] = ['morning', 'afternoon', 'evening']
export const MAX_WINDOWS = 3

export type Meeting = { date: string; time: string; type: MeetingType }

export type SentRequest = {
  tier: PlannerTier
  windows: string[]
  sentAt: string
  assignedAt: string | null
  meeting: Meeting | null
}

type Draft = { tier: PlannerTier; windows: string[]; reach: Reach; note: string }

type FlowState = {
  draft: Draft
  request: SentRequest | null
  setTier: (tier: PlannerTier) => void
  toggleWindow: (key: string) => void
  setReach: (reach: Reach) => void
  setNote: (note: string) => void
  send: () => void
  assign: () => void
  setMeeting: (meeting: Meeting) => void
  cancel: () => void
}

const story = plannerRequest
const initialDraft = (): Draft => ({
  // Reem saved the Gold package on 8 Nov; the story request is Gold with these windows and this note.
  tier: story.tier as PlannerTier,
  windows: story.windows.map(w => windowKey(w.date, w.part)),
  reach: 'chat',
  note: story.note,
})

/** Hours after the prototype clock: the simulated assignment lands the next morning. */
const afterNow = (hours: number): string => new Date(Date.parse(PROTOTYPE_NOW) + hours * 3_600_000).toISOString()

/** The pending simulated assignment: a second send (an edited request) or a cancel replaces it. */
let assignTimer: number | undefined

export const usePlannerFlow = create<FlowState>()((set, get) => ({
  draft: initialDraft(),
  request: null,
  setTier: tier => set(s => ({ draft: { ...s.draft, tier } })),
  toggleWindow: key =>
    set(s => {
      const has = s.draft.windows.includes(key)
      if (!has && s.draft.windows.length >= MAX_WINDOWS) return s
      return { draft: { ...s.draft, windows: has ? s.draft.windows.filter(w => w !== key) : [...s.draft.windows, key] } }
    }),
  setReach: reach => set(s => ({ draft: { ...s.draft, reach } })),
  setNote: note => set(s => ({ draft: { ...s.draft, note } })),
  send: () => {
    const { draft } = get()
    set({ request: { tier: draft.tier, windows: draft.windows, sentAt: PROTOTYPE_NOW, assignedAt: null, meeting: null } })
    // Prototype only: the planning team is a staff action with no product of its own. A few seconds after the request the
    // assignment arrives, so the viewer can follow the thread to the meeting picker.
    window.clearTimeout(assignTimer)
    assignTimer = window.setTimeout(() => get().assign(), 6000)
  },
  assign: () =>
    set(s => (s.request && !s.request.assignedAt ? { request: { ...s.request, assignedAt: afterNow(18) } } : s)),
  // A meeting chosen on the story request (no request sent in this session) adopts the story request and changes only the meeting.
  setMeeting: meeting =>
    set(s => ({
      request: s.request
        ? { ...s.request, meeting }
        : {
            tier: story.tier as PlannerTier,
            windows: story.windows.map(w => windowKey(w.date, w.part)),
            sentAt: story.requestedAt,
            assignedAt: story.assignedAt,
            meeting,
          },
    })),
  cancel: () => {
    window.clearTimeout(assignTimer)
    set({ request: null })
  },
}))

export type RequestStatus = 'requested' | 'assigned' | 'meeting_scheduled'

export type RequestView = {
  status: RequestStatus
  tier: PlannerTier
  requestedAt: string
  assignedAt: string | null
  meeting: { at: string; type: MeetingType; durationMin: number } | null
  windows: string[]
}

/** The frame `state` -> the request status it draws. */
const STATE_STATUS: Record<string, RequestStatus> = {
  'requested-waiting': 'requested',
  assigned: 'assigned',
  'meeting-scheduled': 'meeting_scheduled',
  'meeting-day': 'meeting_scheduled',
  loading: 'meeting_scheduled',
  error: 'meeting_scheduled',
  offline: 'meeting_scheduled',
}

const storyMeeting = (): NonNullable<RequestView['meeting']> => ({
  at: story.meeting?.at ?? '',
  type: 'video',
  durationMin: story.meeting?.durationMin ?? 0,
})

const meetingAt = (m: Meeting): string => `${m.date}T${m.time}:00+03:00`

/** The request the status screen draws: a frame state wins, then what the viewer sent, then the shared story request. */
export function requestView(state: string | undefined, sent: SentRequest | null): RequestView {
  const forced = state ? STATE_STATUS[state] : undefined
  if (!forced && sent) {
    const status: RequestStatus = sent.meeting ? 'meeting_scheduled' : sent.assignedAt ? 'assigned' : 'requested'
    return {
      status,
      tier: sent.tier,
      requestedAt: sent.sentAt,
      assignedAt: sent.assignedAt,
      meeting: sent.meeting ? { at: meetingAt(sent.meeting), type: sent.meeting.type, durationMin: storyMeeting().durationMin } : null,
      windows: sent.windows,
    }
  }
  const status = forced ?? (story.status as RequestStatus)
  return {
    status,
    tier: story.tier as PlannerTier,
    requestedAt: story.requestedAt,
    assignedAt: status === 'requested' ? null : story.assignedAt,
    meeting: status === 'meeting_scheduled' ? storyMeeting() : null,
    windows: story.windows.map(w => windowKey(w.date, w.part)),
  }
}

export const packageOf = (tier: PlannerTier) => plannerPackages.find(p => p.tier === tier) ?? plannerPackages[0]!
export const plannerOf = () => planners.find(p => p.id === story.plannerId) ?? planners[0]!
export const STORY_CONVERSATION = 'conv-planner-nouf'

/** The next `count` civil days after the prototype today (`YYYY-MM-DD`): the earliest consultation is tomorrow. */
export function upcomingDays(f: GzFormat, count = 14): string[] {
  return Array.from({ length: count }, (_, i) => f.isoDay(f.addDays(f.now(), i + 1)))
}

export function isoToDate(f: GzFormat, iso: string): Date {
  const [y = 0, m = 1, d = 1] = iso.split('-').map(Number)
  return f.kuwaitDate(y, m, d, 12, 0)
}

/** `15 Nov` / `15 نوفمبر`: day and short month, no weekday and no year (a window inside the next two weeks, the wedding day). */
export function dayMonth(f: GzFormat, iso: string): string {
  const c = f.civil(isoToDate(f, iso))
  return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
}

/** The months a run of ISO days touches, in order, as short names (one for most fortnights, two across a month end). */
export function monthNames(f: GzFormat, days: readonly string[]): string[] {
  const seen: number[] = []
  days.forEach(iso => {
    const m = f.civil(isoToDate(f, iso)).month
    if (seen[seen.length - 1] !== m) seen.push(m)
  })
  return seen.map(m => f.monthName(m, 'short'))
}
