// Avatar: a monogram, never a face (ADR 0015). Rose-100 disk, the initial in the display serif (d1). Sizes 32 / 40 / 56 / 64.
// The hotel app keeps the serif for venue names and the greeting only (direction rule 1), so it passes voice="sans".
import { cx } from './cx'
import './avatar.css'

export type AvatarSize = 'xs' | 'sm' | 'md' | 'lg'

export type AvatarProps = {
  /** The person's or venue's name; the first letter becomes the monogram. */
  name: string
  /** Override the letter (a venue's brand initial, or the second name of a couple). */
  initial?: string
  size?: AvatarSize
  /** `serif` (client, default) = display d1; `sans` (hotel) = UI weight 600. */
  voice?: 'serif' | 'sans'
  className?: string
}

/** First visible character of the first word, upper-cased for Latin; Arabic and other scripts pass through unchanged. */
export const monogramOf = (name: string): string => {
  const first = Array.from(name.trim())[0]
  return first ? first.toUpperCase() : ''
}

export function Avatar({ name, initial, size = 'md', voice = 'serif', className }: AvatarProps) {
  return (
    <span data-gz="Avatar" data-size={size} className={cx('gz-avatar', `gz-avatar--${size}`, `gz-avatar--${voice}`, className)} role="img" aria-label={name}>
      <span className="gz-avatar__initial" aria-hidden="true">
        {initial ?? monogramOf(name)}
      </span>
    </span>
  )
}
