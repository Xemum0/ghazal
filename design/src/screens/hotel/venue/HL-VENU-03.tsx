// HL-VENU-03 Edit package: bilingual name and description, audience and halls, the pricing structure (per person or package) with a standard
// price AND a voucher price per set of days (voucher <= standard), guest limits, inclusions, active state, and a live "What couples see"
// preview with both prices and the saving. Everything the phone does not edit is stated as read-only (dashboard).
// Requirements: HA-VMGT-03, HA-VMGT-04, HA-VMGT-09, HA-VMGT-11, HA-VMGT-12, HA-VMGT-13, HA-AUTH-02 (voucher model, ADR 0033)
// States: new, validation, loading, success, error, offline, unsaved-guard, voucher-higher-than-standard, saving-below-voucher-fee.
// Params: `packageId` (a package id, or `new`). A static frame shows Ladies' Reception, Weekend.
// Roles: Admin and Manager only (ADR 0008 D12).
import { useFrame } from '../../../shell/frame'
import { Button, ChipGroup, Dialog, ErrorState, IconSegmented, Screen, SegmentedControl, ToggleRow, TopBar, useNav } from '../../../system'
import type { Audience, PricingBasis } from '../../../mock'
import { InclusionChips, InclusionSheet, PackagePreview, TierEditor, type TierKey } from './_components/PackageParts'
import { FormSkeleton, Padded, SaveBar, StateStrip, useDraft, useIsStatic } from './_components/editor'
import { FactLine, DashboardNote, Page, Section, useBi, useUnsavedGuard, useV } from './_components/bits'
import { FieldError, BilingualField, GuestPicker } from './_components/fields'
import { useAudienceLabel } from './_components/labels'
import { hasVoucher, needsFlat, needsGuest, voucherAboveStandard } from './_components/pricing'
import { blankPackage, seedPackage, structureOf, useVenueStore, type PackageModel, type PricingStructure, type TierModel } from './_components/store'
import { GUEST_HARD_CAP, GUEST_PRESETS, halls, isReservedName, venue, venuePackages } from './_components/venue'
import './HL-VENU-03.css'

export const states = ['new', 'validation', 'loading', 'success', 'error', 'offline', 'unsaved-guard', 'voucher-higher-than-standard', 'saving-below-voucher-fee']

const AUDIENCES: readonly Audience[] = ['women', 'men', 'mixed']
const DEMO_ID = 'V01-ladies-weekend'

/** What the frame state lays over the package: the validation frame shows every kind of problem at once. */
function seedFor(id: string, stored: PackageModel | undefined, state: string | undefined): PackageModel {
  if (state === 'new' || id === 'new') return blankPackage()
  const base = stored ?? seedPackage(id) ?? seedPackage(DEMO_ID) ?? blankPackage()
  const tier = base.weekend.on ? 'weekend' : 'weekday'
  const day = base[tier]
  // The two voucher states show a voucher price that is wrong in a way the fixtures' own numbers define (a margin above, a margin of 1 fil).
  if (state === 'voucher-higher-than-standard') return { ...base, [tier]: { ...day, voucherPerGuestFils: (day.perGuestFils ?? 0) + 4000 } }
  if (state === 'saving-below-voucher-fee') return { ...base, [tier]: { ...day, voucherPerGuestFils: (day.perGuestFils ?? 0) - 1 } }
  if (state !== 'validation') return base
  return {
    ...base,
    nameEn: 'Gold',
    minGuests: 400,
    maxGuests: 300,
    weekend: { ...base.weekend, perGuestFils: null },
  }
}

export default function PackageEditor() {
  const { state } = useFrame()
  const nav = useNav()
  const isStatic = useIsStatic()
  const { t, c, f } = useV()
  const bi = useBi()
  const audience = useAudienceLabel()

  const requested = typeof nav.params.packageId === 'string' ? nav.params.packageId : DEMO_ID
  const stored = useVenueStore(s => s.packages[requested])
  const hallModels = useVenueStore(s => s.halls)
  const { draft, patch, update, dirty, commit } = useDraft<PackageModel>(() => seedFor(requested, stored, state))
  const saved = state === 'success'

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const isNew = draft.isNew
  const showErrors = state === 'validation'
  const hallList = halls()
  const multiHall = hallList.length > 1
  const dirtyShown = dirty || state === 'unsaved-guard'
  const guard = useUnsavedGuard(dirtyShown)

  // ---- validation
  const reserved = isReservedName(draft.nameAr) || isReservedName(draft.nameEn)
  const namesMissing = draft.nameAr.trim() === '' || draft.nameEn.trim() === ''
  const noAudience = draft.audiences.length === 0
  const noHall = multiHall && draft.hallIds.length === 0
  const tiers: Array<[TierKey, TierModel]> = [['weekday', draft.weekday], ['weekend', draft.weekend]]
  const noTier = !draft.bundle && !draft.weekday.on && !draft.weekend.on
  const pricesMissing = !draft.bundle && tiers.some(([, m]) => m.on && ((needsFlat(draft.basis) && m.flatFils === null) || (needsGuest(draft.basis) && m.perGuestFils === null)))
  const voucherHigher = !draft.bundle && tiers.some(([, m]) => m.on && (voucherAboveStandard(m).flat || voucherAboveStandard(m).guest))
  const structure = structureOf(draft.basis)
  const setStructure = (next: PricingStructure) => patch({ basis: next === 'per_person' ? 'per_guest' : draft.basis === 'per_guest' ? 'flat' : draft.basis })
  const hallCap = Math.max(0, ...(draft.hallIds.length ? draft.hallIds : hallList.map(h => h.id)).map(id => hallModels[id]?.capacityMax ?? hallList.find(h => h.id === id)?.capacity.max ?? 0))
  const maxBelowMin = draft.maxGuests < draft.minGuests
  const maxOverHall = hallCap > 0 && draft.maxGuests > hallCap
  const guestsBad = maxBelowMin || maxOverHall

  const problem = namesMissing
    ? t('hotelVenueNameRequired')
    : reserved
      ? t('hotelVenueReservedName')
      : noAudience
        ? t('hotelVenueAudienceNeeded')
        : noHall
          ? t('hotelVenueHallsNeeded')
          : noTier
            ? t('hotelVenueTierNeeded')
            : pricesMissing
              ? t('hotelVenueReasonPrices')
              : voucherHigher
                ? t('hotelVenueReasonVoucher')
                : guestsBad
                  ? t('hotelVenueReasonGuests')
                  : undefined

  const displayName = bi({ ar: draft.nameAr, en: draft.nameEn })

  const setTier = (key: TierKey, next: TierModel) => patch(key === 'weekday' ? { weekday: next } : { weekend: next })
  const toggleAudience = (next: Audience[]) => patch({ audiences: AUDIENCES.filter(a => next.includes(a)) })

  const save = () => {
    if (problem || isStatic || offline) return
    useVenueStore.getState().savePackage({ ...draft, nameAr: draft.nameAr.trim(), nameEn: draft.nameEn.trim(), descAr: draft.descAr.trim(), descEn: draft.descEn.trim() })
    commit()
    nav.toast({ message: t(isNew ? 'hotelVenueToastPkgCreated' : 'hotelVenueToastPkgSaved'), icon: 'check-circle' })
    nav.pop()
  }

  const archive = async () => {
    const answer = await nav.openDialog({
      title: t('hotelVenueArchiveTitle'),
      body: t('hotelVenueArchiveBody'),
      icon: 'document',
      tone: 'destructive',
      confirmLabel: t('hotelVenueArchiveConfirm'),
      cancelLabel: t('hotelVenueDeleteKeep'),
    })
    if (answer !== 'confirm') return
    const id = draft.id
    useVenueStore.getState().archivePackage(id)
    nav.pop()
    nav.toast({ message: t('hotelVenueToastArchived', { name: displayName }), undo: true, action: { label: c('commonActionUndo'), onPress: () => useVenueStore.getState().restorePackage(id) } })
  }

  const addInclusion = () =>
    nav.openSheet(<InclusionSheet have={draft.inclusions} onAdd={items => update(d => ({ ...d, inclusions: [...d.inclusions, ...items] }))} />, { title: t('hotelVenueInclusionSheetTitle') })

  const top = (
    <>
      <TopBar title={t(isNew ? 'hotelVenuePkgNew' : 'hotelVenuePkgEditTitle')} subtitle={bi(venue().name)} onBack={guard} />
      <StateStrip offline={offline} saved={saved} />
    </>
  )

  let body
  if (loading) {
    body = <FormSkeleton rows={6} />
  } else if (error) {
    body = (
      <Padded>
        <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-03', { packageId: requested })} />
      </Padded>
    )
  } else {
    body = (
      <Page>
        <Section title={t('hotelVenueSecName')}>
          <BilingualField
            label={t('hotelVenueFieldName')}
            ar={draft.nameAr}
            en={draft.nameEn}
            onAr={v => patch({ nameAr: v })}
            onEn={v => patch({ nameEn: v })}
            errorAr={isReservedName(draft.nameAr) ? t('hotelVenueReservedName') : undefined}
            errorEn={isReservedName(draft.nameEn) ? t('hotelVenueReservedName') : undefined}
            maxLength={60}
          />
          <BilingualField label={t('hotelVenueFieldDescription')} ar={draft.descAr} en={draft.descEn} onAr={v => patch({ descAr: v })} onEn={v => patch({ descEn: v })} multiline maxLength={240} />
        </Section>

        <Section title={t('hotelVenueSecAudience')}>
          <ChipGroup<Audience>
            label={t('hotelVenueAudienceLabel')}
            selection="multiple"
            value={draft.audiences}
            onChange={toggleAudience}
            options={AUDIENCES.map(a => ({ value: a, label: audience(a) }))}
          />
          {multiHall ? (
            <div className="hv-field">
              <span className="gz-t-label">{t('hotelVenueHallsLabel')}</span>
              <ChipGroup<string>
                label={t('hotelVenueHallsLabel')}
                selection="multiple"
                value={draft.hallIds}
                onChange={ids => patch({ hallIds: hallList.map(h => h.id).filter(id => ids.includes(id)) })}
                options={hallList.map(h => ({ value: h.id, label: bi(h.name) }))}
              />
            </div>
          ) : null}
        </Section>

        <Section title={t('hotelVenueSecPricing')}>
          <IconSegmented<PricingStructure>
            label={c('commonPricingStructure')}
            value={structure}
            onChange={setStructure}
            disabled={draft.bundle}
            options={[
              { value: 'per_person', icon: 'per-guest', label: c('commonPricingPerPerson') },
              { value: 'package', icon: 'package', label: c('commonPricingPackage') },
            ]}
          />
          {structure === 'package' && !draft.bundle ? (
            <SegmentedControl<PricingBasis>
              label={t('hotelVenueBasisLabel')}
              value={draft.basis}
              onChange={basis => patch({ basis })}
              options={[
                { value: 'flat', label: t('hotelVenueBasisFlat') },
                { value: 'flat_plus_per_guest', label: t('hotelVenueBasisFlatPlus') },
              ]}
            />
          ) : null}
          {draft.bundle ? (
            <FactLine icon="info">{t('hotelVenueBundleNote')}</FactLine>
          ) : (
            <>
              {tiers.map(([key, model]) => (
                <TierEditor key={key} tier={key} model={model} basis={draft.basis} showEmpty={showErrors || !isNew} onChange={next => setTier(key, next)} />
              ))}
              {noTier ? <FieldError>{t('hotelVenueTierNeeded')}</FieldError> : null}
            </>
          )}
        </Section>

        <Section title={t('hotelVenueSecGuests')}>
          <GuestPicker
            label={t('hotelVenueGuestsMin')}
            value={draft.minGuests}
            onChange={v => patch({ minGuests: v })}
            min={draft.guestStep}
            max={GUEST_HARD_CAP}
            step={draft.guestStep}
            presets={GUEST_PRESETS}
          />
          <GuestPicker
            label={t('hotelVenueGuestsMax')}
            value={draft.maxGuests}
            onChange={v => patch({ maxGuests: v })}
            min={draft.guestStep}
            max={GUEST_HARD_CAP}
            step={draft.guestStep}
            presets={GUEST_PRESETS}
            error={maxBelowMin ? t('hotelVenueMaxBelowMin') : maxOverHall ? t('hotelVenueMaxOverHall', { max: f.integer(hallCap) }) : undefined}
          />
        </Section>

        <Section title={t('hotelVenueSecInclusions')}>
          <InclusionChips items={draft.inclusions} onRemove={i => update(d => ({ ...d, inclusions: d.inclusions.filter((_, j) => j !== i) }))} onAdd={addInclusion} />
        </Section>

        <Section title={t('hotelVenueSecPreview')}>
          <PackagePreview m={draft} name={displayName} />
        </Section>

        <Section title={t('hotelVenueSecStatus')}>
          <ToggleRow
            title={t('hotelVenueActiveTitle')}
            checked={draft.active}
            onChange={active => patch({ active })}
            divider={false}
          />
          {isNew ? null : (
            <Button variant="destructive" iconStart="document" onClick={archive} disabled={offline} reason={offline ? t('hotelVenueOfflineChange') : undefined}>
              {t('hotelVenueArchive')}
            </Button>
          )}
        </Section>

        <DashboardNote kind="prices" />
      </Page>
    )
  }

  const bar = loading || error ? undefined : <SaveBar dirty={dirtyShown} problem={problem} offline={offline} saved={saved} onSave={save} label={isNew ? c('commonActionSave') : undefined} />

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
