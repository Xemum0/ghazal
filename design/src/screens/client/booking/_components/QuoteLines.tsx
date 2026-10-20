// QuoteLines: the itemised price as ruled lines in the figures voice (exact three decimals, ADR 0010), in the two columns of ADR 0033 D4,
// spoken in glyphs (ADR 0034): a line is a glyph, what it is made of (guests and the rate per guest as facts, or the name of an extra) and
// its amount, with the standard amount quiet and struck through beneath it. Discounts are signed lines in the success tone.
// The closing block is the same composition as a package card (step 2): the voucher total as the number that matters (ticket glyph), and
// beneath it the standard total struck (offer glyph) beside the saving after the voucher fee as a green chip (trend-down glyph), all at
// inline-start so each glyph sits against its figure; a quote the voucher would not pay for shows one plain Total. The words of every glyph are accessible names; the sentence about the fee and the venue payment is the caller's info sheet.
// No tax line, no deposit, no fee line that is not already a line. Used by the review and by the step-2 breakdown sheet.
import type { IconName } from '@gz/tokens'
import type { PriceLineKind, Quote } from '../../../../mock'
import { FactChip, FactRow, Figures, Icon, Price, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import './quote.css'

const KIND_GLYPH: Record<PriceLineKind, IconName> = {
  package: 'package',
  menu: 'buffet',
  extra: 'sparkle',
  venue_discount: 'percent',
  service_charge: 'receipt',
  adjustment: 'receipt',
}

export type QuoteLinesProps = {
  quote: Pick<Quote, 'lines' | 'totals' | 'voucherEligible'>
  /** Hide the closing block. */
  noTotal?: boolean
}

export function QuoteLines({ quote, noTotal }: QuoteLinesProps) {
  const f = useFormat()
  const t = useT('common')
  const tb = useT('client-booking')
  const bi = useBi()
  const { totals } = quote
  const has = quote.voucherEligible
  // One line item: the totals block already carries the standard / voucher pair, so the per-line struck figure would repeat it, and a
  // line that is only guests x rate shows that basis alone (its amount is the total beneath).
  const single = quote.lines.length === 1
  const exact = (fils: number) => f.money(fils, { mode: 'exact' })
  return (
    <div className="bk-quote" data-gz="QuoteLines" data-voucher={has ? 'yes' : 'no'}>
      <ul className="bk-quote__lines">
        {quote.lines.map((line, i) => {
          const credit = line.amount.fils < 0
          const named = line.kind === 'extra' || line.kind === 'venue_discount' || line.kind === 'service_charge' || line.kind === 'adjustment'
          const rated = line.unit !== null && line.qty > 1
          const struck = has && !credit && line.standardAmount.fils !== line.amount.fils
          const basisOnly = single && rated && !noTotal
          return (
            <li key={i} className={credit ? 'bk-quote__row is-credit' : 'bk-quote__row'}>
              <span className="bk-quote__what">
                <Icon name={KIND_GLYPH[line.kind]} size="sm" tone="secondary" />
                {named ? (
                  <span className="bk-quote__name gz-t-body-s">
                    <Figures text={bi(line.name)} />
                  </span>
                ) : (
                  <span className="gz-sr-only">{bi(line.name)}</span>
                )}
                {rated ? (
                  <FactRow>
                    <FactChip icon="users-three" label={tb('clientBookingGuestsLabel')} value={f.integer(line.qty)} size="sm" tone="muted" />
                    <FactChip icon="per-guest" label={t('commonUnitPerGuest')} value={exact(line.unit!.fils)} size="sm" tone="muted" />
                  </FactRow>
                ) : null}
              </span>
              {basisOnly ? null : (
                <span className="bk-quote__amounts">
                  <Price fils={line.amount.fils} mode="exact" size="strong" />
                  {has && !credit && !single && struck ? (
                    <span className="bk-quote__was gz-t-fig-caption gz-strike" aria-label={t('commonStandardPrice')}>
                      <bdi dir="ltr">{exact(line.standardAmount.fils)}</bdi>
                    </span>
                  ) : null}
                </span>
              )}
            </li>
          )
        })}
      </ul>
      {noTotal ? null : has ? (
        <div className="bk-quote__totals" data-gz-id="booking.total">
          <div className="bk-quote__trow bk-quote__trow--main">
            <span className="bk-quote__glyph">
              <Icon name="ticket" size="md" tone="success" />
              <span className="gz-sr-only">{tb('clientBookingVoucherTotalLabel')}</span>
            </span>
            <Price fils={totals.voucherTotal.fils} mode="exact" size="total" />
          </div>
          <div className="bk-quote__trow bk-quote__trow--sub">
            <span className="bk-quote__was gz-t-fig-body-s">
              <Icon name="offer" size="xs" tone="secondary" />
              <span className="gz-sr-only">{t('commonStandardPrice')}</span>
              <span className="gz-strike">
                <bdi dir="ltr">{exact(totals.standardTotal.fils)}</bdi>
              </span>
            </span>
            <span className="bk-quote__save gz-t-pill" data-gz-id="saving">
              <Icon name="trend-down" size="xs" mirror={false} />
              <span className="gz-sr-only">{tb('clientBookingYouSaveNet', { amount: exact(totals.netSavings) })}</span>
              <span aria-hidden="true">
                <Figures text={exact(totals.netSavings)} />
              </span>
            </span>
          </div>
        </div>
      ) : (
        <div className="bk-quote__totals" data-gz-id="booking.total">
          <div className="bk-quote__trow bk-quote__trow--plain">
            <span className="gz-t-title">{t('commonMoneyTotal')}</span>
            <Price fils={totals.standardTotal.fils} mode="exact" size="total" />
          </div>
        </div>
      )}
    </div>
  )
}
