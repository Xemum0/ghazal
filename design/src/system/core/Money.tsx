// Money: the one shared money part (ADR 0010 D7). Integer fils in, the formatter's parts out: [currency][amount.fils] as one LTR island
// (.gz-money), so the figure is isolated and the Arabic currency reads after it (`12 د.ك` is drawn د.ك 12). Price, PriceCompare, CardPriceLine
// and the struck standard prices all render through this part, so the currency can never land on a different side in two places.
//   amountClass  the type role of the figure (gz-t-price, gz-t-fig-caption ...); Price passes its size ladder, quiet lines pass a figure role
//   inline       the currency takes the surrounding size and ink instead of the label voice (struck prices, chips, facts)
//   mode "exact" always three decimals, the `.000` set quiet; "browse" (default) drops a zero fraction
import { useFormat } from '../../i18n'
import { cx } from './cx'

export type MoneyProps = {
  /** Integer fils (ADR 0010 D6). */
  fils: number
  mode?: 'browse' | 'exact'
  /** Type role class of the figure. */
  amountClass?: string
  /** The currency inherits size and colour from the surrounding line (struck prices, chips). */
  inline?: boolean
  className?: string
}

export function Money({ fils, mode = 'browse', amountClass, inline = false, className }: MoneyProps) {
  const f = useFormat()
  const parts = f.moneyParts(fils, { mode })
  const quiet = mode === 'exact' && parts.fractionIsZero
  return (
    <span data-gz="Money" className={cx('gz-money', inline && 'gz-money--inline', className)}>
      <span className="gz-money__cur">{parts.currency}</span>
      <span className="gz-money__num">
        <span className={cx('gz-money__amt', amountClass)}>
          {parts.negative ? '−' : ''}
          {parts.integer}
          {!quiet ? parts.fraction : null}
        </span>
        {quiet ? <span className="gz-money__fils">{parts.fraction}</span> : null}
      </span>
    </span>
  )
}
