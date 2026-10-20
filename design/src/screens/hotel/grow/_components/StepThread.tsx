// StepThread: the two steps of the window editor as the system thread with an icon per knot (price, dates), pinned under the top bar. The
// glyphs say which step this is and the knots say how far (a knot ties only when its step is done); the step names are the accessible names,
// not words on the screen (ADR 0034). The first step is tied once the second is open.
import { IconProgress } from '../../../../system'
import { useWords } from './bits'
import './step-thread.css'

export function StepThread({ step }: { step: 1 | 2 }) {
  const { t, c } = useWords()
  return (
    <div className="gs-thread" data-gz="StepThread">
      <IconProgress
        label={t('hotelGrowStepsLabel')}
        describe={c('commonCounter', { current: step, total: 2 })}
        labels="none"
        draw="mount"
        steps={[
          { key: 'price', icon: 'coins', label: t('hotelGrowStepPrice'), state: step === 1 ? 'now' : 'tied' },
          { key: 'dates', icon: 'calendar', label: t('hotelGrowStepDates'), state: step === 2 ? 'now' : 'open' },
        ]}
      />
    </div>
  )
}
