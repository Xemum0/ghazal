// InlineNote: a state line inside a sheet or a form (the system Banner carries its own gutter, so it cannot sit inside a sheet body).
// Text diet: a glyph, a title of at most three words, optional facts (a timer figure), and the long sentence behind an info glyph
// (error recovery, ADR 0034 section 6). One optional one-word action at the end edge. Never colour alone: glyph + word + tone.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, Icon, InfoButton } from '../../../../system'
import { useT } from '../../../../i18n'
import { cx } from './cx'
import './auth.css'

export type NoteTone = 'danger' | 'success' | 'info' | 'offline'

const ICON: Record<NoteTone, IconName> = { danger: 'warning-circle', success: 'check-circle', info: 'info', offline: 'offline' }

export function InlineNote({
  tone,
  icon,
  children,
  facts,
  detail,
  detailTitle,
  action,
}: {
  tone: NoteTone
  /** A glyph that says more than the tone's (a lock, a face). */
  icon?: IconName
  children: ReactNode
  facts?: ReactNode
  /** The recovery paragraph, one tap away behind the info glyph. */
  detail?: ReactNode
  detailTitle?: string
  action?: { label: string; onPress: () => void }
}) {
  const tc = useT('common')
  return (
    <div className={cx('gza-note', `gza-note--${tone}`)} data-gz="InlineNote" data-tone={tone} role={tone === 'danger' || tone === 'offline' ? 'alert' : 'status'}>
      <Icon name={icon ?? ICON[tone]} size="sm" className="gza-note__icon" />
      <p className="gza-note__text gz-t-body-s">{children}</p>
      {facts ? <span className="gza-note__facts">{facts}</span> : null}
      {detail ? (
        <InfoButton title={detailTitle ?? tc('commonLabelDetails')} className="gza-note__info">
          {detail}
        </InfoButton>
      ) : null}
      {action ? (
        <Button variant="tertiary" onClick={action.onPress}>
          {action.label}
        </Button>
      ) : null}
    </div>
  )
}
