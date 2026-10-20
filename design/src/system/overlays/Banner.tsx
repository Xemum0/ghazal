// Banner (offline / info / warning / danger): a state line that sits under the TopBar or at the top of a section. State is carried by
// icon + text + tone together, never colour alone. No gold: a banner is not the verb (direction 2.3), so warning is the rose-100
// quiet panel with an ink glyph and danger is the functional danger tint. `flush` runs edge to edge under a bar (the offline strip);
// `card` is a radius-8 block inside the gutters.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { Button } from '../core/Button'
import { Icon } from '../core/Icon'
import { BarButton } from '../nav/BarButton'
import { cx } from '../core/cx'
import './banner.css'

export type BannerTone = 'info' | 'offline' | 'warning' | 'danger'

const TONE_ICON: Record<BannerTone, IconName> = {
  info: 'info',
  offline: 'offline',
  warning: 'warning',
  danger: 'warning-circle',
}

export type BannerProps = {
  tone?: BannerTone
  children: ReactNode
  /** An optional action (Try again, Learn more): a tertiary button at inline-end. */
  action?: { label: string; onPress?: () => void }
  /** Show a close control (an informational banner the user may dismiss). */
  onDismiss?: () => void
  /** `flush` = full-bleed strip (offline); `card` = inside the gutters, radius 8. Default: flush for offline, card otherwise. */
  shape?: 'flush' | 'card'
  icon?: IconName
}

export function Banner({ tone = 'info', children, action, onDismiss, shape, icon }: BannerProps) {
  const t = useT('common')
  const form = shape ?? (tone === 'offline' ? 'flush' : 'card')
  return (
    <div
      className={cx('gz-banner', `gz-banner--${tone}`, `gz-banner--${form}`)}
      data-gz="Banner"
      data-tone={tone}
      role={tone === 'danger' || tone === 'offline' ? 'alert' : 'status'}
    >
      <Icon name={icon ?? TONE_ICON[tone]} size="sm" className="gz-banner__icon" />
      <p className="gz-banner__text gz-t-body-s">{children}</p>
      {action ? (
        <Button variant="tertiary" onClick={action.onPress}>
          {action.label}
        </Button>
      ) : null}
      {onDismiss ? <BarButton icon="close" label={t('commonActionClose')} onPress={onDismiss} /> : null}
    </div>
  )
}
