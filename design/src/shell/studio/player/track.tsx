// Which screen is the prototype showing right now? The navigator keeps its state private, so the player reads the DOM it renders:
// the visible layer of the active stack (data-gz-screen) and, over it, the top sheet (a data-gz-track mark that wraps every screen the
// player mounts). Wrapping happens through the NavRoot `screens` override: each inventory id resolves to a thin component that
// marks itself and renders the real registry screen, so nothing about the screens or the navigator changes.
import { useMemo, type ComponentType } from 'react'
import { ScreenOutlet, ScreenOverridesContext, type ScreenComponent } from '../../../system/nav'
import { isBuilt } from '../../registry'
import { SCREENS } from '../data/inventory'
import { ProtoStub } from './ProtoStub'

const NONE: Record<string, ScreenComponent> = {}

function make(id: string): ScreenComponent {
  const Tracked: ComponentType<{ state?: string }> = ({ state }) => (
    <div className="gzs-track" data-gz-track={id}>
      {isBuilt(id) ? (
        <ScreenOverridesContext.Provider value={NONE}>
          <ScreenOutlet id={id} state={state} />
        </ScreenOverridesContext.Provider>
      ) : (
        <ProtoStub id={id} />
      )}
    </div>
  )
  Tracked.displayName = `Tracked(${id})`
  return Tracked
}

let cache: Record<string, ScreenComponent> | null = null

/** One tracked wrapper per inventory id (stable identities, so React never remounts a screen because the map was rebuilt). */
export function useTrackedScreens(): Record<string, ScreenComponent> {
  return useMemo(() => (cache ??= Object.fromEntries(SCREENS.map(s => [s.id, make(s.id)]))), [])
}

/** The id of the screen on top: an open sheet's screen, else the visible layer of the active stack. */
export function readCurrentScreen(root: Element): string | null {
  const sheets = [...root.querySelectorAll('[data-gz="Sheet"]')].filter(s => !s.classList.contains('gz-sheet-exit'))
  const sheet = sheets[sheets.length - 1]
  if (sheet) {
    const marks = sheet.querySelectorAll('[data-gz-track]')
    const id = marks[marks.length - 1]?.getAttribute('data-gz-track')
    if (id) return id
  }
  const stack = root.querySelector('.gz-stack[data-state="active"]') ?? root
  const layers = [...stack.querySelectorAll('.gz-layer[data-gz-screen]')].filter(
    l => !l.hasAttribute('data-hidden') && !['exit-push', 'exit-pop', 'fade-out'].includes(l.getAttribute('data-phase') ?? ''),
  )
  return layers[layers.length - 1]?.getAttribute('data-gz-screen') ?? null
}

/** The back button of the visible screen, if it has one. */
export function backButton(root: Element): HTMLElement | null {
  const stack = root.querySelector('.gz-stack[data-state="active"]') ?? root
  const layers = [...stack.querySelectorAll('.gz-layer[data-gz-screen]')].filter(l => !l.hasAttribute('data-hidden'))
  return buttonIn(layers[layers.length - 1]?.querySelector<HTMLElement>('[data-gz-id="bar.back"]'))
}

/** BarButton marks its wrapper; the thing to press is the button inside it. */
const buttonIn = (el: HTMLElement | null | undefined): HTMLElement | null => (el ? (el.matches('button') ? el : el.querySelector<HTMLElement>('button')) : null)

export const openSheetClose = (root: Element): HTMLElement | null => {
  const sheets = [...root.querySelectorAll('[data-gz="Sheet"]')].filter(s => !s.classList.contains('gz-sheet-exit'))
  return buttonIn(sheets[sheets.length - 1]?.querySelector<HTMLElement>('[data-gz-id="sheet.close"]'))
}

export const hasDialog = (root: Element): boolean => root.querySelector('[data-gz="Dialog"]') !== null
