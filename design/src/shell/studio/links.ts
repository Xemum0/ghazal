// Every Studio URL in one place. The hash is the whole state of a view (route, language, width, focus), so a copied link reproduces it.
//   #/canvas/<app>?lang=&w=&focus=<screenId>&flow=<flowId>
//   #/play/<app>/<screenId>?lang=&w=&story=signed-out|signed-in
//   #/system/<galleryPage>?lang=     #/docs/<name>?lang=
// The older chromeless routes (#/gallery/<name>, #/frame/<id>) stay exactly as the harness defines them.
import type { AppId } from './data/inventory'
import type { Lang } from '../lang'

export type StudioParams = { lang: Lang; w?: number | null; [k: string]: string | number | null | undefined }

function query(p: StudioParams, extra: Record<string, string | number | null | undefined> = {}): string {
  const q = new URLSearchParams()
  q.set('lang', p.lang)
  const all = { ...p, ...extra }
  for (const [k, v] of Object.entries(all)) {
    if (k === 'lang' || v === null || v === undefined || v === '') continue
    q.set(k, String(v))
  }
  return q.toString()
}

export const canvasHash = (app: AppId, p: StudioParams, extra?: { focus?: string | null; flow?: string | null }): string =>
  `#/canvas/${app}?${query({ lang: p.lang, w: p.w }, extra)}`

export const playHash = (app: AppId, screenId: string | null, p: StudioParams, extra?: { story?: string | null }): string =>
  `#/play/${app}${screenId ? `/${encodeURIComponent(screenId)}` : ''}?${query({ lang: p.lang, w: p.w }, extra)}`

export const systemHash = (page: string, lang: Lang): string => `#/system/${encodeURIComponent(page)}?lang=${lang}`
export const docsHash = (name: string, lang: Lang): string => `#/docs/${encodeURIComponent(name)}?lang=${lang}`
export const bareGalleryHash = (page: string, lang: Lang): string => `#/gallery/${encodeURIComponent(page)}?lang=${lang}`

/** Absolute URL of the current view, for the Copy link button. */
export const currentUrl = (): string => window.location.href
