// Form pieces of the provider screens: an inline field error, a bilingual field pair with its completeness marker, and a KD price field that
// keeps integer fils (ADR 0010: numeric keypad, Eastern digits normalised, up to three decimals).
import { useEffect, useState, type ReactNode } from 'react'
import { Icon, TextArea, TextField } from '../../../../system'
import { kdText, parseKd } from './money'
import { useFormat, useP } from './bits'
import { useLang } from '../../../../shell/lang'
import './fields.css'

/** An inline message under a control: glyph + words, danger ink (state is never colour alone). */
export function FieldError({ children }: { children: ReactNode }) {
  return (
    <p className="hp-err gz-t-caption" role="alert">
      <Icon name="warning-circle" size="xs" tone="danger" />
      <span className="hp-err__text">{children}</span>
    </p>
  )
}

/** Arabic and English completeness: both are required before a listing goes to review (PA-LST-02). */
export function Completeness({ ar, en }: { ar: boolean; en: boolean }) {
  const { t } = useP()
  const item = (done: boolean, label: string) => (
    <span className="hp-comp__item gz-t-caption" data-done={done || undefined}>
      <Icon name={done ? 'check-circle' : 'clock'} size="xs" tone={done ? 'success' : 'secondary'} />
      <span>{label}</span>
    </span>
  )
  return (
    <p className="hp-comp" role="status">
      {item(ar, t('hotelProviderLangArabic'))}
      {item(en, t('hotelProviderLangEnglish'))}
    </p>
  )
}

export type BilingualFieldProps = {
  /** What the pair is, in the UI language ("Title", "Description"). */
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
  rows?: number
}

/** The current language's field first, then the other; one completeness marker under the pair. */
export function BilingualField({ label, ar, en, onAr, onEn, multiline = false, errorAr, errorEn, helper, maxLength, rows = 3 }: BilingualFieldProps) {
  const { t } = useP()
  const { lang } = useLang()
  const field = (code: 'ar' | 'en') => {
    const value = code === 'ar' ? ar : en
    const set = code === 'ar' ? onAr : onEn
    const error = code === 'ar' ? errorAr : errorEn
    const name = t(code === 'ar' ? 'hotelProviderFieldInArabic' : 'hotelProviderFieldInEnglish', { field: label })
    return multiline ? (
      <TextArea key={code} label={name} lang={code} rows={rows} maxLength={maxLength} value={value} onValueChange={set} error={error} />
    ) : (
      <TextField key={code} label={name} lang={code} maxLength={maxLength} value={value} onValueChange={set} error={error} />
    )
  }
  const order: Array<'ar' | 'en'> = lang === 'ar' ? ['ar', 'en'] : ['en', 'ar']
  return (
    <div className="hp-bi" role="group" aria-label={label}>
      {order.map(field)}
      {helper ? <p className="gz-t-caption hp-bi__helper">{helper}</p> : null}
      <Completeness ar={ar.trim() !== ''} en={en.trim() !== ''} />
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
}

/** A KD amount: numeric keypad, Eastern digits normalised, up to three decimals, stored as integer fils. */
export function PriceField({ label, fils, onChange, helper, error }: PriceFieldProps) {
  const { t } = useP()
  const f = useFormat()
  const [text, setText] = useState(() => kdText(fils))
  const parsed = parseKd(f, text)
  // An outside change (a reset) rewrites the text; typing keeps what the person typed.
  useEffect(() => {
    if (fils !== null && fils !== parsed) setText(kdText(fils))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fils])
  const invalid = text.trim() !== '' && parsed === null
  return (
    <TextField
      label={label}
      helper={helper}
      error={error ?? (invalid ? t('hotelProviderPriceError') : undefined)}
      inputMode="decimal"
      dir="ltr"
      value={text}
      onValueChange={v => {
        setText(v)
        onChange(parseKd(f, v))
      }}
      startAdornment={<span className="gz-t-label hp-cur">{f.moneyParts(0).currency}</span>}
    />
  )
}
