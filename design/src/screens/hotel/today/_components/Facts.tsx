// Facts of the Today flow (docs/design/02-text-diet.md section 2): an icon and a value, never a label. The label is the accessible name.
//   FactValue  the value of a FactChip that holds words as well as digits (a date `14 يناير`, a clock `3:12 م`): FactChip forces its whole
//              string into one LTR island, which puts an Arabic month on the wrong side of its day; this gives the value its own direction
//              (docs/engineering/requests.md, flow:client-messages) and keeps each digit run an LTR island.
//   TimeLeft   `[timer] 3 h` in the SLA tone (neutral, gold from half the window, danger from 80% or under an hour); `glyph="hourglass"` is
//              time spent waiting. The spoken sentence rides along as visually hidden text.
import type { IconName } from '@gz/tokens'
import { FactChip, Figures, Icon } from '../../../../system'
import { useDur } from './time'
import './facts.css'

export function FactValue({ text }: { text: string }) {
  return (
    <bdi dir="auto">
      <Figures text={text} />
    </bdi>
  )
}

/** A fact whose value is a short day or time (a string from the formatter). */
export function TextFact({ icon, text, label, tone, size }: { icon: IconName; text: string; label: string; tone?: 'default' | 'accent' | 'muted'; size?: 'md' | 'sm' }) {
  return <FactChip icon={icon} label={label} value={<FactValue text={text} />} tone={tone} size={size} />
}

export type LeftTone = 'neutral' | 'gold' | 'danger' | 'expired'

/** Time left (timer) or time waited (hourglass) as a glyph and a compact duration; the sentence is the accessible name. */
export function TimeLeft({
  minutes,
  tone = 'neutral',
  glyph = 'timer',
  say,
  onDark = false,
  size = 'sm',
  className = '',
}: {
  minutes: number
  tone?: LeftTone
  glyph?: IconName
  /** The spoken sentence for a duration (`Reply window ends in 3 hours`). */
  say: (spoken: string) => string
  onDark?: boolean
  /** `md` is the band's figure (a 20 glyph and the body size); `sm` sits in a row (16 and the caption). */
  size?: 'sm' | 'md'
  className?: string
}) {
  const dur = useDur()
  const d = dur(minutes)
  return (
    <span className={`ht-left ht-left--${tone} ht-left--${size}${onDark ? ' ht-left--dark' : ''}${className ? ` ${className}` : ''}`}>
      <Icon name={glyph} size={size === 'md' ? 'sm' : 'xs'} />
      <span className={`ht-left__fig ${size === 'md' ? 'gz-t-body' : 'gz-t-caption'}`} aria-hidden="true">
        <FactValue text={d.visual} />
      </span>
      <span className="gz-sr-only">{say(d.spoken)}</span>
    </span>
  )
}
