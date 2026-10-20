import type { KeyboardEvent } from 'react'

/**
 * Roving-tabindex keyboard model shared by the segmented control, tabs and the chip group. Arrow keys follow what the person
 * SEES: in an RTL screen ArrowLeft goes to the next item (the first item sits at the right). Home / End jump. Disabled items
 * are skipped. Returns the new index or null when the key is not ours.
 */
export function rovingIndex(e: KeyboardEvent, index: number, disabled: readonly boolean[], opts: { vertical?: boolean } = {}): number | null {
  const rtl = getComputedStyle(e.currentTarget as Element).direction === 'rtl'
  let delta = 0
  if (e.key === 'ArrowRight') delta = rtl ? -1 : 1
  else if (e.key === 'ArrowLeft') delta = rtl ? 1 : -1
  else if (e.key === 'ArrowDown' && (opts.vertical ?? true)) delta = 1
  else if (e.key === 'ArrowUp' && (opts.vertical ?? true)) delta = -1
  else if (e.key === 'Home') return firstEnabled(disabled, 0, 1)
  else if (e.key === 'End') return firstEnabled(disabled, disabled.length - 1, -1)
  else return null
  return firstEnabled(disabled, index + delta, delta)
}

function firstEnabled(disabled: readonly boolean[], from: number, step: 1 | -1 | number): number | null {
  const s = step < 0 ? -1 : 1
  for (let i = from; i >= 0 && i < disabled.length; i += s) if (!disabled[i]) return i
  return null
}
