// BookingCard (CL-BKNG list, My Wedding, Home "Your booking"): one request as a panel (ADR 0033). Venue or provider thumbnail and serif
// name, the hall line, the status pill (icon + label) beside the voucher chip, three key facts (date, guests, voucher price), the compact
// Booking Thread with its current label, and the reference as an LTR isolate. An approved request carries one calm line with the time left
// to confirm (hours and minutes, never seconds). The whole card is one target; nothing on it is gold except what the thread itself says.
//
// variants  card   the full panel with facts and the compact thread (default)
//           row    thumbnail, name, date and status only (dense lists, Past)
// states    default, pressed, focus-visible, loading (skeleton), no photo
import type { Booking } from '@gz/contracts'
import { bookingTarget, getHall, getVoucher } from '../../mock'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Divider, Icon, Monogram, Price, Skeleton, StatusPill } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import { VoucherChip, useConfirmLeft } from '../domain-voucher'
import { BookingThread } from './BookingThread'
import { Fig, Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './booking-card.css'

const useW = defineWords({
  date: p('Date', 'التاريخ'),
  guests: p('Guests', 'الضيوف'),
  voucherPrice: p('Voucher price', 'سعر الكوبون'),
  quantity: p('Quantity', 'الكمية'),
  reference: p('Reference', 'رقم الحجز'),
  open: p('Open booking {ref}', 'فتح الحجز {ref}'),
  confirmBy: p('Confirm by {when} · {left}', 'التأكيد حتى {when} · {left}'),
})

export type BookingCardProps = {
  booking: Booking
  variant?: 'card' | 'row'
  onOpen?: () => void
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

export function BookingCard({ booking, variant = 'card', onOpen, loading, previewState, className }: BookingCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()

  if (loading) {
    return (
      <div className={cx('gz-bcard gz-cpanel is-loading', className)} data-gz="BookingCard" data-variant={variant} aria-busy="true">
        <div className="gz-bcard__top">
          <Skeleton variant="block" inlineSize={56} blockSize={56} />
          <div className="gz-bcard__who">
            <Skeleton inlineSize={180} blockSize={28} />
            <Skeleton inlineSize={120} blockSize={20} />
          </div>
        </div>
        {variant === 'card' ? (
          <>
            <Skeleton inlineSize={96} blockSize={24} />
            <Skeleton blockSize={52} />
            <Skeleton blockSize={20} />
          </>
        ) : null}
      </div>
    )
  }

  const target = bookingTarget(booking)
  const hall = getHall(booking.sections[0]?.hallId ?? '')?.hall
  const name = bi(target.name)
  const cover = target.venue?.cover ?? target.provider?.portfolio[0] ?? null
  const guests = booking.service ? booking.service.quantity : booking.sections.reduce((n, s) => n + s.guests, 0)
  const hallLine = [hall ? bi(hall.name) : null].filter(Boolean).join(' · ')
  const voucher = getVoucher(booking.voucherId)

  const head = (
    <div className="gz-bcard__top">
      <span className="gz-bcard__thumb" data-gz-id="thumb">
        {cover ? <Photo src={imageSrc(cover.file)} alt="" className="gz-bcard__photo" /> : <Monogram size="sm" />}
      </span>
      <div className="gz-bcard__who">
        <h3 className="gz-bcard__name gz-t-d1 gz-clamp-2" lang={lang} data-gz-id="name">
          {name}
        </h3>
        {hallLine ? <p className="gz-bcard__hall gz-t-body-s">{hallLine}</p> : null}
      </div>
    </div>
  )

  return (
    <article
      data-gz="BookingCard"
      data-variant={variant}
      data-status={booking.status}
      className={cx('gz-bcard gz-cpanel gz-press', variant === 'row' && 'gz-bcard--row', previewState === 'pressed' && 'is-pressed', className)}
    >
      {head}

      <div className="gz-bcard__status" data-gz-id="status">
        <StatusPill status={booking.status} />
        {booking.proposal?.status === 'proposed' ? <StatusPill status="date_proposed" /> : null}
        {voucher ? <VoucherChip code={voucher.code} tone={booking.status === 'redeemed' || booking.status === 'completed' ? 'quiet' : 'bound'} /> : null}
        <span className="gz-bcard__ref gz-t-fig-caption" dir="ltr">
          {booking.ref}
        </span>
      </div>

      {variant === 'card' ? (
        <>
          <dl className="gz-bcard__facts" data-gz-id="facts">
            <div className="gz-bcard__fact gz-bcard__fact--date">
              <dt className="gz-t-caption">{w('date')}</dt>
              <dd className="gz-t-body-s">
                <Figures text={f.date(booking.eventDate, 'compact')} />
              </dd>
            </div>
            <Divider vertical />
            <div className="gz-bcard__fact">
              <dt className="gz-t-caption">{booking.service ? w('quantity') : w('guests')}</dt>
              <dd className="gz-t-body-s">
                <Fig>{f.integer(guests)}</Fig>
              </dd>
            </div>
            <Divider vertical />
            <div className="gz-bcard__fact">
              <dt className="gz-t-caption">{w('voucherPrice')}</dt>
              <dd className="gz-t-body-s">
                <Price fils={booking.totals.voucherTotal.fils} size="card" />
              </dd>
            </div>
          </dl>
          <BookingThread booking={booking} variant="compact" />
          {booking.status === 'approved' && booking.confirmBy ? <ConfirmLine deadline={booking.confirmBy} /> : null}
        </>
      ) : (
        <p className="gz-bcard__line gz-t-caption">
          <Icon name="calendar" size="xs" tone="secondary" />
          <Figures text={f.date(booking.eventDate, 'full')} />
        </p>
      )}

      <button type="button" className="gz-reset gz-bcard__open" onClick={onOpen} aria-label={`${name}, ${w('open', { ref: booking.ref })}`} />
    </article>
  )
}

/** The one calm line under an approved request: when to confirm by and how long is left. */
function ConfirmLine({ deadline }: { deadline: string }) {
  const f = useFormat()
  const w = useW()
  const left = useConfirmLeft(deadline)
  return (
    <p className="gz-bcard__confirm gz-t-caption" data-gz-id="confirm-line">
      <Icon name="hourglass" size="xs" tone="accent" />
      <Figures text={w('confirmBy', { when: f.dateTime(deadline, 'short'), left: left.text })} />
    </p>
  )
}
