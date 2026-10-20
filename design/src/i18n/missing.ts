// Missing-key behaviour (development). A missing key or a broken message is loud in three places: the string itself is
// rendered as ⟦key⟧, the console gets one error per key, and a red badge plus a top strip appear on the page so a screenshot
// can never hide it. `window.__gzI18nMissing` lists them for tooling. In production it only warns once and the key shows.
import type { MissingInfo } from '@gz/i18n'

declare global {
  interface Window {
    __gzI18nMissing?: MissingInfo[]
  }
}

const seen = new Set<string>()
let badge: HTMLElement | null = null

export const isDev: boolean = import.meta.env.DEV

function paintBadge(count: number) {
  if (!isDev || typeof document === 'undefined') return
  document.documentElement.dataset.gzI18nMissing = 'true'
  if (!badge) {
    badge = document.createElement('div')
    badge.className = 'gz-i18n-badge'
    badge.setAttribute('role', 'status')
    badge.dir = 'ltr'
    document.body.appendChild(badge)
  }
  badge.textContent = `i18n: ${count} missing`
}

export function reportMissing(info: MissingInfo): void {
  const id = `${info.lang}/${info.namespace ?? '?'}/${info.key}/${info.reason}`
  if (seen.has(id)) return
  seen.add(id)
  const list = (window.__gzI18nMissing ??= [])
  list.push(info)
  const where = `${info.lang}/${info.namespace ?? '?'}.json`
  const text = info.reason === 'missing-key' ? `missing key "${info.key}" in ${where}` : `cannot format "${info.key}" in ${where}`
  if (isDev) {
    console.error(`[i18n] ${text}`, info.error ?? '')
    queueMicrotask(() => paintBadge(list.length)) // never touch the DOM in the middle of a render
  } else {
    console.warn(`[i18n] ${text}`)
  }
}
