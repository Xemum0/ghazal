// CL-VCHR-05 Use or refund (sheet). Requirements: CA-VCH-11, CA-VCH-14, CA-VCH-05.
// What happened to a released voucher and what can be done with it (voucher-model 4.4): the venue and why it is back as a glyph and one word
// (the sentence behind the info glyph, ADR 0034), then two equal choices: use it again at the same venue until a date, or ask for the KD 2
// back to the original payment method (venue-fault releases only, CA-VCH-11). A client-caused release offers the reuse only (the reason there
// is no refund is behind the info glyph); a voucher consumed by a cancellation after confirming offers nothing, with a drawing. A refund asks
// for one confirmation (the figure, the method, the arrival as facts; it cannot be undone, so that caption stays), then shows its three knots
// and lands a credit note in Receipts (CA-VCH-14). Arrival times stay soft until the gateway confirms them (OQ-B-02).
// States: reuse-or-refund (default), reuse-only, consumed-no-refund, refund-confirm, refund-processing, refunded, refund-failed, offline, error.
import { useEffect, useRef, useState, type ReactNode } from 'react'
import { Banner, Button, EmptyState, ErrorState, FactChip, FactRow, Fig, Icon, IconProgress, Illustration, Price, SheetFooter, useNav } from '../../../system'
import { getVoucher } from '../../../mock'
import type { Voucher } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { ChoiceRow } from './_components/ChoiceRow'
import { Fx } from './_components/Fx'
import { SheetTop } from './_components/SheetTop'
import { Thumb } from './_components/Thumb'
import { useMethodName, useWhy } from './_components/copy'
import { useVc } from './_components/useVc'
import { STORY_RELEASED_CODE, openRequest, optionsOf, readyVariantOf, settled, storyVoucher, useFactsOfVoucher, useLive, useSceneState } from './_components/model'
import './_components/explainer.css'
import './CL-VCHR-05.css'

export const states = ['reuse-only', 'consumed-no-refund', 'refund-confirm', 'refund-processing', 'refunded', 'refund-failed', 'offline', 'error']

type Phase = 'choose' | 'confirm' | 'working' | 'done'

// Fixture vouchers that stand for each state frame (all real seed rows).
const CODE = { reuseOnly: 'GV-2611-AVG0', consumed: 'GV-2609-FPNA', processing: 'GV-2611-5P3A', refunded: 'GV-2610-H9XB' } as const

function frameVoucher(state: string | undefined): Voucher {
  const code = state === 'reuse-only' ? CODE.reuseOnly : state === 'consumed-no-refund' ? CODE.consumed : state === 'refund-processing' ? CODE.processing : state === 'refunded' ? CODE.refunded : STORY_RELEASED_CODE
  return getVoucher(code) ?? readyVariantOf(storyVoucher())
}

export default function UseAgainOrRefund() {
  const { t, tc, f, money, exact, dayMon, dayUnit } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const stored = usePrototype(s => s.vouchers)
  const why = useWhy()
  const method = useMethodName()

  const source: Voucher = (() => {
    if (live && (state === undefined || state === 'offline' || state === 'error')) {
      const id = nav.params.voucherId
      return stored.find(x => x.id === id || x.code === id) ?? stored.find(x => x.code === STORY_RELEASED_CODE) ?? frameVoucher(undefined)
    }
    return frameVoucher(state)
  })()
  const v = settled(source)
  const facts = useFactsOfVoucher(v)
  const options = optionsOf(v)
  const fee = money(v.priceFils)
  const methodName = method(v)

  const consumed = v.status === 'used'
  const refunded = v.status === 'refunded' || Boolean(v.refund)
  const initial: Phase = refunded || state === 'refund-processing' ? 'done' : state === 'refund-confirm' || state === 'refund-failed' ? 'confirm' : 'choose'
  const [phase, setPhase] = useState<Phase>(initial)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])
  const offline = state === 'offline'
  const failed = state === 'refund-failed'

  const reuseUntil = v.reuseUntil ? dayMon(v.reuseUntil) : ''

  // The arrival window as ONE LTR figure and the formatter's own day letter: KNET `1–3 d`, a card `≤10 d` (voucher-model 4.4, soft until OQ-B-02).
  const knet = (v.refund?.arrival ?? (v.payment?.method === 'knet' ? 'knet_1_3_days' : 'card_up_to_10_days')) === 'knet_1_3_days'
  const arrivalFigure = knet ? `${f.integer(1)}–${f.integer(3)}` : `≤${f.integer(10)}`
  const arrivalSentence = knet ? t('clientVouchersArrivalKnet', { from: 1, to: 3 }) : t('clientVouchersArrivalCard', { to: 10 })
  const arrivalFact = (
    <FactChip icon="hourglass" label={t('clientVouchersLabelArrival')} value={<Fig>{arrivalFigure}</Fig>} unit={dayUnit()} tone="muted" />
  )

  const close = () => nav.closeSheet()
  const reuse = () => {
    nav.closeSheet()
    openRequest(nav, v)
  }
  const confirmRefund = () => {
    if (offline) return
    setPhase('working')
    timer.current = window.setTimeout(
      () => {
        if (live) usePrototype.getState().refundVoucher(v.id)
        setPhase('done')
      },
      live ? 900 : 0,
    )
  }
  const support = () => nav.push('CL-MSGS-02', { support: true })

  // ---- the venue the voucher is bound to, and why it is back
  const reason = why(v.releaseReason, facts.name)
  const plate = (
    <div className="gzv-who" data-gz-id="who">
      <Thumb facts={facts} />
      <div className="gzv-who__text">
        <p className="gzv-who__name gz-t-d1" dir="auto">
          {facts.name}
        </p>
        <FactRow>
          <FactChip icon={reason.icon} label={reason.sentence} value={<Fx text={reason.word} />} tone="accent" />
        </FactRow>
      </div>
    </div>
  )
  const reuseOnly = state === 'reuse-only' || !options.refundable
  const sheetInfo = (extra?: ReactNode) => ({
    title: reuseOnly ? t('clientVouchersInfoNoRefund') : t('clientVouchersTermsTitle'),
    body: (
      <>
        <p>{reason.sentence}</p>
        {extra}
      </>
    ),
  })

  if (state === 'error') {
    return (
      <div className="gzv-sheet" data-gz-id="refund.sheet" data-state="error">
        <SheetTop title={t('clientVouchersRefundTitle')} />
        <ErrorState kind="load" fill={false} onRetry={() => nav.replace('CL-VCHR-05', nav.params)} />
      </div>
    )
  }

  // ---- a consumed voucher: nothing to do, and why (behind the info glyph)
  if (consumed && !refunded) {
    return (
      <div className="gzv-sheet" data-gz-id="refund.sheet" data-state="consumed-no-refund">
        <SheetTop title={t('clientVouchersRefundTitle')} />
        <EmptyState illustration="hourglass" title={t('clientVouchersPhaseUsedUp')} detail={t('clientVouchersConsumedBody', { name: facts.name })} detailTitle={t('clientVouchersInfoUsedUp')} fill={false} size="lg" />
        <SheetFooter>
          <Button variant="secondary" fullWidth onClick={close}>
            {tc('commonActionDone')}
          </Button>
        </SheetFooter>
      </div>
    )
  }

  // ---- a refund that has been asked for: where it is
  if (phase === 'done' && v.refund) {
    const completed = v.refund.status === 'completed'
    return (
      <div className="gzv-sheet" data-gz-id="refund.sheet" data-state={completed ? 'refunded' : 'refund-processing'}>
        <SheetTop
          title={t('clientVouchersRefund')}
          info={{
            title: t('clientVouchersRefund'),
            body: <p>{completed ? t('clientVouchersDoneBodyCompleted', { fee: exact(v.priceFils), method: methodName, date: dayMon((v.refund.completedAt ?? '').slice(0, 10)) }) : t('clientVouchersDoneBodySubmitted', { fee: exact(v.priceFils), method: methodName })}</p>,
          }}
        />
        <div className="gzv-done" data-gz-id="done">
          <Illustration name={completed ? 'success-payment' : 'card'} size="lg" />
          <h3 className="gzv-done__title gz-t-d2">{completed ? tc('commonVoucherStatusRefunded') : t('clientVouchersDoneSubmitted')}</h3>
          <FactRow>
            <FactChip icon="coins" label={t('clientVouchersRefund')} value={money(v.priceFils)} />
            {completed ? <FactChip icon="calendar" label={t('clientVouchersLabelRefunded')} value={<Fx text={dayMon((v.refund.completedAt ?? '').slice(0, 10))} />} tone="muted" /> : arrivalFact}
          </FactRow>
        </div>
        {completed ? null : (
          <IconProgress
            label={t('clientVouchersTrackLabel')}
            draw={false}
            steps={[
              { key: 'sent', icon: 'send', label: t('clientVouchersTrackSent'), state: 'tied' },
              { key: 'processing', icon: 'hourglass', label: t('clientVouchersTrackProcessing'), state: 'now' },
              { key: 'done', icon: 'check-circle', label: tc('commonStatusCompleted'), state: 'open' },
            ]}
          />
        )}
        <SheetFooter>
          <Button
            variant="primary"
            fullWidth
            iconStart="receipt"
            onClick={() => {
              nav.closeSheet()
              nav.push('CL-BKNG-05', { voucherId: v.id })
            }}
          >
            {t('clientVouchersViewReceiptShort')}
          </Button>
          <div className="gzv-foot">
            <Button
              variant="tertiary"
              iconStart="ticket"
              onClick={() => {
                nav.closeSheet()
                nav.push('CL-VCHR-02')
              }}
            >
              {t('clientVouchersWalletTitle')}
            </Button>
          </div>
        </SheetFooter>
      </div>
    )
  }

  // ---- the refund failed: nothing was taken, the way on is behind the info glyph
  if (failed) {
    return (
      <div className="gzv-sheet" data-gz-id="refund.sheet" data-state="refund-failed">
        <SheetTop title={t('clientVouchersRefund')} />
        {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
        <ErrorState
          kind="payment"
          title={t('clientVouchersRefundFailed')}
          body={t('clientVouchersRefundFailedBody')}
          onRetry={confirmRefund}
          secondary={{ label: t('clientVouchersSupport'), iconStart: 'headset', onPress: support }}
          fill={false}
        />
      </div>
    )
  }

  // ---- confirm the refund: the figure, the method and the arrival; it cannot be undone
  if (phase === 'confirm' || phase === 'working') {
    const busy = phase === 'working'
    return (
      <div className="gzv-sheet" data-gz-id="refund.sheet" data-state="refund-confirm" aria-busy={busy || undefined}>
        <SheetTop
          title={t('clientVouchersRefund')}
          info={{
            title: t('clientVouchersRefund'),
            body: (
              <>
                <p>{t('clientVouchersConfirmBody', { fee: exact(v.priceFils), method: methodName })}</p>
                <p>{arrivalSentence}</p>
              </>
            ),
          }}
        />
        {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
        <div className="gzv-confirm" data-gz-id="confirm">
          <Illustration name="card" size="lg" />
          <p className="gzv-confirm__figure" aria-label={t('clientVouchersRefundFee', { fee })}>
            <Price fils={v.priceFils} size="kpi" />
          </p>
          <FactRow>
            <FactChip icon="card" label={t('clientVouchersLabelMethod')} value={<Fx text={methodName} />} tone="muted" />
            {arrivalFact}
          </FactRow>
          <p className="gzv-confirm__note gz-t-caption">
            <Icon name="lock" size="xs" tone="secondary" />
            {t('clientVouchersConfirmNote')}
          </p>
        </div>
        <SheetFooter>
          <Button variant="primary" fullWidth loading={busy} onClick={confirmRefund} disabled={offline}>
            {t('clientVouchersConfirmCta')}
          </Button>
          <div className="gzv-foot">
            <Button variant="tertiary" onClick={() => setPhase('choose')} disabled={busy}>
              {t('clientVouchersKeep')}
            </Button>
          </div>
        </SheetFooter>
      </div>
    )
  }

  // ---- the two choices
  return (
    <div className="gzv-sheet" data-gz-id="refund.sheet" data-state={state ?? 'reuse-or-refund'}>
      <SheetTop title={t('clientVouchersRefundTitle')} info={sheetInfo(reuseOnly ? <p>{t('clientVouchersReuseOnly')}</p> : undefined)} />
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {plate}
      <div className="gzv-choices" data-gz-id="choices">
        <ChoiceRow
          icon="ticket"
          title={t('clientVouchersUseAgain')}
          facts={
            <FactRow>
              <FactChip icon="calendar" label={t('clientVouchersLabelReuse')} value={<Fx text={reuseUntil} />} tone="muted" />
            </FactRow>
          }
          onPress={reuse}
          disabled={offline}
        />
        {reuseOnly ? null : (
          <ChoiceRow
            icon="undo"
            title={t('clientVouchersRefundFee', { fee })}
            facts={<FactRow>{arrivalFact}</FactRow>}
            onPress={() => setPhase('confirm')}
            disabled={offline}
          />
        )}
      </div>
    </div>
  )
}
