// Board data hooks: which state variants each built screen exports (read once from the screen modules), and a tiny live store the
// toolbar reads for the frame count and the mounted count.
import { useEffect, useMemo, useState, useSyncExternalStore } from 'react'
import { FLOWS, type AppId } from '../data/inventory'
import { isBuilt, loadScreenStates } from '../../registry'

const cache = new Map<string, string[]>()
const LOAD_TIMEOUT_MS = 4000

/** What a built screen module exports as `states`, once the board has read it (empty before, and for screens that export none). */
export const exportedStates = (id: string): string[] => cache.get(id) ?? []

/**
 * The `states` export of every built screen of the app, as a map by inventory id. `ready` flips as soon as they are all read (or
 * after a timeout, so one slow module never holds the board back); a late answer still updates the map and the board re-lays out.
 */
export function useScreenStates(app: AppId): { states: ReadonlyMap<string, string[]>; ready: boolean } {
  const builtIds = useMemo(() => FLOWS[app].flatMap(f => f.screens).filter(s => isBuilt(s.id)).map(s => s.id), [app])
  const key = builtIds.join(',')
  const [version, setVersion] = useState(0)
  const [ready, setReady] = useState(() => builtIds.every(id => cache.has(id)))

  useEffect(() => {
    const todo = builtIds.filter(id => !cache.has(id))
    if (todo.length === 0) {
      setReady(true)
      return
    }
    let live = true
    const all = Promise.all(
      todo.map(async id => {
        cache.set(id, await loadScreenStates(id))
      }),
    ).then(() => {
      if (!live) return
      setVersion(v => v + 1)
      setReady(true)
    })
    const timer = window.setTimeout(() => live && setReady(true), LOAD_TIMEOUT_MS)
    void all
    return () => {
      live = false
      window.clearTimeout(timer)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- `key` stands for builtIds
  }, [key])

  const states = useMemo(() => {
    const m = new Map<string, string[]>()
    for (const id of builtIds) {
      const s = cache.get(id)
      if (s && s.length) m.set(id, s)
    }
    return m
    // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` marks cache growth
  }, [key, version])
  return { states, ready }
}

// ---------------------------------------------------------------- board info

export type BoardInfo = { frames: number; flows: number; mounted: number }
let info: BoardInfo = { frames: 0, flows: 0, mounted: 0 }
const subs = new Set<() => void>()

export const setBoardInfo = (next: Partial<BoardInfo>) => {
  const merged = { ...info, ...next }
  if (merged.frames === info.frames && merged.flows === info.flows && merged.mounted === info.mounted) return
  info = merged
  subs.forEach(s => s())
}

export function useBoardInfo(): BoardInfo {
  return useSyncExternalStore(
    cb => {
      subs.add(cb)
      return () => {
        subs.delete(cb)
      }
    },
    () => info,
    () => info,
  )
}
