// HomeShelves (CL-DISC-01): the Brief-aware shelves under the status card, in the order of the inventory:
//   1 Free {date} (lead shelf, hidden without a date)   2 Saved (once something is saved)   3 Featured (one large card)
//   4 Voucher prices (replaces Special offers: the venues where the voucher saves the most)   5 This week (replaces Coming up and
//   Last-minute deals, ADR 0033 D4)   6 For you   7 Trending   8 Nearby (+ "My location" asked in context).
// Every header has "All", which opens Results with the equivalent filters. Rails snap to 72% of the frame (Rail). The shelves are
// pure functions of the Brief (data.ts), so what a card says here is what Results says.
// ADR 0034 (text diet): shelf titles are one or two words and there are no notes under them (the Brief card above says date, area and
// guests once); the drive time of Nearby is a glyph and a figure.
import { useMemo, useState } from 'react'
import * as mock from '../../../../mock'
import type { Venue } from '../../../../mock'
import { Button, Chip, Skeleton, VenueCard, useNav } from '../../../../system'
import { DriveFacts } from './DriveFacts'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { useAskLocation } from './useAskLocation'
import { useVenueCards } from './cards'
import { useDayLabel } from './labels'
import { Rail, railItemWidth } from './Rail'
import { Section } from './Section'
import { briefKey, shelves, type ShelfId } from './data'
import type { Scenario } from './scenario'
import './rail.css'

export type HomeShelvesProps = {
  scenario: Scenario
  /** Open Results with a shelf's "See all". */
  onSeeAll: (shelf: ShelfId) => void
  /** Static frames draw every khayt at once. */
  staticDraw?: boolean
}

export function HomeShelves({ scenario: s, onSeeAll, staticDraw }: HomeShelvesProps) {
  const t = useT('client-discover')
  const nav = useNav()
  const { width } = useDevice()
  const live = useDevice().mode === 'live'
  const card = useVenueCards(s)
  const data = useMemo(() => shelves(s.brief), [briefKey(s.brief)]) // eslint-disable-line react-hooks/exhaustive-deps
  const draw = staticDraw ? 'mount' : 'inview'
  const [located, setLocated] = useState(false)

  const date = s.brief.date
  const dayLabel = useDayLabel()
  const dateText = date ? dayLabel(date) : ''

  const saved = s.favourites.map(id => mock.getVenue(id)).filter((v): v is Venue => Boolean(v))
  const rowFor = (v: Venue) => mock.listVenues({}, s.brief).find(r => r.venue.id === v.id)

  const openSaved = () => live && nav.switchTab('saved')
  const compareSaved = () => {
    if (!live) return
    const store = usePrototype.getState()
    if (store.compareList.length < 2) for (const v of saved.slice(0, 3)) store.addToCompare(v.id)
    nav.push('CL-SAVD-04', { from: 'discover' })
  }

  const ask = useAskLocation()
  const askLocation = async () => {
    if (!live) return
    if (await ask()) setLocated(true)
  }

  const itemWidth = railItemWidth(width)

  return (
    <div className="gzd-shelves" data-gz-id="shelves">
      {date && data.free.length > 0 ? (
        <Section title={t('clientDiscoverFreeTitle', { date: dateText })} draw={draw} onSeeAll={() => onSeeAll('free')} dataId="shelf.free">
          <Rail label={t('clientDiscoverFreeTitle', { date: dateText })}>
            {data.free.slice(0, 6).map(r => (
              <VenueCard key={r.venue.id} {...card(r)} />
            ))}
          </Rail>
        </Section>
      ) : null}

      {saved.length > 0 ? (
        <Section title={t('clientDiscoverShortlistTitle')} draw={draw} onSeeAll={openSaved} dataId="shelf.shortlist">
          <Rail label={t('clientDiscoverShortlistTitle')} itemWidth={itemWidth}>
            {saved.slice(0, 3).map(v => {
              const r = rowFor(v)
              return <VenueCard key={v.id} {...(r ? card(r, { variant: 'compact' }) : { venue: v, variant: 'compact' as const })} />
            })}
          </Rail>
          {saved.length > 1 ? (
            <div className="gzd-section__body">
              <Button variant="secondary" iconStart="compare" onClick={compareSaved}>
                {t('clientDiscoverShortlistCompare')}
              </Button>
            </div>
          ) : null}
        </Section>
      ) : null}

      {data.featured ? (
        <Section title={t('clientDiscoverFeaturedTitle')} draw={draw} onSeeAll={() => onSeeAll('featured')} dataId="shelf.featured">
          <div className="gzd-section__body">
            <VenueCard {...card(data.featured, { variant: 'feature' })} />
          </div>
        </Section>
      ) : null}

      {data.voucher.length > 0 ? (
        <Section title={t('clientDiscoverVoucherTitle')} draw={draw} onSeeAll={() => onSeeAll('voucher')} dataId="shelf.voucher">
          <Rail label={t('clientDiscoverVoucherTitle')}>
            {data.voucher.map(r => (
              <VenueCard key={r.venue.id} {...card(r)} />
            ))}
          </Rail>
        </Section>
      ) : null}

      {data.week.length > 0 ? (
        <Section title={t('clientDiscoverWeekTitle')} draw={draw} onSeeAll={() => onSeeAll('week')} dataId="shelf.week">
          <Rail label={t('clientDiscoverWeekTitle')}>
            {data.week.map(x => (
              <VenueCard key={x.row.venue.id} {...card(x.row, { date: x.date })} />
            ))}
          </Rail>
        </Section>
      ) : null}

      {data.recommended.length > 0 ? (
        <Section title={t('clientDiscoverRecommendedTitle')} draw={draw} onSeeAll={() => onSeeAll('recommended')} dataId="shelf.recommended">
          <Rail label={t('clientDiscoverRecommendedTitle')}>
            {data.recommended.map(r => (
              <VenueCard key={r.venue.id} {...card(r)} />
            ))}
          </Rail>
        </Section>
      ) : null}

      {data.trending.length > 0 ? (
        <Section title={t('clientDiscoverTrendingTitle')} draw={draw} onSeeAll={() => onSeeAll('trending')} dataId="shelf.trending">
          <Rail label={t('clientDiscoverTrendingTitle')}>
            {data.trending.map(r => (
              <VenueCard key={r.venue.id} {...card(r)} />
            ))}
          </Rail>
        </Section>
      ) : null}

      {data.nearby.length > 0 ? (
        <Section title={t('clientDiscoverNearbyTitle')} draw={draw} onSeeAll={() => onSeeAll('nearby')} dataId="shelf.nearby">
          <Rail label={t('clientDiscoverNearbyTitle')}>
            {data.nearby.map(r => (
              <div key={r.venue.id} className="gzd-nearby">
                <VenueCard {...card(r)} />
                {r.distance ? <DriveFacts minutes={r.distance.minutes} km={r.distance.km} /> : null}
              </div>
            ))}
          </Rail>
          {!located ? (
            <div className="gzd-section__body">
              <Chip iconStart="navigate" onClick={askLocation}>
                {t('clientDiscoverMapLocate')}
              </Chip>
            </div>
          ) : null}
        </Section>
      ) : null}
    </div>
  )
}

/** The shelves while they load: one head and a rail of static 4:5 blocks each; nothing shimmers (direction 5, reveal). */
export function ShelvesSkeleton() {
  const { width } = useDevice()
  const w = railItemWidth(width)
  const h = Math.round((w * 5) / 4)
  return (
    <div className="gzd-shelves" aria-busy="true" data-gz-id="shelves.loading">
      {[0, 1].map(i => (
        <section className="gzd-section" key={i} aria-hidden="true">
          <div className="gzd-section__head">
            <Skeleton inlineSize={24} blockSize={1} />
            <Skeleton inlineSize={200} blockSize={32} />
          </div>
          <div className="gzd-rail__skeleton">
            {[0, 1].map(j => (
              <div key={j} className="gzd-rail__skeleton-card" style={{ inlineSize: w }}>
                <Skeleton variant="block" blockSize={h} />
                <Skeleton inlineSize={w - 40} blockSize={24} />
                <Skeleton inlineSize={w - 96} blockSize={20} />
                <Skeleton inlineSize={w - 64} blockSize={20} />
                <Skeleton inlineSize={w - 120} blockSize={20} />
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  )
}
