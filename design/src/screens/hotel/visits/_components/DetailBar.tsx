// DetailBar: the pinned bar of the visit detail (HA-VIS-02 to HA-VIS-04), by status and role. Requested: the ONE gold "Confirm" at thumb
// height, then "Propose another time" and "Decline" at equal weight. Confirmed: "Open chat", and on the day "Mark arrived" takes the gold.
// Arrived: "Complete visit". Past visits have no bar. Offline disables every decision in place with its reason. A bar is canvas with a
// 1 px hairline top rule, never ink (direction 2.5); with no tab bar below it adds the home inset.
import type { ReactNode } from 'react'
import type { VisitAppointment } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useBottomChrome } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { Button, useNav } from '../../../../system'
import { useWords } from './bits'
import { useVisitActions } from './actions'
import { useVisitsLocal } from './store'
import { canFlagMissed, canMarkArrived, isLead, type VisitRole } from './model'
import './detail-bar.css'

export function DetailBar({ visit: v, role, canReply, offline }: { visit: VisitAppointment; role: VisitRole; canReply: boolean; offline: boolean }): ReactNode {
  const { t, c } = useWords()
  const f = useFormat()
  const nav = useNav()
  const act = useVisitActions()
  const { tabBar } = useBottomChrome()
  if (!canReply) return null
  const reason = offline ? t('hotelVisitsOfflineReason') : undefined
  let content: ReactNode = null

  if (v.status === 'requested') {
    content = (
      <>
        <Button variant="primary" size="cta" fullWidth iconStart="check" disabled={offline} reason={reason} onClick={() => act.confirm(v)}>
          {t('hotelVisitsConfirm')}
        </Button>
        <div className="hv-bar__pair">
          <Button variant="secondary" size="md" disabled={offline} onClick={() => act.propose(v)}>
            {t('hotelVisitsProposeShort')}
          </Button>
          <Button variant="secondary" size="md" disabled={offline} onClick={() => act.decline(v, () => nav.pop())}>
            {c('commonActionDecline')}
          </Button>
        </div>
      </>
    )
  } else if (v.status === 'confirmed' && canMarkArrived(v)) {
    content = (
      <>
        <Button variant="primary" size="cta" fullWidth iconStart="pin" disabled={offline} reason={reason} onClick={() => act.arrival(v)}>
          {t('hotelVisitsMarkArrived')}
        </Button>
        <Button variant="secondary" size="md" fullWidth iconStart="chat" onClick={() => act.chat(v)}>
          {t('hotelVisitsOpenChat')}
        </Button>
      </>
    )
  } else if (v.status === 'confirmed' || v.status === 'reschedule_proposed') {
    content = (
      <>
        <Button variant="primary" size="cta" fullWidth iconStart="chat" onClick={() => act.chat(v)}>
          {t('hotelVisitsOpenChat')}
        </Button>
        {v.status === 'confirmed' ? (
          <Button variant="tertiary" size="sm" fullWidth onClick={() => useVisitsLocal.getState().jumpToDay(v.id)}>
            {t('hotelVisitsDemoJump')}
          </Button>
        ) : null}
      </>
    )
  } else if (v.status === 'arrived') {
    content = (
      <>
        <Button
          variant="primary"
          size="cta"
          fullWidth
          iconStart="check-double"
          disabled={offline}
          reason={reason}
          onClick={() => {
            usePrototype.getState().setVisitStatus(v.id, 'completed')
            nav.toast({ message: t('hotelVisitsToastCompleted'), tone: 'success', icon: 'check-circle' })
          }}
        >
          {t('hotelVisitsComplete')}
        </Button>
        <Button variant="secondary" size="md" fullWidth iconStart="chat" onClick={() => act.chat(v)}>
          {t('hotelVisitsOpenChat')}
        </Button>
      </>
    )
  } else if (v.status === 'missed' && isLead(role) && canFlagMissed(v)) {
    content = (
      <Button variant="secondary" size="md" fullWidth iconStart="pin" disabled={offline} onClick={() => act.arrival(v)}>
        {t('hotelVisitsCorrectMissed')}
      </Button>
    )
  }

  if (!content) return null
  return (
    <div className="hv-bar" data-gz="VisitDecisionBar">
      {content}
      {tabBar ? null : <div className="hv-bar__inset" />}
    </div>
  )
}
