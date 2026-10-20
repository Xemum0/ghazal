// RunningTotal: the bar summary of step 2. A glyph over nothing: the ticket (the voucher price) beside the all-in voucher total (the number the
// client pays the venue), a chevron that says it opens, and one 48 high target: the breakdown sheet lists every line in both columns. Before a
// package is chosen the bar shows nothing but the primary (its reason says why it waits).
import type { Quote } from '../../../../mock'
import { Icon, Skeleton } from '../../../../system'
import { BarTotal } from './BarTotal'
import { useT } from '../../../../i18n'
import { quotePair } from './flow'

export type RunningTotalProps = {
  quote: Quote | null
  loading?: boolean
  onOpen: () => void
  /** No package chosen yet: nothing to total. */
  missing?: boolean
  /** No voucher bound yet: the figure is an estimate. */
  estimate?: boolean
}

export function RunningTotal({ quote, loading, onOpen, missing, estimate }: RunningTotalProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const pair = quotePair(quote)
  if (missing && !loading) return null
  if (!quote && !loading) return null
  const label = pair?.has ? t(estimate ? 'clientBookingVoucherEstimateLabel' : 'clientBookingVoucherTotalLabel') : tc('commonMoneyTotal')
  return (
    <button type="button" className="gz-reset gz-press bk-sum" onClick={onOpen} aria-haspopup="dialog" aria-label={`${label}: ${t('clientBookingPackageBreakdownOpen')}`} disabled={!quote}>
      {loading || !pair ? <Skeleton inlineSize={96} blockSize={24} /> : <BarTotal fils={pair.total} icon={pair.has ? 'ticket' : 'coins'} label={label} after={<Icon name="chevron-up" size="sm" tone="secondary" />} />}
    </button>
  )
}
