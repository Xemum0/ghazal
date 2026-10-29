// CL-BOOK-05 Review (step 4 of 4): the voucher-bound request summary, the last screen before the request goes to the venue.
// Covers CA-BOOK-09, CA-BOOK-10, CA-BOOK-14, CA-BOOK-17, CA-VDET-16, CA-VCH-08, CA-VCH-09.
// Text diet (ADR 0034, hero screen): no lead, no section words, no sentences. The request plate (photograph, hall, section / guests / session as
// glyph facts), three rows with a glyph, one line and a chevron (date, package, contact: each opens its step to edit), the itemised
// price in both columns (the voucher total large with the standard total struck and the saving as a chip, the same composition as a package
// card; the sentence about the fee and the venue payment behind its info glyph), the attached voucher as a ticket card (with no voucher, the
// "Voucher first" panel is the first thing on the screen, not a panel below the fold), what happens next as four glyph knots with the reply
// time and confirm window as facts (the one place the future of the flow is told: one word under each knot, because a seal, a calendar check
// and a QR are ambiguous alone and the alternative is a paragraph), and the consent as "I agree" with the legal sentence behind an info glyph
// (Read the terms is a button inside it). One gold action: "Send request" with the voucher total beside it.
// Nothing more to pay Ghazal; after the venue approves and the client confirms, the client pays the venue directly (ADR 0033).
// Navigates to CL-BOOK-06, CL-VCHR-01, CL-VCHR-04, CL-BOOK-07, CL-VENU-05, CL-AUTH-02, CL-BKNG-01, CL-BOOK-01, CL-BOOK-02, CL-BOOK-04 (Edit).
import { useEffect, useRef, useState } from 'react'
import { Banner, Checkbox, ErrorState, FactChip, Figures, IconListRow, InfoButton, Skeleton, useBi, useNav } from '../../../system'
import { Phone, useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import * as mock from '../../../mock'
import { BarTotal } from './_components/BarTotal'
import { QuoteLines } from './_components/QuoteLines'
import { NextThread, RequestPlate, TermsInfo, VoucherAttach } from './_components/ReviewParts'
import { StateNote } from './_components/StateNote'
import { StepScreen } from './_components/StepScreen'
import { VoucherNeed } from './_components/VoucherNeed'
import { useVoucherActions } from './_components/voucherActions'
import { AUDIENCE_GLYPH, sessionGlyph } from './_components/glyphs'
import { addHoursIso, goStep, quotePair, tabRoot, useContact, useFlow, useFlowStore, useLive, useScenario } from './_components/flow'
import { centerInBody } from './_components/centerInBody'
import './_components/step.css'
import './_components/review.css'
import './CL-BOOK-05.css'

export const states = ['voucher-missing', 'consent-unchecked', 'phone-unverified', 'open-requests-limit', 'loading', 'error', 'offline']

const SCENARIO: Record<string, string> = {
  'voucher-missing': 'novoucher',
  'open-requests-limit': 'limit',
}

const HOSTING_KEY = { women: 'clientBookingHostingWomen', men: 'clientBookingHostingMen', mixed: 'clientBookingHostingMixed' } as const

export default function Review() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const live = useLive()
  const { state } = useFrame()
  const flow = useFlow(useScenario(state, SCENARIO))
  const contact = useContact()
  const local = useFlowStore()
  const draft = usePrototype(s => s.bookingDraft)
  const { getVoucher, changeVoucher } = useVoucherActions(flow, 'CL-BOOK-05')
  const [sending, setSending] = useState(false)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const unverified = state === 'phone-unverified' || (live && !contact.verified)
  const limited = flow.openRequests >= mock.meta.config.maxOpenRequests
  const consent = state === 'consent-unchecked' ? false : live ? local.consent : true
  const quote = flow.quote
  const pair = quotePair(quote)
  const voucher = flow.voucher
  const venueName = bi(flow.venue.name)
  const first = flow.sections[0]!
  const uneconomic = Boolean(voucher && quote && !quote.voucherEligible)

  // ---- movement
  const edit = (step: 1 | 2 | 3) => (voucher && step <= 2 ? changeVoucher() : goStep(nav, 4, step))
  const openTerms = () => nav.openSheet('CL-VENU-05', { params: { venueId: flow.venue.id, segment: 'terms' } })
  const openVerify = () =>
    nav.openSheet('CL-AUTH-02', {
      params: { presentation: 'sheet', reason: 'send-request' },
      onClose: () => useFlowStore.getState().set({ verifiedPhone: contact.phone }),
    })
  const openTaken = () => nav.openSheet('CL-BOOK-07', { params: { reason: 'date_taken', venueId: flow.venue.id, date: flow.date, from: 'CL-BOOK-05' } })

  // ---- the one action
  const blockedReason = offline
    ? tc('commonStateOffline')
    : limited
      ? t('clientBookingReasonLimit')
      : !voucher
        ? t('clientBookingReasonVoucher')
        : uneconomic
          ? t('clientBookingVoucherUneconomic')
          : unverified
            ? t('clientBookingReasonPhone')
            : !consent
              ? t('clientBookingReasonConsent')
              : undefined

  // A tap on a CTA blocked only by consent is not dead: it brings the consent row into view and says why.
  const consentOnly = !offline && !limited && Boolean(voucher) && !uneconomic && !unverified && !consent && !error
  const toConsent = () => {
    const el = document.querySelector<HTMLElement>('[data-gz-id="booking.consent"]')
    const calm = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    centerInBody(el ?? null, calm)
    el?.focus({ preventScroll: true })
    if (blockedReason) nav.toast({ message: blockedReason, tone: 'neutral' })
  }

  const send = () => {
    if (consentOnly) return toConsent()
    if (blockedReason || sending) return
    if (!flow.dateOk) return openTaken()
    setSending(true)
    timer.current = window.setTimeout(() => {
      if (live && voucher) {
        // R01: the request goes at the voucher price and binds the voucher; no money and no calendar claim move.
        const id = usePrototype.getState().sendRequest(voucher.id, { audience: flow.audience, sessionId: first.sessionId, hallId: first.hall.id, packageId: first.effective?.pkg.id ?? null })
        if (!id) {
          setSending(false)
          nav.toast({ message: t('clientBookingSendFailed'), tone: 'danger' })
          return
        }
        useFlowStore.getState().set({ sentId: id })
        // The request is sent: the steps behind it are history. The outcome goes on top of Discover, so Back never lands inside a finished request.
        nav.reset(tabRoot('discover'))
        nav.push('CL-BOOK-06')
        return
      }
      nav.replace('CL-BOOK-06')
    }, live ? 900 : 0)
  }

  // ---- facts for the rows
  const session = first.sessions.find(x => x.id === first.sessionId)
  const dateParts = f.dateWithHijri(flow.date)
  const requests = (live ? draft.requests : (mock.heroBookingAs('pending').specialRequests ?? '')).trim()
  const replyBy = f.dateTime(addHoursIso(mock.clock.now(), flow.slaHours), 'short')

  // No voucher yet: the one thing the request waits for is the first thing on the screen, not a panel below the fold.
  const needAtTop = !voucher && !limited && !offline && !loading && !error && Boolean(quote)

  const notice = offline ? (
    <Banner tone="offline" shape="card">{t('clientBookingOfflineBanner')}</Banner>
  ) : limited ? (
    <div className="bk-notice">
      <StateNote
        icon="clipboard"
        action={{ label: t('clientBookingLimitAction'), onPress: () => nav.push('CL-BKNG-01') }}
        info={{ title: t('clientBookingLimitInfoTitle'), body: <p>{t('clientBookingLimitInfo')}</p> }}
      >
        {t('clientBookingLimitBanner', { count: f.integer(flow.openRequests), max: f.integer(mock.meta.config.maxOpenRequests) })}
      </StateNote>
    </div>
  ) : needAtTop ? (
    <div className="bk-notice">
      <VoucherNeed onGet={getVoucher} />
    </div>
  ) : unverified && voucher ? (
    <div className="bk-notice">
      <StateNote icon="whatsapp" action={{ label: t('clientBookingPhoneVerify'), onPress: openVerify }}>
        {t('clientBookingPhoneBanner')}
      </StateNote>
    </div>
  ) : uneconomic ? (
    <div className="bk-notice">
      <StateNote tone="danger" icon="warning-circle" info={{ title: t('clientBookingVoucherCardTitle'), body: <p>{t('clientBookingVoucherUneconomicInfo')}</p> }}>
        {t('clientBookingVoucherUneconomic')}
      </StateNote>
    </div>
  ) : null

  return (
    <StepScreen
      step={4}
      venueName={venueName}
      title={t('clientBookingReviewTitle')}
      notice={notice}
      bar={
        error
          ? null
          : {
              summaryValue: pair ? <BarTotal fils={pair.total} icon={pair.has ? 'ticket' : 'coins'} label={pair.has ? t('clientBookingVoucherTotalLabel') : tc('commonMoneyTotal')} /> : undefined,
              action: {
                label: t('clientBookingSend'),
                onPress: send,
                loading: loading || sending,
                disabled: !consentOnly && Boolean(blockedReason),
                // The offline banner above says why; the others (limit, voucher, phone) keep their short reason.
                reason: !consentOnly && !offline ? blockedReason : undefined,
              },
            }
      }
    >
      {error ? (
        <div className="bk-section">
          <ErrorState kind="load" fill={false} />
        </div>
      ) : loading || !quote ? (
        <div className="bk-section bk-rv-skel" aria-busy="true">
          <Skeleton blockSize={88} />
          {[0, 1, 2].map(i => (
            <div key={i} className="bk-rv-skel__row">
              <Skeleton inlineSize={160} blockSize={24} />
              <Skeleton blockSize={20} />
            </div>
          ))}
          <Skeleton blockSize={160} />
        </div>
      ) : (
        <>
          <section className="bk-section bk-section--tight">
            <RequestPlate
              cover={first.hall.cover ?? flow.venue.cover}
              hallName={bi(first.hall.name)}
              facts={
                <>
                  <FactChip icon={AUDIENCE_GLYPH[first.audience]} label={t(HOSTING_KEY[first.audience])} />
                  <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(first.guests)} />
                  {session ? <FactChip icon={sessionGlyph(session.start)} label={bi(session.name)} /> : null}
                </>
              }
            />
          </section>

          <section className="bk-section bk-rv-blocks" aria-label={t('clientBookingReviewTitle')}>
            <IconListRow
              flush
              icon="calendar"
              title={<Figures text={dateParts.primary} />}
              facts={f.lang === 'ar' && dateParts.secondary ? <Figures text={dateParts.secondary} /> : undefined}
              chevron
              onClick={() => edit(1)}
            />
            <IconListRow
              flush
              icon="package"
              title={<Figures text={first.effective ? bi(first.effective.pkg.name) : ''} />}
              autoDir
              chevron
              onClick={() => edit(2)}
            />
            <IconListRow
              flush
              icon="user"
              title={<bdi dir="auto">{contact.name}</bdi>}
              facts={
                <>
                  {contact.phone ? <FactChip icon="phone" label={t('clientBookingPhoneLabel')} value={<Phone value={contact.phone} />} size="sm" tone="muted" /> : null}
                  {local.forWho === 'other' && local.otherName ? <FactChip icon="user-plus" label={t('clientBookingForOther')} value={<bdi dir="auto">{local.otherName}</bdi>} size="sm" tone="muted" /> : null}
                </>
              }
              chevron
              onClick={() => edit(3)}
              last={!requests}
            />
            {requests ? (
              <IconListRow flush last icon="notes" title={<bdi dir="auto" className="gz-clamp-3 bk-rv-note">{requests}</bdi>} chevron onClick={() => edit(3)} />
            ) : null}
          </section>

          <section className="bk-section bk-rv-price" aria-label={t('clientBookingPriceTitle')}>
            <div className="bk-rv-head">
              <h3 className="bk-rv-head__title gz-t-title">{t('clientBookingPriceTitle')}</h3>
              <InfoButton title={t('clientBookingPriceTitle')}>
                <p>{t('clientBookingReviewPriceNote')}</p>
                <p>{t('clientBookingNextVenueNote', { venue: venueName })}</p>
              </InfoButton>
            </div>
            <QuoteLines quote={quote} />
          </section>

          {voucher || !needAtTop ? (
            <section className="bk-section bk-section--tight" aria-label={t('clientBookingVoucherCardTitle')}>
              {voucher ? <VoucherAttach voucher={voucher} onChange={changeVoucher} /> : <VoucherNeed onGet={getVoucher} />}
            </section>
          ) : null}

          <section className="bk-section bk-rv-plan" aria-label={t('clientBookingNextTitle')}>
            <NextThread replyBy={replyBy} confirmHours={mock.meta.config.confirmWindowHours} />
          </section>

          <section className="bk-section bk-consent" aria-label={t('clientBookingConsentRead')}>
            <Checkbox checked={consent} onChange={v => live && local.set({ consent: v })} data-gz-id="booking.consent">
              {t('clientBookingConsent')}
            </Checkbox>
            <TermsInfo body={t('clientBookingConsentBody')} onRead={openTerms} />
          </section>
        </>
      )}
    </StepScreen>
  )
}
