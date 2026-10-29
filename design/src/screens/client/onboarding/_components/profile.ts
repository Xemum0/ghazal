// Flow-local glue between the onboarding screens and the prototype store (ADR 0007 D3, CA-ONB-08): answers are written to the
// wedding profile and the global Brief as each step is confirmed, never earlier, so Skip leaves the store untouched. These are the
// optional steps after the account is created (CL-ONBD-03 to 05); they start from what the account already knows.
// Nothing here formats text; every value is a fixture id, an ISO date, an integer or Money in fils.
import type { Audience, IsoDate, Money } from '../../../../mock'
import { usePrototype, type SearchBrief, type WeddingProfileState } from '../../../../shell/state'
import type { Sex, WeddingRole } from '../../../../shell/state/types'

export type { WeddingRole }

/** The role a sex suggests for the wedding, as a convenience only: it is a chip the person can change (OQ-R2-06). */
export const roleForSex = (sex: Sex | undefined): WeddingRole | null => (sex === 'female' ? 'bride' : sex === 'male' ? 'groom' : null)

const emptyProfile = (): WeddingProfileState => ({
  // The neutral role until the couple says otherwise: no gendered form is ever chosen for them (ADR 0013 D2).
  role: 'family',
  name: '',
  partnerName: null,
  weddingDate: null,
  // `exact` with no date is the calendar waiting for a tap; it only becomes `undecided` when the couple says so (or at the end, below).
  dateMode: 'exact',
  guests: { women: 0, men: 0 },
  venueBudget: null,
  totalBudget: null,
  areaIds: [],
  searching: ['women'],
})

/** The profile being built (the store's, or a fresh one the first time a step is confirmed). */
const draft = (): WeddingProfileState => usePrototype.getState().weddingProfile ?? emptyProfile()

export function commitAbout(a: { role: WeddingRole | null; name: string; partnerName: string }): void {
  const p = draft()
  usePrototype.getState().setWeddingProfile({
    ...p,
    role: a.role ?? p.role,
    name: a.name.trim() || p.name,
    partnerName: a.partnerName.trim() || null,
  })
}

export function commitDate(a: { date: IsoDate | null; mode: WeddingProfileState['dateMode'] }): void {
  usePrototype.getState().setWeddingProfile({ ...draft(), weddingDate: a.date, dateMode: a.mode })
}

export function commitGuestsBudget(a: { women: number; men: number; budget: { min: Money; max: Money } | null }): void {
  usePrototype.getState().setWeddingProfile({ ...draft(), guests: { women: a.women, men: a.men }, venueBudget: a.budget })
}

/** Final step: publish the global Brief from the answers (ADR 0007 D3). The Client app asks for no area (ADR 0038 D1): the Brief carries
 *  the date, guests, section and budget only, and the governorates are chosen in the Brief sheet on Home. */
export function finishOnboarding(): void {
  const store = usePrototype.getState()
  const p = draft()
  store.setWeddingProfile(p)
  const audience: Audience = p.searching[0] ?? 'women'
  const brief: SearchBrief = {
    date: p.weddingDate,
    guests: p.guests.women > 0 ? p.guests.women : null,
    audience,
    budget: p.venueBudget ? { min: p.venueBudget.min, max: p.venueBudget.max } : null,
    dateMode: p.weddingDate ? p.dateMode : 'undecided',
  }
  store.setBrief(brief)
}

/** The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4). Latin initials are capitals. */
export function monogramFor(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean)
  const first = words[0] ?? ''
  const base = first.length > 2 && first.startsWith('ال') ? first.slice(2) : first
  const ch = Array.from(base)[0]
  return ch ? ch.toUpperCase() : ''
}
