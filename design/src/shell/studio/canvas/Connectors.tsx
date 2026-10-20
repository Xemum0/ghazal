// Prototype arrows from the inventory's navigatesTo. Two SVG layers: the quiet base (under the frames) and the active one (over them)
// holding the arrows that touch the selected frame, so the selection reads at a glance. Strokes are non-scaling (constant screen
// width at any zoom); arrow heads and source dots are scaled by --gzs-ui-inv so they keep their on-screen size too.
import { memo } from 'react'
import type { Connector } from './layout'

function Arrow({ c }: { c: Connector }) {
  return (
    <g className="gzs-conn__end" transform={`translate(${c.tip.x} ${c.tip.y}) rotate(${c.tip.deg})`}>
      <path className="gzs-conn__head" d="M-11 -6 L0 0 L-11 6" />
    </g>
  )
}

function Line({ c, active }: { c: Connector; active: boolean }) {
  return (
    <g className="gzs-conn" data-kind={c.kind} data-active={active || undefined}>
      <path className="gzs-conn__line" d={c.d} vectorEffect="non-scaling-stroke" />
      <g transform={`translate(${c.start.x} ${c.start.y})`}>
        <circle className="gzs-conn__dot" r="4" />
      </g>
      <Arrow c={c} />
    </g>
  )
}

export const Connectors = memo(function Connectors({
  connectors,
  selected,
  width,
  height,
  layer,
}: {
  connectors: Connector[]
  selected: string | null
  width: number
  height: number
  layer: 'base' | 'active'
}) {
  const touches = (c: Connector) => selected !== null && (c.from === selected || c.to === selected)
  // The selected frame's own arrows are drawn over the frames; a long cross-flow curve stays under them (it would otherwise cut
  // through the content of every frame it passes) but takes the active style.
  const above = (c: Connector) => touches(c) && c.kind !== 'cross'
  const list = connectors.filter(c => (layer === 'active' ? above(c) : !above(c)))
  return (
    <svg className="gzs-conns" data-ui-scope data-layer={layer} width={width} height={height} viewBox={`0 0 ${width} ${height}`} aria-hidden="true">
      {list.map(c => (
        <Line key={c.id} c={c} active={touches(c)} />
      ))}
      {layer === 'active'
        ? connectors
            .filter(c => c.kind === 'cross' && touches(c))
            .map(c => (
              <text key={`${c.id}:label`} className="gzs-conn__label" x={c.mid.x} y={c.mid.y} textAnchor="middle" dominantBaseline="middle">
                {c.from} {'>'} {c.to}
              </text>
            ))
        : null}
    </svg>
  )
})
