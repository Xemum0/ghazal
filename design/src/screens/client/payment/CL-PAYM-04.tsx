// CL-PAYM-04 · Payment not completed. One outcome layout for the voucher payment (ADR 0013 D5, ADR 0034): the outcome as a drawing and a
// title of two words, the money status as a glyph and two words ("Not charged"), the next step in the pinned bar. What happened and what
// to do is the recovery text behind the info glyph (02-text-diet section 6). Requirements: CA-PAY-10, CA-PAY-01. ADR 0027 D3 (a late
// success is honoured, not refunded); ADR 0033: no hold, no slot, no deposit exist at this step.
//
// states  declined, cancelled-by-user, checkout-expired, late-payment-activated, offline. Support is one tap away on every one of them
// (a chat glyph in the bar, CL-MSGS-02). late-payment-activated is the good outcome: the money arrived after the checkout ended and the
// voucher is active. The way back to the venue is the close glyph.
import type { IconName } from '@gz/tokens'
import { ActionBar, FactChip, FactRow, Screen, TopBar, useNav, type IllustrationName, type IllustrationTone } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { METHOD_ICON, METHOD_SHORT, asMethod, checkoutEndedAt, checkoutMinutes, paramsOf, targetFromParams, voucherFeeFils } from './_components/data'
import { Fx } from './_components/Fx'
import { Outcome } from './_components/Outcome'
import { useIssued } from './_components/usePurchase'
import { useSceneState } from './_components/useScene'

type Scene = 'declined' | 'cancelled-by-user' | 'checkout-expired' | 'late-payment-activated' | 'offline'

export const states: Scene[] = ['declined', 'cancelled-by-user', 'checkout-expired', 'late-payment-activated', 'offline']

const isScene = (s: unknown): s is Scene => typeof s === 'string' && (states as readonly string[]).includes(s)

export default function PaymentNotCompleted() {
  const t = useT('client-payment')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav()
  const sceneState = useSceneState()
  const scene: Scene = isScene(sceneState) ? sceneState : 'declined'

  const p = nav.params as Record<string, unknown> & { depth?: unknown; attempt?: unknown }
  const method = asMethod(p.method)
  const attempt = typeof p.attempt === 'number' ? p.attempt : 1
  const depth = typeof p.depth === 'number' ? p.depth : 2
  const issued = useIssued()
  // An expired checkout may have no voucher yet: its quote travels in the params.
  const target = targetFromParams(p) ?? issued.target
  const voucherId = typeof p.voucherId === 'string' ? p.voucherId : undefined

  // ---- next steps (every edge of the inventory)
  const retry = () => nav.replace('CL-PAYM-02', { voucherId: issued.voucher.id, method, attempt: attempt + 1, answer: 'approved', depth })
  // One level back is the pay screen (it suggests Apple Pay or a card first, reading the failed attempt from the store).
  const another = () => (depth >= 2 && nav.canGoBack ? nav.pop() : nav.replace('CL-PAYM-01', { ...paramsOf(target), voucherId, depth: 1 }))
  const startAgain = () => nav.replace('CL-PAYM-01', { ...paramsOf(target), depth: 1 })
  const detailParams = target.kind === 'provider' ? { providerId: target.targetId, vendorId: target.targetId } : { venueId: target.targetId }
  const backToDetail = () => (nav.canGoBack ? nav.pop(depth) : nav.push(target.detailId, detailParams))
  const viewVoucher = () => nav.replace('CL-PAYM-05', { voucherId: issued.voucher.id, late: true, depth })
  const support = () => nav.push('CL-MSGS-02', { support: true })

  type View = {
    art: IllustrationName
    tone: IllustrationTone
    title: string
    /** The recovery text, behind the info glyph. */
    detail: string
    /** The money status: nothing was charged, or the payment arrived. */
    money: { icon: IconName; label: string; value?: string; facts?: boolean }
    primary: { label: string; onPress: () => void }
    secondary?: { label: string; onPress: () => void }
  }
  const amount = f.money(voucherFeeFils(), { mode: 'exact' })
  const none = { icon: 'shield-check' as IconName, label: t('clientPaymentNotChargedLabel'), value: t('clientPaymentNotCharged') }

  const views: Record<Scene, View> = {
    declined: {
      art: 'card',
      tone: 'danger',
      title: tc('commonStateTitlePayment'),
      detail: t('clientPaymentFailBodyDeclined'),
      money: none,
      primary: { label: tc('commonActionRetry'), onPress: retry },
      secondary: { label: t('clientPaymentFailAnother'), onPress: another },
    },
    'cancelled-by-user': {
      art: 'card',
      tone: 'default',
      title: t('clientPaymentCancelTitle'),
      detail: t('clientPaymentFailBodyCancelled'),
      money: none,
      primary: { label: tc('commonActionRetry'), onPress: retry },
      secondary: { label: t('clientPaymentFailAnother'), onPress: another },
    },
    'checkout-expired': {
      art: 'hourglass',
      tone: 'default',
      title: t('clientPaymentFailTitleExpired'),
      detail: t('clientPaymentFailBodyExpired', { time: f.time(checkoutEndedAt()), minutes: tc('commonCountMinutes', { count: checkoutMinutes() }) }),
      money: none,
      primary: { label: t('clientPaymentFailStartAgain'), onPress: startAgain },
    },
    'late-payment-activated': {
      art: 'success-voucher',
      tone: 'default',
      title: t('clientPaymentFailTitleLate'),
      detail: t('clientPaymentFailBodyLate'),
      money: { icon: 'check-circle', label: t('clientPaymentReceivedLabel'), value: amount, facts: true },
      primary: { label: t('clientPaymentViewVoucher'), onPress: viewVoucher },
    },
    offline: {
      art: 'wifi-off',
      tone: 'default',
      title: tc('commonStateOffline'),
      detail: t('clientPaymentFailBodyOffline'),
      money: none,
      primary: { label: tc('commonActionRetry'), onPress: () => nav.toast({ message: tc('commonStateOffline'), icon: 'offline' }) },
    },
  }
  const v = views[scene]

  // The money status is one fact. A payment that arrived adds how it was paid (method glyph and name).
  const meta = (
    <FactRow label={v.money.label}>
      <FactChip icon={v.money.icon} label={v.money.label} value={v.money.value ? <Fx text={v.money.value} /> : undefined} />
      {v.money.facts ? <FactChip icon={METHOD_ICON[method]} label={t('clientPaymentLabelMethod')} value={t(METHOD_SHORT[method])} /> : null}
    </FactRow>
  )

  return (
    <Screen
      top={<TopBar back="close" onBack={backToDetail} title={t('clientPaymentTopTitle')} rule actions={[{ icon: 'chat', label: t('clientPaymentSupport'), onPress: support }]} />}
      bottom={<ActionBar action={{ label: v.primary.label, onPress: v.primary.onPress }} secondary={v.secondary} />}
    >
      <div className="pm-stage" role="status">
        <Outcome illustration={v.art} tone={v.tone} title={v.title} meta={meta} info={{ title: tc('commonLabelDetails'), body: v.detail }} />
      </div>
    </Screen>
  )
}
