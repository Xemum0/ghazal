// One way to pay, as a radio tile (text diet: the mark is the label). Three tiles sit side by side in platform order; the glyph and the
// typeset wordmark name the method (no brand artwork is copied), the accessible name is the full method name. Selected = ink border and
// the gold bead (gold is the choice, never a fill). After a failed KNET attempt the first tile carries one quiet word, "Suggested".
import { Icon, ThreadBead } from '../../../../system'
import { cx } from '../../../../system/core/cx'
import { useT } from '../../../../i18n'
import { METHOD_ICON, METHOD_LABEL, type MethodKey } from './data'
import './method-tile.css'

/** The typeset wordmark under the glyph: Latin, left to right, never translated. */
const WORD: Record<MethodKey, string> = {
  knet: 'KNET',
  apple_pay: 'Pay',
  google_pay: 'Pay',
  card: 'VISA · MC',
}

export type MethodTileProps = {
  method: MethodKey
  selected: boolean
  onSelect: () => void
  /** The gateway recommends this one after a KNET failure. */
  suggested?: boolean
  disabled?: boolean
}

export function MethodTile({ method, selected, onSelect, suggested = false, disabled = false }: MethodTileProps) {
  const t = useT('client-payment')
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={t(METHOD_LABEL[method])}
      disabled={disabled}
      data-gz="MethodTile"
      data-method={method}
      className={cx('gz-reset gz-press pm-tile', selected && 'is-selected', disabled && 'is-disabled')}
      onClick={onSelect}
    >
      <span className="pm-tile__bead" aria-hidden="true">
        <ThreadBead tone={selected ? 'gold' : 'hollow'} />
      </span>
      <span className="pm-tile__mark" aria-hidden="true">
        <Icon name={METHOD_ICON[method]} size="md" />
        <span className="pm-tile__word">{WORD[method]}</span>
      </span>
      {suggested ? <span className="pm-tile__hint gz-t-caption">{t('clientPaymentMethodSuggested')}</span> : null}
    </button>
  )
}
