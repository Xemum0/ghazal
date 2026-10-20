// The legal pages open in-app (CA-AUTH-11). The texts come from the Super Admin CMS; the prototype shows the section headings only,
// as icon rows. The platform terms now carry the voucher section (ADR 0033: the KD 2 is paid to Ghazal, the event price is paid to
// the venue directly), so one reader holds both.
//
// LegalInfo is the text diet's home for legal consent (ADR 0034 section 6): an info glyph next to the checkbox or the sign-in
// buttons opens a sheet with the two pages one tap away; the paragraph is never on the screen.
import type { ReactNode } from 'react'
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { IconButton, IconListRow, InfoSheet, useNav } from '../../../../system'
import { useT, type MessageKey } from '../../../../i18n'
import './auth.css'

export type LegalKind = 'terms' | 'privacy'

type Section = { key: MessageKey<'client-auth'>; icon: IconName }

const SECTIONS: Record<LegalKind, readonly Section[]> = {
  terms: [
    { key: 'clientAuthSharedTermsSection1', icon: 'document' },
    { key: 'clientAuthSharedTermsSection2', icon: 'ticket' },
    { key: 'clientAuthSharedTermsSection3', icon: 'receipt' },
    { key: 'clientAuthSharedTermsSection4', icon: 'shield-check' },
  ],
  privacy: [
    { key: 'clientAuthSharedPrivacySection1', icon: 'clipboard' },
    { key: 'clientAuthSharedPrivacySection2', icon: 'sliders' },
    { key: 'clientAuthSharedPrivacySection3', icon: 'eye' },
    { key: 'clientAuthSharedPrivacySection4', icon: 'settings' },
  ],
}

function LegalContent({ kind }: { kind: LegalKind }) {
  const t = useT('client-auth')
  const sections = SECTIONS[kind]
  return (
    <div className="gza-legal" data-gz="LegalPage">
      {sections.map((s, i) => (
        <IconListRow key={s.key} flush icon={s.icon} title={t(s.key)} last={i === sections.length - 1} />
      ))}
      <p className="gza-legal__note gz-t-caption">{t('clientAuthSharedLegalNote')}</p>
    </div>
  )
}

export function useLegal(): (kind: LegalKind) => void {
  const nav = useNav()
  const t = useT('client-auth')
  return kind => {
    nav.openSheet(<LegalContent kind={kind} />, { title: t(kind === 'terms' ? 'clientAuthSharedLegalTerms' : 'clientAuthSharedLegalPrivacy') })
  }
}

/**
 * The info glyph and its sheet: optional paragraphs (a function gets `close`, for inline links that must close the sheet first),
 * then (unless `rows` is off) Terms of Use and Privacy Policy as two rows that open the legal reader.
 */
export function LegalInfo({ title, children, rows = true, className }: { title: string; children?: ReactNode | ((close: () => void) => ReactNode); rows?: boolean; className?: string }) {
  const t = useT('client-auth')
  const tc = useT('common')
  const legal = useLegal()
  const [open, setOpen] = useState(false)
  const close = () => setOpen(false)
  const read = (kind: LegalKind) => {
    close()
    legal(kind)
  }
  return (
    <>
      <IconButton icon="info" iconSize="sm" label={tc('commonA11yInfo')} className={className} aria-haspopup="dialog" aria-expanded={open} onClick={() => setOpen(true)} />
      <InfoSheet open={open} onClose={close} title={title}>
        {typeof children === 'function' ? children(close) : children}
        {rows ? (
          <div className="gza-legal gza-legal--rows">
            <IconListRow flush icon="document" title={t('clientAuthSharedLegalTerms')} onClick={() => read('terms')} />
            <IconListRow flush icon="shield-check" title={t('clientAuthSharedLegalPrivacy')} onClick={() => read('privacy')} last />
          </div>
        ) : null}
      </InfoSheet>
    </>
  )
}
