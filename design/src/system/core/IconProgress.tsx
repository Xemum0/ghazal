// IconProgress (ADR 0034): the thread with an icon per knot. Each step is a glyph above its knot on one gold thread; only the
// active step (now, or the one that ended) carries a one-word label, every other label is read by assistive technology only.
// A knot ties only on a recorded event (direction section 4): the caller supplies the states. The thread draws once from
// inline-start over 480 ms (`draw`), a knot pops once on a live change (`pop`), reduced motion keeps the finished state.
// BookingThread builds on it; any other short process (listing review, visit steps, onboarding) uses it directly.
import type { CSSProperties, ReactNode } from 'react'
import { flat } from '@gz/tokens'
import type { IconName } from '@gz/tokens'
import { ThreadKnot, type KnotEndedTone, type KnotState } from '../brand'
import { cx } from './cx'
import { Icon, type IconTone } from './Icon'
import { useRevealOnce } from './useRevealOnce'
import './icon-progress.css'

export type IconProgressStep = {
  key: string
  icon: IconName
  /** One word. Shown only under the active step (or all steps with `labels="all"`). */
  label: string
  state: KnotState
  /** `ended` steps: the terminal glyph and tone on the knot. */
  ended?: { icon: IconName; tone: KnotEndedTone }
}

export type IconProgressProps = {
  steps: readonly IconProgressStep[]
  /** The group's accessible name ("Booking progress"); the active step is appended for you when `describe` is given. */
  label: string
  /** The sentence for assistive technology: "Request, step 2 of 5". Built by the caller from the formatter. */
  describe?: string
  /** `active` (default): one word under the active step. `all`: every step is labelled. `none`: icons only (the accessible names remain). */
  labels?: 'active' | 'all' | 'none'
  /** A full-width line under the thread (a deadline: glyph and time, never a sentence). Hairline above. */
  note?: ReactNode
  /** The note is gold-700 while waiting, danger when ended. */
  noteTone?: 'muted' | 'now' | 'danger'
  onDark?: boolean
  draw?: 'inview' | 'mount' | false
  /** Step key that just changed in view: its knot pops once. */
  pop?: string
  className?: string
}

const SEG_DELAY = flat['motion.duration.fast']
const ICON_TONE: Record<KnotState, IconTone> = { open: 'disabled', now: 'accent', tied: 'primary', ended: 'secondary' }

export function IconProgress({ steps, label, describe, labels = 'active', note, noteTone = 'muted', onDark = false, draw = 'inview', pop, className }: IconProgressProps) {
  const [ref, seen] = useRevealOnce<HTMLDivElement>(draw === 'inview')
  const armed = draw === 'inview' && !seen
  const drawing = draw === 'mount' || (draw === 'inview' && seen)
  const reached = (s: IconProgressStep) => s.state === 'tied' || s.state === 'now' || s.state === 'ended'
  const segStyle = (i: number): CSSProperties => ({ '--gz-delay': `${i * SEG_DELAY}ms` }) as CSSProperties

  return (
    <div ref={ref} data-gz="IconProgress" role="group" aria-label={describe ? `${label}: ${describe}` : label} className={cx('gz-iprog', onDark && 'gz-on-dark', className)}>
      <div className="gz-iprog__cols">
        {steps.map((s, i) => {
          const last = i === steps.length - 1
          const active = s.state === 'now' || s.state === 'ended'
          const shown = labels === 'all' || (labels === 'active' && active)
          const tone: IconTone = s.state === 'ended' ? (s.ended?.tone === 'danger' || s.ended?.tone === 'danger-outline' ? 'danger' : 'secondary') : ICON_TONE[s.state]
          return (
            <div key={s.key} className={cx('gz-iprog__col', `is-${s.state}`)} data-gz-id={`step.${s.key}`}>
              <span className="gz-iprog__icon">
                <Icon name={s.icon} size="md" tone={onDark && s.state !== 'now' ? 'on-dark' : tone} className={cx(s.state === 'open' && 'gz-iprog__icon--open', s.state === 'now' && 'gz-iprog__icon--now')} />
              </span>
              <div className="gz-iprog__head">
                <ThreadKnot state={s.state} onDark={onDark} endedIcon={s.ended?.icon} endedTone={s.ended?.tone} pop={pop === s.key} />
                {!last ? (
                  <span className="gz-iprog__seg gz-thread-track" aria-hidden="true">
                    {reached(steps[i + 1]!) ? <span className={cx('gz-thread-fill gz-iprog__fill', armed && 'is-armed', drawing && 'gz-thread-draw')} style={segStyle(i)} /> : null}
                  </span>
                ) : null}
              </div>
              <span className={cx(shown ? 'gz-iprog__label gz-t-caption' : 'gz-sr-only', s.state === 'ended' && 'is-ended')}>{s.label}</span>
            </div>
          )
        })}
      </div>
      {note ? <p className={cx('gz-iprog__note gz-t-caption', noteTone === 'now' && 'is-now', noteTone === 'danger' && 'is-danger')}>{note}</p> : null}
    </div>
  )
}
