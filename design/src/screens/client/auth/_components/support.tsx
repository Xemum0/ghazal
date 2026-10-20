// Contact Support: a dialog with the fixture number as its only content (display only, never a tel: or wa.me link in the prototype,
// ADR 0012 D11). The number is a value in an LTR island; there is no sentence around it.
import { Phone, useT } from '../../../../i18n'
import { useNav } from '../../../../system'
import { SUPPORT_PHONE } from './flow'

export function useSupport(): () => void {
  const nav = useNav()
  const t = useT('client-auth')
  const tc = useT('common')
  return () => {
    void nav.openDialog({
      title: t('clientAuthSharedSupport'),
      icon: 'whatsapp',
      body: <Phone value={SUPPORT_PHONE} />,
      confirmLabel: tc('commonActionOpenWhatsapp'),
      cancelLabel: tc('commonActionClose'),
    })
  }
}
