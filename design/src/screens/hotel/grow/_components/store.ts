// Flow-local prototype memory for the Grow flow: the venue's voucher-price windows (a mutable copy of the fixtures, so Pause, End and
// Publish show up in the list at once), the draft of a new window that survives Back between the two steps, and what the venue did with its
// reviews (replied, reported). The shared prototype store has no windows or reviews slice yet (docs/engineering/requests.md). Nothing is
// persisted.
import { create } from 'zustand'
import { buildWindow, emptyDraft, seedWindows, type Draft, type WindowRecord } from './model'

export type ReviewAction = { replyText?: string; repliedAt?: string; reportedReason?: string }

type GrowStore = {
  windows: WindowRecord[]
  /** The window to open in the actions sheet as soon as the list is on screen (the toast's View). */
  openWindow: string | null
  highlight: string | null
  draft: Draft
  /** Where the editor was opened from, so Publish returns there. */
  origin: 'list' | 'other'
  patchDraft: (patch: Partial<Draft>) => void
  resetDraft: (patch?: Partial<Draft>) => void
  seq: number
  /** `titles` fills a title the person left on its suggestion (the editor shows it, the draft does not store it). */
  publish: (titles?: { en: string; ar: string }) => WindowRecord
  setPaused: (id: string, paused: boolean) => void
  endNow: (id: string, at: string) => void
  setOrigin: (o: 'list' | 'other') => void
  requestOpen: (id: string | null) => void
  reviews: Record<string, ReviewAction>
  reply: (id: string, text: string, at: string) => void
  report: (id: string, reason: string) => void
  reset: () => void
}

export const useGrow = create<GrowStore>()((set, get) => ({
  windows: seedWindows(),
  openWindow: null,
  highlight: null,
  draft: emptyDraft(),
  origin: 'other',
  seq: 1,
  patchDraft: patch => set(s => ({ draft: { ...s.draft, ...patch, dirty: true } })),
  resetDraft: patch => set({ draft: { ...emptyDraft(), ...patch } }),
  publish: titles => {
    const { draft, seq } = get()
    const filled = draft.titleTouched || !titles ? draft : { ...draft, titleEn: titles.en, titleAr: titles.ar }
    const made = buildWindow(filled, `vw-V01-new-${seq}`)
    set(s => ({ windows: [made, ...s.windows], seq: s.seq + 1, highlight: made.id, draft: emptyDraft() }))
    return made
  },
  setPaused: (id, paused) => set(s => ({ windows: s.windows.map(w => (w.id === id ? { ...w, paused } : w)) })),
  endNow: (id, at) => set(s => ({ windows: s.windows.map(w => (w.id === id ? { ...w, status: 'ended', endsAt: at, paused: false } : w)) })),
  setOrigin: origin => set({ origin }),
  requestOpen: id => set({ openWindow: id }),
  reviews: {},
  reply: (id, text, at) => set(s => ({ reviews: { ...s.reviews, [id]: { ...s.reviews[id], replyText: text, repliedAt: at } } })),
  report: (id, reason) => set(s => ({ reviews: { ...s.reviews, [id]: { ...s.reviews[id], reportedReason: reason } } })),
  reset: () => set({ windows: seedWindows(), draft: emptyDraft(), reviews: {}, openWindow: null, highlight: null, seq: 1 }),
}))
