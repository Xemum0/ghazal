// The canvas camera. Pan and zoom are ONE transform on the world element (translate + scale, nothing else animates), written
// straight to the DOM from requestAnimationFrame: React never renders per frame, so 120 frames pan at the display rate.
// `will-change: transform` is switched on only while the camera moves and off when it settles, so the browser re-rasterises the
// frames sharp at the resting zoom (a permanent will-change would keep them blurry after a zoom).
//
// Zoom-dependent CSS variables (--gzs-ui-s, ...) are written to the registered "ui" elements only (labels, headers, arrows), never to
// the world: a changed custom property invalidates every descendant, and the frames hold thousands of nodes.
import { useSyncExternalStore } from 'react'
import { flat } from '@gz/tokens'
import type { Rect } from './layout'

export const MIN_K = 0.04
export const MAX_K = 2
export const ZOOM_STEPS = [0.25, 0.5, 0.75, 1, 1.5, 2] as const
const SETTLE_MS = 160
/** Labels and headers never grow more than this much when the board is zoomed out. */
const UI_MAX = 2
/** Below this zoom the section tags appear (the header columns are too small to read). */
const FAR_K = 0.26
const FLY_MS = flat['motion.duration.slow']
const easeOut = (t: number) => 1 - Math.pow(1 - t, 3)

export type View = { x: number; y: number; k: number }
export const clampK = (k: number) => Math.min(MAX_K, Math.max(MIN_K, k))

export class Viewport {
  x = 0
  y = 0
  k = 1
  width = 0
  height = 0
  reduced = false

  private el: HTMLElement | null = null
  private world: HTMLElement | null = null
  private ui = new Set<HTMLElement | SVGElement>()
  private raf = 0
  private dirty = false
  private fly: { raf: number } | null = null
  private settleTimer = 0
  private lastK = -1
  private listeners = new Set<() => void>()
  private settleListeners = new Set<(v: View) => void>()
  private snap = 1

  // ---------------------------------------------------------------- wiring
  attach(viewport: HTMLElement, world: HTMLElement) {
    this.el = viewport
    this.world = world
    this.dirty = false
    this.lastK = -1
    this.measure()
    this.write()
    this.snap = Math.round(this.k * 1000) / 1000
    this.listeners.forEach(l => l())
  }

  detach() {
    this.cancelFly()
    cancelAnimationFrame(this.raf)
    window.clearTimeout(this.settleTimer)
    this.dirty = false
    this.el = null
    this.world = null
  }

  /** Register an element that reads --gzs-ui-s / --gzs-ui-inv. Returns the unregister function. */
  registerUi(el: HTMLElement | SVGElement): () => void {
    this.ui.add(el)
    this.writeVars(el)
    return () => {
      this.ui.delete(el)
    }
  }

  measure() {
    if (!this.el) return
    const r = this.el.getBoundingClientRect()
    this.width = r.width
    this.height = r.height
  }

  subscribe = (cb: () => void) => {
    this.listeners.add(cb)
    return () => {
      this.listeners.delete(cb)
    }
  }
  getSnapshot = () => this.snap

  onSettle(cb: (v: View) => void) {
    this.settleListeners.add(cb)
    return () => {
      this.settleListeners.delete(cb)
    }
  }

  get view(): View {
    return { x: this.x, y: this.y, k: this.k }
  }

  // ---------------------------------------------------------------- camera moves
  set(v: Partial<View>) {
    this.cancelFly()
    if (v.x !== undefined) this.x = v.x
    if (v.y !== undefined) this.y = v.y
    if (v.k !== undefined) this.k = clampK(v.k)
    this.schedule()
  }

  panBy(dx: number, dy: number) {
    this.cancelFly()
    this.x += dx
    this.y += dy
    this.schedule()
  }

  /** Zoom by `factor` keeping the world point under screen point (sx, sy) fixed. */
  zoomAt(sx: number, sy: number, factor: number) {
    this.cancelFly()
    const k = clampK(this.k * factor)
    const f = k / this.k
    this.x = sx - (sx - this.x) * f
    this.y = sy - (sy - this.y) * f
    this.k = k
    this.schedule()
  }

  /** Zoom to an absolute level around the viewport centre (or a given screen point), animated. */
  zoomTo(k: number, at?: { x: number; y: number }, animate = true) {
    const kk = clampK(k)
    const sx = at?.x ?? this.width / 2
    const sy = at?.y ?? this.height / 2
    const f = kk / this.k
    this.flyTo({ x: sx - (sx - this.x) * f, y: sy - (sy - this.y) * f, k: kk }, animate)
  }

  stepZoom(dir: 1 | -1) {
    const cur = this.k
    const next = dir > 0 ? ZOOM_STEPS.find(s => s > cur + 0.005) : [...ZOOM_STEPS].reverse().find(s => s < cur - 0.005)
    this.zoomTo(next ?? (dir > 0 ? MAX_K : ZOOM_STEPS[0]))
  }

  /** The view that shows `rect` with `padding` screen px around it, zoom limited to [minK, maxK]. */
  viewFor(rect: Rect, opts: { padding?: number; minK?: number; maxK?: number; insetStart?: number; align?: 'center' | 'start' | 'top' } = {}): View {
    const pad = opts.padding ?? 64
    const availW = Math.max(120, this.width - pad * 2)
    const availH = Math.max(120, this.height - pad * 2)
    const k = clampK(Math.min(opts.maxK ?? MAX_K, Math.max(opts.minK ?? MIN_K, Math.min(availW / rect.w, availH / rect.h))))
    const cx = rect.x + rect.w / 2
    const cy = rect.y + rect.h / 2
    return { x: this.width / 2 - cx * k, y: this.height / 2 - cy * k, k }
  }

  fit(rect: Rect, opts: Parameters<Viewport['viewFor']>[1] & { animate?: boolean } = {}) {
    this.flyTo(this.viewFor(rect, opts), opts.animate ?? true)
  }

  /** Centre `rect` at the current zoom (no zoom change), or bring it fully in view when it is partly outside. */
  reveal(rect: Rect, animate = true) {
    const sx0 = rect.x * this.k + this.x
    const sy0 = rect.y * this.k + this.y
    const sx1 = sx0 + rect.w * this.k
    const sy1 = sy0 + rect.h * this.k
    const m = 48
    if (sx0 >= m && sy0 >= m && sx1 <= this.width - m && sy1 <= this.height - m) return
    this.flyTo({ x: this.width / 2 - (rect.x + rect.w / 2) * this.k, y: this.height / 2 - (rect.y + rect.h / 2) * this.k, k: this.k }, animate)
  }

  flyTo(target: View, animate = true) {
    this.cancelFly()
    const to = { ...target, k: clampK(target.k) }
    if (!animate || this.reduced || !this.el) {
      this.x = to.x
      this.y = to.y
      this.k = to.k
      this.schedule()
      return
    }
    const from = this.view
    const t0 = performance.now()
    const fly = { raf: 0 }
    this.fly = fly
    // Interpolate the zoom geometrically so a long fly feels uniform; position follows with the same easing.
    const tick = (now: number) => {
      if (this.fly !== fly) return
      const p = Math.min(1, (now - t0) / FLY_MS)
      const e = easeOut(p)
      this.k = from.k * Math.pow(to.k / from.k, e)
      this.x = from.x + (to.x - from.x) * e
      this.y = from.y + (to.y - from.y) * e
      this.write()
      this.touch()
      if (p < 1) fly.raf = requestAnimationFrame(tick)
      else this.fly = null
    }
    fly.raf = requestAnimationFrame(tick)
  }

  private cancelFly() {
    if (this.fly) cancelAnimationFrame(this.fly.raf)
    this.fly = null
  }

  /** Mirror the camera about the viewport (language flip): what was on the left is now on the right. */
  mirror(worldWidth: number) {
    this.cancelFly()
    this.x = this.width - this.x - worldWidth * this.k
    this.schedule()
  }

  // ---------------------------------------------------------------- output
  private schedule() {
    if (this.dirty) return
    this.dirty = true
    this.raf = requestAnimationFrame(() => {
      this.dirty = false
      this.write()
      this.touch()
    })
  }

  /** Moving: will-change on; settled: off and observers told. */
  private touch() {
    if (this.world && this.world.dataset.moving !== '1') this.world.dataset.moving = '1'
    window.clearTimeout(this.settleTimer)
    this.settleTimer = window.setTimeout(() => {
      if (this.world) delete this.world.dataset.moving
      const v = this.view
      this.snap = Math.round(v.k * 1000) / 1000
      this.listeners.forEach(l => l())
      this.settleListeners.forEach(l => l(v))
    }, SETTLE_MS)
    // The zoom readout follows live, but at most every few frames.
    const live = Math.round(this.k * 100) / 100
    if (live !== this.snap && this.listeners.size) {
      this.snap = live
      this.listeners.forEach(l => l())
    }
  }

  private write() {
    const { world, el } = this
    if (!world || !el) return
    world.style.transform = `translate3d(${this.x}px, ${this.y}px, 0) scale(${this.k})`
    // Dot grid: pitch doubles until it is at least 24 px on screen, so it never turns into a texture.
    let pitch = 32 * this.k
    while (pitch < 24) pitch *= 2
    el.style.backgroundSize = `${pitch}px ${pitch}px`
    el.style.backgroundPosition = `${this.x}px ${this.y}px`
    const far = this.k < FAR_K
    if (far !== (world.dataset.far === '1')) {
      if (far) world.dataset.far = '1'
      else delete world.dataset.far
    }
    if (this.k !== this.lastK) {
      this.lastK = this.k
      this.ui.forEach(u => this.writeVars(u))
    }
  }

  private writeVars(el: HTMLElement | SVGElement) {
    const inv = 1 / this.k
    // --gzs-ui-s: how much a label or header grows so it stays readable (1 at 100% and above, at most 2x). --gzs-ui-inv: exactly
    // 1/zoom (arrow heads, rings and dots keep a constant on-screen size).
    const s = Math.min(UI_MAX, Math.max(1, inv))
    el.style.setProperty('--gzs-ui-s', String(s))
    el.style.setProperty('--gzs-ui-si', String(1 / s))
    el.style.setProperty('--gzs-ui-inv', String(Math.min(16, inv)))
    // Section tags keep a constant on-screen size however far the board is zoomed out (1x from 100% up).
    el.style.setProperty('--gzs-ui-tag', String(Math.min(30, Math.max(1, inv))))
    el.style.setProperty('--gzs-ui-ring', `${Math.max(2, 2 * inv)}px`)
  }
}

export const viewport = new Viewport()

/** Zoom as a number for React (live while moving, rounded to 1%). */
export function useZoom(): number {
  return useSyncExternalStore(viewport.subscribe, viewport.getSnapshot, () => 1)
}

// QA handle in development builds: `__gzViewport.view`, `.width`, `.fit(...)` from the console or a test script.
if (import.meta.env.DEV && typeof window !== 'undefined') (window as unknown as { __gzViewport: Viewport }).__gzViewport = viewport
