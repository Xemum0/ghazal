// AdPlanCard (HL-PROV plan step, ADR 0033 D8, voucher-model section 9): one advertising plan, weekly, monthly or annual. The rates are NOT
// decided, so a plan without a rate says "Rates announced soon" and never a number; a rate shows only after the Super Admin sets it. For a
// major hotel the card says "Exempt" and nothing is payable. A plan is chosen, not bought: the listing still waits for review.
//   states   default . selected (ink border + bead) . rates announced soon . rate set . exempt (major hotel) . disabled
import type { AdPlan } from '@gz/contracts'
import { useT } from '../../i18n'
import { Icon, Price } from '../core'
import { cx } from '../core/cx'
import { Figures } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import './ad-plan-card.css'

const useW = defineWords({
  exemptBody: p('No fee for major hotels', 'بلا رسوم للفنادق الكبيرة'),
  soonBody: p('You can choose a plan now. Payment opens when rates are announced.', 'يمكنكم اختيار الباقة الآن، ويُفتح الدفع عند الإعلان عن الأسعار.'),
  perPeriod: p('per {period}', 'لكل {period}'),
  week: p('week', 'أسبوع'),
  month: p('month', 'شهر'),
  year: p('year', 'سنة'),
  starts: p('Runs from the day it is approved', 'تبدأ من يوم الموافقة'),
  choose: p('Choose {name}', 'اختيار الباقة {name}'),
})

const NAME = { weekly: 'commonPlanWeekly', monthly: 'commonPlanMonthly', annual: 'commonPlanAnnual' } as const
const PERIOD = { weekly: 'week', monthly: 'month', annual: 'year' } as const

export type AdPlanCardProps = {
  plan: Pick<AdPlan, 'cycle' | 'periodDays' | 'ratesFils'>
  selected?: boolean
  /** Major hotel: exempt, no rate, nothing to pay. */
  exempt?: boolean
  disabled?: boolean
  onSelect?: () => void
  className?: string
}

export function AdPlanCard({ plan, selected = false, exempt = false, disabled = false, onSelect, className }: AdPlanCardProps) {
  const t = useT('common')
  const w = useW()
  const name = t(NAME[plan.cycle])
  const state = exempt ? 'exempt' : plan.ratesFils === null ? 'soon' : 'rate'
  const body = (
    <>
      <span className="gz-plan__head">
        <span className="gz-plan__radio" aria-hidden="true">
          {selected ? <span className="gz-bead" /> : null}
        </span>
        <span className="gz-plan__name gz-t-title">{name}</span>
        <span className="gz-plan__period gz-t-caption">
          <Figures text={t('commonCountDays', { count: plan.periodDays })} />
        </span>
      </span>
      <span className="gz-plan__price" data-gz-id="price">
        {state === 'exempt' ? (
          <>
            <span className="gz-plan__exempt gz-t-pill">
              <Icon name="check" size="xs" tone="success" />
              {t('commonExempt')}
            </span>
            <span className="gz-plan__note gz-t-caption">{w('exemptBody')}</span>
          </>
        ) : state === 'soon' ? (
          <>
            <span className="gz-plan__soon gz-t-body-s">
              <Icon name="clock" size="xs" tone="secondary" />
              {t('commonRatesSoon')}
            </span>
          </>
        ) : (
          <>
            <Price fils={plan.ratesFils as number} mode="browse" size="total" />
            <span className="gz-plan__note gz-t-caption">{w('perPeriod', { period: w(PERIOD[plan.cycle]) })}</span>
          </>
        )}
      </span>
      <span className="gz-plan__starts gz-t-caption">{w('starts')}</span>
    </>
  )
  const label = w('choose', { name })
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={label}
      data-gz="AdPlanCard"
      data-state={state}
      data-cycle={plan.cycle}
      disabled={disabled}
      onClick={onSelect}
      className={cx('gz-reset gz-plan gz-press', selected && 'is-selected', disabled && 'is-disabled', className)}
    >
      {body}
    </button>
  )
}
