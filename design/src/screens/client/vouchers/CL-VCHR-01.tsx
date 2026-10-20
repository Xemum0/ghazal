// CL-VCHR-01 How it works (sheet). Requirements: CA-VCH-01, CA-VCH-02, CA-VCH-03, CA-VCH-04, CA-VCH-10, CA-VCH-12.
// The explainer and the binding confirmation, shown before the first purchase and on every Get voucher (ADR 0033, voucher-model 4.1 and 5.2).
// Text diet (ADR 0034): no paragraph on the sheet. The plate is the binding (venue, hall, package, date, the two prices and the saving, CA-VCH-02
// and CA-VCH-03); three knots say the model (pay KD 2 now, request at the voucher price, pay the venue directly, CA-VCH-01); one line with a
// returns glyph and its (i) carries the refund and reuse terms and the off-app payment (CA-VCH-01, the voucher-terms exception). ONE primary:
// Pay KD 2. A guest sees the same sheet with the voucher price behind a lock and Sign in as the primary (CA-VCH-04), returning to this quote.
// A voucher is never offered when the saving does not beat its price: a drawing, three words and Contact (CA-VCH-10, CA-VCH-12).
// States: default, guest-gated, already-owned, saving-too-small, quote-changed, loading, error, offline.
import { Banner, Button, EmptyState, ErrorState, Icon, InfoButton, SheetFooter, SuccessState, VoucherCard, useNav } from '../../../system'
import { meta } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { QuotePlate } from './_components/QuotePlate'
import { SheetTop } from './_components/SheetTop'
import { Steps } from './_components/Steps'
import { Terms } from './_components/Terms'
import { useVc } from './_components/useVc'
import {
  matchingReady,
  readyVariantOf,
  replyHoursOf,
  storyVoucher,
  targetOfQuote,
  useFactsOf,
  useLive,
  useQuote,
  useSceneState,
  useSignedIn,
  useWallet,
  type Quote,
} from './_components/model'
import './_components/explainer.css'
import './CL-VCHR-01.css'

export const states = ['guest-gated', 'already-owned', 'saving-too-small', 'quote-changed', 'loading', 'error', 'offline']

/** The params a screen below would need to open this sheet again with the same quote (the sign-in gate returns here). */
const paramsOf = (q: Quote) => ({ venueId: q.targetType === 'venue' ? q.targetId : undefined, providerId: q.targetType === 'provider' ? q.targetId : undefined, hallId: q.hallId ?? undefined, packageId: q.packageId, date: q.eventDate, guests: q.guests ?? undefined, audience: q.audience ?? undefined })

export default function VoucherExplainer() {
  const { t, tc, money } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const signedIn = useSignedIn()
  const wallet = useWallet()
  const quote = useQuote()
  const facts = useFactsOf(targetOfQuote(quote))

  const provider = quote.targetType === 'provider'
  const loading = state === 'loading'
  const offline = state === 'offline'
  const failed = state === 'error'
  const owned = state === 'already-owned' ? readyVariantOf(storyVoucher()) : live && signedIn ? matchingReady(wallet, quote) : undefined
  const tooSmall = state === 'saving-too-small' || !quote.offered
  const fee = money(meta.config.voucherFeeFils)
  const replyHours = replyHoursOf(quote.targetType, quote.targetId)

  // ---- actions
  const contact = () => {
    nav.closeSheet()
    nav.push('CL-MSGS-02', provider ? { vendorId: quote.targetId } : { venueId: quote.targetId })
  }
  const toPayment = () => {
    if (loading || offline || failed) return
    if (!signedIn) {
      // The quote travels with the gate: the draft keeps it, the gate remembers where to come back to (ADR 0007 D8).
      const store = usePrototype.getState()
      if (!provider) store.patchDraft({ venueId: quote.targetId, hallId: quote.hallId, packageId: quote.packageId, eventDate: quote.eventDate, guests: quote.guests, audience: quote.audience })
      store.openGate('voucher', { screenId: 'CL-VCHR-01', params: paramsOf(quote) })
      nav.closeSheet()
      nav.openSheet('CL-AUTH-01', { params: { reason: 'voucher' } })
      return
    }
    const id = live
      ? usePrototype.getState().startVoucherCheckout({
          targetType: quote.targetType,
          targetId: quote.targetId,
          hallId: quote.hallId,
          packageId: quote.packageId,
          eventDate: quote.eventDate,
          guests: quote.guests,
          standardFils: quote.standardFils,
          voucherFils: quote.voucherFils,
        })
      : null
    nav.closeSheet()
    nav.push('CL-PAYM-01', id ? { voucherId: id } : {})
  }
  const sendRequest = () => {
    if (!owned) return
    nav.closeSheet()
    nav.push('CL-BOOK-01', { venueId: quote.targetId, voucherId: owned.id, date: quote.eventDate, hallId: quote.hallId ?? undefined, guests: quote.guests ?? undefined })
  }
  const seeVoucher = () => {
    if (!owned) return
    nav.closeSheet()
    nav.push('CL-VCHR-03', { voucherId: owned.id })
  }

  // ---- saving too small: no voucher, no price talk, the way on is the venue
  if (tooSmall && !loading) {
    return (
      <div className="gzv-sheet" data-gz-id="explainer.sheet" data-state="saving-too-small">
        <SheetTop title={t('clientVouchersExplainerTitle')} />
        <QuotePlate quote={quote} facts={facts} signedIn={signedIn} noPrices />
        <EmptyState
          illustration="hall"
          title={t('clientVouchersTooSmallTitle')}
          detail={t('clientVouchersTooSmallBody')}
          detailTitle={t('clientVouchersTermsTitle')}
          fill={false}
          size="lg"
        />
        <SheetFooter>
          <Button variant="primary" fullWidth iconStart="chat" onClick={contact}>
            {t('clientVouchersContact')}
          </Button>
        </SheetFooter>
      </div>
    )
  }

  const primary = owned ? t('clientVouchersSendRequest') : signedIn ? t('clientVouchersPayFee', { fee }) : t('clientVouchersCtaSignIn')

  return (
    <div className="gzv-sheet" data-gz-id="explainer.sheet" data-state={state ?? 'default'} aria-busy={loading || undefined}>
      <SheetTop title={t('clientVouchersExplainerTitle')} />

      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {state === 'quote-changed' ? <Banner tone="info" shape="flush" icon="refresh">{t('clientVouchersPriceChanged')}</Banner> : null}

      {failed ? (
        <ErrorState kind="load" fill={false} onRetry={() => nav.replace('CL-VCHR-01', nav.params)} />
      ) : (
        <>
          {owned ? (
            <section className="gzv-owned" data-gz-id="owned">
              <SuccessState illustration="success-voucher" title={t('clientVouchersOwned')} fill={false} size="lg" />
              <VoucherCard voucher={owned} variant="compact" onOpen={seeVoucher} />
            </section>
          ) : (
            <QuotePlate quote={quote} facts={facts} signedIn={signedIn} loading={loading} />
          )}

          {owned ? null : (
            <>
              <div className="gzv-steps" data-gz-id="steps">
                <Steps fee={fee} provider={provider} />
              </div>
              <div className="gzv-back" data-gz-id="terms">
                <Icon name="undo" size="sm" tone="secondary" />
                <p className="gzv-back__line gz-t-body-s">{t('clientVouchersBackLine')}</p>
                <span className="gzv-back__info">
                  <InfoButton title={t('clientVouchersTermsTitle')}>
                    <Terms name={facts.name} replyHours={replyHours} />
                  </InfoButton>
                </span>
              </div>
            </>
          )}
        </>
      )}

      <SheetFooter>
        {failed ? null : (
          <Button variant="primary" fullWidth iconStart={signedIn ? undefined : 'lock'} onClick={owned ? sendRequest : toPayment} disabled={loading || offline}>
            {primary}
          </Button>
        )}
        {failed || owned ? null : (
          <div className="gzv-foot">
            <Button variant="tertiary" iconStart="chat" onClick={contact}>
              {t('clientVouchersContact')}
            </Button>
          </div>
        )}
      </SheetFooter>
    </div>
  )
}
