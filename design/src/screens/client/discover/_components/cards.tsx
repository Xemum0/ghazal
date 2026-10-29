// useVenueCards: the venue card as Discover draws it, with its behaviour wired once (CL-DISC-01 rails, CL-DISC-03 list, CL-DISC-05 carousel).
//   whole card -> Venue detail (a governmental facility -> its own detail), heart -> saved, compare toggle -> the tray (a fourth add opens
//   "Replace which one?", ADR 0009 D1). Every client is signed in (ADR 0038), so the card always carries the two prices (ADR 0033 D4).
// There is no Book or Request action on the card any more: the voucher action sits under it (`CardAction`).
// In a static frame nothing is wired: a frame is a picture, the player is the prototype.
import type { VenueResult } from '../../../../mock'
import { Button, useNav, type VenueCardProps } from '../../../../system'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import type { Scenario } from './scenario'
import './card-action.css'

export type CardOptions = {
  /** The date this card speaks about (Available this week cards each carry their own free date). Default: the Brief date. */
  date?: string | null
  variant?: VenueCardProps['variant']
}

/** A venue the voucher can be asked for: not governmental, and the price grammar carries a voucher price. */
export const voucherOffered = (row: VenueResult): boolean => row.venue.voucherEnabled && row.venue.type !== 'governmental' && Boolean(row.price?.voucher)

export function useVenueCards(s: Scenario) {
  const nav = useNav()
  const live = useDevice().mode === 'live'

  const open = (row: VenueResult) => {
    if (!live) return
    nav.push(row.venue.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: row.venue.id, from: 'discover' })
  }

  const toggleFavourite = (id: string) => {
    if (!live) return
    const store = usePrototype.getState()
    store.toggleFavourite('venue', id)
  }

  const toggleCompare = (id: string) => {
    if (!live) return
    const store = usePrototype.getState()
    if (store.compareList.includes(id)) return store.removeFromCompare(id)
    if (store.addToCompare(id) === 'full') nav.openSheet('CL-SAVD-03', { params: { incoming: id } })
  }

  /** The props of a `VenueCard` for one result row. */
  return (row: VenueResult, o: CardOptions = {}): VenueCardProps => {
    const date = o.date === undefined ? s.brief.date : o.date
    return {
      venue: row.venue,
      price: row.price,
      availability: date ? row.availability : undefined,
      date: date ?? undefined,
      badge: row.badge,
      tags: row.tags,
      guestRange: row.guestRange,
      sponsored: row.sponsored,
      variant: o.variant ?? 'card',
      favourite: s.favourites.includes(row.venue.id),
      onFavouriteChange: () => toggleFavourite(row.venue.id),
      compared: s.compare.includes(row.venue.id),
      onCompareChange: () => toggleCompare(row.venue.id),
      onOpen: () => open(row),
    }
  }
}

/**
 * The trailing 44 action under a card whose hall is free (or on hold) on the Brief date (CL-DISC-03): "Get voucher" (ticket glyph) for a
 * voucher-eligible venue (opens the CL-VCHR-01 sheet with the quote), otherwise "View"
 * (the detail). One or two words, verb first (ADR 0034).
 * Nothing under a governmental facility (its card already says where to book) and nothing before a date is chosen.
 */
export function CardAction({ row, scenario: s }: { row: VenueResult; scenario: Scenario }) {
  const t = useT('client-discover')
  const nav = useNav()
  const live = useDevice().mode === 'live'
  const date = s.brief.date
  if (!date || row.venue.channel === 'external_link' || (row.availability !== 'available' && row.availability !== 'held')) return null
  const eligible = voucherOffered(row)

  const getVoucher = () => {
    if (!live) return
    const price = row.price
    usePrototype.getState().startDraft(row.venue.id, {
      hallId: row.availabilityHallId,
      packageId: price && price.mode !== 'rental_fee' ? price.packageId : null,
      eventDate: date,
      guests: s.brief.guests ?? null,
      audience: s.brief.audience ?? null,
    })
    // CL-VCHR-01 is a sheet (the explainer and the KD 2 purchase) opened over Results with the quote.
    const params = {
      venueId: row.venue.id,
      hallId: row.availabilityHallId,
      packageId: price && price.mode !== 'rental_fee' ? price.packageId : null,
      eventDate: date,
      guests: s.brief.guests ?? null,
      from: 'discover',
    }
    nav.openSheet('CL-VCHR-01', { params })
  }
  const view = () => live && nav.push('CL-VENU-01', { venueId: row.venue.id, from: 'discover' })

  return (
    <div className="gzd-cardact" data-gz-id="card.action">
      <Button variant="tertiary" iconEnd={eligible ? 'ticket' : undefined} onClick={eligible ? getVoucher : view}>
        {eligible ? t('clientDiscoverCardGetVoucher') : t('clientDiscoverCardView')}
      </Button>
    </div>
  )
}
