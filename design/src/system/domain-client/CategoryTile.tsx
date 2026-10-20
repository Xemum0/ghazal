// CategoryTile (Home quick categories, ADR 0018 B12; ServiceTile in ServiceTile.tsx is the services twin): a 4:5 photograph, radius 12,
// with a single-purpose bottom scrim and the category name in canvas text; never a coloured chip, never an icon grid. An optional count
// ("12 halls") sits under the name. `label="under"` moves the name below the plate (the wall-label form) where a scrim would be too much.
//
// states  default, pressed, focus-visible, selected (ink ring + check), no photo (branded tint), loading
import { Icon, Monogram, Skeleton } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import './tiles.css'

export type CategoryTileProps = {
  /** The category name, already in the current language. */
  label: string
  /** `ImageRef.file`; null shows the branded empty frame. */
  image: string | null
  alt?: string
  /** A small caption under the name ("12 halls"), already formatted. */
  caption?: string
  labelPlacement?: 'over' | 'under'
  selected?: boolean
  onOpen?: () => void
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

export function CategoryTile({ label, image, alt = '', caption, labelPlacement = 'over', selected = false, onOpen, loading, previewState, className }: CategoryTileProps) {
  if (loading) {
    return (
      <div className={cx('gz-ctile is-loading', className)} data-gz="CategoryTile" aria-busy="true">
        <div className="gz-ctile__plate gz-ctile__plate--skeleton" />
        {labelPlacement === 'under' ? <Skeleton inlineSize={96} blockSize={20} /> : null}
      </div>
    )
  }
  const under = labelPlacement === 'under'
  return (
    <div data-gz="CategoryTile" data-placement={labelPlacement} className={cx('gz-ctile gz-press', selected && 'is-selected', previewState === 'pressed' && 'is-pressed', className)}>
      <div className="gz-ctile__plate" data-gz-id="plate">
        {image ? (
          <Photo src={imageSrc(image)} alt={alt} className="gz-ctile__photo" />
        ) : (
          <span className="gz-ctile__empty">
            <Monogram size="sm" />
          </span>
        )}
        {under ? null : (
          <span className="gz-ctile__scrim" data-gz-id="scrim">
            <span className="gz-ctile__name gz-t-title">{label}</span>
            {caption ? <span className="gz-ctile__cap gz-t-caption">{caption}</span> : null}
          </span>
        )}
        {selected ? (
          <span className="gz-ctile__check" aria-hidden="true">
            <Icon name="check" size="xs" />
          </span>
        ) : null}
      </div>
      {under ? (
        <span className="gz-ctile__under">
          <span className="gz-ctile__name gz-ctile__name--under gz-t-title">{label}</span>
          {caption ? <span className="gz-t-caption">{caption}</span> : null}
        </span>
      ) : null}
      <button type="button" className="gz-reset gz-ctile__open" onClick={onOpen} aria-pressed={selected || undefined}>
        <span className="gz-sr-only">{label}</span>
      </button>
    </div>
  )
}
