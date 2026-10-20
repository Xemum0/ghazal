// Wordmark: the master lockup (ADR 0030 D10, direction section 7). Newsreader "Ghazal" and Amiri "غزل" on a shared baseline, a gold-500
// thread running along that baseline and ending in a knot. Brand marks never mirror (ADR 0014), so the lockup is always LTR: Latin
// first, then Arabic, in both languages. The line draws on once at session start (900 ms) when `draw` is set.
// Sizes: sm 24 (Latin weight 400, the minimum), md 28 (the top-bar mark), lg 40, xl 60 (Latin weight 300). Never recolour the
// thread, never put it above the letters, keep a clear space of 0.75 cap-height.
import type { CSSProperties } from 'react'
import { flat } from '@gz/tokens'
import { cx } from '../core/cx'
import './wordmark.css'

export type WordmarkSize = 'sm' | 'md' | 'lg' | 'xl'
export type WordmarkScript = 'both' | 'latin' | 'arabic'

export type WordmarkProps = {
  size?: WordmarkSize
  /** `both` is the master lockup; `latin` or `arabic` is the single-script form (splash, headers that already carry the other script). */
  script?: WordmarkScript
  /** On an ink panel: letters in canvas. The thread stays gold-500, never recoloured. */
  onDark?: boolean
  /** Draw the thread on once (session start only). */
  draw?: boolean
  className?: string
}

const DRAW = flat['motion.duration.wordmark']

export function Wordmark({ size = 'md', script = 'both', onDark = false, draw = false, className }: WordmarkProps) {
  const knotDelay = { '--gz-delay': `${DRAW}ms` } as CSSProperties
  return (
    <span
      data-gz="Wordmark"
      data-size={size}
      dir="ltr"
      role="img"
      aria-label="Ghazal غزل"
      className={cx('gz-wordmark', `gz-wordmark--${size}`, `gz-wordmark--${script}`, onDark && 'gz-on-dark', className)}
    >
      <span className="gz-wordmark__thread" aria-hidden="true">
        <span className={cx('gz-wordmark__line', draw && 'gz-wordmark-draw')} />
        <span className={cx('gz-wordmark__knot', draw && 'gz-fade-in')} style={draw ? knotDelay : undefined} />
      </span>
      {script !== 'arabic' ? (
        <span lang="en" aria-hidden="true" className="gz-wordmark__latin">
          Ghazal
        </span>
      ) : null}
      {script !== 'latin' ? (
        <span lang="ar" aria-hidden="true" className="gz-wordmark__arabic">
          غزل
        </span>
      ) : null}
    </span>
  )
}
