// CL-PLAN-04 Schedule a meeting (sheet). Covers CA-PLAN-06.
// A Sunday-first two-week calendar (only days with free times can be chosen, a gold-700 bead marks them), the 30-minute slots of the
// chosen day (taken slots are hidden, not greyed), Video or Call as two glyphs, and one gold Confirm. Kuwait time sits on the month line.
// Confirming ties the third knot of the request thread and drops the meeting card into the planner chat. A slot taken in the meantime
// says so inline and refreshes the list. The confirmation is one drawing, "Meeting set", the date, the time and the call type as three
// facts (icon + value, ruled like the wedding line), Done and Calendar. Flow-local until the system states take a `facts` slot (requests.md).
import { useEffect, useRef, useState } from 'react'
import { plannerRequest } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import {
  Avatar, Button, ChipGroup, EmptyState, FactChip, FactRow, Figures, Icon, IconSegmented, Illustration, Skeleton, useBi, useNav,
} from '../../../system'
import { SheetHead, SheetNote } from './_components/parts'
import { DayGrid } from './_components/DayGrid'
import { Fx } from './_components/Fx'
import {
  STORY_CONVERSATION, isoToDate, plannerOf, requestView, upcomingDays, usePlannerFlow, type MeetingType,
} from './_components/plannerFlow'
import { useViewer } from './_components/useViewer'
import './CL-PLAN-04.css'

export const states = ['loading-slots', 'no-slots', 'confirming', 'success', 'slot-taken', 'offline-disabled']

type Phase = 'idle' | 'confirming' | 'success'

export default function ScheduleMeeting() {
  const t = useT('client-planner')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const frame = useFrame()
  const nav = useNav()
  const { live } = useViewer(frame.state)
  const state = frame.state
  const sent = usePlannerFlow(s => s.request)
  const planner = plannerOf()
  const name = bi(planner.name)

  // The planner's free slots (fixture): one list per day; a day without a list has no free times.
  const days = upcomingDays(f)
  const offered = plannerRequest.slots
  const taken = state === 'slot-taken'
  const hhmm = (iso: string) => `${String(f.civil(iso).hour).padStart(2, '0')}:${String(f.civil(iso).minute).padStart(2, '0')}`
  const slotsOf = (iso: string): string[] => {
    const all = offered.find(s => s.date === iso)?.times ?? []
    return taken ? all.filter(time => time !== storyTime) : all
  }
  const storyAt = plannerRequest.meeting?.at
  const storyTime = storyAt ? hhmm(storyAt) : ''
  const existing = requestView(undefined, sent).meeting
  const existingTime = existing ? hhmm(existing.at) : null

  const available = days.filter(iso => slotsOf(iso).length > 0)
  const noSlots = state === 'no-slots'
  const firstDay = (noSlots ? undefined : available[0]) ?? days[0] ?? ''
  const [day, setDay] = useState<string>(firstDay)
  const [type, setType] = useState<MeetingType>(existing?.type ?? 'video')
  // A frame shows the story's chosen slot; in the player a new request starts with nothing chosen, a change starts on the current slot.
  const initialTime = state === 'slot-taken' ? null : existingTime ?? (live ? null : storyTime)
  const [time, setTime] = useState<string | null>(initialTime)
  const [phase, setPhase] = useState<Phase>('idle')
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const shown: Phase = state === 'confirming' ? 'confirming' : state === 'success' ? 'success' : phase
  const loadingSlots = state === 'loading-slots'
  const offline = state === 'offline-disabled'
  const times = loadingSlots || noSlots ? [] : slotsOf(day)
  const chosen = time && times.includes(time) ? time : null
  const confirmed = shown === 'success'

  const at = (iso: string, hm: string): Date => {
    const [h = 0, m = 0] = hm.split(':').map(Number)
    const base = f.civil(isoToDate(f, iso))
    return f.kuwaitDate(base.year, base.month, base.day, h, m)
  }
  const timeLabel = (hm: string) => f.time(at(day, hm))

  const confirm = () => {
    if (!chosen) return
    setPhase('confirming')
    timer.current = window.setTimeout(() => {
      usePlannerFlow.getState().setMeeting({ date: day, time: chosen, type })
      setPhase('success')
    }, 900)
  }
  const close = () => nav.closeSheet()

  // ---------------------------------------------------------------- success: one drawing, the outcome, the date, the time, the call type
  if (confirmed) {
    const doneDay = state === 'success' ? (day || firstDay) : day
    const doneTime = chosen ?? time ?? storyTime
    const doneAt = at(doneDay, doneTime)
    const typeName = type === 'phone' ? t('clientPlannerTypePhoneName') : t('clientPlannerTypeVideoName')
    return (
      <div className="gzp4" data-gz-id="plan.meeting.sheet">
        <section className="gzp4-done" data-gz="SuccessState">
          <Illustration name="success-visit" size="lg" />
          <h2 className="gzp4-done__title gz-t-d2">{t('clientPlannerMeetingSuccessTitle')}</h2>
          <FactRow className="gzp4-done__facts" label={t('clientPlannerMeetingTitle')}>
            <FactChip icon="calendar" label={t('clientPlannerMeetingDayLabel')} value={<Fx text={f.date(doneAt, 'short')} />} />
            <FactChip icon="clock" label={t('clientPlannerMeetingTimeLabel')} value={<Fx text={f.time(doneAt)} />} />
            <FactChip icon={type === 'phone' ? 'phone' : 'video'} label={`${typeName}, ${tc('commonLabelKuwaitTime')}`} />
          </FactRow>
          <div className="gzp4-done__actions">
            <Button variant="primary" onClick={close}>
              {tc('commonActionDone')}
            </Button>
            <Button
              variant="tertiary"
              iconStart="calendar-plus"
              onClick={() => nav.toast({ message: t('clientPlannerStatusCalendarToast'), tone: 'success' })}
            >
              {t('clientPlannerMeetingCalendar')}
            </Button>
          </div>
        </section>
      </div>
    )
  }

  // ---------------------------------------------------------------- the picker
  const busy = shown === 'confirming'
  return (
    <div className="gzp4" data-gz-id="plan.meeting.sheet" aria-busy={busy || undefined}>
      <SheetHead title={t('clientPlannerMeetingTitle')} onClose={close} leading={<Avatar name={name} size="sm" />} />

      {offline ? (
        <SheetNote icon="offline" tone="quiet">
          {tc('commonStateOffline')}
        </SheetNote>
      ) : null}

      {noSlots ? (
        <EmptyState
          illustration="empty-bookings"
          fill={false}
          title={t('clientPlannerMeetingNoSlotsTitle')}
          action={{
            label: tc('commonActionMessage'),
            iconStart: 'chat',
            onPress: () => {
              nav.closeSheet()
              nav.push('CL-MSGS-02', { conversationId: STORY_CONVERSATION })
            },
          }}
        />
      ) : (
        <>
          <DayGrid
            days={days}
            value={day}
            onPick={iso => {
              setDay(iso)
              setTime(null)
            }}
            name={t('clientPlannerMeetingDayLabel')}
            label={iso => {
              const label = f.date(isoToDate(f, iso), 'short')
              return slotsOf(iso).length > 0 ? label : t('clientPlannerMeetingDayNoSlots', { day: label })
            }}
            enabled={iso => slotsOf(iso).length > 0}
            marks={iso => (slotsOf(iso).length > 0 && iso !== day ? ['bead'] : [])}
            disabled={busy}
            aside={
              <>
                <Icon name="clock" size="xs" />
                <span>{tc('commonLabelKuwaitTime')}</span>
              </>
            }
          />

          <section className="gzp4-field" aria-label={t('clientPlannerMeetingTimeLabel')}>
            {shown === 'idle' && state === 'slot-taken' ? (
              <SheetNote icon="info">{t('clientPlannerMeetingTaken')}</SheetNote>
            ) : null}
            {loadingSlots ? (
              <div className="gzp4-skel" aria-busy="true">
                {[0, 1, 2, 3].map(i => (
                  <Skeleton key={i} inlineSize={96} blockSize={44} />
                ))}
              </div>
            ) : (
              <ChipGroup<string>
                selection="single"
                label={t('clientPlannerMeetingTimeLabel')}
                options={times.map(hm => ({ value: hm, label: <Figures text={timeLabel(hm)} /> }))}
                value={chosen}
                onChange={setTime}
                disabled={busy || offline}
              />
            )}
          </section>

          <IconSegmented<MeetingType>
            label={t('clientPlannerMeetingTypeLabel')}
            value={type}
            onChange={setType}
            disabled={busy || offline}
            options={[
              { value: 'video', icon: 'video', label: t('clientPlannerTypeVideo') },
              { value: 'phone', icon: 'phone', label: t('clientPlannerTypePhone') },
            ]}
          />

          <div className="gzp4-foot">
            <Button variant="primary" fullWidth loading={busy} disabled={!chosen || offline || loadingSlots} onClick={confirm}>
              {t('clientPlannerMeetingConfirm')}
            </Button>
          </div>
        </>
      )}
    </div>
  )
}
