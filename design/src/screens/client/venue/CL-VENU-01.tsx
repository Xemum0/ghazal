// CL-VENU-01 Venue detail. Covers CA-VDET-04..26, CA-BOOK-01, CA-CMP-01, CA-TOOL-01, CA-CHAT-02, CA-AUTH-09.
// The decision screen of the voucher model (ADR 0033): a full-bleed hero with its hairline progress, the serif name with rating, area and two
// badges, the ruled date strip (is it free on our date, the voucher price and the standard price beside it, the saving), the Booking Thread
// before anything has happened, hall and package choice (two prices each), facilities as glyph tiles, policy tiles, reviews, the map and
// similar halls, and a sticky bar that replaces the tab bar with the three paths: Get voucher (or Send request when a ready voucher exists),
// Book visit, Contact. It works fully for a guest (both prices are visible); the account is asked at Get voucher.
// Text diet (ADR 0034, docs/design/02-text-diet.md): facts are glyph and figure, the three paragraphs that survive (voucher terms, venue terms,
// error recovery) sit behind (i) or in their sheet; the message-the-venue card is gone (Contact in the bar is the same chat, CA-CHAT-02).
// Navigates to CL-VENU-02/03/04/05, CL-RVRW-01, CL-BOOK-01, CL-MSGS-02, CL-SAVD-02/03/04, CL-AUTH-01, CL-DISC-02, CL-VCHR-01, CL-VIST-01.
import { useEffect, useRef, useState } from 'react'
import * as mock from '../../../mock'
import type { VenueResult } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useDevice } from '../../../shell/device/context'
import { usePrototype } from '../../../shell/state'
import { Banner, EmptyState, ErrorState, Screen, Skeleton, SkeletonText, TopBar, useBi, useNav, type Rect } from '../../../system'
import { DateStrip, DateStripCompact } from './_components/DateStrip'
import { GalleryViewer } from './_components/GalleryViewer'
import { HallSection } from './_components/HallSection'
import { MapsSheet } from './_components/MapsSheet'
import { FacilitiesSection, LocationSection, PackagesSection, PoliciesSection, SimilarSection, VenueRail } from './_components/Sections'
import { ReviewsSection } from './_components/Reviews'
import { StickyBar } from './_components/StickyBar'
import { ThreadPreview } from './_components/ThreadPreview'
import { VenueHeader } from './_components/VenueHeader'
import { VenueHero } from './_components/VenueHero'
import { useHeroIndex } from './_components/heroIndex'
import { staleStamp, VOUCHER_FEE_FILS } from './_components/model'
import { useVenueActions, usePendingVoucher } from './_components/useActions'
import { useVenuePage } from './_components/usePage'
import { useScrolledPast } from './_components/useScrolledPast'
import { useGallery } from './_components/zones'

export const states = [
  'loading', 'error', 'offline', 'date-held', 'date-unavailable', 'no-date', 'offer-active', 'no-reviews', 'delisted',
  'guest', 'voucher-already-owned', 'no-voucher-price', 'visit-unavailable', 'browse-only-contact',
]

export default function VenueDetail() {
  const t = useT('client-venue')
  const tc = useT('common')
  const tcmp = useT('client-saved-compare')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const device = useDevice()
  const page = useVenuePage()
  const actions = useVenueActions(page.venue, page.live)
  const { venue, hall, brief, flags } = page
  const [heroIndex, setHeroIndex] = useHeroIndex(page.venueId)
  const [viewer, setViewer] = useState<{ origin: Rect | null } | null>(null)
  const gallery = useGallery(venue)
  const stripRef = useRef<HTMLDivElement>(null)
  const pastStrip = useScrolledPast(stripRef, device.safeTop + 56)
  const favourite = usePrototype(s => (venue ? s.favourites.venue.includes(venue.id) : false))
  const compared = usePrototype(s => (venue ? s.compareList.includes(venue.id) : false))
  const compareCount = usePrototype(s => s.compareList.length)
  const signedIn = usePrototype(s => s.auth === 'signedIn')
  const pending = usePendingVoucher(s => s.pending)

  // A guest who tapped Get voucher and signed in comes back to this page: the voucher sheet opens with the exact quote (ADR 0007 D8).
  useEffect(() => {
    if (!page.live || !signedIn || !pending || pending.venueId !== page.venueId) return
    const id = window.setTimeout(() => {
      usePendingVoucher.getState().set(null)
      actions.openVoucher(pending.carry)
    }, 450)
    return () => window.clearTimeout(id)
  }, [page.live, page.venueId, signedIn, pending, actions])

  // ---- a link to a venue that is no longer listed
  if (flags.delisted || !venue || !hall) {
    const near = mock.listVenues({}, { date: brief.date, guests: brief.guests, audience: brief.audience, areaIds: [] }).filter(r => r.venue.channel !== 'external_link').slice(0, 3) as VenueResult[]
    return (
      <Screen top={<TopBar back />}>
        <div className="gzv-page">
          <EmptyState illustration="no-result" title={t('clientVenueDelistedTitle')} fill={false} action={{ label: t('clientVenueDelistedCta'), variant: 'primary', onPress: () => nav.switchTab('discover') }} />
          <VenueRail rows={near} title={t('clientVenueSimilarTitle')} brief={brief} live={page.live} actions={actions} />
        </div>
      </Screen>
    )
  }

  const name = bi(venue.name)
  const topBar = (
    <TopBar
      variant="transparent"
      back
      actions={[
        {
          icon: 'compare',
          label: compared ? tcmp('clientSavedCompareTrayBadge', { count: compareCount }) : tc('commonA11yCompareAdd'),
          onPress: actions.toggleCompare,
          pressed: compared,
          count: compareCount > 0 ? compareCount : undefined,
        },
        { icon: 'share', label: tc('commonActionShare'), onPress: actions.share },
        {
          icon: favourite ? 'heart-fill' : 'heart',
          label: favourite ? tc('commonA11yFavouriteRemove') : tc('commonA11yFavouriteAdd'),
          onPress: actions.toggleFavourite,
          pressed: favourite,
        },
      ]}
    />
  )

  if (flags.error) {
    return (
      <Screen top={<TopBar back title={name} />}>
        <ErrorState kind="load" />
      </Screen>
    )
  }

  const openViewer = (index: number, origin: Rect | null) => {
    setHeroIndex(index)
    setViewer({ origin })
  }

  const pickDate = (date: string) => {
    if (!page.live) return
    usePrototype.getState().setBrief({ date, dateMode: 'exact' })
  }

  const body = flags.loading ? (
    <div className="gzv-page" aria-busy="true" aria-label={tc('commonStateLoading')}>
      <VenueHero images={[]} captions={[]} zones={[]} index={0} onIndexChange={() => undefined} onOpen={() => undefined} label="" loading />
      <VenueHeader venue={venue} rating={page.rating} loading />
      <div className="gzv-block gzv-block--strip">
        <DateStrip brief={brief} status="none" prices={null} row={undefined} onOpenCalendar={() => undefined} onEditGuests={() => undefined} onPickDate={() => undefined} loading />
      </div>
      <div className="gzv-block gzv-skeleton">
        <Skeleton blockSize={96} />
        <SkeletonText lines={3} />
        <Skeleton blockSize={160} />
      </div>
    </div>
  ) : (
    <div className="gzv-page">
      <VenueHero
        images={gallery.images}
        captions={gallery.captions}
        zones={gallery.zoneOf}
        index={heroIndex}
        onIndexChange={setHeroIndex}
        onOpen={openViewer}
        label={t('clientVenueHeroLabel', { venue: name })}
      />
      {flags.offline ? (
        <Banner tone="offline">{t('clientVenueOfflineBanner', { time: f.plain(f.time(staleStamp())) })}</Banner>
      ) : null}
      <VenueHeader venue={venue} rating={page.rating} />

      <div ref={stripRef} className="gzv-block gzv-block--strip">
        <DateStrip
          brief={brief}
          status={page.status}
          prices={page.prices}
          row={page.row}
          guest={flags.guest}
          owned={Boolean(page.owned)}
          windowTitle={page.windowTitle ? bi(page.windowTitle) : null}
          nearest={page.nearest}
          onOpenCalendar={() => actions.openCalendar(hall.id)}
          onEditGuests={actions.editBrief}
          onHow={() => actions.openHow({ brief, hallId: hall.id, sessionId: page.sessionId, packageId: page.row?.pkg.id ?? null })}
          onPickDate={pickDate}
        />
      </div>
      <DateStripCompact date={brief.date} status={page.status} visible={pastStrip} onPress={() => actions.openCalendar(hall.id)} top={device.safeTop + 56} />

      {/* No voucher price (or a saving under the fee): the page says nothing about vouchers. */}
      {page.prices && !page.prices.eligible && !page.owned ? null : (
        <div className="gzv-block">
          <ThreadPreview
            note={t('clientVenueThreadNote', { fee: f.plain(f.money(VOUCHER_FEE_FILS, { mode: 'browse' })), venue: name })}
            replyHours={venue.response?.usuallyRepliesHours}
            owned={page.owned ? { onView: () => nav.push('CL-VCHR-03', { voucherId: page.owned?.id }) } : undefined}
          />
        </div>
      )}

      <div className="gzv-block">
        <HallSection halls={page.halls} hall={hall} onHall={page.setHallId} day={page.day} date={brief.date} sessionId={page.sessionId} onSession={page.setSessionId} />
      </div>

      <PackagesSection page={page} actions={actions} />
      <FacilitiesSection page={page} />
      <PoliciesSection page={page} actions={actions} />
      <ReviewsSection page={page} actions={actions} />
      <LocationSection venue={venue} brief={brief} onOpenMaps={() => nav.openSheet(<MapsSheet />, { title: t('clientVenueMapsTitle') })} />
      <SimilarSection page={page} actions={actions} />
    </div>
  )

  return (
    <>
      <Screen top={topBar} topOverlay bottom={flags.loading ? undefined : <StickyBar page={page} actions={actions} />}>
        {body}
      </Screen>
      {viewer ? (
        <GalleryViewer
          venue={venue}
          index={heroIndex}
          onIndexChange={setHeroIndex}
          origin={viewer.origin}
          onClose={() => setViewer(null)}
        />
      ) : null}
    </>
  )
}

