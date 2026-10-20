// Skeleton: the loading placeholder. A static ink-100 shape, no shimmer (direction 5, "Reveal": static placeholder, no shimmer;
// nothing loops). Sizes are px numbers taken from the layout being stood in for. Mark the region `aria-busy` where it sits.
import type { CSSProperties } from 'react'
import { cx } from './cx'
import './skeleton.css'

export type SkeletonProps = {
  /** line = one text line (radius 4), block = card or image (radius 12), circle = avatar or disk. */
  variant?: 'line' | 'block' | 'circle'
  /** Fixed width in px; omit to fill the row. */
  inlineSize?: number
  /** Height in px: a text role's line height for `line`, the image height for `block`, the diameter for `circle`. */
  blockSize?: number
  /** Take the remaining width of a row (next to an avatar or a thumbnail). */
  grow?: boolean
  className?: string
}

export function Skeleton({ variant = 'line', inlineSize, blockSize, grow, className }: SkeletonProps) {
  const style: CSSProperties = {}
  if (inlineSize !== undefined) style.inlineSize = inlineSize
  if (blockSize !== undefined) style.blockSize = blockSize
  else if (variant === 'circle' && inlineSize !== undefined) style.blockSize = inlineSize
  return <span data-gz="Skeleton" data-variant={variant} aria-hidden="true" className={cx('gz-skeleton', `gz-skeleton--${variant}`, inlineSize === undefined && 'gz-skeleton--fill', grow && 'gz-skeleton--grow', className)} style={style} />
}

export type SkeletonTextProps = {
  lines?: number
  /** Last line is shorter, as a paragraph ends. Width in px. */
  lastLine?: number
  className?: string
}

/** A paragraph stand-in: body-line-high rows with a shorter last row. */
export function SkeletonText({ lines = 3, lastLine, className }: SkeletonTextProps) {
  return (
    <span data-gz="SkeletonText" aria-hidden="true" className={cx('gz-skeleton-text', className)}>
      {Array.from({ length: lines }, (_, i) => (
        <Skeleton key={i} variant="line" inlineSize={i === lines - 1 ? lastLine : undefined} />
      ))}
    </span>
  )
}
