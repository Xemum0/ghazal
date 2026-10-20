// Ghazal Design Studio: the chrome around the work. A toolbar on top, the sidebar and the inspector at the sides, and one surface in
// the middle: the canvas (default), the prototype player, a component gallery page, or a design document. Every view is a hash route
// (see links.ts), so the URL is the state; preferences and the last view are remembered per tab in sessionStorage.
import { useEffect } from 'react'
import { useLang } from '../lang'
import { useRoute } from '../router'
import { Canvas } from './canvas/Canvas'
import { Hud } from './chrome/Hud'
import { Inspector } from './chrome/Inspector'
import { Sidebar } from './chrome/Sidebar'
import { Toolbar } from './chrome/Toolbar'
import { canvasHash } from './links'
import { DocPage, SystemPage } from './docs/Pages'
import { PlayerPage } from './player/PlayerPage'
import { useStudioRoute } from './route'
import { lastHash, useStudio } from './store'
import './studio.css'

const isTyping = (t: EventTarget | null) => {
  const el = t as HTMLElement | null
  return Boolean(el && (el.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName)))
}

export function Studio() {
  const route = useRoute()
  const r = useStudioRoute()
  const { lang } = useLang()
  const reducedMotion = useStudio(s => s.reducedMotion)
  const sidebarOpen = useStudio(s => s.sidebarOpen)
  const inspectorOpen = useStudio(s => s.inspectorOpen)

  // A bare `#/` opens where this tab left the Studio (or the Client canvas).
  const bare = route.segments.length === 0
  useEffect(() => {
    if (!bare) return
    const last = lastHash.get()
    const next = last && /^#\/(canvas|play|system|docs)\b/.test(last) ? last : canvasHash('client', { lang })
    window.history.replaceState(null, '', next)
    window.dispatchEvent(new HashChangeEvent('hashchange'))
  }, [bare, lang])

  useEffect(() => {
    if (!bare) lastHash.set(`#${route.raw}`)
  }, [bare, route.raw])

  // Emulated reduced motion: one attribute the Studio CSS keys on (the product CSS also honours the OS setting).
  useEffect(() => {
    const html = document.documentElement
    if (reducedMotion) html.dataset.reducedMotion = '1'
    else delete html.dataset.reducedMotion
    return () => {
      delete html.dataset.reducedMotion
    }
  }, [reducedMotion])

  // On a narrow window the side panels start closed; the toolbar toggles open them over the canvas.
  useEffect(() => {
    if (window.innerWidth < 1100) useStudio.setState({ sidebarOpen: false, inspectorOpen: false })
  }, [])

  // Studio-wide shortcuts. The canvas owns its own (0, 1, +, -, F, arrows, P, Space, Esc).
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (isTyping(e.target) || e.ctrlKey || e.metaKey || e.altKey) return
      const st = useStudio.getState()
      if (e.key === '[') st.toggle('sidebarOpen')
      else if (e.key === ']' && r.view !== 'play') st.toggle('inspectorOpen')
      else if ((e.key === 'g' || e.key === 'G') && r.view === 'canvas') st.toggle('grid')
      else if ((e.key === 'r' || e.key === 'R') && r.view === 'canvas') st.toggle('redlines')
      else return
      e.preventDefault()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [r.view])

  if (bare) return null
  const showInspector = r.view === 'canvas'
  return (
    <div className="gzs-studio" data-gz="Studio" data-view={r.view} data-sidebar={sidebarOpen || undefined} data-inspector={(showInspector && inspectorOpen) || undefined}>
      <Toolbar />
      <div className="gzs-studio__body">
        <Sidebar />
        <main className="gzs-studio__main">
          {r.view === 'canvas' ? <Canvas key={r.app} app={r.app} frameW={r.w} /> : null}
          {r.view === 'canvas' ? <Hud /> : null}
          {r.view === 'play' ? <PlayerPage /> : null}
          {r.view === 'system' ? <SystemPage /> : null}
          {r.view === 'docs' ? <DocPage /> : null}
        </main>
        {showInspector ? <Inspector /> : null}
      </div>
    </div>
  )
}
