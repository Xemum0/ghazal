// AsideInfo: the one sentence a step may keep (ADR 0034 section 6) behind a quiet row: a glyph, at most one word, and the info glyph. Tapping
// anywhere on the row opens the InfoSheet (title of at most three words, the paragraph, Done). Optional `action` adds a second button
// inside the sheet (read the terms), which closes the sheet before it acts.
import { useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, Icon, InfoSheet } from '../../../../system'
import './step.css'

export type AsideInfoProps = {
  icon: IconName
  /** The one word on the row. */
  word: string
  /** The sheet title (at most three words). */
  title: string
  children: ReactNode
  action?: { label: string; onPress: () => void }
  className?: string
}

export function AsideInfo({ icon, word, title, children, action, className }: AsideInfoProps) {
  const [open, setOpen] = useState(false)
  return (
    <>
      <button type="button" className={className ? `gz-reset gz-press bk-aside ${className}` : 'gz-reset gz-press bk-aside'} aria-haspopup="dialog" onClick={() => setOpen(true)} data-gz="AsideInfo">
        <Icon name={icon} size="sm" />
        <span className="gz-t-body-s">{word}</span>
        <Icon name="info" size="sm" />
      </button>
      <InfoSheet open={open} onClose={() => setOpen(false)} title={title}>
        {children}
        {action ? (
          <Button
            variant="tertiary"
            onClick={() => {
              setOpen(false)
              action.onPress()
            }}
          >
            {action.label}
          </Button>
        ) : null}
      </InfoSheet>
    </>
  )
}
