// <Device>: the frame every screen runs inside. A static frame (canvas, screenshots, deterministic) and a live frame (the
// prototype player) are the same component; only `mode` differs. It draws the system chrome, publishes the safe areas as
// CSS variables, and owns nothing about navigation (that is system/nav).
import { useCallback, useMemo, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import {
  AppContext,
  DeviceContext,
  ToneContext,
  type AppKind,
  type ChromeTone,
  type DeviceChrome,
  type DeviceInfo,
  type DeviceMode,
  type ToneRegistry,
} from './context'
import { HomeIndicator, StatusBar } from './StatusBar'
import './device.css'

export type DeviceProps = {
  /** Frame width in dp, fluid 360 to 430. Default 390. */
  width?: number
  /** Frame height in dp, or 'auto' to grow with the content (full-page shots). Default 844. */
  height?: number | 'auto'
  /** static: inert and deterministic (no animation, no live clock). live: the prototype player. */
  mode?: DeviceMode
  chrome?: DeviceChrome
  /** Thin bezel with the notch, for the player. The canvas frames have none. */
  bezel?: 'none' | 'thin'
  /** Base tone of the status bar and home indicator; a screen can ask for the other one with useStatusTone. */
  statusTone?: ChromeTone
  /** Clock text. The prototype clock reads 4:00 (Thu 12 Nov 2026, 4:00 PM). */
  time?: string
  app?: AppKind
  /** Accessible name of the frame (the screen id in canvas frames). */
  label?: string
  children?: ReactNode
}

const SAFE_TOP = flat['layout.safe.top']
const SAFE_BOTTOM = flat['layout.safe.bottom']
const BEZEL = 8 // hardware: the thin bezel is 8 dp on each side (device.css --gz-device-bezel)

export function Device({
  width = flat['layout.frame.width'],
  height = flat['layout.frame.height'],
  mode = 'static',
  chrome = 'status',
  bezel = 'none',
  statusTone = 'dark',
  time = '4:00',
  app = 'client',
  label,
  children,
}: DeviceProps) {
  const autoHeight = height === 'auto'
  const frameHeight = autoHeight ? flat['layout.frame.height'] : height
  const safeTop = chrome === 'status' ? SAFE_TOP : 0
  const safeBottom = chrome === 'status' ? SAFE_BOTTOM : 0

  // Tone registry: the latest registration wins; an unregister hands the tone back to the previous one.
  const entries = useRef<{ id: string; tone: ChromeTone }[]>([])
  const [override, setOverride] = useState<ChromeTone | null>(null)
  const register = useCallback<ToneRegistry['register']>((id, tone) => {
    entries.current = [...entries.current.filter(e => e.id !== id), { id, tone }]
    setOverride(entries.current[entries.current.length - 1]?.tone ?? null)
    return () => {
      entries.current = entries.current.filter(e => e.id !== id)
      setOverride(entries.current[entries.current.length - 1]?.tone ?? null)
    }
  }, [])
  const registry = useMemo<ToneRegistry>(() => ({ register }), [register])
  const tone = override ?? statusTone

  const info = useMemo<DeviceInfo>(
    () => ({ width, height: frameHeight, autoHeight, mode, chrome, safeTop, safeBottom }),
    [width, frameHeight, autoHeight, mode, chrome, safeTop, safeBottom],
  )

  // `gz-frame` on the screen: overlays that anchor to "the nearest frame" (the picker sheets of system/inputs) land inside the device.
  // Frame size and safe areas are runtime inputs (?w=, ?h=, chrome), so inline style is the one legitimate place.
  const outer = { inlineSize: width + (bezel === 'thin' ? BEZEL * 2 : 0) } as CSSProperties
  const screen = {
    inlineSize: width,
    blockSize: autoHeight ? undefined : frameHeight,
    '--gz-safe-top': `${safeTop}px`,
    '--gz-safe-bottom': `${safeBottom}px`,
  } as CSSProperties

  return (
    <div className="gz-device" data-gz="Device" data-mode={mode} data-chrome={chrome} data-bezel={bezel} data-auto={autoHeight || undefined} style={outer}>
      <div className="gz-device__screen gz-frame" style={screen} role="group" aria-label={label}>
        <DeviceContext.Provider value={info}>
          <AppContext.Provider value={app}>
            <ToneContext.Provider value={registry}>
              <div className="gz-device__content gz-no-scrollbar">{children}</div>
            </ToneContext.Provider>
          </AppContext.Provider>
        </DeviceContext.Provider>
        {chrome === 'status' && <StatusBar tone={tone} time={time} />}
        {chrome === 'status' && <HomeIndicator tone={tone} />}
      </div>
      {bezel === 'thin' && <span className="gz-device__notch" aria-hidden="true" />}
    </div>
  )
}
