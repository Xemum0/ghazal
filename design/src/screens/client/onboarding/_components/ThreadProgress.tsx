// ThreadProgress (flow-local): the 2 px thread that tells the couple where they are in onboarding. A gold line fills in reading
// direction, ends in the 8 px bead, and the rest of the line stays a hairline track. Used for the three intro slides (CL-ONBD-02)
// and the four profile steps (CL-ONBD-03 to 06). Flex ratios only (no widths, no calc), so it mirrors with `dir` for free.
import { cx } from './cx'
import './thread-progress.css'

export type ThreadProgressProps = {
  /** Number of stops (3 slides, 4 steps). */
  count: number
  /** Zero-based current stop; the line is filled up to and including it. */
  index: number
  /** Spoken name: "Step 2 of 4". */
  label: string
  className?: string
}

export function ThreadProgress({ count, index, label, className }: ThreadProgressProps) {
  const done = Math.min(Math.max(index + 1, 0), count)
  return (
    <div
      className={cx('obd-thread', className)}
      role="progressbar"
      aria-label={label}
      aria-valuemin={1}
      aria-valuemax={count}
      aria-valuenow={done}
    >
      <span className="obd-thread__fill" style={{ flexGrow: done }} />
      <span className="obd-thread__bead" />
      <span className="obd-thread__rest" style={{ flexGrow: Math.max(count - done, 0) }} />
    </div>
  )
}
