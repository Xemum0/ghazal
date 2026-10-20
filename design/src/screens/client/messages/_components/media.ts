// The photographs a couple can attach in the prototype: a few curated stills (kosha, arch, centrepiece, cake, candles, bouquet) from the
// image library, with their bilingual alt text from its manifest. Nothing here is a person; chat media is private between the two sides.
import manifest from '../../../../../public/images/manifest.json'

type ManifestImage = { file: string; alt_en: string; alt_ar: string }
const images = (manifest as { images: ManifestImage[] }).images

const FILES = [
  'ballrooms/ballrooms-18-hotel-ballroom-gold-arch-stage-wide.jpg',
  'ballrooms/ballrooms-17-floral-arch-stage-draped-ceiling.jpg',
  'details/details-07-arch-corner-florals-window-light.jpg',
  'details/details-05-centerpiece-gold-vase-white-roses.jpg',
  'details/details-12-cake-painted-tiers-florals-wood-table.jpg',
  'details/details-09-candles-gold-geometric-lantern-roses.jpg',
  'details/details-29-bouquet-blush-roses-toile-cushion.jpg',
]

export type LibraryPhoto = { file: string; alt: { en: string; ar: string } }

export const libraryPhotos: LibraryPhoto[] = FILES.flatMap(file => {
  const hit = images.find(i => i.file === file)
  return hit ? [{ file, alt: { en: hit.alt_en, ar: hit.alt_ar } }] : []
})

let next = 0
/** The next photo of the rotation: Camera and Photos each hand over a different still, so a second attach is visibly a second photo. */
export const nextPhoto = (): LibraryPhoto => {
  const photo = libraryPhotos[next % libraryPhotos.length] as LibraryPhoto
  next += 1
  return photo
}
