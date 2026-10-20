// CL-MSGS-04 Notifications (pushed from the bell on Discover Home, My Wedding and Messages). Requirements: CA-NOTI-01..08, CA-VCH-13, CA-VIS-06.
// The in-app record of request updates (approved with the hours left; confirmed; not accepted; expired), voucher events (ready, still yours,
// redeemed, expiring, refunded), visit and group-chat events, messages and wedding planning, grouped by day, newest first. Each row is a
// glyph, at most two words, the venue as a quiet line and the clock (NtfRow); each lands on the exact object (landing.ts). The filter is a
// row of six glyphs with the one word of the selected one underneath, then `Unread` and `Read all`. The notification pre-prompt sheet opens
// once, after the first request (never at launch); if the system permission is denied a quiet banner says so, and the sentence that
// updates still appear here is behind its info glyph. A venue that is no longer listed says so with a drawing and similar halls.
// Text diet (ADR 0034): no body sentences on rows, no paragraphs on the screen; empty states are a drawing, a title and one action.
// States: loading, empty, error, offline, unread-only, pre-prompt, os-denied-banner, target-missing.
import { Fragment, useEffect, useMemo, useState } from 'react'
import { Banner, Button, Chip, EmptyState, ErrorState, IconTabs, InfoButton, PullToRefresh, Screen, Sheet, Skeleton, TopBar, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { MissingSheet } from './_components/MissingSheet'
import { NtfRow } from './_components/NtfRow'
import { PromptSheet } from './_components/PromptSheet'
import { useNotificationLanding } from './_components/landing'
import { filterOfKind, useNotificationFeed, type NtfFilter } from './_components/ntf'
import { useMsgStore } from './_components/store'
import { useMsg } from './_components/useMsg'
import './CL-MSGS-04.css'

export const states = ['loading', 'empty', 'error', 'offline', 'unread-only', 'pre-prompt', 'os-denied-banner', 'target-missing']

/** The frame's stand-in for a venue that has left Ghazal: the story's price-drop venue (the notification row exists in the seed). */
const MISSING_VENUE = 'V09'

export default function Notifications() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, tc, f, live, auth } = useMsg()
  const land = useNotificationLanding()
  const feed = useNotificationFeed()
  const permission = useMsgStore(s => s.permission)
  const promptShown = useMsgStore(s => s.promptShown)
  const [filter, setFilter] = useState<NtfFilter>('all')
  const [unreadOnly, setUnreadOnly] = useState(state === 'unread-only')
  const [missing, setMissing] = useState<string | null>(null)

  const guest = live && auth === 'guest'
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty' || guest
  const denied = state === 'os-denied-banner' || permission === 'denied'

  // The pre-prompt: once, after the first booking request, a moment after the centre has settled.
  useEffect(() => {
    if (!live || guest || promptShown || permission !== 'unknown') return
    const handle = window.setTimeout(() => {
      useMsgStore.getState().markPromptShown()
      nav.openSheet(<PromptSheet />)
    }, 700)
    return () => window.clearTimeout(handle)
  }, [live, guest, promptShown, permission]) // eslint-disable-line react-hooks/exhaustive-deps

  const items = empty ? [] : feed.items
  const unreadCount = items.filter(n => !n.read).length
  // The unread switch is a snapshot taken when it is turned on: rows do not jump out from under the thumb as they are read.
  const [snap, setSnap] = useState<Set<string>>(() => new Set(items.filter(n => !n.read).map(n => n.id)))
  const toggleUnread = () => {
    if (!unreadOnly) setSnap(new Set(items.filter(n => !n.read).map(n => n.id)))
    setUnreadOnly(v => !v)
  }
  const shown = items.filter(n => (filter === 'all' || filterOfKind(n.kind) === filter) && (!unreadOnly || snap.has(n.id)))

  const groups = useMemo(() => {
    const out: { day: string; items: typeof shown }[] = []
    for (const n of shown) {
      const day = f.isoDay(n.at)
      const last = out[out.length - 1]
      if (last && last.day === day) last.items.push(n)
      else out.push({ day, items: [n] })
    }
    return out
  }, [shown, f])

  /** `Today`, then the date (`11 November`): a day header is two words at most. */
  const dayLabel = (day: string): string => (f.daysUntil(day) === 0 ? f.relativeDay(day) : f.date(day, 'dayMonth'))

  const markAll = () => {
    usePrototype.getState().markAllNotificationsRead('client')
    setSnap(new Set())
    nav.toast({ message: t('clientMessagesNtfAllRead'), tone: 'success' })
  }

  const top = (
    <>
      <TopBar title={t('clientMessagesNtfTitle')} actions={[{ icon: 'settings', label: t('clientMessagesNtfPrefs'), onPress: () => nav.push('CL-PROF-04') }]} />
      {offline ? <Banner tone="offline">{t('clientMessagesOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )

  let body
  if (loading) {
    body = (
      <div className="gzm-nt__skel" aria-busy="true">
        {[0, 1, 2, 3, 4].map(i => (
          <div key={i} className="gzm-nt__skelrow">
            <Skeleton variant="circle" inlineSize={40} />
            <div className="gzm-nt__skelcol">
              <Skeleton variant="line" inlineSize={i % 2 ? 160 : 208} blockSize={24} />
              <Skeleton variant="line" inlineSize={136} blockSize={20} />
            </div>
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('CL-MSGS-04')} />
  } else if (empty) {
    body = (
      <EmptyState
        illustration="empty-notifications"
        title={t('clientMessagesNtfEmptyTitle')}
        action={{ label: t('clientMessagesEmptyAction'), variant: 'primary', onPress: () => nav.switchTab('discover') }}
      />
    )
  } else {
    body = (
      <>
        {denied ? (
          <div className="gzm-nt__denied">
            <Banner tone="info" icon="bell" action={{ label: t('clientMessagesNtfOpenSettings'), onPress: () => nav.toast(t('clientMessagesNtfSettingsToast')) }}>
              <span className="gzm-nt__denied-text">
                <strong className="gzm-nt__denied-title">{t('clientMessagesNtfDeniedTitle')}</strong>
                <InfoButton title={t('clientMessagesNtfTitle')}>{t('clientMessagesNtfDeniedInfo')}</InfoButton>
              </span>
            </Banner>
          </div>
        ) : null}
        <div className="gzm-nt__tabs">
          <IconTabs<NtfFilter>
            label={t('clientMessagesNtfFilterGroup')}
            value={filter}
            onChange={setFilter}
            items={[
              { value: 'all', icon: 'list', label: tc('commonFilterAll') },
              { value: 'bookings', icon: 'send', label: t('clientMessagesNtfBookings') },
              { value: 'vouchers', icon: 'ticket', label: t('clientMessagesNtfVouchers') },
              { value: 'visits', icon: 'calendar-check', label: t('clientMessagesNtfVisits') },
              { value: 'messages', icon: 'chat', label: t('clientMessagesNtfMessages') },
              { value: 'planning', icon: 'checklist', label: t('clientMessagesNtfPlanning') },
            ]}
          />
        </div>
        <div className="gzm-nt__tools">
          <Chip selected={unreadOnly} onClick={toggleUnread}>
            {t('clientMessagesNtfUnreadOnly')}
          </Chip>
          {unreadCount > 0 ? (
            <Button variant="tertiary" iconStart="check-double" onClick={markAll} disabled={offline}>
              {t('clientMessagesNtfMarkAll')}
            </Button>
          ) : null}
        </div>
        {shown.length === 0 ? (
          <EmptyState
            fill={false}
            illustration={unreadOnly ? 'seal' : 'empty-notifications'}
            title={unreadOnly ? t('clientMessagesNtfUnreadEmptyTitle') : tc('commonStateTitleEmpty')}
            action={{ label: t('clientMessagesNtfShowAll'), onPress: () => { setUnreadOnly(false); setFilter('all') } }}
          />
        ) : (
          groups.map(g => (
            <Fragment key={g.day}>
              <h2 className="gzm-nt__day gz-t-label">{dayLabel(g.day)}</h2>
              <ul className="gzm-nt__group">
                {g.items.map((n, i) => (
                  <li key={n.id}>
                    <NtfRow
                      notification={n}
                      last={i === g.items.length - 1}
                      onOpen={() => {
                        const result = land(n)
                        if (result.missingVenueId) setMissing(result.missingVenueId)
                      }}
                    />
                  </li>
                ))}
              </ul>
            </Fragment>
          ))
        )}
      </>
    )
  }

  const missingId = missing ?? (state === 'target-missing' ? MISSING_VENUE : null)
  return (
    <div className="gzm-nt__root">
      <Screen top={top} bodyClassName="gzm-nt">
        <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
      </Screen>
      {state === 'pre-prompt' ? (
        <Sheet dismissible={false}>
          <PromptSheet inert />
        </Sheet>
      ) : null}
      {missingId ? (
        <Sheet onRequestClose={() => setMissing(null)} dismissible={state !== 'target-missing'}>
          <MissingSheet venueId={missingId} />
        </Sheet>
      ) : null}
    </div>
  )
}
