// CL-BOOK-09 Booking confirmed: the one celebratory moment of the booking flow. Covers CA-BOOK-12, CA-STAT-13, CA-VCH-07, CA-TOOL-16,
// CA-TOOL-17, CA-PLAN-01, CA-NOTI-07.
// Text diet (ADR 0034, hero screen): the request is now a booking at the voucher price. One ink panel: the drawing (640 ms, no confetti), the
// outcome in two words and the Booking Thread with the Confirmation knot tying. Then the voucher as a slim ticket, QR and code first (the thing
// read at the venue; venue, date and prices are on this screen already), "Pay venue" with its sentence behind an info glyph, the date, hall
// and reference as glyph facts, the checklist as a glyph and a check, five glyphs to keep and use the booking (directions, call, message,
// calendar, share), "Book a visit", the planner offer
// once, and "Done". No sentences. params: bookingId. Navigates to CL-BKNG-02, CL-VCHR-03, CL-VIST-01, CL-PLAN-01, CL-WEDD-01, CL-MSGS-02.
import { ActionBar, BookingThread, Banner, Button, FactChip, FactRow, Icon, IconButton, IconListRow, ListRow, Screen, TopBar, VoucherCard, useNav } from '../../../system'
import { Auto, Ltr, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import * as mock from '../../../mock'
import { AsideInfo } from './_components/AsideInfo'
import { DateLine, PlannerOffer, SuccessHero } from './_components/SentParts'
import { leaveFlow, useFlowStore, useLive } from './_components/flow'
import { useRequest } from './_components/useRequest'
import './_components/step.css'
import './_components/sent.css'
import './_components/confirm.css'

export const states = ['offline', 'planner-card-seen']

type Params = { bookingId?: string }

/** Apple Maps is offered on iOS only (inventory); everywhere else the chooser lists Google Maps and Waze. */
const isIos = (): boolean => {
  try {
    return /iPhone|iPad|iPod/.test(navigator.userAgent)
  } catch {
    return false
  }
}

export default function BookingConfirmed() {
  const t = useT('client-booking')
  const tc = useT('common')
  const nav = useNav<Params>()
  const live = useLive()
  const { state } = useFrame()
  const local = useFlowStore()
  const wedding = usePrototype(s => s.weddingProfile)
  const req = useRequest(nav.params.bookingId, mock.heroBookingAs('confirmed'))
  const { booking, voucher } = req
  const venue = booking.venueId ? mock.getVenue(booking.venueId) : undefined
  const offline = state === 'offline'
  const showPlanner = state === 'planner-card-seen' ? false : !local.plannerDismissed
  const differs = Boolean(wedding && wedding.weddingDate !== booking.eventDate)

  const say = (key: Parameters<typeof t>[0]) => () => live && nav.toast({ message: t(key, { venue: req.targetName }), tone: 'success' })
  const exit = (tab: 'discover' | 'my-wedding', then?: { id: string; params?: Record<string, unknown> }) => leaveFlow(nav, tab, then)

  const directions = () =>
    nav.openSheet(
      <div className="bk-maps" data-gz="DirectionsChooser">
        <ListRow flush chevron leading={<Icon name="map" size="md" />} title={t('clientBookingMapsGoogle')} onClick={() => { nav.closeSheet(); say('clientBookingMapsToast')() }} />
        {isIos() ? <ListRow flush chevron leading={<Icon name="navigate" size="md" />} title={t('clientBookingMapsApple')} onClick={() => { nav.closeSheet(); say('clientBookingMapsToast')() }} /> : null}
        <ListRow flush last chevron leading={<Icon name="pin" size="md" />} title={t('clientBookingMapsWaze')} onClick={() => { nav.closeSheet(); say('clientBookingMapsToast')() }} />
      </div>,
      { title: t('clientBookingMapsTitle') },
    )

  return (
    <Screen
      top={<TopBar back="close" backLabel={tc('commonActionClose')} onBack={() => exit('my-wedding')} rule={false} />}
      bottom={
        <ActionBar
          secondary={{ label: t('clientBookingDoneView'), onPress: () => exit('my-wedding', { id: 'CL-BKNG-02', params: { bookingId: booking.id } }) }}
          action={{ label: tc('commonActionDone'), onPress: () => exit('my-wedding') }}
        />
      }
      bodyClassName="bk-sent-body"
    >
      {offline ? (
        <div className="bk-sent-notice">
          <Banner tone="offline" shape="card">{t('clientBookingSentOffline')}</Banner>
        </div>
      ) : null}

      <SuccessHero illustration="success-booking" id="bk-done-title" title={t('clientBookingDoneHeading')} dataGz="ConfirmedHero">
        <BookingThread booking={booking} onDark pop="confirmation" draw="mount" />
      </SuccessHero>

      <section className="bk-section bk-section--tight" aria-label={t('clientBookingDoneVoucherTitle')}>
        {voucher ? (
          <VoucherCard
            variant="slim"
            voucher={voucher}
            onCopy={() => live && nav.toast({ message: t('clientBookingDoneCopied'), tone: 'success' })}
            onShowFull={() => nav.push('CL-VCHR-03', { voucherId: voucher.id })}
          />
        ) : null}
        <AsideInfo icon="receipt" word={t('clientBookingDonePayWord')} title={t('clientBookingDonePayTitle')}>
          <p data-gz-id="booking.done.instruction">{t('clientBookingDonePay', { venue: req.targetName })}</p>
        </AsideInfo>
      </section>

      <section className="bk-section bk-sent-summary" aria-label={t('clientBookingDoneHeading')}>
        <DateLine date={booking.eventDate} />
        <FactRow>
          {req.hallName ? <FactChip icon="hall" label={t('clientBookingSentHall')} value={<Auto>{req.hallName}</Auto>} /> : null}
          <FactChip icon="document" label={t('clientBookingSentReference')} value={<Ltr className="gz-t-fig-body-s">{booking.ref}</Ltr>} tone="muted" />
          <FactChip icon="checklist" label={t('clientBookingDoneChecklist')} value={<Icon name="check" size="xs" tone="success" />} tone="muted" />
        </FactRow>
        {differs ? (
          <Button
            variant="tertiary"
            iconStart="calendar-check"
            onClick={() => {
              usePrototype.getState().patchWeddingProfile({ weddingDate: booking.eventDate, dateMode: 'exact' })
              if (live) nav.toast({ message: t('clientBookingDoneDateSet'), tone: 'success' })
            }}
          >
            {t('clientBookingDoneSetDate')}
          </Button>
        ) : null}
      </section>

      <section className="bk-section bk-section--tight" aria-label={t('clientBookingDoneActions')}>
        <div className="bk-quick">
          <IconButton variant="outline" icon="navigate" label={t('clientBookingDoneDirections')} onClick={directions} />
          <IconButton variant="outline" icon="phone" label={t('clientBookingDoneCall')} onClick={say('clientBookingDoneCalling')} />
          <IconButton variant="outline" icon="chat" label={tc('commonActionMessage')} onClick={() => exit('my-wedding', { id: 'CL-MSGS-02', params: { venueId: req.venueId } })} />
          <IconButton variant="outline" icon="calendar-plus" label={t('clientBookingDoneCalendar')} onClick={say('clientBookingDoneCalendarToast')} />
          <IconButton variant="outline" icon="share" label={tc('commonActionShare')} onClick={say('clientBookingDoneShared')} />
        </div>
        {venue ? <IconListRow flush last icon="door" title={t('clientBookingDoneVisit')} chevron onClick={() => nav.openSheet('CL-VIST-01', { params: { venueId: venue.id } })} /> : null}
      </section>

      {showPlanner ? (
        <section className="bk-section bk-section--tight" aria-label={t('clientBookingPlannerTitle')}>
          <PlannerOffer
            onYes={() => exit('my-wedding', { id: 'CL-PLAN-01', params: { from: 'booking', venueId: req.venueId, date: booking.eventDate } })}
            onNo={() => local.set({ plannerDismissed: true })}
          />
        </section>
      ) : null}
    </Screen>
  )
}
