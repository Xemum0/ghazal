// Money in the Bookings flow (flow-local twin of the venue flow's Money.tsx). Price puts the currency to the visual left of the figure in both
// languages (one LTR island, `.gz-money`); a money string handed to a FactChip or struck inside a bidi isolate puts the Arabic currency to the
// right instead. These build the same island as Price at small sizes, so the voucher price, the standard price struck beside it and the
// saving read as one family in both languages. The word (standard price, saving) is the accessible name the caller gives; a glyph carries it
// on screen. Promotion into the system Price is filed in docs/engineering/requests.md.
import { useFormat } from '../../../../i18n'

type MoneyProps = { fils: number; mode?: 'browse' | 'exact'; className?: string; label?: string }

function Island({ fils, mode = 'browse', className, label, struck }: MoneyProps & { struck: boolean }) {
  const f = useFormat()
  const parts = f.moneyParts(fils, { mode })
  return (
    <span className={`gz-money${className ? ` ${className}` : ''}`} data-gz={struck ? 'StruckMoney' : 'QuietMoney'}>
      {label ? <span className="gz-sr-only">{label}</span> : null}
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

/** A small amount in the figures voice (a saving, a line of the quote): currency and figure in one island. */
export const QuietMoney = (props: MoneyProps) => <Island {...props} struck={false} />
