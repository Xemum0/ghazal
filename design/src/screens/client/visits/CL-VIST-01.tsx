// CL-VIST-01 Book a visit (sheet). Requirements: CA-VIS-01, CA-VIS-02, CA-AUTH-10.
// Text diet (ADR 0034, docs/design/02-text-diet.md): the sheet is the venue, a rail of figures for the day, glyph-led arrival windows, a
// visitors stepper and a one-line note, then the one gold action. No labels, captions or helper lines: the two sentences this sheet used to
// carry (a visit is free and needs no voucher; a chat opens with the venue and Ghazal support; each window lasts 30 minutes) sit behind the
// info glyph in the header (the voucher-terms exception). The first free window of the first day is chosen from the start, so one tap sends.
// A window taken meanwhile turns into a struck chip with the next free ones offered; nothing is queued offline.
// Opened from the venue detail (CL-VENU-01), the confirmed booking and Booking detail.
// States: default, no-slots-this-week, slot-taken, sending, error, offline.
import { useMemo, useState } from 'react'
import { getHall, getVenue, visitSlotsFor } from '../../../mock'
import { Banner, Button, Chip, Icon, InfoButton, Stepper, TextField, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { SheetFrame } from './_components/SheetFrame'
import { SlotPicker, useVisitDates } from './_components/SlotPicker'
import { VenueLine } from './_components/VenueLine'
import { NOTE_MAX, VISITORS_MAX, VISITORS_MIN, offersVisits, useV, type VisitParams } from './_components/model'
import './CL-VIST-01.css'

export const states = ['no-slots-this-week', 'slot-taken', 'sending', 'error', 'offline']

const DEFAULT_VENUE = 'V01'
const SENDING_MS = 700
const DEFAULT_VISITORS = 2
const WINDOW_MINUTES = 30

export default function BookVisit() {
  const { state } = useFrame()
  const nav = useNav<VisitParams>()
  const { t, tc, f, bi, live, dayLine, clockParts } = useV()
  const p = nav.params
  const venue = getVenue(p.venueId ?? DEFAULT_VENUE) ?? getVenue(DEFAULT_VENUE)!
  const hall = (p.hallId ? getHall(p.hallId)?.hall : undefined) ?? null
  const skipDays = state === 'no-slots-this-week' ? 7 : 0
  const dates = useVisitDates(venue.id, skipDays)

  const first = useMemo(() => {
    const d = p.date && dates.includes(p.date) ? p.date : (dates[0] ?? null)
    const free = d ? visitSlotsFor(venue.id, d).filter(x => x.available) : []
    return { date: d, slot: free.find(x => x.start === p.slot)?.start ?? free[0]?.start ?? null }
  }, [venue.id, dates, p.date, p.slot])
  const [date, setDate] = useState<string | null>(first.date)
  const [slot, setSlot] = useState<string | null>(first.slot)
  const [visitors, setVisitors] = useState(Math.min(VISITORS_MAX, Math.max(VISITORS_MIN, p.visitors ?? DEFAULT_VISITORS)))
  const [note, setNote] = useState(p.note ?? '')
  const [busy, setBusy] = useState(state === 'sending')
  const [failed, setFailed] = useState(state === 'error')
  const [taken, setTaken] = useState<string | null>(state === 'slot-taken' ? first.slot : null)

  const offline = state === 'offline'
  const day = date && dates.includes(date) ? date : null

  // The next two free windows after the one that was taken: offered inline so the person does not start again.
  const nextFree = useMemo(() => {
    if (!taken || !day) return []
    return visitSlotsFor(venue.id, day)
      .filter(s => s.available && s.start > taken)
      .slice(0, 2)
      .map(s => s.start)
  }, [taken, day, venue.id])

  const send = () => {
    if (!slot || !day || busy) return
    setFailed(false)
    setBusy(true)
    if (!live) return
    setTimeout(() => {
      const id = usePrototype.getState().bookVisit({ venueId: venue.id, slotStart: slot, visitors, note: note.trim() || null })
      setBusy(false)
      if (!id) return setFailed(true)
      nav.closeSheet()
      nav.push('CL-VIST-02', { visitId: id, venueId: venue.id })
    }, SENDING_MS)
  }

  if (!offersVisits(venue.id)) return null

  const info = (
    <InfoButton title={t('clientVisitsInfoTitle')} icon="info">
      <p>{t('clientVisitsInfoFree')}</p>
      <p>{t('clientVisitsInfoChat', { venue: bi(venue.name) })}</p>
      <p>{t('clientVisitsInfoWindow', { minutes: f.integer(WINDOW_MINUTES) })}</p>
    </InfoButton>
  )

  const footer = (
    <Button variant="primary" fullWidth loading={busy} disabled={!slot || taken === slot || offline} onClick={send}>
      {t('clientVisitsBookAction')}
    </Button>
  )

  const takenTime = taken ? clockParts(taken) : null

  return (
    <>
      <SheetFrame title={t('clientVisitsBookTitle')} info={info} footer={footer}>
        <VenueLine venue={venue} caption={hall ? bi(hall.name) : undefined} />

        {offline ? (
          <Banner tone="offline" shape="card">
            {tc('commonStateOffline')}
          </Banner>
        ) : null}
        {failed ? (
          <Banner tone="danger" action={{ label: tc('commonActionRetry'), onPress: send }}>
            {t('clientVisitsNotSent')}
          </Banner>
        ) : null}
        {skipDays > 0 && dates[0] ? (
          <Banner tone="info" shape="card" icon="calendar-dots">
            {t('clientVisitsNoWeek', { date: dayLine(dates[0]) })}
          </Banner>
        ) : null}
        {taken && slot === taken && takenTime ? (
          <div className="gzvt-bk__taken" role="status">
            <p className="gzvt-bk__taken-text gz-t-body-s">
              <Icon name="clock-off" size="sm" tone="secondary" />
              <span className="gz-t-fig-body-s">{`${takenTime.hm} ${takenTime.mer}`}</span>
              <span>{t('clientVisitsSlotTaken')}</span>
            </p>
            {nextFree.length > 0 ? (
              <div className="gzvt-bk__taken-next" role="group" aria-label={t('clientVisitsTakenNext')}>
                <Icon name="forward" size="sm" tone="secondary" />
                {nextFree.map(s => {
                  const c = clockParts(s)
                  return (
                    <Chip
                      key={s}
                      onClick={() => {
                        setSlot(s)
                        setTaken(null)
                      }}
                    >
                      {`${c.hm} ${c.mer}`}
                    </Chip>
                  )
                })}
              </div>
            ) : null}
          </div>
        ) : null}

        <SlotPicker
          venueId={venue.id}
          date={day}
          slot={slot}
          takenSlot={taken}
          skipDays={skipDays}
          disabled={busy}
          onChange={(d, s) => {
            setDate(d)
            setSlot(s)
            setTaken(null)
          }}
        />

        <div className="gzvt-bk__row">
          <Stepper
            label={
              <span className="gzvt-bk__lead">
                <Icon name="users-three" size="md" tone="secondary" />
                <span className="gz-sr-only">{t('clientVisitsVisitors')}</span>
              </span>
            }
            value={visitors}
            min={VISITORS_MIN}
            max={VISITORS_MAX}
            onChange={setVisitors}
            disabled={busy}
            valueText={n => t('clientVisitsVisitorsCount', { count: n })}
          />
        </div>

        <TextField
          aria-label={t('clientVisitsNoteLabel')}
          placeholder={t('clientVisitsNote')}
          startAdornment={<Icon name="chat-text" size="sm" tone="secondary" />}
          value={note}
          onValueChange={v => setNote([...v].slice(0, NOTE_MAX).join(''))}
          disabled={busy}
        />
      </SheetFrame>
    </>
  )
}
