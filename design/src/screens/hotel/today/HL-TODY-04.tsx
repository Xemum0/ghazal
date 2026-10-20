// HL-TODY-04 Messages: the shared inbox of client conversations (Messages tab root). Who is waiting for me: unread counts, the booking
// each conversation belongs to with the booking's own status pill, `Needs reply` with the elapsed time once a client message is older
// than 30 minutes, Ghazal Support pinned on top. Each site visit opens a three-way group chat (client, hotel representative, Ghazal
// support): it sits in the same list with a group glyph, the visit's day and the three role chips, and opens HL-VIST-03. No swipe actions: a press and hold opens Mark as read or unread (ADR 0014 D4).
// Text diet (docs/design/02-text-diet.md): the filters are glyph tabs with counts (the word shows under the selected one), a row is a
// monogram, a name, one line of the client's own words and its facts (day, status glyph, time waited), the empty states are drawings.
// Requirements: HA-MSG-01, HA-MSG-04, HA-MSG-05, HA-DASH-06, HA-NOTI-05
// States: loading, empty, no-results, error, offline, role-read-only, role-support-only
import { useMemo, useState } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, Button, EmptyState, ErrorState, Figures, Icon, IconTabs, PullToRefresh, Screen, SearchField, Skeleton, TopBar, useNav, type IconTabItem } from '../../../system'
import { matchesSearch } from '../../../system/inputs'
import { getBooking, PROTOTYPE_NOW } from '../../../mock'
import { InboxRow } from './_components/InboxRow'
import { minutesBetween, useAccountKind, useBi, useWords } from './_components/bits'
import { useHotelNotifications, useInboxConversations } from './_components/data'
import { useTodayLocal, unreadOf } from './_components/store'
import './HL-TODY-04.css'

export const states = ['loading', 'empty', 'no-results', 'error', 'offline', 'role-read-only', 'role-support-only']

type Filter = 'all' | 'unread' | 'needs' | 'linked' | 'visit' | 'enquiry'

export default function Inbox() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const [filter, setFilter] = useState<Filter>('all')
  const [query, setQuery] = useState(state === 'no-results' ? 'ZZ' : '')
  const opened = useTodayLocal(s => s.openedConversations)
  const marked = useTodayLocal(s => s.markedUnread)
  const replied = useTodayLocal(s => s.repliedConversations)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const readOnly = state === 'role-read-only'
  const account = useAccountKind()
  const supportOnly = state === 'role-support-only' || account === 'provider'
  const inbox = useInboxConversations()

  const all = useMemo(() => {
    if (state === 'empty') return []
    return supportOnly ? inbox.filter(x => x.kind === 'support') : inbox
  }, [state, supportOnly, inbox])

  const unread = (x: (typeof all)[number]) => unreadOf(x.id, x.unread.hotel, opened, marked)
  const needs = (x: (typeof all)[number]) => Boolean(x.awaitingReplySince) && !replied.includes(x.id) && x.kind !== 'support' && minutesBetween(x.awaitingReplySince ?? PROTOTYPE_NOW, PROTOTYPE_NOW) > 30
  const counts = { unread: all.filter(x => unread(x) > 0).length, needs: all.filter(needs).length }

  const rows = all.filter(x => {
    if (filter === 'unread' && unread(x) === 0) return false
    if (filter === 'needs' && !needs(x)) return false
    if (filter === 'linked' && !x.bookingId) return false
    if (filter === 'visit' && x.kind !== 'visit_group') return false
    if (filter === 'enquiry' && x.kind !== 'enquiry') return false
    const booking = x.bookingId ? getBooking(x.bookingId) : undefined
    return matchesSearch(query, x.clientName, x.title.en, x.title.ar, booking?.ref)
  })

  const openRow = (x: (typeof all)[number]) => {
    useTodayLocal.getState().openConversation(x.id)
    if (x.kind === 'visit_group') nav.push('HL-VIST-03', { visitId: x.visitId })
    else nav.push('HL-TODY-05', { conversationId: x.id, bookingId: x.bookingId, readOnly: readOnly || undefined })
  }

  const longPress = (x: (typeof all)[number]) => {
    const isUnread = unread(x) > 0
    const key = nav.openSheet(
      <div className="ht-ib__menu">
        <Button
          variant="secondary"
          fullWidth
          iconStart={isUnread ? 'check' : 'chat'}
          onClick={() => {
            useTodayLocal.getState().setUnread(x.id, !isUnread)
            nav.closeSheet(key)
          }}
        >
          {isUnread ? t('hotelTodayMarkRead') : t('hotelTodayMarkUnread')}
        </Button>
      </div>,
      { title: x.kind === 'support' ? bi(x.title) : x.clientName },
    )
  }

  const unreadNotifications = useHotelNotifications(account).filter(n => !n.read).length
  const tabs: IconTabItem<Filter>[] = [
    { value: 'all', icon: 'list', label: c('commonFilterAll') },
    { value: 'unread', icon: 'mail', label: t('hotelTodayInboxUnread'), count: counts.unread || undefined },
    { value: 'needs', icon: 'reply', label: t('hotelTodayInboxNeedsReply'), count: counts.needs || undefined },
    { value: 'linked', icon: 'link', label: t('hotelTodayInboxLinked') },
    { value: 'visit', icon: 'users-three', label: t('hotelTodayInboxVisits') },
    { value: 'enquiry', icon: 'help', label: t('hotelTodayInboxEnquiries') },
  ]
  const top = (
    <>
      <TopBar
        variant="large-title"
        title={t('hotelTodayInboxTitle')}
        back={false}
        actions={[{ icon: 'bell', label: unreadNotifications > 0 ? t('hotelTodayBellUnread', { count: unreadNotifications }) : t('hotelTodayBell'), count: unreadNotifications || undefined, onPress: () => nav.push('HL-TODY-03', { account }) }]}
      />
      {offline ? (
        <Banner tone="offline">
          <Figures text={f.time(f.now())} />
          <span className="gz-sr-only">{t('hotelTodayOfflineStamp', { time: f.time(f.now()) })}</span>
        </Banner>
      ) : null}
    </>
  )

  let body
  if (loading) {
    body = (
      <div className="ht-ib__skel" aria-busy="true">
        {[0, 1, 2, 3].map(i => (
          <div key={i} className="ht-ib__skelrow">
            <Skeleton variant="circle" inlineSize={48} />
            <div className="ht-ib__skelcol">
              <Skeleton variant="line" inlineSize={160} blockSize={24} />
              <Skeleton variant="line" blockSize={20} />
              <Skeleton variant="line" inlineSize={136} blockSize={24} />
            </div>
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-TODY-04')} />
  } else if (all.length === 0) {
    body = <EmptyState illustration="empty-messages" title={t('hotelTodayInboxEmptyTitle')} />
  } else {
    body = (
      <>
        {readOnly ? (
          <div className="ht-ib__note">
            <Banner tone="info" icon="lock">
              {t('hotelTodayReadOnly')}
            </Banner>
          </div>
        ) : null}
        {supportOnly ? null : (
          <>
            <div className="ht-ib__search">
              <SearchField label={t('hotelTodayInboxSearchLabel')} placeholder={t('hotelTodayInboxSearch')} value={query} onValueChange={setQuery} />
            </div>
            <div className="ht-ib__chips">
              <IconTabs<Filter> label={t('hotelTodayInboxFilters')} items={tabs} value={filter} onChange={v => setFilter(v)} />
            </div>
          </>
        )}
        {rows.length === 0 ? (
          query ? (
            <EmptyState fill={false} illustration="no-result" title={t('hotelTodayInboxNoResultsTitle')} action={{ label: t('hotelTodayClearSearch'), onPress: () => setQuery('') }} />
          ) : (
            <EmptyState fill={false} illustration="empty-messages" title={t('hotelTodayInboxEmptyTitle')} action={{ label: t('hotelTodayNotifShowAll'), onPress: () => setFilter('all') }} />
          )
        ) : (
          <ul className="ht-ib__list">
            {rows.map((x, i) => (
              <InboxRow
                key={x.id}
                conversation={x}
                unread={unread(x)}
                last={i === rows.length - 1}
                onOpen={() => openRow(x)}
                onLongPress={() => longPress(x)}
              />
            ))}
          </ul>
        )}
        {supportOnly && account !== 'provider' ? (
          <p className="ht-ib__handled gz-t-caption">
            <Icon name="lock" size="xs" tone="secondary" />
            <span>{t('hotelTodayInboxSupportOnly')}</span>
          </p>
        ) : null}
      </>
    )
  }

  return (
    <Screen top={top} bodyClassName="ht-ib">
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
