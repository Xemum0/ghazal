// useNav(): the one hook screens use to move. Without a provider (static frames, gallery specimens) every call is inert and
// never throws, so a screen is the same code in the canvas and in the player.
import { createContext, useContext, useMemo } from 'react'
import type { DialogResult, Nav, NavApi, Params } from './types'

const NOOP = () => {}

export const INERT_NAV: NavApi = {
  push: NOOP,
  pop: NOOP,
  replace: NOOP,
  reset: NOOP,
  switchTab: NOOP,
  openSheet: () => '',
  closeSheet: NOOP,
  openDialog: () => Promise.resolve<DialogResult>('cancel'),
  toast: () => '',
  dismissToast: NOOP,
}

/** The stable operations (identity never changes while the provider lives). */
export const NavApiContext = createContext<NavApi>(INERT_NAV)

/** What is true of the screen (or sheet) a component is rendered in. */
export type NavEntry = {
  id: string
  params: Params
  canGoBack: boolean
  activeTab: string | null
}

export const EntryContext = createContext<NavEntry>({ id: '', params: {}, canGoBack: false, activeTab: null })

export function useNav<P extends Params = Params>(): Nav & { params: P } {
  const api = useContext(NavApiContext)
  const entry = useContext(EntryContext)
  return useMemo(
    () => ({ ...api, params: entry.params as P, currentId: entry.id, canGoBack: entry.canGoBack, activeTab: entry.activeTab }),
    [api, entry],
  )
}
