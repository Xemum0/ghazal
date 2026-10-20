// DateOption (CL-BKNG-04): one date the venue offers, as a radio card. The full date on the first line (weekday, day, month, year: never
// a night, never a bare weekday), the re-quoted voucher price with its ticket glyph on the second; the gold bead marks the chosen date
// (gold is the verb: chosen). The guest count is the same on every card and is shown once above them. A date another couple has taken
// since stays in the list, muted and struck, with a calendar-x glyph and one word, so the couple sees it was there.
import { Figures, Icon, Price, ThreadBead } from '../../../../system'
import './date-option.css'

export type DateOptionProps = {
  date: string
  fils: number
  selected: boolean
  /** The date is no longer available: not a target, says so in one word. */
  takenLabel?: string
  /** What a screen reader hears for the card, built by the screen from the same strings. */
  label: string
  /** The accessible name of the price glyph. */
  priceLabel: string
  onSelect: () => void
  disabled?: boolean
}

export function DateOption({ date, fils, selected, takenLabel, label, priceLabel, onSelect, disabled }: DateOptionProps) {
  const taken = Boolean(takenLabel)
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={taken ? `${label}, ${takenLabel}` : label}
      disabled={taken || disabled}
      className={`gz-reset gzb-dateopt gz-press${selected ? ' is-selected' : ''}${taken ? ' is-taken' : ''}`}
      data-gz="DateOption"
      onClick={onSelect}
    >
      <span className="gzb-dateopt__text">
        <span className="gzb-dateopt__date gz-t-title">
          <Figures text={date} />
        </span>
        {taken ? (
          <span className="gzb-dateopt__sub gzb-dateopt__taken gz-t-caption">
            <Icon name="calendar-x" size="xs" tone="secondary" />
            {takenLabel}
          </span>
        ) : (
          <span className="gzb-dateopt__sub gzb-dateopt__price">
            <Icon name="ticket" size="xs" tone="success" />
            <span className="gz-sr-only">{priceLabel}</span>
            <Price fils={fils} mode="exact" size="strong" />
          </span>
        )}
      </span>
      {taken ? null : (
        <span className="gzb-dateopt__radio" aria-hidden="true">
          <ThreadBead tone={selected ? 'gold' : 'hollow'} />
        </span>
      )}
    </button>
  )
}
