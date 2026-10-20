// StateNote: the state line inside a form or a sheet (danger / success / offline). Text diet (ADR 0034): a glyph, a title of at most three
// words, optional facts (a clock figure), and the sentence behind an info glyph (error recovery, 02-text-diet section 6). Never colour
// alone: glyph + word + tone. The system Banner carries its own gutter, so it cannot sit inside a padded body or a sheet.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, InfoButton } from '../../../../system'
import { useT } from '../../../../i18n'
import { cx } from './cx'
import './access.css'

export type NoteTone = 'danger' | 'success' | 'offline'

const ICON: Record<NoteTone, IconName> = { danger: 'warning-circle', success: 'check-circle', offline: 'offline' }

export function StateNote({
  tone,
  icon,
  children,
  facts,
  detail,
  detailTitle,
}: {
  tone: NoteTone
  /** A glyph that says more than the tone's (a lock, a key). */
  icon?: IconName
  children: ReactNode
  facts?: ReactNode
  /** The recovery paragraph, one tap away behind the info glyph. */
  detail?: ReactNode
  detailTitle?: string
}) {
  const tc = useT('common')
  return (
    <div className={cx('hxa-note', `hxa-note--${tone}`, detail ? 'hxa-note--info' : false)} data-gz="StateNote" data-tone={tone} role={tone === 'success' ? 'status' : 'alert'}>
      <Icon name={icon ?? ICON[tone]} size="sm" className="hxa-note__icon" />
      <p className="hxa-note__text gz-t-body-s">{children}</p>
      {facts ? <span className="hxa-note__facts">{facts}</span> : null}
      {detail ? (
        <InfoButton title={detailTitle ?? tc('commonLabelDetails')} className="hxa-note__info">
          {detail}
        </InfoButton>
      ) : null}
    </div>
  )
}
