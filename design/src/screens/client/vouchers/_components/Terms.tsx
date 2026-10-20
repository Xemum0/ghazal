// Terms: the voucher terms, the one paragraph set that CA-VCH-01 needs on the explainer and that the diet allows (ADR 0034 section 6: cancellation,
// refund and voucher terms) behind an info glyph. A short icon list: what it is and what it is bound to, who is paid and where, the two
// 24 hour windows, the validity, and what happens to the voucher when it does not go ahead. Numbers come from the configuration (meta.config).
import type { IconName } from '@gz/tokens'
import { Figures, Icon } from '../../../../system'
import { meta } from '../../../../mock'
import { useVc } from './useVc'
import { CONFIRM_HOURS } from './model'
import './terms.css'

export function Terms({ name, replyHours }: { name: string; replyHours: number }) {
  const { t, tc, money } = useVc()
  const fee = money(meta.config.voucherFeeFils)
  const days = tc('commonCountDays', { count: meta.config.voucherReuseDays })
  const validity = tc('commonCountDays', { count: meta.config.voucherValidityDays })
  const rows: [IconName, string][] = [
    ['ticket', t('clientVouchersTermWhat', { fee, name })],
    ['hall', t('clientVouchersTermDirect', { name })],
    ['timer', t('clientVouchersTermWindows', { name, reply: tc('commonCountHours', { count: replyHours }), confirm: tc('commonCountHours', { count: CONFIRM_HOURS() }) })],
    ['hourglass', t('clientVouchersTermValid', { validity })],
    ['undo', t('clientVouchersTermBack', { days, fee })],
    ['refresh', t('clientVouchersTermWithdraw')],
    ['x-circle', t('clientVouchersTermUsed')],
  ]
  return (
    <ul className="gzv-terms" data-gz-id="terms">
      {rows.map(([icon, text]) => (
        <li key={icon + text} className="gzv-terms__item">
          <span className="gzv-terms__glyph" aria-hidden="true">
            <Icon name={icon} size="sm" tone="secondary" />
          </span>
          <p className="gzv-terms__text">
            <Figures text={text} />
          </p>
        </li>
      ))}
    </ul>
  )
}
