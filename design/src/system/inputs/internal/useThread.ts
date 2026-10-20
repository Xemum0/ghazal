import { useCallback, useLayoutEffect, useState, type RefObject } from 'react'
import { layoutScale } from '../../core/layoutScale'

export type ThreadBox = {
  /** Distance of the active item's start edge from the container's start edge, in px (always >= 0). */
  x: number
  /** Width of the active item in px. */
  w: number
  /** False until the first measurement, so the thread appears in place instead of sliding in from zero. */
  ready: boolean
  /** 1 in LTR, -1 in RTL: the multiplier ADR 0014 D1 names, derived from the element's computed direction. */
  dir: 1 | -1
}

/**
 * Measures the active child of a segmented control or tab list so a thread can slide under it. Everything is relative to
 * the START edge, so the Arabic layout needs no special case: the component multiplies by `dir` when it writes the
 * translate. Scale-safe: it divides by the element's on-screen scale. Re-measures on resize and once the fonts are in (label widths change when Cairo / Poppins load).
 */
export function useThread(container: RefObject<HTMLElement | null>, activeIndex: number, itemSelector: string, watch: unknown): ThreadBox {
  const [box, setBox] = useState<ThreadBox>({ x: 0, w: 0, ready: false, dir: 1 })

  const measure = useCallback(() => {
    const root = container.current
    if (!root) return
    const item = root.querySelectorAll<HTMLElement>(itemSelector)[activeIndex]
    if (!item) {
      setBox(b => (b.w === 0 ? b : { ...b, w: 0 }))
      return
    }
    const rtl = getComputedStyle(root).direction === 'rtl'
    const c = root.getBoundingClientRect()
    const r = item.getBoundingClientRect()
    // Rects are screen px; the thread is written back in layout px, so undo any ancestor scale (Launcher phone, Studio zoom).
    const k = layoutScale(root)
    const x = (rtl ? c.right - r.right : r.left - c.left) / k
    const next: ThreadBox = { x: Math.round(x * 100) / 100, w: Math.round((r.width / k) * 100) / 100, ready: true, dir: rtl ? -1 : 1 }
    setBox(b => (b.x === next.x && b.w === next.w && b.ready && b.dir === next.dir ? b : next))
  }, [container, activeIndex, itemSelector])

  useLayoutEffect(() => {
    measure()
    const root = container.current
    if (!root) return
    // Size changes of the track or of any item (a label that wraps, a font that lands) re-measure.
    const ro = new ResizeObserver(measure)
    ro.observe(root)
    root.querySelectorAll<HTMLElement>(itemSelector).forEach(el => ro.observe(el))
    void document.fonts?.ready.then(measure)
    // A language switch flips the direction without resizing the track: the items change sides, so `x` and `dir` are stale until measured
    // again. The document element carries `dir` and `lang` (GzProvider); watch them and measure once the new layout has settled.
    let raf = 0
    const mo = new MutationObserver(() => {
      cancelAnimationFrame(raf)
      raf = requestAnimationFrame(() => requestAnimationFrame(measure))
    })
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ['dir', 'lang', 'class'] })
    return () => {
      cancelAnimationFrame(raf)
      mo.disconnect()
      ro.disconnect()
    }
    // `watch` re-runs the measurement when the option set changes.
  }, [measure, container, watch, itemSelector])

  return box
}
