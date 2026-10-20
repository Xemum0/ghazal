// Section: one shelf of Home. Khayt head on the gutter (serif d2 title of one or two words), the body under it. "See all" is the chevron alone
// in a 44 hairline disk at inline-end (the shelf's name is its accessible name): eight repeated "All" words became one glyph (ADR 0034, section 7:
// a universal disclosure glyph, never about money or a decision). 32 between sections is the section rhythm (direction 2.5); the head draws its
// khayt once as it comes into view. No note line under the title (the Brief card says date, area and guests once).
import type { ReactNode } from 'react'
import { IconButton, ThreadRule } from '../../../../system'
import { useT } from '../../../../i18n'
import './rail.css'

export type SectionProps = {
  title: string
  onSeeAll?: () => void
  /** Static frames draw the khayt immediately; the live screen draws it as it scrolls in. */
  draw?: 'mount' | 'inview'
  children: ReactNode
  dataId?: string
}

export function Section({ title, onSeeAll, draw = 'inview', children, dataId }: SectionProps) {
  const c = useT('common')
  return (
    <section className="gzd-section" data-gz-id={dataId}>
      <div className="gzd-section__head">
        <header data-gz="SectionHeader" data-voice="client" className="gz-sechead">
          <ThreadRule variant="khayt" draw={draw} />
          <div className="gz-sechead__row">
            <h2 className="gz-sechead__title gz-t-d2">{title}</h2>
            {onSeeAll ? <IconButton icon="chevron-right" variant="outline" label={`${c('commonActionSeeAll')}: ${title}`} onClick={onSeeAll} data-gz-id="see-all" /> : null}
          </div>
        </header>
      </div>
      {children}
    </section>
  )
}
