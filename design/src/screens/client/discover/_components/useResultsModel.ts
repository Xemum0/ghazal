// useResultsModel: what Results (and the map beside it) draw, one shape for the live player and for the static frames.
// Live: filters, sort and query come from the Discover store, seeded by whoever pushed the screen (a Home shelf, a category tile, the CTA)
// or, when nobody seeded it, by the Brief itself (the availability filter is on when the Brief has a date). Static: a frame is a picture,
// so the filters, query and Brief are derived deterministically from its `state`.
import { useLayoutEffect, useMemo } from 'react'
import { useNav } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { useDevice } from '../../../../shell/device/context'
import { NO_FILTERS, defaultFilters, results, type Filters, type SearchBrief } from './data'
import type { SortKey } from './labels'
import { useScenario, type Scenario } from './scenario'
import { useDiscover } from './state'

export type ResultsModel = {
  scenario: Scenario
  brief: SearchBrief
  live: boolean
  filters: Filters
  sort: SortKey
  query: string
  setFilters: (next: Filters) => void
  setSort: (s: SortKey) => void
  setQuery: (q: string) => void
  rows: ReturnType<typeof results>
  /** True when the frame asks to be drawn with the typeahead open. */
  searchingFrame: boolean
}

/** `owner`: Results seeds the store from the params it was opened with; the Map shares the store and must not reseed it. */
export function useResultsModel(state?: string, owner = false): ResultsModel {
  const nav = useNav()
  const scenario = useScenario(state)
  const live = scenario.live
  const { lang } = useLang()
  useDevice()
  const store = useDiscover()
  const brief = scenario.brief

  // Live: Results is opened with the filters its source decided (a category tile, a shelf's See all, the Home CTA); with none (a push from
  // Saved or Compare) the Brief decides the defaults. Applying is idempotent, so a development double-mount cannot undo it.
  const opened = nav.params.filters as Filters | undefined
  useLayoutEffect(() => {
    if (!live || !owner) return
    useDiscover.getState().seed('opened', opened ?? defaultFilters(brief))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live, owner])

  const frame = useMemo(() => {
    const base = defaultFilters(brief)
    switch (state) {
      case 'voucher-price-filter-on':
        return { filters: { ...base, areaIds: [], voucherOnly: true } as Filters, query: '', sort: 'voucher_price' as SortKey }
      case 'no-results':
        // Nothing hosts 1,300 to 1,500 guests; removing the capacity chip brings the halls back, and the empty state names it.
        return { filters: { ...base, capacity: [1300, 1500] } as Filters, query: '', sort: 'recommended' as SortKey }
      case 'venue-type-governmental-card':
        return { filters: { ...NO_FILTERS, types: ['governmental'], areaIds: [] } as Filters, query: '', sort: 'recommended' as SortKey }
      case 'region-filter-on':
        return { filters: { ...base, governorateIds: ['hawalli'], areaIds: null } as Filters, query: '', sort: 'recommended' as SortKey }
      case 'searching':
        return { filters: base, query: lang === 'ar' ? 'مشرف' : 'Mish', sort: 'recommended' as SortKey }
      default:
        return { filters: base, query: '', sort: 'recommended' as SortKey }
    }
  }, [state, brief, lang])

  const filters = live ? store.filters : frame.filters
  const query = live ? store.query : frame.query
  const sort: SortKey = live ? store.sort : frame.sort
  const rows = useMemo(
    () => results(brief, filters, { query, sort }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [brief, filters, query, sort],
  )

  return {
    scenario,
    brief,
    live,
    filters,
    sort,
    query,
    setFilters: next => live && store.replaceFilters(next),
    setSort: s => live && store.setSort(s),
    setQuery: q => live && store.setQuery(q),
    rows,
    searchingFrame: state === 'searching',
  }
}
