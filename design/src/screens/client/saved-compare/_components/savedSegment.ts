// Which Saved segment to open next (Venues, Services, Packages). `nav.switchTab('saved')` carries no params, so a screen elsewhere that wants
// the Saved tab on Services (the services hub "Saved vendors" row) calls `openSavedSegment('services')` and then switches the tab. The Saved
// screen reads the request whether it mounts after the call or is already mounted, applies it once and clears it. Flow-local and tiny on
// purpose: if the shell ever lets a tab switch carry params, this file goes.
import { useSyncExternalStore } from 'react'

export type SavedSegment = 'venues' | 'services' | 'packages'

let pending: SavedSegment | null = null
const listeners = new Set<() => void>()

const emit = () => listeners.forEach(l => l())
const subscribe = (l: () => void) => {
  listeners.add(l)
  return () => {
    listeners.delete(l)
  }
}

/** Ask the Saved tab to open on a segment the next time it shows (or now, if it is mounted). */
export function openSavedSegment(segment: SavedSegment) {
  pending = segment
  emit()
}

/** The segment someone asked for and the Saved screen has not applied yet. */
export function usePendingSavedSegment(): SavedSegment | null {
  return useSyncExternalStore(subscribe, () => pending, () => null)
}

/** Mark the request as applied. */
export function clearSavedSegment() {
  if (pending === null) return
  pending = null
  emit()
}
