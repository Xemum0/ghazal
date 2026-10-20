// HL-DCSN-03 Propose another date (sheet). Requirement IDs: HA-BOOK-05, HA-BOOK-04, HA-CAL-09, HA-AUTH-02.
// ADR 0008 D7, ADR 0033 D3 and A-05: one to three other dates for the same hall and session on a PENDING request, sent as ONE card the client
// answers ("Venue proposed another date", 48 h). It is the counter-offer only: a confirmed booking is never rescheduled in the app (the
// date is agreed in the chat and, if it moves, the client may need a new request). The voucher price is always held: a date that normally
// costs more keeps the quoted voucher price and the venue absorbs the difference. If the client accepts, the request becomes Approved with a
// new 24 h confirm window. A service request has no hall calendar, so a provider is sent to the chat.
// Story: Reem Al-Dosari asked for Thu 14 Jan 2027 in Danah Ballroom (voucher KD 15,400.000); the free dates come from the availability engine
// and are re-quoted at the voucher price with the booking's own package. Gold = the picked days and the one primary.
// Text diet (ADR 0034): no intro sentence. Three pips count the picks (one to three), `timer 48 h` is the client's reply window, the picked
// dates are glyph rows (ticket and amount; a lock and the struck date price when the voucher price is held; a trend-down and the difference
// when cheaper), the calendar has no legend (busy days are struck, the original is ringed). What the client sees, the 48 hours and the held
// price are three short paragraphs behind the info glyph of the header (voucher terms). Empty, no-hall, success, error and offline are a
// drawing, a short title and one action.
// Requirement homes: HA-BOOK-05 the one to three picked dates and "Send proposal"; HA-BOOK-04 the hand-off from Decline (the reason travels with it);
// HA-CAL-09 the hall switcher (only when the venue has several suitable halls) and the session glyph of the context strip; HA-AUTH-02 the sheet
// is opened by the roles that may propose (a service request, which has no hall calendar, is sent to the chat).
import { useEffect, useMemo, useRef, useState } from 'react'
import { clock, conversationsFor, engine, type Booking, type IsoDate, type Money } from '../../../mock'
import { useFormat, useT, T } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { Button, FactChip, FactRow, InfoButton, SegmentedControl, TextField, useBi, useNav } from '../../../system'
import { SheetShell } from './_components/SheetShell'
import { RequestContext } from './_components/RequestContext'
import { Fx } from './_components/Fx'
import { PickPips, PriceFact, SheetError, SheetState } from './_components/Blocks'
import { MultiDateCalendar } from './_components/MultiDateCalendar'
import { ProposalList, type ProposalEntry } from './_components/ProposalList'
import { RICH } from './_components/local'
import { PRESET_PICKS, freeDates, horizonMonths, startMonth, suitableHalls, type YearMonth } from './_components/proposal'
import {
  DANA_BOOKING_ID,
  MAX_PROPOSED,
  PROPOSAL_HORIZON_DAYS,
  PROVIDER_BOOKING_ID,
  STORY_BOOKING_ID,
  confirmWindowHours,
  hallOf,
  inHours,
  proposalWindowHours,
  commitAfterUndoWindow,
  revealInSheet,
  useClientName,
  useDecisionBooking,
  useHoursFig,
} from './_components/decisions'
import './HL-DCSN-03.css'

export const states = ['selected', 'price-held', 'no-open-dates', 'no-hall', 'loading', 'success', 'error', 'offline', 'date-taken']

type Phase = 'idle' | 'loading' | 'success'

export default function ProposeDate({ state }: { state?: string }) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const tc = useT('common')
  const bi = useBi()
  const nav = useNav()
  const booking = useDecisionBooking(state === 'no-hall' ? PROVIDER_BOOKING_ID : state === 'price-held' ? DANA_BOOKING_ID : STORY_BOOKING_ID)
  const live = state === undefined

  const own = hallOf(booking)
  const halls = useMemo(() => suitableHalls(booking), [booking])
  const [hallId, setHallId] = useState(own?.hall.id ?? '')
  const hall = halls.find(h => h.id === hallId) ?? own?.hall
  const noHall = !own
  const horizon = useMemo(() => horizonMonths(), [])
  const free = useMemo(() => (state === 'no-open-dates' || noHall ? {} : freeDates(booking, hallId)), [booking, hallId, state, noHall])

  const presetKey = state === 'price-held' ? 'dana' : 'reem'
  const initialPicks = live || state === 'no-open-dates' || noHall ? [] : (PRESET_PICKS[presetKey] ?? []).filter(d => free[d])
  const [picked, setPicked] = useState<IsoDate[]>(initialPicks)
  const [month, setMonth] = useState<YearMonth>(() => startMonth(booking.eventDate))
  const [note, setNote] = useState('')
  const [phase, setPhase] = useState<Phase>(state === 'loading' ? 'loading' : state === 'success' ? 'success' : 'idle')
  const [failed, setFailed] = useState(state === 'error')
  const takenDates: IsoDate[] = state === 'date-taken' && initialPicks[1] ? [initialPicks[1]] : []
  const [taken, setTaken] = useState<IsoDate[]>(takenDates)
  const offline = state === 'offline'

  const timers = useRef<number[]>([])
  const listRef = useRef<HTMLDivElement>(null)
  const done = useRef(false)
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  // ---- the quoted voucher price, and what each picked date costs at it (integer fils). The voucher price is held, never raised:
  // a date that normally costs more keeps the quoted price (the venue absorbs the difference), a cheaper date passes its lower price on.
  const original = booking.totals.voucherTotal
  const entries: ProposalEntry[] = [...picked].sort().map(date => {
    const isTaken = taken.includes(date)
    const raw = free[date]?.fils ?? 0
    const fils = Math.min(raw, original.fils)
    return { date, fils: isTaken ? 0 : fils, delta: isTaken ? 0 : fils - original.fils, normally: !isTaken && raw > original.fils ? raw - original.fils : undefined, taken: isTaken }
  })
  // The calendar shows what the client would pay on each free day: the held voucher price, never above the quote.
  const calendarFree = useMemo(() => Object.fromEntries(Object.entries(free).map(([d, v]) => [d, { fils: Math.min(v.fils, original.fils) }])), [free, original.fils])
  const held = entries.some(e => (e.normally ?? 0) > 0)
  const takenFirst = picked.find(d => taken.includes(d))
  const blocked = taken.length > 0 && picked.some(d => taken.includes(d))

  const toggle = (iso: IsoDate) => {
    setPicked(prev => {
      if (prev.includes(iso)) return prev.filter(d => d !== iso)
      if (prev.length >= MAX_PROPOSED) return prev
      return [...prev, iso].sort()
    })
  }
  const remove = (iso: IsoDate) => {
    setPicked(prev => prev.filter(d => d !== iso))
    setTaken(prev => prev.filter(d => d !== iso))
  }
  // The first pick brings the proposal list into view: the price consequences sit under the calendar.
  const firstPick = useRef(picked.length === 0)
  useEffect(() => {
    if (picked.length > 0 && firstPick.current) {
      firstPick.current = false
      revealInSheet(listRef.current)
    }
    if (picked.length === 0) firstPick.current = true
  }, [picked.length])

  const windowHours = proposalWindowHours()
  const hoursFig = useHoursFig()
  const windowFig = hoursFig(windowHours)
  const deadline = f.dateTime(inHours(windowHours))
  const name = useClientName(booking).first
  const close = () => nav.closeSheet()
  const openChat = () => {
    close()
    nav.push('HL-TODY-05', { bookingId: booking.id, conversationId: conversationsFor('hotel').find(x => x.bookingId === booking.id)?.id ?? null })
  }

  const finish = () => {
    if (done.current) return
    done.current = true
    nav.closeSheet()
    nav.toast({ message: t('hotelDecisionsToastProposed', { window: windowFig }), tone: 'success', icon: 'check-circle' })
  }

  const send = () => {
    if (!live || offline || picked.length === 0 || blocked || !hall) return
    setPhase('loading')
    later(() => {
      applyProposal(booking, hallId, entries, windowHours)
      setPhase('success')
      later(finish, 2200)
    }, 480)
  }

  // ---- footer: one action; the way out is the close glyph of the header
  const noDates = Object.keys(free).length === 0
  const replyFact = <FactChip icon="timer" tone="muted" label={t('hotelDecisionsProposeReplyLabel')} value={<Fx text={windowFig} />} />
  let footer
  if (failed) {
    footer = null
  } else if (phase === 'success') {
    footer = (
      <>
        <Button variant="secondary" size="cta" fullWidth onClick={finish}>
          {tc('commonActionDone')}
        </Button>
        <Button variant="tertiary" onClick={() => { finish(); nav.push('HL-BOOK-03', { bookingId: booking.id }) }}>
          {t('hotelDecisionsViewBooking')}
        </Button>
      </>
    )
  } else if (noHall) {
    footer = (
      <Button variant="primary" fullWidth iconStart="chat" onClick={openChat}>
        {tc('commonActionMessage')}
      </Button>
    )
  } else if (offline) {
    footer = (
      <Button variant="primary" fullWidth disabled>
        {t('hotelDecisionsProposeCta')}
      </Button>
    )
  } else if (noDates) {
    footer = null
  } else {
    footer = (
      <Button
        variant="primary"
        fullWidth
        loading={phase === 'loading'}
        disabled={picked.length === 0 || blocked}
        reason={blocked && takenFirst ? t('hotelDecisionsProposeTakenBadge') : picked.length === 0 ? t('hotelDecisionsProposePick') : undefined}
        onClick={send}
      >
        {t('hotelDecisionsProposeCta')}
      </Button>
    )
  }

  // The sentences of the sheet, behind the info glyph of the header: the reply window, what the couple sees, the held voucher price.
  const info =
    failed || offline || noHall || phase === 'success' || noDates ? undefined : (
      <InfoButton title={t('hotelDecisionsTermsTitle')}>
        <p>{t('hotelDecisionsProposeIntro', { window: tc('commonCountHours', { count: windowHours }) })}</p>
        <p>{t('hotelDecisionsProposeHold', { amount: f.money(original.fils, { mode: 'exact' }) })}</p>
      </InfoButton>
    )

  let body
  if (failed) {
    body = <SheetError onRetry={() => setFailed(false)} />
  } else if (offline) {
    body = <SheetState illustration="wifi-off" title={tc('commonStateTitleNetwork')} detail={t('hotelDecisionsOfflineInfo')} />
  } else if (noHall) {
    body = <SheetState illustration="chat" title={t('hotelDecisionsProposeNoHallTitle')} detail={t('hotelDecisionsProposeNoHallBody')} />
  } else if (phase === 'success') {
    body = (
      <>
        <SheetState
          kind="success"
          illustration="success-request"
          title={t('hotelDecisionsProposeSentTitle')}
          detail={
            <>
              <p>
                <T ns="hotel-decisions" k="hotelDecisionsProposeAwaiting" values={{ name, deadline }} components={RICH} />
              </p>
              <p>{t('hotelDecisionsProposeSentBody', { duration: tc('commonCountHours', { count: confirmWindowHours() }) })}</p>
            </>
          }
        >
          <FactRow label={t('hotelDecisionsProposeReplyLabel')}>{replyFact}</FactRow>
        </SheetState>
        <ProposalList entries={entries} onRemove={() => undefined} readOnly />
      </>
    )
  } else {
    body = (
      <>
        {noDates ? null : (
          <div className="gzd-prop-page__meta">
            <PickPips count={picked.length} max={MAX_PROPOSED} label={t('hotelDecisionsProposeCount', { count: picked.length })} />
            {replyFact}
          </div>
        )}

        {halls.length > 1 ? (
          <SegmentedControl
            label={t('hotelDecisionsProposeHallLabel')}
            value={hallId}
            onChange={id => {
              setHallId(id)
              setPicked([])
              setTaken([])
            }}
            options={halls.map(h => ({ value: h.id, label: bi(h.name) }))}
          />
        ) : null}

        {noDates ? (
          <SheetState
            illustration="calendar"
            title={t('hotelDecisionsProposeEmptyTitle')}
            detail={t('hotelDecisionsProposeEmpty', { days: tc('commonCountDays', { count: PROPOSAL_HORIZON_DAYS }) })}
            action={{ label: t('hotelDecisionsProposeEmptyAction'), onPress: () => { close(); nav.switchTab('calendar') } }}
          />
        ) : (
          <MultiDateCalendar
            month={month}
            onMonthChange={setMonth}
            free={calendarFree}
            picked={picked.filter(d => !taken.includes(d))}
            max={MAX_PROPOSED}
            onToggle={toggle}
            original={booking.eventDate}
            taken={taken}
            minMonth={horizon.min}
            maxMonth={horizon.max}
            today={clock.today()}
            label={t('hotelDecisionsProposeCalendarLabel', { hall: f.plain(bi((hall ?? own!.hall).name)) })}
          />
        )}

        {noDates || picked.length === 0 ? null : (
          <section ref={listRef} aria-live="polite">
            <ProposalList entries={entries} onRemove={remove} />
          </section>
        )}

        {noDates ? null : <TextField label={t('hotelDecisionsNote')} value={note} onValueChange={setNote} maxLength={80} />}
      </>
    )
  }

  return (
    <SheetShell
      title={t('hotelDecisionsProposeTitle')}
      info={info}
      context={<RequestContext booking={booking} end={<PriceFact fils={original.fils} label={tc('commonVoucherPrice')} />} />}
      footer={footer}
      onClose={close}
    >
      {body}
    </SheetShell>
  )
}

/**
 * The proposal as the client will see it: ONE card with one to three dates, 48 h, the voucher price held. The store's `rescheduleRequest`
 * (which also arms the 8 s Undo) carries only the first date, so the full proposal (options, hall, session, held price) is written on top of
 * it in both copies of the request. Requested as multi-date `rescheduleRequest(id, options)` in requests.md.
 */
function applyProposal(booking: Booking, hallId: string, entries: readonly ProposalEntry[], hours: number) {
  const first = entries[0]
  if (!first) return
  usePrototype.getState().rescheduleRequest(booking.id, first.date)
  commitAfterUndoWindow(booking.id)
  const sessionId = booking.sections[0]?.sessionId ?? ''
  const currency = booking.totals.voucherTotal.currency
  const proposal = (id: string, now: string) => ({
    id,
    kind: 'counter_offer' as const,
    status: 'proposed' as const,
    proposedAt: now,
    expiresAt: engine.addHours(now, hours),
    originalPriceHeld: true,
    options: entries.map(e => ({
      eventDate: e.date,
      hallId,
      sessionId,
      quotedTotal: { fils: e.fils, currency } as Money,
      delta: { fils: e.delta, currency } as Money,
    })),
  })
  const now = clock.now()
  const patch = (list: Booking[]) => list.map(b => (b.id === booking.id ? { ...b, proposal: proposal(b.proposal?.id ?? `proposal-${booking.id}`, now) } : b))
  usePrototype.setState(s => ({ hotelBookings: patch(s.hotelBookings), clientBookings: patch(s.clientBookings) }))
}
