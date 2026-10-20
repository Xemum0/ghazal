// The Device framework (shell): the frame every screen runs inside, static and live.
export { Device, type DeviceProps } from './Device'
export { StaticFrame, type StaticFrameProps } from './StaticFrame'
export { PrototypePlayer, STORY_START, type PrototypePlayerProps, type Story } from './PrototypePlayer'
export { StaticFrameRoute, PlayerRoute } from './routes'
export {
  AppContext,
  BottomChromeContext,
  DeviceContext,
  LayerActiveContext,
  useAppKind,
  useBottomChrome,
  useDevice,
  useStatusTone,
  type AppKind,
  type ChromeTone,
  type DeviceChrome,
  type DeviceInfo,
  type DeviceMode,
} from './context'
