// Saving: what a voucher saves at the venue, as a glyph and one figure (ADR 0034: "You save" is the glyph's accessible name, not a caption).
// The trend-down glyph sits in a quiet rose disk, the amount is the system Price (the currency stays small, the figure carries the row). It is
// the one number the wallet ticket, the voucher screen and the quote check agree on.
import { Icon, Price, type PriceSize } from '../../../../system'
import { useVc } from './useVc'
import './saving.css'

export function Saving({ fils, size = 'total' }: { fils: number; size?: Extract<PriceSize, 'strong' | 'total' | 'kpi'> }) {
  const { tc, money } = useVc()
  return (
    <span className="gzv-saving" data-gz="Saving">
      <span className="gzv-saving__disk" aria-hidden="true">
        <Icon name="trend-down" size="sm" tone="success" mirror={false} />
      </span>
      <span className="gz-sr-only">{tc('commonYouSave', { amount: money(fils) })}</span>
      <span className="gzv-saving__figure" aria-hidden="true">
        <Price fils={fils} size={size} />
      </span>
    </span>
  )
}
