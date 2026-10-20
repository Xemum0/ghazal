// ProgressHead (CL-WEDD-02): how far the checklist is, as a figure. The percent in the figures voice with its glyph (CA-TOOL-14), the fraction
// quietly at the end, one gold line as long as the share done (a state, direction 2.3 e). No words: "1 of 9 done" is the accessible name.
import { useFormat, useT } from '../../../../i18n'
import { Fig, IconStat } from '../../../../system'
import './checklist.css'

export function ProgressHead({ done, total }: { done: number; total: number }) {
  const t = useT('client-my-wedding')
  const f = useFormat()
  const share = total === 0 ? 0 : Math.round((done / total) * 1000)
  const label = t('clientMyWeddingChecklistProgress', { done: f.integer(done), total: f.integer(total) })
  return (
    <div className="gzmw-prog" role="img" aria-label={label} data-gz="ProgressHead">
      <div className="gzmw-prog__row">
        <IconStat layout="inline" icon="checklist" label={label} value={<bdi dir="ltr">{f.percent(total === 0 ? 0 : (done / total) * 100, { maxFraction: 0 })}</bdi>} />
        <span className="gzmw-prog__frac gz-t-fig-body-s">
          <Fig>{`${f.integer(done)}/${f.integer(total)}`}</Fig>
        </span>
      </div>
      <span className="gzmw-prog__track" aria-hidden="true">
        <span className="gzmw-prog__fill" style={{ flexGrow: share }} />
        <span className="gzmw-prog__rest" style={{ flexGrow: 1000 - share }} />
      </span>
    </div>
  )
}
