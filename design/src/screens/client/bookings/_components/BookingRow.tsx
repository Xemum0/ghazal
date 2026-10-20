// BookingRow (CL-BKNG-01): one request in the list, in glyphs and figures (ADR 0034). Thumbnail and serif venue name, then the facts as
// `[calendar] 14 Jan`, the reception symbol and the session glyph (no words), the status chip (icon + one word) with the voucher price
// and a ticket glyph, then (while the request is live) the compact Booking Thread, whose one line already carries the word and the
// absolute time. A finished request says what became of the voucher with a ticket glyph and one outcome glyph. The whole card is one target.
import { Icon, Monogram, Price, StatusPill, BookingThread, FactChip, FactRow, Photo, imageSrc } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { Fx } from './Fx'
import { groupOf, targetOf, type View } from './model'
import { useBk } from './useBk'
import './booking-row.css'

export type BookingRowProps = {
  view: View
  onOpen?: () => void
  /** Draw as a "Needs you" row: the chip stays the same, the row gets the quiet tint rule (no gold fill). */
  attention?: boolean
}

/** A ticket glyph and one outcome glyph: the voucher came back (undo) or was used up (double check). The word is the accessible name. */
function VoucherMark({ kind, label }: { kind: 'back' | 'used'; label: string }) {
  return (
    <span className="gzb-vmark" role="img" aria-label={label} data-gz-id="note">
      <Icon name="ticket" size="xs" tone="secondary" />
      <Icon name={kind === 'back' ? 'undo' : 'check-double'} size="xs" tone="secondary" />
    </span>
  )
}

export function BookingRow({ view, onOpen, attention }: BookingRowProps) {
  const { t, tc, dayMon, stamp, audienceIcon, audience, session, targetName } = useBk()
  const { lang } = useLang()
  const { booking, voucher, variant } = view
  const target = targetOf(booking)
  const name = targetName(booking)
  const cover = target.venue?.cover
  const live = groupOf(variant) !== 'past'
  const reception = audienceIcon(booking)
  const sess = session(booking)

  // Beyond the thread: a reply deadline for a venue-proposed date (a fact under the thread) and, for a finished request, what became of
  // the voucher (a glyph pair beside the status chip). A redeemed request needs neither: its thread already says the day.
  const mark = (() => {
    switch (variant) {
      case 'completed':
      case 'issue-reported':
        return <VoucherMark kind="used" label={t('clientBookingsRowVoucherUsed')} />
      case 'cancelled-by-me':
        return <VoucherMark kind={voucher.status === 'used' ? 'used' : 'back'} label={voucher.status === 'used' ? t('clientBookingsRowVoucherUsed') : t('clientBookingsRowVoucherBack')} />
      case 'declined':
      case 'expired-venue-no-reply':
      case 'expired-not-confirmed':
      case 'cancelled-by-venue':
        return <VoucherMark kind="back" label={t('clientBookingsRowVoucherBack')} />
      default:
        return null
    }
  })()
  const foot = (() => {
    switch (variant) {
      case 'venue-proposed-date':
        return booking.proposal ? <FactChip icon="timer" tone="accent" label={t('clientBookingsRowReplyBy')} value={<Fx text={stamp(booking.proposal.expiresAt)} />} size="sm" /> : null
      default:
        return null
    }
  })()

  return (
    <article className={`gzb-row gz-press${attention ? ' is-attention' : ''}`} data-gz="BookingRow" data-status={booking.status} data-gz-id={`row.${booking.id}`}>
      <div className="gzb-row__top">
        <span className="gzb-row__thumb">{cover ? <Photo src={imageSrc(cover.file)} alt="" className="gzb-row__photo" sizes="56px" /> : <Monogram size="sm" />}</span>
        <div className="gzb-row__who">
          <h3 className="gzb-row__name gz-t-d1 gz-clamp-2" lang={lang}>
            {name}
          </h3>
          <FactRow className="gzb-row__facts">
            <FactChip icon="calendar" label={t('clientBookingsFactDate')} value={<Fx text={dayMon(booking.eventDate)} />} size="sm" tone="muted" />
            {reception ? <FactChip icon={reception} label={audience(booking) ?? ''} size="sm" tone="muted" /> : null}
            {sess ? <FactChip icon={sess.icon} label={sess.label} size="sm" tone="muted" /> : null}
          </FactRow>
        </div>
      </div>

      <div className="gzb-row__status" data-gz-id="status">
        <StatusPill status={view.pill} />
        {mark}
        <span className="gzb-row__amount">
          <Icon name="ticket" size="xs" tone="secondary" />
          <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
          <Price fils={booking.totals.voucherTotal.fils} mode="exact" size="strong" />
        </span>
      </div>

      {live ? <BookingThread booking={booking} variant="compact" /> : null}
      {foot ? <div className="gzb-row__foot">{foot}</div> : null}

      <button type="button" className="gz-reset gzb-row__open" onClick={onOpen} aria-label={`${name}, ${dayMon(booking.eventDate)}`} />
    </article>
  )
}
