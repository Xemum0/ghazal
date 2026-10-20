// Divider and ThreadRule.
// Divider: the 1 px ink hairline (line / line-strong / on-dark). Structure, not signature.
// ThreadRule: the gold hairline, the khayt (direction rules 2 and 5). It marks a place or a state, never decoration:
//   khayt = 24 x 1 at a section head or under a selected tab . full = spans the row (hero crown, hotel header band) .
//   knot = a full line that ends in the 8 px bead (the divider of brand/divider.svg, it follows reading direction).
// It draws on once, from inline-start, over 480 ms: on mount, or when it first scrolls into view. Reduced motion keeps the
// finished line (motion.css removes the draw).
import type { CSSProperties } from 'react'
import { flat } from '@gz/tokens'
import { cx } from './cx'
import { useRevealOnce } from './useRevealOnce'
import './divider.css'

export type DividerProps = {
  tone?: 'hairline' | 'strong' | 'on-dark'
  /** Vertical rule between two inline items (a facts row). */
  vertical?: boolean
  className?: string
}

export function Divider({ tone = 'hairline', vertical = false, className }: DividerProps) {
  return (
    <hr
      data-gz="Divider"
      data-tone={tone}
      aria-orientation={vertical ? 'vertical' : undefined}
      className={cx('gz-divider', tone === 'strong' && 'gz-divider--strong', tone === 'on-dark' && 'gz-divider--on-dark', vertical && 'gz-divider--vertical', className)}
    />
  )
}

export type ThreadRuleVariant = 'khayt' | 'full' | 'knot'

export type ThreadRuleProps = {
  variant?: ThreadRuleVariant
  /** `mount` draws immediately, `inview` on first reveal, `false` shows the finished line. */
  draw?: 'mount' | 'inview' | false
  className?: string
}

const DRAW_MS = flat['motion.duration.expressive']

export function ThreadRule({ variant = 'khayt', draw = 'inview', className }: ThreadRuleProps) {
  const [ref, seen] = useRevealOnce<HTMLSpanElement>(draw === 'inview')
  const armed = draw === 'inview' && !seen
  const drawing = draw === 'mount' || (draw === 'inview' && seen)
  // The bead of the knot variant fades in as the line arrives (the delay is the draw duration, a token value).
  const beadStyle = { '--gz-delay': `${DRAW_MS}ms` } as CSSProperties
  return (
    <span ref={ref} data-gz="ThreadRule" data-variant={variant} className={cx('gz-threadrule', `gz-threadrule--${variant}`, className)} aria-hidden="true">
      <span className={cx('gz-threadrule__line', armed && 'is-armed', drawing && 'gz-thread-draw')} />
      {variant === 'knot' ? <span className={cx('gz-threadrule__bead', armed && 'is-armed', drawing && 'gz-fade-in')} style={beadStyle}><span className="gz-bead" /></span> : null}
    </span>
  )
}
