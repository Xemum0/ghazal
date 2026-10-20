// DayAgenda: the agenda strip under the month grid for the selected day (ADR 0008 D9: "Month grid with the selected day's agenda strip
// below"). One row per hall (64 minimum): the hall, what it carries as a status pill (booked, on hold with its timer, blocked with its
// reason, open) and the facts that matter (guest, guests, session; the hold deadline; who blocked it). A booked row opens the booking;
// an open row offers Block (3 taps from anywhere, ADR 0008 D9). Pending requests for the date are a count, never identities.
import type { ReactNode } from 'react'
import type { CalendarClaim, Hall, IsoDate, BlockReason } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { Button, ListRow, StatusPill } from '../../core'
import { ThreadBead } from '../../brand'
import { cx } from '../../core/cx'
import { Figures, timeRangeText, UserText, useBi } from '../internal/bits'
import { defineWords, definePlurals, p } from '../internal/copy'
import { markOf } from './model'
import '../calendar.css'

const useW = defineWords({
  open: p('Open', 'متاح'),
  block: p('Block', 'إغلاق'),
  holdUntil: p('Held until {time}', 'محجوز حتى {time}'),
  by: p('by {name}', 'بواسطة {name}'),
  guests: p('{count} guests', '{count} ضيف'),
  offline_booking: p('Booked offline', 'حجز خارج غزل'),
  maintenance: p('Maintenance', 'صيانة'),
  private_event: p('Private event', 'مناسبة خاصة'),
  other: p('Other', 'أخرى'),
  sep: p(' · ', ' · '),
  agenda: p('Agenda for {date}', 'مواعيد {date}'),
  hallLabel: p('{hall}', '{hall}'),
})

const usePl = definePlurals({
  requests: {
    en: { one: '{n} pending request for this date', other: '{n} pending requests for this date' },
    ar: { '=1': 'طلب واحد بانتظار الرد لهذا التاريخ', '=2': 'طلبان بانتظار الرد لهذا التاريخ', few: '{n} طلبات بانتظار الرد لهذا التاريخ', many: '{n} طلبًا بانتظار الرد لهذا التاريخ', other: '{n} طلب بانتظار الرد لهذا التاريخ' },
  },
})

export type DayAgendaProps = {
  date: IsoDate
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  onOpenBooking?: (bookingId: string) => void
  onBlock?: (hallId: string) => void
  className?: string
}

export function DayAgenda({ date, halls, claims, onOpenBooking, onBlock, className }: DayAgendaProps) {
  const f = useFormat()
  const w = useW()
  const pl = usePl()
  const bi = useBi()
  const mine = claims.filter(c => c.date === date)
  const requests = mine.filter(c => c.kind === 'requested').length
  const range = (c: CalendarClaim) => (c.start && c.end ? timeRangeText(f, date, c.start, c.end) : '')
  /** Up to two caption lines per claim: who and how many, then when; the hold deadline; the reason and who blocked it. */
  const lines = (c: CalendarClaim): { first: ReactNode; second?: string } => {
    if (c.kind === 'booking') {
      return {
        first: (
          <>
            {c.clientName ? <UserText role="caption">{c.clientName}</UserText> : null}
            {c.clientName ? ' · ' : ''}
            <Figures text={f.guests(c.guests ?? 0)} />
          </>
        ),
        second: range(c),
      }
    }
    if (c.kind === 'hold') return { first: c.holdUntil ? w('holdUntil', { time: f.dateTime(c.holdUntil) }) : '' }
    const reason = c.blockReason ? w(c.blockReason as BlockReason) : ''
    const note = c.blockNote ? bi(c.blockNote) : ''
    return { first: [reason, note && note !== reason ? note : ''].filter(Boolean).join(w('sep')), second: c.blockedBy ? w('by', { name: c.blockedBy }) : undefined }
  }
  return (
    <section data-gz="DayAgenda" className={cx('gz-agenda', className)} aria-label={w('agenda', { date: f.date(date, 'short') })}>
      <h3 className="gz-agenda__title gz-t-ui-title">
        <Figures text={f.date(date, 'full')} />
      </h3>
      <div className="gz-agenda__rows">
        {halls.map((h, i) => {
          const c = mine.find(x => x.hallId === h.id && markOf(x))
          const last = i === halls.length - 1 && requests === 0
          const sub = c ? lines(c) : null
          return (
            <ListRow
              key={h.id}
              flush
              last={last}
              title={bi(h.name)}
              subtitle={
                sub ? (
                  <span className="gz-agenda__sub">
                    <span>{typeof sub.first === 'string' ? <Figures text={sub.first} /> : sub.first}</span>
                    {sub.second ? (
                      <span>
                        <Figures text={sub.second} />
                      </span>
                    ) : null}
                  </span>
                ) : (
                  w('open')
                )
              }
              chevron={c?.kind === 'booking'}
              onClick={c?.kind === 'booking' && c.bookingId ? () => onOpenBooking?.(c.bookingId as string) : undefined}
              trailing={
                c ? (
                  <StatusPill status={c.kind === 'booking' ? 'confirmed' : c.kind === 'hold' ? 'held' : 'blocked'} audience="hotel" />
                ) : (
                  <Button variant="tertiary" iconStart="lock" onClick={() => onBlock?.(h.id)}>
                    {w('block')}
                  </Button>
                )
              }
            />
          )
        })}
        {requests > 0 ? (
          <p className="gz-agenda__req gz-t-caption">
            <ThreadBead tone="gold" />
            <Figures text={pl('requests', requests)} />
          </p>
        ) : null}
      </div>
    </section>
  )
}
