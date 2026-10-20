// SectionHeader (direction section 3, "Section head"): the 24 x 1 gold khayt, then the title (client: serif d2; hotel: UI title),
// an optional eyebrow label (at most two per screen) and `See all` as a tertiary button at inline-end. The khayt draws on once
// as the header first scrolls into view. Titles are headings: choose the level for the page outline.
import type { ReactNode } from 'react'
import { useT } from '../../i18n'
import { Button } from './Button'
import { cx } from './cx'
import { ThreadRule } from './Divider'
import './section-header.css'

export type SectionHeaderProps = {
  title: ReactNode
  /** Small label above the title (direction: at most two per screen, never on every section). */
  eyebrow?: string
  /** `client` = display serif d2; `hotel` = UI title 20/28 (the hotel app keeps the serif for names and the greeting). */
  voice?: 'client' | 'hotel'
  level?: 2 | 3
  /** Shows the See all button. */
  onSeeAll?: () => void
  /** Replace `See all` (a section with a count, "See all 38"). */
  seeAllLabel?: string
  /** One more control at inline-end of the title row (an `InfoButton` or one icon button), e.g. the voucher-terms (i) of a price section. */
  action?: ReactNode
  draw?: 'mount' | 'inview' | false
  className?: string
}

export function SectionHeader({ title, eyebrow, voice = 'client', level = 2, onSeeAll, seeAllLabel, action, draw = 'inview', className }: SectionHeaderProps) {
  const t = useT('common')
  const Heading = level === 2 ? 'h2' : 'h3'
  return (
    <header data-gz="SectionHeader" data-voice={voice} className={cx('gz-sechead', className)}>
      <ThreadRule variant="khayt" draw={draw} />
      {eyebrow ? <p className="gz-t-label gz-sechead__eyebrow">{eyebrow}</p> : null}
      <div className="gz-sechead__row">
        <Heading className={cx('gz-sechead__title', voice === 'client' ? 'gz-t-d2' : 'gz-t-ui-title')}>{title}</Heading>
        {action ? <span className="gz-sechead__action">{action}</span> : null}
        {onSeeAll ? (
          <Button variant="tertiary" iconEnd="chevron-right" onClick={onSeeAll} className="gz-sechead__all">
            {seeAllLabel ?? t('commonActionSeeAll')}
          </Button>
        ) : null}
      </div>
    </header>
  )
}
