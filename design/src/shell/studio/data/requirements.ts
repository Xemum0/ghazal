// Requirement texts for the inspector and the player panel, from docs/product/feature-matrix.json (571 items, ~190 KB).
// Loaded on first use (dynamic import) so it never weighs on the board's first paint. IDs are append-only, so a lookup by id is stable.
import { useEffect, useState } from 'react'

export type Requirement = { id: string; app: string; group: string; text: string; phase: string; designScope: boolean; notes?: string }

let cache: Map<string, Requirement> | null = null
let pending: Promise<Map<string, Requirement>> | null = null

export function loadRequirements(): Promise<Map<string, Requirement>> {
  if (cache) return Promise.resolve(cache)
  pending ??= import('@docs/product/feature-matrix.json').then(mod => {
    const list = (mod.default ?? mod) as unknown as Requirement[]
    cache = new Map(list.map(r => [r.id, r]))
    return cache
  })
  return pending
}

/** `null` while loading; then the map. A failed load resolves to an empty map so the UI shows ids only. */
export function useRequirements(): Map<string, Requirement> | null {
  const [map, setMap] = useState<Map<string, Requirement> | null>(cache)
  useEffect(() => {
    let live = true
    if (!cache) loadRequirements().then(m => live && setMap(m), () => live && setMap(new Map()))
    return () => {
      live = false
    }
  }, [])
  return map
}
