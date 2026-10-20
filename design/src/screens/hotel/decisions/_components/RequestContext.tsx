// RequestContext: who and what a decision is about, as a ruled strip (hairline above and below, not a panel; direction 3 "YOUR DATE").
// ADR 0034: a monogram, the name as typed (the one place a name is the headline), the hall as a quiet line, then the facts as glyphs and
// figures with no label: calendar + short date, users + guests, the session glyph (sun, sunset or moon: the glyph is the value) and the
// section symbol (women, men, mixed). The words of each fact are its accessible name. A provider request has no hall, session or section,
// so it shows the date and the quantity only. Used by all four sheets so the frame of every decision reads the same.
import type { ReactNode } from 'react'
import { Avatar, FactChip, FactRow, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import type { Booking } from '../../../../mock'
import { Fx } from './Fx'
import { UserText, timeRangeText } from './local'
import { hallOf, sessionGlyph, subjectOf, useClientName } from './decisions'
import './request-context.css'

export type RequestContextProps = {
  booking: Booking
  /** The date fact (default: the booking's event date). */
  date?: string
  /** Trailing node at inline-end (a status pill, the voucher price). */
  end?: ReactNode
}

const AUDIENCE_ICON = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const
const AUDIENCE_KEY = { women: 'hotelDecisionsFactLadies', men: 'hotelDecisionsFactMen', mixed: 'hotelDecisionsFactMixed' } as const

export function RequestContext({ booking, date, end }: RequestContextProps) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const bi = useBi()
  const client = useClientName(booking)
  const own = hallOf(booking)
  const subject = subjectOf(booking)
  const section = booking.sections[0]
  const guests = section?.guests ?? booking.service?.quantity ?? 0
  const day = f.date(date ?? booking.eventDate, 'short')
  const when = section && own?.session ? timeRangeText(f, booking.eventDate, section.start, section.end) : ''

  return (
    <div className="gzd-ctx" data-gz="RequestContext">
      <div className="gzd-ctx__main">
        <Avatar name={client.full} size="sm" voice="sans" />
        <div className="gzd-ctx__text">
          <UserText role="title" className="gzd-ctx__name gz-clamp-2">
            {client.full}
          </UserText>
          {subject ? <span className="gzd-ctx__hall gz-t-caption">{bi(subject)}</span> : null}
        </div>
        {end ? <div className="gzd-ctx__end">{end}</div> : null}
      </div>
      <FactRow className="gzd-ctx__facts" label={t('hotelDecisionsFactsLabel')}>
        <FactChip icon="calendar" label={t('hotelDecisionsFactDate')} value={<Fx text={day} />} />
        {guests ? <FactChip icon="users-three" label={t('hotelDecisionsFactGuests')} value={f.integer(guests)} /> : null}
        {section ? (
          <span className="gzd-ctx__glyphs">
            {own?.session ? <FactChip icon={sessionGlyph(section.start)} label={`${t('hotelDecisionsFactSession')} ${f.plain(when)}`} /> : null}
            <FactChip icon={AUDIENCE_ICON[section.audience]} label={t(AUDIENCE_KEY[section.audience])} />
          </span>
        ) : null}
      </FactRow>
    </div>
  )
}
