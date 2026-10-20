// Contact Support and Contact the account admin as dialogs with the fixture number (display only, never a tel: or wa.me link in the
// prototype, ADR 0012 D11). Text diet: the dialog is a title and the contact itself (name and number as values, no sentence). When the session is
// valid the real app opens the Ghazal Support thread (HL-TODY-05) instead.
import type { ReactNode } from 'react'
import { plainText } from '@gz/i18n'
import { Ltr, useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { SUPPORT_PHONE, adminStaff } from './flow'
import './access.css'

function Contact({ name, phone }: { name?: string; phone: string }): ReactNode {
  return (
    <span className="hxa-contact">
      {name ? <bdi dir="auto" className="hxa-contact__name">{name}</bdi> : null}
      <Ltr className="gz-num gz-t-fig-title hxa-contact__phone">{phone}</Ltr>
    </span>
  )
}

export function useSupport(): () => void {
  const nav = useNav()
  const f = useFormat()
  const t = useT('hotel-access')
  const tc = useT('common')
  return () => {
    if (usePrototype.getState().auth === 'signedIn') {
      nav.push('HL-TODY-05')
      return
    }
    void nav.openDialog({
      title: t('hotelAccessSupportTitle'),
      icon: 'headset',
      body: <Contact phone={plainText(f.phone(SUPPORT_PHONE))} />,
      confirmLabel: tc('commonActionDone'),
      cancelLabel: null,
    })
  }
}

/** Contact the account admin: the same dialog from the deactivated status and from an expired invitation. */
export function useContactAdmin(): () => void {
  const nav = useNav()
  const f = useFormat()
  const t = useT('hotel-access')
  const tc = useT('common')
  const { lang } = useLang()
  return () => {
    const admin = adminStaff()
    void nav.openDialog({
      title: t('hotelAccessAdminTitle'),
      icon: 'phone',
      body: <Contact name={admin ? (lang === 'ar' ? admin.name : admin.nameLatin) : ''} phone={admin ? plainText(f.phone(admin.phone)) : ''} />,
      confirmLabel: tc('commonActionDone'),
      cancelLabel: null,
    })
  }
}
