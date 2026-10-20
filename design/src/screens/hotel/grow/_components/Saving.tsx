// Saving: what a couple keeps, as a signed amount in the figures voice: the currency first, then the true minus (U+2212) inside the LTR island,
// so in Arabic the sign never lands on the far side. Integer fils in, the formatter's parts out (ADR 0010); a glyph before it says "price off".
import { useFormat } from '../../../../i18n'
import { Icon } from '../../../../system'
import './saving.css'

export type SavingProps = {
  /** Integer fils kept by the couple. */
  fils: number
  mode?: 'browse' | 'exact'
  /** The accessible name ("Couples save"), read before the amount. */
  label: string
}

export function Saving({ fils, mode = 'browse', label }: SavingProps) {
  const f = useFormat()
  const m = f.moneyParts(fils, { mode })
  return (
    <span className="gs-saving" data-gz="Saving">
      <Icon name="offer" size="xs" tone="accent" />
      <span className="gz-sr-only">{label}</span>
      <span className="gz-money gs-saving__amt">
        <span className="gz-money__cur">{m.currency}</span>
        <bdi dir="ltr" className="gz-t-price-strong">
          −{m.integer}
          {m.fraction}
        </bdi>
      </span>
    </span>
  )
}
