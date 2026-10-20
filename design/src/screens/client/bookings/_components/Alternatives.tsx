// Alternatives: three halls free on the same date, as compact venue rows (Not accepted and Expired states, CL-BKNG-02). ADR 0034: a picture,
// the name and the price line (glyph facts, already trimmed in the system); the area line is gone. The list is
// the engine's own: venues free on the booking's date for its audience and guest count, in recommended order, minus the venue itself.
// Flow-local row (not the system VenueCard) so every hall has a picture that loads eagerly inside the scroller, or a monogram tile.
import { useMemo } from 'react'
import { CardPriceLine, Monogram, Photo, imageSrc, useBi } from '../../../../system'
import { listVenues, type Booking } from '../../../../mock'
import { guestsOf } from './model'
import './alternatives.css'

export function Alternatives({ booking, onOpen }: { booking: Booking; onOpen: (venueId: string) => void }) {
  const bi = useBi()
  const items = useMemo(() => {
    const audience = booking.sections[0]?.audience ?? 'women'
    const brief = { date: booking.eventDate, guests: guestsOf(booking), audience, areaIds: [] as string[] }
    return listVenues({ availableOnDate: true, audience }, brief)
      .filter(r => r.venue.id !== booking.venueId)
      .slice(0, 3)
  }, [booking])

  return (
    <div className="gzb-alt" data-gz="Alternatives">
      {items.map(r => {
        const cover = r.venue.cover
        return (
          <button key={r.venue.id} type="button" className="gz-reset gzb-alt__row gz-press" onClick={() => onOpen(r.venue.id)}>
            <span className="gzb-alt__thumb">
              {cover ? <Photo src={imageSrc(cover.file)} alt="" className="gzb-alt__photo" sizes="96px" priority /> : <Monogram size="sm" />}
            </span>
            <span className="gzb-alt__body">
              <span className="gzb-alt__name gz-t-d1 gz-clamp-2" dir="auto">
                {bi(r.venue.name)}
              </span>
              {r.price ? <CardPriceLine price={r.price} /> : null}
            </span>
          </button>
        )
      })}
    </div>
  )
}
