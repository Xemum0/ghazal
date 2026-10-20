// Money in the venue flow (flow-local). Price puts the currency to the visual left of the figure in both languages (one LTR island,
// .gz-money); a money string handed to a FactChip or struck inside a bidi isolate puts the Arabic currency to the right instead. These two
// build the same island as Price at small sizes, so the voucher price, the standard price struck beside it and a per-guest rate read as
// one family in both languages. The word (standard price, per guest) is the accessible name given by the caller, a glyph carries it on screen.
import { useFormat } from '../../../../i18n'

type MoneyProps = { fils: number; className?: string }

function Island({ fils, className, struck }: MoneyProps & { struck: boolean }) {
  const f = useFormat()
  const parts = f.moneyParts(fils, { mode: 'browse' })
  return (
    <span className={`gz-money${className ? ` ${className}` : ''}`} data-gz={struck ? 'StruckMoney' : 'QuietMoney'}>
      <span className="gz-money__cur">{parts.currency}</span>
      <span className="gz-money__num">
        <span className={`gz-money__amt gz-t-fig-body-s${struck ? ' gz-strike' : ''}`}>
          {parts.integer}
          {parts.fraction}
        </span>
      </span>
    </span>
  )
}

/** The standard price beside a voucher price: the figure is struck, the currency is not. */
export const StruckMoney = (props: MoneyProps) => <Island {...props} struck />

/** A small amount in the figures voice (a per-guest rate): currency and figure in one island. */
export const QuietMoney = (props: MoneyProps) => <Island {...props} struck={false} />
