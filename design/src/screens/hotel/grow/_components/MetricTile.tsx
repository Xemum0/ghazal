// MetricTile: one number of the listing's performance that can be chosen to drive the main chart. A glyph in a quiet disk, the figure in the
// figures voice and the change against the previous period as a trend glyph and a signed percent: no caption, the name is the accessible name
// (ADR 0034; the legend is the (i) sheet of the screen). Selected = ink border, an ink disk and the gold bead (direction 3, Chip: a thing
// chosen), never a gold fill. The system KpiTile and IconStat are not buttons, so a selectable tile is flow-local (requests.md).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import { Fig } from './bits'
import './metric-tile.css'

export type MetricTileProps = {
  icon: IconName
  /** What it counts: the accessible name, never drawn. */
  label: string
  /** The value, already formatted. */
  figure: string
  /** A quiet fact under the figure (the approved requests). */
  sub?: ReactNode
  /** Change against the previous period: `+12%` already formatted with its sign, its direction and the spoken form. */
  delta?: { text: string; dir: 'up' | 'down' | 'flat'; spoken: string }
  selected?: boolean
  onPress?: () => void
}

export function MetricTile({ icon, label, figure, sub, delta, selected = false, onPress }: MetricTileProps) {
  return (
    <button type="button" className="gz-reset gz-press gm-tile" data-on={selected || undefined} aria-pressed={onPress ? selected : undefined} onClick={onPress} data-gz="MetricTile">
      <span className="gm-tile__disk" aria-hidden="true">
        <Icon name={icon} size="sm" tone={selected ? 'on-dark' : 'primary'} />
      </span>
      {selected ? <span className="gm-tile__bead" aria-hidden="true" /> : null}
      <span className="gz-sr-only">{label}</span>
      <span className="gz-t-fig-xl gm-tile__figure">
        <Fig>{figure}</Fig>
      </span>
      {sub ? <span className="gm-tile__sub">{sub}</span> : null}
      {delta ? (
        <span className="gm-tile__delta gz-t-caption" data-dir={delta.dir} aria-label={delta.spoken}>
          <Icon name={delta.dir === 'up' ? 'trend-up' : delta.dir === 'down' ? 'trend-down' : 'minus'} size="xs" mirror={false} />
          <bdi dir="ltr" className="gz-num">
            {delta.text}
          </bdi>
        </span>
      ) : null}
    </button>
  )
}
