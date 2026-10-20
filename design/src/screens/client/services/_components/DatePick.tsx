// DatePick (CL-SERV-03 Event, CL-SERV-04 Request quote): the system DateField with a compact value. The field box prints the date as
// `14 Jan 2027` (three tokens) instead of `Thursday 14 January 2027` (four), because a form row that already wears the calendar glyph
// needs no weekday; the calendar sheet still shows the full date and, in Arabic, the Hijri line. The field name is visually hidden text
// (the glyph is the label, ADR 0034). Same box, focus, error and sheet as DateField: it reuses the system field classes and the exported
// Calendar and PickerSheet. Flow-local twin until DateField takes `format="compact"` (requests.md); delete this file then.
import { useState } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, Calendar, Figures, Icon, PickerSheet } from '../../../../system'

export type DatePickProps = {
  /** Accessible name of the field; never drawn. */
  label: string
  /** Shown when no date is chosen, and the title of the calendar sheet. */
  placeholder: string
  value: string | null
  onChange: (value: string | null) => void
  minDate?: string
  error?: string
  disabled?: boolean
}

export function DatePick({ label, placeholder, value, onChange, minDate, error, disabled }: DatePickProps) {
  const c = useT('common')
  const f = useFormat()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<string | null>(null)
  const open_ = () => {
    if (disabled) return
    setDraft(value)
    setOpen(true)
  }
  const close = () => setOpen(false)
  return (
    <div className="gz-field" data-gz="DatePick" data-invalid={error ? true : undefined} data-disabled={disabled || undefined} data-force-focus={open || undefined}>
      <div className="gz-field__box">
        <span className="gz-field__adorn">
          <Icon name="calendar" size="sm" />
        </span>
        <button
          type="button"
          className="gz-in-btn gz-datefield__trigger"
          disabled={disabled}
          aria-label={value ? `${label}: ${f.plain(f.date(value, 'full'))}` : label}
          aria-haspopup="dialog"
          aria-expanded={open}
          aria-invalid={error ? true : undefined}
          onClick={open_}
        >
          <span className={`gz-datefield__value gz-t-body${value ? '' : ' is-placeholder'}`}>
            {value ? <Figures text={f.date(value, 'compact')} /> : placeholder}
          </span>
        </button>
      </div>
      {error ? (
        <div className="gz-field__foot">
          <p className="gz-field__msg gz-field__msg--error gz-t-caption" role="alert">
            <Icon name="warning-circle" size="xs" />
            <span>{error}</span>
          </p>
        </div>
      ) : null}
      <PickerSheet
        open={open}
        onClose={close}
        title={placeholder}
        footer={
          <>
            <Button
              variant="primary"
              fullWidth
              disabled={!draft}
              reason={!draft ? placeholder : undefined}
              onClick={() => {
                onChange(draft)
                close()
              }}
            >
              {c('commonActionConfirm')}
            </Button>
            <Button variant="tertiary" fullWidth disabled={!draft} onClick={() => setDraft(null)}>
              {c('commonActionClear')}
            </Button>
          </>
        }
      >
        <Calendar mode="single" minDate={minDate} summary label={placeholder} value={draft} onChange={setDraft} />
      </PickerSheet>
    </div>
  )
}
