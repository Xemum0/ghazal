// PackageChoice: one package as the single decision of step 2. A radio card: ink border and a check on the choice (never gold alone), the serif
// package name, then the two prices of the same quote (ADR 0033 D4) as glyphs and figures (ADR 0034): the voucher total as the number that
// matters (a ticket glyph for a member, a lock for a guest: voucher-model 4.5), the standard total quiet and struck beneath it (offer glyph),
// the saving after the voucher fee (trend-down glyph), and the basis as facts (the rate per guest, the guests). What the package includes is a
// row of glyphs (the venue's own lines are the accessible names and live in the package sheet); an info glyph opens that sheet.
// A package with no voucher price shows its standard total alone and two words. Local to this flow: PriceCompare hides the guest's voucher
// number, which voucher-model 4.5 keeps visible (see requests.md).
import { FactChip, FactRow, Figures, Icon, IconButton, Price, Skeleton, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { inclusionGlyphs } from './glyphs'
import { pricePair, type PricedPackage } from './flow'
import './package.css'

export type PackageChoiceProps = {
  option: PricedPackage
  guests: number
  selected: boolean
  /** Signed out: the voucher price is shown with a lock glyph (voucher-model 4.5); signed in it carries the ticket. */
  guest?: boolean
  /** A voucher is bound to another package: choosing this one opens the voucher quote sheet instead of selecting it. */
  elsewhere?: boolean
  onSelect: () => void
  onDetails: () => void
}

export function PackageChoice({ option, guests, selected, guest, elsewhere, onSelect, onDetails }: PackageChoiceProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { pkg, price } = option
  const pair = pricePair(option)
  const hasVoucher = pair.voucher !== null
  const money = (fils: number) => f.money(fils, { mode: 'browse' })
  const per = hasVoucher ? (price.voucherPerGuest ?? price.perGuest) : price.perGuest
  const flat = hasVoucher ? (price.voucherFlat ?? price.flat) : price.flat
  const glyphs = inclusionGlyphs(pkg.inclusions, bi)
  return (
    <article className={selected ? 'bk-pkg is-selected' : 'bk-pkg'} data-gz="PackageChoice" data-selected={selected || undefined} data-voucher={hasVoucher ? 'yes' : 'no'}>
      <button type="button" role="radio" aria-checked={selected} className="gz-reset gz-press bk-pkg__choose" onClick={onSelect}>
        <span className="bk-pkg__mark" aria-hidden="true">{selected ? <Icon name="check" size="xs" /> : null}</span>
        <span className="bk-pkg__text">
          <span className="bk-pkg__name gz-t-d1">{bi(pkg.name)}</span>
          {hasVoucher ? (
            <>
              <span className="bk-pkg__main">
                <Icon name={guest ? 'lock' : 'ticket'} size="md" tone={guest ? 'secondary' : 'success'} />
                <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
                <Price fils={pair.voucher!} size="total" />
              </span>
              <span className="bk-pkg__sub">
                <span className="bk-pkg__was gz-t-fig-body-s">
                  <Icon name="offer" size="xs" tone="secondary" />
                  <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
                  <span className="gz-strike">
                    <bdi dir="ltr">{money(pair.standard)}</bdi>
                  </span>
                </span>
                <span className="bk-pkg__save gz-t-pill">
                  <Icon name="trend-down" size="xs" mirror={false} />
                  <span className="gz-sr-only">{tc('commonYouSave', { amount: money(pair.net) })}</span>
                  <span aria-hidden="true">
                    <Figures text={money(pair.net)} />
                  </span>
                </span>
              </span>
            </>
          ) : (
            <span className="bk-pkg__main">
              <Price fils={pair.standard} size="total" />
              <span className="bk-pkg__none gz-t-caption">
                <Icon name="ticket" size="xs" tone="secondary" />
                {t('clientBookingPackageNoVoucher')}
              </span>
            </span>
          )}
          <FactRow className="bk-pkg__basis">
            {pkg.pricingBasis === 'flat_plus_per_guest' && flat && per ? (
              <>
                <FactChip icon="package" label={t('clientBookingPackageFlat')} value={money(flat.fils)} size="sm" tone="muted" />
                <FactChip icon="per-guest" label={tc('commonUnitPerGuest')} value={money(per.fils)} size="sm" tone="muted" />
              </>
            ) : per ? (
              <FactChip icon="per-guest" label={tc('commonUnitPerGuest')} value={money(per.fils)} size="sm" tone="muted" />
            ) : (
              <FactChip icon="package" label={t('clientBookingPackageFlat')} size="sm" tone="muted" />
            )}
            <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(Math.max(guests, price.billed))} size="sm" tone="muted" />
          </FactRow>
        </span>
        {selected ? <span className="gz-sr-only">{t('clientBookingPackageSelected')}</span> : null}
        {elsewhere ? <span className="gz-sr-only">{t('clientBookingPackageChangeVoucher')}</span> : null}
      </button>
      <div className="bk-pkg__foot">
        <FactRow label={t('clientBookingPackageIncludes')}>
          {glyphs.map(g => (
            <FactChip key={g.icon} icon={g.icon} label={g.label} size="sm" tone="muted" />
          ))}
        </FactRow>
        <IconButton icon="info" iconSize="sm" label={t('clientBookingPackageDetails')} onClick={onDetails} className="bk-pkg__details" />
      </div>
    </article>
  )
}

export function PackageChoiceSkeleton() {
  return (
    <div className="bk-pkg bk-pkg--loading" aria-busy="true">
      <Skeleton inlineSize={200} blockSize={28} />
      <Skeleton inlineSize={120} blockSize={28} />
      <Skeleton blockSize={20} />
      <Skeleton inlineSize={160} blockSize={20} />
    </div>
  )
}
