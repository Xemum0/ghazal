// CL-VENU-02 Photos and videos. Covers CA-VDET-01, CA-VDET-02, CA-CARD-02.
// The full-screen photo tour: zone chips, pinch and double-tap zoom, a counter that stays left to right, and a video that starts only
// on a tap from its poster. On the venue page the hero opens this same viewer in place, so the photograph can grow from its own
// rectangle (shared element); this screen is the viewer as a route: from the compare table's photo strips, a deep link, the canvas.
// Navigates back to CL-VENU-01. No tab bar.
import { useState } from 'react'
import * as mock from '../../../mock'
import type { Rect } from '../../../system'
import { useNav } from '../../../system'
import { GalleryViewer } from './_components/GalleryViewer'
import { heroIndexOf } from './_components/heroIndex'
import { DEFAULT_VENUE_ID, useVenueId } from './_components/model'
import { useFrame } from '../../../shell/frame'

export const states = ['loading', 'error', 'offline', 'video-playing', 'zoomed']

type Params = { venueId?: string; index?: number; origin?: Rect | null }

export default function Gallery() {
  const nav = useNav<Params>()
  const { state } = useFrame()
  const venueId = useVenueId()
  const venue = mock.getVenue(venueId) ?? mock.getVenue(DEFAULT_VENUE_ID)
  const start = typeof nav.params.index === 'number' ? nav.params.index : heroIndexOf(venueId)
  const [index, setIndex] = useState(start)
  if (!venue) return null
  return <GalleryViewer venue={venue} index={index} onIndexChange={setIndex} origin={nav.params.origin ?? null} onClose={() => nav.pop()} state={state} />
}
