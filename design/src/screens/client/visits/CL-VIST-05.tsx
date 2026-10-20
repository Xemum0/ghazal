// CL-VIST-05 Change or cancel visit (sheet). Requirements: CA-VIS-04, CA-VIS-03.
// Ask the hotel for another time, or cancel the visit. Text diet (ADR 0034): the visit as a venue line with its day and time as icon +
// value; two icon rows (another time, cancel visit); no sentence. The consequence the owner wants stated (no fee, nothing is lost, the
// chat records the change, the hotel is told) is the cancellation-terms exception: it sits behind the info glyph in the header, and the
// finished states carry it as their `detail`. "Another time" opens a slot picker like CL-VIST-01 and posts a system line in the chat;
// "Cancel visit" asks for one reason chip, then one explicit destructive confirm; the chat closes to read-only and the hotel is told.
// Offline both rows lose their chevron in place and show the offline glyph. Opened from the pinned card of CL-VIST-03; leads back to the
// chat or to My visits (CL-VIST-04).
// States: default, ask-other-time, cancel-confirm, success, error, offline.
import { useState } from 'react'
import { getVenue, visitSlotsFor } from '../../../mock'
import { Banner, Button, ChipGroup, Icon, IconListRow, InfoButton, SuccessState, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { SheetFrame } from './_components/SheetFrame'
import { SlotPicker, useVisitDates } from './_components/SlotPicker'
import { VenueLine } from './_components/VenueLine'
import { VisitFacts } from './_components/VisitFacts'
import { HERO_VISIT, useV, useVisitView, type VisitParams } from './_components/model'
import { useVisitActions } from './_components/useVisitActions'
import './CL-VIST-05.css'

export const states = ['ask-other-time', 'cancel-confirm', 'success', 'error', 'offline']

type Step = 'main' | 'ask' | 'cancel' | 'done-ask' | 'done-cancel'
type Reason = 'plans' | 'other-venue' | 'other'
const SENDING_MS = 700

export default function ChangeVisit() {
  const { state } = useFrame()
  const nav = useNav<VisitParams>()
  const { t, tc, f, bi, live, clock } = useV()
  const visitId = nav.params.visitId ?? HERO_VISIT
  const view = useVisitView(visitId)
  const offline = state === 'offline'
  const actions = useVisitActions(view, offline)
  const initial: Step = state === 'ask-other-time' ? 'ask' : state === 'cancel-confirm' ? 'cancel' : state === 'success' ? 'done-cancel' : 'main'
  const [step, setStep] = useState<Step>(initial)
  const [reason, setReason] = useState<Reason | null>(state === 'cancel-confirm' ? 'plans' : null)
  const [busy, setBusy] = useState(false)
  const [failed, setFailed] = useState(state === 'error')
  const venue = view ? getVenue(view.visit.venueId) : undefined
  const dates = useVisitDates(venue?.id ?? '')
  const [date, setDate] = useState<string | null>(null)
  const [slot, setSlot] = useState<string | null>(null)

  if (!view || !venue) return null
  const day = date && dates.includes(date) ? date : (dates[0] ?? null)
  const free = day ? visitSlotsFor(venue.id, day).filter(s => s.available) : []
  const chosen = slot && day && free.some(s => s.start === slot) ? slot : (free[0]?.start ?? null)
  const venueName = bi(venue.name)

  const run = (done: () => void) => {
    setFailed(false)
    setBusy(true)
    if (!live) return
    setTimeout(() => {
      setBusy(false)
      done()
    }, SENDING_MS)
  }

  const askOther = () => {
    if (!chosen) return
    run(() => {
      actions.system(t('clientVisitsSysAsked', { when: `${f.date(chosen, 'short')} · ${clock(chosen)}` }), 'asked', true)
      setStep('done-ask')
    })
  }
  const cancel = () => {
    run(() => {
      usePrototype.getState().setVisitStatus(visitId, 'cancelled', 'client')
      actions.system(t('clientVisitsSysCancelled'), 'cancelled')
      setStep('done-cancel')
    })
  }

  const info = (
    <InfoButton title={t('clientVisitsInfoFeeTitle')}>
      <p>{t('clientVisitsInfoNoFee')}</p>
      <p>{t('clientVisitsInfoRecord', { venue: venueName })}</p>
    </InfoButton>
  )
  const current = <VisitFacts slotStart={view.visit.slotStart} slotEnd={view.visit.slotEnd} tone="muted" compact />

  const banners = (
    <>
      {offline ? (
        <Banner tone="offline" shape="card">
          {tc('commonStateOffline')}
        </Banner>
      ) : null}
      {failed ? (
        <Banner tone="danger" action={{ label: tc('commonActionRetry'), onPress: step === 'ask' ? askOther : cancel }}>
          {t('clientVisitsNothingChanged')}
        </Banner>
      ) : null}
    </>
  )

  if (step === 'ask') {
    return (
      <SheetFrame
        title={t('clientVisitsRowAsk')}
        subtitle={current}
        footer={
          <>
            <Button variant="primary" fullWidth loading={busy} disabled={!chosen || offline} onClick={askOther}>
              {t('clientVisitsAskAction')}
            </Button>
            <Button variant="tertiary" onClick={() => setStep('main')}>
              {tc('commonActionBack')}
            </Button>
          </>
        }
      >
        {banners}
        <SlotPicker
          venueId={venue.id}
          date={day}
          slot={chosen}
          disabled={busy}
          onChange={(d, s) => {
            setDate(d)
            setSlot(s)
          }}
        />
      </SheetFrame>
    )
  }

  if (step === 'cancel') {
    return (
      <SheetFrame
        title={t('clientVisitsRowCancel')}
        subtitle={current}
        info={info}
        footer={
          <>
            <Button
              variant="destructive"
              fullWidth
              iconStart="calendar-x"
              loading={busy}
              disabled={!reason || offline}
              reason={!reason ? t('clientVisitsPickReason') : undefined}
              onClick={cancel}
            >
              {t('clientVisitsRowCancel')}
            </Button>
            <Button variant="tertiary" onClick={() => setStep('main')}>
              {t('clientVisitsKeepVisit')}
            </Button>
          </>
        }
      >
        {banners}
        <ChipGroup
          label={t('clientVisitsPickReason')}
          value={reason}
          onChange={v => setReason(v)}
          options={[
            { value: 'plans', label: t('clientVisitsReasonPlans') },
            { value: 'other-venue', label: t('clientVisitsReasonOtherVenue') },
            { value: 'other', label: t('clientVisitsReasonOther') },
          ]}
          disabled={busy}
        />
      </SheetFrame>
    )
  }

  if (step === 'done-ask' || step === 'done-cancel') {
    const cancelled = step === 'done-cancel'
    return (
      <SheetFrame
        title={<span className="gz-sr-only">{t('clientVisitsChangeTitle')}</span>}
        footer={
          <>
            <Button variant="primary" fullWidth onClick={() => nav.closeSheet()}>
              {tc('commonActionDone')}
            </Button>
            {cancelled ? (
              <Button
                variant="tertiary"
                onClick={() => {
                  nav.closeSheet()
                  nav.push('CL-VIST-04')
                }}
              >
                {t('clientVisitsListTitle')}
              </Button>
            ) : null}
          </>
        }
      >
        <SuccessState
          fill={false}
          size="lg"
          illustration={cancelled ? 'calendar' : 'success-request'}
          title={cancelled ? t('clientVisitsDoneCancelTitle') : t('clientVisitsDoneAskTitle')}
          detailTitle={cancelled ? t('clientVisitsInfoFeeTitle') : undefined}
          detail={cancelled ? t('clientVisitsDoneCancelDetail', { venue: venueName }) : t('clientVisitsDoneAskDetail', { venue: venueName })}
        />
      </SheetFrame>
    )
  }

  return (
    <SheetFrame title={t('clientVisitsChangeTitle')} info={info}>
      <VenueLine venue={venue} facts={<VisitFacts slotStart={view.visit.slotStart} slotEnd={view.visit.slotEnd} compact />} />
      {banners}
      <div className="gzvt-ch5__rows">
        <IconListRow
          flush
          icon="calendar-dots"
          title={t('clientVisitsRowAsk')}
          chevron={!offline}
          trailing={offline ? <Icon name="offline" size="sm" tone="secondary" /> : undefined}
          onClick={offline ? undefined : () => setStep('ask')}
        />
        <IconListRow
          flush
          last
          tone="danger"
          icon="calendar-x"
          title={t('clientVisitsRowCancel')}
          chevron={!offline}
          trailing={offline ? <Icon name="offline" size="sm" tone="secondary" /> : undefined}
          onClick={offline ? undefined : () => setStep('cancel')}
        />
      </div>
    </SheetFrame>
  )
}
