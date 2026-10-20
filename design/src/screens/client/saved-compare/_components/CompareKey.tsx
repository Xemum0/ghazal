// The key of the compare table (ADR 0034): the table has no row labels, so the few marks that are not obvious from their own shape
// (the best-in-row bead, the three header badges, the saving, a check, a coin, a dash, the voucher ticket, the official bank) are listed once
// as glyph and one word behind the info glyph in the top bar. An icon list, not a paragraph; it costs the screen no visible words.
// Each glyph means one thing: the price tag is the cheapest hall, the coins are an extra cost.
import type { IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { Icon } from '../../../../system'
import './compare-key.css'

type Tone = 'primary' | 'secondary' | 'success' | 'accent' | 'disabled'

export function CompareKey() {
  const t = useT('client-saved-compare')
  const rows: { icon: IconName | 'bead'; tone: Tone; label: string }[] = [
    { icon: 'bead', tone: 'accent', label: t('clientSavedCompareKeyBest') },
    { icon: 'star-fill', tone: 'accent', label: t('clientSavedCompareCompareBadgeRated') },
    { icon: 'offer', tone: 'primary', label: t('clientSavedCompareCompareBadgeLowest') },
    { icon: 'navigate', tone: 'primary', label: t('clientSavedCompareCompareBadgeClosest') },
    { icon: 'trend-down', tone: 'success', label: t('clientSavedCompareKeySave') },
    { icon: 'check', tone: 'success', label: t('clientSavedCompareCompareValIncluded') },
    { icon: 'coins', tone: 'accent', label: t('clientSavedCompareCompareValExtra') },
    { icon: 'minus', tone: 'disabled', label: t('clientSavedCompareCompareValNotOffered') },
    { icon: 'ticket', tone: 'primary', label: t('clientSavedCompareCompareActionVoucher') },
    { icon: 'bank', tone: 'primary', label: t('clientSavedCompareCompareActionOfficial') },
  ]
  return (
    <ul className="svd-key" data-gz="CompareKey">
      {rows.map(r => (
        <li key={r.label} className="svd-key__row">
          <span className="svd-key__disk" aria-hidden="true">
            {r.icon === 'bead' ? <span className="gz-cbead" /> : <Icon name={r.icon} size="sm" tone={r.tone} mirror={false} />}
          </span>
          <span className="svd-key__label gz-t-title">{r.label}</span>
        </li>
      ))}
    </ul>
  )
}
