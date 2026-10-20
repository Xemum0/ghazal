// Barrel for system/nav: the navigator contract (useNav), the live host (NavRoot), the screen scaffold and the bars.
// Owner: device-framework-owner. Screens import from '../../system' (the top barrel re-exports this).
export { useNav, INERT_NAV } from './useNav'
export type { Nav, NavApi, Params, SheetOptions, DialogSpec, DialogResult, ToastSpec } from './types'
export { NavProvider, type NavProviderProps } from './NavProvider'
export { NavRoot, type NavRootProps } from './NavRoot'
export { ScreenOutlet, NotBuilt, ScreenOverridesContext, type ScreenComponent } from './ScreenOutlet'
export { Screen, type ScreenProps } from './Screen'
export { TopBar, type TopBarProps, type TopBarAction, type TopBarSearch } from './TopBar'
export { BarButton, type BarButtonProps } from './BarButton'
export { TabBar, AppTabBar, useAppTabItems, type TabBarProps, type TabBarItem, type TabBarBadge, type AppTabBarProps } from './TabBar'
export { ActionBar, type ActionBarProps, type ActionBarAction } from './ActionBar'
export { useTabBadges } from './useTabBadges'
export { CLIENT_TABS, HOTEL_TABS, tabsOf, chromeFor, isSheetScreen, isTabRoot, appOfScreen, type TabDef, type ScreenChrome } from './tabs'
