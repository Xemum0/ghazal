// PhotoStrip (HL-PROV-03): the listing's photographs: thumbnails with a remove control, then an Add tile. The prototype has no camera roll, so Add
// takes the next unused photograph of the provider's category from the curated library (rooms, plates, arrangements; never faces).
import type { ImageRef, ServiceCategoryId } from '../../../../mock'
import { providersFor, serviceCategories } from '../../../../mock'
import { Icon, Photo, imageSrc } from '../../../../system'
import { useBi, useP } from './bits'
import './photo-strip.css'

export const MAX_PHOTOS = 8

/** The curated photographs a category can offer: its own, then every provider portfolio of the category. */
export function photoPool(categoryId: ServiceCategoryId | null): ImageRef[] {
  const cat = serviceCategories.find(c => c.id === categoryId)
  const fromProviders = categoryId ? providersFor(categoryId, { includeHidden: true }).flatMap(p => p.portfolio) : []
  const all = [...(cat ? [cat.image] : []), ...fromProviders]
  return all.filter((img, i) => all.findIndex(x => x.file === img.file) === i)
}

export type PhotoStripProps = {
  photos: ImageRef[]
  categoryId: ServiceCategoryId | null
  onChange: (next: ImageRef[]) => void
}

export function PhotoStrip({ photos, categoryId, onChange }: PhotoStripProps) {
  const { t } = useP()
  const bi = useBi()
  const next = photoPool(categoryId).find(img => !photos.some(p => p.file === img.file))
  const canAdd = photos.length < MAX_PHOTOS && Boolean(next)
  return (
    <div className="hp-photos" data-gz="PhotoStrip">
      <ul className="hp-photos__grid">
        {photos.map((p, i) => (
          <li key={p.file} className="hp-photos__cell">
            <Photo src={imageSrc(p.file)} alt={bi(p.alt)} className="hp-photos__img" sizes="104px" />
            {i === 0 ? <span className="hp-photos__cover gz-t-caption">{t('hotelProviderPhotoCover')}</span> : null}
            <button type="button" className="gz-reset hp-photos__x gz-press" aria-label={t('hotelProviderPhotoRemove')} onClick={() => onChange(photos.filter(x => x.file !== p.file))}>
              <Icon name="close" size="xs" />
            </button>
          </li>
        ))}
        <li className="hp-photos__cell">
          <button type="button" className="gz-reset hp-photos__add gz-press" disabled={!canAdd} onClick={() => next && onChange([...photos, next])}>
            <Icon name="camera" size="md" />
            <span className="gz-t-caption">{t('hotelProviderPhotoAdd')}</span>
          </button>
        </li>
      </ul>
    </div>
  )
}
