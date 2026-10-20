// CL-VCHR-03 Voucher. Requirements: CA-VCH-07, CA-VCH-08, CA-VCH-11, CA-VCH-14, CA-STAT-13.
// One voucher: the ticket (the venue, what it is bound to, the code and QR the venue scans, how long it is valid, CA-VCH-07 and CA-VCH-08) under
// ONE phase strip that says what the voucher is doing now in a glyph, a word and facts (CA-VCH-11: why a released voucher is back and until when
// it can be used again, CA-STAT-13: pay the venue directly and show the code); the sentences are behind the strip's info glyph (voucher terms,
// the diet's exception) and an ended voucher gets a drawing. The saving is the headline figure of a ready voucher. History is a glyph, a word
// and a date per event; the paid event opens the receipt (CA-VCH-14). The one pinned action fits the state. The code is copyable and the QR opens
// full screen for the scanner; both are cached on the phone once the voucher is ready, so the venue can scan them offline.
// States: ready (default), in-request-pending, in-request-approved, in-request-confirmed, redeemed, released-reusable, expired,
// refunded, offline-cached, loading, error.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { ActionBar, Banner, Button, ErrorState, FactChip, FactRow, IconListRow, Screen, Skeleton, TopBar, VoucherCard, useNav } from '../../../system'
import { getVoucher, heroBookingAs, heroVoucherAs } from '../../../mock'
import type { Booking, Voucher } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { ConfirmLeft } from './_components/ConfirmLeft'
import { Fx } from './_components/Fx'
import { History } from './_components/History'
import { PhaseStrip, type PhaseStripProps } from './_components/PhaseStrip'
import { QrFull } from './_components/QrFull'
import { Saving } from './_components/Saving'
import { Terms } from './_components/Terms'
import { copyCode, useMethodName, useWhy } from './_components/copy'
import { useVc } from './_components/useVc'
import {
  STORY_EXPIRED_CODE,
  STORY_REFUNDED_CODE,
  STORY_RELEASED_CODE,
  openRequest,
  optionsOf,
  phaseOf,
  readyVariantOf,
  replyHoursOf,
  settled,
  storyVoucher,
  useBookingLookup,
  useFactsOfVoucher,
  useLive,
  useSceneState,
} from './_components/model'
import './CL-VCHR-03.css'

export const states = ['in-request-pending', 'in-request-approved', 'in-request-confirmed', 'redeemed', 'released-reusable', 'expired', 'refunded', 'offline-cached', 'loading', 'error']

type Scene = { voucher: Voucher; booking: Booking | null }

/** The voucher and request each state frame draws, straight from the fixtures (nothing invented, only the story voucher in its ready form). */
function frameScene(state: string | undefined): Scene {
  const hero = (variant: 'pending' | 'approved' | 'confirmed' | 'redeemed'): Scene => ({ voucher: heroVoucherAs(variant), booking: heroBookingAs(variant) })
  switch (state) {
    case 'in-request-pending':
      return hero('pending')
    case 'in-request-approved':
      return hero('approved')
    case 'in-request-confirmed':
      return hero('confirmed')
    case 'redeemed':
      return hero('redeemed')
    case 'released-reusable':
      return { voucher: getVoucher(STORY_RELEASED_CODE) ?? storyVoucher(), booking: null }
    case 'expired':
      return { voucher: getVoucher(STORY_EXPIRED_CODE) ?? storyVoucher(), booking: null }
    case 'refunded':
      return { voucher: getVoucher(STORY_REFUNDED_CODE) ?? storyVoucher(), booking: null }
    default:
      return { voucher: readyVariantOf(storyVoucher()), booking: null }
  }
}

export default function VoucherDetail() {
  const { t, tc, money, dayMon } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const stored = usePrototype(s => s.vouchers)
  const lookup = useBookingLookup()
  const why = useWhy()
  const method = useMethodName()

  const scene: Scene = (() => {
    if (state && state !== 'loading' && state !== 'error' && state !== 'offline-cached') return frameScene(state)
    if (!live) return frameScene(undefined)
    const id = nav.params.voucherId
    const v = stored.find(x => x.id === id || x.code === id) ?? stored.find(x => x.code === storyVoucher().code) ?? storyVoucher()
    return { voucher: v, booking: lookup(v) }
  })()
  const v = settled(scene.voucher)
  const booking = scene.booking
  const facts = useFactsOfVoucher(v)
  const phase = phaseOf(v, booking)
  const saving = Math.max(0, v.quoteFils.standard - v.quoteFils.voucher)
  const fee = money(v.priceFils)
  const options = optionsOf(v)

  const top = <TopBar back title={t('clientVouchersDetailTitle')} />

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-VCHR-03', nav.params)} />
      </Screen>
    )
  }
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzv-detail" aria-busy="true" data-gz-id="detail.loading">
          <Skeleton variant="block" blockSize={72} />
          <Skeleton variant="block" blockSize={380} />
          <Skeleton variant="line" blockSize={24} inlineSize={220} />
        </div>
      </Screen>
    )
  }

  // ---- actions
  const copy = () => {
    copyCode(v.code)
    nav.toast({ message: t('clientVouchersCodeCopied'), tone: 'success', icon: 'check-circle' })
  }
  const showFull = () => {
    nav.openSheet(<QrFull voucher={v} onClose={() => nav.closeSheet()} />)
  }
  const viewRequest = () => booking && nav.push('CL-BKNG-02', { bookingId: booking.id })
  const refund = () => nav.openSheet('CL-VCHR-05', { params: { voucherId: v.id } })
  const refundButton = (
    <Button variant="tertiary" iconStart="undo" onClick={refund}>
      {t('clientVouchersRefundFee', { fee })}
    </Button>
  )

  // ---- the phase strip: a glyph or a drawing, a word, facts, the paragraph behind (i)
  const info = (title: string, ...paragraphs: string[]): PhaseStripProps['info'] => ({
    title,
    body: paragraphs.map(p => <p key={p}>{p}</p>),
  })
  let strip: ReactNode
  switch (phase) {
    case 'ready':
      strip = (
        <PhaseStrip info={{ title: t('clientVouchersTermsTitle'), body: <Terms name={facts.name} replyHours={replyHoursOf(v.targetType, v.venueOrProviderId)} /> }}>
          {saving > 0 ? <Saving fils={saving} /> : null}
        </PhaseStrip>
      )
      break
    case 'pending':
      strip = <PhaseStrip illustration="envelope" tone="pending" title={t('clientVouchersPhaseWaiting')} info={info(t('clientVouchersInfoRequest'), t('clientVouchersInfoWaiting', { name: facts.name }))} />
      break
    case 'approved':
      strip = booking?.confirmBy ? <ConfirmLeft deadline={booking.confirmBy} /> : <PhaseStrip icon="calendar-check" tone="pending" title={tc('commonStatusApproved')} info={info(t('clientVouchersInfoWindow'), t('clientVouchersWindowBody'))} />
      break
    case 'confirmed':
      strip = <PhaseStrip icon="receipt" tone="success" title={t('clientVouchersPhaseDirect')} info={info(t('clientVouchersInfoPay'), t('clientVouchersPayBody', { name: facts.name }))} />
      break
    case 'redeemed':
      strip = <PhaseStrip illustration="seal" tone="success" title={tc('commonVoucherStatusUsed')} />
      break
    case 'consumed':
      strip = <PhaseStrip illustration="hourglass" title={t('clientVouchersPhaseUsedUp')} info={info(t('clientVouchersInfoUsedUp'), t('clientVouchersUsedUpBody'))} />
      break
    case 'released': {
      const reason = why(v.releaseReason, facts.name)
      strip = (
        <PhaseStrip
          icon={reason.icon}
          tone="pending"
          title={reason.word}
          info={info(t('clientVouchersInfoBack'), reason.sentence, options.refundable ? t('clientVouchersBackRefundable', { date: v.reuseUntil ? dayMon(v.reuseUntil) : '', fee }) : t('clientVouchersBackKept', { date: v.reuseUntil ? dayMon(v.reuseUntil) : '' }))}
          actions={options.refundable ? refundButton : undefined}
        >
          {v.reuseUntil ? (
            <FactRow>
              <FactChip icon="calendar" label={t('clientVouchersLabelReuse')} value={<Fx text={dayMon(v.reuseUntil)} />} tone="accent" />
            </FactRow>
          ) : null}
        </PhaseStrip>
      )
      break
    }
    case 'expired':
      strip = (
        <PhaseStrip
          illustration="hourglass"
          title={tc('commonVoucherStatusExpired')}
          info={info(tc('commonVoucherStatusExpired'), t('clientVouchersExpiredBody', { date: dayMon((v.validUntil ?? '').slice(0, 10)) }), ...(v.refundEligible ? [t('clientVouchersExpiredRefundable', { fee })] : []))}
          actions={v.refundEligible ? refundButton : undefined}
        />
      )
      break
    case 'refunded':
      strip = (
        <PhaseStrip illustration="card" title={tc('commonVoucherStatusRefunded')} info={info(t('clientVouchersRefund'), t('clientVouchersRefundedBody', { fee, method: method(v) }))}>
          <FactRow>
            <FactChip icon="coins" label={t('clientVouchersRefund')} value={money(v.priceFils)} />
          </FactRow>
        </PhaseStrip>
      )
      break
    default:
      strip = <PhaseStrip icon="hourglass" tone="pending" title={tc('commonVoucherStatusUnpaid')} info={info(t('clientVouchersInfoPaying'), t('clientVouchersPayingBody'))} />
  }

  const withQr = phase === 'ready' || phase === 'released' || phase === 'confirmed'

  const primary =
    phase === 'ready' || phase === 'released'
      ? { label: phase === 'released' ? t('clientVouchersUseAgain') : t('clientVouchersSendRequest'), onPress: () => openRequest(nav, v) }
      : phase === 'pending' || phase === 'approved'
        ? { label: t('clientVouchersViewRequest'), onPress: viewRequest }
        : phase === 'confirmed'
          ? { label: t('clientVouchersShowCode'), onPress: showFull, iconEnd: 'qr-code' as IconName }
          : null

  return (
    <Screen top={top} bottom={primary ? <ActionBar action={primary} /> : undefined}>
      {state === 'offline-cached' ? <Banner tone="offline">{t('clientVouchersOfflineSaved')}</Banner> : null}
      <div className="gzv-detail" data-gz-id="detail" data-phase={phase}>
        {strip}

        <VoucherCard voucher={v} variant={withQr ? 'full' : 'compact'} onCopy={withQr ? copy : undefined} onShowFull={withQr ? showFull : undefined} />

        <div className="gzv-detail__hist">
          <History voucher={v} booking={booking} onReceipt={() => nav.push('CL-BKNG-05', { voucherId: v.id })} />
        </div>

        <div className="gzv-detail__links">
          <IconListRow flush last chevron icon="headset" title={t('clientVouchersSupport')} onClick={() => nav.push('CL-MSGS-02', { support: true })} />
        </div>
      </div>
    </Screen>
  )
}
