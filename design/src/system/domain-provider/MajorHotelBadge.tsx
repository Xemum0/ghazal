// MajorHotelBadge (Partner app only): the marker of a major hotel, exempt from every listing and advertising fee (owner rule, ADR 0033 D7).
// Clients never see it (the exemption is a business arrangement, not a quality mark). It never says the hotel skips review: a major hotel
// is exempt from the fee, not from the moderator.
//   chip  crown glyph, "Major hotel" and "Fee exempt" in one 32 px chip (header, listing row)
//   note  the same plus one sentence explaining what the exemption means (billing screen)
import { useT } from '../../i18n'
import { Icon } from '../core'
import { cx } from '../core/cx'
import { defineWords, p } from '../domain-client/copy'
import './major-hotel-badge.css'

const useW = defineWords({
  exemptFee: p('Fee exempt', 'معفى من الرسوم'),
  explain: p('Major hotels pay no listing or advertising fees. Every listing is still reviewed before it goes live.', 'لا تُحتسب على الفنادق الكبيرة رسوم إدراج أو إعلان. وتخضع كل قوائمها للمراجعة قبل النشر.'),
})

export type MajorHotelBadgeProps = {
  variant?: 'chip' | 'note'
  className?: string
}

export function MajorHotelBadge({ variant = 'chip', className }: MajorHotelBadgeProps) {
  const t = useT('common')
  const w = useW()
  return (
    <span data-gz="MajorHotelBadge" data-variant={variant} className={cx('gz-mhb', `gz-mhb--${variant}`, className)}>
      <span className="gz-mhb__chip gz-t-pill">
        <Icon name="crown" size="xs" />
        <span>{t('commonMajorHotel')}</span>
        <span className="gz-mhb__sep" aria-hidden="true" />
        <span>{w('exemptFee')}</span>
      </span>
      {variant === 'note' ? <span className="gz-mhb__note gz-t-body-s">{w('explain')}</span> : null}
    </span>
  )
}
