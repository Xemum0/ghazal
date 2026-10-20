// CL-BOOK-08 Confirm your booking (24 h). Covers CA-STAT-11, CA-STAT-12, CA-STAT-13, CA-VCH-08, CA-BOOK-17.
// Text diet (ADR 0034, hero screen): the official confirmation the owner requires within 24 hours of the venue's approval, as a clock and a
// summary of glyphs and figures. The title row says "Confirm" with the Approved status; the clock is a timer glyph and the absolute deadline, a gold
// bar of the time left and an hourglass figure (mm:ss only in the final 60 minutes). The summary is the date, the hall with its section and
// guests as glyphs, the package, the voucher price (ticket glyph) and the saving after the fee (trend-down glyph), the attached voucher. The
// sentences (nothing is paid here, confirming books the date, cancelling releases it, the terms) are two info glyphs: one beside the price, one
// beside the consent ("I agree"). Message the venue and View request are two glyphs in the bar. One gold action: Confirm booking.
// params: bookingId. Navigates to CL-BOOK-09 (done), CL-BOOK-10 (window ended or approval revoked), CL-BKNG-03, CL-VENU-05,
// CL-MSGS-02, CL-BKNG-02.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, Banner, Button, Checkbox, ErrorState, FactChip, FactRow, Figures, Icon, Illustration, InfoButton, Price, Screen, Sheet, StatusPill, TopBar, VoucherChip, useNav } from '../../../system'
import { Auto, Ltr, useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import * as mock from '../../../mock'
import { DateLine } from './_components/SentParts'
import { RequestPlate, TermsInfo } from './_components/ReviewParts'
import { StateNote } from './_components/StateNote'
import { AUDIENCE_GLYPH } from './_components/glyphs'
import { addSecondsIso, useFlowStore, useLive } from './_components/flow'
import { useRequest } from './_components/useRequest'
import { centerInBody } from './_components/centerInBody'
import { ConfirmClock } from './_components/ConfirmClock'
import './_components/step.css'
import './_components/review.css'
import './_components/confirm.css'

export const states = ['last-60-minutes', 'confirming', 'lapsed', 'date-taken', 'already-updated', 'error', 'offline']

type Params = { bookingId?: string }

const FINAL_MINUTES = 60
const HOSTING_KEY = { women: 'clientBookingHostingWomen', men: 'clientBookingHostingMen', mixed: 'clientBookingHostingMixed' } as const

/** Seconds left to the deadline, ticking once a second in the player (once a minute under reduced motion); static frames do not tick. */
function useSecondsLeft(deadline: string, live: boolean): number {
  const f = useFormat()
  const start = useRef(0)
  const [, tick] = useState(0)
  useEffect(() => {
    if (!live) return
    start.current = performance.now()
    const calm = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const id = window.setInterval(() => tick(n => n + 1), calm ? 60_000 : 1000)
    return () => window.clearInterval(id)
  }, [live])
  const elapsed = live ? performance.now() - start.current : 0
  return Math.max(0, Math.floor((new Date(deadline).getTime() - (f.now().getTime() + elapsed)) / 1000))
}

export default function ConfirmBooking() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav<Params>()
  const live = useLive()
  const { state } = useFrame()
  const local = useFlowStore()
  const confirmBooking = usePrototype(s => s.confirmBooking)
  const clientBookings = usePrototype(s => s.clientBookings)
  const [confirming, setConfirming] = useState(false)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  // The story request in the state the frame needs; in the player the request of the booking id (else the first approved one).
  const now = mock.clock.now()
  const story = mock.heroBookingAs(state === 'lapsed' ? 'lapsed' : 'approved')
  const lastFrame = state === 'last-60-minutes'
  const fallback = lastFrame ? { ...story, confirmBy: addSecondsIso(now, 47 * 60 + 12) } : story
  const approvedMine = clientBookings.find(b => b.status === 'approved')
  const req = useRequest(nav.params.bookingId ?? (live ? approvedMine?.id : undefined), fallback)
  const { booking, voucher } = req
  const deadline = booking.confirmBy ?? fallback.confirmBy ?? now
  const seconds = useSecondsLeft(deadline, live && !state)

  const lapsed = state === 'lapsed' || booking.status === 'expired' || (booking.status === 'approved' && seconds <= 0)
  const takenFrame = state === 'date-taken'
  const updatedFrame = state === 'already-updated'
  const offline = state === 'offline'
  const error = state === 'error'
  const loadingFrame = state === 'confirming'
  const final = lastFrame || (booking.status === 'approved' && seconds > 0 && seconds <= FINAL_MINUTES * 60)
  const consent = loadingFrame ? true : live ? local.confirmConsent : false
  const blocked = lapsed || takenFrame || offline
  const section = booking.sections[0]

  // In the player a window that has ended goes straight to the screen that offers what to do next (a new request).
  useEffect(() => {
    if (live && !state && lapsed) nav.replace('CL-BOOK-10', { bookingId: booking.id, reason: 'lapsed' })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live, state, lapsed])

  const openTerms = () => nav.openSheet('CL-VENU-05', { params: { venueId: req.venueId, segment: 'terms' } })
  const toEnded = (reason: 'lapsed' | 'revoked' | 'date_taken') => nav.replace('CL-BOOK-10', { bookingId: booking.id, reason })
  const updatedContent = (onAction: () => void) => (
    <div className="bk-updated" data-gz="UpdatedSheet">
      <Illustration name="hourglass" size="lg" />
      <Button variant="primary" fullWidth onClick={onAction}>
        {t('clientBookingUpdatedAction')}
      </Button>
    </div>
  )
  const updated = () =>
    nav.openSheet(
      updatedContent(() => {
        nav.closeSheet()
        toEnded('revoked')
      }),
      { title: t('clientBookingUpdatedTitle') },
    )

  const toConsent = () => {
    const el = document.querySelector<HTMLElement>('[data-gz-id="booking.confirm.consent"]')
    centerInBody(el ?? null, window.matchMedia('(prefers-reduced-motion: reduce)').matches)
    el?.focus({ preventScroll: true })
    nav.toast({ message: t('clientBookingConfirmReasonConsent'), tone: 'neutral' })
  }

  const confirm = () => {
    if (lapsed) return toEnded('lapsed')
    if (takenFrame) return toEnded('date_taken')
    if (!consent) return toConsent()
    if (blocked || confirming) return
    setConfirming(true)
    timer.current = window.setTimeout(() => {
      setConfirming(false)
      if (live && req.inStore) {
        // R08 inside the window: the hold becomes a booking. A window that ended meanwhile releases the voucher (R09).
        if (booking.status !== 'approved') return updated()
        if (!confirmBooking(booking.id)) return toEnded('lapsed')
      }
      nav.replace('CL-BOOK-09', { bookingId: booking.id })
    }, live ? 900 : 0)
  }

  return (
    <Screen
      top={
        <TopBar
          title={<bdi dir="auto">{req.targetName}</bdi>}
          back="auto"
          actions={[
            { icon: 'chat', label: tc('commonActionMessage'), onPress: () => nav.push('CL-MSGS-02', { venueId: req.venueId }) },
            { icon: 'document', label: t('clientBookingConfirmViewRequest'), onPress: () => nav.push('CL-BKNG-02', { bookingId: booking.id }) },
          ]}
          rule={false}
        />
      }
      bottom={
        // The pinned bar steps aside while the "request updated" sheet is open (one gold primary on screen, the sheet's) and on the load
        // error (its state carries the one retry).
        updatedFrame || error ? undefined : (
          <ActionBar
            secondary={lapsed ? undefined : { label: t('clientBookingConfirmCancel'), onPress: () => nav.push('CL-BKNG-03', { bookingId: booking.id }) }}
            action={{
              label: lapsed ? t('clientBookingEndedNew') : takenFrame ? t('clientBookingConfirmSeeNext') : t('clientBookingConfirmAction'),
              onPress: confirm,
              loading: confirming || loadingFrame,
              // Offline says so in the banner above; a caption under the primary would stretch the Cancel button beside it.
              disabled: offline,
            }}
          />
        )
      }
      bodyClassName="bk-body"
    >
      {offline ? <Banner tone="offline" shape="card">{t('clientBookingConfirmOffline')}</Banner> : null}
      <header className="bk-head">
        <h2 className="bk-head__title gz-t-d3">{t('clientBookingConfirmHeading')}</h2>
        <span className="bk-head__status">
          <StatusPill status={lapsed ? 'expired' : 'approved'} />
        </span>
      </header>

      {error ? (
        <div className="bk-section">
          <ErrorState kind="load" fill={false} />
        </div>
      ) : (
        <>
          {takenFrame ? (
            <div className="bk-notice bk-notice--flush">
              <StateNote tone="danger" icon="calendar-x">{t('clientBookingDateTakenBanner', { date: f.date(booking.eventDate, 'short') })}</StateNote>
            </div>
          ) : null}
          {lapsed ? (
            <section className="bk-section bk-section--tight" aria-label={t('clientBookingConfirmWindowLabel')}>
              <FactRow>
                <FactChip icon="clock-off" label={t('clientBookingConfirmLapsedLabel')} value={<Figures text={f.dateTime(deadline, 'short')} />} tone="muted" />
              </FactRow>
            </section>
          ) : (
            <section className="bk-section bk-section--tight" aria-label={t('clientBookingConfirmWindowLabel')}>
              <ConfirmClock deadline={deadline} seconds={seconds} final={final} />
            </section>
          )}

          <section className="bk-section bk-confirm-sum" aria-label={t('clientBookingConfirmSummary')}>
            <DateLine date={booking.eventDate} />
            {req.cover && req.hallName ? (
              // The same hall plate the Review closes with: the photograph says which room, the glyphs say how many and for whom.
              <RequestPlate
                cover={req.cover}
                hallName={req.hallName}
                facts={
                  <>
                    {section ? <FactChip icon={AUDIENCE_GLYPH[section.audience]} label={t(HOSTING_KEY[section.audience])} /> : null}
                    {req.guests ? <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(req.guests)} /> : null}
                  </>
                }
              />
            ) : (
              <FactRow>
                {req.hallName ? <FactChip icon="hall" label={t('clientBookingSentHall')} value={<Auto>{req.hallName}</Auto>} /> : null}
                {section ? <FactChip icon={AUDIENCE_GLYPH[section.audience]} label={t(HOSTING_KEY[section.audience])} /> : null}
                {req.guests ? <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(req.guests)} /> : null}
              </FactRow>
            )}
            {req.packageName ? <FactRow><FactChip icon="package" label={t('clientBookingReviewPackage')} value={<Auto>{req.packageName}</Auto>} /></FactRow> : null}
            <div className="bk-confirm-price">
              <div className="bk-confirm-price__main">
                <Icon name="ticket" size="md" tone="success" />
                <span className="gz-sr-only">{t('clientBookingSentVoucherPrice')}</span>
                <Price fils={booking.totals.voucherTotal.fils} mode="exact" size="total" />
                <InfoButton title={t('clientBookingConfirmPayTitle')}>
                  <p>{t('clientBookingConfirmPay')}</p>
                </InfoButton>
              </div>
              <span className="bk-confirm-save gz-t-body-s" data-gz-id="saving">
                <Icon name="trend-down" size="sm" tone="success" mirror={false} />
                <span className="gz-sr-only">{t('clientBookingConfirmSaveNet')}</span>
                <span aria-hidden="true">
                  <Figures text={f.money(booking.totals.netSavings, { mode: 'exact' })} />
                </span>
              </span>
            </div>
            {voucher ? (
              <div className="bk-confirm-voucher" data-gz-id="booking.confirm.voucher">
                <VoucherChip code={voucher.code} tone="bound" />
                <FactChip icon="document" label={t('clientBookingSentReference')} value={<Ltr className="gz-t-fig-caption">{booking.ref}</Ltr>} size="sm" tone="muted" />
              </div>
            ) : null}
          </section>

          {lapsed || takenFrame ? null : (
            <section className="bk-section bk-consent" aria-label={t('clientBookingConsentRead')}>
              <Checkbox checked={consent} onChange={v => live && local.set({ confirmConsent: v })} data-gz-id="booking.confirm.consent">
                {t('clientBookingConsent')}
              </Checkbox>
              <TermsInfo
                body={
                  <>
                    <p>{t('clientBookingConfirmConsentBody')}</p>
                    <p>{t('clientBookingConfirmNoteCancel')}</p>
                  </>
                }
                onRead={openTerms}
              />
            </section>
          )}
        </>
      )}

      {updatedFrame ? (
        <Sheet title={t('clientBookingUpdatedTitle')} onRequestClose={() => undefined}>
          {updatedContent(() => undefined)}
        </Sheet>
      ) : null}
    </Screen>
  )
}
