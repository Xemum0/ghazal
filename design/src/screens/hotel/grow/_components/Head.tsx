// Head: the title of a section of a form or a dashboard as a glyph in a quiet disk and one or two words. The glyph says what the section
// is about before the word does; the optional trailing slot takes the (i) of that section (voucher terms, definitions).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import './head.css'

export type HeadProps = {
  icon: IconName
  title: ReactNode
  trailing?: ReactNode
}

export function Head({ icon, title, trailing }: HeadProps) {
  return (
    <div className="gh-head" data-gz="GrowHead">
      <span className="gh-head__disk" aria-hidden="true">
        <Icon name={icon} size="sm" tone="primary" />
      </span>
      <h2 className="gz-t-ui-title gh-head__title">{title}</h2>
      {trailing ? <span className="gh-head__trail">{trailing}</span> : null}
    </div>
  )
}
