// CL-PAYM-05 · Voucher ready (ADR 0033). The success of the KD 2 payment: the voucher with its single-use code and QR, what it is bound to,
// how long it is valid and the one next step. Requirements: CA-BOOK-13, CA-NOTI-07, CA-VCH-05, CA-VCH-07, CA-VCH-14. ADR 0017 (the 640 ms
// success token, no confetti). The booking-confirmed celebration is CL-BOOK-09, not here.
//
// Text diet (ADR 0034): an ink panel drawn up to the top edge (the transparent bar's close glyph sits on it; title under the glyph, the one
// drawing at inline-end, so the QR and the code start high and are on screen without scrolling), then the voucher
// ticket (a system component, already figures and glyphs), the saving as a fact with the info glyph that holds the voucher terms (what
// happens if the request is declined, and the late-payment note), then three icon rows (My vouchers, Receipt, Message). One primary
// action, pinned: Send request, which opens the booking flow prefilled from the voucher (CL-BOOK-01).
//
// states  voucher-ready (default), voucher-ready-late-payment (the money arrived after the checkout ended), offline, provider
import { ActionBar, Banner, FactChip, FactRow, IconListRow, Icon, Illustration, InfoButton, Screen, TopBar, VoucherCard, useNav } from '../../../system'
import { flat } from '@gz/tokens'
import { useDevice } from '../../../shell/device/context'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { providerSampleVoucher, targetFromVoucher } from './_components/data'
import { Fx } from './_components/Fx'
import { useIssued } from './_components/usePurchase'
import { useSceneState } from './_components/useScene'
import './CL-PAYM-05.css'

export const states = ['voucher-ready-late-payment', 'offline', 'provider']

export default function PaymentVoucherReady() {
  const t = useT('client-payment')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { safeTop } = useDevice()
  const state = useSceneState()

  const params = nav.params as { late?: unknown; depth?: unknown }
  const issued = useIssued()
  const voucher = state === 'provider' ? providerSampleVoucher() : issued.voucher
  const target = targetFromVoucher(voucher)
  const late = state === 'voucher-ready-late-payment' || params.late === true
  const offline = state === 'offline'
  const depth = typeof params.depth === 'number' ? params.depth : 2

  // ---- navigation (inventory edges)
  /** Close returns to the venue or provider the voucher is for. */
  const goDone = () => (nav.canGoBack ? nav.pop(depth) : nav.push(target.detailId, target.kind === 'provider' ? { providerId: target.targetId, vendorId: target.targetId } : { venueId: target.targetId }))
  const sendRequest = () => {
    // The booking flow opens prefilled from the voucher: the draft already holds its quote and the voucher id.
    usePrototype.getState().patchDraft({
      targetType: target.kind,
      venueId: target.kind === 'venue' ? target.targetId : null,
      providerId: target.kind === 'provider' ? target.targetId : null,
      hallId: target.hallId,
      packageId: target.packageId,
      eventDate: target.eventDate,
      guests: target.guests,
      voucherId: voucher.id,
    })
    nav.push('CL-BOOK-01', {
      voucherId: voucher.id,
      venueId: target.kind === 'venue' ? target.targetId : undefined,
      providerId: target.kind === 'provider' ? target.targetId : undefined,
      date: target.eventDate,
      hallId: target.hallId ?? undefined,
      guests: target.guests ?? undefined,
    })
  }
  const receipt = () => nav.push('CL-BKNG-05', { voucherId: voucher.id, receipt: voucher.payment?.receiptNo })
  const myVouchers = () => nav.push('CL-VCHR-02', { voucherId: voucher.id })
  const message = () => nav.push('CL-MSGS-02', target.kind === 'provider' ? { providerId: target.targetId, vendorId: target.targetId } : { venueId: target.targetId })
  const copy = () => {
    try {
      void navigator.clipboard?.writeText(voucher.code)
    } catch {
      /* the toast is the confirmation either way */
    }
    nav.toast({ message: tc('commonStateCopied'), tone: 'success', icon: 'check-circle' })
  }

  const paid = voucher.payment
  const receiptDate = paid ? f.date(paid.at.slice(0, 10), 'compact') : undefined

  return (
    <Screen
      topOverlay
      top={<TopBar variant="transparent" back="close" onBack={goDone} backLabel={tc('commonActionClose')} solidAfter={96} />}
      bottom={<ActionBar action={{ label: t('clientPaymentDoneCta'), onPress: sendRequest }} />}
    >
      <section className="pm-hero gz-on-dark" style={{ ['--pm-top' as string]: `${safeTop + flat['space.2']}px` }} aria-labelledby="pm-done-title" data-gz-id="hero">
        <h1 id="pm-done-title" className="pm-hero__title gz-t-d2">
          {t('clientPaymentDoneTitle')}
        </h1>
        <span className="pm-hero__art">
          <Illustration name="success-voucher" size="lg" tone="on-dark" />
        </span>
      </section>

      <div className="pm-page">
        {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
        {late ? (
          <Banner tone="info" icon="clock">
            {t('clientPaymentDoneLate')}
          </Banner>
        ) : null}

        <div className="pm-card" data-gz-id="voucher">
          <VoucherCard voucher={voucher} onCopy={copy} />
        </div>

        <div className="pm-terms-row" data-gz-id="means">
          <FactRow label={t('clientPaymentLabelSaving')}>
            {target.savingsFils > 0 ? <FactChip icon="offer" label={t('clientPaymentLabelSaving')} value={<Fx text={t('clientPaymentSave', { amount: f.money(target.savingsFils, { mode: 'browse' }) })} />} /> : null}
          </FactRow>
          <InfoButton title={t('clientPaymentTermsTitle')} label={t('clientPaymentTermsLabel')}>
            <p className="pm-info-p">{t('clientPaymentDoneReuse')}</p>
            {late ? <p className="pm-info-p">{t('clientPaymentDoneLateNote')}</p> : null}
          </InfoButton>
        </div>

        <div className="pm-rows">
          <IconListRow flush icon="ticket" title={t('clientPaymentDoneRowVouchers')} onClick={myVouchers} />
          <IconListRow
            flush
            icon="receipt"
            title={t('clientPaymentDoneRowReceipt')}
            onClick={offline ? undefined : receipt}
            trailing={
              offline ? (
                <Icon name="offline" size="sm" tone="secondary" />
              ) : receiptDate ? (
                <FactChip icon="calendar" label={t('clientPaymentLabelDate')} value={<Fx text={receiptDate} />} size="sm" tone="muted" />
              ) : undefined
            }
          />
          <IconListRow flush icon="chat" title={tc('commonActionMessage')} onClick={message} last />
        </div>
      </div>
    </Screen>
  )
}
