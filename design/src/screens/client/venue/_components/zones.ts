// Photo zones of a venue gallery (HL-VENU-01 zones) and the zone label of one photograph: `Hall · Danah Ballroom`.
import { useMemo } from 'react'
import type { MediaZone, Venue } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { imageSrc, type CarouselImage } from '../../../../system'

export const ZONE_ORDER: readonly MediaZone[] = ['hall', 'stage_kosha', 'bridal_suite', 'buffet', 'outdoors', 'entrance_valet', 'layout']

const ZONE_KEY = {
  hall: 'clientVenueZoneHall',
  stage_kosha: 'clientVenueZoneStage',
  bridal_suite: 'clientVenueZoneBridal',
  buffet: 'clientVenueZoneBuffet',
  outdoors: 'clientVenueZoneOutdoors',
  entrance_valet: 'clientVenueZoneEntrance',
  layout: 'clientVenueZoneLayout',
} as const satisfies Record<MediaZone, string>

/** The photographs as viewer images (src and bilingual alt from the manifest) and the zone label of each. */
export function useGallery(venue: Venue | undefined): { images: CarouselImage[]; captions: string[]; zones: MediaZone[]; zoneOf: MediaZone[] } {
  const t = useT('client-venue')
  const { lang } = useLang()
  return useMemo(() => {
    const gallery = venue?.gallery ?? []
    const manyHalls = (venue?.halls.length ?? 0) > 1
    const images = gallery.map(g => ({ src: imageSrc(g.file), alt: g.alt[lang] }))
    const captions = gallery.map(g => {
      const zone = t(ZONE_KEY[g.zone])
      const hall = manyHalls && g.hallId ? venue?.halls.find(h => h.id === g.hallId)?.name[lang] : undefined
      return hall ? t('clientVenueZoneWithHall', { zone, hall }) : zone
    })
    const present = new Set(gallery.map(g => g.zone))
    return { images, captions, zones: ZONE_ORDER.filter(z => present.has(z)), zoneOf: gallery.map(g => g.zone) }
  }, [venue, lang, t])
}

export const zoneName = (t: ReturnType<typeof useT<'client-venue'>>, zone: MediaZone): string => t(ZONE_KEY[zone])
