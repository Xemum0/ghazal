// PriceStack (CL-SERV-02 tile, CL-SERV-03 package, CL-SERV-04 voucher summary): the two prices of one provider offer on the same unit,
// glyphs and figures only (ADR 0034). The voucher price leads behind a ticket glyph (a lock for a guest: the price exists and is shown,
// the account is asked for at Get voucher, CA-VCH-04), the standard price sits next to it quiet and struck through, and the saving is a
// trend glyph with a figure (package variant). Every glyph carries its word as the accessible name. The unit is the per-guest glyph or one
// quiet word ("/event"). An offer with no voucher price shows the standard price alone, with no mention of vouchers. Money is integer fils
// through the shared formatter.
import type { MessageKey } from '../../../../i18n'
import { useFormat, useT } from '../../../../i18n'
import { Figures, Icon, Price } from '../../../../system'
import type { ServiceCategoryId } from '../../../../mock'
import { unitOf, type UnitKind } from './model'
import './price-stack.css'

const UNIT_KEY: Record<Exclude<UnitKind, 'guest'>, MessageKey<'client-services'>> = {
  event: 'clientServicesUnitEvent',
  cake: 'clientServicesUnitCake',
  session: 'clientServicesUnitSession',
  dress: 'clientServicesUnitDress',
  suit: 'clientServicesUnitSuit',
  card: 'clientServicesUnitCard',
  booking: 'clientServicesUnitBooking',
  package: 'clientServicesUnitPackage',
}

export type PriceStackProps = {
  /** Standard price per unit, integer fils. */
  standard: number
  /** Voucher price per unit, integer fils; null = none (or not worth it): standard only. */
  voucher: number | null
  /** The category the price belongs to: it decides the unit glyph or word. */
  categoryId: ServiceCategoryId
  audience: 'member' | 'guest'
  /** `tile` is the list card (the lowest price); `package` is a profile package (an exact price, with the saving). */
  variant: 'tile' | 'package'
  /** One row instead of two (the headline price under a name). */
  inline?: boolean
}

export function PriceStack({ standard, voucher, categoryId, audience, variant, inline = false }: PriceStackProps) {
  const t = useT('client-services')
  const c = useT('common')
  const f = useFormat()
  const tile = variant === 'tile'
  const size = tile ? 'card' : 'strong'
  const kind = unitOf(categoryId)
  const unit =
    kind === 'guest' ? (
      <span className="gzs-pstack__unit">
        <Icon name="per-guest" size="xs" tone="secondary" />
        <span className="gz-sr-only">{c('commonUnitPerGuest')}</span>
      </span>
    ) : (
      <span className="gzs-pstack__unit gz-t-caption">{t(UNIT_KEY[kind])}</span>
    )

  if (voucher === null || voucher >= standard) {
    return (
      <span className="gzs-pstack" data-gz="PriceStack" data-voucher="none">
        <span className="gzs-pstack__line">
          <Price fils={standard} size={size} />
          {unit}
        </span>
      </span>
    )
  }

  const saving = standard - voucher
  const was = f.moneyParts(standard, { mode: 'browse' })
  const guest = audience === 'guest'
  return (
    <span className={`gzs-pstack${inline ? ' gzs-pstack--inline' : ''}`} data-gz="PriceStack" data-voucher={audience} data-variant={variant}>
      <span className="gzs-pstack__line" data-gz-id="voucher-price">
        <span className="gzs-pstack__glyph">
          <Icon name={guest ? 'lock' : 'ticket'} size="xs" tone={guest ? 'secondary' : 'success'} />
          <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
        </span>
        <Price fils={voucher} size={size} />
        {unit}
      </span>
      <span className="gzs-pstack__sub">
        <span className="gzs-pstack__was gz-t-fig-caption" data-gz-id="standard-price">
          <span className="gz-sr-only">{c('commonStandardPrice')}</span>
          <span className="gzs-pstack__cut">{was.currency}</span>
          <span className="gzs-pstack__cut">
            {was.integer}
            {was.fraction}
          </span>
        </span>
        {tile ? null : (
          <span className="gzs-pstack__save gz-t-pill" data-gz-id="saving">
            <Icon name="trend-down" size="xs" mirror={false} />
            <span className="gz-sr-only">{c('commonYouSave', { amount: f.money(saving, { mode: 'browse' }) })}</span>
            <span aria-hidden="true">
              <Figures text={f.money(saving, { mode: 'browse' })} />
            </span>
          </span>
        )}
      </span>
    </span>
  )
}
