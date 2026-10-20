// HL-SETT-04 Billing and fees. Requirement IDs: HA-AUTH-02, HA-BOOK-03, HA-SET-06, PA-ADS-04, PA-ADS-05.
// Repurposed by ADR 0033 (it was Bank information): what Ghazal charges a partner and what it has paid. One status card with a drawing: the
// plan (its name, a status pill, the end date and the days left as facts), Ending (the same, a timer), Ended (hidden listing), No plan (or
// "Rates announced soon" while there are no rates), or for a major hotel the exemption badge. The sentences (the exemption explained and that
// the listing is still reviewed, the reminders at 7 and 1 days, what Renew does, that couples pay the venue directly) sit behind the (i) of the
// card. The Plans row opens the plan chooser (HL-PROV-04); the receipts list opens the bilingual PDF viewer (amounts say KWD on the document).
// There is no bank, no IBAN and no payout: partners are never paid through Ghazal. Admin and Manager change the plan, Accountant views and
// downloads, Reception and Marketing do not see the screen. The only amounts are the labelled SAMPLE ones of the `receipts` frame and of a prototype payment.
// Text diet (ADR 0034): one drawing, facts as glyph + figure, no note under the card, no code on a receipt row.
// Owner round 1: two modes. Contract (hotels and halls): the Business contract card, terms as contracted, no plan row, no receipts and no number.
// Plan (service providers): weekly, monthly or annual from the Super Admin, "Rates announced soon" until it sets them. No credit notes.
// States: contract, plan-active, plan-expiring, plan-expired, no-plan, rates-not-announced, fee-exempt-major-hotel, receipts, role-view-only, offline, error, loading.
import { useMemo } from 'react'
import { planRates } from '../../../mock'
import type { AdPlanCycle } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, Badge, Banner, BillingCard, Button, ErrorState, FactChip, IconListRow, Illustration, InfoButton, MajorHotelBadge, Screen, SectionHeader, Skeleton, StatusPill, TopBar, useNav, type IllustrationName } from '../../../system'
import { PlanReceipt } from '../provider/_components/PlanReceipt'
import { SAMPLE_RATES_FILS } from '../provider/_components/model'
import { useProv, type PaidPlan } from '../provider/_components/store'
import { Fx } from './_components/Fx'
import { PROVIDER_ID, SheetFrame, useAccount, useBi, useBilling, useWords } from './_components/bits'
import { ACCESS, roleOfState, sampleReceipts, type ReceiptEntry } from './_components/model'
import { useFormat } from '../../../i18n'
import { useT } from '../../../i18n'
import './HL-SETT-04.css'

export const states = [
  'contract',
  'plan-active',
  'plan-expiring',
  'plan-expired',
  'no-plan',
  'rates-not-announced',
  'fee-exempt-major-hotel',
  'receipts',
  'role-view-only',
  'offline',
  'error',
  'loading',
]

const PLAN = {
  weekly: 'commonPlanWeekly',
  monthly: 'commonPlanMonthly',
  annual: 'commonPlanAnnual',
} as const
const METHOD = {
  knet: 'hotelSettingsBillMethodKnet',
  card: 'hotelSettingsBillMethodCard',
  apple_pay: 'hotelSettingsBillMethodApplePay',
  google_pay: 'hotelSettingsBillMethodGooglePay',
} as const

export default function BillingAndFees() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const prov = useT('hotel-provider')
  const role = roleOfState(state)
  const access = ACCESS[role].billing
  const canEdit = access === 'edit'
  const account = useAccount()
  const billing = useBilling(account, state)
  const offline = state === 'offline'
  const listings = usePrototype(s => s.listings)
  const paid = useProv(s => s.paid)

  const ratesSoon = state === 'no-plan' ? false : !planRates().payable
  const { status } = billing
  const attention = status === 'expiring' || status === 'expired'

  // ---- receipts: the labelled sample ones in their frame, otherwise the payments made in this prototype session (none until rates are set)
  const receipts: ReceiptEntry[] = useMemo(() => {
    if (state === 'receipts') return sampleReceipts(SAMPLE_RATES_FILS)
    const made = Object.values(paid as Record<string, PaidPlan>)
      .map(p => ({
        number: p.receiptNo,
        at: p.at,
        cycle: p.cycle,
        fils: p.fils,
        method: p.method,
        sample: true as const,
      }))
      .sort((a, b) => b.at.localeCompare(a.at))
    // A plan that is active, expiring or expired has been paid: its receipt is listed (labelled sample, rates are not announced yet).
    if (made.length === 0 && (status === 'active' || status === 'expiring' || status === 'expired') && billing.cycle) {
      return sampleReceipts(SAMPLE_RATES_FILS)
        .slice(0, 1)
        .map(r => ({ ...r, cycle: billing.cycle as AdPlanCycle, fils: SAMPLE_RATES_FILS[billing.cycle as AdPlanCycle] }))
    }
    return made
  }, [state, paid, status, billing.cycle])

  const listingTitle = (): string => {
    if (account.type === 'provider') {
      const l = listings.find(x => x.providerId === PROVIDER_ID && x.status === 'active')
      return l ? bi(l.title) : ''
    }
    return bi({ en: 'Lumi Marina Hotel', ar: 'فندق لومي مارينا' })
  }

  const openReceipt = (r: ReceiptEntry) => {
    const key = nav.openSheet(
      <SheetFrame
        title={prov('hotelProviderReceiptTitle')}
        onClose={() => nav.closeSheet(key)}
        footer={
          <Button
            variant="secondary"
            iconStart="download"
            fullWidth
            onClick={() =>
              nav.toast({
                message: t('hotelSettingsBillDownloaded'),
                tone: 'success',
                icon: 'check-circle',
              })
            }
          >
            {t('hotelSettingsBillDownload')}
          </Button>
        }
      >
        <PlanReceipt number={r.number} listingTitle={listingTitle()} cycle={r.cycle} fils={r.fils} paidAt={r.at} methodLabel={t(METHOD[r.method])} sample={r.sample} />
      </SheetFrame>,
    )
  }

  const offlineGuard = (): boolean => {
    if (!offline) return false
    nav.toast({ message: c('commonStateOffline'), icon: 'offline' })
    return true
  }
  const openPlans = () => {
    if (offlineGuard()) return
    nav.push('HL-PROV-04', {
      account: account.type === 'provider' ? 'provider' : account.major ? 'major' : 'hotel',
      renewal: attention,
    })
  }

  // ---- the status card
  const art: IllustrationName = status === 'exempt' || status === 'contract' ? 'seal' : status === 'expiring' || status === 'expired' ? 'hourglass' : 'partner-ads'
  const endsOn = billing.endsOn ? f.date(billing.endsOn, 'compact') : ''
  const pill =
    status === 'active' ? (
      <StatusPill status="listing_active" label={t('hotelSettingsBillPillActive')} />
    ) : status === 'expiring' ? (
      <StatusPill status="urgent" label={t('hotelSettingsBillPillExpiring')} />
    ) : status === 'expired' ? (
      <StatusPill status="listing_expired" />
    ) : null

  // The sentences of the card, behind its (i): the exemption, the reminders, what ended, what a plan is, and that couples pay the venue.
  const infoLines: string[] =
    status === 'contract'
      ? [t('hotelSettingsBillContractBody'), t('hotelSettingsBillDirectNote')]
      : status === 'exempt'
      ? [t('hotelSettingsBillExemptBody'), t('hotelSettingsBillDirectNote')]
      : status === 'none'
        ? [t(ratesSoon ? 'hotelSettingsBillRatesBody' : 'hotelSettingsBillNoneBody'), t('hotelSettingsBillDirectNote')]
        : status === 'expiring'
          ? [t('hotelSettingsBillExpiringNote'), t('hotelSettingsBillDirectNote')]
          : status === 'expired'
            ? [t('hotelSettingsBillExpiredNote'), t('hotelSettingsBillDirectNote')]
            : [t('hotelSettingsBillDirectNote')]

  const card = (
    <section className="hs-bill" data-gz="BillingStatus" data-status={status} aria-label={t('hotelSettingsBillStatusLabel')}>
      <div className="hs-bill__top">
        <Illustration name={art} size="lg" />
        <InfoButton title={t('hotelSettingsMoreBilling')}>
          {infoLines.map(line => (
            <p key={line}>{line}</p>
          ))}
        </InfoButton>
      </div>
      {status === 'contract' ? (
        <BillingCard billing={{ mode: 'contract', contractSummary: null, plan: null }} />
      ) : status === 'exempt' ? (
        <MajorHotelBadge variant="chip" />
      ) : status === 'none' ? (
        <h2 className="gz-t-ui-xl hs-bill__title">{ratesSoon ? c('commonRatesSoon') : t('hotelSettingsBillNone')}</h2>
      ) : (
        <>
          <div className="hs-bill__head">
            {pill}
            {status === 'expired' ? (
              <Badge variant="quiet" bead={false} icon="eye-off">
                {t('hotelSettingsBillHidden')}
              </Badge>
            ) : null}
          </div>
          <h2 className="gz-t-ui-xl hs-bill__title">{billing.cycle ? c(PLAN[billing.cycle]) : ''}</h2>
          <div className="hs-bill__facts">
            <FactChip icon="calendar" tone={attention ? 'accent' : 'default'} label={t(status === 'expired' ? 'hotelSettingsBillEnded' : 'hotelSettingsBillEnds')} value={<Fx text={endsOn} />} />
            {billing.daysLeft !== null && billing.daysLeft >= 0 ? (
              <FactChip icon="timer" tone={attention ? 'accent' : 'muted'} label={t('hotelSettingsBillDaysLeft')} value={f.integer(billing.daysLeft)} unit={t('hotelSettingsBillDaysUnit')} />
            ) : null}
          </div>
        </>
      )}
      {!canEdit ? (
        <Badge variant="quiet" bead={false} icon="lock">
          {t('hotelSettingsBillViewOnly')}
        </Badge>
      ) : null}
    </section>
  )

  // ---- body
  let body
  if (state === 'loading') {
    body = (
      <div className="hs-page__skeleton" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={296} />
        <Skeleton variant="line" blockSize={56} />
        <Skeleton variant="line" blockSize={56} />
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-SETT-04')} />
  } else if (access === 'none') {
    body = <ErrorState kind="no-access" />
  } else {
    body = (
      <>
        <div className="hs-page__pad">{card}</div>
        {status === 'active' && canEdit ? (
          <div className="hs-bill__plan">
            <IconListRow icon="megaphone" title={t('hotelSettingsBillPlanRow')} chevron onClick={openPlans} last />
          </div>
        ) : null}
        {receipts.length > 0 ? (
          <section className="hs-section" aria-label={t('hotelSettingsBillReceipts')}>
            <div className="hs-section__head">
              <SectionHeader title={t('hotelSettingsBillReceipts')} voice="hotel" />
            </div>
            <div className="hs-section__rows">
              {receipts.map((r, i) => (
                <IconListRow
                  key={r.number}
                  icon="receipt"
                  title={<Fx text={f.date(r.at.slice(0, 10), 'compact')} />}
                  trailing={
                    <Badge variant="quiet" bead={false}>
                      {prov('hotelProviderSampleBadge')}
                    </Badge>
                  }
                  chevron
                  onClick={() => openReceipt(r)}
                  last={i === receipts.length - 1}
                />
              ))}
            </div>
          </section>
        ) : null}
      </>
    )
  }

  const ready = state !== 'loading' && state !== 'error' && access !== 'none'
  const bar =
    ready && canEdit && status !== 'exempt' && (attention || status === 'none') ? (
      <ActionBar
        action={{
          label: t(attention ? 'hotelSettingsBillRenew' : ratesSoon ? 'hotelSettingsBillSeePlans' : 'hotelSettingsBillChoose'),
          onPress: openPlans,
        }}
      />
    ) : undefined

  return (
    <div className="hs-root">
      <Screen top={<TopBar title={t('hotelSettingsMoreBilling')} />} bottom={bar}>
        {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
        <div className="hs-page">{body}</div>
      </Screen>
    </div>
  )
}
