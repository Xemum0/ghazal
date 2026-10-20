import { useId, useRef, type KeyboardEvent, type ReactNode } from 'react'
import { useFormat, useT } from '../../i18n'
import { useControllable } from './internal/useControllable'
import { rovingIndex } from './internal/roving'
import { Figures } from './internal/Figures'
import { useInputWords } from './internal/copy'
import { parseIso } from './internal/calendarModel'
import './internal/base.css'
import './timeslot.css'

export type SessionStatus = 'available' | 'held' | 'booked'

export type TimeSession = {
  id: string
  /** `Afternoon`, `Evening`, `Full day` (ADR 0002 D3 presets) or the hall's own session name. */
  label: string
  /** Venue-local wall time. An end at or before the start means the session ends after midnight on the next day (ADR 0002 D2). */
  start: { h: number; m: number }
  end: { h: number; m: number }
  status?: SessionStatus
  /** Per-session price in integer fils (shown in the numeric voice with `priceUnit`). */
  price?: number
}

export type TimeSlotPickerProps = {
  sessions: ReadonlyArray<TimeSession>
  value?: string | null
  defaultValue?: string | null
  onChange?: (id: string | null) => void
  /** The business day the sessions belong to (`YYYY-MM-DD`). Default: the prototype's today. */
  date?: string
  /** Accessible name of the group (`Session`). */
  label?: string
  /** The unit that follows a price (`per guest`). A price never appears without its unit (ADR 0010 D9). */
  priceUnit?: ReactNode
  disabled?: boolean
  className?: string
}

/**
 * Session picker (ADR 0002 D3: Afternoon 12:00 - 16:00, Evening 19:00 - 01:00, Full day). A radio group of 12-radius rows:
 * the name, the time range in the figures voice, a price or the reason it cannot be chosen. Selected = ink-900 border and ring
 * with a gold bead, like a chip. Booked sessions are struck and say so; held sessions stay selectable (requests allowed) and
 * carry a gold-700 bead and the word. Render it only when more than one session is free that day (ADR 0002 D5).
 */
export function TimeSlotPicker(props: TimeSlotPickerProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useInputWords()
  const uid = useId().replace(/:/g, '')
  const { sessions, disabled } = props
  const [value, setValue] = useControllable<string | null>(props.value, props.defaultValue ?? null, props.onChange)
  const ref = useRef<HTMLDivElement>(null)
  const base = parseIso(props.date ?? f.isoDay(f.now()))
  const flags = sessions.map(s => Boolean(disabled || s.status === 'booked'))
  const firstFree = flags.findIndex(x => !x)
  const selectedIdx = sessions.findIndex(s => s.id === value && !flags[sessions.indexOf(s)])
  const tabStop = selectedIdx >= 0 ? selectedIdx : firstFree

  const range = (s: TimeSession) => {
    const from = f.kuwaitDate(base.year, base.month, base.day, s.start.h, s.start.m)
    const crosses = s.end.h * 60 + s.end.m <= s.start.h * 60 + s.start.m
    const to = f.kuwaitDate(base.year, base.month, base.day + (crosses ? 1 : 0), s.end.h, s.end.m)
    return f.timeRange(from, to)
  }

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const next = rovingIndex(e, i, flags)
    if (next === null) return
    e.preventDefault()
    ref.current?.querySelectorAll<HTMLElement>('.gz-slot')[next]?.focus()
    const s = sessions[next]
    if (s) setValue(s.id)
  }

  return (
    <div ref={ref} className={['gz-slots', props.className ?? ''].filter(Boolean).join(' ')} data-gz="TimeSlotPicker" role="radiogroup" aria-label={props.label ?? w('session')}>
      {sessions.map((s, i) => {
        const status = s.status ?? 'available'
        const selected = s.id === value && !flags[i]
        const statusWord = status === 'booked' ? t('commonAvailabilityBooked') : status === 'held' ? t('commonAvailabilityHeld') : null
        const price = s.price !== undefined && status !== 'booked' ? f.moneyParts(s.price, { mode: 'browse' }) : null
        return (
          <button
            key={s.id}
            type="button"
            role="radio"
            aria-checked={selected}
            aria-disabled={flags[i] || undefined}
            aria-describedby={`${uid}-${s.id}`}
            tabIndex={i === tabStop ? 0 : -1}
            disabled={flags[i]}
            className="gz-in-btn gz-slot gz-press"
            data-selected={selected || undefined}
            data-status={status}
            onClick={() => setValue(s.id)}
            onKeyDown={e => onKey(e, i)}
          >
            {selected ? <span className="gz-bead gz-slot__bead" aria-hidden="true" /> : null}
            <span className="gz-slot__main">
              <span className="gz-slot__label gz-t-body" dir="auto">
                {s.label}
              </span>
              <span id={`${uid}-${s.id}`} className="gz-slot__time gz-t-caption">
                <Figures text={range(s)} />
              </span>
            </span>
            <span className="gz-slot__end">
              {status === 'held' ? <span className="gz-slot__held" aria-hidden="true" /> : null}
              {statusWord ? <span className="gz-slot__status gz-t-caption">{statusWord}</span> : null}
              {price ? (
                <span className="gz-slot__price">
                  <span className="gz-slot__amount gz-t-price-strong">
                    <bdi dir="ltr">{price.fractionIsZero ? price.integer : price.amount}</bdi>
                  </span>
                  <span className="gz-slot__unit gz-t-caption">
                    {price.currency}
                    {props.priceUnit ? <> · {props.priceUnit}</> : null}
                  </span>
                </span>
              ) : null}
            </span>
          </button>
        )
      })}
    </div>
  )
}
