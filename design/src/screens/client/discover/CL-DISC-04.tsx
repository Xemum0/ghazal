// CL-DISC-04 Filters (sheet). Covers CA-SRCH-02 to CA-SRCH-14, CA-SRCH-16, CA-SRCH-18 to CA-SRCH-20, CA-FLT-01 to CA-FLT-06.
// One 90% sheet with every filter of the owner's list, grouped by what couples decide first (inventory order): 1 Region (the shared
// governorate chips with the count in the title, and drive time; ADR 0038: never an exact area), 2 Venue type (Private Hall, Governmental Facility,
// Hotel), 3 Reception (ladies, men, mixed), 4 Capacity (a two-handle range, steps of 50, pre-set from the Brief), 5 Pricing (per person,
// packages), 6 Date (the Brief date, and the calendar CL-DISC-06), 7 Voucher price (only voucher venues, and a range on the voucher
// price), 8 Standard price, 9 Setting, 10 Facilities, 11 Rating, level, hotel brand. The Instant booking row is gone (ADR 0033). Groups
// collapse to a glyph row; a group that holds a choice shows it as one value line and a gold bead. The footer is pinned: Clear and the one
// gold CTA with the live count. Edits are a draft: Show N halls applies them and returns to Results with removable chips; dismissing
// discards them. Sort lives in its own small sheet.
// Text diet (ADR 0034, docs/design/02-text-diet.md): every group is a glyph and one or two words; options are glyph chips with one word or a
// figure; nothing writes "Any"; no hint, note or helper sentence. The zero-result state is the CTA disabled and one suggestion to remove.
// States: default, loading-count, zero-results, error, offline, group-collapsed.
import { useMemo, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { Banner, Button, Chip, ChipGroup, ErrorState, FactChip, Figures, GovernorateFilter, Icon, InfoButton, RangeSlider, SheetHeader, VenueTypeChips, briefGovernorates, useNav } from '../../../system'
import { DateFilterSheet } from './_components/DateFilterSheet'
import { FilterGroup } from './_components/FilterGroup'
import { Histogram } from './_components/Histogram'
import {
  CAPACITY, PRICE_BOUNDS, VOUCHER_PRICE_BOUNDS, activeFilterCount, defaultFilters, perGuestFrom, results, type FacilityKey, type Filters,
} from './_components/data'
import {
  ARRANGEMENTS, ARRANGEMENT_ICON, DISTANCES, FACILITIES, FACILITY_ICON, LEVELS, LEVEL_ICON, RATINGS, SETTINGS, SETTING_ICON, clearedFilters, useAppliedChips, useDayLabel, useLabels,
} from './_components/labels'
import { useDiscover } from './_components/state'
import { useAskLocation } from './_components/useAskLocation'
import { useSheetFill } from './_components/useSheetFill'
import { useScenario } from './_components/scenario'
import './CL-DISC-04.css'

export const states = ['loading-count', 'zero-results', 'error', 'offline', 'group-collapsed']

type GroupId = 'region' | 'type' | 'arrangement' | 'capacity' | 'structure' | 'date' | 'voucher' | 'price' | 'setting' | 'facilities' | 'rating' | 'level' | 'brand'
const OPEN_BY_DEFAULT: GroupId[] = ['region']
const BRANDS = ['Aurelia', 'Madar', 'Lumi', 'Rawnaq']
const GROUP_ICON: Record<GroupId, IconName> = {
  region: 'pin',
  type: 'venue',
  arrangement: 'section-mixed',
  capacity: 'users-three',
  structure: 'package',
  date: 'calendar',
  voucher: 'ticket',
  price: 'coins',
  setting: 'tent',
  facilities: 'checklist',
  rating: 'star',
  level: 'crown',
  brand: 'hotel',
}

/** A chip label with its glyph in front (the glyph says what the option is, the word is one word). */
const glyphLabel = (icon: IconName, label: ReactNode) => (
  <span className="gzd-fil__chiplabel">
    <Icon name={icon} size="xs" />
    {label}
  </span>
)

export default function Filters() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { lang } = useLang()
  const L = useLabels()
  const dayLabel = useDayLabel()
  const s = useScenario(state)
  const fill = useSheetFill()
  const brief = s.brief
  const live = s.live

  const initial = useMemo<Filters>(() => {
    if (live) return useDiscover.getState().filters
    const base = defaultFilters(brief)
    if (state === 'zero-results') return { ...base, capacity: [1300, 1500] }
    if (state === 'group-collapsed') return { ...base, types: ['hotel'], arrangement: 'women', settings: ['indoor'], facilities: ['parking', 'valet'], minRating: 4, levels: ['prestige'], voucherOnly: true }
    return base
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  const [draft, setDraft] = useState<Filters>(initial)
  const [open, setOpen] = useState<Set<GroupId>>(() => new Set(state === 'group-collapsed' ? [] : OPEN_BY_DEFAULT))
  const toggle = (id: GroupId) => setOpen(prev => (prev.has(id) ? new Set([...prev].filter(x => x !== id)) : new Set([...prev, id])))
  const patch = (p: Partial<Filters>) => setDraft(d => ({ ...d, ...p }))

  const loading = state === 'loading-count'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online

  // ---- the live count: the same function Results runs, so the footer and the list can never disagree
  const rows = useMemo(() => results(brief, draft), [brief, draft])
  const count = rows.length
  const chips = useAppliedChips(draft, brief)
  const relax = useMemo(() => {
    if (count > 0) return null
    for (const chip of chips) {
      if (chip.id === 'available') continue
      if (results(brief, chip.remove(draft)).length > 0) return chip
    }
    return null
  }, [count, chips, brief, draft])

  const changed = activeFilterCount(draft, brief) - (draft.available && brief.date ? 1 : 0) > 0 || draft.available !== defaultFilters(brief).available

  // ---- option data from the fixtures
  /** The governorates lit: the filter's own choice, else the Brief's (so they can be switched off here). */
  const selectedGovernorates = draft.governorateIds ?? briefGovernorates(brief)
  const audience = brief.audience ?? 'women'
  const standardRates = useMemo(() => mock.venues.map(v => perGuestFrom(v, audience)).filter((n): n is number => n !== null), [audience])
  const voucherRates = useMemo(() => mock.venues.map(v => perGuestFrom(v, audience, 'voucher')).filter((n): n is number => n !== null), [audience])
  const voucherVenues = useMemo(() => mock.venues.filter(v => v.voucherEnabled).length, [])
  const guestFloor = brief.guests ? Math.max(CAPACITY.min, Math.floor(brief.guests / CAPACITY.step) * CAPACITY.step) : CAPACITY.min
  const capacityValue: [number, number] = draft.capacity ?? [guestFloor, CAPACITY.max]

  const ask = useAskLocation()
  const askLocation = async (minutes: number | null) => {
    if (minutes === null) return patch({ withinMinutes: null })
    if (live && !(await ask())) return
    patch({ withinMinutes: minutes })
  }

  const apply = () => {
    if (live) useDiscover.getState().replaceFilters(draft)
    nav.closeSheet()
  }
  const clear = () => setDraft(clearedFilters(brief))
  /** The date calendar is a sheet over this sheet; it hands the chosen day or range back to the draft. */
  const openDates = () => live && nav.openSheet(<DateFilterSheet onApply={patch} />)

  // ---- what a group says once it holds a choice (nothing is written for "any")
  const sep = lang === 'ar' ? '، ' : ', '
  const money = (kd: number) => f.money(Math.round(kd * 1000), { mode: 'browse' })
  const dateSummary = draft.dates
    ? draft.dates.from === draft.dates.to
      ? dayLabel(draft.dates.from)
      : `${dayLabel(draft.dates.from)} – ${dayLabel(draft.dates.to)}`
    : brief.date && draft.available
      ? dayLabel(brief.date)
      : ''
  const regionSummary = [
    draft.withinMinutes !== null ? L.within(draft.withinMinutes) : '',
    draft.governorateIds !== null ? (draft.governorateIds.length ? L.governorates(draft.governorateIds) : t('clientDiscoverChipGovernoratesAll')) : '',
  ]
    .filter(Boolean)
    .join(sep)
  const summary: Record<GroupId, string> = {
    region: regionSummary,
    type: draft.types.length ? f.list(draft.types.map(L.venueType), 'and') : '',
    arrangement: draft.arrangement ? L.arrangement(draft.arrangement) : '',
    capacity: draft.capacity ? L.capacity(draft.capacity[0], draft.capacity[1]) : '',
    structure: draft.structure ? L.structure(draft.structure) : '',
    date: dateSummary,
    voucher: [draft.voucherOnly ? t('clientDiscoverChipVoucher') : '', draft.voucherPrice ? L.voucherRange(draft.voucherPrice[0], draft.voucherPrice[1]) : ''].filter(Boolean).join(sep),
    price: draft.price ? L.priceRange(draft.price[0], draft.price[1]) : '',
    setting: draft.settings.length ? f.list(draft.settings.map(L.setting), 'and') : '',
    facilities: draft.facilities.length ? f.list(draft.facilities.map(L.facility), 'and') : '',
    rating: draft.minRating !== null ? t('clientDiscoverChipRating', { rating: L.rating(draft.minRating) }) : '',
    level: draft.levels.length ? f.list(draft.levels.map(L.level), 'and') : '',
    brand: draft.brands.length ? f.list(draft.brands.map(L.brand), 'and') : '',
  }
  const activeOf: Record<GroupId, boolean> = {
    region: draft.governorateIds !== null || draft.withinMinutes !== null,
    type: draft.types.length > 0,
    arrangement: draft.arrangement !== null,
    capacity: draft.capacity !== null,
    structure: draft.structure !== null,
    date: draft.dates !== null || (draft.available && Boolean(brief.date)),
    voucher: draft.voucherOnly || draft.voucherPrice !== null,
    price: draft.price !== null,
    setting: draft.settings.length > 0,
    facilities: draft.facilities.length > 0,
    rating: draft.minRating !== null,
    level: draft.levels.length > 0,
    brand: draft.brands.length > 0,
  }
  const titleOf: Record<GroupId, string> = {
    region: t('clientDiscoverFiltersGroupRegion', { count: selectedGovernorates.length }),
    type: t('clientDiscoverFiltersGroupType'),
    arrangement: t('clientDiscoverFiltersGroupArrangement'),
    capacity: t('clientDiscoverFiltersGroupCapacity'),
    structure: t('clientDiscoverFiltersGroupStructure'),
    date: t('clientDiscoverFiltersGroupDate'),
    voucher: t('clientDiscoverFiltersGroupVoucher'),
    price: t('clientDiscoverFiltersGroupPrice'),
    setting: t('clientDiscoverFiltersGroupSetting'),
    facilities: t('clientDiscoverFiltersGroupFacilities'),
    rating: t('clientDiscoverFiltersGroupRating'),
    level: t('clientDiscoverFiltersGroupLevel'),
    brand: t('clientDiscoverFiltersGroupBrand'),
  }
  const group = (id: GroupId, body: ReactNode) => (
    <FilterGroup
      key={id}
      title={titleOf[id]}
      icon={GROUP_ICON[id]}
      summary={summary[id] ? <Figures text={summary[id]} /> : undefined}
      open={open.has(id)}
      onToggle={() => toggle(id)}
      active={activeOf[id]}
      dataId={`group.${id}`}
    >
      {body}
    </FilterGroup>
  )

  const price = draft.price ?? PRICE_BOUNDS
  const voucherPrice = draft.voucherPrice ?? VOUCHER_PRICE_BOUNDS
  const zero = count === 0 && !loading && !errored
  const cta = loading ? t('clientDiscoverCtaShow') : zero ? t('clientDiscoverFiltersCtaNone') : t('clientDiscoverFiltersCta', { count })
  const moneySlider = (lo: number, hi: number) => ({
    formatValue: (n: number) => <Figures text={money(n)} />,
    valueText: (n: number) => f.money(Math.round(n * 1000), { mode: 'browse' }),
    min: lo,
    max: hi,
  })

  return (
    <div className="gzd-fil" data-gz-id="filters" style={{ blockSize: fill }}>
      <SheetHeader title={t('clientDiscoverFiltersTitle')} onClose={() => nav.closeSheet()} />
      {offline ? (
        <div className="gzd-fil__banner">
          <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner>
        </div>
      ) : null}

      <div className="gzd-fil__scroll gz-no-scrollbar">
        {errored ? (
          <ErrorState kind="load" fill={false} onRetry={() => undefined} />
        ) : (
          <div className="gzd-fil__groups">
            {group(
              'region',
              <>
                <GovernorateFilter label={t('clientDiscoverChipRegion')} value={selectedGovernorates} onChange={ids => patch({ governorateIds: ids })} />
                <ChipGroup<number>
                  selection="single"
                  deselectable
                  label={t('clientDiscoverA11yDrive')}
                  value={draft.withinMinutes}
                  onChange={v => askLocation(v)}
                  options={DISTANCES.map(m => ({ value: m, label: glyphLabel('car', L.within(m)) }))}
                />
              </>,
            )}

            {group(
              'type',
              <div className="gzd-fil__row">
                <VenueTypeChips value={draft.types} onChange={types => patch({ types })} />
                <InfoButton title={c('commonVenueTypeGovernmental')}>
                  {t('clientDiscoverResultsGovernmentNote')}
                </InfoButton>
              </div>,
            )}

            {group(
              'arrangement',
              <ChipGroup
                label={titleOf.arrangement}
                selection="single"
                deselectable
                value={draft.arrangement}
                onChange={v => patch({ arrangement: v })}
                options={ARRANGEMENTS.map(a => ({ value: a, label: glyphLabel(ARRANGEMENT_ICON[a], L.arrangement(a)) }))}
              />,
            )}

            {group(
              'capacity',
              <RangeSlider
                min={CAPACITY.min}
                max={CAPACITY.max}
                step={CAPACITY.step}
                value={capacityValue}
                label={titleOf.capacity}
                captions={null}
                formatValue={n => <bdi dir="ltr">{f.integer(n)}</bdi>}
                valueText={n => f.guests(n)}
                onChange={([lo, hi]) => patch({ capacity: lo === CAPACITY.min && hi === CAPACITY.max ? null : [lo, hi] })}
              />,
            )}

            {group(
              'structure',
              <ChipGroup
                label={titleOf.structure}
                selection="single"
                deselectable
                value={draft.structure}
                onChange={v => patch({ structure: v })}
                options={[
                  { value: 'per_person', label: glyphLabel('per-guest', L.structure('per_person')) },
                  { value: 'package', label: glyphLabel('package', L.structure('package')) },
                ]}
              />,
            )}

            {group(
              'date',
              <div className="gzd-fil__row">
                <Chip
                  iconStart="calendar-check"
                  selected={Boolean(brief.date) && draft.available}
                  disabled={!brief.date}
                  onClick={() => patch({ available: !draft.available })}
                >
                  {brief.date ? <Figures text={dayLabel(brief.date)} /> : t('clientDiscoverChipDate')}
                </Chip>
                <Chip iconStart="calendar" menu onClick={openDates}>
                  {t('clientDiscoverFiltersDateOpen')}
                </Chip>
              </div>,
            )}

            {group(
              'voucher',
              <div className="gzd-fil__price">
                <div className="gzd-fil__row">
                  <Chip iconStart="ticket" selected={draft.voucherOnly} onClick={() => patch({ voucherOnly: !draft.voucherOnly })}>
                    {t('clientDiscoverFiltersVoucherTitle')}
                  </Chip>
                  <FactChip icon="venue" label={t('clientDiscoverFiltersVoucherCount')} value={f.integer(voucherVenues)} tone="muted" />
                </div>
                <Histogram values={voucherRates} min={VOUCHER_PRICE_BOUNDS[0]} max={VOUCHER_PRICE_BOUNDS[1]} range={voucherPrice} />
                <RangeSlider
                  {...moneySlider(VOUCHER_PRICE_BOUNDS[0], VOUCHER_PRICE_BOUNDS[1])}
                  step={1}
                  value={voucherPrice}
                  label={titleOf.voucher}
                  captions={null}
                  onChange={([lo, hi]) => patch({ voucherPrice: lo === VOUCHER_PRICE_BOUNDS[0] && hi === VOUCHER_PRICE_BOUNDS[1] ? null : [lo, hi] })}
                />
              </div>,
            )}

            {group(
              'price',
              <div className="gzd-fil__price">
                <Histogram values={standardRates} min={PRICE_BOUNDS[0]} max={PRICE_BOUNDS[1]} range={price} />
                <RangeSlider
                  {...moneySlider(PRICE_BOUNDS[0], PRICE_BOUNDS[1])}
                  step={1}
                  value={price}
                  label={titleOf.price}
                  captions={null}
                  onChange={([lo, hi]) => patch({ price: lo === PRICE_BOUNDS[0] && hi === PRICE_BOUNDS[1] ? null : [lo, hi] })}
                />
              </div>,
            )}

            {group(
              'setting',
              <ChipGroup
                label={titleOf.setting}
                selection="multiple"
                value={draft.settings}
                onChange={v => patch({ settings: v })}
                options={SETTINGS.map(x => ({ value: x, label: glyphLabel(SETTING_ICON[x], L.setting(x)) }))}
              />,
            )}

            {group(
              'facilities',
              <ChipGroup
                label={titleOf.facilities}
                selection="multiple"
                value={draft.facilities}
                onChange={v => patch({ facilities: v as FacilityKey[] })}
                options={FACILITIES.map(x => ({ value: x, label: glyphLabel(FACILITY_ICON[x], L.facility(x)) }))}
              />,
            )}

            {group(
              'rating',
              <ChipGroup
                label={titleOf.rating}
                selection="single"
                deselectable
                value={draft.minRating}
                onChange={v => patch({ minRating: v })}
                options={RATINGS.map(r => ({ value: r, label: glyphLabel('star', <Figures text={t('clientDiscoverChipRating', { rating: L.rating(r) })} />) }))}
              />,
            )}

            {group(
              'level',
              <ChipGroup
                label={titleOf.level}
                selection="multiple"
                value={draft.levels}
                onChange={v => patch({ levels: v })}
                options={LEVELS.map(x => ({ value: x, label: glyphLabel(LEVEL_ICON[x], L.level(x)) }))}
              />,
            )}

            {group(
              'brand',
              <ChipGroup
                label={titleOf.brand}
                selection="multiple"
                value={draft.brands}
                onChange={v => patch({ brands: v })}
                options={BRANDS.map(b => ({ value: b, label: L.brand(b) }))}
              />,
            )}
          </div>
        )}
      </div>

      <div className="gzd-fil__foot" data-gz-id="filters.foot">
        {zero && relax ? (
          <div className="gzd-fil__relax">
            <Button variant="tertiary" iconStart={relax.icon ?? 'close'} onClick={() => setDraft(relax.remove(draft))}>
              {t('clientDiscoverResultsNoneRelax', { filter: relax.label })}
            </Button>
          </div>
        ) : null}
        <div className="gzd-fil__actions">
          <Button variant="tertiary" onClick={clear} disabled={!changed}>
            {t('clientDiscoverFiltersClear')}
          </Button>
          <Button variant="primary" onClick={apply} disabled={zero || errored} loading={loading} className="gzd-fil__cta">
            <Figures text={cta} />
          </Button>
        </div>
      </div>
    </div>
  )
}
