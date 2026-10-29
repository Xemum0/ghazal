// PackageTile (CL-VENU-01 packages; ADR 0004, ADR 0033 D4, ADR 0034): one priced package as a choice, figure-led. The serif name and the
// section glyph (ladies, men, mixed), three facts as glyph and figure (per guest or package, the guest minimum, how many inclusions), and
// the price: the total for the party under the voucher column (a ticket) with the standard total struck and
// the saving, and the per-guest rate as a fact. No sentence, no inclusion list (the sheet has them: CL-VENU-04), no "Show all".
// Choosing is ink and a gold bead, never a gold fill (direction 2.3). Flow-local until the system PackageCard has a figure-led variant
// (docs/engineering/requests.md).
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { FactChip, FactRow, Figures, Icon, IconButton, Price, ThreadBead, useBi } from '../../../../system'
import { SECTION_ICON } from './glyphs'
import { QuietMoney, StruckMoney } from './Money'
import type { PackageRow } from './model'
import './package-tile.css'

export type PackageTileProps = {
  row: PackageRow
  /** The guest count the total is for; without it (no date or no guests) the tile shows the lowest per-guest rate. */
  guests?: number
  selected: boolean
  onSelect: () => void
  onDetails: () => void
  /** Not sold on the Brief date: muted, not a target. */
  unavailable?: boolean
  /** The venue has no voucher price in this frame: the standard price alone. */
  standardOnly?: boolean
}

const AUDIENCE_KEY = { women: 'clientVenueAudWomen', men: 'clientVenueAudMen', mixed: 'clientVenueAudMixed' } as const

export function PackageTile({ row, guests, selected, onSelect, onDetails, unavailable = false, standardOnly = false }: PackageTileProps) {
  const f = useFormat()
  const t = useT('client-venue')
  const tc = useT('common')
  const { lang } = useLang()
  const bi = useBi()
  const { pkg, price } = row

  const voucherOn = Boolean(price?.voucherEligible && price.voucher && !standardOnly)
  const basis = pkg.pricingBasis
  const total = price ? (voucherOn ? price.voucher : price.standard) : null
  const rate = price ? (voucherOn ? (price.voucherPerGuest ?? price.perGuest) : price.perGuest) : null
  const flat = price ? (voucherOn ? (price.voucherFlat ?? price.flat) : price.flat) : null
  const showTotal = Boolean(total && guests && basis !== 'flat')
  const perGuestBasis = basis === 'per_guest' || basis === 'flat_plus_per_guest'
  const saving = voucherOn && price?.savings ? f.plain(f.money(price.savings.fils, { mode: 'browse' })) : null
  const minimum = row.minGuests > 0 ? `${f.integer(row.minGuests)}+` : null

  const mark = (
    <span className="gzv-pt__mark">
      <Icon name={voucherOn ? 'ticket' : 'coins'} size="sm" tone={voucherOn ? 'success' : 'secondary'} />
      <span className="gz-sr-only">{voucherOn ? tc('commonVoucherPrice') : tc('commonStandardPrice')}</span>
    </span>
  )

  const money = unavailable ? (
    <span className="gzv-pt__off" data-gz-id="package.unavailable">
      <Icon name="calendar-x" size="sm" tone="secondary" />
      <span className="gz-sr-only">{tc('commonAvailabilityUnavailable')}</span>
    </span>
  ) : price ? (
    <div className="gzv-pt__money" data-gz-id="price">
      {showTotal && total ? (
        <>
          <span className="gzv-pt__line">
            {mark}
            <Price fils={total.fils} size="total" />
            {rate && perGuestBasis ? (
              <span className="gzv-pt__rate">
                <FactChip icon="per-guest" value={<QuietMoney fils={rate.fils} />} label={tc('commonUnitPerGuest')} />
              </span>
            ) : null}
          </span>
          {voucherOn ? (
            <span className="gzv-pt__sub">
              <span className="gzv-pt__was">
                <Icon name="offer" size="xs" tone="secondary" />
                <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
                <StruckMoney fils={price.standard.fils} />
              </span>
              {saving ? (
                <span className="gzv-pt__save gz-t-pill">
                  <Icon name="trend-down" size="xs" mirror={false} />
                  <span className="gz-sr-only">{tc('commonYouSave', { amount: saving })}</span>
                  <Figures text={saving} />
                </span>
              ) : null}
            </span>
          ) : null}
        </>
      ) : basis === 'flat_plus_per_guest' && flat && rate ? (
        <span className="gzv-pt__line">
          {mark}
          <Price fils={flat.fils} size="total" />
          <Icon name="plus" size="xs" tone="secondary" />
          <FactChip icon="per-guest" value={<QuietMoney fils={rate.fils} />} label={tc('commonUnitPerGuest')} />
        </span>
      ) : basis === 'per_guest' && rate ? (
        <>
          <span className="gzv-pt__line">
            {mark}
            <Price fils={rate.fils} size="total" />
            <Icon name="per-guest" size="sm" tone="secondary" />
            <span className="gz-sr-only">{tc('commonUnitPerGuest')}</span>
          </span>
          {voucherOn && price.perGuest ? (
            <span className="gzv-pt__sub">
              <span className="gzv-pt__was">
                <Icon name="offer" size="xs" tone="secondary" />
                <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
                <StruckMoney fils={price.perGuest.fils} />
              </span>
            </span>
          ) : null}
        </>
      ) : flat ? (
        <span className="gzv-pt__line">
          {mark}
          <Price fils={flat.fils} size="total" unit={pkg.archetype === 'hall_only' ? undefined : 'perNight'} was={voucherOn ? price.flat?.fils : undefined} />
        </span>
      ) : null}
    </div>
  ) : null

  return (
    <article data-gz="PackageTile" data-archetype={pkg.archetype} className={`gzv-pt${selected ? ' is-selected' : ''}${unavailable ? ' is-unavailable' : ''}`}>
      <button type="button" role="radio" aria-checked={selected} disabled={unavailable} onClick={onSelect} className="gz-reset gz-press gzv-pt__choose">
        <span className="gzv-pt__head">
          <span className="gzv-pt__bead" aria-hidden="true">
            <ThreadBead tone={selected ? 'gold' : 'hollow'} />
          </span>
          <span className="gzv-pt__name gz-t-d1" lang={lang} data-gz-id="name">
            {bi(pkg.name)}
          </span>
        </span>
        <FactRow className="gzv-pt__facts">
          {pkg.audiences.map(a => (
            <FactChip key={a} icon={SECTION_ICON[a]} label={t(AUDIENCE_KEY[a])} />
          ))}
          {pkg.priceStructure === 'package' ? <FactChip icon="package" label={tc('commonPricingPackage')} /> : null}
          {minimum ? <FactChip icon="users-three" value={minimum} label={t('clientVenuePkgMinGuests')} /> : null}
          {pkg.inclusions.length > 0 ? <FactChip icon="checklist" value={f.integer(pkg.inclusions.length)} label={t('clientVenuePkgIncludes')} /> : null}
        </FactRow>
        {money}
      </button>
      {unavailable ? null : <IconButton icon="chevron-right" iconSize="sm" label={t('clientVenuePackagesDetails')} onClick={onDetails} className="gzv-pt__more" />}
    </article>
  )
}

