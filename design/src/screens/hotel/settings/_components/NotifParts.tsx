// The pieces of Notification preferences (text diet, ADR 0034): one switch row per alert type (a glyph disk, one word, the switch) and the
// shared "about this page" sheet that the top bar's (i) opens. The sentences that used to sit under every switch (when it fires, that it is
// a push, that WhatsApp is the system's) live in that sheet, not on the screen.
import type { MouseEvent, ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, InfoSheet, Switch } from '../../../../system'

export type PrefRowProps = {
  icon: IconName
  title: string
  checked: boolean
  onChange: (on: boolean) => void
  disabled?: boolean
  last?: boolean
}

/** The whole row is the target; the switch is the one focusable control and carries the title as its name. */
export function PrefRow({ icon, title, checked, onChange, disabled, last }: PrefRowProps) {
  const onRow = (e: MouseEvent<HTMLDivElement>) => {
    if (disabled) return
    if ((e.target as HTMLElement).closest('[role="switch"]')) return
    onChange(!checked)
  }
  return (
    <div className={`hs-pref${last ? ' is-last' : ''}`} data-gz="PrefRow" data-disabled={disabled || undefined} onClick={onRow}>
      <span className="hs-pref__disk" aria-hidden="true">
        <Icon name={icon} size="md" tone={disabled ? 'disabled' : 'primary'} />
      </span>
      <span className="hs-pref__title gz-t-title">{title}</span>
      <Switch checked={checked} onChange={onChange} disabled={disabled} label={title} />
    </div>
  )
}

/** The (i) of a settings page: a sheet of at most three short paragraphs, each with its glyph. */
export function AboutSheet({ open, onClose, title, lines }: { open: boolean; onClose: () => void; title: string; lines: readonly { icon: IconName; text: ReactNode }[] }) {
  return (
    <InfoSheet open={open} onClose={onClose} title={title}>
      <ul className="hs-about">
        {lines.map((line, i) => (
          <li key={i} className="hs-about__line">
            <Icon name={line.icon} size="sm" tone="secondary" />
            <span className="gz-t-body">{line.text}</span>
          </li>
        ))}
      </ul>
    </InfoSheet>
  )
}
