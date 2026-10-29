// PackageRow (CL-SERV-03): one provider package as a choice. A paper panel with a hairline; choosing it puts the ink ring and the gold bead
// on it (a thing chosen, direction 3 Chip). Name and a heart that saves this package alone, the two prices on one unit (voucher price
// first with the saving, the standard price struck beside it; one price when the package has no voucher price), then what is included:
// the chosen package opens its check list, the others carry a checklist glyph and the count (ADR 0034: nothing is said twice). The panel
// is a radio; the heart is its own target.
import type { VendorPackage } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { FactChip, Icon, IconButton, Skeleton, ThreadBead, useBi } from '../../../../system'
import type { ServiceCategoryId } from '../../../../mock'
import { PriceStack } from './PriceStack'
import './package-row.css'

export type PackageRowProps = {
  pkg: VendorPackage
  categoryId: ServiceCategoryId
  chosen?: boolean
  onChoose?: () => void
  /** Voucher price per unit when a voucher is offered for this package at the chosen quantity, else null (standard price alone). */
  voucher?: number | null
  favourite?: boolean
  onFavouriteChange?: (next: boolean) => void
  loading?: boolean
}

export function PackageRow({ pkg, categoryId, chosen = false, onChoose, voucher = null, favourite, onFavouriteChange, loading }: PackageRowProps) {
  const t = useT('client-services')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()

  if (loading) {
    return (
      <div className="gzs-pkg is-loading" aria-busy="true" data-gz="PackageRow">
        <Skeleton inlineSize={200} blockSize={24} />
        <Skeleton inlineSize={120} blockSize={24} />
      </div>
    )
  }

  const name = bi(pkg.name)
  return (
    <div className={`gzs-pkg${chosen ? ' is-chosen' : ''}`} data-gz="PackageRow" data-chosen={chosen || undefined}>
      <button
        type="button"
        role="radio"
        aria-checked={chosen}
        aria-label={chosen ? t('clientServicesProfilePackageChosen', { name }) : t('clientServicesProfilePackageChoose', { name })}
        className="gz-reset gzs-pkg__choose gz-press"
        onClick={onChoose}
      >
        <span className="gzs-pkg__head">
          <span className="gzs-pkg__name gz-t-title">
            {chosen ? <ThreadBead tone="gold" /> : null}
            <span>{name}</span>
          </span>
        </span>
        <span className="gzs-pkg__price" data-gz-id="price">
          <PriceStack standard={pkg.price.fils} voucher={voucher} categoryId={categoryId} variant="package" />
        </span>
        {chosen ? (
          <span className="gzs-pkg__list" data-gz-id="includes">
            {pkg.includes.map((inc, i) => (
              <span key={i} className="gzs-pkg__inc gz-t-body-s">
                <Icon name="check" size="xs" className="gzs-pkg__check" />
                <span>{bi(inc)}</span>
              </span>
            ))}
          </span>
        ) : (
          <span className="gzs-pkg__count" data-gz-id="includes">
            <FactChip icon="checklist" label={t('clientServicesProfileIncludes')} value={f.integer(pkg.includes.length)} tone="muted" size="sm" />
          </span>
        )}
      </button>
      {onFavouriteChange ? (
        <span className="gzs-pkg__fav">
          <IconButton
            variant="plain"
            icon="heart"
            iconActive="heart-fill"
            active={Boolean(favourite)}
            label={c(favourite ? 'commonA11yFavouriteRemove' : 'commonA11yFavouriteAdd')}
            onClick={() => onFavouriteChange(!favourite)}
          />
        </span>
      ) : null}
    </div>
  )
}
