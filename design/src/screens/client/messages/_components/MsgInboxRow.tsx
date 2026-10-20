// InboxRow: one conversation of the Messages tab, as glyphs and a few words (ADR 0034). A monogram in the name's own script (never a face),
// the name and the clock (today) or the date, one short line of the last message in its own language and direction, and the gold unread
// count. What used to be a context sentence is a glyph: the request's status icon after the name (it carries the word as its accessible
// name), the pin of Support, the tick of the couple's own message, the microphone, the camera and the page of a voice note, a photo and a
// document. A visit group chat swaps the monogram for a group glyph, names the venue and shows the visit date as a fact plus the three
// roles as three glyphs. Unread = the preview in ink-900 500; the gold count is the only gold (a count badge, never a fill).
import type { ThreadRole } from '@gz/contracts'
import type { IconName } from '@gz/tokens'
import { Avatar, CountBadge, FactChip, Fig, Figures, Icon, StatusIcon } from '../../../../system'
import { cx } from '../../../../system/core/cx'
import { FactValue } from './FactValue'
import { useLiveBooking, VISIT_CLOSED, VISIT_PILL, type RowModel } from './model'
import { useMsg } from './useMsg'
import './inbox-row.css'

export type InboxRowProps = {
  row: RowModel
  onOpen?: () => void
  last?: boolean
  disabled?: boolean
}

/** The preview is one line: it is cut at a word boundary so the list shows a glimpse, never a paragraph. */
const PREVIEW_WORDS = 5
const clip = (text: string, words = PREVIEW_WORDS): string => {
  const parts = text.trim().split(/\s+/)
  return parts.length > words ? `${parts.slice(0, words).join(' ')}…` : text.trim()
}

const ROLE_ICON: Record<ThreadRole, IconName> = { client: 'user', hotel_representative: 'hotel', support: 'headset' }

export function MsgInboxRow({ row, onOpen, last = false, disabled }: InboxRowProps) {
  const { t, tc, lang, nameOf, dayMonthShort, rowTime, clock } = useMsg()
  const c = row.conversation
  const name = nameOf(c)
  const unread = row.unread
  const group = c.kind === 'visit_group'
  const booking = useLiveBooking(group ? null : c.bookingId)?.booking
  const p = row.preview
  const previewLang = p.kind === 'voice' || p.kind === 'image' ? lang : p.lang
  const roleName = (r: ThreadRole, you: boolean): string => (you ? tc('commonRoleYou') : r === 'client' ? tc('commonRoleClient') : r === 'hotel_representative' ? tc('commonRoleHotelRep') : tc('commonRoleSupport'))

  let preview
  if (p.kind === 'voice') {
    preview = (
      <span className="gzm-inbox__media">
        <Icon name="mic" size="xs" tone="secondary" label={t('clientMessagesPreviewVoice')} />
        <Fig>{clock(p.seconds ?? 0)}</Fig>
      </span>
    )
  } else if (p.kind === 'system') {
    preview = <Icon name={row.visit && VISIT_CLOSED.has(row.visit.status) ? 'lock' : 'users-three'} size="xs" tone="secondary" label={p.text} />
  } else if (p.kind === 'image') {
    preview = <Icon name="image" size="xs" tone="secondary" label={t('clientMessagesPreviewPhoto')} />
  } else if (p.kind === 'document') {
    preview = (
      <span className="gzm-inbox__media">
        <Icon name="document" size="xs" tone="secondary" label={t('clientMessagesPreviewDocument')} />
        <bdi dir="ltr" className="gzm-inbox__file">
          {p.text}
        </bdi>
      </span>
    )
  } else {
    preview = (
      <span className="gzm-inbox__preview-text" lang={previewLang} dir="auto">
        <Figures text={clip(p.text)} />
      </span>
    )
  }

  return (
    <li className={cx('gzm-inbox', last && 'is-last')} data-gz="ConversationRow" data-unread={unread > 0 || undefined} data-pinned={c.pinned || undefined}>
      <button type="button" className="gz-reset gzm-inbox__main gz-press" onClick={onOpen} disabled={disabled}>
        {group ? (
          <span className="gzm-inbox__glyph" aria-hidden="true">
            <Icon name="users-three" size="md" />
          </span>
        ) : (
          <Avatar name={name} initial={lang === 'ar' ? c.monogram : undefined} size="md" />
        )}
        <span className="gzm-inbox__text">
          <span className="gzm-inbox__head">
            <span className="gzm-inbox__name gz-t-title">
              <bdi dir="auto" className="gz-clamp-2">
                {name}
              </bdi>
              {c.pinned ? <Icon name="bookmark-fill" size="xs" tone="secondary" label={t('clientMessagesPinned')} /> : null}
              {booking ? <StatusIcon status={booking.status} size="sm" /> : null}
              {group && row.visit ? <StatusIcon status={VISIT_PILL[row.visit.status]} size="sm" /> : null}
            </span>
            <span className={cx('gzm-inbox__time gz-t-caption', unread > 0 && 'is-unread')}>
              <Figures text={rowTime(row.at)} />
            </span>
          </span>
          <span className="gzm-inbox__line">
            <span className={cx('gzm-inbox__preview gz-t-body-s', unread > 0 && 'is-unread')}>
              {row.mine ? <Icon name={row.status === 'sent' ? 'check' : 'check-double'} size="xs" tone={row.status === 'read' ? 'accent' : 'secondary'} label={t('clientMessagesYou')} /> : null}
              {preview}
            </span>
            {unread > 0 ? <CountBadge count={unread} max={9} label={t('clientMessagesUnreadCount', { count: unread })} /> : null}
          </span>
          {group && row.visit ? (
            <span className="gzm-inbox__facts">
              <FactChip icon="calendar-check" value={<FactValue text={dayMonthShort(row.visit.slotStart)} />} label={t('clientMessagesInfoVisit')} size="sm" />
              {c.members ? (
                <span className="gzm-inbox__roles" role="group" aria-label={t('clientMessagesVisitMembers')}>
                  {c.members.map(m => (
                    <Icon key={m.userId} name={ROLE_ICON[m.role]} size="xs" tone="secondary" label={roleName(m.role, m.role === 'client')} />
                  ))}
                </span>
              ) : null}
            </span>
          ) : null}
        </span>
      </button>
      {last ? null : <span className="gzm-inbox__rule" aria-hidden="true" />}
    </li>
  )
}
