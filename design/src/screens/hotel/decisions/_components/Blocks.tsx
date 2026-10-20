// Small blocks shared by the decision sheets (ADR 0034: glyphs, figures and drawings, no sentences). A section label, a glyph line, the
// voucher price as a glyph and a figure, a switch row led by a glyph, the consequence cells (glyph over one word) and the state
// composition of a sheet (the system EmptyState / SuccessState / ErrorState on the sheet's own gutter, with room for a facts row).
// Money is always integer fils through <Price>; nothing here types a number or a date.
import { useRef, type KeyboardEvent, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { EmptyState, ErrorState, Icon, Price, Switch, SuccessState, type EmptyStateProps, type IconTone } from '../../../../system'
import './blocks.css'

export function SectionLabel({ children, id }: { children: ReactNode; id?: string }) {
  return (
    <div className="gzd-label">
      <span id={id} className="gz-t-label">
        {children}
      </span>
    </div>
  )
}

/** A glyph and a very short text (a consequence, a limit): glyph 16, caption text. At most a few words. */
export function FactLine({ icon, tone = 'secondary', children }: { icon: IconName; tone?: IconTone; children: ReactNode }) {
  return (
    <p className="gzd-fact gz-t-caption">
      <Icon name={icon} size="xs" tone={tone} />
      <span className="gzd-fact__text">{children}</span>
    </p>
  )
}

/** The voucher price as a ticket glyph and an amount (the word is the accessible name): the figure of a context strip or a ledger. */
export function PriceFact({ fils, label, size = 'strong' }: { fils: number; label: string; size?: 'strong' | 'total' }) {
  return (
    <span className="gzd-pfact">
      <Icon name="ticket" size="sm" tone="success" />
      <span className="gz-sr-only">{label}</span>
      <Price fils={fils} size={size} />
    </span>
  )
}

/** A row led by a glyph in a rose disk, a one or two word title and the shared Switch; the whole row is the target (like ToggleRow). */
export function IconSwitchRow({ icon, title, checked, onChange }: { icon: IconName; title: string; checked: boolean; onChange: (on: boolean) => void }) {
  return (
    <div
      className="gzd-swrow"
      onClick={e => {
        if ((e.target as HTMLElement).closest('[role="switch"]')) return
        onChange(!checked)
      }}
    >
      <span className="gzd-disk" aria-hidden="true">
        <Icon name={icon} size="md" tone="primary" />
      </span>
      <span className="gzd-swrow__title gz-t-body">{title}</span>
      <Switch checked={checked} onChange={onChange} label={title} />
    </div>
  )
}

/** A collapsed row: glyph disk, a one or two word title and a chevron that turns; opens the block under it (the lower price). */
export function DiscloseRow({ icon, title, open, onToggle }: { icon: IconName; title: string; open: boolean; onToggle: () => void }) {
  return (
    <button type="button" className="gz-reset gz-press gzd-disclose" aria-expanded={open} onClick={onToggle}>
      <span className="gzd-disk" aria-hidden="true">
        <Icon name={icon} size="md" tone="primary" />
      </span>
      <span className="gzd-disclose__title gz-t-body">{title}</span>
      <Icon name={open ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
    </button>
  )
}

/** One to three picks as pips: filled = picked, open = still free to pick. The count is the accessible name, never a sentence on screen. */
export function PickPips({ count, max, label }: { count: number; max: number; label: string }) {
  return (
    <span className="gzd-pips" role="img" aria-label={label}>
      {Array.from({ length: max }, (_, i) => (
        <span key={i} className="gzd-pip" data-on={i < count || undefined} />
      ))}
    </span>
  )
}

export type ReasonOption<V extends string> = { value: V; icon: IconName; /** One word: the tile's label and its accessible name. */ label: string }

/**
 * A required single choice as equal glyph tiles (a glyph in a rose disk over one word), the same idiom as the consequence cells.
 * A radio group with a roving tab stop; the selected tile takes an ink border and an ink disk, so selection never rests on colour alone.
 * Used for the reasons of Decline and Cancel instead of wrapping chips, which broke into uneven rows in both languages.
 */
export function ReasonTiles<V extends string>({ options, value, onChange, label }: { options: readonly ReasonOption<V>[]; value: V | null; onChange: (v: V) => void; label: string }) {
  const group = useRef<HTMLDivElement>(null)
  const stop = Math.max(0, options.findIndex(o => o.value === value))
  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const rtl = getComputedStyle(e.currentTarget).direction === 'rtl'
    const forward = e.key === 'ArrowDown' || e.key === (rtl ? 'ArrowLeft' : 'ArrowRight')
    const back = e.key === 'ArrowUp' || e.key === (rtl ? 'ArrowRight' : 'ArrowLeft')
    if (!forward && !back) return
    e.preventDefault()
    const next = (i + (forward ? 1 : options.length - 1)) % options.length
    group.current?.querySelectorAll<HTMLElement>('[role="radio"]')[next]?.focus()
    const opt = options[next]
    if (opt) onChange(opt.value)
  }
  return (
    <div ref={group} className="gzd-tiles" role="radiogroup" aria-label={label} data-gz="ReasonTiles">
      {options.map((o, i) => {
        const on = o.value === value
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={on}
            tabIndex={i === stop ? 0 : -1}
            className="gz-reset gz-press gz-select gzd-tile"
            data-on={on || undefined}
            onClick={() => onChange(o.value)}
            onKeyDown={e => onKey(e, i)}
          >
            <span className="gzd-tile__disk" aria-hidden="true">
              <Icon name={o.icon} size="sm" tone={on ? 'on-dark' : 'primary'} />
            </span>
            <span className="gzd-tile__label gz-t-caption">{o.label}</span>
          </button>
        )
      })}
    </div>
  )
}

export type ConsequenceItem ={ icon: IconName; tone?: 'default' | 'danger' | 'success'; label: string }

/** What happens, as glyphs: one panel, equal columns divided by hairlines, each a glyph in a disk over one word. A list for assistive technology. */
export function ConsequenceRow({ items, label }: { items: readonly ConsequenceItem[]; label: string }) {
  return (
    <ul className="gzd-cons" aria-label={label}>
      {items.map(i => (
        <li key={i.icon + i.label} className="gzd-cons__cell" data-tone={i.tone ?? 'default'}>
          <span className="gzd-cons__disk" aria-hidden="true">
            <Icon name={i.icon} size="sm" tone={i.tone === 'danger' ? 'danger' : i.tone === 'success' ? 'success' : 'primary'} />
          </span>
          <span className="gzd-cons__label gz-t-caption">{i.label}</span>
        </li>
      ))}
    </ul>
  )
}

/** A quiet 48 high row that leads somewhere else (the softer way out): glyph, a one or two word title, a chevron that mirrors. */
export function LinkRow({ icon, title, onPress }: { icon: IconName; title: string; onPress: () => void }) {
  return (
    <button type="button" className="gz-reset gz-press gzd-link" onClick={onPress}>
      <Icon name={icon} size="md" tone="primary" />
      <span className="gzd-link__title gz-t-body">{title}</span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}

type SheetStateProps = Pick<EmptyStateProps, 'illustration' | 'title' | 'detail' | 'detailTitle' | 'action' | 'secondary'> & {
  kind?: 'empty' | 'success'
  /** Facts or a list under the composition (a FactRow, the picked dates). */
  children?: ReactNode
}

/** An empty or success composition inside a sheet: the drawing, a title of at most four words, the info glyph; the sheet footer owns the action. */
export function SheetState({ kind = 'empty', children, ...rest }: SheetStateProps) {
  const Comp = kind === 'success' ? SuccessState : EmptyState
  return (
    <div className="gzd-state" data-gz="SheetState">
      <Comp fill={false} size="lg" {...rest} />
      {children ? <div className="gzd-state__extra">{children}</div> : null}
    </div>
  )
}

/** The error composition inside a sheet: the warning drawing, "Something went wrong", one retry, the recovery sentence behind the info glyph. */
export function SheetError({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="gzd-state" data-gz="SheetState">
      <ErrorState fill={false} onRetry={onRetry} />
    </div>
  )
}
