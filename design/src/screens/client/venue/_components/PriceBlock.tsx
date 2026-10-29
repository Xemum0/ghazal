// PriceBlock (CL-VENU-01 date strip, CL-VENU-03 focus card, CL-VENU-04 rate block): the two prices of one quote, as glyphs and figures
// (ADR 0034). The voucher price is the headline (a ticket; every client is signed in, ADR 0038), the standard price sits under it struck through, then the saving as a figure and the (i) that opens the explainer. There is no
// label word on the screen: each glyph carries its word as its accessible name. Without a voucher price, or when the saving does not beat
// the KD 2 fee, the block shows one price and says nothing about vouchers (CA-VCH-10). Flow-local until the shared PriceCompare lands
// (docs/engineering/requests.md).
import { useFormat, useT } from '../../../../i18n'
import { Figures, Icon, IconButton, Price } from '../../../../system'
import { StruckMoney } from './Money'
import { useGuestsText, useSep } from './fmt'
import type { QuotePrices } from './model'
import './price-block.css'

export type PriceBlockProps = {
  prices: QuotePrices
  /** The client already holds a ready voucher for this venue. */
  owned?: boolean
  /** Headline size: `hero` on the page, `total` in a sheet. */
  size?: 'hero' | 'total'
  /** Opens CL-VCHR-01 (the explainer); the (i) shows only when the quote has a voucher price and no voucher is held. */
  onHow?: () => void
  className?: string
}

export function PriceBlock({ prices, owned = false, size = 'hero', onHow, className }: PriceBlockProps) {
  const t = useT('client-venue')
  const tc = useT('common')
  const f = useFormat()
  const guestsText = useGuestsText()
  const sep = useSep()
  const basis = t('clientVenueTotalFor', { guests: guestsText(prices.billedGuests) })

  if (!prices.eligible) {
    return (
      <div className={`gzv-pb gzv-pb--single ${className ?? ''}`} data-gz="PriceBlock" data-voucher="none">
        <div className="gzv-pb__main">
          <span className="gzv-pb__mark">
            <Icon name="coins" size="md" tone="secondary" />
            <span className="gz-sr-only">
              {t('clientVenueEstimateLabel')}
              {sep}
              {basis}
            </span>
          </span>
          <Price fils={prices.standard} size={size} />
        </div>
      </div>
    )
  }

  const saving = f.plain(f.money(prices.savings, { mode: 'browse' }))
  return (
    <div className={`gzv-pb ${className ?? ''}`} data-gz="PriceBlock" data-voucher="member">
      <div className="gzv-pb__main" data-gz-id="voucher.price">
        <span className="gzv-pb__mark">
          <Icon name="ticket" size="md" tone="success" />
          <span className="gz-sr-only">
            {tc('commonVoucherPrice')}
            {sep}
            {basis}
          </span>
        </span>
        <Price fils={prices.voucher} size={size} />
      </div>
      <div className="gzv-pb__sub">
        <span className="gzv-pb__was" data-gz-id="standard.price">
          <Icon name="offer" size="xs" tone="secondary" />
          <span className="gz-sr-only">{tc('commonStandardPrice')}</span>
          <StruckMoney fils={prices.standard} />
        </span>
        <span className="gzv-pb__save gz-t-pill" data-gz-id="saving">
          <Icon name="trend-down" size="xs" mirror={false} />
          <span className="gz-sr-only">{tc('commonYouSave', { amount: saving })}</span>
          <Figures text={saving} />
        </span>
        {onHow && !owned ? <IconButton icon="info" iconSize="sm" label={t('clientVenueHowTitle')} onClick={onHow} data-gz-id="venue.how" className="gzv-pb__how" /> : null}
      </div>
    </div>
  )
}
