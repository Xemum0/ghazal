// The screen inventory (docs/product/screens/{client,hotel}/*.json) as typed data for the Studio. One source: the board, the
// sidebar, the inspector and the player all read this module, so they cannot disagree about what a screen is.
// Read-only: the JSON is owned by the product docs, never edited from here.
import clientIndex from '@docs/product/screens/client/_index.json'
import hotelIndex from '@docs/product/screens/hotel/_index.json'

export type AppId = 'client' | 'hotel'
export type Loc = { en: string; ar: string }
export type ScreenKind = 'screen' | 'sheet' | 'tab-root'
export type Priority = 'core' | 'supporting'

export type ScreenDef = {
  id: string
  slug: string
  title: Loc
  kind: ScreenKind
  purpose: string
  requirementIds: string[]
  states: string[]
  interactions: string[]
  contentNotes: string
  priority: Priority
  navigatesTo: string[]
  app: AppId
  flowId: string
  /** Position inside its flow, 0-based. */
  index: number
}

export type FlowDef = {
  id: string
  app: AppId
  order: number
  title: Loc
  intent: string
  screens: ScreenDef[]
}

type RawScreen = Omit<ScreenDef, 'app' | 'flowId' | 'index' | 'contentNotes'> & { contentNotes?: string }
type RawFlow = { id: string; order: number; title: Loc; intent: string; screens: RawScreen[] }

// Flow files are `NN-<flow>.json`; `_index.json` (no hyphen) is the app index and is imported statically above.
const flowFiles = import.meta.glob('@docs/product/screens/*/*-*.json', { eager: true, import: 'default' }) as Record<string, RawFlow>

type TabInfo = { id: string; title: Loc; rootScreen: string }
type AppIndex = { navigation: { tabs: TabInfo[]; notes: string }; flowOrder: string[]; globalRules: string[] }

const INDEX: Record<AppId, AppIndex> = { client: clientIndex as unknown as AppIndex, hotel: hotelIndex as unknown as AppIndex }

function buildFlows(app: AppId): FlowDef[] {
  const raw: RawFlow[] = Object.entries(flowFiles)
    .filter(([path]) => path.includes(`/screens/${app}/`))
    .map(([, flow]) => flow)
  const order = INDEX[app].flowOrder
  const rank = (id: string) => {
    const i = order.indexOf(id)
    return i === -1 ? order.length : i
  }
  return raw
    .sort((a, b) => rank(a.id) - rank(b.id) || a.order - b.order)
    .map(flow => ({
      id: flow.id,
      app,
      order: flow.order,
      title: flow.title,
      intent: flow.intent,
      screens: flow.screens.map((s, index) => ({ ...s, contentNotes: s.contentNotes ?? '', app, flowId: flow.id, index })),
    }))
}

export const FLOWS: Record<AppId, FlowDef[]> = { client: buildFlows('client'), hotel: buildFlows('hotel') }

export const SCREENS: ScreenDef[] = [...FLOWS.client, ...FLOWS.hotel].flatMap(f => f.screens)
export const SCREEN_BY_ID: ReadonlyMap<string, ScreenDef> = new Map(SCREENS.map(s => [s.id, s]))

export const getScreen = (id: string | null | undefined): ScreenDef | undefined => (id ? SCREEN_BY_ID.get(id.toUpperCase()) : undefined)

/** Who links to this screen (reverse of navigatesTo). */
const incoming = new Map<string, string[]>()
for (const s of SCREENS) {
  for (const t of s.navigatesTo) incoming.set(t, [...(incoming.get(t) ?? []), s.id])
}
export const reachedFrom = (id: string): string[] => incoming.get(id) ?? []

export const tabsOf = (app: AppId): TabInfo[] => INDEX[app].navigation.tabs
export const globalRulesOf = (app: AppId): string[] => INDEX[app].globalRules
export const navigationNotesOf = (app: AppId): string => INDEX[app].navigation.notes

/** The screen the prototype starts on: first screen of the first flow in `flowOrder` (onboarding for clients, access for hotels). */
export const entryScreenOf = (app: AppId): string => FLOWS[app][0]?.screens[0]?.id ?? (app === 'client' ? 'CL-ONBD-01' : 'HL-ACCS-01')

export const appOfId = (id: string): AppId => (id.toUpperCase().startsWith('HL-') ? 'hotel' : 'client')

export const parseApp = (v: string | null | undefined): AppId => (v === 'hotel' ? 'hotel' : 'client')

export const screenCount = (app: AppId): number => FLOWS[app].reduce((n, f) => n + f.screens.length, 0)
