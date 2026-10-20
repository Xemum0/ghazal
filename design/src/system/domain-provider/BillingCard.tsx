// BillingCard (HL-SETT-04, HL-PROV-04; ADR 0035 D7): how a partner pays Ghazal. Two variants and never a price in the prototype.
//   plan      service providers: the chosen cycle (weekly, monthly, annual) and "Rates announced soon" until the Super Admin sets rates
//   contract  hotels and halls: a Business contract card, the one-line summary "terms as contracted", no plan picker, no number
// A major hotel adds the MajorHotelBadge. The card is a fact, not a button: the screen owns any action.
import type { AdPlanCycle, PartnerBilling } from '@gz/contracts'
import { useT } from '../../i18n'
import { Icon } from '../core'
import { cx } from '../core/cx'
import { useBi } from '../domain-client/bits'
import { MajorHotelBadge } from './MajorHotelBadge'
import './billing-card.css'

const CYCLE = { weekly: 'commonPlanWeekly', monthly: 'commonPlanMonthly', annual: 'commonPlanAnnual' } as const satisfies Record<AdPlanCycle, string>

export type BillingCardProps = {
  billing: Pick<PartnerBilling, 'mode' | 'contractSummary' | 'plan'>
  /** Major hotel: adds the exempt marker. */
  majorHotel?: boolean
  className?: string
}

export function BillingCard({ billing, majorHotel = false, className }: BillingCardProps) {
  const t = useT('common')
  const bi = useBi()
  const contract = billing.mode === 'contract'
  const cycle = billing.plan?.cycle ?? null
  return (
    <section data-gz="BillingCard" data-mode={billing.mode} className={cx('gz-bill', className)} aria-label={contract ? t('commonBillingContract') : t('commonBillingPlan')}>
      <header className="gz-bill__head">
        <span className="gz-bill__icon" aria-hidden="true">
          <Icon name={contract ? 'notes' : 'megaphone'} size="md" />
        </span>
        <span className="gz-bill__title gz-t-title">{contract ? t('commonBillingContract') : cycle ? t(CYCLE[cycle]) : t('commonBillingPlan')}</span>
        {majorHotel ? <MajorHotelBadge /> : null}
      </header>
      {contract ? (
        <p className="gz-bill__line gz-t-body-s" data-gz-id="contract">
          {billing.contractSummary ? bi(billing.contractSummary) : t('commonBillingContractTerms')}
        </p>
      ) : (
        <p className="gz-bill__line gz-t-body-s" data-gz-id="rates">
          <Icon name="clock" size="xs" tone="secondary" />
          {billing.plan?.ratesFils === null || !billing.plan ? t('commonRatesSoon') : null}
        </p>
      )}
    </section>
  )
}
