// CL-VENU-06 Government hall. Covers CA-VDET-04, CA-VDET-07..10, CA-VDET-22, CA-HOME-07, CA-HOME-08, CA-CMP-10, CA-TOOL-17.
// An honest listing of a Governmental Facility (ADR 0033: browse-only): the official fees as two glyph rows, the rules that matter as three
// short rows, availability as "Official app", and a hand-off to the official channel after a short "Leaving Ghazal" confirmation. No voucher,
// no Ghazal request, no visit, no availability claim and no reviews (the "Why no voucher?" row opens a one-line answer in an info sheet), and
// the copy never implies that Ghazal guarantees the booking. "Mark booked" notes the hall for the budget, checklist and countdown only.
// Text diet (ADR 0034): fees are a glyph and a price, the hall-only scope is a badge with its explanation (and the fee caveat) behind (i), the
// payment rule's consequence is behind (i), the capacity is a fact under the name (CA-VDET-08) and the hall's own description is behind the
// (i) "About" of the header (CA-VDET-04). Navigates to CL-SERV-01, CL-VENU-02, CL-DISC-03, CL-WEDD-01.
import { useRef, useState } from 'react'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useDevice } from '../../../shell/device/context'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  ActionBar, Badge, Banner, Button, ErrorState, FaqAccordion, Figures, Icon, IconListRow, InfoButton, InfoSheet, Price, Screen, Skeleton, SkeletonText, TopBar, useBi, useNav, type Rect,
} from '../../../system'
import { GalleryViewer } from './_components/GalleryViewer'
import { MapsSheet } from './_components/MapsSheet'
import { LocationSection, Section } from './_components/Sections'
import { SelfReportSheet } from './_components/SelfReportSheet'
import { VenueHeader } from './_components/VenueHeader'
import { VenueHero } from './_components/VenueHero'
import { useShortDay } from './_components/fmt'
import { useHeroIndex } from './_components/heroIndex'
import { staleStamp, useVenueBrief, useVenueId } from './_components/model'
import { useSelfReports } from './_components/selfReport'
import { useVenueActions } from './_components/useActions'
import { usePageFlags } from './_components/usePage'
import { useGallery } from './_components/zones'
import './CL-VENU-06.css'

export const states = ['loading', 'offline', 'error', 'self-reported', 'no-voucher-explained']

const DEFAULT_GOV = 'V19'

export default function GovernmentHall() {
  const t = useT('client-venue')
  const tc = useT('common')
  const tcmp = useT('client-saved-compare')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const shortDay = useShortDay()
  const { state } = useFrame()
  const device = useDevice()
  const live = device.mode === 'live'
  const flags = usePageFlags()
  const requested = useVenueId()
  const venue = mock.getVenue(requested)?.officialFees ? mock.getVenue(requested) : mock.getVenue(DEFAULT_GOV)
  const brief = useVenueBrief(venue)
  const actions = useVenueActions(venue, live)
  const [heroIndex, setHeroIndex] = useHeroIndex(venue?.id ?? DEFAULT_GOV)
  const [viewer, setViewer] = useState<{ origin: Rect | null } | null>(null)
  const [why, setWhy] = useState(state === 'no-voucher-explained')
  const gallery = useGallery(venue)
  const stored = useSelfReports(s => (venue ? s.reports[venue.id] : undefined))
  const favourite = usePrototype(s => (venue ? s.favourites.venue.includes(venue.id) : false))
  const compared = usePrototype(s => (venue ? s.compareList.includes(venue.id) : false))
  const compareCount = usePrototype(s => s.compareList.length)
  const topRef = useRef<HTMLDivElement>(null)
  if (!venue || !venue.officialFees) return null
  const fees = venue.officialFees
  const name = bi(venue.name)
  // The frame state draws the self-reported hall (Thu 14 Jan 2027, KD 100.000); in the player the couple's own record decides.
  const report = stored ?? (state === 'self-reported' ? { date: mock.weddingProfile.weddingDate ?? '2027-01-14', fils: fees.rent.fils } : undefined)

  const leave = async () => {
    const answer = await nav.openDialog({
      title: t('clientVenueGovLeaveTitle'),
      body: t('clientVenueGovLeaveBody'),
      icon: 'external-link',
      confirmLabel: tc('commonActionContinue'),
      cancelLabel: tc('commonActionCancel'),
    })
    if (answer === 'confirm') nav.toast({ message: t('clientVenueGovLeaveToast'), icon: 'external-link' })
  }
  const openSelfReport = () =>
    nav.openSheet(<SelfReportSheet venueId={venue.id} defaultDate={report?.date ?? mock.weddingProfile.weddingDate ?? '2027-01-14'} defaultFils={report?.fils ?? fees.rent.fils} />, {
      title: t('clientVenueGovSelfTitle'),
    })

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

  const noRating = { average: null, count: 0, categories: null } as const
  const body = flags.loading ? (
    <div className="gzv-page" aria-busy="true" aria-label={tc('commonStateLoading')}>
      <VenueHero images={[]} captions={[]} zones={[]} index={0} onIndexChange={() => undefined} onOpen={() => undefined} label="" loading />
      <VenueHeader venue={venue} rating={noRating} hideRating loading />
      <div className="gzv-block gzv-skeleton">
        <Skeleton blockSize={120} />
        <SkeletonText lines={4} />
      </div>
    </div>
  ) : (
    <div className="gzv-page" ref={topRef}>
      <VenueHero
        images={gallery.images}
        captions={gallery.captions}
        zones={gallery.zoneOf}
        index={heroIndex}
        onIndexChange={setHeroIndex}
        onOpen={(i, origin) => {
          setHeroIndex(i)
          setViewer({ origin })
        }}
        label={t('clientVenueHeroLabel', { venue: name })}
      />
      {flags.offline ? <Banner tone="offline">{t('clientVenueOfflineBanner', { time: f.plain(f.time(staleStamp())) })}</Banner> : null}
      <VenueHeader venue={venue} rating={noRating} hideRating capacity={venue.halls[0]?.capacity} />

      <Section title={t('clientVenueGovFeesTitle')} id="gov.fees">
        <dl className="gzv-fees">
          <div className="gzv-fees__row">
            <dt>
              <Icon name="coins" size="md" tone="secondary" />
              <span className="gz-sr-only">{tc('commonMoneyRentalFee')}</span>
            </dt>
            <dd>
              <Price fils={fees.rent.fils} size="total" />
            </dd>
          </div>
          <div className="gzv-fees__row">
            <dt>
              <Icon name="shield-check" size="md" tone="secondary" />
              <span className="gz-sr-only">{t('clientVenueGovSecurity')}</span>
              {fees.refundableDeposit ? (
                <span className="gzv-fees__badge">
                  <Badge variant="outline" bead={false} icon="undo">
                    {t('clientVenueGovRefundable')}
                  </Badge>
                </span>
              ) : null}
            </dt>
            <dd>
              <Price fils={fees.securityDeposit.fils} size="total" />
            </dd>
          </div>
        </dl>
        <div className="gzv-gov__only" data-gz-id="gov.hall-only">
          <Badge variant="quiet" icon="hall">
            {t('clientVenueGovHallOnlyShort')}
          </Badge>
          <InfoButton title={t('clientVenueGovFeesInfoTitle')} label={t('clientVenueGovFeesInfoTitle')}>
            <p>{t('clientVenueGovHallOnly')}</p>
            <p>{bi(fees.note)}</p>
          </InfoButton>
        </div>
        <Button variant="secondary" iconStart="search" onClick={() => nav.push('CL-SERV-01')} fullWidth>
          {t('clientVenueGovCtaCatering')}
        </Button>
      </Section>

      <Section title={t('clientVenueGovRulesTitle')} id="gov.rules">
        <ul className="gzv-gov__rules">
          <li>
            <IconListRow flush icon="calendar-x" title={t('clientVenueGovRuleNoChange')} />
          </li>
          <li>
            <IconListRow
              flush
              icon="timer"
              title={t('clientVenueGovRulePay')}
              trailing={
                <InfoButton title={t('clientVenueGovRulesTitle')} label={t('clientVenueGovRulePay')}>
                  <p>{t('clientVenueGovRulePayInfo')}</p>
                </InfoButton>
              }
            />
          </li>
          <li>
            <IconListRow flush last icon="card" title={t('clientVenueGovRuleKnet')} />
          </li>
        </ul>
      </Section>

      <div className="gzv-block" data-gz-id="gov.availability">
        <ul className="gzv-gov__rules">
          <li>
            <IconListRow flush icon="calendar" title={t('clientVenueGovAvail')} trailing={<Icon name="external-link" size="sm" tone="secondary" />} chevron={false} onClick={leave} />
          </li>
          <li data-gz-id="gov.self-report">
            {report ? (
              <>
                <IconListRow
                  flush
                  icon="check-circle"
                  title={<Figures text={shortDay(report.date)} />}
                  trailing={<Icon name="edit" size="sm" tone="secondary" />}
                  chevron={false}
                  onClick={openSelfReport}
                />
                <Button variant="tertiary" iconEnd="chevron-right" onClick={() => nav.switchTab('my-wedding')}>
                  {t('clientVenueGovSelfView')}
                </Button>
              </>
            ) : (
              <IconListRow flush icon="calendar-check" title={t('clientVenueGovSelfLink')} chevron onClick={openSelfReport} />
            )}
          </li>
          <li data-gz-id="gov.why">
            <IconListRow flush last icon="ticket" title={t('clientVenueGovWhyTitle')} chevron onClick={() => setWhy(true)} />
          </li>
        </ul>
        <InfoSheet open={why} onClose={() => setWhy(false)} title={t('clientVenueGovWhyTitle')}>
          <p>{t('clientVenueGovWhyBody')}</p>
        </InfoSheet>
      </div>

      <LocationSection venue={venue} brief={brief} onOpenMaps={() => nav.openSheet(<MapsSheet />, { title: t('clientVenueMapsTitle') })} />
      {venue.faq.length > 0 ? (
        <div className="gzv-block" data-gz-id="gov.faq">
          <IconListRow
            flush
            last
            icon="help"
            title={t('clientVenueFaqTitle')}
            chevron
            onClick={() => nav.openSheet(<FaqAccordion items={venue.faq} />, { title: t('clientVenueFaqTitle') })}
          />
        </div>
      ) : null}
      <div className="gzv-block">
        <Button variant="tertiary" iconStart="search" onClick={() => nav.push('CL-DISC-03')}>
          {t('clientVenueGovBrowse')}
        </Button>
      </div>
    </div>
  )

  const hasBar = !flags.loading
  return (
    <>
      <Screen
        top={topBar}
        topOverlay
        bottom={
          hasBar ? (
            <ActionBar
              summaryLabel={
                <>
                  <Icon name="coins" size="sm" tone="secondary" />
                  <span className="gz-sr-only">{tc('commonMoneyRentalFee')}</span>
                </>
              }
              summaryValue={<Price fils={fees.rent.fils} size="display" />}
              action={
                flags.offline
                  ? { label: t('clientVenueCtaOffline'), iconEnd: 'offline', disabled: true }
                  : { label: t('clientVenueGovCtaOfficial'), iconEnd: 'external-link', onPress: leave }
              }
            />
          ) : undefined
        }
      >
        {body}
      </Screen>
      {viewer ? <GalleryViewer venue={venue} index={heroIndex} onIndexChange={setHeroIndex} origin={viewer.origin} onClose={() => setViewer(null)} /> : null}
    </>
  )
}
