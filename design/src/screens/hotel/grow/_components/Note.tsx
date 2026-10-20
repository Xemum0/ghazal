// Note: a quiet in-flow line: a glyph, a fragment of a few words, an optional (i) at the inline-end for the sentence that explains it
// (ADR 0034 section 6), and an optional action. Tint, never a border: rose for a heads-up, the danger tint for a refusal. The system Banner
// pads itself with the screen gutter, which squeezes a line inside a padded body; a note keeps its own width.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, Icon } from '../../../../system'
import './note.css'

export type NoteProps = {
  tone?: 'info' | 'danger'
  icon?: IconName
  children: ReactNode
  /** An InfoButton: the explaining sentence lives behind it, never on the screen. */
  info?: ReactNode
  action?: { label: string; onPress?: () => void }
}

export function Note({ tone = 'info', icon, children, info, action }: NoteProps) {
  return (
    <div className="gn-note" data-tone={tone} data-info={info ? '' : undefined} role={tone === 'danger' ? 'alert' : 'status'}>
      <Icon name={icon ?? (tone === 'danger' ? 'warning-circle' : 'info')} size="sm" tone={tone === 'danger' ? 'danger' : 'primary'} />
      <p className="gz-t-body-s gn-note__text">{children}</p>
      {action ? (
        <Button variant="tertiary" onClick={action.onPress}>
          {action.label}
        </Button>
      ) : null}
      {info ? <span className="gn-note__info">{info}</span> : null}
    </div>
  )
}
