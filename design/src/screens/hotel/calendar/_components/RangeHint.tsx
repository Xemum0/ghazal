// RangeHint: how to pick several dates, said as a drawing (ADR 0034): two gold cells joined by the gold thread and an arrow that points the way
// the week runs (it mirrors in Arabic with the registry arrow), and the two ways in a sentence each behind an (i). It replaces the system
// DragAffordance, whose caption is a sentence on the screen (requested in docs/engineering/requests.md: a `compact` form without the caption).
// The hint is static; nothing loops.
import { Icon, InfoButton } from '../../../../system'
import { useWords } from './calBits'
import './range-hint.css'

export function RangeHint() {
  const { t } = useWords()
  return (
    <div className="cal-hint" data-gz="RangeHint">
      <span className="cal-hint__demo gz-drag__demo" aria-hidden="true">
        <span className="gz-drag__cell gz-drag__cell--on" />
        <span className="gz-drag__thread" />
        <span className="gz-drag__cell gz-drag__cell--on" />
        <Icon name="arrow-right" size="xs" tone="secondary" />
      </span>
      <span className="gz-sr-only">{t('hotelCalendarHintDrag')}</span>
      <InfoButton title={t('hotelCalendarActionSelect')}>
        <p>{t('hotelCalendarHintDrag')}</p>
        <p>{t('hotelCalendarHintTap')}</p>
      </InfoButton>
    </div>
  )
}
