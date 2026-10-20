// The email a code went to, as a value and not a sentence: the envelope on a quiet disk and the masked address in an LTR island
// (h•••@aurelia.example). The sentence "Sent to ..." is the accessible name.
import { Icon } from '../../../../system'
import { Ltr, useT } from '../../../../i18n'
import './access.css'

export function NumberRow({ masked }: { masked: string }) {
  const t = useT('hotel-access')
  return (
    <div className="hxa-number" data-gz="NumberRow">
      <span className="hxa-number__mark" aria-hidden="true">
        <Icon name="mail" size="sm" />
      </span>
      <span className="gz-sr-only">{t('hotelAccessVerifySentTo', { email: masked })}</span>
      <p className="hxa-number__value gz-t-title" aria-hidden="true">
        <Ltr>{masked}</Ltr>
      </p>
    </div>
  )
}
