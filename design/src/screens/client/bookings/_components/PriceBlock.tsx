// PriceBlock (CL-BKNG-02): the frozen quote of a request, in glyphs and figures (ADR 0033 D4, ADR 0034). WHO IS PAID WHAT is the whole block,
// as two cells and no repeated figure: the KD 2 voucher to Ghazal (paid, once) and the voucher price to the venue directly (off-app: the one
// word the voucher model needs), the larger cell. Under them the deal is one quiet line of facts, `[offer] struck standard  [trend] saving
// [per guest] KD 44`. The info glyph (`PriceInfo`) holds the sentences ("all-in at the venue's terms", "nothing more to pay Ghazal": voucher
// terms, one of the three allowed paragraphs) and sits in the header of the Price section, where the policy puts it. Further lines (a venue discount,
// a service charge) list only when there is more than one line; there are no add-on lines (ADR 0038).
import type { Booking } from '@gz/contracts'
import { FactChip, FactRow, Icon, InfoButton, Price, useBi } from '../../../../system'
import { StruckAmount } from './Amount'
import { useBk } from './useBk'
import './price-block.css'

export type PriceBlockProps = {
  booking: Booking
  /** Where the request is: only the venue cell changes (off-app, then settled). */
  stage: 'pending' | 'approved' | 'confirmed' | 'redeemed'
}

export function PriceBlock({ booking: b, stage }: PriceBlockProps) {
  const { t, f } = useBk()
  const bi = useBi()
  const { totals } = b
  const hasVoucher = totals.voucherTotal.fils < totals.standardTotal.fils
  const first = b.lines[0]
  const perGuest = first?.unit && first.qty > 1 ? first.unit.fils : null
  const itemised = b.lines.length > 1
  const settled = stage === 'redeemed'

  return (
    <div className="gzb-price" data-gz="PriceBlock" data-stage={stage}>
      {itemised ? (
        <ul className="gzb-price__lines" data-gz-id="lines">
          {b.lines.map((line, i) => {
            const differs = hasVoucher && line.standardAmount.fils !== line.amount.fils
            return (
              <li key={i} className="gzb-price__line">
                <span className="gzb-price__name gz-t-body-s" dir="auto">
                  {bi(line.name)}
                </span>
                <span className="gzb-price__amounts">
                  <Price fils={line.amount.fils} mode="exact" size="strong" />
                  {differs ? <StruckAmount fils={line.standardAmount.fils} /> : null}
                </span>
              </li>
            )
          })}
        </ul>
      ) : null}

      <div className="gzb-price__cells" data-gz-id="settlement">
        <div className="gzb-price__cell gzb-price__cell--ghazal" data-gz-id="ghazal">
          <span className="gzb-price__cellhead">
            <Icon name="ticket" size="sm" tone="secondary" />
            <span className="gz-sr-only">{t('clientBookingsPriceGhazal')}</span>
            <Icon name="check-circle" size="xs" tone="success" />
            <span className="gz-sr-only">{t('clientBookingsPricePaid')}</span>
          </span>
          <Price fils={totals.voucherFee.fils} mode="exact" size="strong" />
        </div>
        <div className="gzb-price__cell gzb-price__cell--venue" data-gz-id="venue" data-settled={settled ? 'true' : undefined}>
          <span className="gzb-price__cellhead">
            <Icon name="hall" size="sm" tone="secondary" />
            <span className="gz-sr-only">{t('clientBookingsPriceVenue')}</span>
            {settled ? (
              <>
                <Icon name="check-circle" size="xs" tone="success" />
                <span className="gz-sr-only">{t('clientBookingsPriceSettled')}</span>
              </>
            ) : (
              <span className="gzb-price__off gz-t-caption">
                <Icon name="receipt" size="xs" tone="secondary" />
                {t('clientBookingsPriceOffApp')}
              </span>
            )}
          </span>
          <Price fils={totals.voucherTotal.fils} mode="exact" size="total" />
        </div>
      </div>

      <FactRow className="gzb-price__facts" label={t('clientBookingsPriceBasis')}>
        {hasVoucher ? <FactChip icon="offer" size="sm" tone="muted" label={t('clientBookingsPriceStandard')} value={<StruckAmount fils={totals.standardTotal.fils} />} /> : null}
        {hasVoucher ? <FactChip icon="trend-down" size="sm" tone="accent" label={t('clientBookingsPriceSaving')} value={<Price fils={totals.savings.fils} mode="exact" size="strong" />} /> : null}
        {perGuest ? <FactChip icon="per-guest" size="sm" tone="muted" label={t('clientBookingsPricePerGuest')} value={f.money(perGuest, { mode: 'browse' })} /> : null}
      </FactRow>
    </div>
  )
}

/** The price terms behind an info glyph: the one place the two sentences live. Placed at the end of the Price section header. */
export function PriceInfo() {
  const { t } = useBk()
  return (
    <InfoButton title={t('clientBookingsPriceInfoTitle')}>
      <p>{t('clientBookingsPriceInfoInclusive')}</p>
      <p>{t('clientBookingsPriceInfoGhazal')}</p>
    </InfoButton>
  )
}
