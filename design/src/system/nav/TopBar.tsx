// TopBar (direction section 3 and 5): the 56 high bar row under the status bar. Variants:
//   standard       back, centred title (16/24 500), up to two actions; hairline appears once content scrolls under it
//   large-title    row as above, then the screen title (client serif d3, hotel ui-xl) that collapses into the row on scroll
//   transparent    over a photograph: canvas disks 44 on a scrim-top gradient; turns solid (canvas, title, hairline) after the hero
//   search         back + a 48 high search field in the row, actions at the end
// The back chevron is the registry's `back` glyph, mirrored in Arabic by the shared mechanism. The bar includes the safe-top inset.
import { type ReactNode } from 'react'
import { flat, type IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { useAppKind, useDevice, useStatusTone } from '../../shell/device/context'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import { BarButton } from './BarButton'
import { useNav } from './useNav'
import { useScreenScroll } from './screen-context'
import './topbar.css'

export type TopBarAction = {
  icon: IconName
  /** The filled glyph of a toggle (`heart-fill`): with `pressed`, the glyph swaps in place and the pop replays on the change, not on a remount. */
  iconActive?: IconName
  label: string
  onPress?: () => void
  count?: number
  pressed?: boolean
}

export type TopBarSearch = {
  placeholder: string
  /** Controlled value: renders a real input. Without it the field is a button that opens search. */
  value?: string
  onChange?: (value: string) => void
  onPress?: () => void
}

export type TopBarProps = {
  variant?: 'standard' | 'large-title' | 'transparent' | 'search'
  title?: ReactNode
  /** One caption line under a standard title (a venue's area, a booking reference). */
  subtitle?: ReactNode
  /** `auto` shows back when the navigator can go back; `close` shows the close glyph; false hides it. */
  back?: 'auto' | boolean | 'close'
  /** Overrides the navigator's pop. */
  onBack?: () => void
  backLabel?: string
  /** At most two (88 wide); a third would not fit beside a title. */
  actions?: readonly TopBarAction[]
  search?: TopBarSearch
  /** Custom start content instead of the back button (a wordmark, a venue switcher). */
  leading?: ReactNode
  /** transparent: scroll offset after which the bar turns solid. Default = hero height under the bar. */
  solidAfter?: number
  /** transparent: draw it as already solid (gallery, or a screen whose hero is shorter than the bar). */
  solid?: boolean
  /** Hairline under the bar: `auto` = once content scrolls under it. */
  rule?: 'auto' | boolean
  /** Gallery only: force the scrolled state. */
  previewScrolled?: boolean
}

const SLOT_UNIT = flat['size.touch-min']
const COLLAPSE_AT = flat['space.4']

export function TopBar({
  variant = 'standard',
  title,
  subtitle,
  back = 'auto',
  onBack,
  backLabel,
  actions = [],
  search,
  leading,
  solidAfter,
  solid,
  rule = 'auto',
  previewScrolled,
}: TopBarProps) {
  const nav = useNav()
  const app = useAppKind()
  const { lang } = useLang()
  const t = useT('common')
  const { safeTop } = useDevice()
  const { scrollTop } = useScreenScroll()
  const scrolled = previewScrolled ?? scrollTop > 0

  const transparent = variant === 'transparent'
  const heroEnd = (solidAfter ?? flat['layout.hero.venue'] - safeTop - flat['size.control.lg'])
  const isSolid = transparent ? Boolean(solid) || scrollTop >= heroEnd || previewScrolled === true : true
  // Imagery under the status bar wants light chrome until the bar turns solid.
  useStatusTone('light', transparent && !isSolid)

  const showBack = back === 'auto' ? nav.canGoBack : back !== false
  const closeGlyph = back === 'close'
  const handleBack = onBack ?? (() => nav.pop())

  const large = variant === 'large-title'
  const compact = large && scrollTop > COLLAPSE_AT
  const showRule = rule === 'auto' ? scrolled && (!transparent || isSolid) : rule
  const disk = transparent && !isSolid

  const slots = Math.max(showBack || leading ? 1 : 0, actions.length, 1)
  const slotWidth = slots * SLOT_UNIT
  // Icon edge on the 20 gutter: bar padding = gutter - (target - glyph) / 2 = 10.
  const pad = flat['space.gutter'] - (SLOT_UNIT - flat['size.icon.md']) / 2
  // The large title's own height (line height of its role in the current language + 12 below it) drives the collapse tween.
  const largeLine = flat[`type.${lang}.${app === 'client' ? 'd3' : 'ui-xl'}` as 'type.en.d3'].lineHeight
  const largeHeight = largeLine + flat['space.3']

  const backName = backLabel ?? t('commonActionBack')
  const closeName = t('commonActionClose')

  const start = leading ?? (showBack ? <BarButton icon={closeGlyph ? 'close' : 'back'} label={closeGlyph ? closeName : backName} onPress={handleBack} tone={disk ? 'disk' : 'plain'} dataId="bar.back" /> : null)

  return (
    <header
      className={cx('gz-topbar', `gz-topbar--${variant}`, large && compact && 'is-compact', showRule && 'has-rule', transparent && !isSolid && 'is-clear')}
      data-gz="TopBar"
      data-variant={variant}
      data-app={app}
      style={{ ['--gz-topbar-pad' as string]: `${pad}px`, ['--gz-topbar-slot' as string]: `${slotWidth}px`, ['--gz-topbar-large-h' as string]: `${largeHeight}px` }}
    >
      {transparent ? <span className="gz-topbar__scrim" aria-hidden="true" /> : null}
      <div className="gz-topbar__row">
        {variant === 'search' && search ? (
          <>
            <div className="gz-topbar__start gz-topbar__start--auto">{start}</div>
            <SearchField search={search} />
            {actions.length > 0 ? <div className="gz-topbar__end gz-topbar__end--auto">{actions.map(renderAction(disk))}</div> : null}
          </>
        ) : (
          <>
            <div className="gz-topbar__start">{start}</div>
            <div className={cx('gz-topbar__center', large && !compact && 'is-faded', transparent && !isSolid && 'is-faded')}>
              {title ? <h1 className="gz-topbar__title gz-t-title">{title}</h1> : null}
              {subtitle ? <p className="gz-topbar__subtitle gz-t-caption">{subtitle}</p> : null}
            </div>
            <div className="gz-topbar__end">{actions.map(renderAction(disk))}</div>
          </>
        )}
      </div>
      {large && title ? (
        <div className="gz-topbar__large" data-gz-id="bar.largeTitle" aria-hidden={compact || undefined}>
          <h1 className={cx('gz-topbar__large-title', app === 'client' ? 'gz-t-d3' : 'gz-t-ui-xl')}>{title}</h1>
        </div>
      ) : null}
      <span className="gz-topbar__rule" aria-hidden="true" />
    </header>
  )
}

const renderAction = (disk: boolean) => (a: TopBarAction) => (
  <BarButton key={a.icon + a.label} icon={a.icon} iconActive={a.iconActive} label={a.label} onPress={a.onPress} count={a.count} pressed={a.pressed} tone={disk ? 'disk' : 'plain'} />
)

function SearchField({ search }: { search: TopBarSearch }) {
  const body = (
    <>
      <Icon name="search" size="sm" tone="secondary" />
      {search.onChange ? (
        <input
          className="gz-topbar__input gz-t-body gz-auto"
          type="search"
          value={search.value ?? ''}
          placeholder={search.placeholder}
          aria-label={search.placeholder}
          onChange={e => search.onChange?.(e.target.value)}
        />
      ) : (
        <span className={cx('gz-topbar__placeholder gz-t-body', search.value && 'has-value')}>{search.value || search.placeholder}</span>
      )}
    </>
  )
  return search.onChange ? (
    <label className="gz-topbar__search" data-gz-id="bar.search">{body}</label>
  ) : (
    <button type="button" className="gz-reset gz-topbar__search gz-press" data-gz-id="bar.search" aria-label={search.placeholder} onClick={search.onPress}>{body}</button>
  )
}
