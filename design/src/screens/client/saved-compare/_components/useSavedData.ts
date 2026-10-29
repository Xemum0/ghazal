// Saved and compare data for the four screens of this flow. One rule: in a static frame (canvas, screenshots) the screen shows the
// shared story (Reem's saved items, her compare set, the Brief of Thu 14 Jan and 350 guests) so a frame is deterministic; in the
// live player it reads the prototype store, so the signed-in persona sees what they saved.
import { useCallback, useMemo } from 'react'
import { clientState, getArea, referencePoints, venueAvailabilityOn, vouchersFor, weddingProfile, type Brief, type SavedItem, type Voucher } from '../../../../mock'
import { useDevice } from '../../../../shell/device'
import { usePrototype, type FavouriteKind, COMPARE_MAX } from '../../../../shell/state'

export { COMPARE_MAX }

/** The shared story Brief as plain data (what `storyBrief()` in the store derives from the wedding profile). */
export const STORY_BRIEF: Brief = {
  date: weddingProfile.weddingDate,
  guests: weddingProfile.guests.women,
  audience: weddingProfile.searching[0] ?? 'women',
  areaIds: weddingProfile.areaIds,
  budget: { min: weddingProfile.venueBudget.min, max: weddingProfile.venueBudget.max },
}

const STORY_SAVED = clientState.saved
const STORY_COMPARE = clientState.compareVenueIds
const STORY_USER_ID = clientState.userId

export type SavedModel = {
  live: boolean
  brief: Brief
  /** Saved ids per segment, in the order they were saved. */
  saved: Record<FavouriteKind, string[]>
  compare: string[]
  toggleSaved: (kind: FavouriteKind, id: string) => void
  /** The earlier price seen for an item, when the account has one (drives "Price dropped"). */
  lastSeen: (kind: FavouriteKind, id: string) => SavedItem['lastSeenPrice']
  /** A paid, unattached voucher the signed-in client holds for this venue or provider (drives "Voucher ready"). */
  readyVoucher: (targetId: string) => Voucher | null
}

/** Live store in the player, the story in a static frame. */
export function useSavedModel(): SavedModel {
  const live = useDevice().mode === 'live'
  const favourites = usePrototype(s => s.favourites)
  const compareList = usePrototype(s => s.compareList)
  const searchBrief = usePrototype(s => s.searchBrief)
  const vouchers = usePrototype(s => s.vouchers)
  const userId = usePrototype(s => s.user?.id ?? null)

  const saved = useMemo(() => {
    if (live) return favourites
    const out: Record<FavouriteKind, string[]> = { venue: [], vendor: [], package: [] }
    for (const s of STORY_SAVED) out[s.type].push(s.id)
    return out
  }, [live, favourites])

  const toggleSaved = useCallback(
    (kind: FavouriteKind, id: string) => {
      if (live) usePrototype.getState().toggleFavourite(kind, id)
    },
    [live],
  )
  const lastSeen = useCallback((kind: FavouriteKind, id: string) => STORY_SAVED.find(s => s.type === kind && s.id === id)?.lastSeenPrice ?? null, [])

  const readyVoucher = useCallback(
    (targetId: string): Voucher | null => {
      const wallet = live ? (userId ? vouchers.filter(v => v.clientId === userId) : []) : vouchersFor(STORY_USER_ID)
      return wallet.find(v => v.venueOrProviderId === targetId && v.status === 'active') ?? null
    },
    [live, userId, vouchers],
  )

  return {
    live,
    brief: live ? searchBrief : STORY_BRIEF,
    saved,
    compare: live ? compareList : [...STORY_COMPARE],
    toggleSaved,
    lastSeen,
    readyVoucher,
  }
}

/** The Brief the frame shows: a state can override the date (no-date) or the audience. */
export function briefFor(model: SavedModel, state: string | undefined): Brief {
  return state === 'no-date' ? { ...model.brief, date: null } : model.brief
}

/** Reference point for "Drive from {area}": the first area of the Brief when it is a reference point, else Salmiya. */
export function originOf(brief: Brief): { id: string; areaId: string } {
  const first = brief.areaIds?.[0]
  const id = first && referencePoints.some(r => r.id === `ref-${first}`) ? `ref-${first}` : 'ref-salmiya'
  return { id, areaId: id.replace(/^ref-/, '') }
}

export const areaOf = getArea

/** Availability rank for the "available halls first" sort. */
export function availabilityRank(venueId: string, brief: Brief): number {
  if (!brief.date) return 0
  const s = venueAvailabilityOn(venueId, brief.date, brief).state
  return s === 'available' ? 0 : s === 'held' ? 1 : s === 'unavailable' ? 2 : 3
}
