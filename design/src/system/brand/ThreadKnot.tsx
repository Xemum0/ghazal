// ThreadKnot and ThreadBead: the thread primitives (direction section 4, thread.css). One knot = one recorded event.
//   open   hollow, 1.5 px ink-500 ring           (not yet)
//   now    gold centre, 3 px canvas gap, 3 px gold-650 ring (the ring is the sole carrier of "now")
//   tied   gold-500 fill with an ink-900 check    (recorded)
//   ended  a terminal knot with an icon in a tone (x danger, clock neutral, return arrow on rose, user-minus danger-outline)
// Sizes: `booking` 20 (full thread) and `compact` 12 (hotel request card). Every state sits in the same slot (32 / 24), so the
// ring of `now` never moves its neighbours. `pop` plays the 0.6 to 1.4 to 1 pop once, for a live state change.
import type { IconName } from '@gz/tokens'
import { cx } from '../core/cx'
import { Icon } from '../core/Icon'
import './thread-knot.css'

export type KnotState = 'open' | 'now' | 'tied' | 'ended'
export type KnotSize = 'booking' | 'compact'
export type KnotEndedTone = 'danger' | 'danger-outline' | 'neutral' | 'rose'

export type ThreadKnotProps = {
  state: KnotState
  size?: KnotSize
  /** On an ink panel (hotel header, confirmation hero): the ring gap and hollow centre are ink, not canvas. */
  onDark?: boolean
  /** `ended` only: the glyph and its tone. The glyph is shown on the 20 px knot, not the 12 px one. */
  endedIcon?: IconName
  endedTone?: KnotEndedTone
  /** Play the knot pop once (a state that just changed in view). */
  pop?: boolean
  /** `start`: the 12 px compact knot sits flush with the inline-start text edge instead of centred in its 24 px slot (list rows, cards). */
  align?: 'center' | 'start'
  /** Accessible name; without it the knot is decorative (its label sits next to it in the thread). */
  label?: string
  className?: string
}

export function ThreadKnot({ state, size = 'booking', onDark = false, endedIcon = 'close', endedTone = 'danger', pop = false, align = 'center', label, className }: ThreadKnotProps) {
  const compact = size === 'compact'
  return (
    <span
      data-gz="ThreadKnot"
      data-state={state}
      data-size={size}
      className={cx('gz-knot-slot', compact && 'gz-knot-slot--compact', align === 'start' && 'gz-knot-slot--start', onDark && 'gz-on-dark', className)}
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <span className={cx('gz-knot', `gz-knot--${state}`, compact && 'gz-knot--compact', state === 'ended' && `gz-knot--ended-${endedTone}`, pop && 'gz-knot-pop')}>
        {state === 'tied' && !compact ? <Icon name="check" size="xs" className="gz-knot__glyph" /> : null}
        {state === 'ended' && !compact ? <Icon name={endedIcon} size="xs" className="gz-knot__glyph" /> : null}
      </span>
    </span>
  )
}

export type ThreadBeadProps = {
  /** gold = chosen or progressing (default); ink = a quiet mark; hollow = not yet. */
  tone?: 'gold' | 'ink' | 'hollow'
  className?: string
}

/** The 8 px diamond. Boxed to 12 so the rotated square never clips or crowds the text beside it. */
export function ThreadBead({ tone = 'gold', className }: ThreadBeadProps) {
  return (
    <span data-gz="ThreadBead" data-tone={tone} className={cx('gz-bead-box', className)} aria-hidden="true">
      <span className={cx('gz-bead', tone !== 'gold' && `gz-bead--${tone}`)} />
    </span>
  )
}
