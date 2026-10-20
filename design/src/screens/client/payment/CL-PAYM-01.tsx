// CL-PAYM-01 · Pay. The one payment a client makes inside Ghazal: KD 2.000 for a voucher bound to one venue or provider and its quote
// (ADR 0033). Requirements: CA-PAY-01, CA-PAY-02, CA-PAY-03, CA-PAY-04, CA-PAY-05, CA-VCH-05, CA-VCH-14. ADR 0027 (hosted gateway, no
// card form ever exists in Ghazal), ADR 0007 D8 (guests are gated at the pay tap, the quote is restored after sign-in).
//
// Text diet (ADR 0034): the screen speaks in a drawing, a figure and glyphs. Order: what the voucher is bound to (photo, name, hall or
// package, date, guests as icon + value), the amount under a voucher drawing with the saving and the checkout clock as facts (an absolute
// time; the mm:ss counter appears only in the last 60 seconds), the methods as three tiles in platform order (the glyph and wordmark are
// the label; what each one means in practice is behind the info glyph), the voucher in three glyphs (price, pay direct, voucher returns;
// the full explainer CL-VCHR-01 is behind the info glyph). One primary action, pinned and full width (the amount is already the hero figure
// above it, so the bar does not repeat it): Pay now, or View voucher when the client already holds one for this quote. Offline, while the
// session loads and once the checkout has ended, the method tiles and the action are locked in place (nothing moves, nothing is hidden); a
// failed session start is the centred Outcome with "Not charged". Dates, times and amounts that carry words go through Fx so Arabic reads in the right order. Tab bar hidden (payment flow).
//
// Inputs (route params, see _components/data.ts): { voucherId } or a quote { targetType, targetId, hallId?, packageId, eventDate, guests?,
// standardFils, voucherFils }; without either the hero story is shown. A failed attempt is read from the store, so Back from the outcome
// screen lands here with Apple Pay or a card suggested first.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, Banner, FactChip, FactRow, Illustration, InfoButton, Price, Screen, SectionHeader, Skeleton, TopBar, useBi, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { checkoutEnd, checkoutLastSecondsMs, checkoutMinutes, defaultMethod, heroVoucher, methodsFor, paramsOf, providerSampleTarget, purchaseOf, voucherFeeFils, type MethodKey } from './_components/data'
import { Fx } from './_components/Fx'
import { MethodTile } from './_components/MethodTile'
import { Outcome } from './_components/Outcome'
import { PayTimer, TermsStrip, VenuePlate } from './_components/parts'
import { usePurchase } from './_components/usePurchase'
import { useAfter, useDraw, useLive, usePlatform, useSceneState, useTick } from './_components/useScene'
import './CL-PAYM-01.css'

export const states = ['last-60-seconds', 'android', 'provider', 'has-voucher', 'loading-session', 'session-error', 'offline', 'checkout-expired']

/** What each method means in practice: the info glyph beside the methods opens the line of the selected one. */
const HONEST = {
  knet: 'clientPaymentHonestKnet',
  apple_pay: 'clientPaymentHonestWallet',
  google_pay: 'clientPaymentHonestWallet',
  card: 'clientPaymentHonestCard',
} as const

export default function PaymentPay() {
  const t = useT('client-payment')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const live = useLive()
  const draw = useDraw()
  const state = useSceneState()
  const platform = usePlatform()
  const store = usePrototype

  const auth = usePrototype(s => s.auth)
  const me = usePrototype(s => s.user?.id ?? null)
  const vouchers = usePrototype(s => s.vouchers)
  const lastPayment = usePrototype(s => s.payment)
  const purchase = usePurchase()
  const params = nav.params as { depth?: unknown }
  const depth = typeof params.depth === 'number' ? params.depth : 1

  // ---- what is being bought (frames force the variants; the player reads the quote it was given)
  const target = state === 'provider' ? providerSampleTarget() : purchase.target
  const isProvider = target.kind === 'provider'
  const fee = voucherFeeFils()

  // A voucher that already exists for exactly this quote: one voucher per booking, so offer it instead of a second payment.
  const existing =
    state === 'has-voucher'
      ? heroVoucher()
      : live && purchase.source !== 'hero'
        ? vouchers.find(v => v.clientId === me && (v.status === 'active' || v.status === 'bound') && v.venueOrProviderId === target.targetId && v.packageId === target.packageId && v.eventDate === target.eventDate)
        : undefined

  // After a failed KNET attempt the gateway suggests Apple Pay, Google Pay or a card first (ADR 0027).
  const afterFailure = live && lastPayment.kind === 'voucher' && lastPayment.outcome === 'failed' && lastPayment.method === 'knet'
  const methods = methodsFor({ platform, afterKnetFailure: afterFailure })
  const [method, setMethod] = useState<MethodKey>(defaultMethod(methods, afterFailure))
  const [busy, setBusy] = useState(false)
  const mounted = useRef(true)
  useEffect(() => {
    mounted.current = true
    return () => {
      mounted.current = false
    }
  }, [])

  const offline = state === 'offline'
  const loadingSession = state === 'loading-session'
  const sessionError = state === 'session-error'
  const ended = state === 'checkout-expired'

  // ---- the clock: an absolute "open until"; mm:ss only in the last 60 seconds. A checkout lasts the configured 30 minutes.
  const tick = useTick(live)
  const left = ended ? 0 : state === 'last-60-seconds' ? checkoutLastSecondsMs() : checkoutMinutes() * 60_000 - tick * 1000
  const showTimer = left <= 60_000
  const expired = left <= 0
  const until = f.time(checkoutEnd()).replace(/\s(?=\S+$)/, ' ')
  // An ended checkout goes to the one outcome layout; Back is always safe and nothing was charged.
  useAfter(ended ? 1400 : 0, () => nav.replace('CL-PAYM-04', { state: 'checkout-expired', voucherId: purchase.voucher?.id, ...paramsOf(target), depth: 1 }), expired || ended)

  const pay = () => {
    if (offline || expired || busy || existing) return
    if (auth === 'guest') {
      store.getState().openGate('voucher', { screenId: 'CL-PAYM-01', params: paramsOf(target) })
      nav.openSheet('CL-AUTH-01', { params: { reason: 'voucher' } })
      return
    }
    setBusy(true)
    // The store opens the checkout (an unpaid voucher with its quote) once; a retry reuses it, so nobody pays twice for one quote.
    const voucherId = purchase.voucher?.id ?? store.getState().startVoucherCheckout(purchaseOf(target))
    store.getState().beginPayment({ kind: 'voucher', refId: voucherId, amount: { fils: fee, currency: 'KWD' }, method })
    window.setTimeout(() => {
      if (mounted.current) setBusy(false)
      nav.push('CL-PAYM-02', { voucherId, method, attempt: 1, depth: depth + 1 })
    }, 900)
  }

  const howItWorks = () => nav.openSheet('CL-VCHR-01', { params: { ...paramsOf(target), from: 'pay' } })

  // ---- the facts of what the voucher is bound to, and of the amount
  const what = isProvider ? target.packageName : target.hallName
  const plateFacts = (
    <FactRow label={bi(target.name)}>
      {what ? <FactChip icon={isProvider ? 'package' : 'hall'} label={t(isProvider ? 'clientPaymentLabelPackage' : 'clientPaymentLabelHall')} value={bi(what)} size="sm" /> : null}
      <FactChip icon="calendar" label={t('clientPaymentLabelDate')} value={<Fx text={f.date(target.eventDate, 'compact')} />} size="sm" />
      {target.guests ? <FactChip icon="users-three" label={t('clientPaymentLabelGuests')} value={f.integer(target.guests)} size="sm" /> : null}
    </FactRow>
  )

  const offlineBanner = offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null

  return (
    <Screen
      top={<TopBar back title={t('clientPaymentTopTitle')} />}
      bottom={
        sessionError ? undefined : (
          <ActionBar
            action={
              existing
                ? { label: t('clientPaymentViewVoucher'), onPress: () => nav.push('CL-VCHR-03', { voucherId: existing.id }) }
                : { label: t('clientPaymentCtaPay'), onPress: pay, loading: busy && !loadingSession, disabled: offline || expired || ended || loadingSession }
            }
          />
        )
      }
    >
      {sessionError ? (
        <Outcome
          illustration="card"
          tone="danger"
          title={t('clientPaymentSessionErrorTitle')}
          meta={<FactChip icon="shield-check" label={t('clientPaymentNotChargedLabel')} value={t('clientPaymentNotCharged')} />}
          info={{ title: tc('commonLabelDetails'), body: t('clientPaymentSessionError') }}
          action={{ label: tc('commonActionRetry'), onPress: () => nav.replace('CL-PAYM-01', nav.params) }}
        />
      ) : (
        <>
          {offlineBanner}
          {ended ? (
            <div className="pm-banner">
              <Banner tone="warning" icon="hourglass">
                {t('clientPaymentExpiredBanner')}
              </Banner>
            </div>
          ) : null}
          {existing ? (
            <div className="pm-banner">
              <Banner tone="info" icon="ticket">
                {t('clientPaymentHasVoucherBanner')}
              </Banner>
            </div>
          ) : null}

          <div className="pm-page">
            <VenuePlate name={target.name} cover={target.cover} facts={plateFacts} />

            <section className="pm-amount" aria-label={t('clientPaymentAmountLabel')}>
              <div className="pm-amount__main">
                <div className="pm-amount__value" aria-busy={busy || undefined}>
                  <Price fils={fee} mode="exact" size="hero" />
                </div>
                <FactRow className="pm-amount__facts">
                  {target.savingsFils > 0 ? <FactChip icon="offer" label={t('clientPaymentLabelSaving')} value={<Fx text={t('clientPaymentSave', { amount: f.money(target.savingsFils, { mode: 'browse' }) })} />} /> : null}
                  {showTimer ? <PayTimer ms={Math.max(0, left)} /> : <FactChip icon="timer" label={t('clientPaymentLabelOpenUntil')} value={<Fx text={until} />} />}
                </FactRow>
              </div>
              <Illustration name="voucher" size="lg" />
            </section>

            <section className="pm-section" aria-labelledby="pm-methods-title">
              <div className="pm-sechead">
                <SectionHeader title={<span id="pm-methods-title">{t('clientPaymentMethodsTitle')}</span>} draw={draw} className="pm-sechead__title" />
                <InfoButton title={t('clientPaymentSecureTitle')}>{t(HONEST[method])}</InfoButton>
              </div>
              {loadingSession ? (
                <div className="pm-methods" aria-busy="true" data-gz-id="methods-loading">
                  {methods.map(m => (
                    <Skeleton key={m} variant="block" blockSize={88} />
                  ))}
                </div>
              ) : (
                <div className="pm-methods" role="radiogroup" aria-label={t('clientPaymentMethodsLabel')}>
                  {methods.map((m, i) => (
                    <MethodTile key={m} method={m} selected={method === m} onSelect={() => setMethod(m)} suggested={afterFailure && i === 0} disabled={busy || offline || expired || ended} />
                  ))}
                </div>
              )}
            </section>

            <TermsStrip
              items={[
                { icon: 'ticket', label: t('clientPaymentTermPrice') },
                { icon: isProvider ? 'package' : 'hall', label: t('clientPaymentTermDirect') },
                { icon: 'undo', label: t('clientPaymentTermReturns') },
              ]}
              infoLabel={t('clientPaymentHowLink')}
              onInfo={howItWorks}
            />
          </div>
        </>
      )}
    </Screen>
  )
}
