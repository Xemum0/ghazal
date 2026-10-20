// Hatch: a pattern that carries a state by shape, never by colour alone (ADR 0008 D9): gold diagonal hatch = on hold, ink diagonal hatch =
// setup and teardown, ink cross-hatch = blocked. An SVG <pattern> shader filling its positioned parent (Flutter: a CustomPainter shader).
import { useId } from 'react'
import { flat } from '@gz/tokens'
import './hatch.css'

const PITCH = flat['size.chart.pattern-pitch']

export function Hatch({ tone, kind = 'hatch' }: { tone: 'gold' | 'ink'; kind?: 'hatch' | 'cross' }) {
  const id = `${useId().replace(/:/g, '')}h`
  return (
    <svg className={`cal-hatch cal-hatch--${tone}`} aria-hidden="true" focusable="false">
      <defs>
        <pattern id={id} width={PITCH} height={PITCH} patternUnits="userSpaceOnUse" patternTransform={kind === 'hatch' ? 'rotate(45)' : undefined}>
          <rect width={PITCH} height={PITCH} className="cal-hatch__bg" />
          {kind === 'hatch' ? (
            <line x1="0" y1="0" x2="0" y2={PITCH} className="cal-hatch__ink" strokeWidth={flat['stroke.thread']} />
          ) : (
            <path d={`M0 0L${PITCH} ${PITCH}M${PITCH} 0L0 ${PITCH}`} className="cal-hatch__ink" strokeWidth={flat['stroke.hair']} />
          )}
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#${id})`} />
    </svg>
  )
}
