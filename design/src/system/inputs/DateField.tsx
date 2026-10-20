import { useState } from 'react'
import { useFormat, useT } from '../../i18n'
import { Glyph } from './internal/Glyph'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import { Figures } from './internal/Figures'
import { Calendar, type CalendarProps, type DateRange } from './Calendar'
import { Button } from '../core/Button'
import { PickerSheet } from './PickerSheet'
import './internal/base.css'
import './datefield.css'

type CalendarPassThrough = Pick<
  CalendarProps,
  'days' | 'minDate' | 'maxDate' | 'today' | 'priceBasis' | 'showViewToggle' | 'defaultView' | 'isSelectable'
>

type Common = FieldChrome &
  CalendarPassThrough & {
    placeholder?: string
    /** Title of the sheet; defaults to "Choose a date" / "Choose dates". */
    sheetTitle?: string
    /** Show the Arabic Hijri secondary line in the sheet's selection summary (ADR 0011 D1). Default true. */
    hijri?: boolean
    id?: string
    className?: string
  }

export type DateFieldProps = Common &
  (
    | { mode?: 'single'; value?: string | null; defaultValue?: string | null; onChange?: (value: string | null) => void }
    | { mode: 'range'; value?: DateRange; defaultValue?: DateRange; onChange?: (value: DateRange) => void }
  )

const NONE: DateRange = { start: null, end: null }

/**
 * Date field: a 56 high input-like button showing the date (or range) with a calendar glyph; it opens the Calendar in a bottom
 * sheet (no native date input, ADR 0011 D5 / ADR 0024). The sheet works on a draft: Confirm commits, Clear empties, closing
 * discards. The summary under the grid carries the full date and, in Arabic only, the Hijri line.
 */
export function DateField(props: DateFieldProps) {
  const t = useT('common')
  const w = useInputWords()
  const f = useFormat()
  const range = props.mode === 'range'
  const { label, optional, helper, error, disabled, disabledReason, forceFocus, placeholder } = props
  const [raw, setRaw] = useControllable<unknown>(props.value as unknown, (props.defaultValue as unknown) ?? (range ? NONE : null), props.onChange as ((v: unknown) => void) | undefined)
  const ids = useFieldIds(props.id, { helper, error, disabled, disabledReason })
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<unknown>(null)

  const single = range ? null : ((raw as string | null) ?? null)
  const rng = range ? ((raw as DateRange) ?? NONE) : NONE
  const hasValue = range ? Boolean(rng.start) : Boolean(single)
  const text = range
    ? rng.start
      ? rng.end && rng.end !== rng.start
        ? w('rangeFromTo', { from: f.plain(f.date(rng.start, 'compact')), to: f.plain(f.date(rng.end, 'compact')) })
        : f.date(rng.start, 'full')
      : ''
    : single
      ? f.date(single, 'full')
      : ''

  const dStart = range ? (draft as DateRange | null)?.start : (draft as string | null)
  const dEnd = range ? (draft as DateRange | null)?.end : dStart
  const canConfirm = range ? Boolean(dStart && dEnd) : Boolean(dStart)

  const openSheet = () => {
    if (disabled) return
    setDraft(raw ?? (range ? NONE : null))
    setOpen(true)
  }
  const close = () => setOpen(false)
  const confirm = () => {
    setRaw(draft)
    close()
  }
  const clear = () => {
    setDraft(range ? NONE : null)
  }

  const calendarProps = {
    days: props.days,
    minDate: props.minDate,
    maxDate: props.maxDate,
    today: props.today,
    priceBasis: props.priceBasis,
    showViewToggle: props.showViewToggle,
    defaultView: props.defaultView,
    isSelectable: props.isSelectable,
    summary: props.hijri !== false,
    label: props.sheetTitle ?? (range ? w('chooseDates') : w('chooseDate')),
  }

  return (
    <FieldShell
      gz="DateField"
      ids={ids}
      label={label}
      optional={optional}
      helper={helper}
      error={error}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus || open}
      className={props.className}
      startAdornment={<Glyph name="calendar" size="sm" />}
    >
      <button
        type="button"
        id={ids.id}
        className="gz-in-btn gz-datefield__trigger"
        disabled={disabled}
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-describedby={ids.describedBy}
        aria-invalid={ids.invalid || undefined}
        onClick={openSheet}
      >
        <span className={`gz-datefield__value gz-t-body${hasValue ? '' : ' is-placeholder'}`}>
          {hasValue ? <Figures text={text} /> : (placeholder ?? (range ? w('chooseDates') : w('chooseDate')))}
        </span>
      </button>
      <PickerSheet
        open={open}
        onClose={close}
        title={props.sheetTitle ?? (range ? w('chooseDates') : w('chooseDate'))}
        footer={
          <>
            <Button variant="primary" fullWidth disabled={!canConfirm} reason={!canConfirm ? (range ? w('chooseDates') : w('chooseDate')) : undefined} onClick={confirm}>
              {t('commonActionConfirm')}
            </Button>
            <Button variant="tertiary" fullWidth disabled={!dStart} onClick={clear}>
              {t('commonActionClear')}
            </Button>
          </>
        }
      >
        {range ? (
          <Calendar {...calendarProps} mode="range" value={(draft as DateRange | null) ?? NONE} onChange={setDraft} />
        ) : (
          <Calendar {...calendarProps} mode="single" value={(draft as string | null) ?? null} onChange={setDraft} />
        )}
      </PickerSheet>
    </FieldShell>
  )
}
