// CL-ONBD-03 Who is planning? Covers CA-ONB-07, CA-ONB-09 and CA-ONB-10.
// First of the three optional steps after the account is created (ADR 0038): the name comes from the account, and the role is suggested
// from the sex given there (female: bride, male: groom; a chip the person can change). The partner's name is the only empty field.
// Text diet (ADR 0034): a two-word question with its drawing (the invitation), four role chips that are a glyph and one word each
// (dress, groom, family, planner; none preselected), a name and an optional partner name (no first/last split, ADR 0012), and a live
// monogram: the first letter of the name in its own script on a rose-tint disk (ADR 0015). No lead, no label over the chips, no
// "optional" tag: every answer is optional, said once by the info glyph in the bar (CA-ONB-09) and by Skip. Skip and Continue both go
// to the date, only Continue writes the answers. There is no Back: the sign-in is behind the person once the account exists.
// States: default (empty), success (the demo persona filled in, the monogram live).
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { ActionBar, Avatar, Chip, Screen, TextField, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { users, weddingProfile as storyProfile, meta } from '../../../mock'
import { StepBar } from './_components/StepBar'
import { StepHead } from './_components/StepHead'
import { commitAbout, monogramFor, roleForSex, type WeddingRole } from './_components/profile'
import { useInStaticFrame, useScreenState } from './_components/useScreenState'
import './_components/form.css'
import './CL-ONBD-03.css'

export const states = ['success']

const ROLES: readonly WeddingRole[] = ['bride', 'groom', 'family', 'planner']
/** One glyph per role: the gown, the male sign, a group, a clipboard. Never a face or a figure. */
const ROLE_ICON: Record<WeddingRole, IconName> = { bride: 'dress', groom: 'groom', family: 'guests', planner: 'clipboard' }

export default function ClOnbd03() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const nav = useNav()
  const { lang } = useLang()
  const filled = useScreenState() === 'success'
  const saved = usePrototype(s => s.weddingProfile)
  const framed = useInStaticFrame()
  const user = usePrototype(s => s.user)

  // The demo persona (Reem): her name is stored once as typed, and the Latin spelling is the fixture's `nameLatin`.
  const reem = users.find(u => u.id === meta.clientUserId)
  const reemName = lang === 'ar' ? (reem?.name ?? '') : (reem?.nameLatin ?? reem?.name ?? '')
  // What the account knows: the name and the sex given at sign-up. A frame has no account, so it shows the demo persona's.
  const accountName = user?.name || (framed ? reemName : '')
  const accountSex = user?.sex ?? (framed ? 'female' : undefined)
  const [role, setRole] = useState<WeddingRole | null>(filled ? storyProfile.role : saved?.name ? saved.role : roleForSex(accountSex))
  const [name, setName] = useState(filled ? reemName : (saved?.name ?? accountName))
  const [partner, setPartner] = useState(filled ? storyProfile.partnerName : (saved?.partnerName ?? ''))

  const roleLabels: Record<WeddingRole, string> = {
    bride: t('clientOnboardingAboutRoleBride'),
    groom: t('clientOnboardingAboutRoleGroom'),
    family: t('clientOnboardingAboutRoleFamily'),
    planner: t('clientOnboardingAboutRolePlanner'),
  }
  const partnerLabel =
    role === 'bride' ? t('clientOnboardingAboutPartnerGroom') : role === 'groom' ? t('clientOnboardingAboutPartnerBride') : role === 'family' || role === 'planner' ? t('clientOnboardingAboutPartnerCouple') : t('clientOnboardingAboutPartnerDefault')

  const next = () => nav.push('CL-ONBD-04')
  const confirm = () => {
    commitAbout({ role, name, partnerName: partner ?? '' })
    next()
  }

  return (
    <Screen top={<StepBar step={1} total={3} back={false} onSkip={next} />} bottom={<ActionBar action={{ label: c('commonActionContinue'), onPress: confirm }} />}>
      <div className="obd-form">
        <StepHead title={t('clientOnboardingAboutTitle')} art="invitation" />

        {/* Two equal rows of two: a single choice reads as one block, not a ragged wrap (the system ChipGroup wraps by content). */}
        <div className="obd-roles" role="group" aria-label={t('clientOnboardingAboutRoleLabel')}>
          {[ROLES.slice(0, 2), ROLES.slice(2)].map((row, i) => (
            <div className="obd-roles__row" key={i}>
              {row.map(r => (
                <Chip key={r} className="obd-roles__chip" iconStart={ROLE_ICON[r]} selected={role === r} onClick={() => setRole(r)}>
                  {roleLabels[r]}
                </Chip>
              ))}
            </div>
          ))}
        </div>

        <section className="obd-group obd-group--fields">
          <div className="obd-about__name">
            <Avatar name={t('clientOnboardingAboutMonogram')} initial={monogramFor(name)} size="md" />
            <TextField label={t('clientOnboardingAboutNameLabel')} value={name} onValueChange={setName} autoComplete="name" enterKeyHint="next" />
          </div>
          <TextField label={partnerLabel} value={partner ?? ''} onValueChange={setPartner} enterKeyHint="done" />
        </section>
      </div>
    </Screen>
  )
}
