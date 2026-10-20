// HL-TODY-01 Today: the first screen of the Partner app is already the inbox (ADR 0008 D2-D4). The status in the Ink band is a figure
// (how many requests, the time left on the first), then what needs a decision (requests, visit requests, a listing decision), the three
// quick actions, today's events, the next seven days, the voucher tiles, the messages waiting and the latest notifications.
// Text diet (ADR 0034, docs/design/02-text-diet.md): no greeting, no sentence, no caption; glyphs and figures carry the screen and the
// words left are section titles, three one-word actions and names. Role changes the content, never the navigation (Reception, Accountant and Marketing
// are states of this screen); a service provider gets its own variant (no halls, no availability strip, listing status).
// Voucher model (ADR 0033): there is no revenue, payable or payout anywhere on this screen: the tiles count requests, vouchers and dates.
// Requirements: HA-DASH-01, HA-DASH-03, HA-DASH-04, HA-DASH-05, HA-DASH-06, HA-DASH-07, HA-AUTH-02, HA-AUTH-03, HA-VCH-01, HA-VIS-01, PA-ACC-02, PA-REV-02, HA-ANLY-08
// States: loading, empty, error, offline, role-reception, role-accountant, role-marketing, first-run, new-request-banner, role-provider,
//         visit-request-banner, listing-review-banner, fee-exempt-badge
import { useEffect, useMemo, useRef } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ErrorState, PullToRefresh, Screen, Skeleton, useNav } from '../../../system'
import { FirstRunContent, FirstRunSheet, NewRequestBanner, VenueSwitcherContent, firstRunTitle } from './_components/Overlays'
import { TodayBar, TodayIntro } from './_components/TodayHeader'
import {
  AccountantBlocks,
  BillingBlock,
  BodySkeleton,
  EventsBlock,
  ListingReviewNote,
  MarketingBlocks,
  MessagesBlock,
  NeedsYouBlock,
  NotificationsBlock,
  ProviderBlocks,
  QuickActions,
  StatusBand,
  StripBlock,
  VenueTilesBlock,
  useWindowEnding,
} from './_components/TodayBlocks'
import { roleOfState, useAccountKind, useWords } from './_components/bits'
import { useHotelNotifications, useListingInReview, useNeedsYou } from './_components/data'
import './today.css'

export const states = [
  'loading',
  'empty',
  'error',
  'offline',
  'role-reception',
  'role-accountant',
  'role-marketing',
  'first-run',
  'new-request-banner',
  'role-provider',
  'visit-request-banner',
  'listing-review-banner',
  'fee-exempt-badge',
]

export default function HotelToday() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t } = useWords()
  const kindOfAccount = useAccountKind()
  // The provider variant is drawn for its own states; the review banner and the badge frame are provider and venue states.
  const account = state === 'listing-review-banner' ? 'provider' : kindOfAccount
  const provider = account === 'provider'
  const role = provider ? 'manager' : roleOfState(state)
  const loading = state === 'loading'
  const empty = state === 'empty'
  const error = state === 'error'
  const offline = state === 'offline'
  const entries = useNeedsYou(account)
  const notifications = useHotelNotifications(account)
  const windowEnding = useWindowEnding()
  const inReview = useListingInReview()
  const extra = useMemo(() => (role === 'marketing' && windowEnding ? [windowEnding] : []), [role, windowEnding])
  const unread = empty ? 0 : notifications.filter(n => !n.read).length

  // First sign-in: the notification sheet, then the biometric sheet (ADR 0008 notes); the live prototype opens them on arrival with ?firstRun.
  const asked = useRef(false)
  const params = nav.params as { firstRun?: boolean }
  useEffect(() => {
    if (asked.current || !params.firstRun) return
    asked.current = true
    const second = () => {
      const key = nav.openSheet(<FirstRunContent step="biometric" onPrimary={() => nav.closeSheet(key)} onSkip={() => nav.closeSheet(key)} />, { title: firstRunTitle('biometric', t) })
    }
    const key = nav.openSheet(
      <FirstRunContent
        step="notifications"
        onPrimary={() => {
          nav.closeSheet(key)
          window.setTimeout(second, 360)
        }}
        onSkip={() => {
          nav.closeSheet(key)
          window.setTimeout(second, 360)
        }}
      />,
      { title: firstRunTitle('notifications', t) },
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [nav, params.firstRun])

  const openSwitcher = () => {
    const key = nav.openSheet(<VenueSwitcherContent onSelect={() => nav.closeSheet(key)} />, { title: t('hotelTodaySwitchTitle') })
  }

  const status = loading ? (
    <Skeleton className="ht-skel--dark" variant="line" inlineSize={248} blockSize={24} />
  ) : error ? null : (
    <StatusBand role={role} account={account} items={empty ? [] : [...extra, ...entries]} />
  )

  const stamp = offline ? f.time(f.now()) : undefined
  const refresh = () => new Promise<void>(resolve => window.setTimeout(resolve, 900))

  const top = <TodayBar account={account} multiVenue={!provider} unread={unread} stamp={stamp} onBell={() => nav.push('HL-TODY-03', { account })} onVenue={openSwitcher} />

  let body
  if (loading) body = <BodySkeleton />
  else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-TODY-01')} />
  } else if (provider) {
    body = (
      <>
        {inReview && state !== 'role-provider' && !empty ? <ListingReviewNote listingId={inReview.id} /> : null}
        <NeedsYouBlock account="provider" forceEmpty={empty} />
        <QuickActions account="provider" />
        <ProviderBlocks />
        <NotificationsBlock account="provider" />
      </>
    )
  } else if (role === 'accountant') {
    body = (
      <>
        <AccountantBlocks />
        <EventsBlock />
        <NotificationsBlock />
      </>
    )
  } else if (role === 'marketing') {
    body = (
      <>
        <MarketingBlocks />
        <NeedsYouBlock role="marketing" limitTo={['review', 'window']} extra={extra} />
        <NotificationsBlock />
      </>
    )
  } else if (role === 'reception') {
    body = (
      <>
        <NeedsYouBlock role="reception" />
        <QuickActions prices={false} />
        <EventsBlock />
        <MessagesBlock />
      </>
    )
  } else {
    body = (
      <>
        <NeedsYouBlock role="manager" offline={offline} initiallyExpanded={offline} forceEmpty={empty} />
        <QuickActions />
        <EventsBlock />
        <StripBlock />
        <VenueTilesBlock />
        {state === 'fee-exempt-badge' ? <BillingBlock /> : null}
        {empty ? null : <MessagesBlock />}
        <NotificationsBlock />
      </>
    )
  }

  return (
    <div className="ht-root">
      <Screen top={top} bodyClassName="ht-screen">
        <PullToRefresh onRefresh={refresh}>
          <TodayIntro role={role} account={account} status={status} />
          <div className="ht-body">{body}</div>
        </PullToRefresh>
      </Screen>
      {state === 'new-request-banner' ? <NewRequestBanner autoDismiss onOpen={() => nav.push('HL-BOOK-03', { bookingId: 'bk-GZ-2611-0147' })} /> : null}
      {state === 'visit-request-banner' ? <NewRequestBanner kind="visit" autoDismiss onOpen={() => nav.push('HL-VIST-02', { visitId: 'visit-aurelia-rashed' })} /> : null}
      {state === 'first-run' ? <FirstRunSheet step="notifications" dismissible={false} /> : null}
    </div>
  )
}
