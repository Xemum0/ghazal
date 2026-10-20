// The body sections of the venue detail (CL-VENU-01): packages, facilities, policies, location, similar venues (reviews are in Reviews.tsx).
// Each is a khayt section head (serif d2) on the 20 gutter with 32 between sections (direction 3 and 2.5). ADR 0034: no note under a head, no
// sentence in a row; policies are four glyph tiles that open their sheets, the map is a plate with one figure and one word.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { flat } from '@gz/tokens'
import type { Venue, VenueResult } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { Button, EmptyState, FactChip, FaqAccordion, Figures, Icon, MapPreview, SectionHeader, VenueCard, useBi, useDuration, useNav } from '../../../../system'
import { FacilitiesSheet, FacilityTiles } from './Facilities'
import { Mixed } from './Mixed'
import { PackageTile } from './PackageTile'
import { useVenueAddress } from './VenueHeader'
import { driveOrigin, similarVenues, type VenueBrief } from './model'
import type { VenueActions } from './useActions'
import type { VenuePage } from './usePage'
import './sections.css'

// ---------------------------------------------------------------- shared frame of a section

export function Section({ title, onSeeAll, seeAllLabel, children, id }: { title: ReactNode; onSeeAll?: () => void; seeAllLabel?: string; children: ReactNode; id?: string }) {
  return (
    <section className="gzv-sec" data-gz-id={id}>
      <SectionHeader title={title} onSeeAll={onSeeAll} seeAllLabel={seeAllLabel} />
      {children}
    </section>
  )
}

// ---------------------------------------------------------------- packages

export function PackagesSection({ page, actions }: { page: VenuePage; actions: VenueActions }) {
  const t = useT('client-venue')
  const { brief, rows, row, hall, status, state } = page
  // The venue has no voucher price in this frame: every package shows its standard price alone.
  const standardOnly = state === 'no-voucher-price' || state === 'browse-only-contact'
  return (
    <Section title={t('clientVenuePackagesTitle')} id="venue.packages">
      {rows.length === 0 ? (
        <EmptyState
          fill={false}
          illustration="empty-listings"
          title={t('clientVenuePackagesNone')}
          action={{ label: t('clientVenueSeeAllDates'), variant: 'secondary', onPress: () => actions.openCalendar(hall?.id) }}
        />
      ) : (
        <ul className="gzv-pkgs" role="radiogroup" aria-label={t('clientVenuePackagesTitle')}>
          {rows.map(r => (
            <li key={r.pkg.id} className="gzv-pkgs__item">
              <PackageTile
                row={r}
                guests={brief.date && brief.guests !== null && status !== 'unavailable' ? brief.guests : undefined}
                selected={row?.pkg.id === r.pkg.id}
                onSelect={() => page.setPackageId(r.pkg.id)}
                onDetails={() => actions.openPackage(r.pkg.id, hall?.id)}
                unavailable={status === 'unavailable'}
                standardOnly={standardOnly}
                guest={page.flags.guest}
              />
            </li>
          ))}
        </ul>
      )}
    </Section>
  )
}

// ---------------------------------------------------------------- facilities

export function FacilitiesSection({ page }: { page: VenuePage }) {
  const t = useT('client-venue')
  const nav = useNav()
  const { venue, brief } = page
  if (!venue) return null
  const items = venue.amenities.filter(a => !a.audience || a.audience === brief.audience)
  return (
    <Section title={t('clientVenueFacilitiesTitle')} id="venue.facilities">
      <FacilityTiles items={items} onOpen={() => nav.openSheet(<FacilitiesSheet items={items} />, { title: t('clientVenueFacilitiesTitle') })} />
    </Section>
  )
}

// ---------------------------------------------------------------- policies and questions

type PolicyTile = { key: string; icon: IconName; label: string; onPress: () => void }

export function PoliciesSection({ page, actions }: { page: VenuePage; actions: VenueActions }) {
  const t = useT('client-venue')
  const nav = useNav()
  const { width } = useDevice()
  const { venue, hall } = page
  if (!venue || !hall) return null
  const tiles: PolicyTile[] = [
    { key: 'terms', icon: 'document', label: t('clientVenuePolicyTerms'), onPress: () => actions.openPolicies('terms', hall.id) },
    { key: 'rules', icon: 'clipboard', label: t('clientVenuePolicyRules'), onPress: () => actions.openPolicies('rules', hall.id) },
    { key: 'good', icon: 'info', label: t('clientVenuePolicyGood'), onPress: () => actions.openPolicies('good', hall.id) },
  ]
  if (venue.faq.length > 0) {
    tiles.push({ key: 'faq', icon: 'help', label: t('clientVenueFaqTitle'), onPress: () => nav.openSheet(<FaqAccordion items={venue.faq} />, { title: t('clientVenueFaqTitle') }) })
  }
  const edge = policyTileWidth(width)
  return (
    <Section title={t('clientVenuePoliciesTitle')} id="venue.policies">
      <ul className="gzv-pol">
        {tiles.map(tile => (
          <li key={tile.key}>
            <button type="button" className="gz-reset gz-press gzv-pol__tile" style={{ inlineSize: edge }} onClick={tile.onPress} data-gz-id={`policies.${tile.key}`}>
              <Icon name={tile.icon} size="md" tone="primary" />
              <span className="gzv-pol__label gz-t-body-s">{tile.label}</span>
            </button>
          </li>
        ))}
      </ul>
    </Section>
  )
}

/** Two tiles to a row, filling the gutters exactly at any frame width (a formula, Flutter reads the same numbers). */
const policyTileWidth = (frame: number): number => Math.floor((frame - 2 * flat['space.gutter'] - flat['space.3']) / 2)

// ---------------------------------------------------------------- location

export function LocationSection({ venue, brief, onOpenMaps }: { venue: Venue; brief: VenueBrief; onOpenMaps: () => void }) {
  const t = useT('client-venue')
  const bi = useBi()
  const duration = useDuration()
  const address = useVenueAddress(venue)
  const origin = driveOrigin(brief)
  const drive = venue.distances[origin.id]
  return (
    <Section title={t('clientVenueLocationTitle')} id="venue.location">
      <div className="gzv-loc">
        <MapPreview venue={venue} origin={{ id: origin.id, name: bi(origin.name) }} onOpen={onOpenMaps} className="gzv-loc__map" />
        <div className="gzv-loc__row">
          <span className="gzv-loc__addr gz-t-body-s">
            <Figures text={address} />
          </span>
          {drive ? <FactChip icon="car" value={<Mixed text={duration(drive.minutes * 60_000)} />} label={t('clientVenueDriveFrom', { origin: bi(origin.name) })} /> : null}
          <Button variant="tertiary" iconStart="navigate" onClick={onOpenMaps}>
            {t('clientVenueMapsShort')}
          </Button>
        </div>
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------- similar venues

const railItemWidth = (frame: number): number => Math.floor((frame * 0.72) / flat['space.1']) * flat['space.1']

/** The rail itself: used for similar venues and, on a delisted page, for the halls close by. */
export function VenueRail({ rows, title, brief, live, actions }: { rows: readonly VenueResult[]; title: string; brief: VenueBrief; live: boolean; actions: VenueActions }) {
  const t = useT('client-venue')
  const nav = useNav()
  const { width } = useDevice()
  const favourites = usePrototype(s => s.favourites.venue)
  const compare = usePrototype(s => s.compareList)
  if (rows.length === 0) return null

  const card = (row: VenueResult) => {
    const id = row.venue.id
    return (
      <VenueCard
        venue={row.venue}
        price={row.price}
        availability={brief.date ? row.availability : undefined}
        date={brief.date ?? undefined}
        badge={row.badge}
        tags={row.tags}
        guestRange={row.guestRange}
        sponsored={row.sponsored}
        favourite={favourites.includes(id)}
        onFavouriteChange={() => live && usePrototype.getState().toggleFavourite('venue', id)}
        compared={compare.includes(id)}
        onCompareChange={() => {
          if (!live) return
          const s = usePrototype.getState()
          if (s.compareList.includes(id)) s.removeFromCompare(id)
          else if (s.addToCompare(id) === 'full') nav.openSheet('CL-SAVD-03', { params: { newId: id, incoming: id } })
        }}
        onOpen={() => actions.openSimilar(row.venue)}
      />
    )
  }

  const w = railItemWidth(width)
  return (
    <section className="gzv-sec gzv-sec--rail" data-gz-id="venue.similar">
      <div className="gzv-sec__head">
        <SectionHeader title={title} />
      </div>
      <div className="gzv-rail gz-no-scrollbar" role="region" aria-label={t('clientVenueSimilarTitle')}>
        <ul className="gzv-rail__track">
          {rows.map(row => (
            <li key={row.venue.id} className="gzv-rail__item" style={{ inlineSize: w }}>
              {card(row)}
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}

export function SimilarSection({ page, actions }: { page: VenuePage; actions: VenueActions }) {
  const t = useT('client-venue')
  const { venue, brief } = page
  if (!venue) return null
  return <VenueRail rows={similarVenues(venue, brief, 3)} title={t('clientVenueSimilarTitle')} brief={brief} live={page.live} actions={actions} />
}
