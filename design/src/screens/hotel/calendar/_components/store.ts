// Flow-local prototype memory of the hotel Calendar: what the viewer is looking at (the chosen day, the month, the hall filter) and what the
// hotel changed in this session (dates it blocked, dates it opened) so the Month, Week and Day views and the block sheet stay in step and
// the calendar updates in place after a block (HA-CAL-08). The fixtures are never touched; a reload is the story start.
import { create } from 'zustand'
import type { CalendarClaim, IsoDate } from '../../../../mock'
import { PROTOTYPE_TODAY } from '../../../../mock'

export type YearMonth = { year: number; month: number }
export const ALL = 'all'

type Snapshot = { added: CalendarClaim[]; removed: string[] }

type CalLocal = {
  /** The day the agenda, the week and the day view are about. */
  selected: IsoDate
  ym: YearMonth
  /** `all` or a hall id. */
  hall: string
  /** Blocks the hotel made in this session. */
  added: CalendarClaim[]
  /** Fixture claim ids the hotel opened in this session. */
  removed: string[]
  /** The state before the last block or open, so its Undo can put it back. */
  last: Snapshot | null
  select: (iso: IsoDate) => void
  setYm: (ym: YearMonth) => void
  setHall: (hall: string) => void
  commit: (add: CalendarClaim[], remove: string[]) => void
  undo: () => void
  reset: () => void
}

const ymOf = (iso: IsoDate): YearMonth => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })

const initial = () => ({ selected: PROTOTYPE_TODAY, ym: ymOf(PROTOTYPE_TODAY), hall: ALL, added: [] as CalendarClaim[], removed: [] as string[], last: null as Snapshot | null })

export const useCal = create<CalLocal>()((set, get) => ({
  ...initial(),
  select: iso => set({ selected: iso, ym: ymOf(iso) }),
  setYm: ym => set({ ym }),
  setHall: hall => set({ hall }),
  commit: (add, remove) => {
    const { added, removed } = get()
    set({ last: { added, removed }, added: [...added.filter(c => !remove.includes(c.id)), ...add], removed: [...removed, ...remove.filter(id => !added.some(c => c.id === id))] })
  },
  undo: () => {
    const { last } = get()
    if (last) set({ added: last.added, removed: last.removed, last: null })
  },
  reset: () => set(initial()),
}))
