import type { IconName } from '@gz/tokens'
import { Icon } from '../../core/Icon'

export type GlyphSize = 'xs' | 'sm' | 'md'

/** The inputs' icon: the shared Icon (mirror registry, size tokens), decorative. The control that owns it carries the name. */
export function Glyph({ name, size = 'sm', className }: { name: IconName; size?: GlyphSize; className?: string }) {
  return <Icon name={name} size={size} className={className} />
}

/** The OS-style activity indicator (the only looping element in the system, ADR 0030 "Pending"). Static under reduced motion. */
export function Activity({ className }: { className?: string }) {
  return <span className={className ? `gz-in-activity ${className}` : 'gz-in-activity'} role="presentation" />
}
