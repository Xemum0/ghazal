// BarTotal: the figure beside the primary action: a glyph (the voucher ticket, or coins for a plain total; its word is the accessible name)
// and the all-in total in the figures voice, on one line. An estimate keeps its one short word ("Est.") before the figure.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, Price } from '../../../../system'
import { useT } from '../../../../i18n'

export type BarTotalProps = {
  fils: number
  icon?: IconName
  /** The accessible name of the glyph ("Voucher price"). */
  label: string
  estimate?: boolean
  /** A control that wraps the figure (the breakdown button) adds its own chevron after it. */
  after?: ReactNode
}

export function BarTotal({ fils, icon = 'ticket', label, estimate, after }: BarTotalProps) {
  const t = useT('client-booking')
  return (
    <span className="bk-bartotal" data-gz="BarTotal">
      <Icon name={icon} size="sm" tone="secondary" />
      <span className="gz-sr-only">{label}</span>
      {estimate ? <span className="bk-bartotal__est gz-t-caption">{t('clientBookingEstimateLabel')}</span> : null}
      <Price fils={fils} size="display" />
      {after}
    </span>
  )
}
