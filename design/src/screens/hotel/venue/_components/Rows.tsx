// The rows of "Packages" (HL-VENU-02): a package row (name, audience, the two day-tier prices, guest range, language completeness,
// the active switch). The row body opens the editor; the switch is its own target.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, Price, Switch } from '../../../../system'
import type { PricingBasis } from '../../../../mock'
import { Figures, LangChip, useV } from './bits'
import { useAudienceLabel } from './labels'
import { hasVoucher } from './pricing'
import { packageCompleteness, structureOf, useVenueStore, type PackageModel, type TierModel } from './store'
import { venuePackages } from './venue'
import './rows.css'

type Column = 'standard' | 'voucher'

/** The tier as one column reads it: the voucher column falls back, field by field, to the standard value (the engine's rule). */
const columnOf = (tier: TierModel, column: Column): TierModel =>
  column === 'standard' ? tier : { ...tier, perGuestFils: tier.voucherPerGuestFils ?? tier.perGuestFils, flatFils: tier.voucherFlatFils ?? tier.flatFils }

/** One price as couples read it: the per-guest rate (unit always shown), a flat amount, or both. `size` is the figure weight. */
export function RateText({ basis, tier, column = 'standard', size = 'card' }: { basis: PricingBasis; tier: TierModel; column?: Column; size?: 'card' | 'strong' }) {
  const { t } = useV()
  const col = columnOf(tier, column)
  const flat = col.flatFils
  const pg = col.perGuestFils
  if (basis === 'per_guest') return pg === null ? null : <Price fils={pg} mode="browse" size={size} unit="perGuest" />
  if (basis === 'flat')
    return flat === null ? null : (
      <span className="hv-rate">
        <Price fils={flat} mode="browse" size={size} />
      </span>
    )
  if (flat === null || pg === null) return null
  return (
    <span className="hv-rate">
      <Price fils={flat} mode="browse" size={size} />
      <span className="gz-t-caption hv-rate__unit">+</span>
      <Price fils={pg} mode="browse" size={size} unit="perGuest" />
    </span>
  )
}

/** The two prices of one set of days: the voucher price as the headline, the standard price quiet under it (voucher-model section 6). */
function TierPrices({ basis, tier }: { basis: PricingBasis; tier: TierModel }) {
  const { c } = useV()
  if (!hasVoucher(tier))
    return (
      <span className="hv-pkg__pair">
        <span className="hv-pkg__cell">
          <span className="gz-t-caption hv-pkg__cap">
            <Icon name="coins" size="xs" tone="secondary" />
            <span className="gz-sr-only">{c('commonStandardPrice')}</span>
          </span>
          <RateText basis={basis} tier={tier} size="strong" />
        </span>
      </span>
    )
  return (
    <span className="hv-pkg__pair">
      <span className="hv-pkg__cell">
        <span className="gz-t-caption hv-pkg__cap">
          <Icon name="ticket" size="xs" tone="secondary" />
          <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
        </span>
        <RateText basis={basis} tier={tier} column="voucher" size="strong" />
      </span>
      <span className="hv-pkg__cell hv-pkg__cell--std">
        <span className="gz-t-caption hv-pkg__cap">
          <Icon name="coins" size="xs" tone="secondary" />
          <span className="gz-sr-only">{c('commonStandardPrice')}</span>
        </span>
        <RateText basis={basis} tier={tier} />
      </span>
    </span>
  )
}

/** The two day tiers of a package, each with both prices (one block when the same prices hold every day). */
function PriceLines({ m }: { m: PackageModel }) {
  const { t, c } = useV()
  if (m.bundle) return <BundleLine m={m} />
  const day = m.weekday
  const end = m.weekend
  const same =
    day.on && end.on && day.perGuestFils === end.perGuestFils && day.flatFils === end.flatFils && day.voucherPerGuestFils === end.voucherPerGuestFils && day.voucherFlatFils === end.voucherFlatFils
  const lines: Array<{ key: string; label: string; tier: TierModel }> = same
    ? [{ key: 'all', label: t('hotelVenueAllDays'), tier: day }]
    : [
        ...(day.on ? [{ key: 'weekday', label: c('commonTierWeekday'), tier: day }] : []),
        ...(end.on ? [{ key: 'weekend', label: c('commonTierWeekend'), tier: end }] : []),
      ]
  return (
    <span className="hv-pkg__prices">
      {lines.map(l => (
        <span key={l.key} className="hv-pkg__price">
          <span className="gz-t-label hv-pkg__tier">{l.label}</span>
          <TierPrices basis={m.basis} tier={l.tier} />
        </span>
      ))}
    </span>
  )
}

/** A bundle (the full night) is the sum of two packages: show their two rates side by side, read only. */
function BundleLine({ m }: { m: PackageModel }) {
  const { t } = useV()
  const parts = venuePackages().find(p => p.id === m.id)?.components ?? []
  return (
    <span className="hv-pkg__prices">
      <span className="hv-pkg__price">
        {parts.map((part, i) => (
          <span key={part.packageId} className="hv-rate">
            {i > 0 ? <span className="gz-t-caption hv-rate__unit">+</span> : null}
            <BundlePart id={part.packageId} />
          </span>
        ))}
      </span>
    </span>
  )
}

function BundlePart({ id }: { id: string }) {
  const part = useVenueStore(s => s.packages[id])
  if (!part) return null
  const tier = part.weekend.on ? part.weekend : part.weekday
  return <RateText basis={part.basis} tier={tier} column={hasVoucher(tier) ? 'voucher' : 'standard'} />
}

export type PackageRowProps = {
  m: PackageModel
  name: string
  disabled?: boolean
  onOpen: () => void
  onActive: (active: boolean) => void
  last?: boolean
}

export function PackageRow({ m, name, disabled, onOpen, onActive, last }: PackageRowProps) {
  const { t, c, f } = useV()
  const audience = useAudienceLabel()
  const gaps = packageCompleteness(m)
  const noVoucher = !m.bundle && ![m.weekday, m.weekend].some(tier => tier.on && hasVoucher(tier))
  return (
    <div className="hv-pkg" data-gz="PackageRow" data-last={last || undefined} data-inactive={!m.active || undefined}>
      <button type="button" className="gz-reset hv-pkg__main gz-press" onClick={onOpen} aria-label={t('hotelVenueEditPackage', { name })}>
        <span className="hv-pkg__head">
          <span className="gz-t-title hv-pkg__name">
            <bdi dir="auto">{name}</bdi>
          </span>
        </span>
        <PriceLines m={m} />
        <span className="hv-pkg__meta">
          <Icon name={structureOf(m.basis) === 'per_person' ? 'per-guest' : 'package'} size="sm" tone="secondary" />
          <span className="gz-sr-only">{structureOf(m.basis) === 'per_person' ? c('commonPricingPerPerson') : c('commonPricingPackage')}</span>
          {m.audiences.map(a => (
            <span key={a} className="hv-pkg__aud">
              <Icon name={`section-${a}` as IconName} size="sm" tone="secondary" />
              <span className="gz-sr-only">{audience(a)}</span>
            </span>
          ))}
          {noVoucher ? (
            <span className="hv-pkg__aud">
              <Icon name="ticket" size="sm" tone="danger" />
              <span className="gz-sr-only">{t('hotelVenueNoVoucherTag')}</span>
            </span>
          ) : null}
          <span className="gz-t-caption hv-pkg__guests">
            <Icon name="guests" size="xs" tone="secondary" />
            <Figures text={t('hotelVenueGuestRange', { from: f.integer(m.minGuests), to: f.integer(m.maxGuests) })} />
          </span>
          {m.active ? null : (
            <span className="hv-pkg__aud">
              <Icon name="eye-off" size="sm" tone="secondary" />
              <span className="gz-sr-only">{t('hotelVenueHidden')}</span>
            </span>
          )}
        </span>
        {gaps.ar + gaps.en > 0 ? <LangChip gaps={gaps} /> : null}
      </button>
      <span className="hv-pkg__switch">
        <Switch checked={m.active} disabled={disabled} onChange={onActive} label={t('hotelVenuePkgActiveLabel', { name })} />
      </span>
    </div>
  )
}
