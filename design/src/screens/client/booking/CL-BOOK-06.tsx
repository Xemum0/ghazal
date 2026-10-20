// CL-BOOK-06 Request sent: the outcome of a request and the screen that keeps the wait between request and reply calm.
// Covers CA-BOOK-10, CA-BOOK-12, CA-STAT-03, CA-PLAN-01, CA-NOTI-02, CA-CHAT-02, CA-VCH-08.
// Text diet (ADR 0034): one ink panel with the drawing (the success moment, 640 ms, no confetti), the outcome in two words and the Booking Thread
// (a glyph per knot, one word under the active one, the absolute expected-reply time as a timer fact; never a ticking clock). Below it the
// request as facts (venue, date, hall, guests, voucher total, reference), the voucher as one row, the planner offer (once) and the ways out.
// The sentences (the date is not held yet; the voucher is attached; withdrawing returns it) live behind one info glyph. One primary: View request.
// Navigates to CL-BKNG-02, CL-MSGS-02, CL-PLAN-01, CL-DISC-01, CL-WEDD-01, CL-VCHR-03.
import { useEffect } from 'react'
import { ActionBar, BookingThread, Banner, Button, FactChip, FactRow, Figures, IconListRow, InfoButton, Screen, Sheet, TopBar, useBi, useNav } from '../../../system'
import { Auto, Ltr, useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import * as mock from '../../../mock'
import { NotifPrompt, PlannerOffer, SuccessHero } from './_components/SentParts'
import { addHoursIso, leaveFlow, useFlowStore, useLive } from './_components/flow'
import './_components/step.css'
import './_components/sent.css'

export const states = ['date-held-chip', 'urgent-event', 'notification-pre-prompt', 'offline']

export default function RequestSent() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const live = useLive()
  const { state } = useFrame()
  const local = useFlowStore()
  const clientBookings = usePrototype(s => s.clientBookings)
  const vouchers = usePrototype(s => s.vouchers)

  // The request just sent (the player), else the story request (a static frame): same ids, same quote, same voucher.
  const sentBooking = live && local.sentId ? clientBookings.find(b => b.id === local.sentId) : undefined
  const story = mock.heroBookingAs('pending')
  const base = sentBooking ?? story
  const urgentFrame = state === 'urgent-event'
  const booking = urgentFrame ? { ...base, slaHours: mock.meta.config.urgentReplyHours, respondBy: addHoursIso(base.createdAt, mock.meta.config.urgentReplyHours) } : base
  const voucher = vouchers.find(v => v.id === booking.voucherId) ?? mock.getVoucher(booking.voucherId)
  const target = mock.bookingTarget(booking)
  const venueName = bi(target.name)
  const section = booking.sections[0]
  const hall = section ? mock.getHall(section.hallId)?.hall : undefined
  const guests = booking.sections.reduce((n, s) => n + s.guests, 0) || booking.service?.quantity || 0
  const urgent = (booking.slaHours ?? 24) <= mock.meta.config.urgentReplyHours
  const offline = state === 'offline'
  const venueId = booking.venueId ?? undefined

  const exit = (tab: 'discover' | 'my-wedding', then?: { id: string; params?: Record<string, unknown> }) => leaveFlow(nav, tab, then)
  const promptNotifications = () => {
    useFlowStore.getState().set({ notifPrompted: true })
    nav.openSheet(
      <NotifPrompt
        onYes={() => {
          nav.closeSheet()
          nav.toast({ message: t('clientBookingSentNotifToast'), tone: 'success' })
        }}
        onNo={() => nav.closeSheet()}
      />,
      { title: t('clientBookingSentNotifTitle') },
    )
  }

  // The OS pre-prompt comes once, after the first request, a beat after the success moment (never at launch).
  useEffect(() => {
    if (!live || useFlowStore.getState().notifPrompted) return
    const id = window.setTimeout(promptNotifications, 2200)
    return () => window.clearTimeout(id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live])

  const showPlanner = !local.plannerDismissed

  return (
    <Screen
      top={<TopBar back="close" backLabel={tc('commonActionClose')} onBack={() => exit('discover')} rule={false} />}
      bottom={
        // While the notification sheet is open the pinned bar steps aside: one gold primary on screen, the sheet's.
        state === 'notification-pre-prompt' ? undefined : (
          <ActionBar
            secondary={{ label: tc('commonActionMessage'), onPress: () => leaveFlow(nav, 'messages', { id: 'CL-MSGS-02', params: { venueId } }) }}
            action={{ label: t('clientBookingSentView'), onPress: () => exit('my-wedding', { id: 'CL-BKNG-02', params: { bookingId: booking.id } }) }}
          />
        )
      }
      bodyClassName="bk-sent-body"
    >
      {offline ? (
        <div className="bk-sent-notice">
          <Banner tone="offline" shape="card">{t('clientBookingSentOffline')}</Banner>
        </div>
      ) : null}

      <SuccessHero illustration="success-request" id="bk-sent-title" title={t('clientBookingSentTitle')} dataGz="SentHero">
        <BookingThread booking={booking} onDark pop="request" draw="mount" />
      </SuccessHero>

      <section className="bk-section bk-sent-summary" aria-label={t('clientBookingSentTitle')}>
        <div className="bk-sent-head">
          <h2 className="bk-sent-head__name gz-t-d1">
            <Auto>{venueName}</Auto>
          </h2>
          <InfoButton title={t('clientBookingSentInfoTitle')}>
            <p>{t('clientBookingSentBody', { venue: venueName, count: mock.meta.config.confirmWindowHours })}</p>
            <p>{t('clientBookingSentWithdraw')}</p>
          </InfoButton>
        </div>
        <FactRow>
          <FactChip icon="calendar" label={t('clientBookingSentDate')} value={f.date(booking.eventDate, 'compact')} />
          {hall ? <FactChip icon="hall" label={t('clientBookingSentHall')} value={<Auto>{bi(hall.name)}</Auto>} /> : null}
          {guests ? <FactChip icon="users-three" label={t('clientBookingSentGuests')} value={f.integer(guests)} /> : null}
        </FactRow>
        <FactRow>
          <FactChip icon="ticket" label={t('clientBookingSentVoucherPrice')} value={<Figures text={f.money(booking.totals.voucherTotal.fils, { mode: 'exact' })} />} tone="accent" />
          <FactChip icon="document" label={t('clientBookingSentReference')} value={<Ltr className="gz-t-fig-body-s">{booking.ref}</Ltr>} tone="muted" />
          {urgent ? <FactChip icon="timer" label={t('clientBookingReplyFast')} value={tc('commonCountHours', { count: booking.slaHours ?? mock.meta.config.urgentReplyHours })} tone="accent" /> : null}
          {state === 'date-held-chip' ? <FactChip icon="calendar-check" label={t('clientBookingSentHeldLong')} value={t('clientBookingSentHeld')} tone="accent" /> : null}
        </FactRow>
        {voucher ? (
          <div data-gz-id="booking.sent.voucher">
            <IconListRow
              flush
              last
              icon="ticket"
              title={<Ltr className="gz-t-fig-body">{voucher.code}</Ltr>}
              chevron
              onClick={() => exit('my-wedding', { id: 'CL-VCHR-03', params: { voucherId: voucher.id } })}
            />
          </div>
        ) : null}
      </section>

      {showPlanner ? (
        <section className="bk-section bk-section--tight" aria-label={t('clientBookingPlannerTitle')}>
          <PlannerOffer
            onYes={() => exit('my-wedding', { id: 'CL-PLAN-01', params: { from: 'booking', venueId, date: booking.eventDate } })}
            onNo={() => local.set({ plannerDismissed: true })}
          />
        </section>
      ) : null}

      <section className="bk-section bk-leave" aria-label={tc('commonActionClose')}>
        <Button variant="tertiary" iconStart="home" onClick={() => exit('discover')}>
          {t('clientBookingSentDiscover')}
        </Button>
        <Button variant="tertiary" iconStart="heart" onClick={() => exit('my-wedding')}>
          {t('clientBookingSentWedding')}
        </Button>
      </section>

      {state === 'notification-pre-prompt' ? (
        <Sheet title={t('clientBookingSentNotifTitle')} onRequestClose={() => undefined}>
          <NotifPrompt onYes={() => undefined} onNo={() => undefined} />
        </Sheet>
      ) : null}
    </Screen>
  )
}
