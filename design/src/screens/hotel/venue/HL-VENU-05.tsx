// HL-VENU-05 Policies: the venue's own terms in plain words, shown to couples as written (payment and cancellation are agreed with the venue
// directly: Ghazal holds no event money, so there are no tiers, cooling-off or refund settings), the voucher terms Ghazal sets (read only),
// the children and boys' age rule per section, the dress code and the opening hours. Everything is bilingual where couples read it.
// Requirements: HA-VMGT-08, HA-VMGT-09, HA-AUTH-02 (voucher model, ADR 0033)
// States: loading, success, error, offline, unsaved-guard.
// Roles: Admin and Manager only (ADR 0008 D12).
import { useFrame } from '../../../shell/frame'
import { ChipGroup, Dialog, ErrorState, Screen, Stepper, TopBar, useNav } from '../../../system'
import { HoursRow, HoursSheet, VoucherTerms } from './_components/PolicyParts'
import { FormSkeleton, Padded, SaveBar, StateStrip, useDraft, useIsStatic } from './_components/editor'
import { FactLine, Figures, Page, Section, useBi, useUnsavedGuard, useV } from './_components/bits'
import { BilingualField } from './_components/fields'
import { useAudienceLabel } from './_components/labels'
import { seedPolicy, useVenueStore, type ChildrenRule, type HoursModel, type PolicyModel } from './_components/store'
import { venue } from './_components/venue'
import './HL-VENU-05.css'

export const states = ['loading', 'success', 'error', 'offline', 'unsaved-guard']

export default function Policies() {
  const { state } = useFrame()
  const nav = useNav()
  const isStatic = useIsStatic()
  const { t } = useV()
  const bi = useBi()
  const audience = useAudienceLabel()
  const stored = useVenueStore(s => s.policy)
  const { draft, patch, update, dirty, commit } = useDraft<PolicyModel>(() => (isStatic ? seedPolicy() : stored))

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const saved = state === 'success'
  const dirtyShown = dirty || state === 'unsaved-guard'
  const guard = useUnsavedGuard(dirtyShown)

  const termsMissing = draft.termsAr.trim() === '' || draft.termsEn.trim() === ''
  const dressMissing = draft.dressAr.trim() === '' || draft.dressEn.trim() === ''
  const problem = termsMissing ? t('hotelVenueTermsNeeded') : dressMissing ? t('hotelVenueDressNeeded') : undefined

  const save = () => {
    if (problem || offline || isStatic) return
    useVenueStore.getState().savePolicy({ ...draft, termsAr: draft.termsAr.trim(), termsEn: draft.termsEn.trim(), dressAr: draft.dressAr.trim(), dressEn: draft.dressEn.trim() })
    commit()
    nav.toast({ message: t('hotelVenueToastPolicySaved'), icon: 'check-circle' })
    nav.pop()
  }

  const rule = (key: 'women' | 'men', next: Partial<ChildrenRule>) => patch({ [key]: { ...draft[key], ...next } } as Partial<PolicyModel>)
  const years = (n: number) => t('hotelVenueYears', { count: n })

  const openHours = (h: HoursModel) =>
    nav.openSheet(<HoursSheet hours={h} onSave={next => update(d => ({ ...d, hours: d.hours.map(x => (x.id === h.id ? next : x)) }))} />, { title: t('hotelVenueHoursTitle') })

  const top = (
    <>
      <TopBar title={t('hotelVenuePolTitle')} subtitle={bi(venue().name)} onBack={guard} />
      <StateStrip offline={offline} saved={saved} />
    </>
  )

  const childrenBlock = (key: 'women' | 'men') => {
    const r = draft[key]
    return (
      <div className="hv-child" key={key}>
        <span className="gz-t-title">{audience(key)}</span>
        <ChipGroup<'none' | 'limit'>
          label={audience(key)}
          value={r.limited ? 'limit' : 'none'}
          onChange={v => v && rule(key, { limited: v === 'limit' })}
          options={[
            { value: 'none', label: t('hotelVenueChildrenNoLimit') },
            { value: 'limit', label: t('hotelVenueChildrenLimit') },
          ]}
        />
        {r.limited ? (
          <Stepper
            label={t('hotelVenueChildrenAge')}
            value={r.age}
            min={1}
            max={18}
            step={1}
            onChange={age => rule(key, { age })}
            valueText={years}
          />
        ) : null}
      </div>
    )
  }

  let body
  if (loading) {
    body = <FormSkeleton rows={5} />
  } else if (error) {
    body = (
      <Padded>
        <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-05')} />
      </Padded>
    )
  } else {
    body = (
      <Page>
        <Section title={t('hotelVenueSecTerms')}>
          <BilingualField
            label={t('hotelVenueTermsLabel')}
            ar={draft.termsAr}
            en={draft.termsEn}
            onAr={v => patch({ termsAr: v })}
            onEn={v => patch({ termsEn: v })}
            multiline
            maxLength={600}
          />
          <VoucherTerms />
        </Section>

        <Section title={t('hotelVenueSecChildren')}>
          {childrenBlock('women')}
          {childrenBlock('men')}
        </Section>

        <Section title={t('hotelVenueSecDress')}>
          <BilingualField label={t('hotelVenueDressLabel')} ar={draft.dressAr} en={draft.dressEn} onAr={v => patch({ dressAr: v })} onEn={v => patch({ dressEn: v })} maxLength={80} />
        </Section>

        <Section title={t('hotelVenueSecHours')}>
          <div className="hv-hrs-list">
            {draft.hours.map(h => (
              <HoursRow key={h.id} h={h} disabled={offline} onOpen={() => openHours(h)} />
            ))}
          </div>
        </Section>
      </Page>
    )
  }

  const bar = loading || error ? undefined : <SaveBar dirty={dirtyShown} problem={problem} offline={offline} saved={saved} onSave={save} />

  return (
    <div className="hv-root">
      <Screen top={top} bottom={bar}>
        {body}
      </Screen>
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelVenueGuardTitle')} body={t('hotelVenueGuardBody')} icon="warning-circle" tone="destructive" confirmLabel={t('hotelVenueGuardDiscard')} cancelLabel={t('hotelVenueGuardKeep')} />
      ) : null}
    </div>
  )
}
