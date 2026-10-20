// Studio UI state (zustand): which panels are open, which overlays are drawn, how the canvas behaves. NOT prototype state (that is
// shell/state). Preferences survive a reload of the tab through sessionStorage; every access is guarded because storage can be
// missing, full or blocked (private windows, thumbnail capture), and the Studio renders correctly without it.
import { create } from 'zustand'

export type ConnectorMode = 'flow' | 'all' | 'off'
export type WheelMode = 'zoom' | 'pan'

export type Prefs = {
  sidebarOpen: boolean
  inspectorOpen: boolean
  /** 4-pt grid overlay on every frame. */
  grid: boolean
  /** Outline every layout box (CSS outline only). */
  redlines: boolean
  /** Which prototype connectors the board draws: those inside a flow, those plus the selected frame's cross-flow links, none. */
  connectors: ConnectorMode
  /** Extra frames for each state a built screen exports. */
  variants: boolean
  /** Plain wheel zooms to the cursor (default) or pans (trackpad habit). Ctrl/Cmd + wheel and pinch always zoom. */
  wheel: WheelMode
  /** In Arabic the flow reads right to left (default). Off keeps the board left to right while the frames themselves mirror. */
  mirrorFlow: boolean
  /** Emulates prefers-reduced-motion for the Studio and the prototype. */
  reducedMotion: boolean
  /** Player: highlight the tappable areas. */
  hotspots: boolean
}

export const DEFAULT_PREFS: Prefs = {
  sidebarOpen: true,
  inspectorOpen: true,
  grid: false,
  redlines: false,
  connectors: 'flow',
  variants: true,
  wheel: 'zoom',
  mirrorFlow: true,
  reducedMotion: false,
  hotspots: false,
}

const KEY = 'gz.studio.prefs'

function read(): Prefs {
  try {
    const raw = window.sessionStorage.getItem(KEY)
    if (!raw) return DEFAULT_PREFS
    const parsed = JSON.parse(raw) as Partial<Prefs>
    // Keep only keys we know with the right type: a stale or hand-edited value never breaks the Studio.
    const out = { ...DEFAULT_PREFS }
    for (const k of Object.keys(DEFAULT_PREFS) as (keyof Prefs)[]) {
      if (typeof parsed[k] === typeof DEFAULT_PREFS[k]) (out as Record<string, unknown>)[k] = parsed[k]
    }
    return out
  } catch {
    return DEFAULT_PREFS
  }
}

function write(p: Prefs) {
  try {
    window.sessionStorage.setItem(KEY, JSON.stringify(p))
  } catch {
    /* storage unavailable: preferences simply do not persist */
  }
}

type StudioState = Prefs & {
  /** Frame the inspector shows (inventory screen id) on the board. */
  selected: string | null
  /** State override per screen id (set from the inspector's state chips); applies to the default frame only. */
  stateOverride: Record<string, string>
  /** Small screens: the sidebar is a drawer; this is its open flag (the desktop flag is `sidebarOpen`). */
  set: (patch: Partial<Prefs>) => void
  toggle: (key: keyof Pick<Prefs, 'sidebarOpen' | 'inspectorOpen' | 'grid' | 'redlines' | 'variants' | 'mirrorFlow' | 'reducedMotion' | 'hotspots'>) => void
  select: (id: string | null) => void
  setStateOverride: (id: string, state: string | null) => void
}

export const useStudio = create<StudioState>()((set, get) => ({
  ...read(),
  selected: null,
  stateOverride: {},
  set: patch => {
    set(patch)
    persist(get())
  },
  toggle: key => {
    set({ [key]: !get()[key] } as Partial<Prefs>)
    persist(get())
  },
  select: id => set({ selected: id }),
  setStateOverride: (id, state) =>
    set(s => {
      const next = { ...s.stateOverride }
      if (state === null || state === 'default') delete next[id]
      else next[id] = state
      return { stateOverride: next }
    }),
}))

function persist(s: StudioState) {
  const prefs = {} as Record<string, unknown>
  for (const k of Object.keys(DEFAULT_PREFS)) prefs[k] = (s as unknown as Record<string, unknown>)[k]
  write(prefs as Prefs)
}

// ---------------------------------------------------------------- remembered view

const LAST_KEY = 'gz.studio.last'
const VIEW_KEY = 'gz.studio.view.'

/** The last Studio hash (route + params), restored when the Studio opens on a bare `#/`. */
export const lastHash = {
  get(): string | null {
    try {
      return window.sessionStorage.getItem(LAST_KEY)
    } catch {
      return null
    }
  },
  set(hash: string) {
    try {
      window.sessionStorage.setItem(LAST_KEY, hash)
    } catch {
      /* ignore */
    }
  },
}

export type SavedView = { x: number; y: number; k: number }

/** Canvas pan/zoom per app, in world units, so coming back from the player lands exactly where you left. */
export const savedView = {
  get(app: string): SavedView | null {
    try {
      const raw = window.sessionStorage.getItem(VIEW_KEY + app)
      if (!raw) return null
      const v = JSON.parse(raw) as SavedView
      return Number.isFinite(v.x) && Number.isFinite(v.y) && Number.isFinite(v.k) ? v : null
    } catch {
      return null
    }
  },
  set(app: string, v: SavedView) {
    try {
      window.sessionStorage.setItem(VIEW_KEY + app, JSON.stringify(v))
    } catch {
      /* ignore */
    }
  },
}
