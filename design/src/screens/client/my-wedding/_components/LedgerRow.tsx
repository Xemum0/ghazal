// LedgerRow (CL-WEDD-03): one payment or expense in the "Payments" list, as a glyph, one word, a status glyph and the amount. A booking
// payment is posted by Ghazal (the voucher: ticket; the venue price: hall) and opens Booking detail, never editable here; an expense the
// couple added shows its note or its category and opens its edit sheet. Paid is the check, committed (booked, not yet settled with the
// venue) the hourglass, planned the calendar; each glyph carries its word as an accessible name. No dates on the row (ADR 0034).
import type { IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { IconListRow, Icon, Price } from '../../../../system'
import type { BudgetModel, LedgerRow as Row } from './model'
import { useCategoryName } from './names'

export type LedgerRowProps = {
  row: Row
  categories: BudgetModel['cats']
  last?: boolean
  onOpen?: () => void
}

export function LedgerRow({ row, categories, last, onOpen }: LedgerRowProps) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const catName = useCategoryName()
  const cat = categories.find(x => x.id === row.categoryId)
  const category = cat ? catName(cat.id, cat.name) : ''

  const title = row.kind === 'auto' ? (row.part === 'venue' ? category : c('commonVoucher')) : (row.label ?? category)
  const glyph: IconName = row.kind === 'auto' ? (row.part === 'venue' ? 'hall' : 'ticket') : 'receipt'
  const status =
    row.status === 'paid'
      ? { icon: 'check-circle' as const, tone: 'success' as const, label: t('clientMyWeddingBudgetPaid') }
      : row.status === 'committed'
        ? { icon: 'hourglass' as const, tone: 'accent' as const, label: t('clientMyWeddingBudgetCommitted') }
        : { icon: 'calendar' as const, tone: 'secondary' as const, label: t('clientMyWeddingBudgetPlanned') }

  return (
    <IconListRow
      icon={glyph}
      title={title}
      autoDir
      trailing={
        <span className="gzmw-led">
          <Icon name={status.icon} size="sm" tone={status.tone} label={status.label} />
          <Price fils={row.amount} size="strong" />
        </span>
      }
      chevron={Boolean(onOpen)}
      last={last}
      onClick={onOpen}
    />
  )
}
