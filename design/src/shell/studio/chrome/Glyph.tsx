// Studio-only glyphs: tool symbols the product registry has no use for (grid overlay, layout boxes, fit, panels). Same drawing
// rules as the registry: 24 grid, 1.5 stroke, round caps and joins, currentColor. Decorative unless a label is given.
import type { CSSProperties } from 'react'

const PATHS = {
  grid: 'M4 4h16v16H4zM4 9.33h16M4 14.67h16M9.33 4v16M14.67 4v16',
  boxes: 'M3.5 5.5h17v13h-17zM7.5 9.5h9v5h-9z',
  fit: 'M4 9V5.5A1.5 1.5 0 0 1 5.5 4H9M15 4h3.5A1.5 1.5 0 0 1 20 5.5V9M20 15v3.5a1.5 1.5 0 0 1-1.5 1.5H15M9 20H5.5A1.5 1.5 0 0 1 4 18.5V15M9 12h6',
  sidebar: 'M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5zM9.5 4v16',
  panel: 'M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5zM14.5 4v16',
  motion: 'M4 12h3M17 12h3M9 7.5 7 12l2 4.5M15 7.5 17 12l-2 4.5M12 5v14',
  hand: 'M9 11V6.5a1.5 1.5 0 0 1 3 0V10M12 10V5a1.5 1.5 0 0 1 3 0v5M15 10V6.5a1.5 1.5 0 0 1 3 0V14a6 6 0 0 1-6 6h-1a6 6 0 0 1-4.8-2.4L4.5 14.5a1.6 1.6 0 0 1 2.5-2L9 14.5V11',
  restart: 'M5 12a7 7 0 1 0 2.2-5.1M5 5v4h4',
  database: 'M5 6c0-1.1 3.1-2 7-2s7 .9 7 2-3.1 2-7 2-7-.9-7-2zM5 6v6c0 1.1 3.1 2 7 2s7-.9 7-2V6M5 12v6c0 1.1 3.1 2 7 2s7-.9 7-2v-6',
  flow: 'M5 7h6M5 12h14M13 17h6M5 17h3',
  tap: 'M12 3v5M5.6 5.6l3.5 3.5M18.4 5.6l-3.5 3.5M3 12h5M16 12h5M12 14l-1 7 3-2 2 3 1-9z',
  book: 'M5 5.5A1.5 1.5 0 0 1 6.5 4H19v14H6.5A1.5 1.5 0 0 0 5 19.5zM5 19.5A1.5 1.5 0 0 0 6.5 21H19M9 8h6',
  swatch: 'M4 14.5 9.5 9l5.5 5.5-6 6A2.1 2.1 0 0 1 6 20.5zM9.5 9 7 6.5 9.5 4 14 8.5M17 15.5a2 2 0 1 0 4 0c0-1.2-2-3.5-2-3.5s-2 2.3-2 3.5z',
  layers: 'm12 4 8.5 4.5L12 13 3.5 8.5zM3.5 12 12 16.5 20.5 12M3.5 15.5 12 20l8.5-4.5',
  keyboard: 'M3.5 7h17v10h-17zM7 10.5h.01M10 10.5h.01M13 10.5h.01M16 10.5h.01M8 14h8',
} as const

export type GlyphName = keyof typeof PATHS

export function Glyph({ name, size = 20, label, className, style }: { name: GlyphName; size?: 16 | 20 | 24; label?: string; className?: string; style?: CSSProperties }) {
  return (
    <svg
      className={className ? `gzs-glyph ${className}` : 'gzs-glyph'}
      style={style}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      focusable="false"
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <path d={PATHS[name]} />
    </svg>
  )
}
