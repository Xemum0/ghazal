// The one gesture-release spring (ADR 0017 D3): mass 1, stiffness 400, damping 40 (critically damped: it continues the finger's
// velocity and never overshoots). Same {mass, stiffness, damping} as Flutter's SpringDescription. Semi-implicit Euler at 1/240 s.
import { flat } from '@gz/tokens'

const MASS = flat['motion.spring.settle.mass']
const STIFFNESS = flat['motion.spring.settle.stiffness']
const DAMPING = flat['motion.spring.settle.damping']
const STEP = 1 / 240
/** Rest thresholds in dp and dp/s: below these the spring has settled. */
const REST_DISTANCE = 0.5
const REST_SPEED = 8

export type SpringHandle = { cancel: () => void }

/**
 * Animate a value from `from` to `to` starting with `velocity` (dp/s). `onFrame` receives each value; `onDone` fires once at rest.
 * Reduced motion: jump to `to` (the state is kept, the movement is removed).
 */
export function springTo(from: number, to: number, velocity: number, onFrame: (value: number) => void, onDone: () => void): SpringHandle {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    onFrame(to)
    onDone()
    return { cancel: () => {} }
  }
  let x = from
  let v = velocity
  let last = performance.now()
  let raf = 0
  let cancelled = false
  const tick = (now: number) => {
    if (cancelled) return
    let dt = Math.min((now - last) / 1000, 0.064)
    last = now
    while (dt > 0) {
      const h = Math.min(STEP, dt)
      const a = (-STIFFNESS * (x - to) - DAMPING * v) / MASS
      v += a * h
      x += v * h
      dt -= h
    }
    if (Math.abs(x - to) < REST_DISTANCE && Math.abs(v) < REST_SPEED) {
      onFrame(to)
      onDone()
      return
    }
    onFrame(x)
    raf = requestAnimationFrame(tick)
  }
  raf = requestAnimationFrame(tick)
  return {
    cancel: () => {
      cancelled = true
      cancelAnimationFrame(raf)
    },
  }
}
