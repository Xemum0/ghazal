// FilterSheet (CL-SERV-02): the one sheet behind the filter glyph in the top bar. Four rows, each led by its glyph with no heading (ADR 0034):
// sort (a three-way glyph switch, every word shown because one of them is money), the governorates the category's providers work in (the
// shared GovernorateFilter chips, multiple choice, the count beside the glyph; ADR 0038, CA-FLT-08), the "up to" prices built from the real starting prices of the list, and the minimum rating. A chosen chip is chosen again to
// clear it. The footer shows how many providers the choice will show; nothing is applied until Show, and closing discards.
import { useState, type ReactNode } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, ChipGroup, Figures, GovernorateFilter, Icon, IconSegmented, useNav } from '../../../../system'
import type { IconName } from '@gz/tokens'
import {
  MIN_RATINGS, NO_FILTERS, governorateOptions, listFor, priceSteps, useFilters, useServicesFlow,
  type Filters, type Sort,
} from './model'
import type { ServiceCategoryId } from '../../../../mock'
import './filter-sheet.css'

function Row({ icon, label, count, children }: { icon: IconName; label: string; count?: string; children: ReactNode }) {
  return (
    <div className="gzs-fsheet__row">
      <span className="gzs-fsheet__glyph">
        <Icon name={icon} size="md" tone="secondary" />
        <span className="gz-sr-only">{label}</span>
        {count ? <span className="gzs-fsheet__count gz-t-fig-caption" aria-hidden="true"><Figures text={count} /></span> : null}
      </span>
      <div className="gzs-fsheet__body">{children}</div>
    </div>
  )
}

export function FilterSheet({ categoryId }: { categoryId: ServiceCategoryId }) {
  const t = useT('client-services')
  const f = useFormat()
  const nav = useNav()
  const applied = useFilters(categoryId)
  const [draft, setDraft] = useState<Filters>(applied)
  const count = listFor(categoryId, draft).length
  const regions = governorateOptions(categoryId)
  const prices = priceSteps(categoryId)

  const reset = () => setDraft({ ...NO_FILTERS })
  const apply = () => {
    useServicesFlow.getState().setFilters(categoryId, { governorateIds: draft.governorateIds, maxFils: draft.maxFils, minRating: draft.minRating, sort: draft.sort })
    nav.closeSheet()
  }

  return (
    <div className="gzs-fsheet" data-gz="FilterSheet">
      <IconSegmented<Sort>
        label={t('clientServicesSheetSortLabel')}
        labels="all"
        value={draft.sort}
        onChange={sort => setDraft(d => ({ ...d, sort }))}
        options={[
          { value: 'recommended', icon: 'sparkle', label: t('clientServicesSortRecommended') },
          { value: 'price', icon: 'coins', label: t('clientServicesSortPrice') },
          { value: 'rating', icon: 'star', label: t('clientServicesSortRating') },
        ]}
      />

      {regions.length > 0 ? (
        <Row icon="pin" label={t('clientServicesGovernorateTitle', { count: draft.governorateIds.length })} count={draft.governorateIds.length > 0 ? f.integer(draft.governorateIds.length) : undefined}>
          <GovernorateFilter label={t('clientServicesGovernorate')} only={regions} value={draft.governorateIds} onChange={governorateIds => setDraft(d => ({ ...d, governorateIds }))} />
        </Row>
      ) : null}

      {prices.length > 0 ? (
        <Row icon="coins" label={t('clientServicesSortPrice')}>
          <ChipGroup<string>
            selection="single"
            deselectable
            label={t('clientServicesSortPrice')}
            options={prices.map(fils => ({ value: String(fils), label: <Figures text={t('clientServicesSheetUpTo', { price: f.money(fils, { mode: 'browse' }) })} /> }))}
            value={draft.maxFils === null ? null : String(draft.maxFils)}
            onChange={v => setDraft(d => ({ ...d, maxFils: v === null ? null : Number(v) }))}
          />
        </Row>
      ) : null}

      <Row icon="star" label={t('clientServicesSortRating')}>
        <ChipGroup<string>
          selection="single"
          deselectable
          label={t('clientServicesSortRating')}
          options={MIN_RATINGS.map(r => ({ value: String(r), label: <Figures text={t('clientServicesSheetRatingAtLeast', { rating: f.number(r, { minFraction: 1, maxFraction: 1 }) })} /> }))}
          value={draft.minRating === null ? null : String(draft.minRating)}
          onChange={v => setDraft(d => ({ ...d, minRating: v === null ? null : Number(v) }))}
        />
      </Row>

      <div className="gzs-fsheet__foot">
        <Button variant="secondary" onClick={reset}>
          {t('clientServicesListClear')}
        </Button>
        <Button variant="primary" disabled={count === 0} onClick={apply}>
          {t('clientServicesSheetShow', { count: f.integer(count) })}
        </Button>
      </div>
    </div>
  )
}
