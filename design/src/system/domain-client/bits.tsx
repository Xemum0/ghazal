// Small shared pieces of the client domain components: bilingual picking, the figures voice inside running text, the
// card price line (ADR 0004 D6 grammar), and a few helpers. Nothing here is exported from the system barrel except what the
// components re-export; screens import components, not these.
import { useCallback, useLayoutEffect, useRef, useState, type ReactNode, type RefObject } from 'react'
import { isolateLtr } from '@gz/i18n'

const NBSP = '\u00a0'
import type { CardPrice } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { FactChip, Icon, Money, Price } from '../core'
import { defineWords, p } from './copy'
import './base.css'

export { useBi, Figures, Fig } from '../core'

const useW = defineWords({
  guests: p('Guests', 'الضيوف'),
  from: p('From', 'من'),
  perNight: p('Per night', 'لليلة'),
  rentalFee: p('Rental fee', 'رسوم الإيجار'),
  lockedVoucher: p('Voucher price after you sign up', 'سعر الكوبون بعد التسجيل'),
  standard: p('Standard', 'العادي'),
})

/** An open-ended budget (`KD 35,000+` / `+35,000 د.ك`): the plus sits inside the number's LTR isolate, never on the far side of the unit. */
export function useOpenBudget() {
  const f = useFormat()
  const { lang } = useLang()
  return useCallback(
    (fils: number): string => {
      const m = f.moneyParts(fils, { mode: 'browse' })
      return lang === 'ar' ? `${isolateLtr(`${m.amount}+`)}${NBSP}${m.currency}` : `${m.currency}${NBSP}${m.amount}+`
    },
    [f, lang],
  )
}

export type PriceLineSize = 'card' | 'strong' | 'display'

/**
 * The venue price line, one grammar (ADR 0004 D6, ADR 0018 D4, ADR 0033 D4): the VOUCHER price is the headline when the card has one
 * (`KD 15,400`, `From KD 14,000`...), the standard price sits struck through beside it, and a saving chip follows. ADR 0034 (text diet): the
 * basis is a glyph and a figure (`[users] 350`, a moon for a night, a key for a rental fee) and the chip is a trend glyph and the saving; the
 * words ("for 350 guests", "per night", "Save", "rental fee") are accessible names. "From" stays: a from-price must say it. Without a voucher price (or for a signed-out visitor) the headline is the standard price; a guest also sees one locked line
 * ("Voucher price after you sign up"). Governmental facilities show their rental fee only. The amount is the figures voice (via <Price>);
 * the basis is a caption. `lean` keeps only the headline and the basis (rows of several halls). Arabic puts the rental-fee label first, as the formatter does.
 */
export function CardPriceLine({
  price,
  size = 'card',
  align = 'start',
  audience = 'member',
  lean = false,
}: {
  price: CardPrice
  size?: PriceLineSize
  align?: 'start' | 'end'
  /** `guest`: the voucher price is locked behind registration. */
  audience?: 'member' | 'guest'
  /** Rows of several halls (list, compare, tray): the headline price and its basis only, no struck standard price and no saving chip. */
  lean?: boolean
}) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const from = w('from')
  const voucher = price.mode !== 'rental_fee' && price.voucher && audience === 'member' ? price.voucher : null
  const locked = price.mode !== 'rental_fee' && price.voucher !== null && audience === 'guest'
  const headline = voucher ? voucher.fils : price.amount.fils
  const amount = (prefix?: string) => <Price fils={headline} size={size} prefix={prefix} was={voucher && !lean ? price.amount.fils : undefined} />
  const basis = (icon: 'users-three' | 'moon' | 'key', label: string, value?: string) => (
    <FactChip icon={icon} label={label} value={value} size="sm" tone="muted" className="gz-price-line__basis" />
  )

  let body: ReactNode
  switch (price.mode) {
    case 'exact':
      body = (
        <>
          {amount()}
          {basis('users-three', w('guests'), f.integer(price.guests))}
        </>
      )
      break
    case 'from_guests':
      body = (
        <>
          {amount(from)}
          {basis('users-three', w('guests'), f.integer(price.guests))}
        </>
      )
      break
    case 'from_minimum':
      body = (
        <>
          {amount(from)}
          {basis('users-three', w('guests'), `${f.integer(price.guests)}+`)}
        </>
      )
      break
    case 'flat_night':
      body = (
        <>
          {amount(price.hasSeveralPackages ? from : undefined)}
          {basis('moon', w('perNight'))}
        </>
      )
      break
    case 'rental_fee':
      body = (
        <>
          <Price fils={price.amount.fils} size={size} />
          {basis('key', w('rentalFee'))}
        </>
      )
      break
  }
  return (
    <span data-gz="CardPriceLine" data-mode={price.mode} data-voucher={voucher ? '' : undefined} data-locked={locked || undefined} className={`gz-price-line gz-price-line--${align}`}>
      {body}
      {voucher && price.savings && !lean ? (
        <span className="gz-price-line__save gz-t-pill">
          <Icon name="trend-down" size="xs" mirror={false} />
          <span className="gz-sr-only">{t('commonSaveAmount', { amount: f.money(price.savings.fils, { mode: 'browse' }) })}</span>
          <span aria-hidden="true">
            <Money fils={price.savings.fils} inline amountClass="gz-num" />
          </span>
        </span>
      ) : null}
      {locked ? (
        <span className="gz-price-line__lock gz-t-caption">
          <Icon name="ticket" size="xs" tone="secondary" />
          <Icon name="lock" size="xs" tone="secondary" />
          <span className="gz-sr-only">{w('lockedVoucher')}</span>
        </span>
      ) : null}
    </span>
  )
}

/** The measured inline size of an element (ResizeObserver), 0 until the first layout. Used where a child needs a px width (a pager inside a card). */
export function useInlineSize<T extends HTMLElement>(): [RefObject<T | null>, number] {
  const ref = useRef<T | null>(null)
  const [size, setSize] = useState(0)
  useLayoutEffect(() => {
    const el = ref.current
    if (!el) return
    const measure = () => setSize(el.offsetWidth) // layout px: unaffected by a scaled phone
    measure()
    if (typeof ResizeObserver === 'undefined') return
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    return () => ro.disconnect()
  }, [])
  return [ref, size]
}

/** `14 Jan` / `14 يناير`: day and short month, for CTAs and chips that have no room for a weekday (formatter parts, never hand-typed). */
export function useDayMonth() {
  const f = useFormat()
  return (iso: string): string => {
    const c = f.civil(iso)
    return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
  }
}
