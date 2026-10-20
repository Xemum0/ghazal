// CapacityRange (CL-DISC filters, CA-FLT capacity range): the guest range a hall must hold, minimum to maximum, as a dual-handle slider.
// It is the system RangeSlider with guests semantics: the start value sits at the inline-start (right in Arabic), both values show as
// LTR figures above the rail, the screen-reader value reads "250 guests", and a one-line summary under the label states the range.
// The bounds come from the fixtures' real hall capacities (never a hard-coded 50 to 1,500) and are passed in.
import { useState } from 'react'
import { useFormat, useT } from '../../i18n'
import { Figures } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import { RangeSlider, type RangeValue } from '../inputs'
import './capacity-range.css'

const useW = defineWords({
  from: p('From', 'من'),
  to: p('To', 'إلى'),
  summary: p('{range} guests', '{range} ضيف'),
  min: p('Fewest guests', 'أقل عدد من الضيوف'),
  max: p('Most guests', 'أكثر عدد من الضيوف'),
})

export type CapacityRangeProps = {
  /** Smallest and largest capacity among the venues (fixtures: `guestRange` over all halls). */
  min: number
  max: number
  step?: number
  value?: RangeValue
  defaultValue?: RangeValue
  onChange?: (value: [number, number]) => void
  onChangeEnd?: (value: [number, number]) => void
  className?: string
}

export function CapacityRange({ min, max, step = 10, value, defaultValue, onChange, onChangeEnd, className }: CapacityRangeProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const [inner, setInner] = useState<RangeValue>(defaultValue ?? [min, max])
  const current = value ?? inner
  const [lo, hi] = [Math.min(current[0], current[1]), Math.max(current[0], current[1])]
  return (
    <div data-gz="CapacityRange" className={className ? `gz-cap ${className}` : 'gz-cap'}>
      <p className="gz-cap__summary gz-t-body-s" aria-live="polite" data-gz-id="summary">
        <Figures text={w('summary', { range: f.numberRange(lo, hi) })} />
      </p>
      <RangeSlider
        min={min}
        max={max}
        step={step}
        value={current}
        onChange={v => {
          setInner(v)
          onChange?.(v)
        }}
        onChangeEnd={onChangeEnd}
        label={t('commonFilterCapacity')}
        thumbLabels={[w('min'), w('max')]}
        captions={[w('from'), w('to')]}
        formatValue={n => <bdi dir="ltr">{f.integer(n)}</bdi>}
        valueText={n => f.guests(n)}
      />
    </div>
  )
}
