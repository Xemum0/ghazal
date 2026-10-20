// HL-GROW-01 Voucher prices: the venue's voucher-price settings by state (Active, Scheduled, Ended): the standing voucher prices of every
// package ("Always on") and the time-boxed windows that lower the voucher price for chosen event dates. Windows replace offers, flash
// sales and venue coupon codes (ADR 0033 D4). The place to pause, end or duplicate a window; with nothing active it turns the venue's open
// weekend dates into the next step.
// Text diet (ADR 0034): glyph tabs with one word under the chosen one, rows of a price and glyph facts, the open dates as a figure over a
// calendar drawing, the pricing rule behind the (i) of the bar, every empty state one drawing and a title.
// Requirements: HA-OFFR-05, HA-OFFR-06, HA-OFFR-02, HA-OFFR-03, HA-AUTH-02, HA-VMGT-11
// States: loading, empty (no active window), no-results (a tab with nothing in it), error, offline, window-actions-sheet, role-limited.
// Roles (ADR 0008 D12): Admin, Manager and Marketing see this screen; Reception and Accountant do not (role-limited).
import { useEffect, useState } from 'react'
import { softDatesFor } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, EmptyState, ErrorState, Icon, IconTabs, Illustration, InfoSheet, PullToRefresh, Screen, Skeleton, Tag, TopBar, useNav } from '../../../system'
import { Fig, Fx, dm, useWords } from './_components/bits'
import { StandingRow, WindowRow } from './_components/WindowRow'
import { WindowActions } from './_components/WindowActions'
import { StaticSheet } from './_components/SheetFrame'
import { useWindowSheet } from './_components/useWindowSheet'
import { STANDING_ID, tabOf, VENUE_ID, type WindowRecord, type WindowTab } from './_components/model'
import { useGrow } from './_components/store'
import './HL-GROW-01.css'

export const states = ['loading', 'empty', 'no-results', 'error', 'offline', 'window-actions-sheet', 'role-limited']

export default function VoucherPrices() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t, c } = useWords()
  const stored = useGrow(s => s.windows)
  const highlight = useGrow(s => s.highlight)
  const openWindow = useGrow(s => s.openWindow)
  const [tab, setTab] = useState<WindowTab>(state === 'no-results' ? 'ended' : 'active')
  const [rules, setRules] = useState(false)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const limited = state === 'role-limited'
  const openSheet = useWindowSheet(offline)

  // `empty` draws a venue with no active window; `no-results` an Ended tab with nothing in it.
  const windows: WindowRecord[] = state === 'empty' ? stored.filter(w => w.status !== 'active') : state === 'no-results' ? [] : stored
  const inTab = (k: WindowTab) => windows.filter(w => tabOf(w) === k)
  const shown = inTab(tab)
  const soft = softDatesFor(VENUE_ID)

  // The toast's View: open the new window's sheet once the list is on screen.
  useEffect(() => {
    if (!openWindow || state) return
    useGrow.getState().requestOpen(null)
    setTab(useGrow.getState().windows.find(w => w.id === openWindow)?.status ?? 'active')
    openSheet(openWindow)
  }, [openWindow, openSheet, state])

  const newWindow = (prefill?: boolean) => {
    const g = useGrow.getState()
    g.resetDraft(prefill ? { eventDates: [...soft], prefilled: true } : undefined)
    g.setOrigin('list')
    nav.push('HL-GROW-02', prefill ? { from: 'list', dates: soft } : { from: 'list' })
  }

  const top = (
    <>
      <TopBar title={t('hotelGrowListTitle')} actions={[{ icon: 'info', label: c('commonA11yInfo'), onPress: () => setRules(true) }]} />
      {offline ? <Banner tone="offline">{t('hotelGrowOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )

  const rulesSheet = (
    <InfoSheet open={rules} onClose={() => setRules(false)} title={t('hotelGrowRulesTitle')}>
      <p>{t('hotelGrowBestOnly')}</p>
    </InfoSheet>
  )

  if (limited) {
    return (
      <Screen top={<TopBar title={t('hotelGrowListTitle')} />}>
        <ErrorState kind="no-access" />
      </Screen>
    )
  }

  const emptyActive = tab === 'active' && shown.length === 0 && !loading && !error
  const bottom = loading || error ? null : (
    <ActionBar
      action={
        emptyActive && soft.length > 0
          ? { label: t('hotelGrowLowerPrice'), onPress: () => newWindow(true), iconEnd: 'chevron-right' }
          : { label: t('hotelGrowNewWindow'), onPress: () => newWindow(), iconEnd: 'plus' }
      }
    />
  )

  const softLabel = t('hotelGrowSoftInsight', { count: soft.length, days: 60 })
  let body
  if (loading) {
    body = (
      <div className="go-list__skel" aria-busy="true">
        <Skeleton variant="line" blockSize={56} />
        {[0, 1, 2].map(i => (
          <div key={i} className="go-list__skelrow">
            <div className="go-list__skelcol">
              <Skeleton variant="line" inlineSize={176} blockSize={24} />
              <Skeleton variant="line" inlineSize={96} blockSize={24} />
              <Skeleton variant="line" inlineSize={216} blockSize={20} />
            </div>
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" body={t('hotelGrowErrorBody')} onRetry={() => nav.replace('HL-GROW-01')} />
  } else {
    body = (
      <>
        <div className="go-list__tabs">
          <IconTabs<WindowTab>
            label={t('hotelGrowTabsLabel')}
            value={tab}
            onChange={setTab}
            items={[
              { value: 'active', icon: 'bolt', label: t('hotelGrowTabActive') },
              { value: 'scheduled', icon: 'hourglass', label: t('hotelGrowTabScheduled') },
              { value: 'ended', icon: 'calendar-check', label: t('hotelGrowTabEnded') },
            ]}
          />
        </div>

        {tab === 'active' || shown.length > 0 ? (
          <>
            {tab === 'active' && shown.length > 0 && soft.length > 0 ? (
              <div className="go-list__insight-wrap">
                <button type="button" className="gz-reset gz-press go-list__insight" onClick={() => newWindow(true)}>
                  <Illustration name="calendar" size="sm" />
                  <span className="go-list__insight-text">
                    <span className="gz-t-fig-xl go-list__insight-fig">
                      <Fig>{f.integer(soft.length)}</Fig>
                    </span>
                    <span className="gz-t-caption go-list__insight-sub">{t('hotelGrowOpenDates')}</span>
                  </span>
                  <span className="gz-sr-only">{softLabel}</span>
                  <Icon name="chevron-right" size="sm" tone="secondary" />
                </button>
              </div>
            ) : null}
            <div className="go-list__rows" role="list">
              {tab === 'active' ? (
                <div role="listitem">
                  <StandingRow onOpen={() => (state ? undefined : openSheet(STANDING_ID))} />
                </div>
              ) : null}
              {shown.map(w => (
                <div role="listitem" key={w.id}>
                  <WindowRow window={w} isNew={w.id === highlight} onOpen={() => (state ? undefined : openSheet(w.id))} />
                </div>
              ))}
            </div>
            {tab === 'active' && shown.length === 0 ? (
              <div className="go-list__empty">
                <EmptyState fill={false} illustration="empty-vouchers" title={t('hotelGrowEmptyTitle')} />
                {soft.length > 0 ? (
                  <section className="go-list__dates" aria-label={softLabel}>
                    <Icon name="calendar-dots" size="sm" tone="primary" />
                    <ul className="go-list__chips">
                      {soft.map(d => (
                        <li key={d}>
                          <Tag icon="calendar">
                            <Fx text={dm(f, d)} />
                          </Tag>
                        </li>
                      ))}
                    </ul>
                  </section>
                ) : null}
              </div>
            ) : null}
          </>
        ) : (
          <EmptyState
            fill={false}
            illustration={tab === 'scheduled' ? 'calendar' : 'shelf'}
            title={t(tab === 'scheduled' ? 'hotelGrowNoScheduledTitle' : 'hotelGrowNoEndedTitle')}
            action={{ label: t('hotelGrowShowActive'), onPress: () => setTab('active') }}
          />
        )}
      </>
    )
  }

  const sample = stored.find(w => w.status === 'active') ?? stored[0]
  return (
    <div className="go-list__root">
      <Screen top={top} bottom={bottom} bodyClassName="go-list">
        <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
      </Screen>
      {rulesSheet}
      {state === 'window-actions-sheet' && sample ? (
        <StaticSheet label={t('hotelGrowActionsLabel')}>
          <WindowActions window={sample} onPauseToggle={() => undefined} onDuplicate={() => undefined} onEnd={() => undefined} />
        </StaticSheet>
      ) : null}
    </div>
  )
}
