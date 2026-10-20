// ChipRow: a chip group named by a glyph instead of a label (ADR 0034: the field label is the accessible name of the group, the glyph is
// what the eye reads). The glyph sits at inline-start, on the first line of chips; the chips wrap beside it.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import './chip-row.css'

export function ChipRow({ icon, children }: { icon: IconName; children: ReactNode }) {
  return (
    <div className="cal-crow" data-gz="ChipRow">
      <span className="cal-crow__ico" aria-hidden="true">
        <Icon name={icon} size="md" tone="secondary" />
      </span>
      <div className="cal-crow__chips">{children}</div>
    </div>
  )
}
