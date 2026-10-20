// WeekRows: the week as seven day rows, Sunday first, with one lane per hall (HL-CALN-02). A lane is one line and a target (44 minimum) and says
// its state three ways: shape (solid ink bar = booked, gold hatch = on hold, cross-hatch + strike = blocked, hairline outline = open, gold bead =
// a request that claims nothing), a glyph at its end (check, hourglass, lock; the word is its accessible name) and the facts as glyph and value
// (the client, the guests, the time left). Thu-Sat carry the rose peak wash, today the ink outline on its date, and past days are quiet: a past
// day nobody held draws no lane at all. Open lanes carry a quiet inline Block and, Thu-Sat, Offer. In "Select dates" mode a tap on a date
// starts, then ends, a range (the accessible path; the same range bar as the month).
import type { CalendarClaim, Hall, IsoDate } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Button, Icon, ThreadBead } from '../../../../system'
import type { DateSpan } from '../../../../system'
import { Hatch } from './Hatch'
import { TODAY, addDays, canBlock, canOffer, claimOf, markOf, minutesLeft, requestsOn, weekdayOf, type Role } from './data'
import { Fig, Fx, UserText, useLeft, useReasonLabel, useShortHall, useWords } from './calBits'
import './week-rows.css'

export type WeekRowsProps = {
  sunday: IsoDate
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  role: Role
  offline?: boolean
  selecting?: boolean
  range?: DateSpan
  onTapDate: (iso: IsoDate) => void
  onOpenDay: (iso: IsoDate) => void
  onBlock: (iso: IsoDate, hallId: string) => void
  onOpenDates: (iso: IsoDate) => void
  onOffer: (iso: IsoDate) => void
  onBooking: (bookingId: string) => void
}

const inRange = (iso: IsoDate, r?: DateSpan): 'edge' | 'in' | undefined => {
  if (!r?.start) return undefined
  const end = r.end ?? r.start
  const [a, b] = r.start <= end ? [r.start, end] : [end, r.start]
  if (iso === a || iso === b) return 'edge'
  return iso > a && iso < b ? 'in' : undefined
}

export function WeekRows({ sunday, halls, claims, role, offline, selecting, range, onTapDate, onOpenDay, onBlock, onOpenDates, onOffer, onBooking }: WeekRowsProps) {
  const f = useFormat()
  const { t, c } = useWords()
  const short = useShortHall(halls)
  const left = useLeft()
  const reasonLabel = useReasonLabel()
  const days = Array.from({ length: 7 }, (_, i) => addDays(sunday, i))

  return (
    <ol className="cal-wk" aria-label={t('hotelCalendarWeekLabel')}>
      {days.map(iso => {
        const wd = weekdayOf(iso)
        const past = iso < TODAY
        const today = iso === TODAY
        const sel = selecting ? inRange(iso, range) : undefined
        const may = canBlock(role) && !past
        return (
          <li key={iso} className="cal-wk__day" data-peak={wd >= 4 || undefined} data-past={past || undefined}>
            <button
              type="button"
              className="gz-reset cal-wk__date gz-press"
              data-today={today || undefined}
              data-sel={sel}
              aria-pressed={selecting ? Boolean(sel) : undefined}
              aria-label={`${f.date(iso, 'short')}${today ? `، ${c('commonLabelToday')}` : ''}`}
              onClick={() => (selecting ? onTapDate(iso) : onOpenDay(iso))}
            >
              <span className="cal-wk__wd gz-t-caption">{f.weekdayName(wd, 'header')}</span>
              <span className="cal-wk__num gz-t-price-strong">
                <Fig>{f.integer(Number(iso.slice(8)))}</Fig>
              </span>
            </button>
            <div className="cal-wk__lanes">
              {halls.map(h => {
                const claim = claimOf(claims, iso, h.id)
                const mark = markOf(claim)
                const asked = requestsOn(claims, iso, [h.id])
                // A past day nobody held is a quiet date and nothing else.
                if (past && !mark) return null
                const state = mark ?? 'open'
                const word = mark === 'booked' ? (past ? c('commonStatusCompleted') : c('commonAvailabilityBooked')) : mark === 'held' ? c('commonAvailabilityHeld') : mark === 'blocked' ? c('commonAvailabilityBlocked') : asked > 0 ? t('hotelCalendarRequestedLabel') : t('hotelCalendarOpenLabel')
                const glyph = mark === 'booked' ? (past ? 'check-double' : 'check') : mark === 'held' ? 'hourglass' : mark === 'blocked' ? 'lock' : null

                const body = (
                  <>
                    {mark === 'held' ? (
                      <span className="cal-wk__stripe">
                        <Hatch tone="gold" />
                      </span>
                    ) : null}
                    {mark === 'blocked' ? (
                      <span className="cal-wk__stripe">
                        <Hatch tone="ink" kind="cross" />
                      </span>
                    ) : null}
                    <span className="cal-wk__text gz-t-caption">
                      {halls.length > 1 ? <span className="cal-wk__hall">{short(h.id)}</span> : null}
                      {mark === 'booked' || mark === 'held' ? (
                        claim?.clientName ? <UserText>{claim.clientName}</UserText> : null
                      ) : mark === 'blocked' && claim ? (
                        <span className="cal-wk__struck">{reasonLabel(claim.blockReason)}</span>
                      ) : asked > 0 ? (
                        <span className="cal-wk__open">
                          <ThreadBead tone="gold" />
                          {word}
                        </span>
                      ) : (
                        <span className="cal-wk__open">{word}</span>
                      )}
                    </span>
                    {mark === 'booked' || mark === 'held' ? (
                      <span className="cal-wk__facts gz-t-fig-caption">
                        {mark === 'held' && claim?.holdUntil ? (
                          <span className="cal-wk__fact">
                            <Icon name="timer" size="xs" tone="inherit" />
                            <Fx text={left.lead(minutesLeft(claim.holdUntil))} />
                          </span>
                        ) : claim?.guests ? (
                          <span className="cal-wk__fact">
                            <Icon name="users-three" size="xs" tone="inherit" />
                            <Fig>{f.integer(claim.guests)}</Fig>
                            <span className="gz-sr-only">{t('hotelCalendarGuestsFact')}</span>
                          </span>
                        ) : null}
                      </span>
                    ) : null}
                  </>
                )
                const end = glyph ? (
                  <span className="cal-wk__state">
                    <Icon name={glyph} size="sm" tone="inherit" />
                    <span className="gz-sr-only">{word}</span>
                  </span>
                ) : null
                const tap = mark === 'booked' || mark === 'held' ? (claim?.bookingId ? () => onBooking(claim.bookingId as string) : undefined) : mark === 'blocked' && may && !selecting ? () => onOpenDates(iso) : undefined
                if (!mark && may && !selecting) {
                  return (
                    <div key={h.id} className="cal-wk__lane" data-state="open">
                      {body}
                      <span className="cal-wk__acts">
                        <Button variant="tertiary" disabled={offline} onClick={() => onBlock(iso, h.id)}>
                          {t('hotelCalendarBlock')}
                        </Button>
                        {wd >= 4 && canOffer(role) ? (
                          <Button variant="tertiary" disabled={offline} onClick={() => onOffer(iso)}>
                            {t('hotelCalendarOffer')}
                          </Button>
                        ) : null}
                      </span>
                    </div>
                  )
                }
                return tap && !selecting ? (
                  <button key={h.id} type="button" className="gz-reset cal-wk__lane gz-press" data-state={state} data-past={past || undefined} onClick={tap}>
                    {body}
                    {end}
                  </button>
                ) : (
                  <div key={h.id} className="cal-wk__lane" data-state={state} data-past={past || undefined}>
                    {body}
                    {end}
                  </div>
                )
              })}
            </div>
          </li>
        )
      })}
    </ol>
  )
}
