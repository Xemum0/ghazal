// InfoButton and InfoSheet (ADR 0034, docs/design/02-text-diet.md section 6): where the paragraphs that survive the diet live.
// Only three kinds of paragraph may exist: legal consent, cancellation and voucher terms, error recovery. None is on the screen:
// a 44 px info glyph sits next to the thing it explains and opens a sheet (title of at most three words, the paragraph, `Done`).
// The sheet is the shared PickerSheet: drag, scrim, Esc, focus trap and focus return, portal into the device frame.
import { useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { Button } from '../core/Button'
import { IconButton } from '../core/IconButton'
import { PickerSheet } from './PickerSheet'
import './info.css'

export type InfoSheetProps = {
  open: boolean
  onClose: () => void
  /** At most three words. */
  title: string
  /** The paragraph(s). Plain text nodes; one idea per paragraph. */
  children: ReactNode
}

export function InfoSheet({ open, onClose, title, children }: InfoSheetProps) {
  const t = useT('common')
  return (
    <PickerSheet
      open={open}
      onClose={onClose}
      title={title}
      footer={
        <Button variant="secondary" fullWidth onClick={onClose}>
          {t('commonActionDone')}
        </Button>
      }
    >
      <div className="gz-info__body gz-t-body">{children}</div>
    </PickerSheet>
  )
}

export type InfoButtonProps = {
  /** Sheet title (at most three words). */
  title: string
  children: ReactNode
  /** Accessible name of the glyph. Default: the shared "More info". */
  label?: string
  icon?: IconName
  className?: string
}

/** The info glyph (44 target) and the sheet it opens. Place it beside the checkbox, the card header or the error it explains. */
export function InfoButton({ title, children, label, icon = 'info', className }: InfoButtonProps) {
  const t = useT('common')
  const [open, setOpen] = useState(false)
  return (
    <>
      <IconButton
        icon={icon}
        iconSize="sm"
        label={label ?? t('commonA11yInfo')}
        className={className}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={() => setOpen(true)}
      />
      <InfoSheet open={open} onClose={() => setOpen(false)} title={title}>
        {children}
      </InfoSheet>
    </>
  )
}
