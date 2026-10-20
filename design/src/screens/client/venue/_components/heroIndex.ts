// The photograph a venue's hero and its full-screen gallery agree on. The hero (CL-VENU-01) and the viewer (CL-VENU-02) are two
// screens of one stack; when the viewer closes, the hero is on the photograph the visitor last looked at. A tiny external store keyed
// by venue id (the prototype store belongs to the integrator; this is flow-local presentation state that dies with the page).
import { useSyncExternalStore } from 'react'

let indexes: Record<string, number> = {}
const listeners = new Set<() => void>()

const subscribe = (fn: () => void) => {
  listeners.add(fn)
  return () => {
    listeners.delete(fn)
  }
}

export const heroIndexOf = (venueId: string): number => indexes[venueId] ?? 0

export function setHeroIndex(venueId: string, index: number): void {
  if (indexes[venueId] === index) return
  indexes = { ...indexes, [venueId]: index }
  listeners.forEach(fn => fn())
}

/** [index, set] of the photograph the hero shows for this venue. */
export function useHeroIndex(venueId: string): [number, (index: number) => void] {
  const index = useSyncExternalStore(subscribe, () => indexes[venueId] ?? 0, () => 0)
  return [index, (i: number) => setHeroIndex(venueId, i)]
}
