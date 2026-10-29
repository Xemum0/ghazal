// CL-MSGS-01 Messages (Messages tab root). Requirements: CA-CHAT-01, CA-CHAT-05, CA-CHAT-10, CA-NOTI-06, CA-VIS-03.
// One thread per counterpart (venue, planner, service provider, Ghazal Support) plus one group chat per site visit, each a monogram, a name,
// a clock, one short line of the last message and the unread count. The filter is a row of glyphs (hall, visit, planner, services, support)
// with the one word of the selected one underneath; the Visits glyph holds the group chats, which open CL-VIST-03. Support is pinned on top
// and always available. The bell opens the notification centre. An
// empty inbox is a drawing, three words and one action. Offline keeps the cached conversations under a one-line stamp.
// Text diet (ADR 0034): no sentences on the screen; the status of a request is a glyph after the name, the context line is gone.
// States: loading, empty, error, offline.
import { useMemo, useState } from 'react'
import { Banner, EmptyState, ErrorState, IconTabs, PullToRefresh, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { MsgInboxRow as InboxRow } from './_components/MsgInboxRow'
import { filterOf, useInbox, type InboxFilter, type RowModel } from './_components/model'
import { useNotificationFeed } from './_components/ntf'
import { useMsg } from './_components/useMsg'
import './CL-MSGS-01.css'

export const states = ['loading', 'empty', 'error', 'offline']

export default function Inbox() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, tc, f, lang } = useMsg()
  const [filter, setFilter] = useState<InboxFilter>('all')
  const feed = useNotificationFeed()
  const inbox = useInbox(lang)

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'

  // The cached rows of an offline frame are the same rows as the default.
  const rows = useMemo<RowModel[]>(() => (empty ? [] : inbox), [empty, inbox])

  const shown = filter === 'all' ? rows : rows.filter(r => filterOf(r.conversation) === filter)
  const bell = { icon: 'bell' as const, label: t('clientMessagesBellUnread', { count: feed.unread }), count: feed.unread || undefined, onPress: () => nav.push('CL-MSGS-04') }

  const open = (r: RowModel) => {
    if (r.conversation.kind === 'support') nav.push('CL-MSGS-02', { support: true })
    else if (r.conversation.kind === 'visit_group') nav.push('CL-VIST-03', { visitId: r.conversation.visitId, conversationId: r.conversation.id })
    else nav.push('CL-MSGS-02', { conversationId: r.conversation.id, venueId: r.conversation.venueId ?? undefined })
  }

  const top = (
    <>
      <TopBar variant="large-title" title={t('clientMessagesInboxTitle')} back={false} actions={[bell]} />
      {offline ? <Banner tone="offline">{t('clientMessagesOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )

  let body
  if (loading) {
    body = (
      <div className="gzm-ib__skel" aria-busy="true">
        {[0, 1, 2, 3, 4].map(i => (
          <div key={i} className="gzm-ib__skelrow">
            <Skeleton variant="circle" inlineSize={56} />
            <div className="gzm-ib__skelcol">
              <Skeleton variant="line" inlineSize={i % 2 ? 176 : 216} blockSize={24} />
              <Skeleton variant="line" blockSize={24} />
            </div>
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('CL-MSGS-01')} />
  } else if (rows.length === 0) {
    body = (
      <EmptyState
        illustration="empty-messages"
        title={t('clientMessagesEmptyTitle')}
        action={{ label: t('clientMessagesEmptyAction'), variant: 'primary', onPress: () => nav.switchTab('discover') }}
        secondary={{ label: t('clientMessagesEmptySupport'), iconStart: 'headset', onPress: () => nav.push('CL-MSGS-02', { support: true }) }}
      />
    )
  } else {
    body = (
      <>
        <div className="gzm-ib__tabs">
          <IconTabs<InboxFilter>
            label={t('clientMessagesFilterGroup')}
            value={filter}
            onChange={setFilter}
            items={[
              { value: 'all', icon: 'list', label: tc('commonFilterAll') },
              { value: 'venues', icon: 'hall', label: t('clientMessagesFilterVenues') },
              { value: 'visits', icon: 'calendar-check', label: t('clientMessagesFilterVisits') },
              { value: 'planner', icon: 'user', label: t('clientMessagesFilterPlanner') },
              { value: 'providers', icon: 'sparkle', label: t('clientMessagesFilterProviders') },
              { value: 'support', icon: 'headset', label: t('clientMessagesFilterSupport') },
            ]}
          />
        </div>
        {shown.length === 0 ? (
          <EmptyState fill={false} illustration="empty-messages" title={tc('commonStateTitleEmpty')} action={{ label: tc('commonFilterAll'), onPress: () => setFilter('all') }} />
        ) : (
          <ul className="gzm-ib__list">
            {shown.map((r, i) => (
              <InboxRow key={r.conversation.id} row={r} last={i === shown.length - 1} onOpen={() => open(r)} />
            ))}
          </ul>
        )}
      </>
    )
  }

  return (
    <Screen top={top} bodyClassName="gzm-ib">
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
