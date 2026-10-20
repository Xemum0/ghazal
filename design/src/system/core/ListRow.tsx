// ListRow (direction section 3): min 64 (queue row 80), a 1 px ink-200 rule under it, title 16/24 500 (AR 17/28), caption sub-line,
// a leading slot, a trailing slot, and a disclosure chevron that mirrors in Arabic. The row pads itself with the gutter (20) so
// a pressed row fills edge to edge; pass `flush` inside a panel that already pads.
import type { ReactNode } from 'react'
import { cx } from './cx'
import { Icon } from './Icon'
import './core.css'
import './list-row.css'

export type ListRowProps = {
  title: ReactNode
  subtitle?: ReactNode
  /** Icon in a disk, avatar, thumbnail: anything up to 64 square. */
  leading?: ReactNode
  /** Amount, time, status pill, switch: sits at inline-end, before the chevron. */
  trailing?: ReactNode
  /** Disclosure chevron (chevron-right, mirrored in RTL by the icon registry). */
  chevron?: boolean
  size?: 'md' | 'queue'
  /** Makes the row a button. */
  onClick?: () => void
  selected?: boolean
  tone?: 'default' | 'danger'
  /** Titles that are names (people, venues) align by their own first strong character (ADR 0014 D8). */
  autoDir?: boolean
  /** No own gutter and no bottom rule's inset: for rows inside a panel. */
  flush?: boolean
  /** Hide the bottom rule (last row of a group). */
  last?: boolean
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function ListRow({ title, subtitle, leading, trailing, chevron = false, size = 'md', onClick, selected, tone = 'default', autoDir = false, flush = false, last = false, previewState, className }: ListRowProps) {
  const interactive = Boolean(onClick)
  const classes = cx(
    'gz-row',
    `gz-row--${size}`,
    tone === 'danger' && 'gz-row--danger',
    interactive && 'gz-row--interactive gz-reset',
    selected && 'is-selected',
    flush && 'gz-row--flush',
    last && 'gz-row--last',
    previewState === 'pressed' && 'is-pressed',
    previewState === 'focus' && 'is-focus',
    className,
  )
  const body = (
    <>
      {leading ? <span className="gz-row__leading">{leading}</span> : null}
      <span className="gz-row__text">
        <span className="gz-row__title gz-t-title">{autoDir ? <bdi dir="auto">{title}</bdi> : title}</span>
        {subtitle ? <span className="gz-row__sub gz-t-caption">{subtitle}</span> : null}
      </span>
      {trailing ? <span className="gz-row__trailing gz-t-body-s">{trailing}</span> : null}
      {chevron ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
    </>
  )
  if (interactive) {
    return (
      <button type="button" data-gz="ListRow" aria-current={selected || undefined} onClick={onClick} className={classes}>
        {body}
      </button>
    )
  }
  return (
    <div data-gz="ListRow" aria-current={selected || undefined} className={classes}>
      {body}
    </div>
  )
}
