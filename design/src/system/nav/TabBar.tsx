// TabBar (direction section 3): canvas with a 1 px ink-200 top rule, never ink. Five items, icon + label always visible,
// active = ink-900 label, regular-weight glyph and a 24 x 2 gold khayt on the top edge that slides between items (320 ms,
// direction-aware); inactive = ink-600. Count badge 20 gold with a 2 px canvas ring (danger only for SLA danger, ADR 0008 D2).
// Height 56 + the home-indicator inset. Order mirrors in RTL by logical flow; the first tab is always at inline-start.
import { useMemo } from 'react'
import { flat, type IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { useDevice, type AppKind } from '../../shell/device/context'
import { CountBadge } from '../core/Badge'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import { tabsOf } from './tabs'
import './tabbar.css'

export type TabBarBadge =
  | { count: number; /** Cap shown as `9+` (hotel Bookings, ADR 0008 D2). Default 9. */ max?: number; tone?: 'gold' | 'danger'; label?: string }
  /** A dot without a number: My Wedding when an action is due (ADR 0007 D4). */
  | { dot: true; label?: string }

export type TabBarItem = {
  id: string
  label: string
  icon: IconName
  badge?: TabBarBadge | null
}

export type TabBarProps = {
  items: readonly TabBarItem[]
  activeId: string
  onSelect?: (id: string) => void
  ariaLabel: string
  /** Gallery only: draw the pressed state on one item. */
  previewPressed?: string
}

const BADGE_CAP = 9

function BadgeView({ badge }: { badge: TabBarBadge }) {
  if ('dot' in badge) return <span className="gz-tabbar__dot" data-gz-id="tab.badge" aria-hidden="true" />
  return (
    <span className="gz-tabbar__badge" data-gz-id="tab.badge" aria-hidden="true">
      <CountBadge count={badge.count} max={badge.max ?? BADGE_CAP} tone={badge.tone ?? 'gold'} ring />
    </span>
  )
}

export function TabBar({ items, activeId, onSelect, ariaLabel, previewPressed }: TabBarProps) {
  const { width } = useDevice()
  const { isRtl } = useLang()
  const index = Math.max(0, items.findIndex(i => i.id === activeId))
  // Formula, not a measurement: item width = frame width / item count; the khayt travels index x item width toward inline-end.
  const itemWidth = width / items.length
  const shift = Math.round(index * itemWidth) * (isRtl ? -1 : 1)
  // Centre the 24 px khayt in its item: its start offset is (item - khayt) / 2.
  const khaytOffset = Math.round((itemWidth - flat['size.khayt.width']) / 2)

  return (
    <nav className="gz-tabbar" data-gz="TabBar" aria-label={ariaLabel}>
      <span
        className="gz-tabbar__khayt gz-thread-slide"
        data-gz-id="tab.khayt"
        aria-hidden="true"
        style={{ marginInlineStart: khaytOffset, transform: `translateX(${shift}px)` }}
      />
      <ul className="gz-tabbar__row">
        {items.map(item => {
          const active = item.id === activeId
          const badgeLabel = item.badge?.label
          return (
            <li className="gz-tabbar__cell" key={item.id}>
              <button
                type="button"
                className={cx('gz-reset gz-tabbar__item gz-press', active && 'is-active', previewPressed === item.id && 'is-pressed')}
                data-gz-id={`tab.${item.id}`}
                aria-current={active ? 'page' : undefined}
                aria-label={badgeLabel ? `${item.label}, ${badgeLabel}` : undefined}
                onClick={() => onSelect?.(item.id)}
              >
                <span className="gz-tabbar__glyph">
                  <Icon name={item.icon} weight={active ? 'regular' : 'light'} />
                  {item.badge ? <BadgeView badge={item.badge} /> : null}
                </span>
                <span className="gz-tabbar__label gz-t-tab">{item.label}</span>
              </button>
            </li>
          )
        })}
      </ul>
    </nav>
  )
}

/** Tab items of one app with catalog labels: the single place the five labels and icons are joined. */
export function useAppTabItems(app: AppKind, badges: Partial<Record<string, TabBarBadge | null>> = {}): TabBarItem[] {
  const tClient = useT('client-shell')
  const tHotel = useT('hotel-shell')
  return useMemo(
    () =>
      tabsOf(app).map(def => ({
        id: def.id,
        icon: def.icon,
        label: app === 'client' ? tClient(def.labelKey as Parameters<typeof tClient>[0]) : tHotel(def.labelKey as Parameters<typeof tHotel>[0]),
        badge: badges[def.id] ?? null,
      })),
    [app, tClient, tHotel, badges],
  )
}

export type AppTabBarProps = {
  app: AppKind
  activeId: string
  onSelect?: (id: string) => void
  badges?: Partial<Record<string, TabBarBadge | null>>
  previewPressed?: string
}

/** The client or hotel tab bar with its labelled items. */
export function AppTabBar({ app, activeId, onSelect, badges, previewPressed }: AppTabBarProps) {
  const items = useAppTabItems(app, badges)
  const tClient = useT('client-shell')
  const tHotel = useT('hotel-shell')
  const ariaLabel = app === 'client' ? tClient('clientShellTabBarLabel') : tHotel('hotelShellTabBarLabel')
  return <TabBar items={items} activeId={activeId} onSelect={onSelect} ariaLabel={ariaLabel} previewPressed={previewPressed} />
}
