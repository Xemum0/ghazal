// Small local pieces of the Profile flow, built on the text-diet system (ADR 0034): the sheet frame (own header, one scrolling middle,
// pinned footer: with a `title` the system Sheet's header sits in the drag zone and a real click on its close button is swallowed, see
// requests.md), the choice list (a language, the digits, a role), the switch row (glyph, one word, a switch) and the picker row of an
// edit form (glyph, the answer, a chevron; the field's name is read by assistive technology, not drawn).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { flat } from '@gz/tokens'
import { useDevice } from '../../../../shell/device/context'
import { useLang } from '../../../../shell/lang'
import { BarButton, Button, Icon, IconListRow, SectionHeader, SheetHeader, Switch, ThreadBead, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './parts.css'

// ---------------------------------------------------------------- mixed values

/**
 * A value that mixes figures and Arabic words (`14 يناير`, `63 يومًا`, `2 د.ك`, `من 10:00 م إلى 9:00 ص`) inside a figure-role container.
 * The figure roles are LTR isolates, which reverse the order of the runs for an Arabic reader; an explicit RTL isolate inside restores it
 * (the same finding as requests.md "FactChip Arabic order"; this wrapper stays correct once the system fixes it).
 */
export function Mixed({ children }: { children: ReactNode }) {
  const { lang } = useLang()
  return lang === 'ar' ? <bdi dir="rtl">{children}</bdi> : <>{children}</>
}

// ---------------------------------------------------------------- picker row

export type PickRowProps = {
  icon: IconName
  /** What the row sets (Date, Guests, Budget ...). Read by assistive technology, never drawn. */
  label: string
  /** The answer: a formatter string, a FactRow or any node. */
  children: ReactNode
  /** A second quiet line (the Hijri date). */
  sub?: ReactNode
  onClick?: () => void
  disabled?: boolean
  /** The answer is a placeholder ("Not decided"): quieter than a value. */
  empty?: boolean
  last?: boolean
}

/** A picker row of an edit form: glyph disk, the answer in the title role, a mirrored chevron. 64 min, a hairline under it. */
export function PickRow({ icon, label, children, sub, onClick, disabled, empty, last }: PickRowProps) {
  const body = (
    <>
      <span className="gz-sr-only">{label}</span>
      <span className={empty ? 'gzpr-pick__empty' : undefined}>{children}</span>
    </>
  )
  return (
    <div className={`gzpr-pick${disabled ? ' is-disabled' : ''}`} data-gz="PickRow">
      <IconListRow icon={icon} title={body} facts={sub} chevron onClick={disabled ? undefined : onClick} last={last} />
    </div>
  )
}

// ---------------------------------------------------------------- switch row

export type SwitchRowProps = {
  icon: IconName
  title: ReactNode
  /** A fact under the title (a FactChip): the exception, not the rule. */
  fact?: ReactNode
  checked: boolean
  onChange: (on: boolean) => void
  disabled?: boolean
  /** The change is being saved: the row waits (dimmed, announced as busy). */
  busy?: boolean
  /** The accessible name of the switch (the title as text). */
  label: string
  /** An InfoButton beside the switch (a rule behind the (i) sheet). */
  info?: ReactNode
  /** A row of a group that opened under its master switch: the disk steps in. */
  nested?: boolean
  last?: boolean
}

/** A 64 row with a switch at inline-end, edge to edge like the other rows. The whole row toggles; the switch is the one control (never gold). */
export function SwitchRow({ icon, title, fact, checked, onChange, disabled, busy, label, info, nested, last }: SwitchRowProps) {
  const locked = Boolean(disabled || busy)
  return (
    <div
      className={`gzpr-swrow${last ? ' is-last' : ''}${locked ? ' is-locked' : ''}${nested ? ' is-nested' : ''}`}
      data-gz="SwitchRow"
      aria-busy={busy || undefined}
      onClick={e => {
        if (locked) return
        const el = e.target as HTMLElement
        // A click inside the info sheet (a portal child) bubbles through React but is not inside this row.
        if (!e.currentTarget.contains(el) || el.closest('[role="switch"]') || el.closest('[aria-haspopup]')) return
        onChange(!checked)
      }}
    >
      <span className="gz-irow__disk" aria-hidden="true">
        <Icon name={icon} size="md" />
      </span>
      <span className="gzpr-swrow__text">
        <span className="gzpr-swrow__title gz-t-title">{title}</span>
        {fact ? <span className="gzpr-swrow__fact">{fact}</span> : null}
      </span>
      {info}
      <Switch checked={checked} onChange={onChange} disabled={locked} label={label} />
    </div>
  )
}

// ---------------------------------------------------------------- sheet frame

/** Share of the frame a sheet may take; the same 90% the system Sheet uses, snapped to the 4-pt grid. */
function useSheetHeight(share = 0.9): number {
  const { height, safeBottom } = useDevice()
  const max = Math.floor((height * share) / flat['space.1']) * flat['space.1']
  // The Sheet adds 12 top, a 20 grab zone, 24 bottom and the home-indicator inset around what we draw.
  return max - (flat['space.3'] + flat['space.5'] + flat['space.6'] + safeBottom)
}

export type SheetBoxProps = {
  title: ReactNode
  children: ReactNode
  footer?: ReactNode
  /** Take the full sheet height (a calendar, a long list) so the header and footer stay put and only the middle scrolls. */
  fill?: boolean
  onClose?: () => void
  /** A back control at the start of the header instead of a title only (a picker inside a picker). */
  onBack?: () => void
  backLabel?: string
}

export function SheetBox({ title, children, footer, fill = false, onClose, onBack, backLabel }: SheetBoxProps) {
  const nav = useNav()
  const height = useSheetHeight()
  const close = onClose ?? (() => nav.closeSheet())
  return (
    <div className="gzpr-sheet" data-gz="ProfileSheet" style={fill ? { blockSize: height } : undefined}>
      {onBack ? (
        <header className="gz-sheet__header gzpr-sheet__head">
          <BarButton icon="back" label={backLabel ?? ''} onPress={onBack} />
          <h2 className="gz-sheet__title gz-t-d1">{title}</h2>
        </header>
      ) : (
        <SheetHeader title={title} onClose={close} />
      )}
      <div className="gzpr-sheet__scroll gz-no-scrollbar">{children}</div>
      {footer ? <div className="gzpr-sheet__foot">{footer}</div> : null}
    </div>
  )
}

/** The Done button every picker sheet ends with: the one gold action of the sheet. */
export function DoneButton({ onClick, label, loading }: { onClick: () => void; label?: string; loading?: boolean }) {
  const c = useT('common')
  return (
    <Button variant="primary" fullWidth onClick={onClick} loading={loading}>
      {label ?? c('commonActionDone')}
    </Button>
  )
}

// ---------------------------------------------------------------- choice list

export type ChoiceOption<V extends string> = { value: V; title: ReactNode; lang?: 'ar' | 'en' }

/**
 * One choice among a few, as large rows (a language, the digits, a role): radio semantics, radius 8, the chosen row takes the ink border,
 * weight 500 and the gold bead (the chip's selected anatomy). A row is at least 64 high; arrows follow the reading direction.
 */
export function ChoiceList<V extends string>({ label, value, onChange, options }: { label: string; value: V; onChange: (v: V) => void; options: ReadonlyArray<ChoiceOption<V>> }) {
  return (
    <div className="gzpr-choices" role="radiogroup" aria-label={label} data-gz="ChoiceList">
      {options.map(o => {
        const on = o.value === value
        return (
          <button key={o.value} type="button" role="radio" aria-checked={on} className={`gz-reset gz-press gzpr-choice${on ? ' is-on' : ''}`} onClick={() => onChange(o.value)}>
            <span className="gzpr-choice__title gz-t-body" lang={o.lang}>
              {o.title}
            </span>
            <span className="gzpr-choice__mark">{on ? <ThreadBead /> : null}</span>
          </button>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------- section head

/** The client section head (khayt, serif d2). The khayt draws once as it is first seen in the player; a static frame shows it drawn. */
export function Head({ title }: { title: ReactNode }) {
  const live = useDevice().mode === 'live'
  return <SectionHeader title={title} draw={live ? 'inview' : false} />
}
