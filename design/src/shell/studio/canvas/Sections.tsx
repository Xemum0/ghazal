// A flow is a section: a quiet panel behind its frames, with the header column on the inline-start side (title, intent, how much is
// built, two commands). The header grows when the board is zoomed out (--gzs-ui-s) so the flow names stay readable in the overview.
import { memo, type CSSProperties } from 'react'
import { Button } from '../../../system/core'
import { go } from '../../router'
import { useLang } from '../../lang'
import { isBuilt } from '../../registry'
import { Khayt } from '../bits'
import { pickLoc, useCopy } from '../copy'
import { playHash } from '../links'
import { canvas } from './bridge'

const TAG_INSET = 32
import type { SectionNode } from './layout'

export const SectionPanel = memo(function SectionPanel({ section }: { section: SectionNode }) {
  const style = { transform: `translate3d(${section.x}px, ${section.y}px, 0)`, inlineSize: section.w, blockSize: section.h } as CSSProperties
  return <div className="gzs-section" data-gz="FlowSection" data-flow={section.flow.id} style={style} />
})

export const SectionHeader = memo(function SectionHeader({ section, w }: { section: SectionNode; w: number | null }) {
  const { lang, dir } = useLang()
  const t = useCopy()
  const flow = section.flow
  const total = flow.screens.length
  const built = flow.screens.filter(s => isBuilt(s.id)).length
  const first = flow.screens[0]
  const style = { transform: `translate3d(${section.header.x}px, ${section.header.y}px, 0)`, inlineSize: section.header.w } as CSSProperties
  return (
    <header className="gzs-sechead" data-gz="FlowHeader" data-dir={dir} dir={dir} style={style}>
      <div className="gzs-sechead__in">
        <span className="gz-t-label gzs-sechead__num">
          {t('flow1')} <span className="gz-num">{String(section.index + 1).padStart(2, '0')}</span>
        </span>
        <Khayt />
        <h2 className="gzs-sechead__title gz-t-d3">{pickLoc(flow.title, lang)}</h2>
        <p className="gzs-sechead__intent gz-t-body-s" dir="auto">{flow.intent}</p>
        <div className="gzs-sechead__progress" role="img" aria-label={`${built} ${t('of')} ${total} ${t('built')}`}>
          <span className="gzs-sechead__track">
            <span className="gzs-sechead__fill" style={{ inlineSize: `${(built / Math.max(1, total)) * 100}%` }} />
          </span>
          <span className="gz-t-caption gzs-sechead__count">
            <span className="gz-num">{built}</span> {t('of')} <span className="gz-num">{total}</span> {t('built')}
          </span>
        </div>
        <div className="gzs-sechead__actions">
          <Button variant="secondary" size="sm" iconStart="play" onClick={() => first && go(playHash(flow.app, first.id, { lang, w }))}>
            {t('playFlow')}
          </Button>
          <Button variant="tertiary" size="sm" onClick={() => canvas.fitFlow(flow.id)}>
            {t('fitShort')}
          </Button>
        </div>
      </div>
    </header>
  )
})

/** The Figma-style section name: constant on-screen size, shown only when the board is zoomed out far enough that the header column is not legible. */
export const SectionTag = memo(function SectionTag({ section }: { section: SectionNode }) {
  const { lang, dir } = useLang()
  const t = useCopy()
  const flow = section.flow
  const built = flow.screens.filter(s => isBuilt(s.id)).length
  // Anchored just inside the section's inline-start top corner.
  const style = { transform: `translate3d(${section.mirror ? section.x + section.w - TAG_INSET : section.x + TAG_INSET}px, ${section.y + TAG_INSET}px, 0)` } as CSSProperties
  return (
    <div className="gzs-tag" data-gz="FlowTag" data-dir={dir} dir={dir} style={style} aria-hidden="true">
      <div className="gzs-tag__in gz-t-body-s">
        <span className="gzs-tag__num"><span className="gz-num">{String(section.index + 1).padStart(2, '0')}</span></span>
        <span className="gzs-tag__title">{pickLoc(flow.title, lang)}</span>
        <span className="gzs-tag__count"><bdi dir="ltr" className="gz-num">{built}/{flow.screens.length}</bdi> {t('built')}</span>
      </div>
    </div>
  )
})
