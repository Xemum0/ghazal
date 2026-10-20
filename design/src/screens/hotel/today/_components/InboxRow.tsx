// InboxRow: one conversation of the shared hotel inbox (HA-MSG-01, HA-MSG-04). A monogram in the client's own script (never a face),
// the client's name, one line of the last message in its own script and direction, the clock (today) or the short date, the unread
// count and, in the full variant, the booking context as facts: the event day with the booking's own status glyph, an Enquiry glyph when
// there is no booking, and the time a client message has waited once it is over 30 minutes (ADR 0008 D4; the glyph is an hourglass in
// gold, the sentence is read). Ghazal Support is pinned, carries the Ghazal monogram and never a booking. A visit group chat leads with a
// group glyph (never a face), the visit's day and slot with its own status glyph and the three role glyphs (client, hotel, support).
import { useRef } from 'react'
import type { Conversation } from '@gz/contracts'
import { getBooking, PROTOTYPE_NOW, PROTOTYPE_TODAY } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Avatar, CountBadge, FactRow, Icon, StatusIcon, type VisitState } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { Figures, UserText, clockInstant, minutesBetween, scriptOf, useBi, useDayMonth, useWords } from './bits'
import { TextFact, TimeLeft } from './Facts'
import { lastMessage } from './data'
import { useTodayLocal } from './store'
import './inbox-row.css'

export type InboxRowProps = {
  conversation: Conversation
  /** `full` adds the booking context (the inbox); `compact` is the Today preview. */
  variant?: 'full' | 'compact'
  /** The unread count to show; the screen passes 0 once the thread was opened. */
  unread?: number
  onOpen?: () => void
  /** Press and hold (or the context-menu key): the Mark as read / unread menu. No swipe actions (ADR 0014 D4). */
  onLongPress?: () => void
  last?: boolean
  disabled?: boolean
}

const NEEDS_REPLY_AFTER_MIN = 30

/** A preview is a glimpse, not the message (docs/design/02-text-diet.md section 1: authored text is clamped): about one phone line, so the row
 *  reads the first few words and the thread holds the rest. The row still ellipsises by width on the narrowest screen. */
const PREVIEW_CHARS = 34
const glimpse = (text: string): string => {
  const chars = Array.from(text)
  return chars.length > PREVIEW_CHARS ? `${chars.slice(0, PREVIEW_CHARS).join('').trimEnd()}…` : text
}

const VISIT_STATUS: Record<string, VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}

export function InboxRow({ conversation: c, variant = 'full', unread, onOpen, onLongPress, last = false, disabled }: InboxRowProps) {
  const hold = useRef<{ timer: number; fired: boolean } | null>(null)
  const startHold = () => {
    if (!onLongPress) return
    const h = {
      timer: window.setTimeout(() => {
        h.fired = true
        onLongPress()
      }, 500),
      fired: false,
    }
    hold.current = h
  }
  const endHold = () => {
    if (hold.current) window.clearTimeout(hold.current.timer)
  }
  const f = useFormat()
  const bi = useBi()
  const dayMonth = useDayMonth()
  const { t, c: common } = useWords()
  const { lang } = useLang()
  const support = c.kind === 'support'
  const group = c.kind === 'visit_group'
  const visit = usePrototype(st => (c.visitId ? st.visits.find(v => v.id === c.visitId) : undefined))
  const name = support ? bi(c.title) : c.clientName
  const count = unread ?? c.unread.hotel
  const msg = lastMessage(c.id)
  // The booking's status follows what the manager did in this session (accept, decline), not the fixture.
  const live = usePrototype(s => (c.bookingId ? s.hotelBookings.find(b => b.id === c.bookingId) : undefined))
  const booking = live ?? (c.bookingId ? getBooking(c.bookingId) : undefined)

  let preview = bi(c.subtitle)
  let previewLang: 'ar' | 'en' = lang
  if (msg) {
    if (msg.kind === 'voice') preview = t('hotelTodayPreviewVoice')
    else if (msg.kind === 'image') preview = t('hotelTodayPreviewPhoto')
    else if (msg.kind === 'document') preview = msg.document?.name ?? t('hotelTodayPreviewDocument')
    else if (msg.text) {
      preview = msg.text[msg.origin]
      previewLang = msg.origin
    }
  }
  const own = msg ? msg.from === 'venue' : false
  const at = msg?.at ?? c.lastMessageAt
  const sameDay = at.slice(0, 10) === PROTOTYPE_TODAY
  const time = sameDay ? f.time(at) : dayMonth(at, false)

  const replied = useTodayLocal(s => s.repliedConversations.includes(c.id))
  const waited = c.awaitingReplySince && !replied ? minutesBetween(c.awaitingReplySince, PROTOTYPE_NOW) : 0
  const needsReply = waited > NEEDS_REPLY_AFTER_MIN
  const wait = needsReply ? (
    <TimeLeft minutes={waited} tone="gold" glyph="hourglass" say={s => t('hotelTodayWaitingLong', { time: s })} />
  ) : null

  let when: string | null = null
  if (booking) {
    const first = booking.sections[0]
    when = booking.eventDate === PROTOTYPE_TODAY && first ? f.time(clockInstant(f, booking.eventDate, first.start)) : dayMonth(booking.eventDate)
  }
  const full = variant === 'full'
  const facts =
    group && visit ? (
      <FactRow className="ht-inbox__facts" label={t('hotelTodayVisitMembers')}>
        <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={f.dateTime(visit.slotStart, 'short')} />
        <StatusIcon status={VISIT_STATUS[visit.status] ?? 'visit_requested'} audience="hotel" />
        <span className="ht-inbox__roles">
          <RoleGlyph icon="user" name={common('commonRoleClient')} />
          <RoleGlyph icon="hotel" name={common('commonRoleHotelRep')} />
          <RoleGlyph icon="headset" name={common('commonRoleSupport')} />
        </span>
      </FactRow>
    ) : full && !group && (booking || c.kind === 'enquiry' || wait) ? (
      <FactRow className="ht-inbox__facts">
        {booking && when ? (
          <>
            <TextFact icon={booking.eventDate === PROTOTYPE_TODAY ? 'clock' : 'calendar'} label={t('hotelTodayFactDate')} text={when} />
            <StatusIcon status={booking.status} audience="hotel" />
          </>
        ) : null}
        {!booking && c.kind === 'enquiry' ? (
          <span className="ht-inbox__tag">
            <Icon name="help" size="xs" />
            <span className="gz-sr-only">{t('hotelTodayEnquiry')}</span>
          </span>
        ) : null}
        {wait}
      </FactRow>
    ) : variant === 'compact' && wait ? (
      <FactRow className="ht-inbox__facts">{wait}</FactRow>
    ) : null

  return (
    <li className="ht-inbox" data-unread={count > 0 || undefined} data-pinned={c.pinned || undefined}>
      <button
        type="button"
        className="gz-reset ht-inbox__main gz-press"
        onClick={() => {
          if (hold.current?.fired) {
            hold.current = null
            return
          }
          onOpen?.()
        }}
        onPointerDown={startHold}
        onPointerUp={endHold}
        onPointerLeave={endHold}
        onPointerCancel={endHold}
        onContextMenu={e => {
          if (!onLongPress) return
          e.preventDefault()
          onLongPress()
        }}
        disabled={disabled}
      >
        {group ? (
          <span className="ht-inbox__avatar ht-inbox__group" aria-hidden="true">
            <Icon name="users-three" size="sm" />
          </span>
        ) : (
          <span lang={support ? lang : scriptOf(name)} className="ht-inbox__avatar">
            <Avatar name={name} initial={support ? 'غ' : undefined} size="sm" voice="sans" />
          </span>
        )}
        <span className="ht-inbox__text">
          <span className="ht-inbox__head">
            <span className="ht-inbox__name">
              {support ? <span className="gz-t-title gz-clamp-2">{name}</span> : <UserText role="title" className="gz-clamp-2">{name}</UserText>}
              {c.pinned ? <Icon name="bookmark-fill" size="xs" tone="secondary" label={t('hotelTodayPinned')} /> : null}
            </span>
            <span className="ht-inbox__time gz-t-caption">
              <Figures text={time} />
            </span>
          </span>
          <span className="ht-inbox__line">
            <span className={`ht-inbox__preview gz-t-body-s${count > 0 ? ' is-unread' : ''}`}>
              {own ? (
                <span className="ht-inbox__you">
                  <Icon name="reply" size="xs" tone="secondary" />
                  <span className="gz-sr-only">{t('hotelTodayYou')}</span>
                </span>
              ) : null}
              <span className="ht-inbox__preview-text" lang={previewLang} dir="auto">
                <Figures text={glimpse(preview)} />
              </span>
            </span>
            {count > 0 ? <CountBadge count={count} label={t('hotelTodayUnreadCount', { count })} /> : null}
          </span>
          {facts}
        </span>
      </button>
      {last ? null : <span className="ht-inbox__rule" aria-hidden="true" />}
    </li>
  )
}

/** A role of a visit chat as a glyph; its name is read. */
function RoleGlyph({ icon, name }: { icon: 'user' | 'hotel' | 'headset'; name: string }) {
  return (
    <span className="ht-inbox__role">
      <Icon name={icon} size="xs" />
      <span className="gz-sr-only">{name}</span>
    </span>
  )
}
