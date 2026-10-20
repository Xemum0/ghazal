// HL-PROV-04 Choose a plan: Weekly, Monthly or Annual, with what every plan includes. The rates are an owner decision (OQ-V-07): while they are
// not set every card says "Rates announced soon" and "Continue to payment" is disabled with that reason; no number appears. A major hotel sees an
// explanation instead of plans and goes straight to review. Choosing or paying never publishes a listing: a person at Ghazal approves it.
// Requirements: PA-ADS-01, PA-ADS-03, PA-ADS-04, PA-ADS-05, PA-ADS-06
// States: rates-set-sample, fee-exempt-major-hotel, renewal, loading, error, offline (the default frame is the plans with rates not announced)
import { useState } from 'react'
import { planRates } from '../../../mock'
import type { AdPlanCycle } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, Button, ErrorState, Icon, Illustration, MajorHotelBadge, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { PlanRows } from './_components/PlanRows'
import { Note, OfflineStrip, UserText, useBi, useFormat, useP } from './_components/bits'
import { CYCLES, PROVIDER_ID, SAMPLE_RATES_FILS, accountOf, categoryName, isAccountKind, pickListing } from './_components/model'
import { chooseAndSubmit, useProv } from './_components/store'
import './HL-PROV-04.css'

const PERIOD = { weekly: 7, monthly: 30, annual: 365 } as const

export const states = ['rates-set-sample', 'fee-exempt-major-hotel', 'renewal', 'loading', 'error', 'offline']

export default function AdPlan() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t } = useP()
  const viewer = useProv(s => s.viewer)
  const listings = usePrototype(s => s.listings)

  const kind = state === 'fee-exempt-major-hotel' ? 'major' : isAccountKind(nav.params.account) ? nav.params.account : viewer
  const account = accountOf(kind)
  const exempt = account.exempt
  const renewalFrame = state === 'renewal'
  const mine = listings.filter(l => l.providerId === PROVIDER_ID)
  const listing = renewalFrame
    ? mine.find(l => l.id === 'lst-flowers-zahra-autumn')
    : pickListing(mine, nav.params.listingId, ['payment_pending', 'draft', 'rejected', 'expired'])
  const renewal = renewalFrame || nav.params.renewal === true
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  const fixture = planRates()
  const [sample, setSample] = useState(state === 'rates-set-sample' || nav.params.sample === true)
  const rates = (c: AdPlanCycle): number | null => (sample ? SAMPLE_RATES_FILS[c] : (fixture.plans.find(p => p.plan.cycle === c && p.rate !== 'announced_soon')?.plan.ratesFils ?? null))
  const payable = CYCLES.every(c => rates(c) !== null)
  const [chosen, setChosen] = useState<AdPlanCycle | null>(renewalFrame ? 'monthly' : state === 'rates-set-sample' ? 'monthly' : (listing?.planCycle ?? 'monthly'))

  const title = renewal ? t('hotelProviderPlanTitleRenew') : t('hotelProviderPlanTitle')
  const catName = listing ? categoryName(listing.categoryId) : undefined
  const endsOn = listing?.endsOn ?? null

  const pay = () => {
    if (!listing || !chosen) return
    nav.push('HL-PROV-05', { listingId: listing.id, cycle: chosen, sample: sample, renewal, account: kind })
  }
  const submitNow = () => {
    if (!listing) return
    chooseAndSubmit(listing.id, exempt ? null : chosen, exempt)
    nav.toast({ message: t('hotelProviderPlanSubmittedToast'), tone: 'success' })
    nav.replace('HL-PROV-06', { listingId: listing.id, account: kind })
  }

  const top = (
    <>
      <TopBar title={title} />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  let bottom
  if (!loading && !error) {
    if (exempt) {
      bottom = <ActionBar action={{ label: t('hotelProviderStepSubmit'), iconEnd: 'check', disabled: offline || !listing, reason: offline ? t('hotelProviderNeedsConnection') : undefined, onPress: submitNow }} />
    } else {
      const reason = offline ? t('hotelProviderNeedsConnection') : !chosen ? t('hotelProviderPlanReasonChoose') : undefined
      bottom = payable ? (
        <ActionBar
          action={{ label: t('hotelProviderPlanContinue'), iconEnd: 'chevron-right', disabled: Boolean(reason), reason, onPress: pay }}
          note={sample ? t('hotelProviderPlanSampleCta') : undefined}
        />
      ) : (
        <ActionBar
          action={{ label: t('hotelProviderStepSubmit'), iconEnd: 'check', disabled: Boolean(reason) || !listing, reason, onPress: submitNow }}
          note={t('hotelProviderPlanReasonRates')}
        />
      )
    }
  }

  let body
  if (loading) {
    body = (
      <div className="hp04" aria-busy="true">
        <Skeleton variant="block" blockSize={72} />
        <Skeleton variant="block" blockSize={128} />
        <Skeleton variant="block" blockSize={128} />
        <Skeleton variant="block" blockSize={128} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelProviderPlanErrorTitle')} body={t('hotelProviderPlanErrorBody')} onRetry={() => nav.replace('HL-PROV-04', nav.params)} />
  } else if (exempt) {
    body = (
      <div className="hp04">
        <MajorHotelBadge />
        <div className="hp04__art">
          <Illustration name="seal" size="lg" />
        </div>
        {listing ? <ForListing title={bi(listing.title)} category={catName ? bi(catName) : ''} onEdit={() => nav.push('HL-PROV-03', { listingId: listing.id, account: kind })} /> : null}
      </div>
    )
  } else {
    body = (
      <div className="hp04">
        {listing ? <ForListing title={bi(listing.title)} category={catName ? bi(catName) : ''} onEdit={() => nav.push('HL-PROV-03', { listingId: listing.id, account: kind })} /> : null}
        {renewal && endsOn ? <Note icon="calendar">{t(listing?.status === 'expired' ? 'hotelProviderPlanRenewExpired' : 'hotelProviderPlanRenewLive', { date: f.date(endsOn, 'short') })}</Note> : null}
        {sample ? <Note tone="quiet" icon="warning-circle">{t('hotelProviderPlanSampleNote')}</Note> : null}
        <PlanRows cycles={CYCLES} periodDays={PERIOD} rate={rates} chosen={chosen} onChoose={setChosen} label={t('hotelProviderPlanGroup')} />
        <section className="hp04__incl" aria-label={t('hotelProviderPlanInclTitle')}>
          <ul className="hp04__points">
            {([['hotelProviderPlanIncl1', 'megaphone'], ['hotelProviderPlanIncl2', 'ticket'], ['hotelProviderPlanIncl3', 'chart-bar']] as const).map(([k, ic]) => (
              <li key={k} className="hp04__point gz-t-body">
                <Icon name={ic} size="sm" tone="accent" />
                <span>{t(k)}</span>
              </li>
            ))}
          </ul>
        </section>
        {!sample ? (
          <div className="hp04__proto">
            <Button variant="tertiary" iconStart="eye" onClick={() => setSample(true)}>
              {t('hotelProviderPlanPreviewSample')}
            </Button>
          </div>
        ) : null}
      </div>
    )
  }

  return <Screen top={top} bottom={bottom}>{body}</Screen>
}

function ForListing({ title, category, onEdit }: { title: string; category: string; onEdit: () => void }) {
  const { t } = useP()
  return (
    <div className="hp04__for" data-gz="PlanFor">
      <span className="hp04__for-text">
        <UserText role="title" className="hp04__for-title">{title}</UserText>
        {category ? <span className="hp04__for-cat gz-t-caption">{category}</span> : null}
      </span>
      <Button variant="tertiary" onClick={onEdit}>
        {t('hotelProviderPlanEditListing')}
      </Button>
    </div>
  )
}
