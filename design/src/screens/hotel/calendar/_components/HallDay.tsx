// HallDay: one hall on one date, in operational detail (HL-CALN-03), told in glyphs and figures (ADR 0034): the hall's short name, its facts
// (capacity, the session window, and for an event today the time until it starts), the business-day bar (setup, event, teardown) and the
// card of what the hall carries: a booking (monogram, name, section and guests, Call and Chat, one status word), a hold (the same, with the
// time left to confirm as a figure), a block (its reason, who made it, Open date) or an open hall (a doorway, Block and Offer). The clock
// times of setup, event and teardown live behind the (i) of the hall. Pending requests for the date are a bead, a name and an (i): a request
// never claims the date (ADR 0001 D5).
import type { CalendarClaim, Hall, IsoDate } from '../../../../mock'
import { conversationsFor } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Avatar, Button, FactChip, FactRow, Icon, IconButton, Illustration, InfoButton, StatusPill, ThreadBead, useNav } from '../../../../system'
import { ScheduleKey, type ScheduleRow } from './Legend'
import { TimelineBar, type Segment } from './TimelineBar'
import { NOW_CLOCK, TODAY, addDays, canBlock, canOffer, minutesLeft, type Role } from './data'
import { Fx, UserText, audienceIcon, sessionIcon, useAudienceLabel, useClock, useLeft, useReasonLabel, useShortHall, useWords } from './calBits'
import './hall-day.css'

export type HallDayProps = {
  date: IsoDate
  hall: Hall
  /** Every hall the venue has: the short name drops the generic word only when two halls tell them apart. */
  allHalls: readonly Hall[]
  claims: readonly CalendarClaim[]
  claim: CalendarClaim | undefined
  role: Role
  offline?: boolean
  onBlock: (hallId: string) => void
  onOpenDates: () => void
}

const shift = (hhmm: string, minutes: number): { time: string; next: boolean } => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  const total = h * 60 + m + minutes
  const t = ((total % 1440) + 1440) % 1440
  return { time: `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`, next: total >= 1440 || total < 0 }
}
const toMin = (hhmm: string): number => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return h * 60 + m
}

export function HallDay({ date, hall, allHalls, claims, claim, role, offline, onBlock, onOpenDates }: HallDayProps) {
  const f = useFormat()
  const nav = useNav()
  const { t, c } = useWords()
  const short = useShortHall(allHalls)
  const clock = useClock()
  const left = useLeft()
  const audience = useAudienceLabel()
  const reasonLabel = useReasonLabel()
  const session = hall.sessions[0]
  const past = date < TODAY
  const may = canBlock(role) && !past
  const kind = claim?.kind
  const start = claim?.start ?? session?.start ?? '21:00'
  const end = claim?.end ?? session?.end ?? '02:00'
  const asked = claims.filter(x => x.date === date && x.hallId === hall.id && x.kind === 'requested')
  const startsIn = date === TODAY && kind === 'booking' ? toMin(start) - toMin(NOW_CLOCK) : 0

  const segments: Segment[] = []
  const rows: ScheduleRow[] = []
  if (session && kind === 'booking') {
    const before = shift(start, -session.bufferBeforeMin)
    const after = shift(end, session.bufferAfterMin)
    segments.push({ kind: 'setup', start: before.time, end: start }, { kind: 'event', start, end }, { kind: 'teardown', start: end, end: after.time })
    rows.push(
      { key: 'setup', kind: 'setup', label: t('hotelCalendarSetup'), time: clock.range(date, before.time, start) },
      { key: 'event', kind: 'event', label: t('hotelCalendarEvent'), time: clock.range(date, start, end) },
      { key: 'down', kind: 'teardown', label: t('hotelCalendarTeardown'), time: clock.range(end < start ? addDays(date, 1) : date, end, after.time), extra: end < start || after.next ? f.date(addDays(date, 1), 'short') : undefined },
    )
  } else if (session && kind === 'hold') segments.push({ kind: 'held', start, end })
  else if (session && kind === 'block') segments.push({ kind: 'blocked', start: session.start, end: session.end })
  else if (session) segments.push({ kind: 'window', start: session.start, end: session.end })

  const conversation = claim?.bookingId ? conversationsFor('hotel').find(x => x.bookingId === claim.bookingId) : undefined
  const name = claim?.clientName ?? ''
  const holdLeft = kind === 'hold' && claim?.holdUntil ? left.lead(minutesLeft(claim.holdUntil)) : null

  return (
    <section className="cal-hd" data-gz="HallDay" aria-label={allHalls.length > 1 ? hall.name[f.lang] : short(hall.id)}>
      <header className="cal-hd__head">
        <h3 className="cal-hd__name gz-t-ui-title">{short(hall.id)}</h3>
        {rows.length > 0 ? <ScheduleKey title={t('hotelCalendarTimes')} rows={rows} /> : null}
      </header>

      <FactRow label={c('commonLabelDetails')}>
        <FactChip icon="users-three" label={t('hotelCalendarCapacityFact')} value={f.integer(hall.capacity.max)} />
        {session ? <FactChip icon={sessionIcon(session.start)} label={t('hotelCalendarSessionFact')} value={<Fx text={clock.range(date, session.start, session.end)} />} /> : null}
        {startsIn > 0 ? <FactChip icon="timer" tone="accent" label={t('hotelCalendarStartsFact')} value={<Fx text={left.lead(startsIn)} />} /> : null}
      </FactRow>

      <TimelineBar date={date} segments={segments} label={t('hotelCalendarTimelineLabel', { hall: hall.name[f.lang] })} />

      {kind === 'booking' || kind === 'hold' ? (
        <div className="cal-hd__card" data-kind={kind}>
          <div className="cal-hd__who">
            <button type="button" className="gz-reset cal-hd__main gz-press" onClick={() => claim?.bookingId && nav.push('HL-BOOK-03', { bookingId: claim.bookingId })} aria-label={`${t('hotelCalendarOpenBooking')}، ${name}`}>
              <Avatar name={name} size="sm" voice="sans" />
              <span className="cal-hd__id">
                <span className="cal-hd__client gz-t-body">
                  <UserText role="body">{name}</UserText>
                </span>
                <FactRow>
                  <FactChip size="sm" icon={audienceIcon(claim?.audience)} label={audience(claim?.audience ?? null)} />
                  <FactChip size="sm" icon="users-three" label={t('hotelCalendarGuestsFact')} value={f.integer(claim?.guests ?? 0)} />
                </FactRow>
              </span>
            </button>
            <IconButton icon="phone" label={t('hotelCalendarCall', { name })} onClick={() => claim?.bookingId && nav.openSheet('HL-BOOK-04', { params: { bookingId: claim.bookingId } })} />
            <IconButton
              icon="chat"
              label={t('hotelCalendarMessage', { name })}
              onClick={() => claim?.bookingId && nav.push('HL-TODY-05', { bookingId: claim.bookingId, conversationId: conversation?.id ?? null })}
            />
          </div>
          <div className="cal-hd__line">
            <StatusPill status={kind === 'booking' ? 'confirmed' : 'held'} audience="hotel" />
            {holdLeft ? <FactChip icon="timer" tone="accent" label={t('hotelCalendarHoldLeft')} value={<Fx text={holdLeft} />} /> : null}
          </div>
        </div>
      ) : null}

      {kind === 'block' && claim ? (
        <div className="cal-hd__card" data-kind="block">
          <div className="cal-hd__blk">
            <span className="gz-irow__disk" aria-hidden="true">
              <Icon name="lock" size="md" tone="primary" />
            </span>
            <span className="cal-hd__id">
              <span className="cal-hd__client gz-t-body">{reasonLabel(claim.blockReason)}</span>
              {claim.blockedBy ? (
                <FactRow>
                  <FactChip size="sm" icon="user" label={t('hotelCalendarBlockedByFact')} value={claim.blockedBy} />
                </FactRow>
              ) : null}
            </span>
            <StatusPill status="blocked" audience="hotel" />
          </div>
          {may ? (
            <div className="cal-hd__act">
              <Button variant="secondary" iconStart="lock" disabled={offline} onClick={onOpenDates}>
                {t('hotelCalendarOpenThisDate')}
              </Button>
            </div>
          ) : null}
        </div>
      ) : null}

      {!kind ? (
        <div className="cal-hd__open">
          <div className="cal-hd__openhead">
            <span className="cal-hd__door" aria-hidden="true">
              <Illustration name={past ? 'calendar' : 'doorway'} size="sm" />
            </span>
            {past ? <StatusPill status="past" /> : <StatusPill status="available" label={t('hotelCalendarOpenLabel')} />}
          </div>
          {may || (canOffer(role) && !past) ? (
            <div className="cal-hd__acts">
              {may ? (
                <Button variant="secondary" iconStart="lock" disabled={offline} onClick={() => onBlock(hall.id)}>
                  {t('hotelCalendarBlock')}
                </Button>
              ) : null}
              {canOffer(role) && !past ? (
                <Button variant="tertiary" iconStart="offer" disabled={offline} onClick={() => nav.push('HL-GROW-02', { date })}>
                  {t('hotelCalendarOffer')}
                </Button>
              ) : null}
            </div>
          ) : null}
        </div>
      ) : null}

      {asked.length > 0 ? (
        <div className="cal-hd__req">
          {asked.map((r, i) => (
            <div key={r.id} className="cal-hd__reqrow">
              <button type="button" className="gz-reset cal-hd__reqmain gz-press" onClick={() => r.bookingId && nav.push('HL-BOOK-03', { bookingId: r.bookingId })}>
                <ThreadBead tone="gold" />
                <span className="cal-hd__reqword gz-t-caption">{t('hotelCalendarRequestedLabel')}</span>
                {r.clientName ? <UserText role="body-s">{r.clientName}</UserText> : <span />}
                <Icon name="chevron-right" size="sm" tone="secondary" />
              </button>
              {i === 0 ? (
                <InfoButton title={t('hotelCalendarRequestedLabel')}>
                  <p>{t('hotelCalendarRequestNote')}</p>
                </InfoButton>
              ) : (
                <span className="cal-hd__reqgap" aria-hidden="true" />
              )}
            </div>
          ))}
        </div>
      ) : null}
    </section>
  )
}
