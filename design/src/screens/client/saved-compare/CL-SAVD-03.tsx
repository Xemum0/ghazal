// CL-SAVD-03 Replace which one? (sheet). Covers CA-CMP-02, CA-CMP-01.
// Shown on the fourth add: Compare holds three halls, so nothing is dropped silently and the family chooses which one to swap. Each row is a
// choice (the system compare card: an ink border and a check, never gold; a pressed-state button, because the tap acts at once), and choosing
// one replaces it and closes the sheet. The close glyph in the header leaves the set as it was.
// Text diet (ADR 0034): the explaining sentence is a picture: the incoming hall in a rose-tint card with the swap glyph, above the three halls
// it can replace. The sentence stays as visually hidden text for assistive technology. No Cancel button: the header's close glyph is the same exit.
import { useEffect, useRef, useState } from 'react'
import { cardPrice, getArea, getVenue, type Venue } from '../../../mock'
import { useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Icon, Monogram, Photo, SheetHeader, VenueCard, imageSrc, useBi, useNav } from '../../../system'
import { usePrototype } from '../../../shell/state'
import { COMPARE_MAX, useSavedModel } from './_components/useSavedData'
import './CL-SAVD-03.css'

/** The hall that triggered the sheet when no params arrive (a static frame, a direct visit): the winter-rate hall of the story. */
const DEFAULT_NEW = 'V09'

export default function ReplaceWhichOne() {
  const t = useT('client-saved-compare')
  const nav = useNav<{ newId?: string }>()
  const m = useSavedModel()
  const bi = useBi()
  const { lang } = useLang()
  const newId = typeof nav.params.newId === 'string' ? nav.params.newId : DEFAULT_NEW
  const incoming = getVenue(newId)
  const incomingArea = incoming ? getArea(incoming.areaId) : undefined
  const rows = m.compare.slice(0, COMPARE_MAX).flatMap(id => (getVenue(id) ? [getVenue(id) as Venue] : []))
  const [chosen, setChosen] = useState<string | null>(null)
  const timer = useRef<number>(0)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const choose = (old: Venue) => {
    if (chosen) return
    setChosen(old.id)
    if (m.live) usePrototype.getState().replaceInCompare(old.id, newId)
    // The check shows for a beat (one settle, 320 ms) before the sheet leaves.
    timer.current = window.setTimeout(() => {
      nav.closeSheet()
      if (incoming) nav.toast({ message: t('clientSavedCompareReplaceDone'), tone: 'success' })
    }, 320)
  }

  return (
    <div className="svd-replace" data-gz-id="replace">
      <SheetHeader title={t('clientSavedCompareReplaceTitle')} onClose={() => nav.closeSheet()} />
      <p className="gz-sr-only">{t('clientSavedCompareReplaceBody', { max: COMPARE_MAX, name: incoming ? bi(incoming.name) : '' })}</p>
      {incoming ? (
        <div className="svd-replace__new" role="group" aria-label={bi(incoming.name)} data-gz-id="replace.new">
          <span className="svd-replace__thumb">
            {incoming.cover ? <Photo src={imageSrc(incoming.cover.file)} alt="" className="svd-replace__photo" /> : <Monogram size="sm" />}
          </span>
          <span className="svd-replace__who">
            <span className="svd-replace__name gz-t-d1 gz-clamp-2" lang={lang}>
              {bi(incoming.name)}
            </span>
            {incomingArea ? <span className="svd-replace__area gz-t-caption">{bi(incomingArea.name)}</span> : null}
          </span>
          <span className="svd-replace__swap" aria-hidden="true">
            <Icon name="swap" size="md" />
          </span>
        </div>
      ) : null}
      <ul className="svd-replace__list" aria-label={t('clientSavedCompareReplaceTitle')}>
        {rows.map(v => (
          <li key={v.id}>
            <VenueCard variant="compare" venue={v} price={cardPrice(v.id, m.brief)} selected={chosen === v.id} onSelect={() => choose(v)} />
          </li>
        ))}
      </ul>
    </div>
  )
}
