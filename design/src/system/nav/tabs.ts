// The two tab sets (ADR 0007 D1: client Discover, Saved, My Wedding, Messages, Profile; ADR 0008 D1: hotel Today, Bookings,
// Calendar, Messages, More). Root screen ids come from the screen inventory (docs/product/screens/*/_index.json), so the
// navigator and the inventory cannot drift; labels come from the i18n catalog; icons from the registry.
import type { IconName } from '@gz/tokens'
import clientIndex from '@docs/product/screens/client/_index.json'
import hotelIndex from '@docs/product/screens/hotel/_index.json'
import type { AppKind } from '../../shell/device/context'

export type TabDef = {
  id: string
  /** Inventory id of the tab root, e.g. CL-DISC-01. */
  root: string
  icon: IconName
  /** i18n key in client-shell / hotel-shell. */
  labelKey: string
}

type InventoryTab = { id: string; rootScreen: string }
const rootOf = (tabs: InventoryTab[], id: string, fallback: string): string => tabs.find(t => t.id === id)?.rootScreen ?? fallback

const clientTabs = (clientIndex as { navigation: { tabs: InventoryTab[] } }).navigation.tabs
const hotelTabs = (hotelIndex as { navigation: { tabs: InventoryTab[] } }).navigation.tabs

export const CLIENT_TABS: readonly TabDef[] = [
  { id: 'discover', root: rootOf(clientTabs, 'discover', 'CL-DISC-01'), icon: 'search', labelKey: 'clientShellTabDiscover' },
  { id: 'saved', root: rootOf(clientTabs, 'saved', 'CL-SAVD-01'), icon: 'heart', labelKey: 'clientShellTabSaved' },
  { id: 'my-wedding', root: rootOf(clientTabs, 'my-wedding', 'CL-WEDD-01'), icon: 'calendar-check', labelKey: 'clientShellTabMyWedding' },
  { id: 'messages', root: rootOf(clientTabs, 'messages', 'CL-MSGS-01'), icon: 'chat', labelKey: 'clientShellTabMessages' },
  { id: 'profile', root: rootOf(clientTabs, 'profile', 'CL-PROF-01'), icon: 'user', labelKey: 'clientShellTabProfile' },
]

export const HOTEL_TABS: readonly TabDef[] = [
  { id: 'today', root: rootOf(hotelTabs, 'today', 'HL-TODY-01'), icon: 'home', labelKey: 'hotelShellTabToday' },
  { id: 'bookings', root: rootOf(hotelTabs, 'bookings', 'HL-BOOK-01'), icon: 'clipboard', labelKey: 'hotelShellTabBookings' },
  { id: 'calendar', root: rootOf(hotelTabs, 'calendar', 'HL-CALN-01'), icon: 'calendar', labelKey: 'hotelShellTabCalendar' },
  { id: 'messages', root: rootOf(hotelTabs, 'messages', 'HL-TODY-04'), icon: 'chat', labelKey: 'hotelShellTabMessages' },
  { id: 'more', root: rootOf(hotelTabs, 'more', 'HL-SETT-01'), icon: 'more', labelKey: 'hotelShellTabMore' },
]

export const tabsOf = (app: AppKind): readonly TabDef[] => (app === 'client' ? CLIENT_TABS : HOTEL_TABS)

// ---------------------------------------------------------------- screen chrome from the inventory id

export const appOfScreen = (id: string): AppKind => (id.startsWith('HL-') ? 'hotel' : 'client')

/** `CL-BOOK-05` -> `BOOK`. */
const flowOf = (id: string): string => id.split('-')[1] ?? ''

/** Flow code -> tab a screen of that flow belongs to (null: the flow lives outside the tabs). */
const CLIENT_FLOW_TAB: Record<string, string | null> = {
  ONBD: null,
  AUTH: null,
  DISC: 'discover',
  VENU: 'discover',
  SERV: 'discover',
  SAVD: 'saved',
  BOOK: 'discover',
  PAYM: 'discover',
  BKNG: 'my-wedding',
  WEDD: 'my-wedding',
  PLAN: 'my-wedding',
  MSGS: 'messages',
  RVRW: 'profile',
  PROF: 'profile',
  VCHR: 'profile',
  VIST: 'messages',
}

const HOTEL_FLOW_TAB: Record<string, string | null> = {
  ACCS: null,
  TODY: 'today',
  BOOK: 'bookings',
  DCSN: 'bookings',
  CALN: 'calendar',
  VENU: 'more',
  GROW: 'more',
  SETT: 'more',
  VIST: 'bookings',
  PROV: 'more',
}

/**
 * Where the tab bar is hidden (ADR 0007 D6, ADR 0008 notes, direction section 9). Whole flows first, then single screens:
 * client onboarding, auth, booking flow, payment, full-screen map (DISC-05), gallery viewer (VENU-02), compare table (SAVD-04),
 * chat composer (MSGS-02), and the detail pages whose CTA bar replaces the tab bar (venue VENU-01, government hall VENU-06, vendor SERV-03); hotel access, chat composer (TODY-05)
 * and the two offer-stepper screens.
 */
const HIDDEN_FLOWS = new Set(['CL-ONBD', 'CL-AUTH', 'CL-BOOK', 'CL-PAYM', 'HL-ACCS'])
const HIDDEN_SCREENS = new Set(['CL-DISC-05', 'CL-VENU-01', 'CL-VENU-02', 'CL-VENU-06', 'CL-SERV-03', 'CL-SAVD-04', 'CL-MSGS-02', 'CL-PLAN-02', 'CL-RVRW-02', 'CL-PROF-06', 'HL-TODY-05', 'HL-GROW-02', 'HL-GROW-03', 'HL-BOOK-06'])

export type ScreenChrome = {
  app: AppKind
  /** The tab this screen belongs to, or null for flows outside the tabs. */
  tab: string | null
  tabBar: boolean
}

export function chromeFor(id: string): ScreenChrome {
  const app = appOfScreen(id)
  const flow = flowOf(id)
  const tab = (app === 'client' ? CLIENT_FLOW_TAB : HOTEL_FLOW_TAB)[flow] ?? null
  const prefix = id.split('-').slice(0, 2).join('-')
  let owner = tab
  // The Messages tab root lives in the hotel Today flow (HL-TODY-04), and so does its composer.
  if (id === 'HL-TODY-04' || id === 'HL-TODY-05') owner = 'messages'
  const hidden = HIDDEN_FLOWS.has(prefix) || HIDDEN_SCREENS.has(id) || owner === null
  return { app, tab: owner, tabBar: !hidden }
}

// ---------------------------------------------------------------- sheets

/**
 * Inventory screens whose `kind` is `sheet` (docs/product/screens/*): they open over a screen instead of being pushed, so a static
 * frame draws them inside the Sheet container on the modal scrim. derived from the inventory (non-deprecated `kind: sheet`; 30 ids at the voucher pivot), checked in the nav gallery page.
 */
export const SHEET_SCREENS: ReadonlySet<string> = new Set([
  'CL-AUTH-01', 'CL-DISC-02', 'CL-DISC-04', 'CL-DISC-06', 'CL-VENU-03', 'CL-VENU-04', 'CL-VENU-05', 'CL-SAVD-02',
  'CL-SAVD-03', 'CL-BOOK-07', 'CL-BKNG-03', 'CL-BKNG-04', 'CL-WEDD-04', 'CL-WEDD-05', 'CL-PLAN-04', 'CL-SERV-04',
  'CL-MSGS-03', 'CL-VCHR-01', 'CL-VCHR-04', 'CL-VCHR-05', 'CL-VIST-01', 'CL-VIST-05', 'HL-BOOK-04', 'HL-BOOK-07',
  'HL-DCSN-01', 'HL-DCSN-02', 'HL-DCSN-03', 'HL-DCSN-04', 'HL-CALN-04', 'HL-VIST-04',
])

export const isSheetScreen = (id: string): boolean => SHEET_SCREENS.has(id)

/** True for the root screen of a tab (no back button, tab bar visible). */
export const isTabRoot = (id: string): boolean => [...CLIENT_TABS, ...HOTEL_TABS].some(t => t.root === id)
