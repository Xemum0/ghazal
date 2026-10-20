// NavProvider: the live navigator. State is one pure reducer (stacks per tab, sheets, one dialog, one toast); the API handed
// to screens is a stable object. Hosts (StackHost, SheetHost, DialogHost, ToastHost) render this state; the provider itself
// draws nothing. Persist nothing: state is gone on reload (the prototype resets to the story start).
import { createContext, useContext, useMemo, useReducer, useRef, type ReactNode } from 'react'
import type { AppKind } from '../../shell/device/context'
import { tabsOf } from './tabs'
import { EntryContext, NavApiContext } from './useNav'
import type { DialogResult, DialogSpec, NavApi, Params, SheetOptions, ToastSpec } from './types'

export const FLOW = '_flow'

export type StackEntry = { key: string; id: string; params: Params }
export type SheetContent = { kind: 'node'; node: ReactNode } | { kind: 'screen'; id: string; params: Params }
export type SheetEntry = { key: string; content: SheetContent; options: SheetOptions; closing: boolean }
export type DialogEntry = { key: string; spec: DialogSpec; closing: boolean }
export type ToastEntry = { key: string; spec: ToastSpec; closing: boolean }

export type NavState = {
  /** Stack per tab id (and FLOW for screens outside the tab host). The first entry of a tab stack is its root. */
  stacks: Record<string, StackEntry[]>
  active: string
  /** Tabs whose stack has been shown at least once: only those are mounted (state survives a tab switch). */
  visited: string[]
  sheets: SheetEntry[]
  dialog: DialogEntry | null
  toast: ToastEntry | null
  /** Bumped when the active tab is re-selected: its root screen scrolls to top. */
  scrollSignal: number
  /** Bumped whenever a different tab (or a reset) becomes visible: drives the 200 ms cross-fade of the incoming stack. */
  tabEpoch: number
}

type Action =
  | { type: 'push'; entry: StackEntry }
  | { type: 'pop'; count: number }
  | { type: 'replace'; entry: StackEntry }
  | { type: 'reset'; app: AppKind; entry: StackEntry; keys: Record<string, string> }
  | { type: 'switchTab'; tab: string; app: AppKind }
  | { type: 'openSheet'; sheet: SheetEntry }
  | { type: 'closeSheet'; key?: string }
  | { type: 'sheetRemoved'; key: string }
  | { type: 'openDialog'; dialog: DialogEntry }
  | { type: 'closeDialog'; key: string }
  | { type: 'dialogRemoved'; key: string }
  | { type: 'toast'; toast: ToastEntry }
  | { type: 'dismissToast'; key?: string }
  | { type: 'toastRemoved'; key: string }

let uid = 0
const nextKey = (prefix: string) => `${prefix}${++uid}`

function rootEntryFor(tabRoot: string): StackEntry {
  return { key: nextKey('e'), id: tabRoot, params: {} }
}

export function createInitialState(app: AppKind, initial?: string, initialParams: Params = {}, initialTab?: string): NavState {
  const tabs = tabsOf(app)
  const stacks: Record<string, StackEntry[]> = {}
  for (const t of tabs) stacks[t.id] = [rootEntryFor(t.root)]
  const startTab = tabs.find(t => t.id === initialTab) ?? tabs.find(t => t.root === initial) ?? null
  let active: string
  if (startTab) {
    active = startTab.id
    if (initial && initial !== startTab.root) stacks[active] = [...(stacks[active] ?? []), { key: nextKey('e'), id: initial, params: initialParams }]
    else if (initial) stacks[active] = [{ key: nextKey('e'), id: initial, params: initialParams }]
  } else if (initial) {
    active = FLOW
    stacks[FLOW] = [{ key: nextKey('e'), id: initial, params: initialParams }]
  } else {
    active = tabs[0]?.id ?? FLOW
  }
  return { stacks, active, visited: [active], sheets: [], dialog: null, toast: null, scrollSignal: 0, tabEpoch: 0 }
}

function reducer(state: NavState, action: Action): NavState {
  switch (action.type) {
    case 'push': {
      const stack = state.stacks[state.active] ?? []
      return { ...state, stacks: { ...state.stacks, [state.active]: [...stack, action.entry] } }
    }
    case 'pop': {
      const stack = state.stacks[state.active] ?? []
      if (stack.length <= 1) return state
      return { ...state, stacks: { ...state.stacks, [state.active]: stack.slice(0, Math.max(1, stack.length - action.count)) } }
    }
    case 'replace': {
      const stack = state.stacks[state.active] ?? []
      if (stack.length === 0) return { ...state, stacks: { ...state.stacks, [state.active]: [action.entry] } }
      return { ...state, stacks: { ...state.stacks, [state.active]: [...stack.slice(0, -1), action.entry] } }
    }
    case 'reset': {
      const tabs = tabsOf(action.app)
      const stacks: Record<string, StackEntry[]> = {}
      for (const t of tabs) stacks[t.id] = [{ key: action.keys[t.id] ?? nextKey('e'), id: t.root, params: {} }]
      const tab = tabs.find(t => t.root === action.entry.id)
      let active: string
      if (tab) {
        active = tab.id
        stacks[tab.id] = [action.entry]
      } else {
        active = FLOW
        stacks[FLOW] = [action.entry]
      }
      return { ...state, stacks, active, visited: [active], sheets: [], dialog: null, tabEpoch: state.tabEpoch + 1 }
    }
    case 'switchTab': {
      const tab = tabsOf(action.app).find(t => t.id === action.tab)
      if (!tab) return state
      if (state.active === action.tab) {
        const stack = state.stacks[action.tab] ?? []
        const root = stack[0] ?? rootEntryFor(tab.root)
        return { ...state, stacks: { ...state.stacks, [action.tab]: [root] }, scrollSignal: state.scrollSignal + 1 }
      }
      const stacks = { ...state.stacks }
      // Leaving a flow outside the tabs (onboarding) drops it: the tabs are the home from here on.
      if (state.active === FLOW) delete stacks[FLOW]
      return {
        ...state,
        stacks,
        active: action.tab,
        visited: state.visited.includes(action.tab) ? state.visited : [...state.visited, action.tab],
        tabEpoch: state.tabEpoch + 1,
      }
    }
    case 'openSheet':
      return { ...state, sheets: [...state.sheets, action.sheet] }
    case 'closeSheet': {
      const open = state.sheets.filter(s => !s.closing)
      const target = action.key ? open.find(s => s.key === action.key) : open[open.length - 1]
      if (!target) return state
      return { ...state, sheets: state.sheets.map(s => (s.key === target.key ? { ...s, closing: true } : s)) }
    }
    case 'sheetRemoved':
      return { ...state, sheets: state.sheets.filter(s => s.key !== action.key) }
    case 'openDialog':
      return { ...state, dialog: action.dialog }
    case 'closeDialog':
      return state.dialog?.key === action.key ? { ...state, dialog: { ...state.dialog, closing: true } } : state
    case 'dialogRemoved':
      return state.dialog?.key === action.key ? { ...state, dialog: null } : state
    case 'toast':
      return { ...state, toast: action.toast }
    case 'dismissToast':
      if (!state.toast || (action.key && state.toast.key !== action.key)) return state
      return { ...state, toast: { ...state.toast, closing: true } }
    case 'toastRemoved':
      return state.toast?.key === action.key ? { ...state, toast: null } : state
    default:
      return state
  }
}

// ---------------------------------------------------------------- internal context (hosts only)

export type NavInternals = {
  app: AppKind
  state: NavState
  removeSheet: (key: string) => void
  /** The dialog host reports the choice; the promise given to openDialog resolves here. */
  answerDialog: (key: string, result: DialogResult) => void
  removeDialog: (key: string) => void
  removeToast: (key: string) => void
  dismissToast: (key?: string) => void
}

const InternalsContext = createContext<NavInternals | null>(null)

export function useNavInternals(): NavInternals {
  const ctx = useContext(InternalsContext)
  if (!ctx) throw new Error('Nav hosts must be rendered inside <NavProvider>')
  return ctx
}

export type NavProviderProps = {
  app: AppKind
  /** Screen shown first: a tab root enters the tab host, anything else starts a flow outside it (onboarding). */
  initial?: string
  initialParams?: Params
  initialTab?: string
  children: ReactNode
}

export function NavProvider({ app, initial, initialParams, initialTab, children }: NavProviderProps) {
  const [state, dispatch] = useReducer(reducer, undefined, () => createInitialState(app, initial, initialParams, initialTab))
  const resolvers = useRef(new Map<string, (r: DialogResult) => void>())
  const closeCallbacks = useRef(new Map<string, (() => void) | undefined>())
  const appRef = useRef(app)
  appRef.current = app

  const api = useMemo<NavApi>(
    () => ({
      push: (id, params = {}) => dispatch({ type: 'push', entry: { key: nextKey('e'), id, params } }),
      pop: (count = 1) => dispatch({ type: 'pop', count: Math.max(1, count) }),
      replace: (id, params = {}) => dispatch({ type: 'replace', entry: { key: nextKey('e'), id, params } }),
      reset: (id, params = {}) => dispatch({ type: 'reset', app: appRef.current, entry: { key: nextKey('e'), id, params }, keys: {} }),
      switchTab: tabId => dispatch({ type: 'switchTab', tab: tabId, app: appRef.current }),
      openSheet: (content, options = {}) => {
        const key = nextKey('s')
        const sheetContent: SheetContent = typeof content === 'string' ? { kind: 'screen', id: content, params: options.params ?? {} } : { kind: 'node', node: content }
        closeCallbacks.current.set(key, options.onClose)
        dispatch({ type: 'openSheet', sheet: { key, content: sheetContent, options, closing: false } })
        return key
      },
      closeSheet: key => dispatch({ type: 'closeSheet', key }),
      openDialog: spec =>
        new Promise<DialogResult>(resolve => {
          const key = nextKey('d')
          resolvers.current.set(key, resolve)
          dispatch({ type: 'openDialog', dialog: { key, spec, closing: false } })
        }),
      toast: message => {
        const key = nextKey('t')
        dispatch({ type: 'toast', toast: { key, spec: typeof message === 'string' ? { message } : message, closing: false } })
        return key
      },
      dismissToast: key => dispatch({ type: 'dismissToast', key }),
    }),
    [],
  )

  const internals = useMemo<NavInternals>(
    () => ({
      app,
      state,
      removeSheet: key => {
        closeCallbacks.current.get(key)?.()
        closeCallbacks.current.delete(key)
        dispatch({ type: 'sheetRemoved', key })
      },
      answerDialog: (key, result) => {
        resolvers.current.get(key)?.(result)
        resolvers.current.delete(key)
        dispatch({ type: 'closeDialog', key })
      },
      removeDialog: key => {
        resolvers.current.get(key)?.('cancel')
        resolvers.current.delete(key)
        dispatch({ type: 'dialogRemoved', key })
      },
      removeToast: key => dispatch({ type: 'toastRemoved', key }),
      dismissToast: key => dispatch({ type: 'dismissToast', key }),
    }),
    [app, state],
  )

  return (
    <NavApiContext.Provider value={api}>
      <InternalsContext.Provider value={internals}>
        {/* Outside any screen: the shell-level entry (used by hosts that call useNav, e.g. the tab bar). */}
        <EntryContext.Provider value={{ id: '', params: {}, canGoBack: false, activeTab: state.active === FLOW ? null : state.active }}>{children}</EntryContext.Provider>
      </InternalsContext.Provider>
    </NavApiContext.Provider>
  )
}
