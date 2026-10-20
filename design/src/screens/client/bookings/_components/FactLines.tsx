// FactLines: ruled rows of glyph + value, no label (ADR 0034 section 2). The label of a fact is its accessible name, never on screen.
// Plain rows, not targets; an `onPress` makes the row a button with the mirrored chevron. Hairline between rows.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import './fact-lines.css'

export type FactLine = {
  icon: IconName
  /** What the fact is (Hall, Package, Notes). Read by assistive technology, not shown. */
  label: string
  value: ReactNode
  /** A glyph or a figure at inline-end (the reception symbol of a hall). */
  trailing?: ReactNode
  onPress?: () => void
  /** Names are typed by people: align by their own first strong character. */
  auto?: boolean
}

export function FactLines({ lines }: { lines: FactLine[] }) {
  return (
    <ul className="gzb-flines" data-gz="FactLines">
      {lines.map((line, i) => {
        const body = (
          <>
            <Icon name={line.icon} size="sm" tone="secondary" className="gzb-flines__icon" />
            <span className="gzb-flines__text">
              <span className="gz-sr-only">{line.label}</span>
              <span className="gzb-flines__value gz-t-body-s">{line.auto ? <bdi dir="auto">{line.value}</bdi> : line.value}</span>
            </span>
            {line.trailing ? <span className="gzb-flines__trail">{line.trailing}</span> : null}
            {line.onPress ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
          </>
        )
        return (
          <li key={i} className="gzb-flines__li">
            {line.onPress ? (
              <button type="button" className="gz-reset gzb-flines__row gz-press" onClick={line.onPress}>
                {body}
              </button>
            ) : (
              <div className="gzb-flines__row">{body}</div>
            )}
          </li>
        )
      })}
    </ul>
  )
}
