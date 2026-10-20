// Agenda: what the chosen day carries, under the month grid (HL-CALN-01). The heading is the date and it opens the Day view (a chevron says so;
// the old "Open day" button is gone). One row per hall (64 minimum): the client as a monogram, the name and the one-word state pill on the first
// line, the facts as glyph and value (hall, guests, session, section) on the line under it, the full width of the text column so none of
// them hides in a scroll. A held row adds the time left as a figure, a blocked row its reason, a free row the hall and Block. A booked row opens the booking, a blocked row opens the Open variant of the block sheet. Under the rows: the
// requests as a bead and a count (they claim nothing, the key behind the (i) says so) and the day's own actions: Offer, and on a sold-out day
// a disabled Block whose reason is one tap away, behind an (i), instead of a sentence.
import type { CalendarClaim, Hall, IsoDate } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Avatar, Button, FactChip, FactRow, Icon, InfoButton, StatusPill, ThreadBead, useNav } from '../../../../system'
import type { ReactNode } from 'react'
import { TODAY, canBlock, canOffer, claimOf, isFullyBlocked, isSoldOut, markOf, minutesLeft, requestsOn, type Role } from './data'
import { Fig, Fx, UserText, audienceIcon, sessionIcon, useAudienceLabel, useLeft, useReasonLabel, useShortHall, useWords } from './calBits'
import './agenda.css'

export type AgendaProps = {
  date: IsoDate
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  role: Role
  offline?: boolean
  /** Open the block sheet for this date, and one hall when the row asked for it. */
  onBlock: (hallId: string | null) => void
  /** Open the Open variant of the sheet for this date. */
  onOpenDates: () => void
}

/** One agenda row: leading mark, a name and a state on the first line, facts under them, an optional trailing action, a chevron when it opens something. */
function AgendaRow({ leading, title, status, facts, trailing, onClick, last }: { leading: ReactNode; title: ReactNode; status?: ReactNode; facts?: ReactNode; trailing?: ReactNode; onClick?: () => void; last?: boolean }) {
  const body = (
    <>
      <span className="cal-ag__lead">{leading}</span>
      <span className="cal-ag__col">
        <span className="cal-ag__line">
          <span className="cal-ag__name gz-t-title">{title}</span>
          {status}
        </span>
        {facts}
      </span>
      {trailing}
      {onClick ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
    </>
  )
  return onClick ? (
    <button type="button" data-gz="AgendaRow" className="gz-reset cal-ag__row cal-ag__row--tap gz-press" data-last={last || undefined} onClick={onClick}>
      {body}
    </button>
  ) : (
    <div data-gz="AgendaRow" className="cal-ag__row" data-last={last || undefined}>
      {body}
    </div>
  )
}

export function Agenda({ date, halls, claims, role, offline, onBlock, onOpenDates }: AgendaProps) {
  const f = useFormat()
  const { t } = useWords()
  const nav = useNav()
  const short = useShortHall(halls)
  const audience = useAudienceLabel()
  const reasonLabel = useReasonLabel()
  const left = useLeft()
  const past = date < TODAY
  const mine = halls.map(h => ({ hall: h, claim: claimOf(claims, date, h.id) }))
  const requests = requestsOn(claims, date, halls.map(h => h.id))
  const soldOut = isSoldOut(claims, date, halls)
  const blocked = isFullyBlocked(claims, date, halls)
  const someFree = mine.some(m => !m.claim)
  const may = canBlock(role) && !past
  const offerable = canOffer(role) && someFree && !blocked && !past

  const hallFact = (h: Hall) => (halls.length > 1 ? <FactChip icon="hall" label={t('hotelCalendarHallFact')} value={short(h.id)} /> : null)

  const facts = (h: Hall, c: CalendarClaim) => (
    <FactRow>
      {hallFact(h)}
      {c.guests ? <FactChip icon="users-three" label={t('hotelCalendarGuestsFact')} value={f.integer(c.guests)} /> : null}
      <FactChip icon={sessionIcon(c.start ?? h.sessions[0]?.start)} label={t('hotelCalendarSessionFact')} />
      {c.audience ? <FactChip icon={audienceIcon(c.audience)} label={audience(c.audience)} /> : null}
      {markOf(c) === 'held' && c.holdUntil ? <FactChip icon="timer" tone="accent" label={t('hotelCalendarHoldLeft')} value={<Fx text={left.lead(minutesLeft(c.holdUntil))} />} /> : null}
    </FactRow>
  )

  return (
    <section className="cal-ag" data-gz="Agenda" aria-label={t('hotelCalendarAgendaTitle', { date: f.date(date, 'short') })}>
      <button type="button" className="gz-reset cal-ag__head gz-press" onClick={() => nav.push('HL-CALN-03', { date })}>
        <span className="cal-ag__title gz-t-ui-title">
          <Fx text={f.date(date, 'short')} />
          <span className="gz-sr-only">{t('hotelCalendarOpenDay')}</span>
        </span>
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>

      <div className="cal-ag__rows">
        {mine.map(({ hall, claim }, i) => {
          const mark = markOf(claim)
          const last = i === mine.length - 1 && requests === 0
          const open = mark === 'booked' || mark === 'held' ? () => claim?.bookingId && nav.push('HL-BOOK-03', { bookingId: claim.bookingId }) : mark === 'blocked' && may ? onOpenDates : undefined
          if (claim && (mark === 'booked' || mark === 'held')) {
            return (
              <AgendaRow
                key={hall.id}
                last={last}
                leading={claim.clientName ? <Avatar name={claim.clientName} size="sm" voice="sans" /> : <span className="gz-irow__disk" aria-hidden="true"><Icon name="hall" size="md" tone="primary" /></span>}
                title={claim.clientName ? <UserText role="title">{claim.clientName}</UserText> : short(hall.id)}
                status={<StatusPill status={mark === 'booked' ? 'confirmed' : 'held'} audience="hotel" />}
                facts={facts(hall, claim)}
                onClick={open}
              />
            )
          }
          if (claim) {
            return (
              <AgendaRow
                key={hall.id}
                last={last}
                leading={
                  <span className="gz-irow__disk" aria-hidden="true">
                    <Icon name="lock" size="md" tone="primary" />
                  </span>
                }
                title={reasonLabel(claim.blockReason)}
                status={<StatusPill status="blocked" audience="hotel" />}
                facts={
                  <FactRow>
                    {hallFact(hall)}
                    {claim.blockedBy ? <span className="gz-sr-only">{t('hotelCalendarBlockedBy', { name: claim.blockedBy })}</span> : null}
                  </FactRow>
                }
                onClick={open}
              />
            )
          }
          return (
            <AgendaRow
              key={hall.id}
              last={last}
              leading={
                <span className="gz-irow__disk" aria-hidden="true">
                  <Icon name={past ? 'calendar' : 'door'} size="md" tone="secondary" />
                </span>
              }
              title={short(hall.id)}
              status={past ? <StatusPill status="past" /> : <span className="cal-ag__free gz-t-caption">{t('hotelCalendarOpenLabel')}</span>}
              trailing={
                !past && may ? (
                  <Button variant="tertiary" iconStart="lock" disabled={offline} onClick={() => onBlock(hall.id)}>
                    {t('hotelCalendarBlock')}
                  </Button>
                ) : null
              }
            />
          )
        })}
        {requests > 0 ? (
          <p className="cal-ag__req gz-t-body-s">
            <ThreadBead tone="gold" />
            <span>{t('hotelCalendarRequestedLabel')}</span>
            <span className="gz-t-fig-body-s">
              <Fig>{f.integer(requests)}</Fig>
            </span>
          </p>
        ) : null}
      </div>

      {past ? null : (
        <div className="cal-ag__actions">
          {may && blocked ? (
            <Button variant="secondary" iconStart="lock" disabled={offline} onClick={onOpenDates}>
              {t('hotelCalendarOpenThisDate')}
            </Button>
          ) : null}
          {may && soldOut ? (
            <span className="cal-ag__why">
              <Button variant="secondary" iconStart="lock" disabled>
                {t('hotelCalendarBlock')}
              </Button>
              <InfoButton title={t('hotelCalendarWhyTitle')}>
                <p>{t('hotelCalendarSoldOutReason')}</p>
              </InfoButton>
            </span>
          ) : null}
          {offerable ? (
            <Button variant="tertiary" iconStart="offer" disabled={offline} onClick={() => nav.push('HL-GROW-02', { date })}>
              {t('hotelCalendarOffer')}
            </Button>
          ) : null}
        </div>
      )}
    </section>
  )
}
