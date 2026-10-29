// The wedding file as Wedding info edits it. In the player it is the store's wedding profile (written by onboarding or by these edits); in a static
// frame it is Reem's, with the date moved when the state says the booking is on another day. An edit writes the profile AND the part of the
// global Brief it feeds, so the countdown, the budget and the recommendations all follow (ADR 0007 D3, CA-PROF-02, CA-ONB-09).
import { storyWeddingProfile } from '../../../../shell/state/defaults'
import { usePrototype, type SearchBrief, type WeddingProfileState } from '../../../../shell/state'
import { useLive, useSceneState } from './useProfile'

/** A date the booking is not on, for the "date differs from the booking" frame (Thu 28 Jan 2027, free at the venue). */
export const OTHER_DATE = '2027-01-28'
/** The open top band of the budget picker is stored as this ceiling (KD 60,000, the picker's own maximum). */
export const BUDGET_CEILING_FILS = 60_000_000

const EMPTY: WeddingProfileState = {
  // The neutral role until the couple says otherwise: no gendered form is ever chosen for them (ADR 0013 D2).
  role: 'family',
  name: '',
  partnerName: null,
  weddingDate: null,
  dateMode: 'undecided',
  guests: { women: 0, men: 0 },
  venueBudget: null,
  totalBudget: null,
  areaIds: [],
  searching: ['women'],
}

/** The profile on screen. */
export function useWeddingProfile(): WeddingProfileState {
  const live = useLive()
  const state = useSceneState()
  const stored = usePrototype(s => s.weddingProfile)
  if (live) return stored ?? EMPTY
  const story = storyWeddingProfile() ?? EMPTY
  return state === 'date-differs-from-booking' ? { ...story, weddingDate: OTHER_DATE } : story
}

/** Writes a change to the profile and to the Brief fields it feeds. Returns the new profile. */
export function commitWedding(patch: Partial<WeddingProfileState>): WeddingProfileState {
  const store = usePrototype.getState()
  const next: WeddingProfileState = { ...(store.weddingProfile ?? EMPTY), ...patch }
  store.setWeddingProfile(next)

  const audience = next.searching[0] ?? 'women'
  const brief: Partial<SearchBrief> = {}
  if ('weddingDate' in patch || 'dateMode' in patch) {
    brief.date = next.weddingDate
    brief.dateMode = next.weddingDate ? next.dateMode : 'undecided'
  }
  if ('guests' in patch) {
    brief.audience = audience
    brief.guests = (audience === 'men' ? next.guests.men : next.guests.women) || null
  }
  if ('governorateIds' in patch) {
    brief.governorateIds = next.governorateIds ?? []
    brief.areaIds = []
  }
  if ('venueBudget' in patch) brief.budget = next.venueBudget ? { min: next.venueBudget.min, max: next.venueBudget.max.fils >= BUDGET_CEILING_FILS ? null : next.venueBudget.max } : null
  if (Object.keys(brief).length > 0) store.setBrief(brief)
  return next
}
