// Typeahead (CL-DISC-03, state `searching`): what the list becomes while the name search has focus. Empty field: recent searches (the Brief's
// governorates and the hall the couple last asked, nothing invented). Typing: matching governorates (pin glyph, name, hall count as glyph
// and figure), then matching halls (hall glyph, name); the match folds alef, ya, ta marbuta and tashkeel (fold() in data.ts), and a hall
// is also found by its address line («مشرف» finds the halls of Mishref). Choosing a governorate narrows Results to it (ADR 0038: no exact
// area is chosen); choosing a hall opens it. Search events would fire after an 800 ms debounce (ADR 0019); the
// prototype filters on every key. ADR 0034: the glyph says recent, area or hall, so there are no visible section titles (the heading stays for
// assistive technology) and no sentence for "no match".
import { useMemo } from 'react'
import * as mock from '../../../../mock'
import { EmptyState, FactChip, Icon, briefGovernorates, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { fold, matchesQuery, type SearchBrief } from './data'
import './typeahead.css'

export type TypeaheadProps = {
  query: string
  brief: SearchBrief
  onPickGovernorate: (governorateId: string) => void
  onPickVenue: (venueId: string) => void
  onPickRecent: (text: string) => void
  onClearRecent: () => void
}

export function Typeahead({ query, brief, onPickGovernorate, onPickVenue, onPickRecent, onClearRecent }: TypeaheadProps) {
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const needle = fold(query)

  const regions = useMemo(() => {
    if (!needle) return []
    return mock.governorates
      .filter(g => [g.name.en, g.name.ar].some(x => fold(x).includes(needle)))
      .map(g => ({ governorate: g, count: mock.venues.filter(v => v.governorateId === g.id).length }))
      .filter(r => r.count > 0)
  }, [needle])
  const halls = useMemo(() => (needle ? mock.venues.filter(v => matchesQuery(v, query)).slice(0, 5) : []), [needle, query])

  const recents = useMemo(() => {
    const out: string[] = []
    for (const id of briefGovernorates(brief)) {
      const g = mock.getGovernorate(id)
      if (g) out.push(bi(g.name))
    }
    const hero = mock.getVenue(mock.heroBookingAs('pending').venueId ?? '')
    if (hero) out.push(bi(hero.name))
    return out
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [brief.governorateIds, brief.areaIds])

  const keep = (e: { preventDefault: () => void }) => e.preventDefault() // keep the field focused while a row is pressed

  if (!needle) {
    return (
      <div className="gzd-ta" data-gz="Typeahead" data-gz-id="typeahead">
        <header className="gzd-ta__head">
          <h2 className="gz-sr-only">{t('clientDiscoverSearchRecent')}</h2>
          <button type="button" className="gz-reset gzd-ta__clear gz-t-caption" onPointerDown={keep} onClick={onClearRecent}>
            {t('clientDiscoverSearchClearRecent')}
          </button>
        </header>
        <ul className="gzd-ta__list">
          {recents.map(text => (
            <li key={text}>
              <button type="button" className="gz-reset gzd-ta__row gz-press" onPointerDown={keep} onClick={() => onPickRecent(text)}>
                <Icon name="clock" size="sm" tone="secondary" />
                <span className="gzd-ta__text gz-t-body">{text}</span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    )
  }

  if (regions.length === 0 && halls.length === 0) {
    return (
      <div className="gzd-ta" data-gz="Typeahead" data-gz-id="typeahead">
        <EmptyState fill={false} illustration="no-result" title={c('commonStateTitleEmptySearch')} />
      </div>
    )
  }

  return (
    <div className="gzd-ta" data-gz="Typeahead" data-gz-id="typeahead">
      {regions.length > 0 ? (
        <section>
          <ul className="gzd-ta__list">
            {regions.map(({ governorate, count }) => (
              <li key={governorate.id}>
                <button type="button" className="gz-reset gzd-ta__row gz-press" onPointerDown={keep} onClick={() => onPickGovernorate(governorate.id)}>
                  <Icon name="pin" size="sm" tone="secondary" />
                  <span className="gzd-ta__text gz-t-body">{bi(governorate.name)}</span>
                  <FactChip icon="hall" label={t('clientDiscoverResultsTitle')} value={f.integer(count)} />
                </button>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      {halls.length > 0 ? (
        <section>
          <ul className="gzd-ta__list">
            {halls.map(v => (
              <li key={v.id}>
                <button type="button" className="gz-reset gzd-ta__row gz-press" onPointerDown={keep} onClick={() => onPickVenue(v.id)}>
                  <Icon name="hall" size="sm" tone="secondary" />
                  <span className="gzd-ta__text gz-t-body">{bi(v.name)}</span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  )
}
