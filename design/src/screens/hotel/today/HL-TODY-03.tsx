// HL-TODY-03 Notifications: everything the system told the venue, grouped by absolute day, with read and unread state. A new booking
// request is the one row that stands out (gold-tint disk, `Needs reply` tag, time left); everything else is quiet ink. Each row opens
// its object with a rebuilt back stack (ADR 0008 D13). Types (ADR 0033): new request, client confirmed, confirm window ended, voucher
// redeemed by you, visit request and visit chat message, listing approved or not approved, plan ending. No deposit or balance alerts.
// Text diet (docs/design/02-text-diet.md): a row is a glyph, a name and its facts (the kind is the glyph, the sentence is read); the filter
// is two glyph tabs (the unread count is a badge) with the word under the selected one; mark all as read is a double tick; the empty states are a drawing and two words.
// Requirements: HA-NOTI-01..07, HA-DASH-05
// States: loading, empty, error, offline, unread-filter, new-request-banner, push-denied
import { Fragment, useMemo, useState } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Banner, Button, EmptyState, ErrorState, Figures, Icon, IconButton, IconTabs, PullToRefresh, Screen, Skeleton, TopBar, useNav, type IconTabItem } from '../../../system'
import { NotifRow } from './_components/NotifRow'
import { NewRequestBanner } from './_components/Overlays'
import { useAccountKind, useWords } from './_components/bits'
import { useHotelNotifications } from './_components/data'
import { useNotificationLanding } from './_components/landing'
import { PROTOTYPE_TODAY } from '../../../mock'
import './HL-TODY-03.css'

export const states = ['loading', 'empty', 'error', 'offline', 'unread-filter', 'new-request-banner', 'push-denied']

type Filter = 'all' | 'unread'

export default function Notifications() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t, c } = useWords()
  const land = useNotificationLanding()
  const account = useAccountKind()
  const all = useHotelNotifications(account)
  const [filter, setFilter] = useState<Filter>(state === 'unread-filter' ? 'unread' : 'all')
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'

  const list = empty ? [] : all
  const unread = list.filter(n => !n.read)
  // The unread tab is a snapshot taken when you switch to it: rows do not jump under the thumb as they are read.
  const [snap, setSnap] = useState<Set<string>>(() => new Set(unread.map(n => n.id)))
  const choose = (next: Filter) => {
    if (next === 'unread') setSnap(new Set(unread.map(n => n.id)))
    setFilter(next)
  }
  const shown = filter === 'unread' ? list.filter(n => snap.has(n.id)) : list

  const groups = useMemo(() => {
    const out: { day: string; items: typeof shown }[] = []
    for (const n of shown) {
      const day = n.at.slice(0, 10)
      const last = out[out.length - 1]
      if (last && last.day === day) last.items.push(n)
      else out.push({ day, items: [n] })
    }
    return out
  }, [shown])

  const markAll = () => {
    usePrototype.getState().markAllNotificationsRead('hotel')
    setSnap(new Set())
    nav.toast({ message: t('hotelTodayAllRead'), tone: 'success' })
  }

  const top = (
    <>
      <TopBar title={t('hotelTodayBell')} actions={[{ icon: 'settings', label: t('hotelTodayPrefs'), onPress: () => nav.push('HL-SETT-02') }]} />
      {offline ? (
        <Banner tone="offline">
          <Figures text={f.time(f.now())} />
          <span className="gz-sr-only">{t('hotelTodayOfflineStamp', { time: f.time(f.now()) })}</span>
        </Banner>
      ) : null}
    </>
  )

  // Two glyph tabs, the word under the selected one; the unread count rides on the envelope as a badge (no sentence, no `(3)`).
  const tabs: IconTabItem<Filter>[] = [
    { value: 'all', icon: 'list', label: c('commonFilterAll') },
    { value: 'unread', icon: 'mail', label: t('hotelTodayInboxUnread'), count: unread.length || undefined },
  ]
  const controls = (
    <div className="ht-nt__controls">
      <IconTabs<Filter> label={t('hotelTodayNotifFilter')} items={tabs} value={filter} onChange={choose} />
    </div>
  )

  let body
  if (loading) {
    body = (
      <div className="ht-nt__skel" aria-busy="true">
        {[0, 1, 2, 3, 4].map(i => (
          <div key={i} className="ht-nt__skelrow">
            <Skeleton variant="circle" inlineSize={40} />
            <div className="ht-nt__skelcol">
              <Skeleton variant="line" inlineSize={208} blockSize={24} />
              <Skeleton variant="line" blockSize={20} />
              <Skeleton variant="line" inlineSize={136} blockSize={20} />
            </div>
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-TODY-03')} />
  } else if (empty) {
    body = <EmptyState illustration="empty-notifications" title={t('hotelTodayNotifEmptyTitle')} />
  } else {
    body = (
      <>
        {controls}
        {state === 'push-denied' ? (
          <div className="ht-nt__denied">
            <span className="ht-nt__denied-disk" aria-hidden="true">
              <Icon name="bell" size="sm" tone="secondary" />
            </span>
            <p className="ht-nt__denied-title gz-t-title">{t('hotelTodayPushDeniedTitle')}</p>
            <Button variant="secondary" size="sm" onClick={() => nav.toast(t('hotelTodayPushDeniedToast'))}>
              {t('hotelTodayOpenSettings')}
            </Button>
          </div>
        ) : null}
        {shown.length === 0 ? (
          <EmptyState fill={false} illustration="seal" title={t('hotelTodayNotifUnreadEmptyTitle')} action={{ label: t('hotelTodayNotifShowAll'), onPress: () => choose('all') }} />
        ) : (
          groups.map((g, gi) => (
            <Fragment key={g.day}>
              <div className="ht-nt__day">
                <h2 className="ht-nt__day-label gz-t-label">{g.day === PROTOTYPE_TODAY ? c('commonLabelToday') : f.date(g.day, 'short')}</h2>
                {gi === 0 && unread.length > 0 ? <IconButton icon="check-double" iconSize="sm" label={t('hotelTodayMarkAllRead')} onClick={markAll} disabled={offline} /> : null}
              </div>
              <ul className="ht-nt__group">
                {g.items.map((n, i) => (
                  <NotifRow key={n.id} notification={n} last={i === g.items.length - 1} onOpen={() => land(n)} />
                ))}
              </ul>
            </Fragment>
          ))
        )}
      </>
    )
  }

  return (
    <div className="ht-nt__root">
      <Screen top={top} bodyClassName="ht-nt">
        <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
      </Screen>
      {state === 'new-request-banner' ? <NewRequestBanner autoDismiss onOpen={() => nav.push('HL-BOOK-03', { bookingId: 'bk-GZ-2611-0147' })} /> : null}
    </div>
  )
}
