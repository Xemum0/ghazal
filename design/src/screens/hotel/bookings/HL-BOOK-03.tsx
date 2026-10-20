// HL-BOOK-03 Booking detail. Requirement IDs: HA-BOOK-02, HA-BOOK-03, HA-BOOK-04, HA-BOOK-06, HA-BOOK-07, HA-BOOK-10, HA-BOOK-11, HA-AUTH-02, HA-VCH-01, HA-VCH-03, HA-VCH-05.
// The canonical request screen of the partner (ADR 0033): who, when, what, the voucher price and what happens next. One set of sections, a
// variant per status (never one screen per status): header (status, voucher chip, the date, the deadline that matters as a glyph and a
// figure), the Booking Thread as five glyph knots, special requests, the client (monogram, Call and Chat glyphs), the counter-offer when one
// is out, the event (hall photograph, time, section, guests, package, extras), the price at the voucher (one figure, the standard struck, the
// saving), the voucher panel once it is confirmed or used, the history behind one row. No payment, cash, invoice or payout exists: the venue
// collects the voucher price from the client directly (one sentence, behind an info glyph). The pinned bar carries only the action of the
// status and role (see DecisionBar); the decisions run in the Decisions flow (HL-DCSN-01 to 04) and the redemption in HL-BOOK-06.
// Text diet (ADR 0034): no section titles, no labels, no captions; a state is a drawing, a word and facts; the paragraphs are the two
// exceptions that apply here (voucher and cancellation terms), each behind an info glyph.
// Demo variants: Pending = Reem Al-Dosari (GZ-2611-0147), Awaiting client = Haya Al-Mutairi, Confirmed = Lulwa Al-Saleh, Redeemed = Munira
// Al-Khaled, Completed = Nora Al-Fahad.
// States: pending, pending-danger, awaiting-client-confirmation, confirmed, redeemed, counter-offer-sent, completed, declined, expired-missed,
//         expired-lapsed, cancelled-by-client, cancelled-by-venue, issue-reported, loading, error, offline, conflict, role-limited
import { useEffect, useRef } from 'react'
import { Ltr, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ErrorState, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { Copyable } from './_components/DetailParts'
import { DecisionBar } from './_components/DecisionBar'
import { ActionsBlock, AuditBlock, ClientBlock, EventBlock, HeaderBlock, Notices, OutcomeBlock, PriceBlock, ProposalBlock, SpecialRequests, ThreadBlock, VoucherBlock, voucherVisible } from './_components/DetailSections'
import { useDetailModel } from './_components/detail'
import { useVenueBookings } from './_components/model'
import './HL-BOOK-03.css'

export const states = [
  'pending',
  'pending-danger',
  'awaiting-client-confirmation',
  'confirmed',
  'redeemed',
  'counter-offer-sent',
  'completed',
  'declined',
  'expired-missed',
  'expired-lapsed',
  'cancelled-by-client',
  'cancelled-by-venue',
  'issue-reported',
  'loading',
  'error',
  'offline',
  'conflict',
  'role-limited',
]

const CLOSED = new Set(['declined', 'expired', 'cancelled', 'completed'])

export default function BookingDetail() {
  const { state } = useFrame()
  const nav = useNav()
  const t = useT('hotel-bookings')
  const m = useDetailModel(state)
  const all = useVenueBookings()
  const { booking: b } = m
  const others = all.filter(x => x.status === 'pending' && x.eventDate === b.eventDate && x.id !== b.id).length
  const voucherRef = useRef<HTMLDivElement>(null)

  // A landing from the redeem screen or a notification can ask for the voucher panel.
  useEffect(() => {
    if (m.params.section === 'voucher') voucherRef.current?.scrollIntoView({ block: 'start', behavior: 'auto' })
  }, [m.params.section])

  const top = (
    <TopBar
      title={t('hotelBookingsDetailTitle')}
      subtitle={
        <Copyable value={b.ref}>
          <Ltr className="gz-num">{b.ref}</Ltr>
        </Copyable>
      }
    />
  )

  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="hbk-detail__skel" aria-busy="true">
          <Skeleton variant="line" inlineSize={120} blockSize={24} />
          <Skeleton variant="line" inlineSize={200} blockSize={32} />
          <Skeleton variant="line" blockSize={24} />
          <Skeleton variant="block" blockSize={96} />
          <Skeleton variant="block" blockSize={180} />
          <Skeleton variant="block" blockSize={140} />
        </div>
      </Screen>
    )
  }

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('HL-BOOK-03', { bookingId: b.id })} secondary={{ label: t('hotelBookingsBackToList'), onPress: () => nav.pop() }} />
      </Screen>
    )
  }

  const closed = CLOSED.has(b.status)
  return (
    <Screen top={top} bottom={<DecisionBar m={m} others={others} />}>
      <div className="hbk-detail" data-status={b.status}>
        <HeaderBlock m={m} />
        <div className="hbk-detail__body">
          <ThreadBlock b={b} />
          <Notices m={m} others={others} />
          {closed ? <OutcomeBlock m={m} /> : null}
          {b.specialRequests ? <SpecialRequests text={b.specialRequests} /> : null}
          <ClientBlock m={m} />
          <ProposalBlock b={b} />
          <EventBlock b={b} />
          <PriceBlock m={m} />
          {voucherVisible(m) ? (
            <div ref={voucherRef} className="hbk-detail__voucher">
              <VoucherBlock m={m} />
            </div>
          ) : null}
          <ActionsBlock m={m} />
          <AuditBlock b={b} />
        </div>
      </div>
    </Screen>
  )
}
