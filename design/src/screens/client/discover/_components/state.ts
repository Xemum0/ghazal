// Flow-local state of Discover: what Results, the Filters sheet and the map share and the prototype store does not carry (filters, sort,
// view, query). The Brief, the favourites, the compare list and the account stay in the prototype store (ADR 0007). A Results screen
// seeds this store from the params it was opened with (a category tile, a shelf's "See all"), so a stale choice never leaks in.
import { create } from 'zustand'
import type { SortKey } from './labels'
import { NO_FILTERS, type Filters } from './data'

type DiscoverState = {
  filters: Filters
  sort: SortKey
  query: string
  /** Which params the current filters were seeded from (a navigation key), so a remount does not reseed. */
  seededFrom: string | null
  setFilters: (patch: Partial<Filters>) => void
  replaceFilters: (next: Filters) => void
  setSort: (sort: SortKey) => void
  setQuery: (q: string) => void
  seed: (key: string, filters: Filters, sort?: SortKey) => void
}

export const useDiscover = create<DiscoverState>()(set => ({
  filters: NO_FILTERS,
  sort: 'recommended',
  query: '',
  seededFrom: null,
  setFilters: patch => set(s => ({ filters: { ...s.filters, ...patch } })),
  replaceFilters: filters => set({ filters }),
  setSort: sort => set({ sort }),
  setQuery: query => set({ query }),
  seed: (seededFrom, filters, sort = 'recommended') => set({ seededFrom, filters, sort, query: '' }),
}))
