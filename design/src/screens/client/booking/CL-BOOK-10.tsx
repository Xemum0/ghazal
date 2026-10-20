// CL-BOOK-10 Confirmation window ended. Covers CA-STAT-12, CA-VCH-11, CA-BOOK-16.
// Text diet (ADR 0034): the calm outcome when the 24 hour confirm window lapses (or the venue withdrew its approval, or the date was taken), as a
// drawing, two words and two facts (what ended, which date was released). The sentences (the outcome, and what happens to the voucher: it is back
// with you and can be used again at this venue; a venue-side end also makes it refundable) are behind two info glyphs. The voucher is a ticket
// row with its code, the Ready status and the date it can be used until. Never blaming, never a dead end: a new request, free dates, a message
// to the venue, the venue itself, or similar halls free on the date. params: bookingId, reason (lapsed | revoked | date_taken).
// Navigates to CL-BOOK-01, CL-VENU-03, CL-VCHR-05, CL-MSGS-02, CL-VENU-01.
import { ActionBar, Banner, Button, FactChip, FactRow, Figures, Icon, IconButton, Illustration, InfoButton, ListRow, Photo, Price, Screen, StatusPill, TopBar, imageSrc, useBi, useNav } from '../../../system'
import { Auto, Ltr, useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import * as mock from '../../../mock'
import { similarHalls } from './_components/alternatives'
import { leaveFlow, useLive } from './_components/flow'
import { useRequest } from './_components/useRequest'
import './_components/step.css'
import './_components/sent.css'
import './_components/taken.css'
import './_components/confirm.css'

export const states = ['lapsed-client', 'revoked-by-venue', 'date-taken-meanwhile', 'offline']

type Reason = 'lapsed' | 'revoked' | 'date_taken'
type Params = { bookingId?: string; reason?: Reason }

const FROM_STATE: Record<string, Reason> = { 'lapsed-client': 'lapsed', 'revoked-by-venue': 'revoked', 'date-taken-meanwhile': 'date_taken' }

export default function ConfirmWindowEnded() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const live = useLive()
  const { state } = useFrame()
  const areaIds = usePrototype(s => s.searchBrief.areaIds)
  const req = useRequest(nav.params.bookingId, mock.heroBookingAs('lapsed'))
  const { booking, voucher } = req
  const reason: Reason = (state && FROM_STATE[state]) || nav.params.reason || 'lapsed'
  const offline = state === 'offline'
  const section = booking.sections[0]
  const venueId = booking.venueId
  const venue = venueId ? mock.getVenue(venueId) : undefined
  const date = f.date(booking.eventDate, 'short')
  const reuse = voucher?.reuseUntil ?? null
  const refundable = reason !== 'lapsed'

  const rail = venueId && section ? similarHalls(venueId, booking.eventDate, section.guests, section.audience, areaIds ?? [], 2) : []

  const heading = t(reason === 'lapsed' ? 'clientBookingEndedTitle' : reason === 'revoked' ? 'clientBookingEndedRevokedTitle' : 'clientBookingEndedTakenTitle')
  const outcome =
    reason === 'lapsed'
      ? t('clientBookingEndedLapsed', { duration: tc('commonCountHours', { count: mock.meta.config.confirmWindowHours }), date })
      : reason === 'revoked'
        ? t('clientBookingEndedRevoked', { venue: req.targetName, date })
        : t('clientBookingEndedTaken', { venue: req.targetName, date })
  const voucherLine = reuse
    ? t(refundable ? 'clientBookingEndedVoucherRefundable' : 'clientBookingEndedVoucher', { venue: req.targetName, date: f.date(reuse, 'full') })
    : t('clientBookingEndedVoucherPlain')

  const newRequest = () => {
    if (!venueId) return
    nav.push('CL-BOOK-01', { venueId, voucherId: voucher?.id, fresh: true })
  }
  const freeDates = () => nav.openSheet('CL-VENU-03', { params: { source: 'booking', venueId, hallId: section?.hallId, date: booking.eventDate, guests: section?.guests } })
  const openHall = (id: string) => {
    usePrototype.getState().setBrief({ date: booking.eventDate, guests: section?.guests ?? null, audience: section?.audience ?? null })
    leaveFlow(nav, 'discover', { id: 'CL-VENU-01', params: { venueId: id } })
  }

  return (
    <Screen
      top={<TopBar back="close" backLabel={tc('commonActionClose')} onBack={() => nav.pop()} rule={false} />}
      bottom={
        <ActionBar
          secondary={{ label: t('clientBookingEndedFreeDates'), onPress: freeDates }}
          // Offline says so in the banner above; a caption under the primary would stretch the secondary beside it.
          action={{ label: t('clientBookingEndedNew'), onPress: newRequest, disabled: offline }}
        />
      }
      bodyClassName="bk-body"
    >
      {offline ? <Banner tone="offline" shape="card">{t('clientBookingEndedOffline')}</Banner> : null}
      <section className="bk-ended-hero" data-gz-id="booking.ended.outcome" aria-labelledby="bk-ended-title">
        {/* The hourglass is the 24 hours that ran out; when the venue withdrew or the date went to someone else, the calendar says it. */}
        <Illustration name={reason === 'lapsed' ? 'hourglass' : 'calendar'} size="lg" />
        <h1 id="bk-ended-title" className="bk-ended-hero__title gz-t-d3">
          {heading}
          <InfoButton title={heading}>
            <p>
              <Figures text={outcome} />
            </p>
          </InfoButton>
        </h1>
        <FactRow>
          <FactChip icon="calendar-x" label={t('clientBookingEndedReleased')} value={f.date(booking.eventDate, 'compact')} tone="muted" />
          {reason === 'lapsed' ? <FactChip icon="clock-off" label={t('clientBookingEndedWindow')} value={tc('commonCountHours', { count: mock.meta.config.confirmWindowHours })} tone="muted" /> : null}
        </FactRow>
      </section>

      <section className="bk-section bk-section--tight" aria-label={t('clientBookingEndedVoucherTitle')}>
        <div className="bk-ended-voucher" data-gz-id="booking.ended.voucher">
          <div className="bk-ended-voucher__head">
            <span className="bk-ended-voucher__disk" aria-hidden="true">
              <Icon name="ticket" size="md" />
            </span>
            <span className="bk-ended-voucher__code gz-t-fig-body">{voucher ? <Ltr>{voucher.code}</Ltr> : null}</span>
            <InfoButton title={t('clientBookingEndedVoucherTitle')}>
              <p>
                <Figures text={voucherLine} />
              </p>
            </InfoButton>
          </div>
          <div className="bk-ended-voucher__foot">
            <StatusPill status="voucher_active" />
            {reuse ? <FactChip icon="calendar" label={t('clientBookingEndedUntil')} value={f.date(reuse, 'compact')} size="sm" tone="muted" /> : null}
            {refundable && voucher ? (
              <Button variant="tertiary" iconEnd="chevron-right" onClick={() => nav.openSheet('CL-VCHR-05', { params: { voucherId: voucher.id } })} className="bk-ended-voucher__refund">
                {t('clientBookingEndedRefund')}
              </Button>
            ) : null}
          </div>
        </div>
      </section>

      {rail.length ? (
        <section className="bk-section bk-section--tight" aria-label={t('clientBookingTakenSimilar', { date })}>
          <FactRow>
            <FactChip icon="calendar-check" label={t('clientBookingTakenSimilar', { date: '' })} value={f.date(booking.eventDate, 'compact')} tone="muted" />
          </FactRow>
          <div>
            {rail.map((h, i) => (
              <ListRow
                key={h.venue.id}
                flush
                last={i === rail.length - 1}
                chevron
                autoDir
                leading={<span className="bk-taken__thumb">{h.venue.cover ? <Photo src={imageSrc(h.venue.cover.file)} alt="" sizes="64px" /> : null}</span>}
                title={<Auto>{bi(h.venue.name)}</Auto>}
                trailing={<Price fils={(h.price.voucher ?? h.price.standard).fils} size="strong" />}
                onClick={() => openHall(h.venue.id)}
              />
            ))}
          </div>
        </section>
      ) : null}

      <section className="bk-section bk-leave bk-leave--center" aria-label={t('clientBookingEndedViewVenue')}>
        <IconButton icon="chat" label={tc('commonActionMessage')} onClick={() => nav.push('CL-MSGS-02', { venueId })} />
        {venue ? (
          <Button variant="tertiary" iconStart="venue" onClick={() => nav.push('CL-VENU-01', { venueId: venue.id })}>
            {t('clientBookingEndedViewVenue')}
          </Button>
        ) : null}
      </section>
    </Screen>
  )
}
