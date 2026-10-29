// Facilities (CL-VENU-01, CA-VDET-05, CA-VDET-11..15, CA-VDET-26): the facilities of a venue as a field of glyph tiles (ADR 0034: a facility is
// its glyph, present = shown, no "Yes" or "Included" words on the page). Included facilities show plain, extra-cost ones carry a small plus; the
// ones that are not offered are not shown. The last tile is the count that opens the full list, where each facility has its name and
// its state (included, extra cost with its price anchor, not offered): the three-state model of ADR 0015 D6 lives in that sheet. Every tile is
// a 44 target that opens the list, so no tap is dead. A facility is a fact of the venue, never a service Ghazal sells (ADR 0038, OQ-R2-09).
import type { VenueAmenity } from '../../../../mock'
import { amenityDefs } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { Icon, IconListRow, useBi } from '../../../../system'
import { useSep } from './fmt'
import { AMENITY_ICON } from './glyphs'
import './facilities.css'

const COLUMNS = 6
const GAP = 8
const GUTTER = 20
/** Tiles on the page before the count tile: two full rows with the count in the last cell. */
const SHOWN = COLUMNS * 2 - 1

const defOf = (id: string) => amenityDefs.find(d => d.id === id)

/** Tile edge so six tiles and five gaps fill the gutters exactly at any frame width (a formula, Flutter reads the same numbers). */
const tileEdge = (frame: number): number => Math.floor((frame - 2 * GUTTER - (COLUMNS - 1) * GAP) / COLUMNS)

export function FacilityTiles({ items, onOpen }: { items: readonly VenueAmenity[]; onOpen: () => void }) {
  const t = useT('client-venue')
  const bi = useBi()
  const sep = useSep()
  const { width } = useDevice()
  const known = items.filter(a => defOf(a.amenityId))
  // One tile per glyph: two facilities that share a drawing (the welcome drinks and the coffee station) would read as a repeat; the full list names both.
  const seen = new Set<string>()
  const offered = known
    .filter(a => a.state !== 'not_offered')
    .filter(a => {
      const glyph = AMENITY_ICON[a.amenityId] ?? 'check-circle'
      if (seen.has(glyph)) return false
      seen.add(glyph)
      return true
    })
  const shown = offered.slice(0, offered.length > SHOWN ? SHOWN : offered.length)
  const rest = known.length - shown.length
  const edge = tileEdge(width)
  const size = { inlineSize: edge, blockSize: edge }
  return (
    <ul className="gzv-fac" data-gz="FacilityTiles" aria-label={t('clientVenueFacilitiesTitle')}>
      {shown.map(a => (
        <li key={a.amenityId}>
          <button type="button" className={`gz-reset gz-press gzv-fac__tile${a.state === 'extra' ? ' is-extra' : ''}`} style={size} onClick={onOpen} data-gz-id={`amenity.${a.amenityId}`} data-state={a.state}>
            <Icon name={AMENITY_ICON[a.amenityId] ?? 'check-circle'} size="md" tone="primary" />
            {a.state === 'extra' ? (
              <span className="gzv-fac__plus" aria-hidden="true">
                <Icon name="plus" size="xs" tone="accent" />
              </span>
            ) : null}
            <span className="gz-sr-only">
              {bi(defOf(a.amenityId)?.label)}
              {sep}
              {a.state === 'extra' ? t('clientVenueFacExtra') : t('clientVenueFacIncluded')}
            </span>
          </button>
        </li>
      ))}
      {rest > 0 ? (
        <li>
          <button type="button" className="gz-reset gz-press gzv-fac__tile gzv-fac__tile--more gz-t-fig-body-s" style={size} onClick={onOpen} data-gz-id="facilities.all">
            <bdi dir="ltr" className="gz-num">
              +{rest}
            </bdi>
            <span className="gz-sr-only">{t('clientVenueFacilitiesAll')}</span>
          </button>
        </li>
      ) : null}
    </ul>
  )
}

/** The full list in a sheet: every facility with its name and its state, the extra ones with the price they start from. */
export function FacilitiesSheet({ items }: { items: readonly VenueAmenity[] }) {
  const t = useT('client-venue')
  const f = useFormat()
  const bi = useBi()
  const order = { included: 0, extra: 1, not_offered: 2 } as const
  const known = items.filter(a => defOf(a.amenityId)).sort((a, b) => order[a.state] - order[b.state])
  return (
    <ul className="gzv-facl" data-gz-id="venue.facilities">
      {known.map((a, i) => {
        const off = a.state === 'not_offered'
        return (
          <li key={a.amenityId}>
            <IconListRow
              icon={AMENITY_ICON[a.amenityId] ?? 'check-circle'}
              title={<span className={off ? 'gzv-facl__off' : undefined}>{bi(defOf(a.amenityId)?.label)}</span>}
              last={i === known.length - 1}
              flush
              trailing={
                <span className="gzv-facl__state">
                  <Icon name={a.state === 'included' ? 'check' : a.state === 'extra' ? 'plus' : 'minus'} size="sm" tone={a.state === 'included' ? 'success' : 'secondary'} />
                  {a.state === 'extra' && a.from ? <span className="gz-t-fig-body-s">{f.plain(f.money(a.from.fils, { mode: 'browse' }))}</span> : null}
                  <span className="gz-sr-only">{a.state === 'included' ? t('clientVenueFacIncluded') : a.state === 'extra' ? t('clientVenueFacExtra') : t('clientVenueFacOff')}</span>
                </span>
              }
            />
          </li>
        )
      })}
    </ul>
  )
}
