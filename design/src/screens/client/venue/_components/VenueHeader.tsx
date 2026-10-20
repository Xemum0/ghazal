// VenueHeader (CL-VENU-01): the wall label under the hero. The khayt (allowed here and on the hero only), the venue name in the display
// face at d3, then facts: the rating, the area as a pin and two quiet badges (luxury level, venue type). ADR 0034: no eyebrow sentence, no
// full address here (it lives under the map), no caption. The label does the work; nothing is laid over the photograph. The venue's own
// description (CA-VDET-04, partner-authored) is the one paragraph and sits behind an (i) "About" beside the badges; a single-room hall
// (the government hall) also shows its capacity as a fact (CA-VDET-08), since that page has no hall section.
import type { IconName } from '@gz/tokens'
import type { Venue } from '../../../../mock'
import { getArea, getGovernorate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Badge, FactChip, Icon, InfoButton, Rating, Skeleton, ThreadRule, useBi } from '../../../../system'
import './venue-header.css'

const TIER_KEY = {
  prestige: 'clientVenueTierPrestige',
  signature: 'clientVenueTierSignature',
  classic: 'clientVenueTierClassic',
  government: 'clientVenueTierGovernment',
} as const

const STYLE_KEY = {
  hotel: 'clientVenueTypeHotel',
  hall: 'clientVenueTypeHall',
  resort: 'clientVenueTypeResort',
  villa: 'clientVenueTypeVilla',
  outdoor: 'clientVenueTypeOutdoor',
  convention: 'clientVenueTypeConvention',
} as const

const STYLE_ICON: Record<Venue['style'], IconName> = {
  hotel: 'hotel',
  hall: 'hall',
  resort: 'beach',
  villa: 'home',
  outdoor: 'garden',
  convention: 'venue',
  government: 'bank',
}

export type VenueHeaderProps = {
  venue: Venue
  rating: Venue['rating']
  /** Government halls carry no reviews: no rating and no "New" either. */
  hideRating?: boolean
  /** A hall of one room (the government hall): its capacity is a fact beside the area, since the page has no hall section. */
  capacity?: { min: number; max: number }
  loading?: boolean
}

/** `Sharq, Capital`: the area and its governorate (the region the search filters by). */
export function useVenueRegion(venue: Venue): string {
  const t = useT('client-venue')
  const bi = useBi()
  const area = getArea(venue.areaId)
  const gov = getGovernorate(venue.governorateId)
  return t('clientVenueRegionLine', { area: area ? bi(area.name) : '', governorate: gov ? bi(gov.name) : '' })
}

/** `Block 4, Gulf Street` (block and street), the Kuwait address pattern; the area is on the map plate. */
export function useVenueAddress(venue: Venue): string {
  const t = useT('client-venue')
  const bi = useBi()
  const street = bi(venue.address.street)
  return venue.address.block ? t('clientVenueAddressLine', { block: venue.address.block, street }) : street
}

export function VenueHeader({ venue, rating, hideRating, capacity, loading }: VenueHeaderProps) {
  const t = useT('client-venue')
  const tc = useT('common')
  const { lang } = useLang()
  const bi = useBi()
  const f = useFormat()
  const region = useVenueRegion(venue)

  if (loading) {
    return (
      <header className="gzv-head" aria-busy="true">
        <Skeleton inlineSize={24} blockSize={1} />
        <Skeleton blockSize={40} />
        <Skeleton inlineSize={200} blockSize={20} />
      </header>
    )
  }

  // A governmental facility's tier and style are one word: say it once.
  const gov = venue.style === 'government'
  return (
    <header className="gzv-head" data-gz="VenueHeader">
      <ThreadRule variant="khayt" draw="mount" />
      <h1 className="gzv-head__name gz-t-d3" lang={lang} data-gz-id="venue.name">
        {bi(venue.name)}
      </h1>
      <div className="gzv-head__facts">
        {hideRating ? null : (
          <span className="gzv-head__rating" data-gz-id="venue.rating">
            {rating.average !== null && rating.count > 0 ? <Rating value={rating.average} count={rating.count} /> : <span className="gz-t-body-s gzv-head__new">{tc('commonLabelNew')}</span>}
          </span>
        )}
        <span className="gzv-head__region gz-t-body-s" data-gz-id="venue.address">
          <Icon name="pin" size="xs" tone="secondary" />
          {region}
        </span>
        {capacity ? (
          <span data-gz-id="venue.capacity">
            <FactChip
              icon="users-three"
              label={t('clientVenueHallCapacity')}
              value={
                <bdi dir="ltr" className="gz-num">
                  {f.integer(capacity.min)}–{f.integer(capacity.max)}
                </bdi>
              }
            />
          </span>
        ) : null}
      </div>
      <div className="gzv-head__badges" data-gz-id="venue.type">
        {gov ? (
          <Badge variant="quiet" icon="bank">
            {t('clientVenueTierGovernment')}
          </Badge>
        ) : (
          <>
            <Badge variant="quiet" icon="crown">
              {t(TIER_KEY[venue.tier])}
            </Badge>
            <Badge variant="quiet" icon={STYLE_ICON[venue.style]}>
              {t(STYLE_KEY[venue.style as keyof typeof STYLE_KEY])}
            </Badge>
          </>
        )}
        {venue.description.en ? (
          <InfoButton title={t('clientVenueAboutTitle')} label={t('clientVenueAboutTitle')} className="gzv-head__about">
            <p data-gz-id="venue.description">{bi(venue.description)}</p>
          </InfoButton>
        ) : null}
      </div>
    </header>
  )
}
