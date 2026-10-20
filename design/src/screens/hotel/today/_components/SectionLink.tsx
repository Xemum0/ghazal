// SectionLink: the section head of the diet. The 24 x 1 gold khayt, then the title (UI title, hotel voice) and, when the section opens
// somewhere, a count and a chevron at inline-end in the same 44 px press target: `See all` and its caption are the chevron, not words
// (docs/design/02-text-diet.md section 11). The system SectionHeader prints `See all`; this twin is flow-local until it takes a glyph-only
// link (docs/engineering/requests.md, flow:hotel-today).
import type { ReactNode } from 'react'
import { Fig, Icon, ThreadRule } from '../../../../system'
import { useWords } from './bits'

export type SectionLinkProps = {
  title: ReactNode
  /** A count at inline-end (the queue length, a number of days). */
  count?: number | string
  /** Opens the section's home. Without it the head is a plain heading. */
  onPress?: () => void
  /** The accessible sentence of the link (`See all 10`), read after the title. */
  hint?: string
  className?: string
}

export function SectionLink({ title, count, onPress, hint, className }: SectionLinkProps) {
  const { c } = useWords()
  const body = (
    <>
      <span className="ht-sh__title gz-t-ui-title">{title}</span>
      {onPress ? (
        <span className="ht-sh__end">
          {count !== undefined ? (
            <span className="ht-sh__count gz-t-fig-body-s">
              <Fig>{String(count)}</Fig>
            </span>
          ) : null}
          <Icon name="chevron-right" size="sm" tone="secondary" />
        </span>
      ) : null}
    </>
  )
  return (
    <header data-gz="SectionLink" className={`ht-sh${className ? ` ${className}` : ''}`}>
      <ThreadRule variant="khayt" />
      <h2 className="ht-sh__h">
        {onPress ? (
          <button type="button" className="gz-reset ht-sh__row gz-press" onClick={onPress} aria-label={`${typeof title === 'string' ? title : ''}. ${hint ?? c('commonActionSeeAll')}`}>
            {body}
          </button>
        ) : (
          <span className="ht-sh__row">{body}</span>
        )}
      </h2>
    </header>
  )
}
