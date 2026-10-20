// VoucherOutcome: what became of the KD 2 voucher once its request ended (voucher-model section 4.4, CA-VCH-11). The outcome is a glyph and a
// title of at most four words; "until 11 Jan" and "Refundable" are facts; the sentence that explains reuse, refund or use-up is behind the
// info glyph (voucher terms, one of the three allowed paragraphs). A released voucher is reusable at the same venue for 60 days and, only
// after a venue fault, askable; a voucher of a confirmed booking that the client cancelled is used up. The one action opens CL-VCHR-05.
import type { IconName } from '@gz/tokens'
import { Button, FactChip, FactRow, Icon, InfoButton, useNav } from '../../../../system'
import { voucherOptions, type Voucher } from '../../../../mock'
import { Fx } from './Fx'
import { useBk } from './useBk'
import './voucher-outcome.css'

export type VoucherOutcomeProps = {
  voucher: Voucher
  /** Name of the venue or provider the voucher is bound to (named in the info sheet). */
  targetName: string
  /** Instant to read the validity from (the prototype clock by default). */
  now?: string
  /** The action is the screen's main one (no pinned bar): draw it as the primary. */
  primary?: boolean
  /** Hide the action when the screen already offers the same way on (a new request at the same venue). */
  action?: boolean
}

export function VoucherOutcome({ voucher, targetName, now, primary = false, action: withAction = true }: VoucherOutcomeProps) {
  const nav = useNav()
  const { t, dayFull, dayMon } = useBk()
  const opts = voucherOptions(voucher, now)

  let icon: IconName = 'ticket'
  let title: string
  let body: string
  let until: string | null = null
  let askable = false
  let action: string | null = null

  if (voucher.status === 'used') {
    icon = 'check-double'
    title = t('clientBookingsOutcomeUsedTitle')
    body = t('clientBookingsOutcomeUsedBody')
  } else if (voucher.status === 'forfeited') {
    icon = 'x-circle'
    title = t('clientBookingsOutcomeForfeitedTitle')
    body = t('clientBookingsOutcomeForfeitedBody', { venue: targetName, hours: 24 })
  } else if (voucher.status === 'credit_issued') {
    icon = 'gift'
    title = t('clientBookingsOutcomeCreditTitle')
    body = t('clientBookingsOutcomeCreditBody')
  } else if (voucher.status === 'expired') {
    icon = 'clock-off'
    title = t('clientBookingsOutcomeExpiredTitle')
    body = t('clientBookingsOutcomeExpiredBody')
  } else if (opts.reusable && opts.reusableUntil) {
    icon = 'undo'
    title = t('clientBookingsOutcomeBackTitle')
    until = opts.reusableUntil
    askable = opts.creditEligible
    body = askable
      ? t('clientBookingsOutcomeBackCredit', { venue: targetName, date: dayFull(opts.reusableUntil) })
      : t('clientBookingsOutcomeBackReusable', { venue: targetName, date: dayFull(opts.reusableUntil) })
    action = t('clientBookingsOutcomeAction')
  } else {
    icon = 'undo'
    title = t('clientBookingsOutcomeBackTitle')
    body = t('clientBookingsOutcomeBackPlain')
  }

  return (
    <section className="gzb-outcome" data-gz="VoucherOutcome" data-status={voucher.status} data-gz-id="voucher-outcome">
      <div className="gzb-outcome__head">
        <span className="gzb-outcome__icon" aria-hidden="true">
          <Icon name="ticket" size="sm" tone="secondary" />
          <Icon name={icon} size="sm" tone="primary" />
        </span>
        <h3 className="gzb-outcome__title gz-t-title">{title}</h3>
        <InfoButton title={t('clientBookingsOutcomeInfoTitle')} className="gzb-outcome__info">
          <p>{body}</p>
        </InfoButton>
      </div>
      {until || askable ? (
        <FactRow className="gzb-outcome__facts">
          {until ? <FactChip icon="calendar" label={t('clientBookingsOutcomeUntil')} value={<Fx text={dayMon(until)} />} /> : null}
          {askable ? <FactChip icon="gift" label={t('clientBookingsOutcomeAskSupport')} value={t('clientBookingsOutcomeAskSupport')} tone="muted" /> : null}
        </FactRow>
      ) : null}
      {action && withAction ? (
        <Button variant={primary ? 'primary' : 'secondary'} iconStart="ticket" fullWidth onClick={() => nav.openSheet('CL-VCHR-05', { params: { voucherId: voucher.id } })}>
          {action}
        </Button>
      ) : null}
    </section>
  )
}
