// StatTile: one count of the month as a hairline panel: a glyph in its tint disk, the figure, an optional second fact at inline-end and an
// optional unit. No caption: the glyph names it and the label is read (docs/design/02-text-diet.md, IconStat). Counts only, never money
// (ADR 0033). The panel is a button when it opens Bookings or the Calendar filtered to it.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../../../i18n'
import { IconStat } from '../../../../system'
import './stat-tile.css'

export function StatTile({
  icon,
  value,
  label,
  unit,
  aside,
  hero = false,
  onPress,
}: {
  icon: IconName
  value: number
  /** What it counts: read by assistive technology, not shown. */
  label: string
  /** A quiet unit after the figure (`30 d`). */
  unit?: ReactNode
  /** A second fact at inline-end (the vouchers redeemed beside the requests). */
  aside?: ReactNode
  hero?: boolean
  onPress?: () => void
}) {
  const f = useFormat()
  const body = (
    <>
      <IconStat icon={icon} value={f.integer(value)} unit={unit} label={label} layout="inline" />
      {aside ? <span className="ht-tile__aside">{aside}</span> : null}
    </>
  )
  const cls = `ht-tile${hero ? ' ht-tile--hero' : ''}${onPress ? ' ht-tile--press gz-press' : ''}`
  return onPress ? (
    <button type="button" className={`gz-reset ${cls}`} onClick={onPress}>
      {body}
    </button>
  ) : (
    <div className={cls}>{body}</div>
  )
}
