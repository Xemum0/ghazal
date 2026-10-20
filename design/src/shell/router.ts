// Hash router for the chromeless harness routes. #/<kind>/<name>?lang=ar|en&state=...&w=...
// The hash is the single source of truth (language included), so a URL is a complete, shareable state.
import { useSyncExternalStore } from 'react'

export type Route = {
  /** Path segments after #/, decoded: ['gallery', 'core'] */
  segments: string[]
  params: URLSearchParams
  /** The raw hash without the leading '#', used as a React key to reset boundaries on navigation. */
  raw: string
}

export function parseHash(hash: string): Route {
  const raw = hash.replace(/^#/, '')
  const [path = '', query = ''] = raw.split('?')
  const segments = path.split('/').filter(Boolean).map(s => decodeURIComponent(s))
  return { segments, params: new URLSearchParams(query), raw }
}

const subscribe = (cb: () => void) => {
  window.addEventListener('hashchange', cb)
  return () => window.removeEventListener('hashchange', cb)
}
const getSnapshot = () => window.location.hash

/** Current route; re-renders on hash change. */
export function useRoute(): Route {
  const hash = useSyncExternalStore(subscribe, getSnapshot, () => '')
  return parseHash(hash)
}

/** Navigate by hash, e.g. go('#/gallery/core?lang=ar'). */
export const go = (hash: string) => { window.location.hash = hash.replace(/^#/, '') }

/** Change one query param in place (replaceState: no history entry), then notify listeners. */
export function setParam(key: string, value: string | null) {
  const r = parseHash(window.location.hash)
  if (value === null) r.params.delete(key)
  else r.params.set(key, value)
  const q = r.params.toString()
  const next = '#/' + r.segments.map(encodeURIComponent).join('/') + (q ? '?' + q : '')
  window.history.replaceState(null, '', next)
  window.dispatchEvent(new HashChangeEvent('hashchange'))
}
