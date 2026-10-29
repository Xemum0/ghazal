// QuotePlate: the choice a voucher is bound to, as one plate (CA-VCH-03): the venue or provider (photograph or monogram, name), the hall and
// the package as facts, the date, then the two prices and the saving through the system PriceCompare (glyphs and figures, the net-of-fee
// sentence behind its own info glyph). No eyebrow, no caption: the plate IS the binding. A voucher is never offered when the saving does
// not beat its price, so then the plate shows the choice without prices.
import { FactChip, FactRow, PriceCompare, Skeleton } from '../../../../system'
import { meta } from '../../../../mock'
import { Fx } from './Fx'
import { Thumb } from './Thumb'
import { useVc } from './useVc'
import type { Facts, Quote } from './model'
import './quote-plate.css'

export type QuotePlateProps = {
  quote: Quote
  facts: Facts
  loading?: boolean
  /** The saving does not beat the voucher price: no prices on the plate. */
  noPrices?: boolean
}

export function QuotePlate({ quote, facts, loading, noPrices }: QuotePlateProps) {
  const { t, dayLong } = useVc()
  const provider = quote.targetType === 'provider'
  return (
    <section className="gzv-plate" aria-label={t('clientVouchersQuoteLabel')} aria-busy={loading || undefined} data-gz-id="quote">
      {loading ? (
        <div className="gzv-plate__skeleton" data-gz-id="quote.loading">
          <div className="gzv-plate__who">
            <Skeleton variant="block" inlineSize={56} blockSize={56} />
            <div className="gzv-plate__text">
              <Skeleton variant="line" blockSize={28} />
              <Skeleton variant="line" blockSize={20} inlineSize={120} />
            </div>
          </div>
          <Skeleton variant="line" blockSize={20} inlineSize={200} />
          <Skeleton variant="block" blockSize={128} />
        </div>
      ) : (
        <>
          <div className="gzv-plate__who">
            <Thumb facts={facts} />
            <div className="gzv-plate__text">
              <p className="gzv-plate__name gz-t-d1" dir="auto">
                {facts.name}
              </p>
              {facts.hall ? (
                <FactRow>
                  <FactChip className="gzv-plate__fact" icon="hall" label={t('clientVouchersLabelHall')} value={<span dir="auto">{facts.hall}</span>} tone="muted" />
                </FactRow>
              ) : null}
            </div>
          </div>
          <FactRow>
            <FactChip className="gzv-plate__fact" icon="calendar" label={t('clientVouchersLabelEvent')} value={<Fx text={dayLong(quote.eventDate)} />} />
            {facts.pkg ? <FactChip className="gzv-plate__fact" icon="package" label={t('clientVouchersLabelPackage')} value={<span dir="auto">{facts.pkg}</span>} tone="muted" /> : null}
          </FactRow>
          {noPrices ? null : (
            <div className="gzv-plate__prices">
              <PriceCompare
                standard={quote.standardFils}
                voucher={quote.voucherFils}
                structure="package"
                guests={provider ? null : quote.guests}
                variant="inline"
                fee={meta.config.voucherFeeFils}
              />
            </div>
          )}
        </>
      )}
    </section>
  )
}
