// NotificationRow (CA-NTF, ADR 0003 D9): one notification as a row. A glyph in a disk whose tone is a reinforcement (never the only
// signal: the title says what happened), the title, up to two lines of the ready-made body, the time and, while unread, a gold bead.
// Marketing arrives only by opt-in (ADR 0015 D8); the row marks it with a quiet "Offer" tag so it is never mistaken for a request event.
import type { IconName } from '@gz/tokens'
import type { Notification, NotificationKind } from '@gz/contracts'
import { useFormat } from '../../i18n'
import { Badge, Icon, ThreadBead } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './notification-row.css'

const useW = defineWords({
  unread: p('Unread', 'غير مقروء'),
  marketing: p('Offer', 'عرض'),
})

const KIND_ICON: Record<NotificationKind, IconName> = {
  request_sent: 'send',
  request_approved: 'check-circle',
  confirm_reminder: 'hourglass',
  request_confirmed: 'calendar-check',
  request_declined: 'x-circle',
  request_expired: 'clock-off',
  booking_cancelled: 'x-circle',
  voucher_ready: 'ticket',
  voucher_released: 'undo',
  voucher_redeemed: 'check-double',
  credit_voucher_issued: 'gift',
  voucher_forfeited: 'x-circle',
  voucher_expiring: 'clock',
  visit_requested: 'calendar-plus',
  visit_confirmed: 'calendar-check',
  visit_reminder: 'bell',
  visit_message: 'users-three',
  new_request: 'bell',
  client_confirmed: 'check-circle',
  client_lapsed: 'clock-off',
  voucher_redeemed_by_you: 'qr-code',
  visit_request: 'calendar-plus',
  listing_submitted: 'megaphone',
  listing_approved: 'check-circle',
  listing_rejected: 'x-circle',
  listing_expiring: 'clock',
  review_received: 'star',
  calendar_confirm: 'calendar-check',
  invite: 'user-plus',
  countdown: 'calendar',
  new_venue: 'venue',
  planner_assigned: 'user',
  message: 'chat',
  review_prompt: 'star',
  checklist_due: 'checklist',
}

export type NotificationRowProps = {
  notification: Notification
  onOpen?: () => void
  last?: boolean
  className?: string
}

export function NotificationRow({ notification: n, onOpen, last = false, className }: NotificationRowProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const unread = !n.read
  return (
    <button
      type="button"
      data-gz="NotificationRow"
      data-kind={n.kind}
      data-tone={n.tone}
      data-unread={unread || undefined}
      className={cx('gz-reset gz-ntf gz-press', unread && 'is-unread', last && 'is-last', className)}
      onClick={onOpen}
    >
      <span className={cx('gz-ntf__disk', `is-${n.tone}`)}>
        <Icon name={KIND_ICON[n.kind] ?? 'bell'} size="sm" />
      </span>
      <span className="gz-ntf__text">
        <span className="gz-ntf__head">
          <span className="gz-ntf__title gz-t-title">{bi(n.title)}</span>
          {n.tag ? <Badge variant="quiet">{bi(n.tag)}</Badge> : n.channel === 'marketing' ? <Badge variant="quiet">{w('marketing')}</Badge> : null}
        </span>
        <span className="gz-ntf__body gz-t-body-s gz-clamp-2">
          <Figures text={bi(n.body)} />
        </span>
        <span className="gz-ntf__time gz-t-caption">
          <Figures text={f.ago(n.at)} />
        </span>
      </span>
      {unread ? (
        <span className="gz-ntf__dot">
          <ThreadBead tone="gold" />
          <span className="gz-sr-only">{w('unread')}</span>
        </span>
      ) : null}
    </button>
  )
}
