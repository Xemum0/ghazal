// Lazy mounting for the board. Every frame slot is a cheap placeholder; only the slots near the viewport mount the real screen.
//   1. an IntersectionObserver (root = the canvas viewport, generous margin) says which slots are near the screen;
//   2. below LOD_ZOOM a frame is too small to read, so nothing mounts (the placeholders already carry id and title);
//   3. at most MAX_MOUNTED of the near slots mount, nearest to the viewport centre first (already mounted ones are sticky).
// Subscribers are per key (useSyncExternalStore), so a change re-renders only the slots whose answer changed.
import { useCallback, useSyncExternalStore } from 'react'
import { viewport } from './viewport'

export const LOD_ZOOM = 0.18
export const MAX_MOUNTED = 36
const MARGIN = 900

export class Visibility {
  private io: IntersectionObserver | null = null
  private near = new Set<string>()
  private mounted = new Set<string>()
  private subs = new Map<string, Set<() => void>>()
  private els = new Map<string, Element>()
  private keyOf = new WeakMap<Element, string>()
  private centers = new Map<string, { x: number; y: number }>()
  private raf = 0
  private off: (() => void) | null = null

  attach(root: HTMLElement) {
    this.io = new IntersectionObserver(
      entries => {
        for (const e of entries) {
          const key = this.keyOf.get(e.target)
          if (!key) continue
          if (e.isIntersecting) this.near.add(key)
          else this.near.delete(key)
        }
        this.schedule()
      },
      { root, rootMargin: `${MARGIN}px` },
    )
    this.els.forEach(el => this.io?.observe(el))
    this.off = viewport.onSettle(() => this.schedule())
  }

  detach() {
    this.io?.disconnect()
    this.io = null
    this.off?.()
    cancelAnimationFrame(this.raf)
  }

  /** World-space centres, so the cap can pick the slots nearest the camera. */
  setCenters(centers: Map<string, { x: number; y: number }>) {
    this.centers = centers
    this.schedule()
  }

  observe(key: string, el: Element): () => void {
    this.els.set(key, el)
    this.keyOf.set(el, key)
    this.io?.observe(el)
    return () => {
      this.io?.unobserve(el)
      this.els.delete(key)
      this.near.delete(key)
      this.keyOf.delete(el)
      this.schedule()
    }
  }

  isMounted = (key: string) => this.mounted.has(key)

  subscribe = (key: string, cb: () => void) => {
    let set = this.subs.get(key)
    if (!set) this.subs.set(key, (set = new Set()))
    set.add(cb)
    return () => {
      set.delete(cb)
    }
  }

  get mountedCount() {
    return this.mounted.size
  }

  private schedule() {
    if (this.raf) return
    this.raf = requestAnimationFrame(() => {
      this.raf = 0
      this.recompute()
    })
  }

  private recompute() {
    const v = viewport.view
    let next = new Set<string>()
    if (v.k >= LOD_ZOOM) {
      const cx = (viewport.width / 2 - v.x) / v.k
      const cy = (viewport.height / 2 - v.y) / v.k
      const ranked = [...this.near]
        .map(key => {
          const c = this.centers.get(key)
          const d = c ? Math.hypot(c.x - cx, c.y - cy) : 0
          return { key, d: this.mounted.has(key) ? d * 0.7 : d }
        })
        .sort((a, b) => a.d - b.d)
        .slice(0, MAX_MOUNTED)
      next = new Set(ranked.map(r => r.key))
    }
    const changed: string[] = []
    next.forEach(k => {
      if (!this.mounted.has(k)) changed.push(k)
    })
    this.mounted.forEach(k => {
      if (!next.has(k)) changed.push(k)
    })
    this.mounted = next
    for (const k of changed) this.subs.get(k)?.forEach(cb => cb())
  }
}

export function useMounted(vis: Visibility, key: string): boolean {
  const sub = useCallback((cb: () => void) => vis.subscribe(key, cb), [vis, key])
  return useSyncExternalStore(sub, () => vis.isMounted(key), () => false)
}
