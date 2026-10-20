// FactChip and FactRow (ADR 0034, docs/design/02-text-diet.md section 2): a fact is an icon and a value, no label.
// The label moves into the accessible name (visually hidden text before the value): "Guests 350" for a screen reader, `[users] 350`
// on screen. A value may be a formatter string (its digits become Cairo figures through <Figures>) or any node. A unit is quiet and
// follows the value (`m²`, `km`, `h`, `/guest`). FactChip is not a control: it has no target size and never takes focus.
// Direction of the value: a pure figure, code or phone is an LTR isolate (the figures roles). A string that mixes figures and Arabic words
// (a date, a duration, a time range, money) takes the language direction, each digit run staying an LTR island (<Figures>), so it reads
// `14 يناير`, `63 يومًا`, `2 د.ك` in Arabic and not unit first.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { cx } from './cx'
import { plainText } from '@gz/i18n'
import { Figures } from './Figures'
import { Icon } from './Icon'
import './fact.css'

export type FactTone = 'default' | 'accent' | 'muted'

export type FactChipProps = {
  icon: IconName
  /** The value: a formatter string (money, count, short date) or a node. Never a sentence. Omit for a fact that is its glyph alone (sun, parking). */
  value?: ReactNode
  /** A quiet unit after the value. */
  unit?: ReactNode
  /** What the fact is (guests, area, session ...). Read by assistive technology, not shown. */
  label: string
  /** `accent` = gold-700 glyph (ratings, held), `muted` = secondary value (a fact that is background). */
  tone?: FactTone
  /** `md` = 16 (rows, cards), `sm` = 13 caption (dense lists). */
  size?: 'md' | 'sm'
  /** Mirror the glyph in Arabic (only for a directional glyph; the registry decides by default). */
  className?: string
}

/** Arabic letters in a value: it mixes figures and words (`14 يناير`, `2 د.ك`, `63 يومًا`), so it reads in the language direction. */
const hasArabic = (text: string): boolean => /[\u0600-\u06FF]/.test(plainText(text))

export function FactChip({ icon, value, unit, label, tone = 'default', size = 'md', className }: FactChipProps) {
  const role = size === 'sm' ? 'gz-t-fig-caption' : 'gz-t-fig-body-s'
  return (
    <span data-gz="FactChip" data-tone={tone} data-size={size} className={cx('gz-fchip', `gz-fchip--${tone}`, `gz-fchip--${size}`, className)}>
      <Icon name={icon} size={size === 'sm' ? 'xs' : 'sm'} tone={tone === 'accent' ? 'accent' : 'secondary'} />
      <span className="gz-sr-only">{label}</span>
      {value !== undefined && value !== null && value !== '' ? (
        <span className={cx('gz-fchip__value', role, typeof value === 'string' && hasArabic(value) && 'gz-fchip__value--words')}>
          {typeof value === 'string' ? <Figures text={value} /> : value}
        </span>
      ) : null}
      {unit ? <span className="gz-fchip__unit gz-t-caption">{unit}</span> : null}
    </span>
  )
}

export type FactRowProps = {
  children: ReactNode
  /** Names the group for assistive technology ("Details"). Optional. */
  label?: string
  /** `scroll` keeps one line and scrolls sideways (a rail of facts); `wrap` (default) wraps only when the width runs out. */
  overflow?: 'wrap' | 'scroll'
  className?: string
}

/** Two to five facts on one line. Order is always: guests, area, session, rating, price. Unknown facts are omitted, never dashed. */
export function FactRow({ children, label, overflow = 'wrap', className }: FactRowProps) {
  return (
    <div data-gz="FactRow" role="group" aria-label={label} className={cx('gz-frow', overflow === 'scroll' && 'gz-frow--scroll gz-no-scrollbar', className)}>
      {children}
    </div>
  )
}
