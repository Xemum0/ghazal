// CL-SAVD-02 Compare tray (sheet kind). Covers CA-CMP-01, CA-CMP-03, CA-CMP-11, CA-CMP-12.
// The tray is one component with several states. On Home, Results and Saved it floats above the tab bar (see CL-SAVD-01: one hall, two or
// three ready, the 44 pill). On Venue detail it must never cover the sticky price bar, so it becomes the count-only header badge, and tapping
// that badge opens THIS sheet: the set as three rows with a remove control each, a hairline empty slot while only one hall is in, and
// the one action, Compare. Nothing here nags: no push, no re-prompt after Clear.
// Text diet (ADR 0034): the title is one word, the hint sentence is gone, the empty slot is a dashed plus (its words are the accessible name,
// and the disabled Compare says "Add one more" under itself because that prevents an error).
import { cardPrice, getArea, getVenue, type Venue } from '../../../mock'
import { useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Button, CardPriceLine, Icon, IconButton, Monogram, Photo, SheetHeader, imageSrc, useBi, useNav } from '../../../system'
import { usePrototype } from '../../../shell/state'
import { COMPARE_MAX, useSavedModel } from './_components/useSavedData'
import { useLang } from '../../../shell/lang'
import './CL-SAVD-02.css'

export const states = ['one-venue', 'two-or-three-ready', 'full']

export default function CompareTraySheet() {
  const { state } = useFrame()
  const t = useT('client-saved-compare')
  const c = useT('common')
  const nav = useNav()
  const m = useSavedModel()
  const bi = useBi()
  const { lang } = useLang()
  const ids = state === 'one-venue' ? m.compare.slice(0, 1) : state === 'two-or-three-ready' ? m.compare.slice(0, 2) : m.compare.slice(0, COMPARE_MAX)
  const venues = ids.flatMap(id => (getVenue(id) ? [getVenue(id) as Venue] : []))
  const ready = venues.length >= 2
  const empties = Math.max(0, Math.min(1, COMPARE_MAX - venues.length))

  const remove = (id: string) => m.live && usePrototype.getState().removeFromCompare(id)
  const clear = () => {
    if (m.live) usePrototype.getState().clearCompare()
    nav.closeSheet()
  }

  return (
    <div className="svd-tray" data-gz-id="traysheet">
      <SheetHeader title={t('clientSavedCompareTrayTitle')} onClose={() => nav.closeSheet()} />
      <ul className="svd-tray__list">
        {venues.map(v => {
          const area = getArea(v.areaId)
          const price = cardPrice(v.id, m.brief)
          return (
            <li key={v.id} className="svd-tray__row">
              <span className="svd-tray__thumb">{v.cover ? <Photo src={imageSrc(v.cover.file)} alt="" className="svd-tray__photo" /> : <Monogram size="sm" />}</span>
              <span className="svd-tray__text">
                <span className="svd-tray__name gz-t-d1 gz-clamp-2" lang={lang}>
                  {bi(v.name)}
                </span>
                {area ? <span className="svd-tray__area gz-t-caption">{bi(area.name)}</span> : null}
                {price ? <CardPriceLine price={price} /> : null}
              </span>
              <IconButton icon="close" label={t('clientSavedCompareTrayRemove', { name: bi(v.name) })} onClick={() => remove(v.id)} />
            </li>
          )
        })}
        {Array.from({ length: empties }, (_, i) => (
          <li key={`e${i}`} className="svd-tray__row svd-tray__row--empty">
            <span className="svd-tray__thumb svd-tray__thumb--empty" aria-hidden="true">
              <Icon name="plus" size="sm" tone="secondary" />
            </span>
            <span className="gz-sr-only">{t('clientSavedCompareTrayAddOne')}</span>
          </li>
        ))}
      </ul>
      <div className="svd-tray__actions">
        <Button
          variant="primary"
          fullWidth
          disabled={!ready}
          reason={ready ? undefined : t('clientSavedCompareTrayAddOne')}
          onClick={() => {
            nav.closeSheet()
            nav.push('CL-SAVD-04')
          }}
        >
          {t('clientSavedCompareTrayAction', { count: venues.length })}
        </Button>
        <Button variant="tertiary" className="svd-tray__clear" onClick={clear}>
          {c('commonActionClear')}
        </Button>
      </div>
    </div>
  )
}
