// ProviderListingCard (HL-PROV list, home of a service provider): one advertisement of the provider as the Partner app shows it. A cover
// thumbnail (compact 72 x 88), the title (as typed, in its own script), the category, the lifecycle pill, then the plan line (cycle and
// end date, or the honest "Rates announced soon" / "Exempt") and, when the moderator said no, the first reason in plain words.
// It never shows a number the Super Admin has not set. The whole card is one target.
import type { Listing, ListingRejectionCode } from '@gz/contracts'
import { serviceCategories } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { Badge, Icon } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import { Photo, imageSrc } from '../overlays'
import { ListingStatusPill } from './ListingStatusPill'
import './provider-listing-card.css'

const useW = defineWords({
  endsOn: p('Ends {date}', 'تنتهي {date}'),
  startsAfter: p('Starts when approved', 'تبدأ عند الموافقة'),
  noPlan: p('No plan chosen yet', 'لم تُختر باقة بعد'),
  review: p('With the review team', 'لدى فريق المراجعة'),
  ...REJECT_WORDS(),
})

function REJECT_WORDS() {
  return {
    content_not_compliant: p('Content does not meet our guidelines', 'المحتوى لا يتوافق مع إرشادات النشر'),
    wrong_category: p('Wrong category', 'الفئة غير مناسبة'),
    missing_details: p('Details are missing', 'بعض البيانات ناقصة'),
    unclear_pricing: p('Pricing is unclear', 'الأسعار غير واضحة'),
    other: p('See the moderator note', 'راجعوا ملاحظة المراجع'),
  } satisfies Record<ListingRejectionCode, ReturnType<typeof p>>
}

export type ProviderListingCardProps = {
  listing: Listing
  /** The partner is a major hotel: the plan line reads "Exempt". */
  exempt?: boolean
  onOpen?: () => void
  className?: string
}

export function ProviderListingCard({ listing: l, exempt = false, onOpen, className }: ProviderListingCardProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const category = serviceCategories.find(c => c.id === l.categoryId)
  const planName = l.planCycle ? t(l.planCycle === 'weekly' ? 'commonPlanWeekly' : l.planCycle === 'monthly' ? 'commonPlanMonthly' : 'commonPlanAnnual') : null
  const billing = exempt ? t('commonExempt') : l.billing.status === 'rates_pending' ? t('commonRatesSoon') : null
  const planLine = [
    planName,
    l.endsOn ? w('endsOn', { date: f.date(l.endsOn, 'short') }) : l.planCycle ? w('startsAfter') : null,
  ].filter(Boolean)
  const reason = l.status === 'rejected' && l.rejection?.codes[0] ? w(l.rejection.codes[0]) : null

  const body = (
    <>
      <span className="gz-plc__thumb" aria-hidden={l.cover ? undefined : true}>
        {l.cover ? <Photo src={imageSrc(l.cover.file)} alt={bi(l.cover.alt)} className="gz-plc__photo" sizes="72px" /> : <Icon name="megaphone" size="md" tone="secondary" />}
      </span>
      <span className="gz-plc__text">
        <span className="gz-plc__top">
          <ListingStatusPill status={l.status} />
          {l.sponsored && l.status === 'active' ? <Badge variant="quiet">{t('commonLabelSponsored')}</Badge> : null}
        </span>
        <span className="gz-plc__title gz-t-title" dir="auto">
          {bi(l.title)}
        </span>
        {category ? <span className="gz-plc__cat gz-t-caption">{bi(category.name)}</span> : null}
        <span className="gz-plc__plan gz-t-caption">
          <Figures text={planLine.length ? planLine.join(' · ') : w('noPlan')} />
          {billing ? (
            <>
              <span aria-hidden="true"> · </span>
              <span className="gz-plc__billing">{billing}</span>
            </>
          ) : null}
        </span>
        {reason ? (
          <span className="gz-plc__reason gz-t-caption">
            <Icon name="info" size="xs" tone="danger" />
            {reason}
          </span>
        ) : l.status === 'pending_review' ? (
          <span className="gz-plc__reason gz-plc__reason--wait gz-t-caption">
            <Icon name="clock" size="xs" tone="secondary" />
            {w('review')}
          </span>
        ) : null}
      </span>
      {onOpen ? <Icon name="chevron-right" size="sm" tone="secondary" className="gz-plc__go" /> : null}
    </>
  )
  return (
    <article data-gz="ProviderListingCard" data-status={l.status} className={cx('gz-plc', className)}>
      {onOpen ? (
        <button type="button" className="gz-reset gz-plc__row gz-press" onClick={onOpen}>
          {body}
        </button>
      ) : (
        <div className="gz-plc__row">{body}</div>
      )}
    </article>
  )
}
