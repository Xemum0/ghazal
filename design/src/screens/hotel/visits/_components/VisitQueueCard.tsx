// VisitQueueCard (HL-VIST-01): one visit of the queue. Client first name on a monogram, the date and the 30-minute arrival window in the
// figures voice, how many come, the note as a quiet quote, and, for a request that waits for a reply, "Confirm" (gold, one per card as on
// the booking triage cards) and "Propose another time" inline. The body is one 44+ target that opens the detail; the actions are separate.
import type { VisitAppointment } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Avatar, Button, Icon, StatusPill, type VisitState } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { Figures, UserText, useWords } from './bits'
import { firstName, type Segment } from './model'
import './visit-queue-card.css'

const PILL: Record<VisitAppointment['status'], VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}

export type VisitQueueCardProps = {
  visit: VisitAppointment
  segment: Segment
  /** `offline` and `readonly` disable the inline decisions in place, with the reason on the screen above. */
  lock?: 'offline' | 'readonly'
  onOpen: () => void
  onConfirm: () => void
  onPropose: () => void
}

export function VisitQueueCard({ visit: v, segment, lock, onOpen, onConfirm, onPropose }: VisitQueueCardProps) {
  const f = useFormat()
  const { lang } = useLang()
  const { t } = useWords()
  const name = firstName(v.clientName)
  const decide = segment === 'requested' && v.status === 'requested'
  return (
    <article data-gz="VisitQueueCard" data-status={v.status} className="hv-qcard">
      <button type="button" className="gz-reset gz-press hv-qcard__body" onClick={onOpen} aria-label={t('hotelVisitsOpenVisit', { name, when: f.plain(f.dateTime(v.slotStart, 'short')) })}>
        <span className="hv-qcard__who">
          <Avatar name={name} initial={lang === 'ar' ? name.slice(0, 1) : undefined} size="sm" voice="sans" />
          <span className="hv-qcard__name">
            <UserText role="title">{name}</UserText>
            <span className="gz-t-caption hv-qcard__sub">{decide ? t('hotelVisitsRequestedAgo', { ago: f.ago(v.requestedAt) }) : t('hotelVisitsVisitors', { count: v.visitors })}</span>
          </span>
          {decide ? null : <StatusPill status={PILL[v.status]} audience="hotel" />}
        </span>
        <span className="hv-qcard__when gz-t-ui-title">
          <Figures text={f.date(v.slotStart, 'short')} />
        </span>
        <span className="hv-qcard__facts gz-t-fig-body-s">
          <span className="hv-qcard__fact">
            <Icon name="clock" size="xs" tone="secondary" />
            <bdi dir="ltr">{f.timeRange(v.slotStart, v.slotEnd)}</bdi>
          </span>
          {decide ? (
            <span className="hv-qcard__fact">
              <Icon name="guests" size="xs" tone="secondary" />
              <span className="gz-t-body-s">{t('hotelVisitsVisitors', { count: v.visitors })}</span>
            </span>
          ) : null}
        </span>
        {v.note ? (
          <span className="hv-qcard__note gz-t-body-s gz-clamp-2">
            <UserText role="body-s">{v.note}</UserText>
          </span>
        ) : null}
      </button>
      {decide ? (
        <div className="hv-qcard__actions">
          <Button variant="primary" size="md" iconStart="check" disabled={Boolean(lock)} onClick={onConfirm}>
            {t('hotelVisitsConfirm')}
          </Button>
          <Button variant="secondary" size="md" disabled={Boolean(lock)} onClick={onPropose}>
            {t('hotelVisitsPropose')}
          </Button>
        </div>
      ) : null}
    </article>
  )
}
