// CL-VCHR-02 My vouchers. Requirements: CA-VCH-06, CA-VCH-13, CA-PROF-12, CA-VCH-11.
// The wallet: every voucher the client holds, in three groups (Ready, In request, History) behind a glyph switch that names only the chosen one.
// Each voucher is a ticket (ADR 0034: no sentences): the venue (photograph or monogram), the event date as a fact, the saving as a figure
// (CA-VCH-06), the state as icon + one word, and under the perforation the ONE date that matters for it with the action that fits (Send request,
// or Use again and Ask support for a released voucher, CA-VCH-11). A voucher inside its last week shows that date in the gold ink (CA-VCH-13).
// Nothing swipes. The wallet works offline (codes and QR are cached on the phone).
// States: default, empty-ready, empty-history, expiring-soon, loading, error, offline.
import { useState } from 'react'
import { Banner, Button, EmptyState, ErrorState, IconSegmented, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { clock, engine, getRefundRequest } from '../../../mock'
import type { Voucher, WalletVoucher } from '../../../mock'
import { Ticket, type StubFact } from './_components/Ticket'
import { useVc } from './_components/useVc'
import {
  EXPIRING_DAYS,
  STORY_RELEASED_CODE,
  daysToEnd,
  endsOn,
  fixtureWallet,
  openRequest,
  optionsOf,
  segmentOf,
  useBookingLookup,
  useLive,
  useSceneState,
  useWallet,
  type Segment,
} from './_components/model'
import './CL-VCHR-02.css'

export const states = ['empty-ready', 'empty-history', 'expiring-soon', 'loading', 'error', 'offline']

export default function MyVouchers() {
  const { t, tc, dayMon, stamp } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const lookup = useBookingLookup()
  const stored = useWallet()
  const [segment, setSegment] = useState<Segment>(state === 'empty-history' ? 'history' : 'ready')

  // The static frames read the story client's vouchers from the fixtures; the player reads the store, so a voucher just bought is here.
  let wallet: WalletVoucher[] = live ? stored : fixtureWallet()
  if (state === 'empty-ready') wallet = []
  if (state === 'empty-history') wallet = wallet.filter(v => segmentOf(v) !== 'history')
  if (state === 'expiring-soon') wallet = wallet.map(v => (v.kind === 'bound' && v.code === STORY_RELEASED_CODE ? { ...v, reuseUntil: engine.addDays(clock.today(), 4) } : v))

  const top = <TopBar title={t('clientVouchersWalletTitle')} />

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-VCHR-02')} />
      </Screen>
    )
  }

  const shown = wallet.filter(v => segmentOf(v) === segment)

  const open = (v: WalletVoucher) => nav.push('CL-VCHR-03', { voucherId: v.id })
  const refund = (v: Voucher) => nav.openSheet('CL-VCHR-05', { params: { voucherId: v.id } })

  // The one fact under the perforation: the date that matters for this voucher's state, in the gold ink inside its last week.
  const stubOf = (v: WalletVoucher): StubFact | undefined => {
    const end = endsOn(v)
    const left = daysToEnd(v)
    const soon = left !== null && left <= EXPIRING_DAYS
    const tone = soon ? ('accent' as const) : ('muted' as const)
    if (v.status === 'active') {
      if (v.kind === 'bound' && v.reuseUntil) return { icon: soon ? 'timer' : 'undo', label: soon ? t('clientVouchersLabelExpires') : t('clientVouchersLabelReuse'), value: dayMon(v.reuseUntil), tone }
      return end ? { icon: soon ? 'timer' : 'hourglass', label: soon ? t('clientVouchersLabelExpires') : t('clientVouchersLabelValid'), value: dayMon(end), tone } : undefined
    }
    if (v.kind === 'credit') {
      if (v.status === 'used') return { icon: 'check-double', label: t('clientVouchersLabelUsed'), value: dayMon((v.usedAt ?? '').slice(0, 10)) }
      return { icon: 'clock-off', label: t('clientVouchersLabelExpired'), value: dayMon((v.validUntil ?? '').slice(0, 10)) }
    }
    if (v.status === 'bound') {
      const b = lookup(v)
      return b?.status === 'approved' && b.confirmBy ? { icon: 'timer', label: t('clientVouchersLabelConfirmBy'), value: stamp(b.confirmBy), tone: 'accent' } : undefined
    }
    if (v.status === 'used') return { icon: 'check-double', label: t('clientVouchersLabelUsed'), value: dayMon((v.usedAt ?? '').slice(0, 10)) }
    if (v.status === 'credit_issued') return { icon: 'gift', label: tc('commonVoucherStatusCreditIssued'), value: dayMon((getRefundRequest(v.refundRequestId ?? '')?.decidedAt ?? '').slice(0, 10)) }
    if (v.status === 'forfeited') return { icon: 'x-circle', label: tc('commonVoucherStatusForfeited'), value: dayMon((v.forfeitedAt ?? '').slice(0, 10)) }
    return { icon: 'clock-off', label: t('clientVouchersLabelExpired'), value: dayMon((v.validUntil ?? '').slice(0, 10)) }
  }

  const actionsOf = (v: WalletVoucher) => {
    if (v.status !== 'active') return undefined
    if (v.kind === 'credit') {
      return (
        <Button variant="secondary" onClick={() => nav.push('CL-DISC-03')}>
          {t('clientVouchersUseThis')}
        </Button>
      )
    }
    const released = Boolean(v.releaseReason || v.reuseUntil)
    const canRefund = released && optionsOf(v).creditEligible
    return (
      <>
        <Button variant="secondary" onClick={() => openRequest(nav, v)}>
          {released ? t('clientVouchersUseAgain') : t('clientVouchersSendRequest')}
        </Button>
        {canRefund ? (
          <Button variant="tertiary" onClick={() => refund(v)}>
            {tc('commonAskSupport')}
          </Button>
        ) : null}
      </>
    )
  }

  const empty = {
    ready: { art: 'empty-vouchers' as const, title: t('clientVouchersEmptyReady'), action: { label: t('clientVouchersBrowseHalls'), variant: 'secondary' as const, iconStart: 'search' as const, onPress: () => nav.push('CL-DISC-03') } },
    request: { art: 'empty-bookings' as const, title: t('clientVouchersEmptyRequest'), action: undefined },
    history: { art: 'shelf' as const, title: t('clientVouchersEmptyHistory'), action: undefined },
  }[segment]

  return (
    <Screen top={top}>
      {state === 'offline' ? <Banner tone="offline">{t('clientVouchersOfflineSaved')}</Banner> : null}
      <div className="gzv-wallet" data-gz-id="wallet" aria-busy={state === 'loading' || undefined}>
        <IconSegmented<Segment>
          label={t('clientVouchersSegLabel')}
          value={segment}
          onChange={setSegment}
          options={[
            { value: 'ready', icon: 'ticket', label: t('clientVouchersSegReady') },
            { value: 'request', icon: 'send', label: t('clientVouchersSegRequest') },
            { value: 'history', icon: 'clock', label: t('clientVouchersSegHistory') },
          ]}
        />
        {state === 'loading' ? (
          <div className="gzv-wallet__list" data-gz-id="wallet.loading">
            {[0, 1].map(i => (
              <Skeleton key={i} variant="block" blockSize={176} />
            ))}
          </div>
        ) : shown.length === 0 ? (
          <EmptyState illustration={empty.art} title={empty.title} action={empty.action} fill={false} size="lg" />
        ) : (
          <div className="gzv-wallet__list" role="list">
            {shown.map(v => (
              <div key={v.id} role="listitem">
                <Ticket voucher={v} stub={stubOf(v)} actions={actionsOf(v)} onOpen={() => open(v)} />
              </div>
            ))}
          </div>
        )}
      </div>
    </Screen>
  )
}
