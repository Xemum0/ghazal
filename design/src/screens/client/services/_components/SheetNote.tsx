// SheetNote (CL-SERV-04): a quiet note inside a sheet (the sheet body already owns the gutter, so the page Banner would double it).
// An icon and a fragment of a few words on rose-100 (a quiet note is what rose is for); the danger tone is the functional tint. State is icon
// + text. Anything longer than a fragment (what was not lost, what was not charged) lives behind the info glyph at the end (ADR 0034).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, InfoButton } from '../../../../system'
import './sheet-note.css'

export type SheetNoteProps = {
  icon: IconName
  tone?: 'quiet' | 'danger'
  children: ReactNode
  /** The recovery text: opens in an info sheet from a glyph at the end of the note. */
  info?: { title: string; body: ReactNode }
}

export function SheetNote({ icon, tone = 'quiet', children, info }: SheetNoteProps) {
  return (
    <div className={`gzs-snote gz-t-body-s${tone === 'danger' ? ' gzs-snote--danger' : ''}`} role={tone === 'danger' ? 'alert' : 'status'} data-gz="SheetNote">
      <Icon name={icon} size="sm" />
      <span className="gzs-snote__text">{children}</span>
      {info ? (
        <InfoButton title={info.title}>
          <p>{info.body}</p>
        </InfoButton>
      ) : null}
    </div>
  )
}
