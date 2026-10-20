// IconListRow (ADR 0034): the list row of the diet. A leading glyph (in a quiet disk) or a small illustration, a one-line title (at
// most three words), a trailing fact or chevron. No subtitle: a second piece of information is a fact (FactRow) under the title.
// A thin layer over ListRow so the 64 minimum, the hairline, the pressed state and the mirrored chevron stay one implementation.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Illustration } from '../illustration/Illustration'
import type { IllustrationName } from '../illustration/registry'
import { Icon } from './Icon'
import { ListRow } from './ListRow'
import './icon-list-row.css'

export type IconListRowProps = {
  title: ReactNode
  icon?: IconName
  /** A drawing instead of a glyph (state lists, partner tasks): raises the row to the illustration size. */
  illustration?: IllustrationName
  /** A fact, a figure or a StatusIcon at inline-end, before the chevron. */
  trailing?: ReactNode
  /** Facts under the title (a FactRow). The exception, not the rule. */
  facts?: ReactNode
  chevron?: boolean
  onClick?: () => void
  selected?: boolean
  tone?: 'default' | 'danger'
  autoDir?: boolean
  flush?: boolean
  last?: boolean
  className?: string
}

export function IconListRow({ title, icon, illustration, trailing, facts, chevron, onClick, selected, tone, autoDir, flush, last, className }: IconListRowProps) {
  const leading = illustration ? (
    <span className="gz-irow__art" aria-hidden="true">
      <Illustration name={illustration} size="sm" />
    </span>
  ) : icon ? (
    <span className="gz-irow__disk" aria-hidden="true">
      <Icon name={icon} size="md" tone={tone === 'danger' ? 'danger' : 'primary'} />
    </span>
  ) : undefined
  return (
    <ListRow
      title={title}
      subtitle={facts}
      leading={leading}
      trailing={trailing}
      chevron={chevron ?? Boolean(onClick)}
      onClick={onClick}
      selected={selected}
      tone={tone}
      autoDir={autoDir}
      flush={flush}
      last={last}
      className={className}
    />
  )
}
