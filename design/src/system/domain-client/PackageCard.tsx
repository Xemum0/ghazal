// PackageCard (venue details, booking step 2; ADR 0004 D1, ADR 0002, ADR 0033 D4): one priced package as a choice. Serif name, audience, the
// structure (per person or package) and guest bounds, the VOUCHER price in the basis it is sold in (per guest with the total for the guests,
// a flat night, flat plus per guest, hall only) with the standard price struck through and the saving,
// the minimum guests as a plain fact, inclusions with checks, and what the package does not cover. Choosing is ink and a gold bead,
// never a gold fill (direction 2.3): selected = ink-900 border, the bead filled, "Selected" in text for assistive technology.
//
// states   default, pressed, focus-visible, selected, unavailable on the date (muted, not a target), loading (skeleton)
import { useState } from 'react'
import type { engine, Package } from '@gz/contracts'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Button, Icon, Price, Skeleton, ThreadBead } from '../core'
import { useT } from '../../i18n'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './package-card.css'

const useW = defineWords({
  hallOnly: p('hall hire', 'تأجير القاعة'),
  plus: p('plus', 'إضافة إلى'),
  forGuests: p('for {guests}', 'لعدد {guests}'),
  upTo: p('up to {guests}', 'حتى {guests}'),
  included: p('Included', 'يشمل'),
  notCovered: p('Good to know', 'للعلم'),
  selected: p('Selected', 'تم اختيار هذه الباقة'),
  unavailable: p('Not available on your date', 'غير متاحة في تاريخكم'),
  showAll: p('Show all {n} inclusions', 'عرض كل المشمولات ({n})'),
  showLess: p('Show fewer', 'عرض أقل'),
  ladies: p('Ladies', 'نسائي'),
  men: p('Men', 'رجالي'),
  mixed: p('Mixed', 'مختلط'),
  complimentary: p('{pct} complimentary guests', 'ضيوف مجانيون {pct}'),
  noVoucher: p('Standard price only', 'السعر العادي فقط'),
})

const AUDIENCE = { women: 'ladies', men: 'men', mixed: 'mixed' } as const
const audienceOf = (pkg: Package, w: (k: 'ladies' | 'men' | 'mixed') => string) => pkg.audiences.map(a => w(AUDIENCE[a])).join(' · ')

export type PackageCardProps = {
  pkg: Package
  /** From `engine.packagePrice` (or `cardPrice`): null while loading or when the package has no rule for the date. */
  price?: engine.PackagePrice | null
  /** The guest count the total is for; with it the per-guest packages show the all-in total (the larger of guests and the minimum). */
  guests?: number
  selected?: boolean
  onSelect?: () => void
  /** Not sold on the Brief date: muted, with the reason, not a target. */
  unavailable?: boolean
  /** Inclusions shown before "Show all". */
  collapsedCount?: number
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

export function PackageCard({ pkg, price, guests, selected = false, onSelect, unavailable = false, collapsedCount = 5, loading, previewState, className }: PackageCardProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const [open, setOpen] = useState(false)

  if (loading) {
    return (
      <div className={cx('gz-pkg gz-cpanel is-loading', className)} data-gz="PackageCard" aria-busy="true">
        <Skeleton inlineSize={200} blockSize={28} />
        <Skeleton inlineSize={140} blockSize={20} />
        <Skeleton blockSize={20} />
        <Skeleton blockSize={20} />
        <Skeleton inlineSize={160} blockSize={20} />
      </div>
    )
  }

  const bounds = pkg.minGuests > 0 ? f.minGuests(pkg.minGuests) : pkg.maxGuests > 0 ? w('upTo', { guests: f.guests(pkg.maxGuests) }) : ''
  const shown = open ? pkg.inclusions : pkg.inclusions.slice(0, collapsedCount)

  // The price block: the voucher price in the basis the package is sold in (when the voucher is worth its fee and the visitor is signed in),
  // the standard price struck through beside it, then the all-in total for the guests.
  const voucherOn = Boolean(price?.voucherEligible && price.voucher)
  const basis = pkg.pricingBasis
  const unitPrice = voucherOn ? (price?.voucherPerGuest ?? price?.perGuest ?? null) : (price?.perGuest ?? null)
  const flatPrice = voucherOn ? (price?.voucherFlat ?? price?.flat ?? null) : (price?.flat ?? null)
  const wasUnit = voucherOn ? (price?.perGuest ?? null) : null
  const wasFlat = voucherOn ? (price?.flat ?? null) : null
  const total = voucherOn ? (price?.voucher ?? null) : (price?.standard ?? null)
  const showTotal = Boolean(total && guests && basis !== 'flat')
  const structure = pkg.priceStructure === 'package' ? t('commonPricingPackage') : t('commonPricingPerPerson')

  const body = (
    <>
      <span className="gz-pkg__head">
        <span className="gz-pkg__mark" aria-hidden="true">
          {selected ? <ThreadBead tone="gold" /> : <ThreadBead tone="hollow" />}
        </span>
        <span className="gz-pkg__title">
          <span className="gz-pkg__name gz-t-d1" lang={lang} data-gz-id="name">
            {bi(pkg.name)}
          </span>
          <span className="gz-pkg__sub gz-t-caption">
            <Figures text={[audienceOf(pkg, w), structure, bounds].filter(Boolean).join(' · ')} />
          </span>
        </span>
        <span className="gz-pkg__price" data-gz-id="price">
          {price ? (
            basis === 'flat_plus_per_guest' && flatPrice && unitPrice ? (
              <>
                <Price fils={flatPrice.fils} size="card" />
                <span className="gz-pkg__unit gz-t-caption">{w('plus')}</span>
                <Price fils={unitPrice.fils} size="card" unit="perGuest" />
              </>
            ) : basis === 'per_guest' && unitPrice ? (
              <Price fils={unitPrice.fils} size="card" unit="perGuest" was={wasUnit?.fils} className="gz-pkg__amount" />
            ) : flatPrice ? (
              pkg.archetype === 'hall_only' ? (
                <>
                  <Price fils={flatPrice.fils} size="card" was={wasFlat?.fils} />
                  <span className="gz-pkg__unit gz-t-caption">{w('hallOnly')}</span>
                </>
              ) : (
                <Price fils={flatPrice.fils} size="card" unit="perNight" was={wasFlat?.fils} />
              )
            ) : null
          ) : null}
        </span>
      </span>
      {price && showTotal && total ? (
        <span className="gz-pkg__total gz-t-caption" data-gz-id="total">
          <Price fils={total.fils} size="strong" was={voucherOn ? price.standard.fils : undefined} />
          <span>{w('forGuests', { guests: f.guests(guests ?? 0, { afterPreposition: lang === 'ar' }) })}</span>
          {voucherOn && price.savings ? <span className="gz-pkg__save gz-t-pill">{t('commonSaveAmount', { amount: f.money(price.savings.fils, { mode: 'browse' }) })}</span> : null}
        </span>
      ) : null}
    </>
  )

  const interactive = Boolean(onSelect) && !unavailable
  return (
    <article
      data-gz="PackageCard"
      data-archetype={pkg.archetype}
      className={cx('gz-pkg gz-cpanel', selected && 'is-selected', unavailable && 'is-unavailable', interactive && 'gz-press', previewState === 'pressed' && 'is-pressed', className)}
    >
      {interactive || selected ? (
        <button
          type="button"
          role="radio"
          aria-checked={selected}
          className="gz-reset gz-pkg__choose"
          onClick={onSelect}
          disabled={unavailable}
        >
          {body}
          {selected ? <span className="gz-sr-only">{w('selected')}</span> : null}
        </button>
      ) : (
        <div className="gz-pkg__choose gz-pkg__choose--static">{body}</div>
      )}

      {unavailable ? (
        <p className="gz-pkg__reason gz-t-caption">
          <Icon name="calendar-x" size="xs" tone="secondary" />
          {w('unavailable')}
        </p>
      ) : null}

      {shown.length > 0 ? (
        <ul className="gz-pkg__list" aria-label={w('included')} data-gz-id="inclusions">
          {shown.map((inc, i) => (
            <li key={i} className="gz-pkg__inc gz-t-body-s">
              <Icon name="check" size="xs" className="gz-pkg__check" />
              <span>
                <Figures text={bi(inc)} />
              </span>
            </li>
          ))}
        </ul>
      ) : null}

      {pkg.inclusions.length > collapsedCount ? (
        <Button variant="tertiary" iconEnd={open ? 'chevron-up' : 'chevron-down'} onClick={() => setOpen(v => !v)} className="gz-pkg__more">
          {open ? w('showLess') : w('showAll', { n: f.integer(pkg.inclusions.length) })}
        </Button>
      ) : null}

      {pkg.notes.length > 0 ? (
        <ul className="gz-pkg__list gz-pkg__list--notes" aria-label={w('notCovered')} data-gz-id="notes">
          {pkg.notes.map((n, i) => (
            <li key={i} className="gz-pkg__inc gz-pkg__inc--note gz-t-caption">
              <Icon name="info" size="xs" tone="secondary" />
              <span>{bi(n)}</span>
            </li>
          ))}
        </ul>
      ) : null}
    </article>
  )
}
