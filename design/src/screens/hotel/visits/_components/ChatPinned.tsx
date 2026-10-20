// ChatPinned (HL-VIST-03): the visit card pinned under the chat header. Status and slot on one line, the client's first name, and the
// representative's action for the state: Requested shows "Confirm" and "Propose another time", a confirmed visit on its day shows "Mark
// arrived"; every other state is information only. The card opens the visit (HL-VIST-02). Not a voucher, not a price: a visit is free.
import type { VisitAppointment } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Button, Icon, StatusPill, type VisitState } from '../../../../system'
import { Figures, useWords } from './bits'
import { useVisitsLocal } from './store'
import { canMarkArrived, firstName } from './model'
import './chat-pinned.css'

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

export type ChatPinnedProps = {
  visit: VisitAppointment
  /** The representative may act (assigned, Admin or Manager, online). */
  canAct: boolean
  offline?: boolean
  onOpen: () => void
  onConfirm: () => void
  onPropose: () => void
  onArrived: () => void
}

export function ChatPinned({ visit: v, canAct, offline = false, onOpen, onConfirm, onPropose, onArrived }: ChatPinnedProps) {
  const f = useFormat()
  const { t } = useWords()
  const name = firstName(v.clientName)
  const requested = v.status === 'requested'
  const arrive = v.status === 'confirmed' && canMarkArrived(v)
  const demo = canAct && v.status === 'confirmed' && !arrive
  return (
    <div className="hv-pin" data-gz="VisitPinned" data-status={v.status}>
      <button type="button" className="gz-reset gz-press hv-pin__body" onClick={onOpen} aria-label={t('hotelVisitsOpenVisit', { name, when: f.plain(f.dateTime(v.slotStart, 'short')) })}>
        <span className="hv-pin__line">
          <StatusPill status={PILL[v.status]} audience="hotel" />
          <span className="hv-pin__when gz-t-fig-body-s">
            <Icon name="calendar-check" size="xs" tone="secondary" />
            <Figures text={f.dateTime(v.slotStart, 'short')} />
          </span>
        </span>
      </button>
      {canAct && (requested || arrive) ? (
        <div className="hv-pin__actions">
          {requested ? (
            <>
              <Button variant="primary" size="sm" iconStart="check" disabled={offline} onClick={onConfirm}>
                {t('hotelVisitsConfirm')}
              </Button>
              <Button variant="secondary" size="sm" disabled={offline} onClick={onPropose}>
                {t('hotelVisitsProposeShort')}
              </Button>
            </>
          ) : (
            <Button variant="primary" size="sm" iconStart="pin" disabled={offline} onClick={onArrived}>
              {t('hotelVisitsMarkArrived')}
            </Button>
          )}
        </div>
      ) : null}
      {demo ? (
        <Button variant="tertiary" size="sm" onClick={() => useVisitsLocal.getState().jumpToDay(v.id)}>
          {t('hotelVisitsDemoJump')}
        </Button>
      ) : null}
    </div>
  )
}
