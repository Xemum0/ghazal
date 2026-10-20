// VenueHero (CL-VENU-01, direction 5 and rule 8): the full-bleed photograph under the status bar, 440 high, nothing on it but the zone
// glyph, the counter and the hairline progress with its bead. A tap opens the viewer from the photograph's own rectangle (shared element,
// ADR 0017). ADR 0034: the zone is a glyph (its name is the accessible name), the counter is a figure. The transparent TopBar brings its own
// scrim; the bottom scrim exists only where the glyph and the figure sit.
import type { MediaZone } from '../../../../mock'
import { useT } from '../../../../i18n'
import { Icon, Illustration, Pager, PagerProgress, Photo, rectOf, type CarouselImage, type Rect } from '../../../../system'
import { ZONE_ICON } from './glyphs'
import './venue-hero.css'

export type VenueHeroProps = {
  images: readonly CarouselImage[]
  /** Zone name of each photograph (`Hall · Danah Ballroom`), read by assistive technology. */
  captions: readonly string[]
  /** Zone of each photograph: the glyph on the hero. */
  zones: readonly MediaZone[]
  index: number
  onIndexChange: (index: number) => void
  /** The rectangle of the tapped photograph: the origin of the expansion. */
  onOpen: (index: number, origin: Rect) => void
  label: string
  /** Loading: the static placeholder, no photograph yet. */
  loading?: boolean
}

export function VenueHero({ images, captions, zones, index, onIndexChange, onOpen, label, loading }: VenueHeroProps) {
  const t = useT('client-venue')
  const tc = useT('common')

  if (loading) return <div className="gzv-hero gzv-hero--loading" data-gz="VenueHero" aria-busy="true" />

  if (images.length === 0) {
    return (
      <div className="gzv-hero gzv-hero--empty" data-gz="VenueHero">
        <Illustration name="camera" size="lg" label={t('clientVenueNoPhotos')} />
      </div>
    )
  }

  const current = Math.min(index, images.length - 1)
  const zone = zones[current]
  return (
    <div className="gzv-hero" data-gz="VenueHero">
      <Pager mode="full" index={current} onIndexChange={onIndexChange} label={label}>
        {images.map((img, i) => (
          <div key={`${i}-${img.src}`} className="gzv-hero__cell">
            <button
              type="button"
              className="gz-reset gzv-hero__item"
              aria-label={`${img.alt}. ${t('clientVenueHeroOpen')}`}
              onClick={e => onOpen(i, rectOf(e.currentTarget.querySelector('img') ?? e.currentTarget))}
            >
              <Photo src={img.src} alt="" className="gzv-hero__photo" priority={i === current} />
            </button>
          </div>
        ))}
      </Pager>
      <span className="gzv-hero__scrim" aria-hidden="true" />
      <div className="gzv-hero__foot">
        <PagerProgress count={images.length} index={current} />
        <div className="gzv-hero__row">
          <p className="gzv-hero__zone" data-gz-id="hero.zone">
            {zone ? <Icon name={ZONE_ICON[zone]} size="sm" tone="on-dark" /> : null}
            <span className="gz-sr-only">{captions[current]}</span>
          </p>
          <p className="gzv-hero__counter gz-t-fig-caption" aria-label={tc('commonA11yPhotoCounter', { current: current + 1, total: images.length })}>
            <Icon name="gallery" size="xs" tone="on-dark" />
            <bdi dir="ltr">{t('clientVenueGalleryCounter', { current: current + 1, total: images.length })}</bdi>
          </p>
        </div>
      </div>
    </div>
  )
}
