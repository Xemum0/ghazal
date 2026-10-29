// CL-VENU-04 Package (sheet). Covers CA-VDET-07, CA-VDET-08, CA-VDET-12, CA-VDET-13, CA-VDET-14, CA-BOOK-04, CA-BOOK-14.
// Everything one package includes and what it costs for the Brief, in both columns (ADR 0033): the voucher price and the standard price
// (PriceBlock) with the per-guest rate, the day type of the date and its sibling rate (the weekday against the weekend), the guest limits of
// the hall as facts, what is included and the menu (no extras or add-ons, CA-SVC-19). Guests below the minimum are priced at the minimum
// (a `300+` fact); guests over the hall's capacity meet a warning row and the way out. The primary action is Get voucher (Send request when a
// ready voucher exists); Book visit sits in the body; the heart saves the package to Saved > Packages.
// Text diet (ADR 0034): the sheet's facts are glyph and figure, the inclusions are the venue's own words (four shown, the rest behind a count),
// the sentences of the tier line and the limits are gone. Navigates to CL-BOOK-01, CL-VENU-01, CL-SAVD-01, CL-VCHR-01, CL-VIST-01.
import { useState } from 'react'
import * as mock from '../../../mock'
import type { Audience, Hall, Package } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useDevice } from '../../../shell/device/context'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  Accordion, Banner, Button, ErrorState, FactChip, FactRow, Figures, Icon, IconButton, IconListRow, Price, Skeleton, SkeletonText, StatusPill, useBi, useNav,
} from '../../../system'
import { SheetFrame } from './_components/SheetFrame'
import { SECTION_ICON } from './_components/glyphs'
import { useSep, useShortDay } from './_components/fmt'
import { dayOn, defaultPackage, fittingHalls, hasVisitTimes, packageRows, sectionOf, statusOfDay, useVenueBrief, useVenueId, VOUCHER_FEE_FILS, type QuotePrices } from './_components/model'
import { PriceBlock } from './_components/PriceBlock'
import { StruckMoney } from './_components/Money'
import { useVenueActions } from './_components/useActions'
import { useOwnedVoucher, usePageFlags } from './_components/usePage'
import './CL-VENU-04.css'

export const states = ['loading', 'below-minimum-guests', 'over-capacity', 'unavailable-on-date', 'offline']

type Params = { venueId?: string; packageId?: string; hallId?: string }

const TIER_KEY = {
  weekday: 'clientVenuePkgTierWeekday',
  weekend: 'clientVenuePkgTierWeekend',
  season: 'clientVenuePkgTierSeason',
  holiday: 'clientVenuePkgTierHoliday',
  peak: 'clientVenuePkgTierSeason',
  special_date: 'clientVenuePkgTierSpecialDate',
} as const

const AUDIENCE_KEY = { women: 'clientVenueAudWomen', men: 'clientVenueAudMen', mixed: 'clientVenueAudMixed' } as const
/** Inclusions shown before the count: the sheet is about what is included, but the rest wait behind one chevron. */
const SHOWN_INCLUSIONS = 4

export default function PackageSheet() {
  const t = useT('client-venue')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const live = useDevice().mode === 'live'
  const shortDay = useShortDay()
  const sep = useSep()
  const venueId = useVenueId()
  const venue = mock.getVenue(venueId)
  const brief = useVenueBrief(venue)
  const saved = usePrototype(s => (nav.params.packageId ? s.favourites.package.includes(String(nav.params.packageId)) : false))
  const flags = usePageFlags()
  const actions = useVenueActions(venue, live)
  const owned = useOwnedVoucher(venue?.id, live)
  const [allIncluded, setAllIncluded] = useState(false)

  if (state === 'error') {
    return (
      <SheetFrame title={t('clientVenuePackagesDetails')}>
        <ErrorState kind="load" fill={false} />
      </SheetFrame>
    )
  }
  if (state === 'loading') {
    return (
      <SheetFrame title={t('clientVenuePackagesDetails')}>
        <div className="gzv-pk__skeleton" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <Skeleton inlineSize={200} blockSize={28} />
          <Skeleton blockSize={72} />
          <SkeletonText lines={5} />
        </div>
      </SheetFrame>
    )
  }
  if (!venue) return null

  // The package: the one the sheet was opened for, else the first sold to the Brief audience.
  const halls = fittingHalls(venue, brief.audience, brief.guests)
  const wanted = nav.params.packageId ? mock.getPackage(String(nav.params.packageId)) : undefined
  const hall: Hall | undefined =
    halls.find(h => h.id === nav.params.hallId && (!wanted || wanted.hallIds.includes(h.id))) ?? halls.find(h => !wanted || wanted.hallIds.includes(h.id)) ?? halls[0]
  if (!hall) return null
  const rows = packageRows(venue, hall, brief.audience, brief.date, brief.guests)
  const row = rows.find(r => r.pkg.id === wanted?.id) ?? defaultPackage(rows, brief.audience)
  const pkg: Package | undefined = row?.pkg ?? wanted
  if (!pkg) return null

  const audience: Audience = row?.audience ?? pkg.audiences[0] ?? brief.audience
  const hallSection = sectionOf(hall, audience)
  const maxInHall = Math.min(hall.capacity.max, hallSection?.maxGuests ?? hall.capacity.max, pkg.maxGuests || hall.capacity.max)
  const minGuests = row?.minGuests ?? Math.max(pkg.minGuests, hallSection?.minGuests ?? 0)
  const day = dayOn(venue, hall, brief.date, brief)
  const status = statusOfDay(day, brief.date)
  const unavailable = state === 'unavailable-on-date' || status === 'unavailable'
  const overCapacity = brief.guests !== null && brief.guests > maxInHall
  const price = row?.price ?? null
  const offline = state === 'offline'
  const noVoucher = state === 'no-voucher-price'

  // The day type of the date and its sibling (the weekday against the weekend), in both columns: a glyph, one word and two figures.
  const rateOf = (archetype: Package['archetype'], tier: 'weekday' | 'weekend'): { standard: number; voucher: number | null } | null => {
    const sib = mock.packagesFor(venue.id).find(p => p.archetype === archetype && p.hallIds.includes(hall.id))
    const rule = sib ? mock.rulesFor(sib.id).find(r => r.tier === tier) : undefined
    return rule?.perGuest ? { standard: rule.perGuest.fils, voucher: rule.voucherPerGuest?.fils ?? null } : null
  }
  const money = (fils: number) => f.plain(f.money(fils, { mode: 'browse' }))
  const sibling =
    price && brief.date
      ? price.tier === 'weekend' && pkg.archetype === 'ladies_weekend'
        ? { rates: rateOf('ladies_weekday', 'weekday'), days: [0, 3] as const }
        : price.tier === 'weekday' && pkg.archetype === 'ladies_weekday'
          ? { rates: rateOf('ladies_weekend', 'weekend'), days: [4, 6] as const }
          : null
      : null
  const siblingVoucher = sibling?.rates?.voucher != null && price?.voucherEligible && !noVoucher

  const billed = price?.billed ?? minGuests
  const eligible = Boolean(price?.voucherEligible) && !noVoucher
  const prices: QuotePrices | null = price
    ? { eligible, standard: price.standard.fils, voucher: price.voucher?.fils ?? price.standard.fils, savings: price.savings?.fils ?? 0, billedGuests: billed }
    : null
  const perGuest = pkg.pricingBasis === 'per_guest' || pkg.pricingBasis === 'flat_plus_per_guest'

  const carry = { brief, hallId: hall.id, packageId: pkg.id }
  const after = (go: () => void) => () => {
    if (!live) return
    nav.closeSheet()
    go()
  }
  const seeDates = () => nav.openSheet('CL-VENU-03', { params: { venueId: venue.id, hallId: hall.id } })
  const toggleSave = () => {
    if (!live) return
    const on = usePrototype.getState().toggleFavourite('package', pkg.id)
    nav.toast({ message: on ? tc('commonStateSaved') : t('clientVenueSavedRemoved'), icon: on ? 'heart-fill' : undefined })
  }

  const editGuests = () => nav.openSheet('CL-DISC-02', { params: { focus: 'guests' } })
  const action = offline
    ? { label: t('clientVenueCtaOffline'), disabled: true, onClick: undefined }
    : overCapacity && !unavailable
      ? { label: t('clientVenueCtaChangeGuests'), disabled: false, onClick: editGuests }
      : unavailable
        ? { label: t('clientVenueCtaSeeDates'), disabled: false, onClick: seeDates }
        : !brief.date
          ? { label: t('clientVenueCtaChooseDate'), disabled: false, onClick: seeDates }
          : !eligible
            ? { label: t('clientVenueCtaContact'), disabled: false, onClick: after(actions.contactVenue) }
            : owned
              ? { label: t('clientVenueCtaSendRequest'), disabled: false, onClick: after(() => actions.sendRequest(carry, owned)) }
              : { label: t('clientVenueCtaGetVoucher'), disabled: false, onClick: after(() => actions.getVoucher(carry)) }
  const calendarAction = unavailable || !brief.date || (overCapacity && !unavailable)
  const getsVoucher = !offline && !calendarAction && eligible && !owned
  const visitOpen = state !== 'visit-unavailable' && hasVisitTimes(venue)
  const shownInclusions = allIncluded ? pkg.inclusions : pkg.inclusions.slice(0, SHOWN_INCLUSIONS)
  const hiddenInclusions = pkg.inclusions.length - SHOWN_INCLUSIONS

  const accordion = [
    {
      id: 'menu',
      title: t('clientVenuePkgMenu'),
      content: (
        <div className="gzv-pk__menu gz-t-body-s">
          <p>{bi(pkg.description)}</p>
          {pkg.notes.map((n, i) => (
            <p key={i} className="gzv-pk__note">
              <Icon name="info" size="xs" tone="secondary" />
              <span>{bi(n)}</span>
            </p>
          ))}
        </div>
      ),
    },
  ]

  return (
    <SheetFrame
      title={bi(pkg.name)}
      footer={
        <div className="gzv-pk__foot">
          <IconButton
            icon={saved ? 'heart-fill' : 'heart'}
            label={saved ? t('clientVenuePkgSaved') : t('clientVenuePkgSave')}
            variant="outline"
            disk="lg"
            active={saved}
            onClick={toggleSave}
          />
          {getsVoucher ? (
            <span className="gzv-pk__fee">
              <Icon name="ticket" size="sm" tone="secondary" />
              <span className="gz-sr-only">{tc('commonVoucher')}</span>
              <Price fils={VOUCHER_FEE_FILS} size="display" />
            </span>
          ) : null}
          <div className="gzv-pk__cta">
            <Button variant="primary" fullWidth disabled={action.disabled} onClick={action.onClick} iconEnd={calendarAction && !offline ? 'calendar' : getsVoucher ? 'ticket' : undefined}>
              {action.label}
            </Button>
          </div>
        </div>
      }
    >
      {offline ? <Banner tone="offline" shape="card">{tc('commonStateOffline')}</Banner> : null}

      <section className="gzv-pk__rate" data-gz-id="package.rate">
        <FactRow className="gzv-pk__facts" label={t('clientVenueHallFacts')}>
          <FactChip icon={SECTION_ICON[audience]} label={t(AUDIENCE_KEY[audience])} />
          {pkg.priceStructure === 'package' ? <FactChip icon="package" label={tc('commonPricingPackage')} /> : null}
          <span data-gz-id="package.limits">
            <FactChip
              icon="users-three"
              label={`${tc('commonUnitMinGuests', { count: minGuests })}${sep}${tc('commonUnitUpToGuests', { count: maxInHall })}`}
              value={
                <bdi dir="ltr" className="gz-num">
                  {f.integer(minGuests)}–{f.integer(maxInHall)}
                </bdi>
              }
            />
          </span>
          {row?.belowMinimum && !unavailable && price ? (
            <span data-gz-id="package.below-min">
              <FactChip icon="users-three" tone="accent" value={`${f.integer(minGuests)}+`} label={t('clientVenueEstimateMinimum', { guests: f.plain(f.guests(minGuests)) })} />
            </span>
          ) : null}
        </FactRow>

        {unavailable ? (
          <div className="gzv-pk__alert" data-gz-id="package.unavailable">
            <StatusPill status="unavailable" />
            {brief.date ? <FactChip icon="calendar" value={shortDay(brief.date)} label={t('clientVenuePkgUnavailable', { date: f.plain(f.date(brief.date, 'full')) })} /> : null}
          </div>
        ) : price ? (
          <>
            {brief.date && !overCapacity && prices && !row?.lowestRate ? <PriceBlock prices={prices} owned={Boolean(owned)} size="hero" onHow={undefined} /> : null}
            {perGuest && price.perGuest ? (
              <div className="gzv-pk__rates" data-gz-id="package.rates">
                <span className="gzv-pk__basis">
                  <Icon name="per-guest" size="sm" tone="secondary" />
                  <span className="gz-sr-only">{tc('commonUnitPerGuest')}</span>
                </span>
                {eligible && price.voucherPerGuest ? (
                  <span className="gzv-pk__unit">
                    <Icon name="ticket" size="sm" tone="success" />
                    <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
                    <Price fils={price.voucherPerGuest.fils} size="card" />
                  </span>
                ) : null}
                <span className="gzv-pk__unit gzv-pk__unit--std">
                  <Icon name="offer" size="xs" tone="secondary" />
                  <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
                  {eligible && price.voucherPerGuest ? <StruckMoney fils={price.perGuest.fils} /> : <Price fils={price.perGuest.fils} size="card" />}
                </span>
              </div>
            ) : null}
            {brief.date ? (
              <div className="gzv-pk__tier" data-gz-id="package.tier">
                <FactChip icon="calendar-dots" tone="accent" value={t(TIER_KEY[price.tier])} label={t('clientVenuePkgTierLabel', { date: f.plain(f.date(brief.date, 'full')) })} />
                {sibling?.rates ? (
                  <span className="gzv-pk__sibling gz-t-caption">
                    <Figures text={`${f.weekdayName(sibling.days[0], 'short')}–${f.weekdayName(sibling.days[1], 'short')}`} />
                    {siblingVoucher ? (
                      <>
                        <Icon name="ticket" size="xs" tone="success" />
                        <Figures text={money(sibling.rates.voucher as number)} />
                      </>
                    ) : null}
                    <Icon name="offer" size="xs" tone="secondary" />
                    <span className="gz-strike">
                      <Figures text={money(sibling.rates.standard)} />
                    </span>
                  </span>
                ) : null}
              </div>
            ) : null}
          </>
        ) : null}
        {overCapacity && !unavailable ? (
          <div data-gz-id="package.over-capacity">
            <IconListRow
              flush
              last
              icon="warning"
              title={t('clientVenuePkgOverTitle')}
              trailing={<FactChip icon="users-three" value={f.integer(maxInHall)} label={t('clientVenuePkgOverCap', { hall: bi(hall.name), guests: f.plain(f.guests(maxInHall)) })} />}
            />
          </div>
        ) : null}
      </section>

      {pkg.inclusions.length > 0 ? (
        <section className="gzv-pk__block" aria-labelledby="pk-inc">
          <h3 id="pk-inc" className="gzv-pk__h gz-t-title">
            {t('clientVenuePkgIncludes')}
          </h3>
          <ul className="gzv-pk__list">
            {shownInclusions.map((inc, i) => (
              <li key={i} className="gzv-pk__item gz-t-body-s">
                <Icon name="check" size="sm" tone="success" />
                <span className="gzv-pk__item-text">
                  <Figures text={bi(inc)} />
                </span>
              </li>
            ))}
          </ul>
          {hiddenInclusions > 0 ? (
            <Button variant="tertiary" iconEnd={allIncluded ? 'chevron-up' : 'chevron-down'} aria-label={allIncluded ? tc('commonActionShowLess') : t('clientVenuePkgIncludesAll')} aria-expanded={allIncluded} onClick={() => setAllIncluded(v => !v)} className="gzv-pk__more">
              {allIncluded ? (
                tc('commonActionShowLess')
              ) : (
                <bdi dir="ltr" className="gz-num">
                  +{f.integer(hiddenInclusions)}
                </bdi>
              )}
            </Button>
          ) : null}
        </section>
      ) : null}

      <Accordion items={accordion} />

      {visitOpen ? (
        <Button variant="tertiary" iconStart="calendar-check" onClick={after(actions.bookVisit)} className="gzv-pk__visit">
          {t('clientVenueCtaVisit')}
        </Button>
      ) : null}
    </SheetFrame>
  )
}
