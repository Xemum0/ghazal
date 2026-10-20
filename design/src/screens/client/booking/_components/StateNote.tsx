// StateNote: a state line that has something to do (verify the number, see your open requests). A glyph, a fragment of a few words, one
// action beneath at inline-start, and optionally the info glyph that opens the sentence behind it. Rose-100 panel (danger tone for a taken date).
// Local to this flow: the system Banner puts its action beside the text (see requests.md).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, Icon, InfoButton } from '../../../../system'
import './note.css'

export type StateNoteProps = {
  icon: IconName
  children: string
  tone?: 'quiet' | 'danger'
  action?: { label: string; onPress: () => void }
  /** The sentence behind the info glyph (sheet title and body). */
  info?: { title: string; body: ReactNode }
}

export function StateNote({ icon, children, action, tone = 'quiet', info }: StateNoteProps) {
  return (
    <div className={tone === 'danger' ? 'bk-note-card is-danger' : 'bk-note-card'} role={tone === 'danger' ? 'alert' : 'status'} data-gz="StateNote">
      <Icon name={icon} size="md" className="bk-note-card__icon" />
      <div className="bk-note-card__body">
        <p className="bk-note-card__text gz-t-body-s">{children}</p>
        {action ? (
          <Button variant="tertiary" onClick={action.onPress}>
            {action.label}
          </Button>
        ) : null}
      </div>
      {info ? (
        <InfoButton title={info.title} className="bk-note-card__info">
          {info.body}
        </InfoButton>
      ) : null}
    </div>
  )
}
