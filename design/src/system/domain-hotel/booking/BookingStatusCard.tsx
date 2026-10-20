// BookingStatusCard: where a request stands, for the partner (ADR 0033 D3, direction 4): the status pill (partner wording) and the booking
// reference, the vertical Booking Thread (past knots with absolute times, at most two faint future knots), then the VOUCHER block instead of
// a payment schedule: the voucher chip with its code, what the client pays the venue directly (the voucher total, the standard price struck
// through) and, while the request waits on the client, the calm 24 hour confirm line. "Redeem voucher" is offered once the request is
// confirmed, to the roles that may (Admin, Manager, Reception; ADR 0008 D12). A counter-offer is a chip, never a status. No payment
// milestones, no cash, no balance: the event is settled between the client and the venue off-app.
import type { Booking } from '@gz/contracts'
import { getVoucher } from '../../../mock'
import { useFormat, Ltr } from '../../../i18n'
import { Button, Icon, Price, StatusPill } from '../../core'
import { cx } from '../../core/cx'
import { BookingThread } from '../../domain-client'
import { VoucherChip, useConfirmLeft } from '../../domain-voucher'
import { Figures } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './booking-detail.css'

const useW = defineWords({
  ref: p('Booking reference', 'رقم الحجز'),
  voucher: p('Voucher', 'الكوبون'),
  code: p('Code', 'الرمز'),
  clientPays: p('The client pays you directly', 'يدفع العميل لكم مباشرة'),
  standard: p('Standard price', 'السعر العادي'),
  direct: p('Settled between you and the client, off the app.', 'تتم التسوية بينكم وبين العميل خارج التطبيق.'),
  awaiting: p('Waiting for the client to confirm by {when} · {left}', 'بانتظار تأكيد العميل حتى {when} · {left}'),
  redeem: p('Redeem voucher', 'استخدام الكوبون'),
  redeemed: p('Redeemed {when} by {name}', 'تم الاستخدام {when} بواسطة {name}'),
  redeemedNoName: p('Redeemed {when}', 'تم الاستخدام {when}'),
  usedLine: p('Voucher used', 'تم استخدام الكوبون'),
})

export type BookingStatusCardProps = {
  booking: Booking
  /** Offer "Redeem voucher" on a confirmed request (roles that may redeem). */
  canRedeem?: boolean
  onRedeem?: () => void
  className?: string
}

export function BookingStatusCard({ booking, canRedeem = false, onRedeem, className }: BookingStatusCardProps) {
  const f = useFormat()
  const w = useW()
  const voucher = getVoucher(booking.voucherId)
  const hasVoucherPrice = booking.totals.voucherTotal.fils < booking.totals.standardTotal.fils
  return (
    <section data-gz="BookingStatusCard" className={cx('gz-bs', className)}>
      <header className="gz-bs__head">
        <div className="gz-bs__pills">
          <StatusPill status={booking.status} audience="hotel" />
          {booking.proposal?.status === 'proposed' ? <StatusPill status="date_proposed" /> : null}
        </div>
        <p className="gz-bs__ref gz-t-caption">
          {w('ref')} <Ltr className="gz-num">{booking.ref}</Ltr>
        </p>
      </header>

      <BookingThread booking={booking} variant="vertical" />

      {booking.status === 'approved' && booking.confirmBy ? <AwaitingLine deadline={booking.confirmBy} /> : null}

      <div className="gz-bs__pay">
        <h3 className="gz-t-label gz-bs__label">{w('voucher')}</h3>
        {voucher ? (
          <div className="gz-bs__voucher">
            <VoucherChip code={voucher.code} tone={voucher.status === 'used' ? 'quiet' : 'bound'} />
            <span className="gz-bs__code gz-t-fig-title">
              <bdi dir="ltr">{voucher.code}</bdi>
            </span>
          </div>
        ) : null}
        <div className="gz-bs__total">
          <span className="gz-t-title">{w('clientPays')}</span>
          <Price fils={booking.totals.voucherTotal.fils} mode="exact" size="total" />
        </div>
        {hasVoucherPrice ? (
          <p className="gz-bs__standard gz-t-caption">
            {w('standard')} <span className="gz-t-fig-caption gz-strike"><bdi dir="ltr">{f.money(booking.totals.standardTotal.fils, { mode: 'exact' })}</bdi></span>
          </p>
        ) : null}
        <p className="gz-bs__direct gz-t-caption">{w('direct')}</p>
        {booking.status === 'redeemed' && booking.redeemedAt ? (
          <p className="gz-bs__state gz-bs__state--paid gz-t-caption">
            <Icon name="check-circle" size="xs" tone="success" />
            <Figures text={booking.redeemedBy ? w('redeemed', { when: f.dateTime(booking.redeemedAt, 'short'), name: booking.redeemedBy }) : w('redeemedNoName', { when: f.dateTime(booking.redeemedAt, 'short') })} />
          </p>
        ) : null}
        {canRedeem && booking.status === 'confirmed' ? (
          <Button variant="primary" iconStart="qr-code" fullWidth onClick={onRedeem}>
            {w('redeem')}
          </Button>
        ) : null}
      </div>
    </section>
  )
}

function AwaitingLine({ deadline }: { deadline: string }) {
  const f = useFormat()
  const w = useW()
  const left = useConfirmLeft(deadline)
  return (
    <p className="gz-bs__state gz-t-caption" data-gz-id="awaiting">
      <Icon name="hourglass" size="xs" tone="accent" />
      <Figures text={w('awaiting', { when: f.dateTime(deadline, 'short'), left: left.text })} />
    </p>
  )
}
