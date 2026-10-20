// The header badge of Venue detail (ADR 0009 D3): on a venue's page the tray is replaced by this count-only badge so nothing covers the sticky
// price and Book bar. A 44 target with the compare glyph and the gold count (only when something is in the set); it opens the list sheet
// CL-SAVD-02. Exported for the venue flow; request filed to promote it to the system.
import { useFormat, useT } from '../../../../i18n'
import { CountBadge, Icon } from '../../../../system'
import './compare-badge.css'

export function CompareBadge({ count, onPress }: { count: number; onPress?: () => void }) {
  const t = useT('client-saved-compare')
  const f = useFormat()
  if (count === 0) return null
  return (
    <button type="button" className="gz-reset svd-badge gz-press" aria-label={t('clientSavedCompareTrayBadge', { count })} onClick={onPress} data-gz-id="compare.badge">
      <span className="svd-badge__disk">
        <Icon name="compare" size="md" />
        <CountBadge count={count} ring className="svd-badge__count" />
      </span>
      <span className="gz-sr-only">{f.integer(count)}</span>
    </button>
  )
}
