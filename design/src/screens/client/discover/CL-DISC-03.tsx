// CL-DISC-03 Results. Covers CA-SRCH-01, CA-SRCH-14, CA-SRCH-16, CA-SRCH-17, CA-SRCH-20, CA-SRCH-21, CA-HOME-06, CA-HOME-08, CA-HOME-16,
// CA-CARD-01 to CA-CARD-13, CA-TOOL-01, CA-CMP-01, CA-FLT-01 to CA-FLT-07, CA-VCH-02, CA-VCH-10.
// The venue list for the Brief. Top: back and the name search (typeahead). Under it the Brief as its facts (BriefFacts: glyph and value each,
// one button that opens the Brief sheet), then one chip row: Filters (count), then Sort, Region (governorates: opens the Filters sheet on its Region group) and Date (CL-DISC-06) as glyph-only
// chips that say a value only once it differs from what the Brief above already says (a chosen order, governorates, "All governorates" or a date range), every other
// applied filter as a glyph chip with a close mark, Clear. Then the count (hall glyph and a figure). The cards are the canonical
// VenueCard (ADR 0018) with the two prices of the voucher model (ADR 0033): the voucher price as the headline and the standard price
// beneath; under a free hall the one action is "Get voucher" or "View". A booked hall offers its free
// dates; a governmental facility is its own browse-only card, its rule one info glyph away. Pull to refresh; the Compare tray and the Map
// pill float above the bar.
// Text diet (ADR 0034): no sentence on the screen. Empty: a drawing, "No matches", one action. Error and offline: the shared states.
// No signed-out variant (ADR 0038). States: default, loading, no-results, error, offline, searching, voucher-price-filter-on,
// venue-type-governmental-card, region-filter-on.
import { useMemo, useState } from 'react'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import {
  Banner, Button, Chip, EmptyState, ErrorState, FactChip, Figures, Icon, InfoButton, PullToRefresh, Screen, TopBar, VenueCard, useNav,
} from '../../../system'
import { AppliedChips } from './_components/AppliedChips'
import { BriefFacts } from './_components/BriefFacts'
import { TextFact } from './_components/TextFact'
import { DateFilterSheet } from './_components/DateFilterSheet'
import { SortSheet } from './_components/SortSheet'
import { TrayDock } from './_components/TrayDock'
import { Typeahead } from './_components/Typeahead'
import { CardAction, useVenueCards } from './_components/cards'
import { activeFilterCount, nearestFreeDates, results } from './_components/data'
import { clearedFilters, useAppliedChips, useDayLabel, useLabels, type Chip as AppliedChip } from './_components/labels'
import { useResultsModel } from './_components/useResultsModel'
import './CL-DISC-03.css'

export const states = ['loading', 'no-results', 'error', 'offline', 'searching', 'voucher-price-filter-on', 'venue-type-governmental-card', 'region-filter-on']

export default function Results() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const L = useLabels()
  const dayLabel = useDayLabel()
  const m = useResultsModel(state, true)
  const s = m.scenario
  const card = useVenueCards(s)
  const [focused, setFocused] = useState(false)
  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online
  const searching = m.searchingFrame || focused || (m.live && m.query !== '')
  const typing = m.live ? focused || m.query !== '' : m.searchingFrame

  const chips = useAppliedChips(m.filters, m.brief)
  const defaults = clearedFilters(m.brief)
  const extra = chips.filter(x => !(x.id === 'available' && defaults.available))
  const count = activeFilterCount(m.filters, m.brief) - (defaults.available && m.filters.available ? 1 : 0)
  // Region and Date live in their own quick chips (they open their editors); every other applied filter is a removable chip.
  const QUICK = ['governorates', 'dates', 'available']
  const removable = chips.filter(x => !QUICK.includes(x.id))
  const regionChip = chips.find(x => x.id === 'governorates')
  const dateChip = chips.find(x => x.id === 'dates') ?? chips.find(x => x.id === 'available')
  // Region and Date show a value only when the filter says something the Brief above does not (a range, a chosen region).
  const range = m.filters.dates
  const dateText = range ? (range.from === range.to ? dayLabel(range.from) : `${dayLabel(range.from)} – ${dayLabel(range.to)}`) : null

  // ---- actions
  const openBrief = () => m.live && nav.openSheet('CL-DISC-02')
  const openFilters = () => m.live && nav.openSheet('CL-DISC-04')
  const openSort = () => m.live && nav.openSheet(<SortSheet value={m.sort} />)
  const openMap = () => m.live && nav.push('CL-DISC-05', { from: 'results' })
  const openRegion = () => m.live && nav.openSheet('CL-DISC-04', { params: { focus: 'region' } })
  const openDate = () => m.live && nav.openSheet(<DateFilterSheet />)
  const remove = (chip: AppliedChip) => m.setFilters(chip.remove(m.filters))
  const clearAll = () => m.setFilters(clearedFilters(m.brief))
  const refresh = () =>
    new Promise<void>(done =>
      window.setTimeout(() => {
        nav.toast({ message: t('clientDiscoverResultsRefreshed'), tone: 'success' })
        done()
      }, 700),
    )

  const blurField = () => (document.activeElement instanceof HTMLElement ? document.activeElement.blur() : undefined)
  const pickGovernorate = (id: string) => {
    m.setFilters({ ...m.filters, governorateIds: [id] })
    m.setQuery('')
    blurField()
    setFocused(false)
  }
  const pickVenue = (id: string) => {
    const v = mock.getVenue(id)
    blurField()
    setFocused(false)
    if (v) nav.push(v.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: id, from: 'discover' })
  }
  const pickRecent = (text: string) => {
    m.setQuery(text)
  }

  // ---- the no-results state: one filter whose removal brings halls back, named
  const relax = useMemo(() => {
    if (m.rows.length > 0) return null
    for (const chip of chips) {
      if (chip.id === 'available') continue
      const next = chip.remove(m.filters)
      if (results(m.brief, next, { query: m.query }).length > 0) return { chip, next }
    }
    return null
  }, [m.rows.length, chips, m.filters, m.brief, m.query])
  const nearDates = useMemo(() => (m.rows.length === 0 && m.brief.date ? nearestFreeDates(m.brief) : []), [m.rows.length, m.brief])

  const facts = <BriefFacts brief={m.brief} onEdit={openBrief} />
  const showGovNote = m.filters.types.includes('governmental') || m.filters.category === 'government'

  const list = (
    <ul className="gzd-res__list" aria-label={t('clientDiscoverResultsTitle')} aria-busy={loading || undefined}>
      {loading
        ? [0, 1].map(i => (
            <li key={i}>
              <VenueCard venue={mock.venues[i]!} loading />
            </li>
          ))
        : m.rows.map(row => (
            <li key={row.venue.id} className="gzd-res__item">
              <VenueCard {...card(row, { variant: 'list' })} />
              <CardAction row={row} scenario={s} />
              {m.brief.date && row.availability === 'unavailable' && row.venue.channel !== 'external_link' ? (
                <div className="gzd-res__booked">
                  <Button variant="tertiary" iconStart="calendar" onClick={() => m.live && nav.openSheet('CL-VENU-03', { params: { venueId: row.venue.id } })}>
                    {t('clientDiscoverResultsSeeFreeDates')}
                  </Button>
                </div>
              ) : null}
            </li>
          ))}
    </ul>
  )

  const noResults = (
    <div className="gzd-res__none" data-gz-id="results.none">
      <EmptyState
        fill={false}
        illustration="no-result"
        title={c('commonStateTitleEmptySearch')}
        action={relax ? { label: t('clientDiscoverResultsNoneRelax', { filter: relax.chip.label }), onPress: () => m.setFilters(relax.next), variant: 'secondary', iconStart: relax.chip.icon ?? 'close' } : undefined}
        secondary={{ label: t('clientDiscoverResultsClearAll'), onPress: clearAll }}
      />
      {nearDates.length > 0 ? (
        <div className="gzd-res__near-chips" role="group" aria-label={t('clientDiscoverResultsNoneDates')}>
          {nearDates.map(d => (
            <Chip key={d} iconStart="calendar" onClick={() => m.live && s.setBrief({ date: d, dateMode: 'exact' })}>
              <Figures text={dayLabel(d)} />
            </Chip>
          ))}
        </div>
      ) : null}
    </div>
  )

  return (
    <Screen
      top={
        <div className="gzd-res__top" onFocusCapture={() => setFocused(true)} onBlurCapture={e => !e.currentTarget.contains(e.relatedTarget as Node | null) && setFocused(false)}>
          <TopBar
            variant="search"
            search={{ placeholder: t('clientDiscoverResultsSearchPlaceholder'), value: m.query, onChange: q => (m.live ? m.setQuery(q) : undefined) }}
            back="auto"
          />
        </div>
      }
      bottom={
        <TrayDock scenario={s} forceCollapsed={state === 'tray' ? false : undefined}>
          {!typing && !loading && !errored && m.rows.length > 0 ? (
            <button type="button" className="gz-reset gz-tray-pill gz-press gzd-res__map" onClick={openMap} data-gz-id="map.toggle">
              <Icon name="map" size="sm" />
              <span className="gz-t-button">{t('clientDiscoverResultsMap')}</span>
            </button>
          ) : null}
        </TrayDock>
      }
      bodyClassName="gzd-res"
    >
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      {typing ? (
        <Typeahead
          query={m.query}
          brief={m.brief}
          onPickGovernorate={pickGovernorate}
          onPickVenue={pickVenue}
          onPickRecent={pickRecent}
          onClearRecent={() => m.live && m.setQuery('')}
        />
      ) : (
        <PullToRefresh onRefresh={refresh}>
          <div className="gzd-res__head" data-gz-id="results.head">
            {facts}
          </div>
          <AppliedChips
            chips={removable}
            filterCount={count}
            sortLabel={L.sort(m.sort)}
            sortSet={m.sort !== 'recommended'}
            onFilters={openFilters}
            onSort={openSort}
            region={{ label: regionChip?.label ?? null, active: Boolean(regionChip), onOpen: openRegion }}
            date={{ label: dateText, active: Boolean(dateChip), onOpen: openDate }}
            onRemove={remove}
            onClearAll={extra.length > 0 || (chips.length > 0 && !defaults.available) ? clearAll : undefined}
          />
          {errored ? (
            <div className="gzd-res__state">
              <ErrorState kind="load" fill={false} onRetry={() => undefined} />
            </div>
          ) : (
            <>
              {loading || m.rows.length > 0 || offline ? (
                <p className="gzd-res__count" aria-live="polite" data-gz-id="results.count">
                  {offline ? (
                    <TextFact icon="clock" label={t('clientDiscoverA11yUpdated')} value={f.dateTime(mock.clock.now(), 'short')} size="sm" tone="muted" />
                  ) : loading ? (
                    <span className="gz-sr-only">{c('commonStateLoading')}</span>
                  ) : (
                    <FactChip icon="hall" label={t('clientDiscoverResultsTitle')} value={f.integer(m.rows.length)} />
                  )}
                  {showGovNote && m.rows.length > 0 ? (
                    <InfoButton title={c('commonVenueTypeGovernmental')}>
                      {t('clientDiscoverResultsGovernmentNote')}
                    </InfoButton>
                  ) : null}
                </p>
              ) : null}
              {!loading && m.rows.length === 0 ? noResults : list}
              <div className="gzd-res__foot" aria-hidden="true" />
            </>
          )}
        </PullToRefresh>
      )}
    </Screen>
  )
}

