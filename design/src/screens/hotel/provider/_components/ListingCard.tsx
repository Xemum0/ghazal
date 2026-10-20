// ListingCard (HL-PROV-02): the provider listing row, local to the flow. It reuses the system card's look (gz-plc classes) but owns the plan
// line: a fee-exempt major hotel has no plan to choose, so its line is only "Fee-exempt" and never "No plan chosen yet".
import type { Listing, ListingRejectionCode } from '../../../../mock'
import { Badge, Icon, ListingStatusPill, Photo, imageSrc } from '../../../../system'
import { Figures, useBi, useFormat, useP } from './bits'
import { categoryName } from './model'
import './listing-card.css'

const REASON = {
  content_not_compliant: 'hotelProviderRejectContent',
  wrong_category: 'hotelProviderRejectCategory',
  missing_details: 'hotelProviderRejectDetails',
  unclear_pricing: 'hotelProviderRejectPricing',
  other: 'hotelProviderRejectOther',
} as const satisfies Record<ListingRejectionCode, string>

export function ListingCard({ listing: l, exempt, onOpen }: { listing: Listing; exempt: boolean; onOpen: () => void }) {
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useP()
  const cat = categoryName(l.categoryId)
  const planName = l.planCycle ? c(l.planCycle === 'weekly' ? 'commonPlanWeekly' : l.planCycle === 'monthly' ? 'commonPlanMonthly' : 'commonPlanAnnual') : null

  let plan = ''
  if (!exempt) {
    const parts = [planName, l.endsOn ? f.date(l.endsOn, 'short') : null].filter(Boolean)
    if (l.billing.status === 'rates_pending') parts.push(c('commonRatesSoon'))
    plan = parts.join(' · ')
  }
  const code = l.status === 'rejected' ? l.rejection?.codes[0] : undefined

  return (
    <article data-gz="ProviderListingCard" data-status={l.status} className="gz-plc hp-card">
      <button type="button" className="gz-reset gz-plc__row gz-press hp-card__row" onClick={onOpen}>
        <span className="gz-plc__thumb" aria-hidden={l.cover ? undefined : true}>
          {l.cover ? <Photo src={imageSrc(l.cover.file)} alt={bi(l.cover.alt)} className="gz-plc__photo" sizes="72px" /> : <Icon name="megaphone" size="md" tone="secondary" />}
        </span>
        <span className="gz-plc__text hp-card__text">
          <span className="gz-plc__top">
            <ListingStatusPill status={l.status} />
            {l.sponsored && l.status === 'active' ? <Badge variant="quiet">{c('commonLabelSponsored')}</Badge> : null}
          </span>
          <span className="gz-plc__title gz-t-title" dir="auto">{bi(l.title)}</span>
          {cat ? <span className="gz-plc__cat gz-t-caption">{bi(cat)}</span> : null}
          {plan ? <span className="gz-plc__plan gz-t-caption"><Figures text={plan} /></span> : null}
          {code ? (
            <span className="gz-plc__reason gz-t-caption">
              <Icon name="info" size="xs" tone="danger" />
              {t(REASON[code])}
            </span>
          ) : null}
        </span>
        <Icon name="chevron-right" size="sm" tone="secondary" className="gz-plc__go" />
      </button>
    </article>
  )
}
