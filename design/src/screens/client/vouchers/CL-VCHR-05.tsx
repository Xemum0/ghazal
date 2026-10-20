// CL-VCHR-05 Use again or ask support (sheet). Requirements: CA-VCH-11, CA-VCH-14, CA-VCH-05.
// What happened to a released voucher and what can be done with it (ADR 0035 D5): the venue and why it is back as a glyph and one word (the
// sentence behind the info glyph, ADR 0034), then two equal choices: use it again at the same venue until a date, or ask support for a credit
// voucher (venue-fault releases only). Asking support is one confirm step and then the support chat opens with the request already written;
// no money goes back and the sheet promises nothing. A client-caused release offers the reuse only (the reason is behind the info glyph); a
// voucher used up by a cancellation after confirming offers nothing, with a drawing. Once support has answered, the sheet shows the outcome:
// credit issued (opens the credit voucher) or not issued.
// States: reuse-or-refund (default), reuse-only, consumed-no-refund, request-confirm, request-sent, credit-granted, request-declined, offline, error.
import { useState, type ReactNode } from 'react'
import { Banner, Button, EmptyState, ErrorState, FactChip, FactRow, Illustration, SheetFooter, useNav } from '../../../system'
import { getRefundRequest, getVoucher } from '../../../mock'
import type { RefundRequest, Voucher } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { ChoiceRow } from './_components/ChoiceRow'
import { Fx } from './_components/Fx'
import { SheetTop } from './_components/SheetTop'
import { Thumb } from './_components/Thumb'
import { useWhy } from './_components/copy'
import { useVc } from './_components/useVc'
import { STORY_CREDIT_ISSUED_CODE, STORY_RELEASED_CODE, openRequest, optionsOf, readyVariantOf, settled, storyVoucher, useFactsOfVoucher, useLive, useSceneState } from './_components/model'
import './_components/explainer.css'
import './CL-VCHR-05.css'

export const states = ['reuse-only', 'consumed-no-refund', 'request-confirm', 'request-sent', 'credit-granted', 'request-declined', 'offline', 'error']

type Phase = 'choose' | 'confirm'

// Fixture vouchers that stand for each state frame (all real seed rows).
const CODE = { reuseOnly: 'GV-2611-AVG0', consumed: 'GV-2609-FPNA', granted: STORY_CREDIT_ISSUED_CODE } as const

function frameVoucher(state: string | undefined): Voucher {
  const code = state === 'reuse-only' ? CODE.reuseOnly : state === 'consumed-no-refund' ? CODE.consumed : state === 'credit-granted' ? CODE.granted : STORY_RELEASED_CODE
  return getVoucher(code) ?? readyVariantOf(storyVoucher())
}

export default function UseAgainOrAskSupport() {
  const { t, tc, dayMon } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const stored = usePrototype(s => s.vouchers)
  const why = useWhy()

  const source: Voucher = (() => {
    if (live && (state === undefined || state === 'offline' || state === 'error')) {
      const id = nav.params.voucherId
      return stored.find(x => x.id === id || x.code === id) ?? stored.find(x => x.code === STORY_RELEASED_CODE) ?? frameVoucher(undefined)
    }
    const f = frameVoucher(state)
    // The two frames with no seed row: a request just sent, and one support answered with a no.
    return state === 'request-sent' || state === 'request-declined' ? { ...f, refundRequestId: `rr-frame-${state}` } : f
  })()
  const v = settled(source)
  const facts = useFactsOfVoucher(v)
  const options = optionsOf(v)

  const asked: RefundRequest | undefined = v.refundRequestId ? getRefundRequest(v.refundRequestId) : undefined
  const declined = state === 'request-declined' || asked?.status === 'declined'
  const granted = v.status === 'credit_issued'
  const sent = Boolean(v.refundRequestId) && !granted && !declined
  const [phase, setPhase] = useState<Phase>(state === 'request-confirm' ? 'confirm' : 'choose')
  const offline = state === 'offline'

  const close = () => nav.closeSheet()
  const reuse = () => {
    nav.closeSheet()
    openRequest(nav, v)
  }
  /** The request is a message in the support chat, written for the client to send; the voucher is marked as asked about. */
  const openChat = (record: boolean) => {
    if (offline) return
    if (record && live) usePrototype.getState().askSupportCredit(v.id)
    nav.closeSheet()
    nav.push('CL-MSGS-02', { support: true, draft: t('clientVouchersAskText', { code: `⁦${v.code}⁩` }) })
  }

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
  const reuseOnly = state === 'reuse-only' || !options.creditEligible
  const sheetInfo = (extra?: ReactNode) => ({
    title: t('clientVouchersInfoBack'),
    body: (
      <>
        <p>{reason.sentence}</p>
        {extra}
      </>
    ),
  })
  const frame = (dataState: string, body: ReactNode, top?: ReactNode) => (
    <div className="gzv-sheet" data-gz-id="refund.sheet" data-state={dataState}>
      {top ?? <SheetTop title={t('clientVouchersAskTitle')} />}
      {body}
    </div>
  )

  if (state === 'error') {
    return frame('error', <ErrorState kind="load" fill={false} onRetry={() => nav.replace('CL-VCHR-05', nav.params)} />)
  }

  // ---- a voucher used up by a cancellation: nothing to do, and why (behind the info glyph)
  if (v.status === 'used') {
    return frame(
      'consumed-no-refund',
      <>
        <EmptyState illustration="hourglass" title={t('clientVouchersPhaseUsedUp')} detail={t('clientVouchersConsumedBody', { name: facts.name })} detailTitle={t('clientVouchersInfoUsedUp')} fill={false} size="lg" />
        <SheetFooter>
          <Button variant="secondary" fullWidth onClick={close}>
            {tc('commonActionDone')}
          </Button>
        </SheetFooter>
      </>,
    )
  }

  // ---- support has answered: a credit voucher was issued
  if (granted) {
    const creditId = asked?.creditVoucherId
    return frame(
      'credit-granted',
      <>
        <div className="gzv-done" data-gz-id="done">
          <Illustration name="success-payment" size="lg" />
          <h3 className="gzv-done__title gz-t-d2">{tc('commonVoucherStatusCreditIssued')}</h3>
          <FactRow>
            <FactChip icon="globe" label={tc('commonVoucherAnyVenue')} value={tc('commonVoucherCredit')} tone="muted" />
            {asked?.decidedAt ? <FactChip icon="calendar" label={tc('commonVoucherStatusCreditIssued')} value={<Fx text={dayMon(asked.decidedAt.slice(0, 10))} />} tone="muted" /> : null}
          </FactRow>
        </div>
        <SheetFooter>
          {creditId ? (
            <Button
              variant="primary"
              fullWidth
              onClick={() => {
                close()
                nav.push('CL-VCHR-03', { voucherId: creditId })
              }}
            >
              {tc('commonVoucherCredit')}
            </Button>
          ) : null}
        </SheetFooter>
      </>,
    )
  }

  // ---- support has said no, or the request is waiting: the chat is the way on
  if (declined || sent) {
    return frame(
      declined ? 'request-declined' : 'request-sent',
      <>
        <div className="gzv-done" data-gz-id="done">
          <Illustration name={declined ? 'hourglass' : 'envelope'} size="lg" />
          <h3 className="gzv-done__title gz-t-d2">{declined ? t('clientVouchersCreditDeclined') : tc('commonCreditRequested')}</h3>
        </div>
        <SheetFooter>
          <Button variant="primary" fullWidth iconStart="headset" onClick={() => { close(); nav.push('CL-MSGS-02', { support: true }) }}>
            {t('clientVouchersAskOpen')}
          </Button>
          {declined && options.reusable ? (
            <Button variant="secondary" fullWidth onClick={reuse}>
              {t('clientVouchersUseAgain')}
            </Button>
          ) : null}
        </SheetFooter>
      </>,
    )
  }

  // ---- confirm: the request is written in the support chat for the client to send
  if (phase === 'confirm') {
    return frame(
      'request-confirm',
      <>
        {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
        <div className="gzv-confirm" data-gz-id="confirm">
          <Illustration name="envelope" size="lg" />
          <h3 className="gzv-done__title gz-t-d2">{tc('commonAskSupport')}</h3>
        </div>
        <SheetFooter>
          <Button variant="primary" fullWidth iconStart="headset" onClick={() => openChat(true)} disabled={offline}>
            {t('clientVouchersAskOpen')}
          </Button>
          <Button variant="tertiary" fullWidth onClick={() => setPhase('choose')}>
            {tc('commonActionBack')}
          </Button>
        </SheetFooter>
      </>,
      <SheetTop title={t('clientVouchersAskTitle')} info={sheetInfo()} />,
    )
  }

  // ---- the two choices
  return frame(
    state ?? 'reuse-or-refund',
    <>
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {plate}
      <div className="gzv-choices" data-gz-id="choices">
        <ChoiceRow
          icon="ticket"
          title={t('clientVouchersUseAgain')}
          facts={
            v.reuseUntil ? (
              <FactRow>
                <FactChip icon="calendar" label={t('clientVouchersLabelReuse')} value={<Fx text={dayMon(v.reuseUntil)} />} tone="muted" />
              </FactRow>
            ) : undefined
          }
          onPress={reuse}
          disabled={offline}
        />
        {reuseOnly ? null : <ChoiceRow icon="headset" title={tc('commonAskSupport')} onPress={() => setPhase('confirm')} disabled={offline} />}
      </div>
    </>,
    <SheetTop title={t('clientVouchersAskTitle')} info={sheetInfo(reuseOnly ? <p>{t('clientVouchersReuseOnly')}</p> : undefined)} />,
  )
}
