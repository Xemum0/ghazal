// NtfRow: one notification of the centre, as a glyph and a few words (ADR 0034; the system NotificationRow still carries the two-line body).
// A tone disk whose glyph says what kind of event it is, the title in at most two words (written here from the kind, so the Arabic is as short
// as the English), the venue as a quiet line, time left as a fact (`timer 23 h`, never a phrase), the clock, and while unread the gold bead.
// Marketing arrives by opt-in only (ADR 0015 D8) and keeps its quiet "Offer" tag so it is never mistaken for a request event.
// The planning rows carry one number in place of a venue: days to the wedding, a due date, a meeting date.
// A message from a person or Support keeps the fixture's own title: it is a name.
import type { IconName } from '@gz/tokens'
import type { Notification, NotificationKind } from '@gz/contracts'
import { getVenue } from '../../../../mock'
import { type MessageKey } from '../../../../i18n'
import { Badge, FactChip, Figures, Icon, ThreadBead, useBi } from '../../../../system'
import { cx } from '../../../../system/core/cx'
import { FactValue } from './FactValue'
import { useMsg } from './useMsg'
import './ntf-row.css'

type Kind = { icon: IconName; key?: MessageKey<'client-messages'> }

const KIND: Partial<Record<NotificationKind, Kind>> = {
  request_sent: { icon: 'send', key: 'clientMessagesNtfKindRequestSent' },
  request_approved: { icon: 'check-circle', key: 'clientMessagesNtfKindApproved' },
  confirm_reminder: { icon: 'hourglass', key: 'clientMessagesNtfKindConfirmReminder' },
  request_confirmed: { icon: 'calendar-check', key: 'clientMessagesNtfKindConfirmed' },
  request_declined: { icon: 'x-circle', key: 'clientMessagesNtfKindDeclined' },
  request_expired: { icon: 'clock-off', key: 'clientMessagesNtfKindExpired' },
  booking_cancelled: { icon: 'x-circle', key: 'clientMessagesNtfKindCancelled' },
  voucher_ready: { icon: 'ticket', key: 'clientMessagesNtfKindVoucherReady' },
  voucher_released: { icon: 'undo', key: 'clientMessagesNtfKindVoucherKept' },
  voucher_redeemed: { icon: 'check-double', key: 'clientMessagesNtfKindRedeemed' },
  voucher_refunded: { icon: 'receipt', key: 'clientMessagesNtfKindRefunded' },
  voucher_expiring: { icon: 'clock', key: 'clientMessagesNtfKindExpiring' },
  visit_requested: { icon: 'calendar-plus', key: 'clientMessagesNtfKindVisitRequested' },
  visit_confirmed: { icon: 'calendar-check', key: 'clientMessagesNtfKindVisitConfirmed' },
  visit_reminder: { icon: 'bell', key: 'clientMessagesNtfKindVisitSoon' },
  visit_message: { icon: 'users-three', key: 'clientMessagesNtfKindVisitChat' },
  new_venue: { icon: 'venue', key: 'clientMessagesNtfKindNewVenue' },
  review_prompt: { icon: 'star', key: 'clientMessagesNtfKindReview' },
  countdown: { icon: 'calendar', key: 'clientMessagesNtfKindCountdown' },
  checklist_due: { icon: 'checklist', key: 'clientMessagesNtfKindChecklist' },
  planner_assigned: { icon: 'user' },
  message: { icon: 'chat' },
}

/** Kinds that name a venue: the venue is the subject line. A person's message, the planner and the planning reminders have none. */
const ABOUT_VENUE = new Set<NotificationKind>([
  'request_sent', 'request_approved', 'confirm_reminder', 'request_confirmed', 'request_declined', 'request_expired', 'booking_cancelled',
  'voucher_ready', 'voucher_released', 'voucher_redeemed', 'voucher_expiring', 'visit_requested', 'visit_confirmed', 'visit_reminder', 'visit_message', 'new_venue',
])

export type NtfRowProps = {
  notification: Notification
  onOpen?: () => void
  last?: boolean
}

export function NtfRow({ notification: n, onOpen, last = false }: NtfRowProps) {
  const { t, f, hoursLeft, duration } = useMsg()
  const bi = useBi()
  const unread = !n.read
  const meta = KIND[n.kind] ?? { icon: 'bell' as const }
  const title = meta.key ? t(meta.key) : bi(n.title)
  const venue = ABOUT_VENUE.has(n.kind) && n.venueId ? getVenue(n.venueId) : undefined
  const confirmBy = typeof n.params.confirmBy === 'string' ? n.params.confirmBy : null
  const timeLeft = (n.kind === 'request_approved' || n.kind === 'confirm_reminder') && confirmBy ? hoursLeft(confirmBy) : null
  // The planning rows carry one fact in place of a venue: the days to the wedding as they stood when it was sent, the due date, the meeting date.
  const str = (k: string): string | null => (typeof n.params[k] === 'string' ? (n.params[k] as string) : null)
  const weddingDate = n.kind === 'countdown' ? str('weddingDate') : null
  const dueOn = n.kind === 'checklist_due' ? str('dueOn') : null
  const meetingAt = n.kind === 'planner_assigned' ? str('meetingAt') : null
  const plan: { icon: IconName; value: string; label: string; tone?: 'accent' } | null = weddingDate
    ? { icon: 'timer', value: duration(Math.max(0, Math.round((Date.parse(weddingDate) - Date.parse(f.isoDay(n.at))) / 86_400_000)) * 86_400_000), label: t('clientMessagesFactDaysLeft'), tone: 'accent' }
    : dueOn
      ? { icon: 'calendar', value: f.date(dueOn, 'dayMonth'), label: t('clientMessagesFactDue') }
      : meetingAt
        ? { icon: 'calendar', value: f.date(meetingAt, 'dayMonth'), label: t('clientMessagesFactMeeting') }
        : null
  return (
    <>
      <button
        type="button"
        data-gz="NotificationRow"
        data-kind={n.kind}
        data-tone={n.tone}
        data-unread={unread || undefined}
        className={cx('gz-reset gzm-ntf gz-press', unread && 'is-unread')}
        onClick={onOpen}
      >
        <span className={cx('gzm-ntf__disk', `is-${n.tone}`)}>
          <Icon name={meta.icon} size="sm" />
        </span>
        <span className="gzm-ntf__text">
          <span className="gzm-ntf__head">
            <span className="gzm-ntf__title gz-t-title">
              <bdi dir="auto">{title}</bdi>
            </span>
            {n.channel === 'marketing' ? <Badge variant="quiet">{t('clientMessagesNtfOffer')}</Badge> : null}
          </span>
          {venue || timeLeft !== null || plan ? (
            <span className="gzm-ntf__sub gz-t-body-s">
              {venue ? <bdi dir="auto" className="gzm-ntf__venue">{bi(venue.name)}</bdi> : null}
              {timeLeft !== null ? <FactChip icon="timer" value={<FactValue text={duration(timeLeft * 3_600_000)} />} label={t('clientMessagesFactTimeLeft')} tone="accent" size="sm" /> : null}
            {plan ? <FactChip icon={plan.icon} value={<FactValue text={plan.value} />} label={plan.label} tone={plan.tone ?? 'muted'} size="sm" /> : null}
            </span>
          ) : null}
        </span>
        <span className="gzm-ntf__side">
          <span className="gzm-ntf__time gz-t-caption">
            <Figures text={f.time(n.at)} />
          </span>
          {unread ? (
            <span className="gzm-ntf__dot">
              <ThreadBead tone="gold" />
              <span className="gz-sr-only">{t('clientMessagesNtfUnread')}</span>
            </span>
          ) : null}
        </span>
      </button>
      {last ? null : <span className="gzm-ntf__rule" aria-hidden="true" />}
    </>
  )
}
