// The Studio's view of the URL hash: which surface is showing and with what parameters. The hash stays the single source of truth
// (links.ts builds it, router.ts parses it), so every view is a shareable link.
import { useMemo } from 'react'
import { useRoute, type Route } from '../router'
import { parseApp, type AppId } from './data/inventory'

export type StudioView = 'canvas' | 'play' | 'system' | 'docs'
export const DEVICE_WIDTHS = [360, 390, 430] as const
export type DeviceWidth = (typeof DEVICE_WIDTHS)[number]

export type StudioRoute = {
  view: StudioView
  app: AppId
  /** Frame width in dp. */
  w: DeviceWidth
  /** `#/system/<page>` and `#/docs/<name>`. */
  page: string
  /** `#/play/<app>/<screenId>`. */
  screen: string | null
  story: 'guest' | 'signed-in'
  route: Route
}

const toWidth = (v: string | null): DeviceWidth => {
  const n = Number(v)
  return (DEVICE_WIDTHS as readonly number[]).includes(n) ? (n as DeviceWidth) : 390
}

export const STUDIO_VIEWS: readonly string[] = ['canvas', 'play', 'system', 'docs']

export function parseStudioRoute(route: Route): StudioRoute {
  const [head = '', a = '', b = ''] = route.segments
  const view: StudioView = head === 'play' || head === 'system' || head === 'docs' ? head : 'canvas'
  const app = parseApp(view === 'canvas' || view === 'play' ? a : route.params.get('app'))
  return {
    view,
    app,
    w: toWidth(route.params.get('w')),
    page: view === 'system' || view === 'docs' ? a : '',
    screen: view === 'play' && b ? b : null,
    story: route.params.get('story') === 'signed-in' ? 'signed-in' : 'guest',
    route,
  }
}

export function useStudioRoute(): StudioRoute {
  const route = useRoute()
  return useMemo(() => parseStudioRoute(route), [route.raw]) // eslint-disable-line react-hooks/exhaustive-deps -- raw identifies the route
}
