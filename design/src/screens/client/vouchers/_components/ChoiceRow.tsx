// ChoiceRow: one of two equal choices (Use again, Refund): a glyph in a quiet disk, a title of one or two words, its facts (a date, a time) and a
// mirrored chevron. No sentence (ADR 0034). A whole row is the target (64 and up). Both choices carry the same weight: neither is gold.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import './choice-row.css'

export function ChoiceRow({ icon, title, facts, onPress, disabled }: { icon: IconName; title: string; facts?: ReactNode; onPress: () => void; disabled?: boolean }) {
  return (
    <button type="button" className="gz-reset gz-press gzv-choicerow" onClick={onPress} disabled={disabled}>
      <span className="gzv-choicerow__disk" aria-hidden="true">
        <Icon name={icon} size="sm" />
      </span>
      <span className="gzv-choicerow__text">
        <span className="gzv-choicerow__title gz-t-title">{title}</span>
        {facts ? <span className="gzv-choicerow__facts">{facts}</span> : null}
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
