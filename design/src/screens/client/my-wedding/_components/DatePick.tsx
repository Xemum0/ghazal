// DatePick (CL-WEDD-04, task sheet): a compact date control for sheets of this flow. A local build because the shared DateField shows the
// full weekday-and-year sentence ("Thursday 12 November 2026") and a visible label (request filed: a `display="compact"` DateField with a
// glyph-only label). It is the same pattern on the same pieces: a 56 box with a calendar glyph and the day and month, opening the shared
// Calendar in a PickerSheet (draft, Confirm commits, Clear empties, closing discards).
import { useState } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, Calendar, Figures, Icon, PickerSheet } from '../../../../system'
import './sheet.css'

export type DatePickProps = {
  value: string | null
  onChange: (value: string | null) => void
  /** The accessible name of the control and the title of its sheet (one or two words). */
  label: string
  /** What an empty control shows (one word). */
  placeholder?: string
  minDate?: string
  maxDate?: string
  disabled?: boolean
  /** The calendar's selection summary (and its Hijri line in Arabic). */
  summary?: boolean
}

export function DatePick({ value, onChange, label, placeholder, minDate, maxDate, disabled, summary = true }: DatePickProps) {
  const t = useT('common')
  const f = useFormat()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<string | null>(value)

  const close = () => setOpen(false)
  const openSheet = () => {
    if (disabled) return
    setDraft(value)
    setOpen(true)
  }

  return (
    <>
      <button
        type="button"
        className="gz-reset gzmw-datepick gz-press"
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-label={value ? `${label}: ${f.date(value, 'full')}` : label}
        disabled={disabled}
        onClick={openSheet}
      >
        <Icon name="calendar" size="sm" tone="secondary" />
        <span className={`gzmw-datepick__value gz-t-body${value ? '' : ' is-placeholder'}`}>{value ? <Figures text={f.date(value, 'dayMonth')} /> : (placeholder ?? label)}</span>
      </button>
      <PickerSheet
        open={open}
        onClose={close}
        title={label}
        footer={
          <>
            <Button
              variant="primary"
              fullWidth
              disabled={!draft}
              onClick={() => {
                onChange(draft)
                close()
              }}
            >
              {t('commonActionConfirm')}
            </Button>
            <Button variant="tertiary" fullWidth disabled={!draft} onClick={() => setDraft(null)}>
              {t('commonActionClear')}
            </Button>
          </>
        }
      >
        <Calendar mode="single" value={draft} onChange={setDraft} minDate={minDate} maxDate={maxDate} summary={summary} label={label} />
      </PickerSheet>
    </>
  )
}
