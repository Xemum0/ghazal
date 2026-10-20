// The data side of the compare table: which column is which kind (official channel, unlisted, booked on the date), who wins each objective
// row, and which action each column's button carries. Pure functions over `compareSet()` output; no JSX, no strings.
import type { Brief, CompareColumn, Package } from '../../../../mock'
import { packagesFor } from '../../../../mock'

export type ColumnKind = 'normal' | 'official' | 'unlisted'

export type ColumnInfo = {
  col: CompareColumn
  kind: ColumnKind
  /** Booked on the Brief date: the availability cell says so, the date-priced rows fall back to a dash. */
  booked: boolean
  held: boolean
  /** Has a voucher price for the Brief date (a normal hall, free or held, with a priced voucher column). */
  voucher: boolean
  /** Has a standard price for the Brief date to show. */
  priced: boolean
}

export function describe(columns: readonly CompareColumn[], unlistedId?: string | null): ColumnInfo[] {
  return columns.map(col => {
    const kind: ColumnKind = col.venue.id === unlistedId ? 'unlisted' : col.channel === 'external_link' ? 'official' : 'normal'
    const booked = kind === 'normal' && col.availability === 'unavailable'
    return {
      col,
      kind,
      booked,
      held: kind === 'normal' && col.availability === 'held',
      voucher: kind === 'normal' && !booked && col.voucherPrice !== null,
      priced: kind === 'normal' && !booked && col.price !== null,
    }
  })
}

/** The price a column competes with: its voucher price, else its standard price. */
export const headline = (i: ColumnInfo): number | null => (i.col.voucherPrice ?? i.col.price)?.fils ?? null

export type Winners = { price: Set<string>; fit: Set<string>; nearest: Set<string>; rated: Set<string> }

/** Best-in-row on objective rows only (ADR 0009 D6): lowest voucher price for the Brief (the standard price when no hall has one), best fit, nearest, highest rating with five or more reviews. A held hall has no price to win with. */
export function winners(infos: readonly ColumnInfo[], brief: Brief): Winners {
  const live = infos.filter(i => i.kind === 'normal')
  const priced = live.filter(i => i.priced && !i.held && headline(i) !== null)
  const low = priced.length > 1 ? Math.min(...priced.map(i => headline(i) ?? Infinity)) : null
  const rated = live.filter(i => i.col.rating.average !== null && i.col.rating.count >= 5)
  const top = rated.length > 1 ? Math.max(...rated.map(i => i.col.rating.average ?? 0)) : null
  const fitting = brief.guests ? live.filter(i => i.col.maxGuests >= (brief.guests ?? 0)) : []
  const tight = fitting.length > 1 ? Math.min(...fitting.map(i => i.col.maxGuests)) : null
  const near = live.filter(i => i.col.distance)
  const closest = near.length > 1 ? Math.min(...near.map(i => i.col.distance?.minutes ?? Infinity)) : null
  const ids = (list: ColumnInfo[], pick: (i: ColumnInfo) => boolean) => new Set(list.filter(pick).map(i => i.col.venue.id))
  return {
    price: low === null ? new Set() : ids(priced, i => headline(i) === low),
    fit: tight === null ? new Set() : ids(fitting, i => i.col.maxGuests === tight),
    nearest: closest === null ? new Set() : ids(near, i => i.col.distance?.minutes === closest),
    rated: top === null ? new Set() : ids(rated, i => i.col.rating.average === top),
  }
}

export type BadgeKind = 'lowest' | 'closest' | 'rated'

/** One objective badge per header column: Lowest price, then Closest, then Best rated. */
export function badgeFor(id: string, w: Winners): BadgeKind | undefined {
  return w.price.has(id) ? 'lowest' : w.nearest.has(id) ? 'closest' : w.rated.has(id) ? 'rated' : undefined
}

export type ActionKind = 'voucher' | 'dates' | 'official' | 'view' | 'remove'

/**
 * What the footer button of a column does (ADR 0033; there is no Request or Book here): Get voucher (the hall sells a voucher price and the
 * date is free), See dates (not free on the Brief date: booked or on hold), Official (governmental facility), View (no voucher price: the standard
 * price only, open the hall), or Remove (left the platform).
 */
export function actionFor(info: ColumnInfo, brief: Brief): ActionKind {
  if (info.kind === 'unlisted') return 'remove'
  if (info.kind === 'official') return 'official'
  if (brief.date && info.col.availability && info.col.availability !== 'available') return 'dates'
  return info.col.voucherPrice || info.col.packages.fromVoucher ? 'voucher' : 'view'
}

export function hallSetting(info: ColumnInfo): 'indoor' | 'outdoor' | 'mixed' {
  const set = new Set(info.col.venue.halls.map(h => h.setting))
  return set.size === 1 ? ([...set][0] ?? 'indoor') : 'mixed'
}

export function amenityState(info: ColumnInfo, amenityId: string): 'included' | 'extra' | 'not_offered' | null {
  if (info.kind !== 'normal') return null
  return info.col.venue.amenities.find(a => a.amenityId === amenityId)?.state ?? 'not_offered'
}

export function packageList(info: ColumnInfo): Package[] {
  return packagesFor(info.col.venue.id).filter(p => p.active && !p.components && p.archetype !== 'hall_only')
}
