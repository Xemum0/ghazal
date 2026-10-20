// Amount: a struck-through standard price built the same way as every other amount (the Price component): one LTR island, the
// currency left of the number in both languages, the line through the number only. Same decimals as the Price rows (exact, three).
import { useFormat } from '../../../../i18n'
import { cx } from '../../../../system/core/cx'

export function StruckAmount({ fils, className }: { fils: number; className?: string }) {
  const f = useFormat()
  const parts = f.moneyParts(fils, { mode: 'exact' })
  return (
    <span className={cx('gz-money gzb-struck', className)} data-gz="StruckAmount">
      <span className="gz-money__cur">{parts.currency}</span>
      <span className="gz-money__num">
        <span className="gz-money__amt gz-t-fig-caption gz-strike">
          {parts.integer}
          {parts.fraction}
        </span>
      </span>
    </span>
  )
}
