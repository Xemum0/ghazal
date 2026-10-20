// TextFact: the FactChip anatomy (glyph, then a value) for a value that carries WORDS (a short date "Thu 14 Jan" / «14 يناير», an area name,
// "20 h 40 m", "18 min · 13 km"). The system FactChip draws its value in a figure role (`gz-t-fig-*`: direction ltr, isolate) because it is made
// for pure figures (350, 4.8, KD 15,400); a string with Arabic words in that role reads in the wrong order (the day after the month, the
// minutes after the hours). TextFact keeps the chip's layout classes and draws the value in the ordinary text role (direction from the
// language) with every digit run still a Cairo LTR island (Figures). Flow-local until the system FactChip handles word values (requests.md).
import type { IconName } from '@gz/tokens'
import { Figures, Icon } from '../../../../system'

export type TextFactProps = {
  icon: IconName
  /** A formatter or message string (words and numbers). */
  value: string
  /** What the fact is; read by assistive technology, not shown. */
  label: string
  tone?: 'default' | 'muted' | 'accent'
  size?: 'md' | 'sm'
}

export function TextFact({ icon, value, label, tone = 'default', size = 'md' }: TextFactProps) {
  return (
    <span data-gz="FactChip" data-tone={tone} data-size={size} className={`gz-fchip gz-fchip--${tone} gz-fchip--${size}`}>
      <Icon name={icon} size={size === 'sm' ? 'xs' : 'sm'} tone={tone === 'accent' ? 'accent' : 'secondary'} />
      <span className="gz-sr-only">{label}</span>
      <span className={`gz-fchip__value ${size === 'sm' ? 'gz-t-caption' : 'gz-t-body-s'}`}>
        <Figures text={value} />
      </span>
    </span>
  )
}
