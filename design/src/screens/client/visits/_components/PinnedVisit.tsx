// PinnedVisit (CL-VIST-03): the visit card pinned under the chat header, with no sentence on it (ADR 0034). The status pill (icon + one
// word) and a "more" glyph that opens change or cancel (CL-VIST-05); the day, the arrival window and the visitors as icon + value; then the
// action of the moment: "Confirm" when the hotel proposed another time (the proposed time is a second row of facts in the gold-700 tone),
// "En route" and "Arrived" on the day (the representative then marks the arrival), "Another time" once the visit is over without a result.
// Exactly one gold action at a time. Offline, the arrival buttons are disabled with a two-word reason (a tap is never queued).
import type { ReactNode } from 'react'
import type { VisitStatus } from '@gz/contracts'
import { Button, FactChip, Icon, IconButton, StatusPill, type VisitState } from '../../../../system'
import { VisitFacts } from './VisitFacts'
import { useV, type VisitView } from './model'
import './pinned-visit.css'

const PILL: Record<VisitStatus, VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}

const SLOT_MS = 30 * 60_000

export type PinnedVisitProps = {
  view: VisitView
  /** The member discs (a button that opens the member sheet), placed beside "more". */
  members?: ReactNode
  offline?: boolean
  /** The client already tapped "En route". */
  onTheWay?: boolean
  onChange: () => void
  onAnother: () => void
  onConfirmProposed: () => void
  onOnTheWay: () => void
  onArrived: () => void
}

export function PinnedVisit({ view, members, offline = false, onTheWay = false, onChange, onAnother, onConfirmProposed, onOnTheWay, onArrived }: PinnedVisitProps) {
  const { t } = useV()
  const { visit, phase } = view
  const proposed = phase === 'reschedule' ? visit.proposedSlotStart : null
  const changeable = phase === 'requested' || phase === 'confirmed' || phase === 'reschedule' || phase === 'day-of'

  return (
    <section className="gzvt-pin" data-gz="PinnedVisit" data-phase={phase} aria-label={t('clientVisitsPinLabel')}>
      <div className="gzvt-pin__top">
        <span className="gzvt-pin__status">
          <StatusPill status={PILL[visit.status]} />
          {phase === 'day-of' && onTheWay ? <FactChip icon="navigate" tone="accent" label={t('clientVisitsStepWay')} /> : null}
        </span>
        <span className="gzvt-pin__end">
          {members}
          {changeable ? <IconButton icon="more" iconSize="sm" label={t('clientVisitsChangeOrCancel')} onClick={onChange} /> : null}
        </span>
      </div>

      <VisitFacts slotStart={visit.slotStart} slotEnd={visit.slotEnd} visitors={visit.visitors} compact tone={proposed ? 'muted' : 'default'} />

      {proposed ? (
        <div className="gzvt-pin__proposed">
          <Icon name="forward" size="sm" tone="accent" />
          <VisitFacts slotStart={proposed} slotEnd={new Date(Date.parse(proposed) + SLOT_MS).toISOString()} compact tone="accent" dayIcon="calendar-dots" />
        </div>
      ) : null}

      {phase === 'reschedule' ? (
        <div className="gzvt-pin__actions">
          <Button variant="primary" fullWidth onClick={onConfirmProposed}>
            {t('clientVisitsConfirmTime')}
          </Button>
        </div>
      ) : null}

      {phase === 'day-of' ? (
        <div className="gzvt-pin__actions">
          <div className="gzvt-pin__pair">
            {onTheWay ? null : (
              <Button variant="secondary" iconStart="navigate" disabled={offline} onClick={onOnTheWay}>
                {t('clientVisitsOnTheWay')}
              </Button>
            )}
            <Button variant="primary" iconStart="pin" disabled={offline} onClick={onArrived}>
              {t('clientVisitsArrived')}
            </Button>
          </div>
          {offline ? (
            <p className="gzvt-pin__why gz-t-caption">
              <Icon name="offline" size="xs" tone="secondary" />
              <span>{t('clientVisitsNeedsConnection')}</span>
            </p>
          ) : null}
        </div>
      ) : null}

      {phase === 'declined' || phase === 'missed' || phase === 'cancelled' ? (
        <div className="gzvt-pin__actions">
          <Button variant="secondary" iconStart="calendar-plus" onClick={onAnother}>
            {t('clientVisitsChooseAnother')}
          </Button>
        </div>
      ) : null}
    </section>
  )
}
