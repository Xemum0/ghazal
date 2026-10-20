// PriceLines: the request price a couple sees for the example booking (350 guests, one date): the venue's standard total, the saving and what
// couples pay, in exact money, each row a glyph and one or two words. The KD 2 voucher fee is Ghazal's, never the venue's income: it lives
// behind the (i) of the section (voucher terms, ADR 0034 section 6). Swaps instantly when the draft changes (ADR 0017 D7).
import { useFormat } from '../../../../i18n'
import { FactChip, FactRow, Icon, InfoButton, Price } from '../../../../system'
import { Fx, dm, useWords } from './bits'
import { Head } from './Head'
import { exampleQuote, VOUCHER_FEE } from './model'
import { Saving } from './Saving'
import './price-lines.css'

export type PriceLinesProps = { rate: number; packageIds: readonly string[]; dates: readonly string[] }

export function PriceLines({ rate, packageIds, dates }: PriceLinesProps) {
  const f = useFormat()
  const { t } = useWords()
  const ex = exampleQuote(packageIds, dates, rate)
  return (
    <section className="gl-lines" aria-label={t('hotelGrowRequestPrice')}>
      <Head
        icon="receipt"
        title={t('hotelGrowRequestPrice')}
        trailing={
          <InfoButton title={t('hotelGrowFeeTitle')}>
            <p>{t('hotelGrowFeeNote', { fee: f.money(VOUCHER_FEE) })}</p>
          </InfoButton>
        }
      />
      <FactRow label={t('hotelGrowExampleLabel')}>
        {ex.unit === 'flat' ? <FactChip icon="package" label={t('hotelGrowUnitPackage')} size="sm" tone="muted" /> : <FactChip icon="users-three" value={f.integer(ex.guests)} label={t('hotelGrowFactGuests')} size="sm" tone="muted" />}
        <FactChip icon="calendar" value={<Fx text={dm(f, ex.date)} />} label={t('hotelGrowFactDate')} size="sm" tone="muted" />
      </FactRow>
      <div className="gl-lines__rows">
        <div className="gl-lines__row">
          <span className="gz-t-body-s gl-lines__name">
            <Icon name="coins" size="sm" tone="secondary" />
            {t('hotelGrowStandardPrice')}
          </span>
          <Price fils={ex.standard} mode="exact" size="strong" />
        </div>
        <div className="gl-lines__row">
          <span className="gz-t-body-s gl-lines__name">
            <Icon name="offer" size="sm" tone="secondary" />
            {t('hotelGrowSaving')}
          </span>
          <Saving fils={ex.saving} mode="exact" label={t('hotelGrowYouSave')} />
        </div>
        <div className="gl-lines__row gl-lines__row--total">
          <span className="gz-t-body gl-lines__name gl-lines__name--total">
            <Icon name="ticket" size="sm" tone="accent" />
            {t('hotelGrowCouplesPay')}
          </span>
          <Price fils={ex.voucher} mode="exact" size="total" />
        </div>
      </div>
    </section>
  )
}
