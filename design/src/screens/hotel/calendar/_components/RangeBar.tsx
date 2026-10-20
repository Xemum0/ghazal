// RangeBar: the pinned bar of range selection (HL-CALN-01, HL-CALN-02): the chosen dates as a figure (`24 – 26 Dec`, and how many) and, in one
// row, Offer, Open and Block, the ONE gold primary at the inline-end (ADR 0014 D7). Canvas with a hairline top rule like every bar; it sits
// above the tab bar, so it adds no home-indicator inset. Before the first tap there is no summary line, only the three buttons at rest. Offline
// the three are disabled in place (the banner at the top says why); a read-only role never sees the bar.
import { Button, IconButton, Icon } from '../../../../system'
import { canBlock, canOffer, type Role } from './data'
import { Fig, Fx, useWords } from './calBits'
import { useFormat } from '../../../../i18n'
import './range-bar.css'

export type RangeBarProps = {
  /** `24 – 26 Dec`, or empty before the first tap. */
  summary: string
  count: number
  role: Role
  offline?: boolean
  onBlock: () => void
  onOpen: () => void
  onOffer: () => void
  onClear: () => void
}

export function RangeBar({ summary, count, role, offline, onBlock, onOpen, onOffer, onClear }: RangeBarProps) {
  const { t, c } = useWords()
  const f = useFormat()
  const none = count === 0
  return (
    <div className="cal-rbar" data-gz="RangeBar" data-gz-id="calendar.rangebar">
      {none ? null : (
        <div className="cal-rbar__top">
          <Icon name="calendar-dots" size="md" tone="primary" />
          <p className="cal-rbar__count gz-t-body-s">
            <Fx text={summary} />
            <span className="cal-rbar__n gz-t-fig-body-s">
              <Fig>{f.integer(count)}</Fig>
              <span className="gz-sr-only">{c('commonCountDates', { count })}</span>
            </span>
          </p>
          <IconButton icon="close" label={c('commonActionClear')} onClick={onClear} />
        </div>
      )}
      <div className="cal-rbar__row">
        {canOffer(role) ? (
          <Button variant="secondary" size="cta" disabled={none || offline} onClick={onOffer}>
            {t('hotelCalendarRangeOffer')}
          </Button>
        ) : null}
        {canBlock(role) ? (
          <>
            <Button variant="secondary" size="cta" disabled={none || offline} onClick={onOpen}>
              {t('hotelCalendarRangeOpen')}
            </Button>
            <Button variant="primary" size="cta" disabled={none || offline} onClick={onBlock}>
              {t('hotelCalendarRangeBlock')}
            </Button>
          </>
        ) : null}
      </div>
    </div>
  )
}
