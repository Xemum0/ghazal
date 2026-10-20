// FLIP helper for the shared-element expansion (ADR 0017: shared element = 480 ms ease-emph, one per navigation; Flutter: Hero).
// First = where the element was (a rect captured before the change), Last = where it is now; the element is inverted to First
// with a transform and played back to identity. Transform only; reduced motion plays nothing (the cross-fade of the host remains).
import { flat } from '@gz/tokens'
import { layoutScale } from '../core/layoutScale'

export type Rect = { left: number; top: number; width: number; height: number }

export const rectOf = (el: Element): Rect => {
  const r = el.getBoundingClientRect()
  return { left: r.left, top: r.top, width: r.width, height: r.height }
}

const EASE = `cubic-bezier(${flat['motion.ease.emphasized'].join(', ')})`
const DURATION = flat['motion.duration.expressive']

const reduced = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches

/**
 * Animate `el` between `from` (a rect in viewport coordinates) and its own current box. Uniform scale by width plus a centre-to-centre
 * translate, so the photograph is never stretched. `reverse` plays Last -> First (the collapse back to the thumbnail).
 */
export function flip(el: HTMLElement, from: Rect, options: { reverse?: boolean; onFinish?: () => void } = {}): Animation | null {
  if (reduced() || from.width === 0) {
    options.onFinish?.()
    return null
  }
  const to = rectOf(el)
  // The offsets are screen px, the transform is applied in the element's own (possibly scaled) space.
  const k = layoutScale(el)
  const dx = (from.left + from.width / 2 - (to.left + to.width / 2)) / k
  const dy = (from.top + from.height / 2 - (to.top + to.height / 2)) / k
  const scale = from.width / to.width
  const inverted = `translate(${dx}px, ${dy}px) scale(${scale})`
  const frames: Keyframe[] = options.reverse ? [{ transform: 'none' }, { transform: inverted }] : [{ transform: inverted }, { transform: 'none' }]
  const anim = el.animate(frames, { duration: DURATION, easing: EASE, fill: 'both' })
  anim.onfinish = () => options.onFinish?.()
  return anim
}
