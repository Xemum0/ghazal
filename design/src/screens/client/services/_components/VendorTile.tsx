// VendorTile (CL-SERV-02): a provider in a list, in the venue card's language but lighter. An unframed plate (4:5 photograph of the work,
// radius 12, never a face), a canvas heart disk at inline-end, then the wall label: the name in the display face and facts as glyph +
// figure with no labels (ADR 0034): the rating (or a New mark), the women's-section glyph when the team is female, the area, and the two
// prices pinned to the foot so a row of tiles lines up (voucher price first, the standard price quiet and struck beside it; a provider
// with no voucher price shows one). A paid placement wears the "Sponsored" photo badge, nothing else is labelled. The whole tile is
// one press target; the heart sits above it. States: default, pressed, loading.
import type { Vendor } from '../../../../mock'
import { getArea } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Badge, FactChip, FactRow, IconButton, Photo, Rating, Skeleton, imageSrc, useBi } from '../../../../system'
import { Fx } from './Fx'
import { PriceStack } from './PriceStack'
import { fromVoucherOf, isSponsored } from './model'
import './vendor-tile.css'

export type VendorTileProps = {
  vendor: Vendor
  favourite?: boolean
  onFavouriteChange?: (next: boolean) => void
  onOpen?: () => void
  loading?: boolean
}

export function VendorTile({ vendor, favourite, onFavouriteChange, onOpen, loading }: VendorTileProps) {
  const t = useT('client-services')
  const c = useT('common')
  const { lang } = useLang()
  const bi = useBi()

  if (loading) {
    return (
      <div className="gzs-vtile is-loading" aria-busy="true" data-gz="VendorTile">
        <div className="gzs-vtile__media" />
        <div className="gzs-vtile__label">
          <Skeleton blockSize={28} />
          <Skeleton inlineSize={96} blockSize={20} />
          <Skeleton inlineSize={128} blockSize={24} />
        </div>
      </div>
    )
  }

  const name = bi(vendor.name)
  const area = getArea(vendor.areaId)
  const cover = vendor.portfolio[0]
  return (
    <article className="gzs-vtile gz-press" data-gz="VendorTile" data-vendor={vendor.id}>
      <div className="gzs-vtile__media" data-gz-id="cover">
        {cover ? <Photo src={imageSrc(cover.file)} alt={bi(cover.alt)} className="gzs-vtile__photo" /> : null}
        {isSponsored(vendor) ? (
          <span className="gzs-vtile__sponsored" data-gz-id="sponsored">
            <Badge variant="photo">{c('commonLabelSponsored')}</Badge>
          </span>
        ) : null}
        {onFavouriteChange ? (
          <span className="gzs-vtile__fav">
            <IconButton
              variant="over-image"
              icon="heart"
              iconActive="heart-fill"
              active={Boolean(favourite)}
              label={c(favourite ? 'commonA11yFavouriteRemove' : 'commonA11yFavouriteAdd')}
              onClick={() => onFavouriteChange(!favourite)}
            />
          </span>
        ) : null}
      </div>
      <div className="gzs-vtile__label">
        <h3 className="gzs-vtile__name gz-t-compare-name gz-clamp-2" lang={lang} data-gz-id="name">
          {name}
        </h3>
        <FactRow className="gzs-vtile__facts">
          {vendor.rating ? <Rating value={vendor.rating.average} count={vendor.rating.count} /> : <FactChip icon="sparkle" label={c('commonLabelNew')} value={c('commonLabelNew')} tone="accent" />}
          {vendor.femaleTeamForLadies ? <FactChip icon="section-women" label={t('clientServicesListFemaleTeam')} /> : null}
          {area ? <FactChip icon="pin" label={t('clientServicesArea')} value={<Fx text={bi(area.name)} />} tone="muted" /> : null}
        </FactRow>
        <div className="gzs-vtile__price" data-gz-id="price">
          <PriceStack standard={vendor.from.fils} voucher={fromVoucherOf(vendor)} categoryId={vendor.categoryId} variant="tile" />
        </div>
      </div>
      <button type="button" className="gz-reset gzs-vtile__open" onClick={onOpen} aria-label={name} />
    </article>
  )
}
