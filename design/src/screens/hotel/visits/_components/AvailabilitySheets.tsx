// The two sheets of the visit availability: pick a time (half-hour choices inside the day's business hours, 12-hour clock, Western digits)
// and add blackout dates (a range on the calendar, an optional name). Plain content for nav.openSheet.
import { useState } from 'react'
import { useFormat } from '../../../../i18n'
import { Button, Calendar, ChipGroup, type DateRange } from '../../../../system'
import { SheetShell, useWords } from './bits'
import { clockOf, timeChoices } from './availability'
import type { Week } from './store'

export function TimeContent({ title, day, initial, onSet }: { title: string; day: keyof Week; initial: string; onSet: (hhmm: string) => void }) {
  const { t } = useWords()
  const f = useFormat()
  const choices = timeChoices(day)
  const [value, setValue] = useState<string>(initial)
  const options = choices.includes(initial) ? choices : [...choices, initial].sort()
  return (
    <SheetShell
      title={title}
      footer={
        <Button size="cta" fullWidth onClick={() => onSet(value)}>
          {t('hotelVisitsTimeSet')}
        </Button>
      }
    >
      <ChipGroup<string> label={title} layout="wrap" value={value} onChange={v => v && setValue(v)} options={options.map(o => ({ value: o, label: <bdi dir="ltr">{f.time(clockOf(f, o))}</bdi> }))} />
    </SheetShell>
  )
}

export function BlackoutContent({ onAdd }: { onAdd: (from: string, to: string) => void }) {
  const { t } = useWords()
  const [range, setRange] = useState<DateRange>({ start: null, end: null })
  const ready = range.start !== null
  return (
    <SheetShell
      title={t('hotelVisitsBlackoutTitle')}
      footer={
        <Button size="cta" fullWidth disabled={!ready} reason={ready ? undefined : t('hotelVisitsBlackoutNeed')} onClick={() => range.start && onAdd(range.start, range.end ?? range.start)}>
          {t('hotelVisitsBlackoutAdd')}
        </Button>
      }
    >
      <Calendar mode="range" value={range} onChange={setRange} legend={false} summary={false} label={t('hotelVisitsBlackoutTitle')} />
    </SheetShell>
  )
}
