// PriceCompare (venue detail, package sheet, request summary, compare cell, booking detail; ADR 0033 D4, voucher-model section 6): the
// two prices of one quote on the same basis. The voucher price is the headline in the figures voice; the standard price sits under it,
// quiet and struck through (only ever the venue's real standard price); then the saving and the basis.
// ADR 0034 (text diet): glyph and number, no label words. The rows are a ticket glyph (voucher price), a tag glyph (standard, struck),
// a trend-down glyph with the saving as a figure (the net-of-fee sentence is behind an info glyph), and the basis as glyphs (per guest or
// package, then the guest count). Every glyph carries its word as the accessible name.
//
// variants  stack   (default) the package sheet, request summary, booking detail
//           inline  one line for a card or list row: voucher price, struck standard price, the saving chip
// Every client is signed in (ADR 0038, no guest mode), so there is no locked "after you sign up" variant.
// A package without a voucher price renders the standard price alone (no strike, no saving, no voucher mention).
import type { PriceStructure } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { FactChip, FactRow, Icon, Money, Price, type PriceSize } from '../core'
import { cx } from '../core/cx'
import { defineWords, p } from '../domain-client/copy'
import { InfoButton } from '../inputs'
import './price-compare.css'

const useW = defineWords({
  netTitle: p('Your saving', 'التوفير'),
  net: p('You save {amount} after the {fee} voucher.', 'توفّرون {amount} بعد كوبون بقيمة {fee}.'),
  perGuest: p('per guest', 'للضيف'),
  package: p('Package price', 'سعر الباقة'),
  guestsLabel: p('Guests', 'الضيوف'),
})

export type PriceCompareProps = {
  /** Integer fils, standard column. */
  standard: number
  /** Integer fils, voucher column; null = no voucher price on this quote. */
  voucher: number | null
  /** The basis both prices share. */
  structure: PriceStructure
  /** Guest count the quote is for (shown as the guests glyph and a figure). */
  guests?: number | null
  /** Voucher fee in fils (default KD 2.000): the net saving sentence (behind the info glyph) names it. Omit it with `showNet={false}`. */
  fee?: number
  showNet?: boolean
  variant?: 'stack' | 'inline'
  /** Price size of the voucher headline (default `total`; `display` for the venue plate). */
  size?: Extract<PriceSize, 'strong' | 'total' | 'display'>
  className?: string
}

export function PriceCompare({
  standard,
  voucher,
  structure,
  guests,
  fee = 2000,
  showNet = true,
  variant = 'stack',
  size = 'total',
  className,
}: PriceCompareProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const has = voucher !== null && voucher < standard
  const savings = has ? standard - (voucher as number) : 0
  const saving = f.money(savings, { mode: 'browse' })
  /** The basis as glyphs: per guest or package, then the guest count. */
  const basis = (
    <FactRow className="gz-pcmp__basis" label={structure === 'per_person' ? w('perGuest') : w('package')}>
      <FactChip icon={structure === 'per_person' ? 'per-guest' : 'package'} label={structure === 'per_person' ? w('perGuest') : w('package')} size="sm" tone="muted" />
      {guests ? <FactChip icon="users-three" label={w('guestsLabel')} value={f.integer(guests)} size="sm" tone="muted" /> : null}
    </FactRow>
  )

  if (!has) {
    return (
      <div data-gz="PriceCompare" data-variant={variant} data-voucher="none" className={cx('gz-pcmp', `gz-pcmp--${variant}`, className)}>
        <span className="gz-pcmp__main">
          <Price fils={standard} size={size === 'display' ? 'display' : 'total'} />
          {basis}
        </span>
      </div>
    )
  }

  const savingChip = (
    <span className="gz-pcmp__chip gz-t-pill">
      <Icon name="trend-down" size="xs" mirror={false} />
      <span className="gz-sr-only">{t('commonYouSave', { amount: saving })}</span>
      <span aria-hidden="true">
        <Money fils={savings} inline amountClass="gz-num" />
      </span>
    </span>
  )

  if (variant === 'inline') {
    return (
      <div data-gz="PriceCompare" data-variant="inline" className={cx('gz-pcmp gz-pcmp--inline', className)}>
        <Price fils={voucher as number} size="strong" />
        <span className="gz-pcmp__strike" aria-label={t('commonStandardPrice')}>
          <Money fils={standard} inline className="gz-t-fig-caption gz-strike" />
        </span>
        {savingChip}
        {basis}
      </div>
    )
  }

  return (
    <div data-gz="PriceCompare" data-variant="stack" className={cx('gz-pcmp gz-pcmp--stack', className)}>
      <div className="gz-pcmp__row gz-pcmp__row--voucher" data-gz-id="voucher">
        <span className="gz-pcmp__label">
          <Icon name="ticket" size="sm" tone="success" />
          <span className="gz-sr-only">{t('commonVoucherPrice')}</span>
        </span>
        <Price fils={voucher as number} mode="browse" size={size} />
      </div>
      <div className="gz-pcmp__row gz-pcmp__row--standard" data-gz-id="standard">
        <span className="gz-pcmp__label">
          <Icon name="offer" size="xs" tone="secondary" />
          <span className="gz-sr-only">{t('commonStandardPrice')}</span>
        </span>
        <span className="gz-pcmp__was">
          <Money fils={standard} inline className="gz-t-fig-body-s gz-strike" />
        </span>
      </div>
      <div className="gz-pcmp__save-row" data-gz-id="saving">
        <span className="gz-pcmp__save gz-t-body-s">
          <Icon name="trend-down" size="xs" tone="success" mirror={false} />
          <span className="gz-sr-only">{t('commonYouSave', { amount: saving })}</span>
          <span aria-hidden="true">
            <Money fils={savings} inline amountClass="gz-num" />
          </span>
        </span>
        {showNet && savings > fee ? (
          <InfoButton title={w('netTitle')} label={w('netTitle')} data-gz-id="net">
            <p>{w('net', { amount: f.money(savings - fee, { mode: 'browse' }), fee: f.money(fee, { mode: 'browse' }) })}</p>
          </InfoButton>
        ) : null}
      </div>
      {basis}
    </div>
  )
}
