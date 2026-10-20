// The pieces of the booking rules screen (HL-VENU-06): the fixed booking mode panel and the "What couples see" timeline, computed for the
// story booking (Thu 14 Jan 2027) from the rules being edited. Money is integer fils; dates are absolute; the confirm window is the owner's
// fixed 24 hours, read from the platform configuration.
import type { ReactNode } from 'react'
import { Icon } from '../../../../system'
import { Figures, useV } from './bits'
import { platform, sample } from './venue'
import type { RulesModel } from './store'
import './rules.css'

/** Booking mode is always "Request to book" (ADR 0033): shown as a fact with its one-line explanation, never as a switch. */
export function ModeCard() {
  const { t, c } = useV()
  return (
    <div className="hv-mode" data-gz="ModeCard">
      <span className="hv-mode__head">
        <Icon name="lock" size="sm" tone="secondary" />
        <span className="gz-t-title">{t('hotelVenueModeRequest')}</span>
      </span>
    </div>
  )
}

type Row = { key: string; title: string; text: ReactNode }

/** Request, reply, confirm, pay the venue directly: the four steps a couple lives through, with this venue's reply window. */
export function CouplesTimeline({ rules }: { rules: RulesModel }) {
  const { t, c, f } = useV()
  const { standardFils, voucherFils } = sample()
  const hours = (n: number) => c('commonCountHours', { count: n })
  const rows: Row[] = [
    { key: 'request', title: t('hotelVenueTlRequest'), text: '' },
    { key: 'reply', title: t('hotelVenueTlReply', { hours: hours(rules.responseHours) }), text: '' },
    { key: 'confirm', title: t('hotelVenueTlConfirm', { hours: hours(platform.confirmWindowHours) }), text: '' },
    {
      key: 'pay',
      title: t('hotelVenueTlPay'),
      text: t('hotelVenueTlPayText', { voucher: f.money(voucherFils, { mode: 'exact' }), standard: f.money(standardFils, { mode: 'exact' }) }),
    },
  ]
  return (
    <div className="hv-tl" data-gz="CouplesTimeline">
      <ol className="hv-tl__list">
        {rows.map((r, i) => (
          <li key={r.key} className="hv-tl__row" data-last={i === rows.length - 1 || undefined}>
            <span className="hv-tl__rail" aria-hidden="true">
              <span className="hv-tl__bead" />
              <span className="hv-tl__line" />
            </span>
            <span className="hv-tl__body">
              <span className="gz-t-title hv-tl__title">
                <Figures text={r.title} />
              </span>
              {r.text ? (
                <span className="gz-t-body-s hv-tl__text">
                  <Figures text={r.text as string} />
                </span>
              ) : null}
            </span>
          </li>
        ))}
      </ol>
    </div>
  )
}
