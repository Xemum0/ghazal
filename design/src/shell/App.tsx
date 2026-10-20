import { GalleryRoute } from './GalleryRoute'
import { StaticFrameRoute } from './device'
import { Launcher } from './Launcher'
import { Studio } from './studio/Studio'
import { useRoute } from './router'

/**
 * Router. The front door is the Launcher: a bare #/ shows one phone and a Client | Hotel switch, nothing else.
 * Two chromeless harness routes stay exactly as the tools expect them (#/gallery/<name>, #/frame/<screenId>).
 * The design-work views remain, but only on explicit routes: #/canvas/<app>, #/play/<app>/<screenId>, #/system/<page>, #/docs/<name>.
 */
export function App() {
  const route = useRoute()
  switch (route.segments[0]) {
    case 'gallery':
      return <GalleryRoute />
    case 'frame':
      return <StaticFrameRoute />
    case 'canvas':
    case 'play':
    case 'system':
    case 'docs':
      return <Studio />
    default:
      return <Launcher />
  }
}
