// The number a code went to, as a value and not a sentence: the WhatsApp mark on a quiet disk and the masked figure in an LTR island
// (+965 •••• 0040). The sentence "Sent to ..." is the accessible name.
import { Icon } from '../../../../system'
import { Ltr, useT } from '../../../../i18n'
import './access.css'

export function NumberRow({ masked }: { masked: string }) {
  const t = useT('hotel-access')
  return (
    <div className="hxa-number" data-gz="NumberRow">
      <span className="hxa-number__mark" aria-hidden="true">
        <Icon name="whatsapp" size="sm" />
      </span>
      <span className="gz-sr-only">{t('hotelAccessVerifySentTo', { phone: masked })}</span>
      <p className="hxa-number__value gz-t-fig-title" aria-hidden="true">
        <Ltr className="gz-num">{masked}</Ltr>
      </p>
    </div>
  )
}
