// PrimaryTile (CL-SERV-01): one of the five Additional services categories. A photograph plate (4:5, or 16:10 for the lead category) with
// the category name in canvas text on the single bottom scrim token, then one line of facts under it (ADR 0034): the providers glyph with
// the count of approved providers (or an hourglass and "Soon" when it has none, never hidden) and, where providers carry a voucher price,
// the ticket glyph alone. No chips, no gold: the photograph is the identity. The whole plate and its label are one press target.
import type { ServiceCategory } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { FactChip, FactRow, Icon, Photo, Skeleton, imageSrc, useBi } from '../../../../system'
import { ICON_OF } from './model'
import './primary-tile.css'

export type PrimaryTileProps = {
  category: ServiceCategory
  /** Approved, active providers of the category. */
  count: number
  /** At least one of them carries a voucher price. */
  voucher: boolean
  /** The lead category of the page runs full width at 16:10. */
  feature?: boolean
  onOpen?: () => void
  loading?: boolean
}

export function PrimaryTile({ category, count, voucher, feature = false, onOpen, loading }: PrimaryTileProps) {
  const t = useT('client-services')
  const f = useFormat()
  const bi = useBi()

  if (loading) {
    return (
      <div className={`gzs-ptile is-loading${feature ? ' gzs-ptile--feature' : ''}`} aria-busy="true" data-gz="PrimaryTile">
        <div className="gzs-ptile__plate" />
        <Skeleton inlineSize={96} blockSize={20} />
      </div>
    )
  }

  const name = bi(category.name)
  return (
    <div className={`gzs-ptile gz-press${feature ? ' gzs-ptile--feature' : ''}`} data-gz="PrimaryTile" data-category={category.id}>
      <div className="gzs-ptile__plate" data-gz-id="plate">
        <Photo src={imageSrc(category.image.file)} alt={bi(category.image.alt)} className="gzs-ptile__photo" />
        <span className="gzs-ptile__scrim" data-gz-id="scrim">
          <Icon name={ICON_OF[category.id]} size="sm" tone="on-dark" />
          <span className="gzs-ptile__name gz-t-title gz-clamp-2">{name}</span>
        </span>
      </div>
      <FactRow className="gzs-ptile__facts" label={name}>
        {count > 0 ? (
          <FactChip icon="team" label={t('clientServicesProviders')} value={f.integer(count)} />
        ) : (
          <FactChip icon="hourglass" label={t('clientServicesListEmptyTitle')} value={t('clientServicesSoon')} tone="muted" />
        )}
        {voucher ? <FactChip icon="ticket" label={t('clientServicesVoucherAvailable')} /> : null}
      </FactRow>
      <button type="button" className="gz-reset gzs-ptile__open" onClick={onOpen} aria-label={t('clientServicesOpenName', { name })} />
    </div>
  )
}
