// HL-PROV-06 Review status: where a listing is in manual review. Pending (what to expect), Approved or Live (when and until), Not approved with
// reason chips and the moderator's note in the provider's language, and the way to edit and resubmit. A moderator checks content compliance and
// category; a major hotel is reviewed too. Payment never publishes a listing.
// Requirements: PA-REV-01, PA-REV-02, PA-REV-03, PA-REV-04, PA-REV-05, PA-ADS-07
// States: pending-long-wait, approved, live, rejected, rejected-plan-retained, rejected-refunded, changes-requested, offline, error
//   (the default frame is Pending; live shows a prototype-only tray to play the Ghazal moderator)
import { useRef } from 'react'
import type { IconName } from '@gz/tokens'
import type { Listing, ListingRejectionCode } from '../../../mock'
import { clock, engine } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, Button, ErrorState, Icon, Illustration, ProviderListingCard, ReviewTimeline, Screen, SectionHeader, Skeleton, Tag, TopBar, useNav } from '../../../system'
import { Figures, Note, OfflineStrip, UserText, useBi, useFormat, useLive, useP } from './_components/bits'
import { LONG_WAIT_HOURS, PROVIDER_ID, SAMPLE_PERIOD_DAYS, accountOf, daysLeft, isAccountKind, pickListing } from './_components/model'
import { useProv } from './_components/store'
import './HL-PROV-06.css'

export const states = ['pending-long-wait', 'approved', 'live', 'rejected', 'rejected-plan-retained', 'rejected-refunded', 'changes-requested', 'offline', 'error']

const REASON: Record<ListingRejectionCode, 'hotelProviderReasonContent' | 'hotelProviderReasonCategory' | 'hotelProviderReasonMissing' | 'hotelProviderReasonPricing' | 'hotelProviderReasonOther'> = {
  content_not_compliant: 'hotelProviderReasonContent',
  wrong_category: 'hotelProviderReasonCategory',
  missing_details: 'hotelProviderReasonMissing',
  unclear_pricing: 'hotelProviderReasonPricing',
  other: 'hotelProviderReasonOther',
}

const hoursAgo = (h: number): string => engine.addMinutes(clock.now(), -h * 60)

type View = { listing: Listing; revision: boolean; paidFils: number | null; refunded: boolean }

/** The listing a frame shows for a state; the live player reads the shared store. */
function frameView(state: string | undefined, all: Listing[]): View | null {
  const get = (id: string) => all.find(l => l.id === id)
  const table = get('lst-flowers-zahra-table')
  const live = get('lst-flowers-zahra')
  const kosha = get('lst-flowers-zahra-kosha')
  const today = clock.today()
  switch (state) {
    case 'pending-long-wait':
      return table ? { listing: { ...table, submittedAt: hoursAgo(53), history: table.history.map(h => (h.to === 'pending_review' ? { ...h, at: hoursAgo(53) } : h)) }, revision: false, paidFils: null, refunded: false } : null
    case 'approved':
      return table
        ? {
            listing: {
              ...table,
              status: 'approved',
              planCycle: 'monthly',
              startsOn: today,
              endsOn: engine.addDays(today, SAMPLE_PERIOD_DAYS.monthly),
              decidedAt: clock.now(),
              history: [...table.history, { id: 'rev-demo-approved', listingId: table.id, at: clock.now(), from: 'pending_review', to: 'approved', actor: 'moderator', actorName: 'Hessa Al-Awadhi' }],
            },
            revision: false,
            paidFils: null,
            refunded: false,
          }
        : null
    case 'live':
      return live ? { listing: live, revision: false, paidFils: null, refunded: false } : null
    case 'changes-requested':
      return live ? { listing: live, revision: true, paidFils: null, refunded: false } : null
    case 'rejected':
      return kosha ? { listing: { ...kosha, planKeptUntil: null }, revision: false, paidFils: null, refunded: false } : null
    case 'rejected-plan-retained':
      return kosha ? { listing: { ...kosha, planKeptUntil: engine.addDays(today, 9) }, revision: false, paidFils: 15000, refunded: false } : null
    case 'rejected-refunded':
      return kosha ? { listing: { ...kosha, planKeptUntil: engine.addDays(today, -2) }, revision: false, paidFils: 15000, refunded: true } : null
    default:
      return table ? { listing: table, revision: false, paidFils: null, refunded: false } : null
  }
}

export default function ReviewStatus() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t } = useP()
  const live = useLive()
  const viewer = useProv(s => s.viewer)
  const revisions = useProv(s => s.revisions)
  const paid = useProv(s => s.paid)
  const listings = usePrototype(s => s.listings)

  const kind = isAccountKind(nav.params.account) ? nav.params.account : viewer
  const exempt = accountOf(kind).exempt
  const mine = listings.filter(l => l.providerId === PROVIDER_ID)
  const offline = state === 'offline'
  const error = state === 'error'
  const loading = state === 'loading'

  const framed = state !== undefined && state !== 'offline' && state !== 'error'
  const picked = pickListing(mine, nav.params.listingId, ['pending_review', 'approved', 'rejected', 'active'])
  const view: View | null =
    framed || (!live && !nav.params.listingId)
      ? frameView(state, mine)
      : picked
        ? { listing: picked, revision: Boolean(revisions[picked.id]), paidFils: paid[picked.id]?.fils ?? (picked.billing.status === 'paid' ? picked.billing.amountFils : null), refunded: picked.billing.status === 'refunded' }
        : null
  const l = view?.listing

  const toList = () => nav.reset('HL-PROV-02', { account: kind })
  const go = (to: string, params: Record<string, unknown> = {}) => nav.push(to, { listingId: l?.id, account: kind, ...params })

  const top = (
    <>
      <TopBar title={t('hotelProviderReviewTitle')} />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  if (loading || !l) {
    return (
      <Screen top={top}>
        <div className="hp06" aria-busy="true">
          <Skeleton variant="block" blockSize={120} />
          <Skeleton variant="block" blockSize={240} />
        </div>
      </Screen>
    )
  }
  if (error) {
    return (
      <Screen top={top}>
        <ErrorState kind="load" title={t('hotelProviderReviewErrorTitle')} body={t('hotelProviderReviewErrorBody')} onRetry={() => nav.replace('HL-PROV-06', nav.params)} />
      </Screen>
    )
  }

  const waitedHours = l.submittedAt ? Math.floor(engine.diffMinutes(l.submittedAt, clock.now()) / 60) : 0
  const longWait = l.status === 'pending_review' && waitedHours >= LONG_WAIT_HOURS && !view?.revision
  const isLive = l.status === 'active'
  const days = daysLeft(l.endsOn)
  const head: { art: 'partner-review' | 'seal' | 'warning'; tone: 'neutral' | 'success' | 'danger'; title: string; date?: string } =
    l.status === 'rejected'
      ? { art: 'warning', tone: 'danger', title: t('hotelProviderHeadRejectedTitle') }
      : l.status === 'approved'
        ? { art: 'seal', tone: 'success', title: t('hotelProviderHeadApprovedTitle'), date: l.endsOn ?? undefined }
        : isLive && !view?.revision
          ? { art: 'seal', tone: 'success', title: t('hotelProviderHeadLiveTitle'), date: l.endsOn ?? undefined }
          : isLive
            ? { art: 'partner-review', tone: 'neutral', title: t('hotelProviderHeadRevisionTitle') }
            : { art: 'partner-review', tone: 'neutral', title: t('hotelProviderHeadPendingTitle') }

  const rejected = l.status === 'rejected'
  const paidLine =
    view?.refunded ? t('hotelProviderPlanRefunded') : view?.paidFils ? t('hotelProviderPlanRetained') : null

  const action = (() => {
    if (rejected) return { label: t('hotelProviderEditResubmit'), iconEnd: 'chevron-right' as const, onPress: () => go('HL-PROV-03') }
    if (isLive || l.status === 'approved') return { label: t('hotelProviderViewPerformance'), iconEnd: 'chevron-right' as const, onPress: () => go('HL-PROV-07') }
    return { label: t('hotelProviderBackToListings'), onPress: toList }
  })()

  // The prototype-only moderator buttons sit at the bottom of a long page: bring the new decision (the hero) back into view.
  const rootRef = useRef<HTMLDivElement>(null)
  const toTop = () => {
    let el: HTMLElement | null = rootRef.current?.parentElement ?? null
    while (el && !(el.scrollHeight > el.clientHeight && /(auto|scroll)/.test(getComputedStyle(el).overflowY))) el = el.parentElement
    el?.scrollTo({ top: 0 })
  }
  const moderate = (approve: boolean) => {
    const s = usePrototype.getState()
    requestAnimationFrame(toTop)
    if (approve) s.moderateListing(l.id, { approve: true })
    else s.moderateListing(l.id, { approve: false, codes: ['wrong_category', 'missing_details'], note: t('hotelProviderProtoNote') })
  }

  return (
    <Screen top={top} bottom={<ActionBar action={{ ...action, disabled: offline && rejected, reason: offline && rejected ? t('hotelProviderNeedsConnection') : undefined }} />}>
      <div ref={rootRef} className="hp06" data-gz="ReviewStatus" data-status={l.status}>
        <header className="hp06__head" data-tone={head.tone}>
          <Illustration name={head.art} size="lg" />
          <h1 className="gz-t-ui-xl hp06__title">{head.title}</h1>
          {head.date ? <span className="gz-t-body hp06__body"><Icon name="calendar" size="sm" tone="secondary" /> <Figures text={f.date(head.date, 'short')} /></span> : null}
        </header>

        {longWait ? (
          <Note icon="clock" action={{ label: t('hotelProviderContactSupport'), onPress: () => go('HL-TODY-05', { to: 'support' }) }}>
            {t('hotelProviderLongWait', { hours: waitedHours })}
          </Note>
        ) : null}

        {rejected && l.rejection ? (
          <section className="hp06__sec" aria-label={t('hotelProviderReasons')}>
            <SectionHeader voice="hotel" level={2} title={t('hotelProviderReasons')} />
            <ul className="hp06__chips">
              {l.rejection.codes.map(c => (
                <li key={c}>
                  <Tag icon="warning-circle">{t(REASON[c])}</Tag>
                </li>
              ))}
            </ul>
            <div className="hp06__note">
              <UserText role="body">{bi(l.rejection.note)}</UserText>
            </div>
            {paidLine ? <Note tone="quiet" icon="coins" action={view?.refunded ? undefined : { label: t('hotelProviderContactSupport'), onPress: () => go('HL-TODY-05', { to: 'support' }) }}>{paidLine}</Note> : null}
            {!l.planCycle && !exempt ? (
              <Button variant="tertiary" onClick={() => go('HL-PROV-04')}>
                {t('hotelProviderChoosePlanAgain')}
              </Button>
            ) : null}
          </section>
        ) : null}

        <section className="hp06__sec" aria-label={t('hotelProviderListingLabel')}>
          <ProviderListingCard listing={l} exempt={exempt} />
        </section>

        <section className="hp06__sec" aria-label={t('hotelProviderTimeline')}>
          <SectionHeader voice="hotel" level={2} title={t('hotelProviderTimeline')} />
          <ReviewTimeline listing={{ ...l, history: l.history.map((h, i) => ({ ...h, id: `${h.id}#${i}` })) }} />
        </section>

        <section className="hp06__sec hp06__facts" aria-label={t('hotelProviderFacts')}>
          {l.submittedAt ? <Fact icon="calendar" k={t('hotelProviderFactSubmitted')} v={`${f.date(l.submittedAt.slice(0, 10), 'short')} · ${f.time(l.submittedAt)}`} /> : null}
          {exempt ? <Fact icon="coins" k={t('hotelProviderFactFees')} v={t('hotelProviderFactNoFees')} /> : l.billing.status === 'paid' || view?.paidFils ? <Fact icon="coins" k={t('hotelProviderFactFees')} v={t('hotelProviderFactPaid')} /> : <Fact icon="coins" k={t('hotelProviderFactFees')} v={t('hotelProviderFactRatesSoon')} />}
          {isLive && days !== null ? <Fact icon="timer" k={t('hotelProviderFactPlanEnds')} v={`${f.date(l.endsOn as string, 'short')} · ${t('hotelProviderDaysLeft', { days })}`} /> : null}
        </section>

        {live && l.status === 'pending_review' && !view?.revision ? (
          <section className="hp06__proto" data-gz-id="proto" aria-label={t('hotelProviderProtoTitle')}>
            <p className="gz-t-label hp06__protolabel">{t('hotelProviderProtoTitle')}</p>
            <div className="hp06__protobtns">
              <Button variant="secondary" onClick={() => moderate(true)}>
                {t('hotelProviderProtoApprove')}
              </Button>
              <Button variant="secondary" onClick={() => moderate(false)}>
                {t('hotelProviderProtoReject')}
              </Button>
            </div>
          </section>
        ) : null}
      </div>
    </Screen>
  )
}

function Fact({ icon, k, v }: { icon: IconName; k: string; v: string }) {
  return (
    <div className="hp06__fact">
      <span className="hp06__factk"><Icon name={icon} size="sm" tone="secondary" label={k} /></span>
      <span className="gz-t-body hp06__factv">
        <Figures text={v} />
      </span>
    </div>
  )
}
