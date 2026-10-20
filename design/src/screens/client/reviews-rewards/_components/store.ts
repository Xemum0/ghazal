// Flow-local prototype memory of reviews and rewards (CL-RVRW-01..02). The shared prototype store has no reviews or credit slice
// (docs/engineering/requests.md carries the ask); until it does, this small store keeps the two screens consistent in the player:
// the review draft (it autosaves, so it survives leaving the screen), the review once sent, and the reviews the viewer reported.
// Nothing is persisted: a reload is the story start. Everything displayed still comes from the shared fixtures; this file only remembers
// what the viewer typed, picked or chose.
import { create } from 'zustand'
import { usePrototype } from '../../../../shell/state'

export type StarValue = 0 | 1 | 2 | 3 | 4 | 5
export type Categories = { venue: StarValue; food: StarValue; service: StarValue; value: StarValue }
export type MediaStatus = 'uploading' | 'review' | 'rejected'
/** A photograph the viewer picked (from the curated library, the stand-in for the OS picker) and where it stands in moderation. */
export type Media = { id: string; file: string; alt: { en: string; ar: string }; status: MediaStatus }

export type ReviewDraft = {
  rating: StarValue
  categories: Categories
  text: string
  anonymous: boolean
  media: Media[]
}

export type SentReview = ReviewDraft & { bookingId: string; venueId: string; sentAt: string }

const emptyDraft = (): ReviewDraft => ({
  rating: 0,
  categories: { venue: 0, food: 0, service: 0, value: 0 },
  text: '',
  anonymous: false,
  media: [],
})

type RewardsFlow = {
  draft: ReviewDraft
  /** Reviews sent in this session, by booking id. */
  sent: Record<string, SentReview>
  /** Review ids the viewer reported. */
  reported: string[]
  setRating: (rating: StarValue) => void
  setCategory: (key: keyof Categories, value: StarValue) => void
  setText: (text: string) => void
  setAnonymous: (anonymous: boolean) => void
  addMedia: (media: Media) => void
  patchMedia: (id: string, status: MediaStatus) => void
  removeMedia: (id: string) => void
  send: (bookingId: string, venueId: string, at: string) => void
  report: (reviewId: string) => void
  reset: () => void
}

export const useRewardsFlow = create<RewardsFlow>()(set => ({
  draft: emptyDraft(),
  sent: {},
  reported: [],
  setRating: rating => set(s => ({ draft: { ...s.draft, rating } })),
  setCategory: (key, value) => set(s => ({ draft: { ...s.draft, categories: { ...s.draft.categories, [key]: value } } })),
  setText: text => set(s => ({ draft: { ...s.draft, text } })),
  setAnonymous: anonymous => set(s => ({ draft: { ...s.draft, anonymous } })),
  addMedia: media => set(s => ({ draft: { ...s.draft, media: [...s.draft.media, media] } })),
  patchMedia: (id, status) => set(s => ({ draft: { ...s.draft, media: s.draft.media.map(m => (m.id === id ? { ...m, status } : m)) } })),
  removeMedia: id => set(s => ({ draft: { ...s.draft, media: s.draft.media.filter(m => m.id !== id) } })),
  send: (bookingId, venueId, at) =>
    set(s => ({
      sent: { ...s.sent, [bookingId]: { ...s.draft, bookingId, venueId, sentAt: at } },
      draft: emptyDraft(),
    })),
  report: reviewId => set(s => (s.reported.includes(reviewId) ? s : { reported: [...s.reported, reviewId] })),
  reset: () => set({ draft: emptyDraft(), sent: {}, reported: [] }),
}))

// A restart of the player (the launcher's Restart, switching app, a story button) calls `resetToStoryStart`, which hands the prototype
// store a fresh copy of the hotel queue. When that happens with no hotel action pending, this flow forgets what it remembered too.
usePrototype.subscribe((state, prev) => {
  if (state.hotelBookings !== prev.hotelBookings && state.lastHotelAction === null) useRewardsFlow.getState().reset()
})
