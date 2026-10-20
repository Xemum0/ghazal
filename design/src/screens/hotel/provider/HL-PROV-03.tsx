// HL-PROV-03 Listing: create or edit a listing. Category, title and description in Arabic and English (both required before review), photos,
// packages each with a standard price and a voucher price on the same basis, and the contact options for clients who browse without a voucher.
// Save draft keeps it; Continue goes to the plan (or straight to review for a fee-exempt partner or a resubmission). Editing a LIVE listing sends
// the new version to review while the approved one stays live (PA-LST-03, A-09).
// Requirements: PA-LST-01, PA-LST-02, PA-LST-03, PA-LST-07, HA-VMGT-09
// States: new, editing-live, validation, saving, saved, saving-below-fee, unsaved-guard, error, offline (the default frame is a saved draft)
import { useMemo, useRef, useState } from 'react'
import type { Listing, ServiceCategoryId } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { ActionBar, Banner, Dialog, Screen, SectionHeader, SelectRow, Skeleton, ToggleRow, TopBar, useNav } from '../../../system'
import { BilingualField } from './_components/fields'
import { Note, OfflineStrip, StaticSheet, useBi, useLive, useP } from './_components/bits'
import { CategorySheet } from './_components/CategorySheet'
import { PackageCards, PackageSheet, newPackage } from './_components/PackageCards'
import { PhotoStrip } from './_components/PhotoStrip'
import { WhatCouplesSee } from './_components/WhatCouplesSee'
import { PROVIDER_ID, accountOf, categoryOptions, isAccountKind } from './_components/model'
import { EMPTY_DRAFT, chooseAndSubmit, createListing, hasProblems, problemsOf, saveListing, seedDraft, sendLiveRevision, useProv, type ListingDraft, type PackageDraft } from './_components/store'
import './HL-PROV-03.css'

export const states = ['new', 'editing-live', 'validation', 'saving', 'saved', 'saving-below-fee', 'unsaved-guard', 'error', 'offline']

const LIVE_ID = 'lst-flowers-zahra'
const DRAFT_ID = 'lst-flowers-zahra-table'

/** A package whose saving (KD 1) is below the KD 2 voucher fee: the frame of `saving-below-fee`. */
const BELOW_FEE: PackageDraft = { id: 'pk-demo-below', nameAr: 'مدخل وطاولات', nameEn: 'Entrance and tables', structure: 'package', standardFils: 950000, voucherFils: 949000, includes: ['Entrance arrangement', 'Table centrepieces'] }

export default function ListingEditor() {
  const { state } = useFrame()
  const nav = useNav()
  const bi = useBi()
  const { t } = useP()
  const viewer = useProv(s => s.viewer)
  const listings = usePrototype(s => s.listings)
  const edits = useProv(s => s.edits)

  const live = useLive()
  const kind = state === undefined || !isAccountKind(nav.params.account) ? viewer : nav.params.account
  const exempt = accountOf(kind).exempt

  // Which listing: the route's (live), the live demo for `editing-live`, else the demo draft; a new listing has none.
  const paramId = typeof nav.params.listingId === 'string' ? nav.params.listingId : undefined
  const frameId = state === 'editing-live' ? LIVE_ID : state === 'new' || state === 'validation' ? undefined : DRAFT_ID
  const listingId = state ? frameId : live ? paramId : (paramId ?? DRAFT_ID)
  const listing: Listing | undefined = listings.find(l => l.id === listingId && l.providerId === PROVIDER_ID)
  const mode: 'new' | 'draft' | 'live' | 'rejected' = !listing ? 'new' : listing.status === 'active' ? 'live' : listing.status === 'rejected' ? 'rejected' : 'draft'

  const seed = useMemo<ListingDraft>(() => {
    if (state === 'validation') return { ...EMPTY_DRAFT, categoryId: 'flowers', titleEn: 'Engagement florals' }
    if (!listing) return { ...EMPTY_DRAFT, packages: [], photos: [] }
    return edits[listing.id] ?? seedDraft(listing)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [listing?.id, state])
  const [draft, setDraft] = useState<ListingDraft>(seed)
  const [base, setBase] = useState<ListingDraft>(seed)
  const [tried, setTried] = useState(state === 'validation')
  const [createdId, setCreatedId] = useState<string | undefined>(undefined)
  const [busy, setBusy] = useState(state === 'saving')
  const [savedFlag, setSavedFlag] = useState(state === 'saved')
  const [failed, setFailed] = useState(state === 'error')
  const dirtyRef = useRef(false)

  const dirty = JSON.stringify(draft) !== JSON.stringify(base)
  dirtyRef.current = dirty
  const problems = problemsOf(draft)
  const offline = state === 'offline'
  const patch = (p: Partial<ListingDraft>) => {
    setSavedFlag(false)
    setDraft(d => ({ ...d, ...p }))
  }
  const show = tried || state === 'validation'

  const persist = (): string => {
    const id = listing?.id ?? createdId
    if (id) {
      saveListing(id, draft)
      return id
    }
    const made = createListing(draft)
    setCreatedId(made)
    return made
  }

  const saveDraft = () => {
    if (!draft.titleEn.trim() && !draft.titleAr.trim()) {
      nav.toast({ message: t('hotelProviderEditorDraftNeedsTitle'), icon: 'info' })
      return
    }
    persist()
    setBase(draft)
    nav.toast({ message: t('hotelProviderEditorDraftSaved'), tone: 'success' })
    nav.pop()
  }

  const next = () => {
    setTried(true)
    if (hasProblems(problems)) {
      nav.toast({ message: t('hotelProviderEditorFixFields'), tone: 'danger' })
      return
    }
    const id = persist()
    setBase(draft)
    if (mode === 'live') {
      sendLiveRevision(id)
      nav.replace('HL-PROV-06', { listingId: id, account: kind })
    } else if (mode === 'rejected' || exempt) {
      // A resubmission keeps the plan that was chosen; a fee-exempt partner has none to choose.
      chooseAndSubmit(id, exempt ? null : (listing?.planCycle ?? null), exempt)
      if (!exempt && !listing?.planCycle) nav.push('HL-PROV-04', { listingId: id, account: kind })
      else nav.replace('HL-PROV-06', { listingId: id, account: kind })
    } else {
      nav.push('HL-PROV-04', { listingId: id, account: kind })
    }
  }

  const leave = async () => {
    if (!dirtyRef.current) return nav.pop()
    const r = await nav.openDialog({ title: t('hotelProviderGuardTitle'), body: t('hotelProviderGuardBody'), icon: 'warning', confirmLabel: t('hotelProviderGuardDiscard'), cancelLabel: t('hotelProviderGuardKeep'), tone: 'destructive' })
    if (r === 'confirm') nav.pop()
  }

  const editPackage = (p: PackageDraft | null) => {
    const isNew = p === null
    const initial = p ?? newPackage()
    const key = nav.openSheet(
      <PackageSheet
        initial={initial}
        isNew={isNew}
        onClose={() => nav.closeSheet(key)}
        onSave={saved => {
          setSavedFlag(false)
          setDraft(d => ({ ...d, packages: isNew ? [...d.packages, saved] : d.packages.map(x => (x.id === saved.id ? saved : x)) }))
          nav.closeSheet(key)
        }}
        onDelete={() => {
          setDraft(d => ({ ...d, packages: d.packages.filter(x => x.id !== initial.id) }))
          nav.closeSheet(key)
        }}
      />,
      {},
    )
  }
  const chooseCategory = () => {
    const key = nav.openSheet(
      <CategorySheet
        title={t('hotelProviderEditorCategory')}
        max={1}
        value={draft.categoryId ? [draft.categoryId] : []}
        onClose={() => nav.closeSheet(key)}
        onApply={v => {
          patch({ categoryId: v[0] ?? null })
          nav.closeSheet(key)
        }}
      />,
      {},
    )
  }

  const reason = offline ? t('hotelProviderNeedsConnection') : undefined
  const label = savedFlag ? t('hotelProviderEditorSaved') : mode === 'live' ? t('hotelProviderEditorSubmitChanges') : mode === 'rejected' ? t('hotelProviderEditorResubmit') : exempt ? t('hotelProviderStepSubmit') : t('hotelProviderEditorContinue')
  const bottom = (
    <ActionBar
      action={{ label, iconEnd: savedFlag ? 'check' : 'chevron-right', loading: busy, disabled: offline || savedFlag, reason, onPress: next }}
      secondary={mode === 'live' ? undefined : { label: t('hotelProviderEditorSaveDraft'), onPress: saveDraft }}
    />
  )

  const title = t(mode === 'new' ? 'hotelProviderEditorTitleNew' : 'hotelProviderEditorTitle')
  const top = (
    <>
      <TopBar title={title} onBack={leave} />
      {offline ? <OfflineStrip /> : null}
      {savedFlag ? (
        <Banner tone="info" icon="check-circle">
          {t('hotelProviderEditorSavedBanner')}
        </Banner>
      ) : null}
    </>
  )

  const cats = categoryOptions()
  const required = t('hotelProviderRequired')

  const form = (
    <div className="hp03" data-gz="ListingForm">
      {failed ? (
        <Note tone="danger" action={{ label: t('hotelProviderRetryShort'), onPress: () => setFailed(false) }}>
          {t('hotelProviderEditorError')}
        </Note>
      ) : null}
      {mode === 'live' ? <Note icon="eye">{t('hotelProviderEditorLiveNote')}</Note> : null}
      {mode === 'rejected' && listing?.rejection ? (
        <Note tone="danger">
          {t('hotelProviderEditorRejectedNote', { note: bi(listing.rejection.note) })}
        </Note>
      ) : null}
      {show && hasProblems(problems) ? <Note tone="danger">{t('hotelProviderEditorValidationNote')}</Note> : null}

      <section className="hp03__sec" aria-label={t('hotelProviderEditorCategory')}>
        <SectionHeader voice="hotel" level={2} title={t('hotelProviderEditorCategory')} />
        <SelectRow<ServiceCategoryId>
          label={t('hotelProviderEditorCategory')}
          placeholder={t('hotelProviderEditorCategoryPlaceholder')}
          sheetTitle={t('hotelProviderEditorCategory')}
          options={cats.map(c => ({ value: c.id, label: bi(c.name) }))}
          value={draft.categoryId}
          onChange={v => patch({ categoryId: v })}
          error={show && problems.category ? required : undefined}
        />
      </section>

      <section className="hp03__sec" aria-label={t('hotelProviderEditorTexts')}>
        <SectionHeader voice="hotel" level={2} title={t('hotelProviderEditorTexts')} />
        <BilingualField
          label={t('hotelProviderEditorTitleField')}
          ar={draft.titleAr}
          en={draft.titleEn}
          onAr={titleAr => patch({ titleAr })}
          onEn={titleEn => patch({ titleEn })}
          errorAr={show && problems.titleAr ? required : undefined}
          errorEn={show && problems.titleEn ? required : undefined}
          maxLength={60}
        />
        <BilingualField
          label={t('hotelProviderEditorDescField')}
          ar={draft.descAr}
          en={draft.descEn}
          onAr={descAr => patch({ descAr })}
          onEn={descEn => patch({ descEn })}
          errorAr={show && problems.descAr ? required : undefined}
          errorEn={show && problems.descEn ? required : undefined}
          maxLength={400}
          multiline
        />
      </section>

      <section className="hp03__sec" aria-label={t('hotelProviderEditorPhotos')}>
        <SectionHeader voice="hotel" level={2} title={t('hotelProviderEditorPhotos')} />
        <PhotoStrip photos={draft.photos} categoryId={draft.categoryId} onChange={photos => patch({ photos })} />
      </section>

      <section className="hp03__sec" aria-label={t('hotelProviderEditorPackages')}>
        <SectionHeader voice="hotel" level={2} title={t('hotelProviderEditorPackages')} />
        <PackageCards packages={draft.packages} onEdit={p => editPackage(p)} onAdd={() => editPackage(null)} error={show && problems.packages} />
      </section>

      <section className="hp03__sec" aria-label={t('hotelProviderPreviewTitle')}>
        <WhatCouplesSee draft={draft} />
      </section>

      <section className="hp03__sec" aria-label={t('hotelProviderEditorContact')}>
        <SectionHeader voice="hotel" level={2} title={t('hotelProviderEditorContact')} />
        <div className="hp03__toggles">
          <ToggleRow title={t('hotelProviderEditorChat')} checked={draft.chat} onChange={chat => patch({ chat })} />
          <ToggleRow title={t('hotelProviderEditorPhone')} checked={draft.showPhone} onChange={showPhone => patch({ showPhone })} divider={false} />
        </div>
      </section>
    </div>
  )

  const guard = state === 'unsaved-guard'
  return (
    <>
      <Screen top={top} bottom={bottom}>
        {state === 'loading' ? <Skeleton variant="block" blockSize={240} /> : form}
      </Screen>
      {state === 'saving-below-fee' ? (
        <StaticSheet label={t('hotelProviderPkgSheetEdit')}>
          <PackageSheet initial={BELOW_FEE} isNew={false} onSave={() => undefined} />
        </StaticSheet>
      ) : null}
      {guard ? <Dialog open placement="inline" icon="warning" tone="destructive" title={t('hotelProviderGuardTitle')} body={t('hotelProviderGuardBody')} confirmLabel={t('hotelProviderGuardDiscard')} cancelLabel={t('hotelProviderGuardKeep')} /> : null}
    </>
  )
}
