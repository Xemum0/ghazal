// ProviderNote (CA-SVC-20, ADR 0038, round 2b, R3): the note that tells a service provider where to apply, made impossible to miss. One full-width
// row or card with the whole sentence visible ("Service provider? Apply in the Partner app"), a glyph at inline-start and a call to action at
// inline-end: a short "Apply" label in the accent colour with a chevron. At least 44 high (the card 64), the sentence wraps to two lines on the
// narrowest phone, and no info glyph hides any word. Two forms of the same note: `banner` is a rose card inside the screen's gutter at the TOP of
// the Services hub (CL-SERV-01: right under the Venues | Services switch, above the voucher strip and the category tiles, so it is in the first
// screen) and `row` is one row at the top of the Profile hub (CL-PROF-01: right under the identity header, on a full-width rose band).
// `footer` is the earlier name of `banner` (the note used to sit under the category list, below the fold): same card, kept as an alias.
// The target is the Partner app's store page, a URL kept in configuration (OQ-R2-04): the app opens it through `onOpen`; without it the
// note is drawn but inert (the gallery).
import { useT } from '../../i18n'
import { Icon } from '../core'
import { IconListRow } from '../core/IconListRow'
import './provider-note.css'

export type ProviderNoteProps = {
  /** `banner`: a rose card (Services hub, top of the page). `row`: a list row (Profile hub, top of the page). `footer`: the old name of `banner`. */
  variant?: 'banner' | 'footer' | 'row'
  /** The app opens the Partner app's store page from configuration; the prototype shows a toast. */
  onOpen?: () => void
  className?: string
}

export function ProviderNote({ variant = 'row', onOpen, className }: ProviderNoteProps) {
  const t = useT('client-services')
  const text = t('clientServicesProviderNote')
  const action = <span className="gz-pnote__cta gz-t-button">{t('clientServicesProviderNoteAction')}</span>
  if (variant === 'banner' || variant === 'footer') {
    const classes = ['gz-pnote', className].filter(Boolean).join(' ')
    const body = (
      <>
        <Icon name="user-plus" size="md" className="gz-pnote__glyph" />
        <span className="gz-pnote__text gz-t-body">{text}</span>
        <span className="gz-pnote__end">
          {action}
          <Icon name="chevron-right" size="sm" />
        </span>
      </>
    )
    return onOpen ? (
      <button type="button" className={`gz-reset gz-press ${classes}`} data-gz="ProviderNote" data-gz-id="provider-note" onClick={onOpen}>
        {body}
      </button>
    ) : (
      <div className={classes} data-gz="ProviderNote" data-gz-id="provider-note" role="note">
        {body}
      </div>
    )
  }
  return (
    <div data-gz="ProviderNote" data-gz-id="provider-note" role={onOpen ? undefined : 'note'}>
      <IconListRow icon="user-plus" last title={<span className="gz-t-body">{text}</span>} trailing={action} chevron onClick={onOpen} className={['gz-pnote-row', className].filter(Boolean).join(' ')} />
    </div>
  )
}
