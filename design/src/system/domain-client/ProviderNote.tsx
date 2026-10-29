// ProviderNote (CA-SVC-20, ADR 0038): the one small note that tells a service provider where to apply. A glyph, one line ("Service provider?
// Apply in the Partner app") and a quiet external-link glyph at inline-end. Two forms of the same note: `footer` closes the Services hub
// (CL-SERV-01, a compact quiet line inside the screen's gutter) and `row` is a row of the Profile hub list (CL-PROF-01, the list's own row).
// It opens nothing in the prototype: the target is the Partner app's store page, a URL kept in configuration (OQ-R2-04), so there is no tap
// and no chevron. Text diet: no paragraph, one line (it may wrap to two on the narrowest phone).
import { useT } from '../../i18n'
import { Icon } from '../core'
import { IconListRow } from '../core/IconListRow'
import './provider-note.css'

export type ProviderNoteProps = {
  /** `footer`: a compact quiet line (Services hub). `row`: a list row (Profile hub). */
  variant?: 'footer' | 'row'
  /** Reserved for the day the URL exists: the store link is opened by the app, never typed here. */
  onOpen?: () => void
  className?: string
}

export function ProviderNote({ variant = 'row', onOpen, className }: ProviderNoteProps) {
  const t = useT('client-services')
  const text = t('clientServicesProviderNote')
  if (variant === 'footer') {
    return (
      <div className={['gz-pnote', className].filter(Boolean).join(' ')} data-gz="ProviderNote" data-gz-id="provider-note" role="note">
        <Icon name="user-plus" size="sm" tone="secondary" />
        <span className="gz-pnote__text gz-t-body-s">{text}</span>
        <Icon name="external-link" size="sm" tone="secondary" />
      </div>
    )
  }
  return (
    <div data-gz="ProviderNote" data-gz-id="provider-note" role="note">
      <IconListRow icon="user-plus" last title={text} trailing={<Icon name="external-link" size="sm" tone="secondary" />} onClick={onOpen} chevron={false} className={className} />
    </div>
  )
}
