// MergePanel (CL-DISC-02, variant `merge-conflict`): shown once after sign-in when the account already holds a different Brief. The two Briefs
// sit side by side ("This phone" / "My account"), each as glyph and value facts with its own "Keep" under it, and the person chooses with one
// of two equal secondary buttons: nothing is preselected, because neither side is the default and gold is reserved for the verb the person has
// not yet chosen. ADR 0034: no lead sentence, one word per button.
import type { ReactNode } from 'react'
import * as mock from '../../../../../mock'
import { Button, Figures, Icon } from '../../../../../system'
import { useFormat, useT } from '../../../../../i18n'
import { useLang } from '../../../../../shell/lang'
import type { IconName } from '@gz/tokens'
import type { SearchBrief } from '../data'

export type MergePanelProps = {
  phone: SearchBrief
  account: SearchBrief
  onKeep: (which: 'phone' | 'account') => void
}

const SECTION_GLYPH = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const

function Fact({ icon, children }: { icon: IconName; children: ReactNode }) {
  return (
    <p className="gzd-merge__fact gz-t-body-s">
      <Icon name={icon} size="sm" tone="secondary" />
      <span className="gzd-merge__value">{children}</span>
    </p>
  )
}

function Column({ brief, title, id, onKeep }: { brief: SearchBrief; title: string; id: string; onKeep: () => void }) {
  const t = useT('client-discover')
  const f = useFormat()
  const { lang } = useLang()
  const areas = f.list((brief.areaIds ?? []).map(a => mock.getArea(a)?.name[lang] ?? '').filter(Boolean), 'and')
  return (
    <section className="gzd-merge__col" data-gz-id={id} aria-label={title}>
      <h3 className="gzd-merge__title gz-t-label">{title}</h3>
      <div className="gzd-merge__facts">
        <Fact icon="calendar">
          <Figures text={brief.date ? f.date(brief.date, 'compact') : t('clientDiscoverBriefChooseDate')} />
        </Fact>
        {brief.guests ? (
          <Fact icon={brief.audience ? SECTION_GLYPH[brief.audience] : 'users-three'}>
            <Figures text={f.integer(brief.guests)} />
          </Fact>
        ) : null}
        {areas ? <Fact icon="pin">{areas}</Fact> : null}
      </div>
      <Button variant="secondary" fullWidth onClick={onKeep}>
        {t('clientDiscoverMergeKeep')}
      </Button>
    </section>
  )
}

export function MergePanel({ phone, account, onKeep }: MergePanelProps) {
  const t = useT('client-discover')
  return (
    <div className="gzd-merge" data-gz-id="brief.merge">
      <div className="gzd-merge__cols">
        <Column brief={phone} title={t('clientDiscoverMergePhone')} id="merge.phone" onKeep={() => onKeep('phone')} />
        <span className="gzd-merge__rule" aria-hidden="true" />
        <Column brief={account} title={t('clientDiscoverMergeAccount')} id="merge.account" onKeep={() => onKeep('account')} />
      </div>
    </div>
  )
}
