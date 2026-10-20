// Nudge: the weekly "is your calendar up to date?" card (OQ-B-22). A quiet rose-100 note: a glyph, three words and the one action, shared with
// Needs-you: confirming here clears the item there (the Today flow's store) and the card leaves with a two-word thank-you toast. Offline it
// rests: confirming needs a connection.
import { Button, Icon, useNav } from '../../../../system'
import { useTodayLocal } from '../../today/_components/store'
import { useWords } from './calBits'
import './nudge.css'

export function Nudge({ offline, preview }: { offline?: boolean; preview?: boolean }) {
  const { t, c } = useWords()
  const nav = useNav()
  const confirmed = useTodayLocal(s => s.calendarConfirmed)
  if (confirmed && !preview) return null
  return (
    <section className="cal-nudge" data-gz="CalendarNudge" aria-label={t('hotelCalendarNudgeTitle')}>
      <span className="cal-nudge__disk" aria-hidden="true">
        <Icon name="calendar-check" size="md" tone="primary" />
      </span>
      <h3 className="cal-nudge__title gz-t-body-s">{t('hotelCalendarNudgeTitle')}</h3>
      <Button
        variant="secondary"
        size="sm"
        disabled={offline}
        onClick={() => {
          useTodayLocal.getState().confirmCalendar()
          nav.toast({ message: t('hotelCalendarNudgeDone'), tone: 'success', icon: 'check-circle' })
        }}
      >
        {c('commonActionConfirm')}
      </Button>
    </section>
  )
}
