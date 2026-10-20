// HL-VIST-04 Mark arrival (sheet). Requirement IDs: HA-VIS-04, CA-VIS-05.
// On the day, the representative's half of the arrival confirmation that the client starts in the chat ("on our way"): "Mark arrived"
// sets Arrived and posts "Welcome, {name}" in the group chat; "Client did not arrive" is available from 30 minutes after the slot, flags
// Missed and informs Ghazal support. Admin or Manager can correct a missed flag within a day. A missed visit carries no penalty for the
// client in the MVP, and a visit has no money. Decisions are never queued: offline disables both in place.
// States: default, client-on-the-way, arrived-confirmed, flag-missed, success, offline, error
import { useState } from 'react'
import { engine } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Avatar, Banner, Button, Icon, useNav } from '../../../system'
import { Figures, Notice, SheetShell, UserText, useWords } from './_components/bits'
import { HERO_CONFIRMED, canFlagMissed, deriveVisit, firstName, useVisitById, variantOfState } from './_components/model'
import { stamp } from './_components/chat'
import './HL-VIST-04.css'

export const states = ['default', 'client-on-the-way', 'arrived-confirmed', 'flag-missed', 'success', 'offline', 'error']

type Phase = 'idle' | 'saving' | 'arrived' | 'missed'

export default function MarkArrival() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { lang } = useLang()
  const { t, c } = useWords()
  const params = nav.params as { visitId?: string }
  const stored = useVisitById(params.visitId ?? HERO_CONFIRMED)
  const framed = state !== undefined
  const visit = framed ? deriveVisit(variantOfState(state, 'day-of')) : (stored ?? deriveVisit('day-of'))
  const name = firstName(visit.clientName)
  const offline = state === 'offline'
  const [phase, setPhase] = useState<Phase>(state === 'arrived-confirmed' ? 'arrived' : state === 'success' ? 'missed' : 'idle')
  const [failed, setFailed] = useState(state === 'error')
  const onTheWay = state === 'client-on-the-way'
  const missedOpen = canFlagMissed(visit) || state === 'flag-missed'
  const missedFrom = engine.addMinutes(visit.slotStart, 30)

  const close = () => nav.closeSheet()
  const toChat = () => {
    close()
    nav.push('HL-VIST-03', { visitId: visit.id })
  }

  const markArrived = () => {
    if (offline) return
    setPhase('saving')
    window.setTimeout(() => {
      usePrototype.getState().setVisitStatus(visit.id, 'arrived')
      setPhase('arrived')
    }, 480)
  }
  const flagMissed = async () => {
    if (offline || !missedOpen) return
    const r = await nav.openDialog({
      title: t('hotelVisitsMissedDialogTitle'),
      body: t('hotelVisitsMissedDialogBody', { name }),
      icon: 'warning-circle',
      confirmLabel: t('hotelVisitsMissedCta'),
      cancelLabel: c('commonActionBack'),
      tone: 'destructive',
    })
    if (r === 'confirm') {
      usePrototype.getState().setVisitStatus(visit.id, 'missed')
      setPhase('missed')
    }
  }

  const header = (
    <div className="hv-arr__who">
      <Avatar name={name} initial={lang === 'ar' ? name.slice(0, 1) : undefined} size="md" voice="sans" />
      <span className="hv-arr__text">
        <UserText role="ui-title">{name}</UserText>
        <span className="gz-t-fig-body-s hv-arr__when">
          <Figures text={f.dateTime(visit.slotStart, 'short')} />
        </span>
      </span>
    </div>
  )

  // ---- the result: the visit is Arrived (or Missed); the chat has been told
  if (phase === 'arrived' || phase === 'missed') {
    const arrived = phase === 'arrived'
    return (
      <SheetShell
        title={t('hotelVisitsArrivalTitle')}
        footer={
          <>
            <Button size="cta" fullWidth iconStart="chat" onClick={toChat}>
              {t('hotelVisitsOpenChat')}
            </Button>
            <Button variant="tertiary" fullWidth onClick={close}>
              {c('commonActionDone')}
            </Button>
          </>
        }
      >
        <div className="hv-arr__done" role="status" aria-live="polite">
          <span className="hv-arr__badge" data-tone={arrived ? 'ok' : 'quiet'}>
            <Icon name={arrived ? 'check' : 'clock-off'} size="md" />
          </span>
          <p className="gz-t-ui-title hv-arr__done-title">{arrived ? t('hotelVisitsArrivedDoneTitle', { name }) : t('hotelVisitsMissedDoneTitle', { name })}</p>
        </div>
      </SheetShell>
    )
  }

  const busy = phase === 'saving'
  return (
    <SheetShell
      title={t('hotelVisitsArrivalTitle')}
      footer={
        <>
          <Button size="cta" fullWidth iconStart="pin" loading={busy} disabled={offline} reason={offline ? t('hotelVisitsOfflineReason') : undefined} onClick={markArrived}>
            {t('hotelVisitsMarkArrived')}
          </Button>
          <Button
            variant="secondary"
            size="md"
            fullWidth
            iconStart="user-minus"
            disabled={offline || !missedOpen || busy}
            reason={!offline && !missedOpen ? t('hotelVisitsMissedFrom', { time: f.time(missedFrom) }) : undefined}
            onClick={flagMissed}
          >
            {t('hotelVisitsDidNotArrive')}
          </Button>
        </>
      }
    >
      {header}
      {failed ? (
        <Banner tone="danger" shape="card" action={{ label: c('commonActionRetry'), onPress: () => setFailed(false) }}>
          {t('hotelVisitsArrivalError')}
        </Banner>
      ) : null}
      {offline ? <Banner tone="offline" shape="card">{t('hotelVisitsOfflineBannerShort')}</Banner> : null}
      {onTheWay ? (
        <Notice icon="navigate" tone="rose" role="status" title={t('hotelVisitsOnTheWayTitle', { name })}>
          {t('hotelVisitsOnTheWayBody', { time: f.time(stamp(-12)) })}
        </Notice>
      ) : null}
      {state === 'flag-missed' ? (
        <Notice icon="clock-off" title={t('hotelVisitsSlotEndedTitle')}>
          {t('hotelVisitsSlotEndedBody', { name })}
        </Notice>
      ) : null}
    </SheetShell>
  )
}
