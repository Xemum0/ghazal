// The disabled decision of an offline frame: nothing is queued, so the three controls are off in place and the offline glyph beside the
// name says why; the glyph opens the one-line reason (a 44 px info button, so the sentence has a home; ADR 0008 D10, docs/design/02-text-diet.md).
import { Button, InfoButton } from '../../../../system'
import { UserText, useDayMonth, useWords } from './bits'
import { TextFact } from './Facts'
import type { NeedItem } from './data'
import './today-blocks.css'

export function OfflineDecision({ request }: { request: NonNullable<NeedItem['request']> }) {
  const { t, c } = useWords()
  const dayMonth = useDayMonth()
  const b = request.booking
  return (
    <div className="ht-offline-card">
      <div className="ht-offline-card__head">
        <UserText role="title">{b.clientName}</UserText>
        <span className="ht-offline-card__why">
          <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={dayMonth(b.eventDate)} />
          <InfoButton icon="offline" title={c('commonStateTitleNetwork')} label={t('hotelTodayOfflineReason')}>
            {t('hotelTodayOfflineReason')}
          </InfoButton>
        </span>
      </div>
      <Button variant="primary" fullWidth iconStart="check" disabled>
        {c('commonActionAccept')}
      </Button>
      <div className="ht-offline-card__pair">
        <Button variant="secondary" disabled>
          {c('commonActionReschedule')}
        </Button>
        <Button variant="secondary" disabled>
          {c('commonActionDecline')}
        </Button>
      </div>
    </div>
  )
}
