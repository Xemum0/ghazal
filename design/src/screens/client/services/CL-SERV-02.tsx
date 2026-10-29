// CL-SERV-02 Providers in one category (voucher model, ADR 0033; text diet, ADR 0034). Covers CA-SVC-09, CA-SVC-02 to CA-SVC-08 (every category
// group opens here, siblings one glyph away), CA-SVC-13, CA-SVC-16, CA-SVC-17, CA-VCH-02, CA-FLT-08, CA-SVC-19, CA-TOOL-02.
// The category as the large title, its sibling categories as a glyph switch (the five primaries together, or the group of a secondary one;
// the title names the chosen one), the filter glyph in the top bar with the count of filters on (sort, governorate, price and rating share one
// sheet), then the providers as an unframed two-up grid in the venue card's language: 4:5 photograph of the work, name, facts as glyph and
// figure, the voucher price with the standard price struck beside it (a ticket), a heart that saves to
// Saved > Services. Only approved, active listings appear; a paid placement says "Sponsored" and nothing else is labelled.
// A filter that matches nothing offers Clear filters; a category with no providers points to a sibling. Pull to refresh.
// No signed-out variant (ADR 0038). States: default, loading, empty, no-results, error, offline.
import { useState } from 'react'
import { vendorsFor, type ServiceCategoryId } from '../../../mock'
import { useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Banner, EmptyState, ErrorState, IconSegmented, PullToRefresh, Screen, TopBar, useBi, useNav } from '../../../system'
import { VendorTile } from './_components/VendorTile'
import { FilterSheet } from './_components/FilterSheet'
import {
  DEFAULT_CATEGORY, ICON_OF, NO_FILTERS, appliedCount, categoryOf, governorateOptions, listFor, siblingsOf, useFilters, useLive, useServicesFlow, type Filters,
} from './_components/model'
import './CL-SERV-02.css'

export const states = ['loading', 'empty', 'no-results', 'error', 'offline']

type Params = { categoryId?: ServiceCategoryId }

export default function CategoryList() {
  const t = useT('client-services')
  const c = useT('common')
  const bi = useBi()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const live = useLive()

  // The category in view: from the link, or the sibling chosen here (no history entry per switch).
  const [catId, setCatId] = useState<ServiceCategoryId>(state === 'empty' ? 'live_music' : (nav.params.categoryId ?? DEFAULT_CATEGORY))
  const category = categoryOf(catId)
  const stored = useFilters(catId)
  // The no-results frame shows a filter that cannot match; live, the filters are the viewer's own.
  const filters: Filters =
    state === 'no-results' ? { ...NO_FILTERS, governorateIds: [governorateOptions(catId)[0] ?? ''], maxFils: 1 } : stored
  const favourites = usePrototype(s => s.favourites.vendor)

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'
  const noVendors = state === 'empty'
  const all = noVendors ? [] : vendorsFor(catId)
  const list = noVendors ? [] : listFor(catId, filters)
  const filtered = !noVendors && all.length > 0 && list.length === 0
  const siblings = siblingsOf(catId)
  const other = siblings.find(s => s.id !== catId)

  const openFilters = () => nav.openSheet(<FilterSheet categoryId={catId} />, { title: t('clientServicesFilterTitle') })

  const toggleFavourite = (vendorId: string) => {
    const saved = usePrototype.getState().toggleFavourite('vendor', vendorId)
    if (saved) nav.toast({ message: c('commonStateSaved'), icon: 'heart-fill', action: { label: t('clientServicesSavedView'), onPress: () => nav.switchTab('saved') } })
  }

  const title = category ? bi(category.name) : t('clientServicesListTitle')
  const rows: (typeof list)[] = []
  for (let i = 0; i < list.length; i += 2) rows.push(list.slice(i, i + 2))

  const body = (
    <>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzs-list">
        {siblings.length > 1 ? (
          <div className="gzs-list__switch" data-gz-id="siblings">
            <IconSegmented<ServiceCategoryId>
              label={t('clientServicesListSiblings')}
              labels="none"
              value={catId}
              onChange={setCatId}
              options={siblings.map(s => ({ value: s.id, icon: ICON_OF[s.id], label: bi(s.name) }))}
            />
          </div>
        ) : null}

        {errored ? (
          <div className="gzs-list__pad">
            <ErrorState kind="load" fill={false} onRetry={() => nav.toast({ message: c('commonStateOffline'), tone: 'danger' })} />
          </div>
        ) : noVendors ? (
          <div className="gzs-list__pad">
            <EmptyState
              fill={false}
              illustration="empty-results"
              title={t('clientServicesListEmptyTitle')}
              action={other ? { label: bi(other.name), variant: 'secondary', iconStart: ICON_OF[other.id], onPress: () => setCatId(other.id) } : undefined}
            />
          </div>
        ) : filtered ? (
          <div className="gzs-list__pad">
            <EmptyState
              fill={false}
              illustration="no-result"
              title={t('clientServicesListNoResultsTitle')}
              action={{ label: t('clientServicesListClear'), variant: 'secondary', onPress: () => useServicesFlow.getState().clearFilters(catId) }}
            />
          </div>
        ) : (
          <section className="gzs-list__grid" aria-label={t('clientServicesListGridLabel', { category: title })} aria-busy={loading || undefined} data-gz-id="vendors">
            {loading
              ? [0, 1].map(i => (
                  <div key={i} className="gzs-list__row">
                    <VendorTile vendor={all[0] ?? vendorsFor(DEFAULT_CATEGORY)[0]!} loading />
                    <VendorTile vendor={all[0] ?? vendorsFor(DEFAULT_CATEGORY)[0]!} loading />
                  </div>
                ))
              : rows.map(row => (
                  <div key={row[0]?.id} className="gzs-list__row">
                    {row.map(v => (
                      <VendorTile
                        key={v.id}
                        vendor={v}
                        favourite={favourites.includes(v.id)}
                        onFavouriteChange={() => toggleFavourite(v.id)}
                        onOpen={() => nav.push('CL-SERV-03', { vendorId: v.id, categoryId: catId })}
                      />
                    ))}
                    {row.length === 1 ? <span className="gzs-list__spacer" aria-hidden="true" /> : null}
                  </div>
                ))}
          </section>
        )}
      </div>
    </>
  )

  return (
    <Screen
      top={
        <TopBar
          variant="large-title"
          title={title}
          actions={[{ icon: 'filter', label: t('clientServicesFilterLabel'), onPress: openFilters, count: appliedCount(filters) }]}
        />
      }
    >
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
