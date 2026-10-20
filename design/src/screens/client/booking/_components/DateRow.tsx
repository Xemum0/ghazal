// DateRow: the ruled "your date" strip (direction rule 8: a hairline above and below, not a panel). One 64 high target that opens the
// calendar sheet: the calendar glyph, the weekday and full date, a chevron. No countdown line, no helper: the date is the whole row.
import { Figures, Icon } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'

export type DateRowProps = {
  date: string
  onPress: () => void
}

export function DateRow({ date, onPress }: DateRowProps) {
  const f = useFormat()
  const t = useT('client-booking')
  const label = f.date(date, 'full')
  return (
    <button type="button" className="gz-reset gz-press bk-row" onClick={onPress} aria-label={`${t('clientBookingDateChange')}: ${f.plain(label)}`} data-gz-id="booking.date">
      <span className="bk-row__lead" aria-hidden="true">
        <Icon name="calendar" size="md" />
      </span>
      <span className="bk-row__text">
        <span className="bk-row__value gz-t-title">
          <Figures text={label} />
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
