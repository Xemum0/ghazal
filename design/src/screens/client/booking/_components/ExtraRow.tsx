// ExtraRow: one add-on as a ruled row (64 min), spoken in glyphs (ADR 0034): the glyph of what it is in a quiet disk, its name, and the price in
// the unit it is sold in (the standard price struck when the venue gives a voucher price). At inline-end the choice: the whole row is the
// toggle for a flat extra (a ring that fills with a check: choice is ink, never gold), a stepper for a per-hour or per-attendant extra.
// Anything the chosen package already includes shows a check and no price. No price changes after this step. No description, no range.
import type { Extra } from '../../../../mock'
import { Icon, Price, Stepper, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { extraPair } from './flow'
import { extraGlyph } from './glyphs'
import './extras.css'

export type ExtraRowProps = {
  extra: Extra
  /** The event date: extras are priced on it, in both columns. */
  date: string
  included: boolean
  selected: boolean
  qty: number
  onToggle: () => void
  onQty: (qty: number) => void
}

export function ExtraRow({ extra, date, included, selected, qty, onToggle, onQty }: ExtraRowProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const pair = extraPair(extra, date)
  const both = pair.voucher < pair.standard
  const perUnit = extra.pricingUnit === 'per_unit'
  const body = (
    <>
      <span className="bk-extra__disk" aria-hidden="true">
        <Icon name={extraGlyph(extra.category)} size="md" />
      </span>
      <span className="bk-extra__text">
        <span className="bk-extra__name gz-t-title">{bi(extra.name)}</span>
        {included ? null : (
          <span className="bk-extra__price">
            <Price fils={both ? pair.voucher : pair.standard} size="strong" />
            {perUnit && extra.unitLabel ? <span className="gz-t-caption">{bi(extra.unitLabel)}</span> : null}
            {both ? (
              <span className="bk-extra__was gz-t-fig-caption gz-strike" aria-label={tc('commonStandardPrice')}>
                <bdi dir="ltr">{f.money(pair.standard, { mode: 'browse' })}</bdi>
              </span>
            ) : null}
          </span>
        )}
      </span>
    </>
  )
  return (
    <li className="bk-extra" data-gz="ExtraRow" data-selected={selected || undefined}>
      {included ? (
        <div className="bk-extra__main">
          {body}
          <span className="bk-extra__done">
            <Icon name="check-circle" size="md" tone="success" />
            <span className="gz-sr-only">{t('clientBookingExtrasIncluded')}</span>
          </span>
        </div>
      ) : perUnit ? (
        <div className="bk-extra__main">
          {body}
          <Stepper className="bk-extra__stepper" value={selected ? qty : 0} min={0} max={extra.maxQty} onChange={onQty} valueText={n => `${bi(extra.name)} ${f.integer(n)}`} />
        </div>
      ) : (
        <button type="button" role="checkbox" aria-checked={selected} className="gz-reset gz-press bk-extra__main bk-extra__toggle" onClick={onToggle}>
          {body}
          <span className="bk-extra__mark" aria-hidden="true">
            {selected ? <Icon name="check" size="xs" /> : null}
          </span>
        </button>
      )}
    </li>
  )
}
