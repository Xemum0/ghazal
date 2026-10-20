// CL-DISC-07 Search by region. Covers CA-FLT-01, CA-SRCH-03, CA-SRCH-02, CA-FLT-07, CA-HOME-03.
// Region, governorate and location search: a typeahead over governorates, areas and venue names (Arabic-normalised: «مشرف» finds Mishref, and
// transliteration aliases match) above the six governorates as expandable groups, each with its areas, venue counts and multi-select
// checkboxes (a governorate selects all of its areas). "Near me" asks for the location in context and filters by drive time; a refusal falls
// back to the preferred area. The primary "Show 3 halls" writes the selection to the Brief's areas and to the Results filter (shown there as
// removable chips). Reached from the Results Region chip and from the Filters and Brief sheets.
// Text diet (ADR 0034): no section titles (the glyph says recent, near, area, hall), counts are a hall glyph and a figure, "Near me" shows its
// drive time as a fact once on, and "no match" is a drawing, "No matches" and one way out (Clear).
// States: default, typing, no-match, location-denied, loading, offline, error.
import { useMemo, useState } from 'react'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { ActionBar, Banner, Chip, EmptyState, ErrorState, FactChip, Icon, Screen, Skeleton, TopBar, useBi, useNav } from '../../../system'
import { TextFact } from './_components/TextFact'
import { RegionList, useRegionGroups } from './_components/RegionList'
import { NO_FILTERS, fold, matchesQuery, results } from './_components/data'
import { useAskLocation } from './_components/useAskLocation'
import { useScenario } from './_components/scenario'
import { useDiscover } from './_components/state'
import './CL-DISC-07.css'

export const states = ['typing', 'no-match', 'location-denied', 'loading', 'offline', 'error']

/** The drive-time bound "Near me" applies (the Filters sheet offers 15, 30 and 45). */
const NEAR_MINUTES = 30

type RegionMatch = { kind: 'governorate' | 'area' | 'venue'; id: string; name: { en: string; ar: string }; venueCount: number }

export default function RegionSearch() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const bi = useBi()
  const { lang } = useLang()
  const s = useScenario(state)
  const groups = useRegionGroups()
  const live = s.live
  const brief = s.brief

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online

  const initial = useMemo<string[]>(() => {
    if (!live) return state === 'default' || state === undefined ? (brief.areaIds ?? []) : [...(brief.areaIds ?? [])]
    const st = useDiscover.getState().filters
    if (st.areaIds) return st.areaIds
    if (st.governorateIds.length) return groups.filter(g => st.governorateIds.includes(g.governorate.id)).flatMap(g => g.areas.map(a => a.id))
    return brief.areaIds ?? []
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  const [selected, setSelected] = useState<string[]>(initial)
  const [query, setQuery] = useState(!live && state === 'typing' ? (lang === 'ar' ? 'سال' : 'Sal') : !live && state === 'no-match' ? (lang === 'ar' ? 'دبي' : 'Dubai') : '')
  const [near, setNear] = useState(false)
  const [denied, setDenied] = useState(!live && state === 'location-denied')

  // The typeahead folds alef, ya, ta marbuta and tashkeel (fold() in data.ts), so «مشرف» finds Mishref and «سال» finds Salmiya. Only governorates and
  // areas that hold a hall are offered (the list below is the same set), then halls by name.
  const matches = useMemo<RegionMatch[]>(() => {
    const needle = fold(query)
    if (!needle) return []
    const hit = (names: readonly string[]) => names.some(x => fold(x).includes(needle))
    const perArea = new Map<string, number>()
    for (const v of mock.venues) perArea.set(v.areaId, (perArea.get(v.areaId) ?? 0) + 1)
    const out: RegionMatch[] = []
    for (const g of groups) {
      if (hit([g.governorate.name.en, g.governorate.name.ar])) out.push({ kind: 'governorate', id: g.governorate.id, name: g.governorate.name, venueCount: g.count })
    }
    for (const g of groups) {
      for (const a of g.areas) {
        const aliases = mock.getArea(a.id)?.aliases ?? []
        if (hit([a.name.en, a.name.ar, ...aliases])) out.push({ kind: 'area', id: a.id, name: a.name, venueCount: perArea.get(a.id) ?? 0 })
      }
    }
    for (const v of mock.venues) if (matchesQuery(v, query)) out.push({ kind: 'venue', id: v.id, name: v.name, venueCount: 1 })
    return out
  }, [query, groups])
  const typing = query.trim() !== ''

  // ---- the count: halls of the chosen areas, on the Brief date when there is one (the same list Results opens with)
  const count = useMemo(() => results({ ...brief, areaIds: selected }, { ...NO_FILTERS, areaIds: selected, available: Boolean(brief.date) }).length, [brief, selected])
  const cta = loading || offline || errored ? t('clientDiscoverCtaShow') : t('clientDiscoverCtaCount', { count })

  // ---- actions
  const toggleArea = (id: string) => setSelected(prev => (prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]))
  const toggleGovernorate = (id: string) => {
    const ids = groups.find(g => g.governorate.id === id)?.areas.map(a => a.id) ?? []
    setSelected(prev => (ids.every(x => prev.includes(x)) ? prev.filter(x => !ids.includes(x)) : [...new Set([...prev, ...ids])]))
  }
  const pick = (m: (typeof matches)[number]) => {
    if (m.kind === 'venue') {
      if (live) nav.push(mock.getVenue(m.id)?.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: m.id, from: 'discover' })
      return
    }
    if (m.kind === 'governorate') toggleGovernorate(m.id)
    else toggleArea(m.id)
    setQuery('')
  }
  const ask = useAskLocation()
  const askLocation = async () => {
    if (near) return setNear(false)
    if (!live) return
    if (await ask()) {
      setNear(true)
      setDenied(false)
    } else setDenied(true)
  }
  const apply = () => {
    if (!live) return
    s.setBrief({ areaIds: selected })
    const st = useDiscover.getState()
    st.replaceFilters({ ...st.filters, areaIds: null, governorateIds: [], withinMinutes: near ? NEAR_MINUTES : null })
    nav.pop()
  }

  const areaName = (id: string) => mock.getArea(id)?.name[lang] ?? ''
  const preferred = areaName(brief.areaIds?.[0] ?? 'salmiya')
  const recents = useMemo(() => {
    const out = (brief.areaIds ?? []).map(areaName).filter(Boolean)
    const hero = mock.getVenue(mock.heroBookingAs('pending').venueId ?? '')
    if (hero) out.push(bi(hero.name))
    return out
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [brief.areaIds, lang])

  const glyph = (m: (typeof matches)[number]) => (m.kind === 'venue' ? 'hall' : 'pin')

  return (
    <Screen
      top={
        <div className="gzd-reg__top">
          <TopBar variant="search" search={{ placeholder: t('clientDiscoverRegionPlaceholder'), value: query, onChange: q => (live ? setQuery(q) : undefined) }} back="auto" />
        </div>
      }
      bottom={<ActionBar action={{ label: cta, onPress: apply, disabled: errored || loading }} />}
    >
      <div className="gzd-reg" data-gz-id="region" aria-busy={loading || undefined}>
        {offline ? <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner> : null}

        {errored ? (
          <ErrorState kind="load" fill={false} onRetry={() => undefined} />
        ) : typing ? (
          matches.length === 0 ? (
            <EmptyState
              fill={false}
              illustration="no-result"
              title={c('commonStateTitleEmptySearch')}
              action={{ label: t('clientDiscoverResultsClearAll'), onPress: () => setQuery(''), variant: 'secondary', iconStart: 'close' }}
            />
          ) : (
            <section className="gzd-reg__section" data-gz-id="region.matches">
              <ul className="gzd-reg__matches">
                {matches.map(m => {
                  const on = m.kind === 'area' ? selected.includes(m.id) : false
                  return (
                    <li key={`${m.kind}-${m.id}`}>
                      <button type="button" className="gz-reset gzd-reg__match gz-press" onClick={() => pick(m)} aria-pressed={m.kind === 'venue' ? undefined : on}>
                        <Icon name={glyph(m)} size="sm" tone="secondary" />
                        <span className="gzd-reg__match-text gz-t-body">{m.name[lang]}</span>
                        {m.kind === 'venue' ? null : <FactChip icon="hall" label={t('clientDiscoverResultsTitle')} value={f.integer(m.venueCount)} tone="muted" />}
                        {on ? <Icon name="check" size="sm" /> : null}
                      </button>
                    </li>
                  )
                })}
              </ul>
            </section>
          )
        ) : (
          <div className="gzd-reg__stack">
            <section className="gzd-reg__section">
              <button type="button" className="gz-reset gzd-reg__near gz-press" onClick={askLocation} aria-pressed={near} data-gz-id="region.near">
                <Icon name="navigate" size="sm" />
                <span className="gzd-reg__near-text">
                  <span className="gz-t-body">{t('clientDiscoverRegionNear')}</span>
                </span>
                {near ? <TextFact icon="car" label={t('clientDiscoverA11yDrive')} value={t('clientDiscoverMinutes', { minutes: f.integer(NEAR_MINUTES) })} /> : null}
                {near ? <Icon name="check" size="sm" /> : null}
              </button>
              {denied ? (
                <p className="gzd-reg__note gz-t-caption" role="status">
                  <Icon name="pin" size="xs" tone="secondary" />
                  {t('clientDiscoverMapDenied', { area: preferred })}
                </p>
              ) : null}
            </section>

            {!loading && recents.length > 0 ? (
              <section className="gzd-reg__section" data-gz-id="region.recent">
                <div className="gzd-reg__recents" role="group" aria-label={t('clientDiscoverSearchRecent')}>
                  {recents.map(r => (
                    <Chip key={r} iconStart="clock" onClick={() => live && setQuery(r)}>
                      {r}
                    </Chip>
                  ))}
                </div>
              </section>
            ) : null}

            <section className="gzd-reg__section" data-gz-id="region.groups">
              {loading ? (
                <div className="gzd-reg__section" aria-hidden="true">
                  {[0, 1, 2, 3, 4, 5].map(i => (
                    <Skeleton key={i} inlineSize={i % 2 ? 180 : 140} blockSize={24} />
                  ))}
                </div>
              ) : (
                <RegionList groups={groups} selected={selected} onChange={setSelected} defaultOpen={groups.filter(g => g.areas.some(a => selected.includes(a.id))).map(g => g.governorate.id)} />
              )}
            </section>
          </div>
        )}
      </div>
    </Screen>
  )
}
