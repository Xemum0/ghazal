// "I booked this hall" (CL-VENU-06): the couple notes a government hall they booked on the official channel. It feeds Budget, Checklist
// and Countdown only and is never a Ghazal booking, so it lives in this flow-local store (a prototype memory, nothing persisted).
import { create } from 'zustand'
import type { IsoDate } from '../../../../mock'

export type SelfReport = { date: IsoDate; fils: number }

type Store = {
  reports: Record<string, SelfReport>
  save: (venueId: string, report: SelfReport) => void
  clear: (venueId: string) => void
}

export const useSelfReports = create<Store>()(set => ({
  reports: {},
  save: (venueId, report) => set(s => ({ reports: { ...s.reports, [venueId]: report } })),
  clear: venueId =>
    set(s => {
      const next = { ...s.reports }
      delete next[venueId]
      return { reports: next }
    }),
}))
