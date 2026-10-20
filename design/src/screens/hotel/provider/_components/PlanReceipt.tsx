// PlanReceipt: the plan invoice of a listing plan (the only Ghazal document a partner receives): issuer, number as an LTR isolate, the plan line,
// the period, how it was paid and the total. Documents say KWD (the legal label), Western digits, three decimals (ADR 0010 D7). The prototype's
// amounts come from the sample fixture only and the document says so.
import type { ReactNode } from 'react'
import { Figures, Icon } from '../../../../system'
import type { AdPlanCycle } from '../../../../mock'
import { Code, UserText, dayWithYear, useFormat, useP } from './bits'
import './plan-receipt.css'

export type PlanReceiptProps = {
  number: string
  listingTitle: string
  cycle: AdPlanCycle
  fils: number
  paidAt: string
  methodLabel: string
  sample: boolean
}

const PLAN = { weekly: 'commonPlanWeekly', monthly: 'commonPlanMonthly', annual: 'commonPlanAnnual' } as const

export function PlanReceipt({ number, listingTitle, cycle, fils, paidAt, methodLabel, sample }: PlanReceiptProps) {
  const f = useFormat()
  const { t, c } = useP()
  const rows: [string, ReactNode][] = [
    [t('hotelProviderReceiptNumber'), <Code key="n">{number}</Code>],
    [t('hotelProviderReceiptDate'), <Figures key="d" text={`${dayWithYear(f, paidAt.slice(0, 10))} · ${f.time(paidAt)}`} />],
    [t('hotelProviderReceiptListing'), <UserText key="l" role="body">{listingTitle}</UserText>],
    [t('hotelProviderReceiptPlan'), c(PLAN[cycle])],
    [t('hotelProviderReceiptVia'), methodLabel],
  ]
  return (
    <article className="hp-rec" data-gz="PlanReceipt" aria-label={t('hotelProviderReceiptTitle')}>
      <header className="hp-rec__head">
        <Icon name="receipt" size="md" />
        <span className="gz-t-title">{t('hotelProviderReceiptIssuer')}</span>
      </header>
      <dl className="hp-rec__rows">
        {rows.map(([k, v]) => (
          <div key={k} className="hp-rec__row">
            <dt className="gz-t-caption">{k}</dt>
            <dd className="gz-t-body">{v}</dd>
          </div>
        ))}
      </dl>
      <div className="hp-rec__total">
        <span className="gz-t-title">{c('commonMoneyTotal')}</span>
        <span className="gz-t-price-total hp-rec__amount">
          <Figures text={f.money(fils, { mode: 'exact', label: 'legal' })} />
        </span>
      </div>
      <p className="hp-rec__foot gz-t-caption">{t(sample ? 'hotelProviderReceiptSample' : 'hotelProviderReceiptFoot')}</p>
    </article>
  )
}
