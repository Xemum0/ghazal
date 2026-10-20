// HL-BOOK-07 Voucher redeemed (sheet). Requirement IDs: HA-VCH-01, HA-VCH-05, HA-VCH-03.
// The confirmation after a redemption (ADR 0033): the request is now Redeemed, the voucher used, and the venue's next step is simply to
// honour the voucher price it showed. One short success moment (a drawing, no confetti): the voucher price as one figure with the sentence
// that the client is charged at it behind an info glyph, then the facts of the visit as glyphs and values (who, when, hall, guests, who
// redeemed). Payment to the venue happens off-app: Ghazal shows no amount due. "Done" returns to the scanner, "View booking" opens HL-BOOK-03.
// Text diet (ADR 0034): the title is the one word of the sheet header; no label, no line of prose.
// States: offline-cached
import { getBooking, type Booking } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Avatar, Banner, Button, FactChip, FactRow, Illustration, InfoButton, Price, VoucherChip, useNav } from '../../../system'
import { Fx, UserText, useDays, useHallName, useStaffName } from './_components/bits'
import { useBookingById, useBookingParams } from './_components/model'
import { SheetFrame } from './_components/SheetFrame'
import './_components/redeem.css'
import './HL-BOOK-07.css'

export const states = ['offline-cached']

/** The request a static frame draws when no redemption has just happened: a redeemed one from the seed. */
const DEMO_BOOKING_ID = 'bk-GZ-2609-4Z6X'

export default function VoucherRedeemed() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const days = useDays()
  const hall = useHallName()
  const staff = useStaffName()
  const params = useBookingParams() as { bookingId?: string }
  const found = useBookingById(params.bookingId ?? DEMO_BOOKING_ID) ?? (getBooking(DEMO_BOOKING_ID) as Booking)
  const voucher = usePrototype(s => s.vouchers.find(v => v.id === found.voucherId))
  const first = found.clientName.trim().split(/\s+/)[0] ?? found.clientName
  const guests = found.sections.reduce((n, s) => n + s.guests, 0)
  const at = found.redeemedAt
  const by = staff(found.redeemedBy ?? '') || t('hotelBookingsActorVenue')
  const close = () => nav.closeSheet()

  return (
    <SheetFrame
      title={c('commonStatusHotelRedeemed')}
      onClose={close}
      footer={
        <div className="hbk-done__footer">
          <Button variant="primary" size="cta" fullWidth onClick={close}>
            {c('commonActionDone')}
          </Button>
          <Button
            variant="tertiary"
            fullWidth
            onClick={() => {
              close()
              nav.push('HL-BOOK-03', { bookingId: found.id, section: 'voucher' })
            }}
          >
            {t('hotelBookingsViewBooking')}
          </Button>
        </div>
      }
    >
      {state === 'offline-cached' ? (
        <Banner tone="offline" shape="card">
          {t('hotelBookingsRedeemedCached', { time: f.time(f.now()) })}
        </Banner>
      ) : null}
      <div className="hbk-done">
        <div className="hbk-done__art">
          <Illustration name="partner-redeemed" size="lg" />
        </div>
        <div className="hbk-done__price">
          <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
          <Price fils={found.totals.voucherTotal.fils} mode="exact" size="total" />
          <InfoButton title={c('commonVoucher')}>
            <p>{t('hotelBookingsRedeemedFine')}</p>
          </InfoButton>
        </div>
        <div className="hbk-done__facts">
          <div className="hbk-done__who">
            <Avatar name={found.clientName} size="sm" voice="sans" />
            <UserText role="title">{first}</UserText>
            {voucher ? <VoucherChip code={voucher.code} tone="quiet" /> : null}
          </div>
          <FactRow label={t('hotelBookingsFactsLabel')}>
            <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={f.date(found.eventDate, 'short')} />} />
            <FactChip icon="users-three" label={t('hotelBookingsFactGuests')} value={f.integer(guests)} />
          </FactRow>
          <FactRow label={t('hotelBookingsFactsLabel')}>
            <FactChip icon="hall" label={t('hotelBookingsFactHall')} value={<Fx text={hall(found)} />} />
          </FactRow>
          <FactRow label={t('hotelBookingsRowRedeemedBy')}>
            <FactChip icon="check-circle" tone="accent" label={t('hotelBookingsRowRedeemedBy')} value={<UserText role="body-s" text={by}>{by}</UserText>} />
            {at ? <FactChip icon="clock" label={t('hotelBookingsRowTime')} value={<Fx text={`${days.dm(at)} ${f.time(at)}`} />} /> : null}
          </FactRow>
        </div>
      </div>
    </SheetFrame>
  )
}
