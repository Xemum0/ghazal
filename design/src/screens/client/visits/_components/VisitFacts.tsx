// VisitFacts (visits): the three facts of one visit as icon + value, no labels (ADR 0034 section 2): the day, the arrival window and how
// many people come. The label of each fact is its accessible name. `compact` drops the weekday (list rows); `accent` gives the glyphs the
// gold-700 tone (a proposed time). Used by the summary, the pinned card, the list rows and the sheets.
import { FactChip, FactRow, type FactTone } from '../../../../system'
import { useV } from './model'

export type VisitFactsProps = {
  slotStart: string
  slotEnd: string
  visitors?: number
  /** Day without the weekday: `14 Nov`. */
  compact?: boolean
  tone?: FactTone
  /** The glyph of the day fact (a proposed time uses `calendar-dots`). */
  dayIcon?: 'calendar' | 'calendar-dots'
  /** Show only the start time (`5:00 PM`) instead of the whole window. */
  startOnly?: boolean
  className?: string
}

export function VisitFacts({ slotStart, slotEnd, visitors, compact = false, tone = 'default', dayIcon = 'calendar', startOnly = false, className }: VisitFactsProps) {
  const { t, f, dayLine, dayNum, windowParts, clockParts } = useV()
  const win = windowParts(slotStart, slotEnd)
  const start = clockParts(slotStart)
  return (
    <FactRow className={className}>
      <FactChip icon={dayIcon} tone={tone} label={t('clientVisitsFactDay')} value={compact ? dayNum(slotStart) : dayLine(slotStart)} />
      <FactChip icon="clock" tone={tone} label={t('clientVisitsFactWindow')} value={startOnly ? start.hm : win.range} unit={startOnly ? start.mer : win.mer} />
      {visitors ? <FactChip icon="users-three" tone={tone === 'accent' ? 'default' : tone} label={t('clientVisitsFactVisitors')} value={f.integer(visitors)} /> : null}
    </FactRow>
  )
}
