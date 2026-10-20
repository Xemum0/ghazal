// HL-PROV-05 Pay for the plan: the hosted gateway (same methods as the client voucher) and every outcome. Payment moves the listing to review;
// it never publishes it. The only amounts here are the prototype's labelled SAMPLE rates: while rates are not announced the screen cannot be
// reached (it says so). The hosted bank page is a third-party placeholder; the "Prototype only" tray chooses what the bank answers.
// Requirements: PA-ADS-02, PA-ADS-03, PA-ADS-07, PA-REV-01
// States: methods, redirecting, bank-page, confirming-with-bank, paid-submitted-for-review, failed, cancelled, rates-not-announced, offline, error
import { useEffect, useRef, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { clock, planRates } from '../../../mock'
import type { AdPlanCycle } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, Badge, Button, ChipGroup, ErrorState, Figures, Icon, InfoButton, PaymentMethodRow, Price, Screen, TopBar, toPaymentMethod, useNav, type PaymentMethodKey } from '../../../system'
import { Interstitial } from './_components/Interstitial'
import { PlanReceipt } from './_components/PlanReceipt'
import { Note, OfflineStrip, SheetFrame, StaticSheet, UserText, useAfter, useBi, useFormat, useIsStatic, useP } from './_components/bits'
import { CYCLES, PROVIDER_ID, SAMPLE_PERIOD_DAYS, SAMPLE_RATES_FILS, isAccountKind, pickListing } from './_components/model'
import { payAndSubmit, useProv } from './_components/store'
import './HL-PROV-05.css'

export const states = ['methods', 'redirecting', 'bank-page', 'confirming-with-bank', 'paid-submitted-for-review', 'failed', 'cancelled', 'rates-not-announced', 'offline', 'error']

type Phase = 'summary' | 'redirecting' | 'bank' | 'confirming' | 'paid' | 'failed' | 'cancelled'
type Answer = 'approved' | 'declined'

const FRAME_PHASE: Record<string, Phase> = {
  methods: 'summary',
  redirecting: 'redirecting',
  'bank-page': 'bank',
  'confirming-with-bank': 'confirming',
  'paid-submitted-for-review': 'paid',
  failed: 'failed',
  cancelled: 'cancelled',
}

const METHODS: readonly PaymentMethodKey[] = ['knet', 'visa', 'mastercard', 'apple_pay', 'google_pay']
const NAME: Record<PaymentMethodKey, 'hotelProviderMethodKnet' | 'hotelProviderMethodVisa' | 'hotelProviderMethodMastercard' | 'hotelProviderMethodApplePay' | 'hotelProviderMethodGooglePay'> = {
  knet: 'hotelProviderMethodKnet',
  visa: 'hotelProviderMethodVisa',
  mastercard: 'hotelProviderMethodMastercard',
  apple_pay: 'hotelProviderMethodApplePay',
  google_pay: 'hotelProviderMethodGooglePay',
}
const PLAN = { weekly: 'commonPlanWeekly', monthly: 'commonPlanMonthly', annual: 'commonPlanAnnual' } as const

export default function AdPayment() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useP()
  const isStatic = useIsStatic()
  const viewer = useProv(s => s.viewer)
  const listings = usePrototype(s => s.listings)

  const kind = isAccountKind(nav.params.account) ? nav.params.account : viewer
  const mine = listings.filter(l => l.providerId === PROVIDER_ID)
  const listing = pickListing(mine, nav.params.listingId, ['payment_pending', 'draft', 'rejected', 'expired'])
  const cycle: AdPlanCycle = CYCLES.includes(nav.params.cycle as AdPlanCycle) ? (nav.params.cycle as AdPlanCycle) : 'monthly'
  const renewal = nav.params.renewal === true
  const fixtureRate = planRates().plans.find(p => p.plan.cycle === cycle)?.plan.ratesFils ?? null
  const sample = fixtureRate === null
  // Rates exist only as the labelled sample; the real ones are null until the owner decides (OQ-V-07).
  const blocked = state === 'rates-not-announced' || (!isStatic && nav.params.sample !== true && fixtureRate === null)
  const fils = fixtureRate ?? SAMPLE_RATES_FILS[cycle]

  const offline = state === 'offline'
  const error = state === 'error'
  const [phase, setPhase] = useState<Phase>(state ? (FRAME_PHASE[state] ?? 'summary') : 'summary')
  const [method, setMethod] = useState<PaymentMethodKey>('knet')
  const [answer, setAnswer] = useState<Answer>('approved')
  const [outcome, setOutcome] = useState<'review' | 'renewed'>(renewal ? 'renewed' : 'review')
  const [receipt] = useState(() => ({ number: 'GP-2611-0042', at: clock.now() }))
  const recorded = useRef(false)

  const methodName = t(NAME[method])
  const title = listing ? bi(listing.title) : ''
  const amountText = f.money(fils, { mode: 'exact' })
  const endsOn = listing?.endsOn ?? null

  // Live only: the transient screens move on by themselves.
  useAfter(900, () => setPhase('bank'), phase === 'redirecting')
  useAfter(1400, () => setPhase(answer === 'approved' ? 'paid' : 'failed'), phase === 'confirming')

  // Payment recorded once, when it succeeds in the live prototype: the listing goes to review (never live) or the live plan is extended.
  useEffect(() => {
    if (phase !== 'paid' || isStatic || recorded.current || !listing) return
    recorded.current = true
    setOutcome(payAndSubmit(listing.id, { cycle, fils, at: receipt.at, method: toPaymentMethod(method), receiptNo: receipt.number }, SAMPLE_PERIOD_DAYS[cycle]))
  }, [phase, isStatic, listing, cycle, fils, receipt, method])

  const openMethods = () => {
    const key = nav.openSheet(<MethodsSheet value={method} onPick={m => setMethod(m)} onDone={() => nav.closeSheet(key)} />, {})
  }
  const openReceipt = () => {
    nav.openSheet(
      <SheetFrame title={t('hotelProviderReceiptTitle')}>
        <PlanReceipt number={receipt.number} listingTitle={title} cycle={cycle} fils={fils} paidAt={receipt.at} methodLabel={methodName} sample={sample} />
      </SheetFrame>,
      {},
    )
  }
  const askLeave = async () => {
    if (phase === 'summary' || phase === 'paid' || phase === 'failed' || phase === 'cancelled') return nav.pop()
    const r = await nav.openDialog({ title: t('hotelProviderLeaveTitle'), body: t('hotelProviderLeaveBody'), icon: 'lock', confirmLabel: t('hotelProviderLeaveStay'), cancelLabel: t('hotelProviderLeaveConfirm') })
    if (r === 'cancel') setPhase('cancelled')
  }
  const toStatus = () => nav.replace('HL-PROV-06', { listingId: listing?.id, account: kind })
  const toPlans = () => nav.pop()

  const secureBar = (
    <TopBar
      back="close"
      onBack={askLeave}
      rule
      title={
        <span className="hp05__bartitle">
          <Icon name="lock" size="xs" />
          <span>{t('hotelProviderGatewayTitle', { method: methodName })}</span>
        </span>
      }
    />
  )

  let top = <TopBar title={t('hotelProviderPayTitle')} />
  let bottom: ReactNode
  let body: ReactNode

  if (error) {
    body = <ErrorState kind="payment" title={t('hotelProviderPayErrorTitle')} body={t('hotelProviderPayErrorBody')} onRetry={() => nav.replace('HL-PROV-05', nav.params)} />
  } else if (blocked) {
    body = (
      <Interstitial icon="clock" art="hourglass" title={t('hotelProviderBlockedTitle')} body={t('hotelProviderBlockedBody')}>
        <div className="hp05__act">
          <Button variant="secondary" onClick={toPlans}>
            {t('hotelProviderBackToPlans')}
          </Button>
        </div>
      </Interstitial>
    )
  } else if (phase === 'redirecting') {
    top = secureBar
    body = (
      <Interstitial icon="activity" title={t('hotelProviderRedirectTitle', { method: methodName })} body={t('hotelProviderRedirectBody')}>
        <Summary title={title} cycle={cycle} amount={amountText} sample={sample} />
      </Interstitial>
    )
  } else if (phase === 'confirming') {
    top = secureBar
    body = <Interstitial icon="activity" title={t('hotelProviderConfirmingTitle')} body={t('hotelProviderConfirmingBody')} />
  } else if (phase === 'bank') {
    top = secureBar
    body = (
      <div className="hp05__hosted" data-gz-id="hosted">
        <div className="hp05__bank">
          <div className="hp05__brand">
            <span className="hp05__logo">{method === 'knet' ? 'KNET' : method === 'visa' || method === 'mastercard' ? 'VISA · MC' : 'PAY'}</span>
          </div>
          <dl className="hp05__facts">
            <div>
              <dt className="gz-t-caption">{t('hotelProviderBankMerchant')}</dt>
              <dd className="gz-t-title">{t('hotelProviderBankMerchantName')}</dd>
            </div>
            <div>
              <dt className="gz-t-caption">{t('hotelProviderBankAmount')}</dt>
              <dd className="gz-t-title">
                <Figures text={f.money(fils, { mode: 'exact', label: 'legal' })} />
              </dd>
            </div>
          </dl>
          <div className="hp05__fields" aria-hidden="true">
            {(['hotelProviderBankCard', 'hotelProviderBankExpiry', 'hotelProviderBankPin'] as const).map(k => (
              <div key={k} className="hp05__field">
                <span className="gz-t-caption">{t(k)}</span>
                <span className="hp05__input" />
              </div>
            ))}
          </div>
          <div className="hp05__bankact">
            <button type="button" className="gz-reset gz-press gz-t-button hp05__bankbtn" onClick={() => setPhase('cancelled')}>
              {c('commonActionCancel')}
            </button>
            <button type="button" className="gz-reset gz-press gz-t-button hp05__bankbtn hp05__bankbtn--solid" onClick={() => setPhase('confirming')}>
              {t('hotelProviderBankSubmit')}
            </button>
          </div>
        </div>
        <div className="hp05__proto" data-gz-id="proto">
          <p className="gz-t-label hp05__protolabel">{t('hotelProviderProtoLabel')}</p>
          <ChipGroup<Answer>
            label={t('hotelProviderProtoLabel')}
            value={answer}
            onChange={v => v && setAnswer(v)}
            options={[
              { value: 'approved', label: t('hotelProviderProtoApproved') },
              { value: 'declined', label: t('hotelProviderProtoDeclined') },
            ]}
          />
        </div>
      </div>
    )
  } else if (phase === 'paid') {
    top = <TopBar title={t('hotelProviderPayTitle')} back={false} />
    const renewed = outcome === 'renewed'
    bottom = (
      <ActionBar
        action={{
          label: renewed ? t('hotelProviderBackToListings') : t('hotelProviderViewStatus'),
          iconEnd: 'chevron-right',
          onPress: renewed ? () => nav.reset('HL-PROV-02', { account: kind }) : toStatus,
        }}
      />
    )
    body = (
      <Interstitial icon="check-circle" tone="success" art="success-payment" title={t(renewed ? 'hotelProviderRenewedTitle' : 'hotelProviderPaidTitle')} body={t(renewed ? 'hotelProviderRenewedBody' : 'hotelProviderPaidBody')}>
        <Summary title={title} cycle={cycle} amount={amountText} sample={sample} paid />
        <div className="hp05__act">
          <Button variant="tertiary" iconStart="receipt" onClick={openReceipt}>
            {t('hotelProviderReceiptLink')}
          </Button>
        </div>
        {renewed && endsOn ? <Note icon="calendar">{t('hotelProviderRenewedNote', { date: f.date(endsOn, 'short') })}</Note> : null}
      </Interstitial>
    )
  } else if (phase === 'failed') {
    body = (
      <Interstitial icon="warning-circle" tone="danger" art="card" title={t('hotelProviderFailedTitle')} body={t('hotelProviderFailedBody')}>
        <div className="hp05__acts">
          <Button variant="primary" onClick={() => setPhase('redirecting')}>
            {t('hotelProviderRetry')}
          </Button>
          <Button variant="secondary" onClick={() => { setPhase('summary'); if (!isStatic) openMethods() }}>
            {t('hotelProviderSwitchMethod')}
          </Button>
        </div>
      </Interstitial>
    )
  } else if (phase === 'cancelled') {
    body = (
      <Interstitial icon="info" art="card" title={t('hotelProviderCancelledTitle')} body={t('hotelProviderCancelledBody')}>
        <div className="hp05__act">
          <Button variant="secondary" onClick={() => setPhase('summary')}>
            {t('hotelProviderBackToPay')}
          </Button>
        </div>
      </Interstitial>
    )
  } else {
    top = (
      <>
        <TopBar title={t('hotelProviderPayTitle')} />
        {offline ? <OfflineStrip /> : null}
      </>
    )
    bottom = (
      <ActionBar
        action={{
          label: t('hotelProviderPayAction', { amount: amountText }),
          iconEnd: 'lock',
          disabled: offline,
          reason: offline ? t('hotelProviderOfflinePay') : undefined,
          onPress: () => setPhase('redirecting'),
        }}
      />
    )
    body = (
      <div className="hp05">
        <section className="hp05__hero" aria-label={t('hotelProviderPayTotal')}>
          <span className="hp05__heroamt">
            <Price fils={fils} mode="exact" size="kpi" />
            {sample ? <Badge variant="quiet">{t('hotelProviderSampleBadge')}</Badge> : null}
          </span>
        </section>
        <Summary title={title} cycle={cycle} amount={amountText} sample={sample} hideAmount />
        <section className="hp05__method" aria-label={t('hotelProviderPayWith')}>
          <div role="radiogroup" aria-label={t('hotelProviderPayWith')}>
            <PaymentMethodRow method={method} selected last />
          </div>
          <Button variant="tertiary" onClick={openMethods}>
            {t('hotelProviderChangeMethod')}
          </Button>
        </section>
        <p className="hp05__refund">
          <InfoButton title={t('hotelProviderRefundTitle')}>{t('hotelProviderRefundNote')}</InfoButton>
        </p>
      </div>
    )
  }

  return (
    <>
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'methods' ? (
        <StaticSheet label={t('hotelProviderMethodsTitle')}>
          <MethodsSheet value={method} onPick={setMethod} />
        </StaticSheet>
      ) : null}
    </>
  )
}

function Summary({ title, cycle, amount, sample, hideAmount = false, paid = false }: { title: string; cycle: AdPlanCycle; amount: string; sample: boolean; hideAmount?: boolean; paid?: boolean }) {
  const { t, c } = useP()
  const rows: [IconName, string, ReactNode][] = [
    ['megaphone', t('hotelProviderSumListing'), <UserText key="l" role="body">{title}</UserText>],
    ['calendar', t('hotelProviderSumPlan'), <Figures key="p" text={`${c(PLAN[cycle])} · ${c('commonCountDays', { count: SAMPLE_PERIOD_DAYS[cycle] })}`} />],
    ...(hideAmount ? [] : ([['coins', paid ? t('hotelProviderSumPaid') : t('hotelProviderSumAmount'), <span key="a" className="hp05__sumamt"><Figures text={amount} />{sample ? <Badge variant="quiet">{t('hotelProviderSampleBadge')}</Badge> : null}</span>]] as [IconName, string, ReactNode][])),
  ]
  return (
    <dl className="hp05__sum" data-gz="PaySummary">
      {rows.map(([ic, k, v]) => (
        <div key={k} className="hp05__sumrow">
          <dt><Icon name={ic} size="sm" tone="secondary" label={k} /></dt>
          <dd className="gz-t-body">{v}</dd>
        </div>
      ))}
    </dl>
  )
}

function MethodsSheet({ value, onPick, onDone }: { value: PaymentMethodKey; onPick: (m: PaymentMethodKey) => void; onDone?: () => void }) {
  const { t, c } = useP()
  const [pick, setPick] = useState(value)
  return (
    <SheetFrame
      title={t('hotelProviderMethodsTitle')}
      onClose={onDone}
      footer={
        <Button variant="primary" fullWidth onClick={onDone}>
          {c('commonActionDone')}
        </Button>
      }
    >
      <div role="radiogroup" aria-label={t('hotelProviderMethodsTitle')} className="hp05__methods">
        {METHODS.map((m, i) => (
          <PaymentMethodRow
            key={m}
            method={m}
            selected={pick === m}
            last={i === METHODS.length - 1}
            onSelect={() => {
              setPick(m)
              onPick(m)
            }}
          />
        ))}
      </div>
    </SheetFrame>
  )
}
