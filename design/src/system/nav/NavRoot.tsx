// NavRoot: the live app inside a Device. Provider + tab host + persistent tab bar + sheet, dialog and toast hosts.
//   <Device mode="live"><NavRoot app="client" initial="CL-DISC-01" /></Device>
// Per-tab stacks stay mounted once visited; the tab bar is one element that follows the top screen (hidden on the flows and
// screens the inventory lists, ADR 0007 D6 / ADR 0008) and slides away with a pushed screen; overlays cover everything.
import { useCallback, useContext, useEffect, useLayoutEffect, useMemo, useRef, useState, type CSSProperties } from 'react'
import { flat } from '@gz/tokens'
import { useDevice, type AppKind } from '../../shell/device/context'
import { FLOW, NavProvider, useNavInternals, type NavProviderProps } from './NavProvider'
import { StackHost } from './StackHost'
import { DialogHost, SheetHost, ToastHost } from './OverlayHosts'
import { AppTabBar } from './TabBar'
import { useTabBadges } from './useTabBadges'
import { ScreenOverridesContext, type ScreenComponent } from './ScreenOutlet'
import { BarInsetContext, ScrollTopSignalContext } from './screen-context'
import { NavApiContext } from './useNav'
import { chromeFor, tabsOf } from './tabs'
import './navroot.css'

export type NavRootProps = Omit<NavProviderProps, 'children'> & {
  /** Dummy or override screens by inventory id (gallery demos). They win over src/screens/**. */
  screens?: Record<string, ScreenComponent>
}

const EMPTY: Record<string, ScreenComponent> = {}
const TOAST_GAP = flat['space.4']
/** Cross-fade window of a tab switch: the outgoing stack stays visible this long under the incoming one. */
const SWITCH_MS = flat['motion.duration.base'] + flat['motion.duration.fast']

export function NavRoot({ screens, ...provider }: NavRootProps) {
  return (
    <ScreenOverridesContext.Provider value={screens ?? EMPTY}>
      <NavProvider {...provider}>
        <NavShell app={provider.app} />
      </NavProvider>
    </ScreenOverridesContext.Provider>
  )
}

function NavShell({ app }: { app: AppKind }) {
  const { state } = useNavInternals()
  const api = useContext(NavApiContext)
  const { safeBottom } = useDevice()
  const tabs = tabsOf(app)
  const badges = useTabBadges(app)

  // The tab bar follows the top screen of the active stack.
  const activeStack = state.stacks[state.active] ?? []
  const top = activeStack[activeStack.length - 1]
  const inTabs = state.active !== FLOW
  const barVisible = inTabs && (top ? chromeFor(top.id).tabBar : true)
  // A sheet or dialog is modal: the content and the tab bar behind it are inert (no focus, no assistive-tech reach) until it leaves.
  const modalOpen = state.sheets.length > 0 || !!state.dialog

  // Tab switch: the outgoing stack stays visible while the incoming one fades in over it.
  const [leaving, setLeaving] = useState<string | null>(null)
  // The epoch whose fade is still running: the animation class is dropped afterwards so no composited layer outlives it.
  const [fading, setFading] = useState(0)
  const prevActive = useRef(state.active)
  useLayoutEffect(() => {
    if (state.tabEpoch === 0) return
    if (prevActive.current !== state.active) setLeaving(prevActive.current)
    prevActive.current = state.active
    setFading(state.tabEpoch)
    const id = window.setTimeout(() => {
      setLeaving(null)
      setFading(0)
    }, SWITCH_MS)
    return () => window.clearTimeout(id)
  }, [state.active, state.tabEpoch])

  // ActionBar heights (of the visible screen) lift the toast above them.
  const [insets, setInsets] = useState<Record<string, number>>({})
  const registry = useMemo(
    () => ({
      report: (key: string, h: number) => setInsets(prev => (prev[key] === h ? prev : { ...prev, [key]: h })),
      clear: (key: string) => setInsets(prev => (key in prev ? Object.fromEntries(Object.entries(prev).filter(([k]) => k !== key)) : prev)),
    }),
    [],
  )
  const actionBar = Math.max(0, ...Object.values(insets))
  const barReserve = flat['size.tab-bar'] + safeBottom
  const toastBottom = (actionBar > 0 ? actionBar : barVisible ? barReserve : safeBottom) + TOAST_GAP

  // Stacks to mount: every visited tab, plus the flow outside the tabs.
  const mounted = useMemo(() => {
    const ids = state.visited.filter(id => state.stacks[id])
    return ids
  }, [state.visited, state.stacks])

  const onSelect = useCallback((id: string) => api.switchTab(id), [api])
  const activeTabId = inTabs ? state.active : (tabs[0]?.id ?? '')

  useEffect(() => {
    // Keep the document aware of the live app (screenshots and QA read it).
    document.documentElement.dataset.gzApp = app
  }, [app])

  return (
    <BarInsetContext.Provider value={registry}>
      <ScrollTopSignalContext.Provider value={state.scrollSignal}>
        <div className="gz-navroot" data-gz="NavRoot" data-app={app} style={{ ['--gz-bar-reserve' as string]: `${barReserve}px` } as CSSProperties}>
          <div className="gz-navroot__stage" inert={modalOpen ? true : undefined}>
            {mounted.map(id => {
              const isActive = id === state.active
              const stateName = isActive ? 'active' : id === leaving ? 'leaving' : 'hidden'
              return (
                <div
                  key={id}
                  className={['gz-stack', isActive && fading === state.tabEpoch && state.tabEpoch > 0 ? `gz-stack--in-${state.tabEpoch % 2}` : ''].filter(Boolean).join(' ')}
                  data-gz="Stack"
                  data-tab={id === FLOW ? undefined : id}
                  data-state={stateName}
                  inert={isActive ? undefined : true}
                >
                  <StackHost stack={state.stacks[id] ?? []} tab={id === FLOW ? null : id} active={isActive} />
                </div>
              )
            })}
          </div>
          <div className="gz-navroot__bar" data-hidden={barVisible ? undefined : true} inert={barVisible && !modalOpen ? undefined : true}>
            <AppTabBar app={app} activeId={activeTabId} onSelect={onSelect} badges={badges} />
          </div>
          <SheetHost />
          <DialogHost />
          <ToastHost bottomInset={toastBottom} />
        </div>
      </ScrollTopSignalContext.Provider>
    </BarInsetContext.Provider>
  )
}
