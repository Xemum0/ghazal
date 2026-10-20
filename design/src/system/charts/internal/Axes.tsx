// The value axis (labels at the inline-start edge, gridlines in the plot) and the explicit time axis labels, shared by Line and Bar.
// Both are flex boxes: the labels line up with the gridlines because the label column is 16 taller than the plot and centred on the
// two end lines (the same trick in every chart), and the x labels sit in a space-between row so the first label is always at the
// inline-start (right in Arabic) and the last at the inline-end (ADR 0014 D5: every chart labels its first and last date).
import { flat } from '@gz/tokens'

const LABEL_LINE = flat['space.4']
/** The y label column is `plot + LABEL_LINE` tall and the plot starts half a label line down. */
export const AXIS_INSET = LABEL_LINE / 2

export function YAxis({ ticks, format, height }: { ticks: readonly number[]; format: (n: number) => string; height: number }) {
  const top = [...ticks].reverse()
  return (
    <div className="gz-chart-yaxis gz-t-fig-label" style={{ blockSize: height + LABEL_LINE }} aria-hidden="true">
      {top.map((t, i) => (
        <span key={i}>
          <bdi dir="ltr" className="gz-num">
            {format(t)}
          </bdi>
        </span>
      ))}
    </div>
  )
}

export function GridLines({ count = 3 }: { count?: number }) {
  return (
    <div className="gz-chart-grid" aria-hidden="true">
      {Array.from({ length: count }, (_, i) => (
        <i key={i} />
      ))}
    </div>
  )
}

export function XAxis({ labels }: { labels: readonly string[] }) {
  return (
    <div className="gz-chart-xaxis gz-t-caption" aria-hidden="true">
      {labels.map((l, i) => (
        <span key={i}>{l}</span>
      ))}
    </div>
  )
}
