// The digit-style switch (ADR 0010 D2) and the clock the formatters read. The Settings row `الأرقام / Digits` is owned by a
// profile screen; it calls `setDigitStyle`. Default is western, in both languages, and it is never inferred from the device.
// For screenshots and QA a hash param wins: `?digits=eastern` (Arabic only, like the real switch) or `?digits=western`.
import { useSyncExternalStore } from 'react'
import { prototypeNow, type DigitStyle } from '@gz/i18n'
import { useRoute } from '../shell/router'

const STORAGE_KEY = 'gz.digitStyle'
const listeners = new Set<() => void>()

let stored: DigitStyle = 'western'

function read(): DigitStyle {
  try {
    return window.localStorage.getItem(STORAGE_KEY) === 'easternArabic' ? 'easternArabic' : 'western'
  } catch {
    return 'western' // storage can be blocked (private window, thumbnail capture): the page must render without it
  }
}
if (typeof window !== 'undefined') stored = read()

export function setDigitStyle(style: DigitStyle): void {
  stored = style
  try {
    window.localStorage.setItem(STORAGE_KEY, style)
  } catch {
    /* in-memory only */
  }
  listeners.forEach(l => l())
}

const subscribe = (cb: () => void) => {
  listeners.add(cb)
  return () => void listeners.delete(cb)
}

/** The stored choice, reactive. */
export const useStoredDigitStyle = (): DigitStyle => useSyncExternalStore(subscribe, () => stored, () => 'western' as DigitStyle)

/** The digit style in force: the `?digits=` param if present, else the stored setting. */
export function useDigitStyle(): DigitStyle {
  const param = useRoute().params.get('digits')
  const saved = useStoredDigitStyle()
  if (param === 'eastern' || param === 'easternArabic') return 'easternArabic'
  if (param === 'western') return 'western'
  return saved
}

// The one clock. The prototype pins NOW = Thu 12 Nov 2026 16:00 Asia/Kuwait (ADR 0011 D8); a screen that needs another
// moment calls `setClock` in its own module scope and restores it, never `new Date()`.
let clock: () => Date = prototypeNow
export const getNow = (): Date => clock()
export const setClock = (next: (() => Date) | null): void => {
  clock = next ?? prototypeNow
}
