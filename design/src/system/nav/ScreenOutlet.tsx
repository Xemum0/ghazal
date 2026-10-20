// ScreenOutlet: loads a screen by inventory id from the lazy registry (src/shell/registry) and renders it with the frame
// context a screen expects (useFrame). A missing id shows the same clear "Not built yet" notice as the #/frame route, with a
// way back. `ScreenOverrides` lets the gallery supply dummy screens without touching the registry.
import { Suspense, createContext, useContext, type ComponentType, type ReactNode } from 'react'
import { ErrorBoundary } from '../../shell/ErrorBoundary'
import { FrameContext, type FrameState } from '../../shell/frame'
import { find, screenEntries } from '../../shell/registry'
import { useDevice } from '../../shell/device/context'
import { useLang } from '../../shell/lang'
import { TopBar } from './TopBar'
import { isSheetScreen } from './tabs'

export type ScreenComponent = ComponentType<{ state?: string }>

/** Screens that win over the registry for the ids they name (gallery demos, tests). */
export const ScreenOverridesContext = createContext<Record<string, ScreenComponent>>({})

const NOT_BUILT = {
  en: { title: 'Not built yet', body: (id: string) => `No file named ${id}.tsx under design/src/screens.` },
  ar: { title: 'لم تُبنَ بعد', body: (id: string) => `لا يوجد ملف باسم ${id}.tsx داخل design/src/screens.` },
} as const

/** Harness notice for an id with no screen file. Same markers as the #/frame route (data-gz-missing) so shots.mjs reports it. */
export function NotBuilt({ id }: { id: string }) {
  const sheet = isSheetScreen(id)
  const { lang } = useLang()
  const copy = NOT_BUILT[lang]
  return (
    <div className="gz-notbuilt" data-gz="NotBuilt">
      {sheet ? null : <TopBar title={<bdi className="gz-ltr">{id}</bdi>} />}
      <div className="gz-shell-notice" role="status" data-gz-missing={id}>
        <h2 className="gz-shell-notice__title">{copy.title}</h2>
        <p className="gz-shell-notice__id"><bdi>{id}</bdi></p>
        <p className="gz-shell-notice__body">{copy.body(id)}</p>
      </div>
    </div>
  )
}

export type ScreenOutletProps = {
  id: string
  state?: string
  fallback?: ReactNode
}

/** Resolve `id` and render it inside a frame context, an error boundary and Suspense. */
export function ScreenOutlet({ id, state, fallback = null }: ScreenOutletProps) {
  const overrides = useContext(ScreenOverridesContext)
  const { width } = useDevice()
  const Override = overrides[id]
  const entry = Override ? undefined : find(screenEntries, id)
  const frame: FrameState = { screenId: entry?.id ?? id, state, width }
  const Component = Override ?? entry?.Component
  return (
    <FrameContext.Provider value={frame}>
      <ErrorBoundary label={`screen/${id}`}>
        <Suspense fallback={fallback}>{Component ? <Component state={state} /> : <NotBuilt id={id} />}</Suspense>
      </ErrorBoundary>
    </FrameContext.Provider>
  )
}
