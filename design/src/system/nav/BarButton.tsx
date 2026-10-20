// BarButton: the icon target of a bar or a photo control. A thin wrapper over the core IconButton (44 x 44 target, disk 44) that adds
// the optional gold count (hotel bell, client notifications). `plain` = glyph on the bar; `disk` = canvas disk with the ring-fab
// hairline that floats over photography (direction section 5).
import type { IconName } from '@gz/tokens'
import { CountBadge } from '../core/Badge'
import { IconButton } from '../core/IconButton'
import './barbutton.css'

export type BarButtonProps = {
  icon: IconName
  /** Accessible name; an icon alone is not a name. */
  label: string
  onPress?: () => void
  tone?: 'plain' | 'disk'
  /** Count shown as a small gold badge at the glyph's top inline-end. */
  count?: number
  /** Toggle state (aria-pressed); the filled glyph comes from `iconActive`. */
  pressed?: boolean
  iconActive?: IconName
  disabled?: boolean
  dataId?: string
}

export function BarButton({ icon, iconActive, label, onPress, tone = 'plain', count, pressed, disabled, dataId }: BarButtonProps) {
  return (
    <span className="gz-barbtn" data-gz="BarButton" data-gz-id={dataId}>
      <IconButton
        icon={icon}
        iconActive={iconActive}
        label={label}
        variant={tone === 'disk' ? 'over-image' : 'plain'}
        disk="lg"
        active={pressed}
        disabled={disabled}
        onClick={onPress}
      />
      {count ? (
        <span className="gz-barbtn__count" aria-hidden="true">
          <CountBadge count={count} max={9} ring />
        </span>
      ) : null}
    </span>
  )
}
