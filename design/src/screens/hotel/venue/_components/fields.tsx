// Form pieces of the venue editors: a bilingual field pair with its completeness chip, a KD price field that keeps integer fils,
// a guest stepper with preset chips, an inline field error and the sheet column (body + pinned footer).
import { useEffect, useState, type CSSProperties, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { useDevice } from '../../../../shell/device/context'
import { ChipGroup, Fig, Icon, Stepper, TextArea, TextField } from '../../../../system'
import { kdText, parseKd } from './money'
import { LangChip, useV } from './bits'
import { completeness } from './store'

/** An inline message under a control: glyph + words, danger ink (state is never colour alone). */
export function FieldError({ children }: { children: ReactNode }) {
  return (
    <p className="hv-err gz-t-caption" role="alert">
      <Icon name="warning-circle" size="xs" tone="danger" />
      <span className="hv-err__text">{children}</span>
    </p>
  )
}

export type BilingualFieldProps = {
  /** What the pair is, in the UI language ("Name", "Description"). */
  label: string
  ar: string
  en: string
  onAr: (v: string) => void
  onEn: (v: string) => void
  multiline?: boolean
  errorAr?: string
  errorEn?: string
  helper?: string
  maxLength?: number
  /** Both languages are required before a venue publishes (HA-VMGT-09): the chip says what is missing. Default true. */
  required?: boolean
}

/** The current language's field first, then the other; one completeness chip under the pair. */
export function BilingualField({ label, ar, en, onAr, onEn, multiline = false, errorAr, errorEn, helper, maxLength, required = true }: BilingualFieldProps) {
  const { t, lang } = useV()
  const field = (code: 'ar' | 'en') => {
    const value = code === 'ar' ? ar : en
    const set = code === 'ar' ? onAr : onEn
    const error = code === 'ar' ? errorAr : errorEn
    const name = t(code === 'ar' ? 'hotelVenueFieldInArabic' : 'hotelVenueFieldInEnglish', { field: label })
    return multiline ? (
      <TextArea key={code} label={name} lang={code} rows={3} maxLength={maxLength} value={value} onValueChange={set} error={error} />
    ) : (
      <TextField key={code} label={name} lang={code} maxLength={maxLength} value={value} onValueChange={set} error={error} />
    )
  }
  const order: Array<'ar' | 'en'> = lang === 'ar' ? ['ar', 'en'] : ['en', 'ar']
  return (
    <div className="hv-bi" role="group" aria-label={label}>
      {order.map(field)}
      {helper ? <p className="gz-t-caption hv-bi__helper">{helper}</p> : null}
      {required ? <LangChip gaps={completeness([{ ar, en }])} /> : null}
    </div>
  )
}

export type PriceFieldProps = {
  label: string
  /** Integer fils, or null while the field is empty or not an amount. */
  fils: number | null
  onChange: (fils: number | null) => void
  helper?: string
  error?: string
  disabled?: boolean
  disabledReason?: string
}

/** A KD amount: numeric keypad, Eastern digits normalised, up to three decimals, stored as integer fils (ADR 0010). */
export function PriceField({ label, fils, onChange, helper, error, disabled, disabledReason }: PriceFieldProps) {
  const { t, f } = useV()
  const [text, setText] = useState(() => kdText(fils))
  const parsed = parseKd(f, text)
  // An outside change (a reset, a preset) rewrites the text; typing keeps what the person typed.
  useEffect(() => {
    if (fils !== null && fils !== parsed) setText(kdText(fils))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fils])
  const invalid = text.trim() !== '' && parsed === null
  return (
    <TextField
      label={label}
      helper={helper}
      error={error ?? (invalid ? t('hotelVenuePriceError') : undefined)}
      inputMode="decimal"
      dir="ltr"
      disabled={disabled}
      disabledReason={disabledReason}
      value={text}
      onValueChange={v => {
        setText(v)
        onChange(parseKd(f, v))
      }}
      startAdornment={<span className="gz-t-label hv-cur">{f.moneyParts(0).currency}</span>}
    />
  )
}

export type GuestPickerProps = {
  label: string
  caption?: string
  value: number
  onChange: (v: number) => void
  min: number
  max: number
  step: number
  presets: readonly number[]
  error?: string
}

/** A guest count: the stepper (moves by the package's guest step) and a rail of preset chips under it. */
export function GuestPicker({ label, caption, value, onChange, min, max, step, presets, error }: GuestPickerProps) {
  const { f } = useV()
  const top = presets[presets.length - 1]
  return (
    <div className="hv-guest">
      <Stepper label={label} caption={caption} value={value} min={min} max={max} step={step} onChange={onChange} />
      <ChipGroup<number>
        label={label}
        layout="rail"
        value={presets.includes(value) ? value : null}
        onChange={v => {
          if (v !== null) onChange(v)
        }}
        options={presets.map(p => ({ value: p, disabled: p < min || p > max, label: <Fig>{`${f.integer(p)}${p === top ? '+' : ''}`}</Fig> }))}
      />
      {error ? <FieldError>{error}</FieldError> : null}
    </div>
  )
}

/**
 * The column a sheet's content draws in: the middle scrolls, the pinned footer holds the ONE gold primary at thumb height (direction rule 9).
 * The host draws the title row; this takes what is left of the sheet's 90% cap so the footer never covers content.
 */
export function SheetFrame({ children, footer }: { children: ReactNode; footer?: ReactNode }) {
  const { height, safeBottom, safeTop, mode } = useDevice()
  // Live, the sheet host sits over the tab bar (90% of the frame). A static frame draws the sheet inline above the tab bar, so it
  // must also stay under the status bar: the same sheet, the same content, a smaller room.
  const room = mode === 'static' ? height - safeTop - flat['size.tab-bar'] - safeBottom - flat['space.3'] : height * 0.9
  const cap = Math.floor(Math.min(height * 0.9, room) / 4) * 4
  const maxHeight = cap - flat['space.sheet-pad-top'] - flat['space.5'] - flat['size.control.md'] - flat['space.sheet-pad-bottom'] - safeBottom
  return (
    <div className="hv-sheet" data-gz="VenueSheet" style={{ maxBlockSize: maxHeight } as CSSProperties}>
      <div className="hv-sheet__content gz-no-scrollbar">{children}</div>
      {footer ? <div className="hv-sheet__foot">{footer}</div> : null}
    </div>
  )
}
