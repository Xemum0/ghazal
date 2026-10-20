// DragAffordance: the hint that range selection has two doors (ADR 0008 D9, ADR 0014 D4): press and hold a day, then drag across the
// dates; or tap a start day and an end day (the accessible "Select dates" path). A tiny diagram says it without words: two gold cells
// joined by the gold thread, and an arrow that points the way the week runs (it mirrors in Arabic with the registry arrow). The hint
// is static; nothing loops.
import { Icon } from '../../core'
import { cx } from '../../core/cx'
import { defineWords, p } from '../internal/copy'
import '../calendar.css'

const useW = defineWords({
  hint: p('Press and hold a date, then drag across. Or tap a start date and an end date.', 'اضغطوا مطوّلًا على تاريخ ثم اسحبوا عبر التواريخ. أو انقروا على تاريخ البداية ثم تاريخ النهاية.'),
})

export function DragAffordance({ className }: { className?: string }) {
  const w = useW()
  return (
    <div data-gz="DragAffordance" className={cx('gz-drag', className)}>
      <span className="gz-drag__demo" aria-hidden="true">
        <span className="gz-drag__cell gz-drag__cell--on" />
        <span className="gz-drag__thread" />
        <span className="gz-drag__cell gz-drag__cell--on" />
        <Icon name="arrow-right" size="xs" tone="secondary" />
      </span>
      <p className="gz-drag__text gz-t-caption">{w('hint')}</p>
    </div>
  )
}
