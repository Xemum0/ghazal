// DatePick: a date field of the window editor (Starts, Ends). The system DateField with a compact value: `15 Nov` (or `15 Nov 2027` when the
// year is not the current one) beside the calendar glyph, a one-word label above, the calendar in the system sheet. The system field prints
// `Sunday 15 November 2026` (four tokens) which two side-by-side fields cannot hold at 360. It reuses the system field classes and the exported
// Calendar and PickerSheet; flow-local twin until DateField takes `format="compact"` (requests.md, filed by client-services).
import { useState } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, Calendar, Icon, PickerSheet } from '../../../../system'
import { Fx, dmy } from './bits'

export type DatePickProps = {
  /** One word, drawn above the box; also the title of the calendar sheet. */
  label: string
  value: string | null
  onChange: (value: string | null) => void
  minDate?: string
  today?: string
  error?: string
  disabled?: boolean
}

export function DatePick({ label, value, onChange, minDate, today, error, disabled }: DatePickProps) {
  const c = useT('common')
  const f = useFormat()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<string | null>(null)
  const show = () => {
    if (disabled) return
    setDraft(value)
    setOpen(true)
  }
  const close = () => setOpen(false)
  return (
    <div className="gz-field" data-gz="DatePick" data-invalid={error ? true : undefined} data-disabled={disabled || undefined} data-force-focus={open || undefined}>
      <span className="gz-field__label gz-t-label">{label}</span>
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
          onClick={show}
        >
          <span className={`gz-datefield__value gz-t-body${value ? '' : ' is-placeholder'}`}>{value ? <Fx text={dmy(f, value)} /> : '–'}</span>
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
              {c('commonActionConfirm')}
            </Button>
            <Button variant="tertiary" fullWidth disabled={!draft} onClick={() => setDraft(null)}>
              {c('commonActionClear')}
            </Button>
          </>
        }
      >
        <Calendar mode="single" minDate={minDate} today={today} summary label={label} value={draft} onChange={setDraft} />
      </PickerSheet>
    </div>
  )
}
