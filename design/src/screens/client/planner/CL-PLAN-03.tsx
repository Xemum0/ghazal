// CL-PLAN-03 Your planner (request status). Covers CA-PLAN-07, CA-PLAN-08, CA-CHAT-03.
// The three states of the request (sent, planner assigned, meeting scheduled) are one icon thread with one word under the active step.
// Waiting has nobody to show, so it opens with the system's state composition (a drawing and a four-word title, centred as ADR 0034 D7 allows
// a single-purpose composition; everything under it is full width); once a planner is assigned she is the screen: monogram, name, role,
// package, a chat glyph, and a wordless calendar drawing says what comes next (the pinned action is Schedule). A scheduled meeting is a card
// (time as the figure, date, a glyph for video or phone, add to calendar, Reschedule). The offline banner is the only offline text: a
// disabled control carries no second copy of it. No planner directory, no presence or typing: she replies through ordinary chat.
import { useEffect, useRef } from 'react'
import { plannerRequest } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import {
  ActionBar, Banner, Button, EmptyState, ErrorState, FactChip, Figures, IconButton, IconProgress, Screen, Skeleton, SkeletonText,
  ThreadBead, TopBar, useBi, useNav, type IconProgressStep,
} from '../../../system'
import { PlannerIdentity, RequestSummary } from './_components/parts'
import { STORY_CONVERSATION, plannerOf, requestView, usePlannerFlow } from './_components/plannerFlow'
import { useViewer } from './_components/useViewer'
import './CL-PLAN-03.css'

export const states = ['requested-waiting', 'assigned', 'meeting-scheduled', 'meeting-day', 'loading', 'error', 'offline']

export default function PlannerStatus() {
  const t = useT('client-planner')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const frame = useFrame()
  const nav = useNav()
  const { live } = useViewer(frame.state)
  const sent = usePlannerFlow(s => s.request)
  const state = frame.state
  const view = requestView(state, sent)
  const planner = plannerOf()
  const name = bi(planner.name)
  const offline = state === 'offline'
  const day = state === 'meeting-day'

  // The assignment arrives while the viewer is on this screen: say so once.
  const before = useRef(view.status)
  useEffect(() => {
    if (live && before.current === 'requested' && view.status === 'assigned') {
      nav.toast({ message: t('clientPlannerStatusAssignedToast', { name }), tone: 'success' })
    }
    before.current = view.status
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [view.status])

  const message = () => nav.push('CL-MSGS-02', { conversationId: STORY_CONVERSATION })
  const schedule = () => nav.openSheet('CL-PLAN-04', { params: { tier: view.tier } })
  const edit = () => nav.push('CL-PLAN-02', { tier: view.tier, edit: true })
  const cancel = async () => {
    const answer = await nav.openDialog({
      title: t('clientPlannerStatusCancelTitle'),
      body: t('clientPlannerStatusCancelBody'),
      confirmLabel: t('clientPlannerStatusCancelConfirm'),
      cancelLabel: t('clientPlannerStatusCancelKeep'),
      tone: 'destructive',
    })
    if (answer !== 'confirm') return
    usePlannerFlow.getState().cancel()
    nav.toast({ message: t('clientPlannerStatusCancelledToast') })
    nav.replace('CL-PLAN-01')
  }

  const top = <TopBar title={t('clientPlannerStatusTitle')} />

  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzp3-body" aria-busy="true">
          <Skeleton inlineSize={144} blockSize={144} />
          <SkeletonText lines={1} />
          <Skeleton blockSize={96} />
        </div>
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.toast({ message: t('clientPlannerRetryToast'), tone: 'danger' })} />
      </Screen>
    )
  }

  const { status } = view
  const assigned = status !== 'requested'
  const scheduled = status === 'meeting_scheduled'
  const meeting = view.meeting

  // Knots tie only on a recorded event; the one word under the active knot names the step in progress.
  const steps: IconProgressStep[] = [
    { key: 'requested', icon: 'send', label: t('clientPlannerStatusStepRequested'), state: 'tied' },
    { key: 'assigned', icon: 'user', label: t('clientPlannerStatusStepAssigned'), state: assigned ? 'tied' : 'now' },
    { key: 'meeting', icon: 'calendar-check', label: t('clientPlannerStatusStepMeeting'), state: scheduled ? 'tied' : assigned ? 'now' : 'open' },
  ]
  const reached = scheduled ? 3 : assigned ? 2 : 1

  const bar = scheduled ? (
    <ActionBar action={{ label: tc('commonActionMessage'), onPress: message, iconEnd: 'chat' }} />
  ) : assigned ? (
    <ActionBar action={{ label: t('clientPlannerStatusSchedule'), onPress: schedule, iconEnd: 'calendar-plus' }} />
  ) : undefined

  const typeName = meeting?.type === 'phone' ? t('clientPlannerTypePhoneName') : t('clientPlannerTypeVideoName')

  return (
    <Screen top={top} bottom={bar}>
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {!assigned ? <EmptyState illustration="hourglass" fill={false} title={t('clientPlannerStatusHeadWaiting')} /> : null}
      <div className="gzp3-body">
        {assigned ? (
          <section className="gzp-panel" aria-label={name} data-gz-id="plan.planner">
            <PlannerIdentity
              name={name}
              role={bi(planner.role)}
              tier={view.tier}
              action={
                !scheduled ? (
                  <IconButton icon="chat" variant="outline" label={t('clientPlannerStatusMessageName', { name })} onClick={message} />
                ) : undefined
              }
            />
          </section>
        ) : null}

        <IconProgress
          className="gzp3-thread"
          steps={steps}
          label={t('clientPlannerStatusThreadLabel')}
          describe={tc('commonCounter', { current: reached, total: steps.length })}
        />

        {scheduled && meeting ? (
          <section className="gzp-panel gzp3-meeting" data-gz-id="plan.meeting" aria-label={t('clientPlannerStatusMeetingLabel')}>
            <div className="gzp3-meeting__when">
              <span className="gzp3-meeting__time gz-t-ui-xl">
                <Figures text={f.time(meeting.at)} />
              </span>
              <span className="gzp3-meeting__date gz-t-body">
                {day ? (
                  <span className="gzp3-today">
                    <ThreadBead tone="gold" />
                    <span>{tc('commonLabelToday')}</span>
                  </span>
                ) : (
                  <Figures text={f.date(meeting.at, 'short')} />
                )}
              </span>
            </div>
            <div className="gzp3-meeting__foot">
              <FactChip
                icon={meeting.type === 'phone' ? 'phone' : 'video'}
                label={`${typeName}, ${tc('commonLabelKuwaitTime')}`}
              />
              <div className="gzp3-meeting__actions">
                <IconButton
                  icon="calendar-plus"
                  variant="outline"
                  label={t('clientPlannerStatusAddToCalendar')}
                  onClick={() => nav.toast({ message: t('clientPlannerStatusCalendarToast'), tone: 'success' })}
                />
                <Button variant="tertiary" onClick={schedule} disabled={offline}>
                  {tc('commonActionReschedule')}
                </Button>
              </div>
            </div>
          </section>
        ) : null}

        {!assigned ? (
          <>
            <RequestSummary tier={view.tier} venueId={plannerRequest.venueId ?? 'V01'} date={plannerRequest.eventDate} />
            <div className="gzp3-manage">
              <Button variant="secondary" fullWidth iconStart="edit" onClick={edit}>
                {tc('commonActionEdit')}
              </Button>
              <Button variant="destructive" fullWidth iconStart="close" onClick={cancel}>
                {tc('commonActionCancel')}
              </Button>
            </div>
          </>
        ) : null}
      </div>
      {assigned && !scheduled ? <EmptyState illustration="empty-bookings" /> : null}
    </Screen>
  )
}
