// HL-VENU-04 Halls, capacity and amenities: the venue profile (venue type for the client filter, governorate and area), the list of bookable
// halls (a single-hall venue lands straight in the editor, profile on top) and the hall editor: name, capacity bounds, audiences and setting,
// sessions, facilities as Included / Extra / Not offered rows, and per-section facts.
// Requirements: HA-VMGT-06, HA-VMGT-07, HA-VMGT-09, HA-VMGT-12, HA-CAL-09, HA-AUTH-02 (voucher model, ADR 0033)
// States: single-hall, loading, validation, success, error, offline, unsaved-guard.
// Params: `hallId` opens a hall in the editor. A static frame shows the list (default) or Danah Ballroom in the editor.
import { useFrame } from '../../../shell/frame'
import { Button, ChipGroup, Dialog, ErrorState, Icon, ListRow, Screen, Skeleton, ToggleRow, TopBar, useNav } from '../../../system'
import type { AmenityState, Audience, HallSetting } from '../../../mock'
import { AmenityRows, SectionFacts, SessionRow, SessionSheet } from './_components/HallParts'
import { VenueProfile } from './_components/VenueProfile'
import { Padded, SaveBar, StateStrip, useDraft, useIsStatic } from './_components/editor'
import { FactLine, Figures, Page, Section, useBi, useUnsavedGuard, useV } from './_components/bits'
import { BilingualField, FieldError, GuestPicker } from './_components/fields'
import { useAudienceLabel, useSettingLabel } from './_components/labels'
import { seedHall, useVenueStore, type HallModel } from './_components/store'
import { GUEST_HARD_CAP, GUEST_PRESETS, HALL_AMENITIES, halls, venue } from './_components/venue'
import './HL-VENU-04.css'

export const states = ['single-hall', 'loading', 'validation', 'success', 'error', 'offline', 'unsaved-guard']

const AUDIENCES: readonly Audience[] = ['women', 'men', 'mixed']
const SETTINGS: readonly HallSetting[] = ['indoor', 'outdoor', 'mixed']
const EDITOR_STATES = new Set(['single-hall', 'validation', 'success', 'offline', 'unsaved-guard'])

export default function HallsAndAmenities() {
  const { state } = useFrame()
  const nav = useNav()
  const bi = useBi()
  const { t } = useV()
  const hallList = halls()
  const requested = typeof nav.params.hallId === 'string' ? nav.params.hallId : undefined
  const editing = requested ?? (EDITOR_STATES.has(state ?? '') || hallList.length === 1 ? hallList[0]?.id : undefined)
  const loading = state === 'loading'
  const error = state === 'error'

  if (editing && !loading) return <HallEditor hallId={editing} />

  const top = (
    <>
      <TopBar title={t('hotelVenueHallsTitle')} subtitle={bi(venue().name)} />
    </>
  )
  let body
  if (loading) {
    body = (
      <div className="hv-halls" aria-busy="true">
        <Skeleton variant="line" blockSize={24} />
        {[0, 1].map(i => (
          <Skeleton key={i} variant="block" blockSize={96} />
        ))}
      </div>
    )
  } else if (error) {
    body = (
      <Padded>
        <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-04')} />
      </Padded>
    )
  } else {
    body = <HallList onOpen={id => nav.push('HL-VENU-04', { hallId: id })} />
  }
  return (
    <div className="hv-root">
      <Screen top={top}>{body}</Screen>
    </div>
  )
}

// ---------------------------------------------------------------- list

function HallList({ onOpen }: { onOpen: (id: string) => void }) {
  const { t, c, f } = useV()
  const bi = useBi()
  const audience = useAudienceLabel()
  const setting = useSettingLabel()
  const models = useVenueStore(s => s.halls)
  return (
    <div className="hv-halls">
      <VenueProfile />
      <Section title={t('hotelVenueSecHalls')}>
      <div className="hv-hall">
        {halls().map((h, i, all) => {
          const m = models[h.id]
          if (!m) return null
          return (
            <ListRow
              key={h.id}
              flush
              last={i === all.length - 1}
              leading={
                <span className="hv-halls__disk">
                  <Icon name="hall" size="md" />
                </span>
              }
              title={<bdi dir="auto">{bi({ ar: m.nameAr, en: m.nameEn })}</bdi>}
              subtitle={
                <span className="hv-halls__sub">
                  <span className="hv-halls__cap">
                    <Icon name="guests" size="xs" tone="secondary" />
                    <Figures text={f.integer(m.capacityMax)} />
                  </span>
                  <span>{f.list(m.audiences.map(audience))}</span>
                </span>
              }
              chevron
              onClick={() => onOpen(h.id)}
            />
          )
        })}
      </div>
      </Section>
    </div>
  )
}

// ---------------------------------------------------------------- editor

function HallEditor({ hallId }: { hallId: string }) {
  const { state } = useFrame()
  const nav = useNav()
  const isStatic = useIsStatic()
  const { t } = useV()
  const bi = useBi()
  const audience = useAudienceLabel()
  const setting = useSettingLabel()
  const stored = useVenueStore(s => s.halls[hallId])
  const { draft, patch, update, dirty, commit } = useDraft<HallModel>(() => {
    const base = stored ?? seedHall(hallId) ?? (seedHall(halls()[0]?.id ?? '') as HallModel)
    return state === 'validation' ? { ...base, minGuests: { ...base.minGuests, women: base.capacityMax + 50 } } : base
  })

  const offline = state === 'offline'
  const saved = state === 'success'
  const dirtyShown = dirty || state === 'unsaved-guard'
  const guard = useUnsavedGuard(dirtyShown)

  // ---- validation
  const namesMissing = draft.nameAr.trim() === '' || draft.nameEn.trim() === ''
  const noAudience = draft.audiences.length === 0
  const minBad = (a: Audience) => draft.audiences.includes(a) && draft.minGuests[a] >= draft.capacityMax
  const anyMinBad = AUDIENCES.some(minBad)
  const noSession = !draft.exclusiveDay && draft.sessions.length === 0
  const problem = namesMissing ? t('hotelVenueNameRequired') : noAudience ? t('hotelVenueAudAtLeastOne') : anyMinBad ? t('hotelVenueMinAboveMax') : noSession ? t('hotelVenueSessionNeeded') : undefined

  const amenityIds = [...HALL_AMENITIES, ...(draft.setting === 'indoor' ? [] : ['indoor-backup'])]
  const toggleAudience = (next: Audience[]) => patch({ audiences: AUDIENCES.filter(a => next.includes(a)) })

  const save = () => {
    if (problem || isStatic || offline) return
    useVenueStore.getState().saveHall({ ...draft, nameAr: draft.nameAr.trim(), nameEn: draft.nameEn.trim() })
    commit()
    nav.toast({ message: t('hotelVenueToastHallSaved'), icon: 'check-circle' })
    nav.pop()
  }

  const openSession = (s?: SessionModelAlias) => {
    const key = nav.openSheet(
      <SessionSheet
        session={s}
        onSave={next => update(d => ({ ...d, sessions: s ? d.sessions.map(x => (x.id === s.id ? next : x)) : [...d.sessions, next] }))}
        onDelete={
          s
            ? () => {
                update(d => ({ ...d, sessions: d.sessions.filter(x => x.id !== s.id) }))
                nav.closeSheet(key)
              }
            : undefined
        }
      />,
      { title: t(s ? 'hotelVenueSessionEditTitle' : 'hotelVenueSessionNewTitle') },
    )
  }

  const top = (
    <>
      <TopBar title={t('hotelVenueHallEditTitle')} subtitle={bi({ ar: draft.nameAr, en: draft.nameEn })} onBack={guard} />
      <StateStrip offline={offline} saved={saved} />
    </>
  )

  const single = halls().length === 1 || state === 'single-hall'
  const body = (
    <Page>
      {single ? <VenueProfile disabled={offline} /> : null}
      <Section title={t('hotelVenueFieldName')}>
        <BilingualField label={t('hotelVenueFieldName')} ar={draft.nameAr} en={draft.nameEn} onAr={v => patch({ nameAr: v })} onEn={v => patch({ nameEn: v })} maxLength={60} />
      </Section>

      <Section title={t('hotelVenueSecCapacity')}>
        <GuestPicker
          label={t('hotelVenueCapMax')}
          value={draft.capacityMax}
          onChange={v => patch({ capacityMax: v })}
          min={10}
          max={GUEST_HARD_CAP}
          step={10}
          presets={GUEST_PRESETS}
        />
        {draft.audiences.map(a => (
          <GuestPicker
            key={a}
            label={t('hotelVenueCapMin', { audience: audience(a) })}
            value={draft.minGuests[a]}
            onChange={v => patch({ minGuests: { ...draft.minGuests, [a]: v } })}
            min={10}
            max={GUEST_HARD_CAP}
            step={10}
            presets={GUEST_PRESETS}
            error={minBad(a) ? t('hotelVenueMinAboveMax') : undefined}
          />
        ))}
      </Section>

      <Section title={t('hotelVenueSecHallAudience')}>
        <div className="hv-field">
          <ChipGroup<Audience> label={t('hotelVenueAudienceAllowed')} selection="multiple" value={draft.audiences} onChange={toggleAudience} options={AUDIENCES.map(a => ({ value: a, label: audience(a) }))} />
          {noAudience ? <FieldError>{t('hotelVenueAudAtLeastOne')}</FieldError> : null}
        </div>
        <div className="hv-field">
          <ChipGroup<HallSetting> label={t('hotelVenueSettingLabel')} value={draft.setting} onChange={v => v && patch({ setting: v })} options={SETTINGS.map(s => ({ value: s, label: setting(s) }))} />
        </div>
      </Section>

      <Section title={t('hotelVenueSecSessions')}>
        <ToggleRow
          title={t('hotelVenueExclusiveTitle')}
          checked={draft.exclusiveDay}
          onChange={v => patch({ exclusiveDay: v })}
          divider={false}
        />
        {(
          <>
            <div className="hv-am">
              {draft.sessions.map(s => (
                <SessionRow key={s.id} s={s} onOpen={() => openSession(s)} disabled={offline} />
              ))}
            </div>
            {noSession ? <FieldError>{t('hotelVenueSessionNeeded')}</FieldError> : null}
            <Button variant="secondary" iconStart="plus" onClick={() => openSession()} disabled={offline}>
              {t('hotelVenueSessionAdd')}
            </Button>
          </>
        )}
      </Section>

      <Section title={t('hotelVenueSecFacilities')}>
        <AmenityRows ids={amenityIds} states={draft.amenities} onChange={(id, s: AmenityState) => update(d => ({ ...d, amenities: { ...d.amenities, [id]: s } }))} />
      </Section>

      {draft.audiences.length > 0 ? (
        <Section title={t('hotelVenueSecSections')}>
          {draft.audiences.map(a => (
            <SectionFacts
              key={a}
              audience={a}
              facts={draft.facts[a] ?? { photography: 'allowed', music: 'none' }}
              onChange={next => update(d => ({ ...d, facts: { ...d.facts, [a]: next } }))}
            />
          ))}
        </Section>
      ) : null}

      <ListRow flush last leading={<Icon name="clipboard" size="md" />} title={t('hotelVenueLinkRules')} chevron onClick={() => nav.push('HL-VENU-06', { hallId: draft.id })} />
    </Page>
  )

  return (
    <div className="hv-root">
      <Screen top={top} bottom={<SaveBar dirty={dirtyShown} problem={problem} offline={offline} saved={saved} onSave={save} />}>
        {body}
      </Screen>
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelVenueGuardTitle')} body={t('hotelVenueGuardBody')} icon="warning-circle" tone="destructive" confirmLabel={t('hotelVenueGuardDiscard')} cancelLabel={t('hotelVenueGuardKeep')} />
      ) : null}
    </div>
  )
}

type SessionModelAlias = HallModel['sessions'][number]
