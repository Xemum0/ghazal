// HL-PROV-02 My listings (tab root for a service provider, the slot of Calendar; reached from More for a hotel that also lists services).
// Every listing with its lifecycle pill, plan line and the one next step: Choose a plan, Fix and resubmit, Renew. A listing is never live
// because it was paid for: In review and Approved are their own cards. Major hotels see "No listing fees" and no payment steps.
// Requirements: PA-LST-01, PA-LST-03, PA-LST-04, PA-ADS-05, PA-REV-02
// States: empty, loading, error, offline, expiring-plan, rejected-needs-changes, fee-exempt, role-limited
import { useMemo } from 'react'
import { engine } from '../../../mock'
import type { Listing } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, EmptyState, ErrorState, MajorHotelBadge, PullToRefresh, Screen, SectionHeader, Skeleton, TopBar, useNav } from '../../../system'
import { ListingItem } from './_components/ListingItem'
import { Note, OfflineStrip, useFormat, useP } from './_components/bits'
import { PROVIDER_ID, accountOf, daysLeft, groupOf, isAccountKind, isExpiring, openTarget, sortListings, today, type AccountKind, type Group } from './_components/model'
import { useProv } from './_components/store'
import './HL-PROV-02.css'

export const states = ['empty', 'loading', 'error', 'offline', 'expiring-plan', 'rejected-needs-changes', 'fee-exempt', 'role-limited']

const GROUPS: readonly Group[] = ['attention', 'running', 'ended']
const TITLE = { attention: 'hotelProviderListGroupAttention', running: 'hotelProviderListGroupRunning', ended: 'hotelProviderListGroupEnded' } as const

export default function MyListings() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t } = useP()
  const viewer = useProv(s => s.viewer)
  const all = usePrototype(s => s.listings)

  const kind: AccountKind = state === 'fee-exempt' ? 'major' : isAccountKind(nav.params.account) ? nav.params.account : viewer
  const account = accountOf(kind)
  const readOnly = state === 'role-limited'
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  // The demo account is Zahra Floral Studio. A hotel that also lists sees only what it created; the fee-exempt frame borrows the demo set.
  const demo = kind === 'provider' || state === 'fee-exempt'
  const list: Listing[] = useMemo(() => {
    if (state === 'empty') return []
    const mine = all.filter(l => l.providerId === PROVIDER_ID && (demo || l.id.startsWith('lst-proto-')))
    // expiring-plan: the live listing's plan ends five days from the prototype clock.
    return sortListings(state === 'expiring-plan' ? mine.map(l => (l.status === 'active' && l.id === 'lst-flowers-zahra' ? { ...l, endsOn: engine.addDays(today(), 5) } : l)) : mine)
  }, [all, demo, state])

  const exempt = account.exempt
  const expiring = list.find(isExpiring)
  const rejected = list.filter(l => l.status === 'rejected')
  const showRejectedBanner = state === 'rejected-needs-changes' && rejected.length > 0

  const openEditor = () => nav.push('HL-PROV-03', { account: kind })
  const go = (to: string, params: Record<string, unknown>) => nav.push(to, { ...params, account: kind })

  const top = (
    <>
      <TopBar variant="large-title" title={t('hotelProviderListTitle')} />
      {offline ? <OfflineStrip /> : null}
    </>
  )
  const bottom = loading || error ? undefined : (
    <ActionBar
      action={{
        label: t('hotelProviderListNew'),
        iconEnd: 'plus',
        disabled: readOnly || offline,
        reason: readOnly ? t('hotelProviderListRoleReason') : offline ? t('hotelProviderNeedsConnection') : undefined,
        onPress: openEditor,
      }}
    />
  )

  let body
  if (loading) {
    body = (
      <div className="hp02" aria-busy="true">
        <Skeleton variant="block" blockSize={112} />
        <Skeleton variant="block" blockSize={112} />
        <Skeleton variant="block" blockSize={112} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelProviderListErrorTitle')} body={t('hotelProviderListErrorBody')} onRetry={() => nav.replace('HL-PROV-02', { account: kind })} />
  } else if (list.length === 0) {
    body = (
      <div className="hp02">
        {exempt ? <MajorHotelBadge /> : null}
        <EmptyState fill={false} illustration="empty-listings" title={t('hotelProviderListEmptyTitle')} />
      </div>
    )
  } else {
    body = (
      <div className="hp02">
        {readOnly ? <Note tone="quiet" icon="lock">{t('hotelProviderListRoleReason')}</Note> : null}
        {exempt ? <MajorHotelBadge /> : null}
        {showRejectedBanner ? (
          <Note
            tone="danger"
            action={readOnly ? undefined : { label: t('hotelProviderStepFix'), onPress: () => go('HL-PROV-03', { listingId: rejected[0]?.id }) }}
          >
            {t('hotelProviderListRejectedBanner', { count: rejected.length })}
          </Note>
        ) : null}
        {expiring && !exempt ? (
          <Note
            icon="clock"
            action={readOnly ? undefined : { label: t('hotelProviderStepRenew'), onPress: () => go('HL-PROV-04', { listingId: expiring.id, renewal: true }) }}
          >
            {t('hotelProviderListExpiryBanner', { days: daysLeft(expiring.endsOn) ?? 0, date: expiring.endsOn ? f.date(expiring.endsOn, 'short') : '' })}
          </Note>
        ) : null}
        {GROUPS.map(g => {
          const items = list.filter(l => groupOf(l) === g)
          if (!items.length) return null
          return (
            <section key={g} className="hp02__group" data-group={g}>
              <SectionHeader voice="hotel" level={2} title={t(TITLE[g], { count: items.length })} />
              <ul className="hp02__list">
                {items.map(l => (
                  <ListingItem
                    key={l.id}
                    listing={l}
                    exempt={exempt}
                    readOnly={readOnly}
                    onOpen={() => {
                      const o = openTarget(l)
                      go(o.to, o.params)
                    }}
                    onStep={go}
                  />
                ))}
              </ul>
            </section>
          )
        })}
      </div>
    )
  }

  return (
    <Screen top={top} bottom={bottom}>
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
