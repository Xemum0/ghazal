// ChoiceRow: one option of a short single choice, as a ruled radio row (ADR 0034): a glyph, at most three words, the gold bead when chosen
// (gold is the verb: chosen). A radio in a radiogroup: the whole row is the 56 high target.
import type { IconName } from '@gz/tokens'
import { Icon, ThreadBead } from '../../../../system'
import './choice-row.css'

export function ChoiceRow({ icon, label, selected, onSelect }: { icon: IconName; label: string; selected: boolean; onSelect: () => void }) {
  return (
    <button type="button" role="radio" aria-checked={selected} className={`gz-reset gzb-choice gz-press${selected ? ' is-selected' : ''}`} data-gz="ChoiceRow" onClick={onSelect}>
      <Icon name={icon} size="md" tone={selected ? 'primary' : 'secondary'} />
      <span className="gzb-choice__label gz-t-title">{label}</span>
      <span className="gzb-choice__radio" aria-hidden="true">
        <ThreadBead tone={selected ? 'gold' : 'hollow'} />
      </span>
    </button>
  )
}
