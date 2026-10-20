// StaticFrame: one screen drawn in a Device, deterministically (no animation, inert navigation). This is the canvas form of
// every screen: the same component the player renders, with the chrome the inventory prescribes (status bar, home indicator, the
// tab bar when the flow shows it, the sheet container for sheet screens). `useNav()` inside the screen is inert and never throws.
import { useMemo, type ReactNode } from 'react'
import { BottomChromeContext, type DeviceChrome } from './context'
import { Device } from './Device'
import { AppTabBar } from '../../system/nav/TabBar'
import { useTabBadges } from '../../system/nav/useTabBadges'
import { ScreenOutlet } from '../../system/nav/ScreenOutlet'
import { EntryContext } from '../../system/nav/useNav'
import { chromeFor, isSheetScreen, isTabRoot } from '../../system/nav/tabs'
import { Sheet } from '../../system/overlays/Sheet'
import './static-frame.css'

export type StaticFrameProps = {
  screenId: string
  /** `loading | empty | error | offline | ...` (the ?state= of the frame route). */
  state?: string
  width?: number
  height?: number | 'auto'
  chrome?: DeviceChrome
  /** Params a deep screen would receive (read with useNav().params). */
  params?: Record<string, unknown>
  /** Draw a thin bezel around it (gallery). */
  bezel?: 'none' | 'thin'
  /** Replace the resolved screen (gallery specimens that are not in the registry). */
  children?: ReactNode
}

export function StaticFrame({ screenId, state, width, height, chrome = 'status', params, bezel = 'none', children }: StaticFrameProps) {
  const info = chromeFor(screenId)
  const sheet = isSheetScreen(screenId)
  const root = isTabRoot(screenId)
  const badges = useTabBadges(info.app)
  const entry = useMemo(
    () => ({ id: screenId, params: params ?? {}, canGoBack: !root && !sheet, activeTab: info.tab }),
    [screenId, params, root, sheet, info.tab],
  )
  const showBar = info.tabBar && !sheet && chrome === 'status' && info.tab !== null

  const body = children ?? <ScreenOutlet id={screenId} state={state} />

  return (
    <Device mode="static" app={info.app} width={width} height={height} chrome={chrome} bezel={bezel} label={screenId}>
      <EntryContext.Provider value={entry}>
        <BottomChromeContext.Provider value={{ tabBar: showBar }}>
          {sheet ? (
            <>
              <div className="gz-static__under" />
              <Sheet placement="overlay" dismissible={false}>
                {body}
              </Sheet>
            </>
          ) : (
            <>
              <div className="gz-static__body gz-no-scrollbar" data-gz-id="frame.body">{body}</div>
              {showBar && info.tab ? <AppTabBar app={info.app} activeId={info.tab} badges={badges} /> : null}
            </>
          )}
        </BottomChromeContext.Provider>
      </EntryContext.Provider>
    </Device>
  )
}
