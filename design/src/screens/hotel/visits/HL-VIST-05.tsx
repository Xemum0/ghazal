// HL-VIST-05 Visit availability. Requirement IDs: HA-VIS-05, HA-AUTH-02.
// When couples can request a visit: a master switch ("Accept visit requests"; off hides Book a visit on the client venue page), seven weekday
// rows Sunday first (open switch, from and to through a custom 12-hour time sheet), the arrival-window length, the default representative
// and blackout dates. The business hours (HL-SETT-05) are the outer bound; a visit window never runs past midnight. Drives the slots in the
// client's visit sheet. Admin and Manager only. Pinned "Save changes", a guard against leaving unsaved, offline disables Save in place.
// States: default, visits-off, validation, success, error, offline, unsaved-guard, role-hidden
import { useEffect, useMemo, useRef } from 'react'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, Button, Chip, ChipGroup, Dialog, ErrorState, IconButton, ListRow, Screen, Skeleton, ToggleRow, TopBar, useNav } from '../../../system'
import { Avatar } from '../../../system'
import { Figures, Notice, Section, UserText, useWords } from './_components/bits'
import { BlackoutContent, TimeContent } from './_components/AvailabilitySheets'
import { VisitDayRow } from './_components/VisitDayRow'
import { RepContent } from './_components/Sheets'
import { SLOT_CHOICES, mistakeOf, seedAvailability } from './_components/availability'
import { isLead, roleOfParam, staffById } from './_components/model'
import { WEEK_DAYS, sameAvailability, useVisitsLocal, type Availability } from './_components/store'
import './HL-VIST-05.css'

export const states = ['default', 'visits-off', 'validation', 'success', 'error', 'offline', 'unsaved-guard', 'role-hidden']

let blackoutSeq = 0

export default function VisitAvailability() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { lang } = useLang()
  const { t, c } = useWords()
  const seed = useMemo(seedAvailability, [])
  const store = useVisitsLocal()
  useEffect(() => store.init(seed), []) // eslint-disable-line react-hooks/exhaustive-deps
  const role = state === 'role-hidden' ? 'reception' : roleOfParam((nav.params as { role?: string }).role)
  const offline = state === 'offline'

  // Frames that show an edited or switched-off week draw it without touching the live store (the canvas draws several frames at once).
  const saved = store.saved ?? seed
  const demo: Availability | null =
    state === 'visits-off'
      ? { ...saved, on: false }
      : state === 'validation'
        ? { ...saved, week: { ...saved.week, 1: { ...saved.week[1], from: '17:00', to: '10:00' } } }
        : state === 'unsaved-guard'
          ? { ...saved, slotMinutes: 60 }
          : null
  const draft = demo ?? store.draft ?? seed
  const dirty = demo !== null ? state === 'unsaved-guard' || state === 'validation' : !sameAvailability(store.draft, store.saved)
  const mistakes = WEEK_DAYS.map(d => mistakeOf(d, draft.week[d]))
  const invalid = draft.on && mistakes.some(Boolean)

  // ---- leaving with unsaved changes
  const guard = async () => {
    if (!dirty) {
      nav.pop()
      return
    }
    const result = await nav.openDialog({
      title: t('hotelVisitsGuardTitle'),
      body: t('hotelVisitsGuardBody'),
      icon: 'warning-circle',
      confirmLabel: t('hotelVisitsGuardLeave'),
      cancelLabel: t('hotelVisitsGuardStay'),
      tone: 'destructive',
    })
    if (result === 'confirm') {
      useVisitsLocal.getState().discard()
      nav.pop()
    }
  }
  const discardOnLeave = useRef(false)
  useEffect(
    () => () => {
      if (discardOnLeave.current) useVisitsLocal.getState().discard()
    },
    [],
  )
  discardOnLeave.current = demo === null

  // ---- sheets
  const pickTime = (day: (typeof WEEK_DAYS)[number], which: 'from' | 'to') => {
    const key = nav.openSheet(
      <TimeContent
        title={which === 'from' ? t('hotelVisitsTimeFrom') : t('hotelVisitsTimeTo')}
        day={day}
        initial={draft.week[day][which]}
        onSet={v => {
          useVisitsLocal.getState().setDay(day, { [which]: v })
          nav.closeSheet(key)
        }}
      />,
    )
  }
  const addBlackout = () => {
    const key = nav.openSheet(
      <BlackoutContent
        onAdd={(from, to) => {
          blackoutSeq += 1
          useVisitsLocal.getState().edit({ blackouts: [...draft.blackouts, { id: `blackout-${blackoutSeq}`, from, to }] })
          nav.closeSheet(key)
        }}
      />,
    )
  }
  const pickRep = () => {
    const key = nav.openSheet(
      <RepContent
        currentId={draft.repId ?? ''}
        onPick={s => {
          useVisitsLocal.getState().edit({ repId: s.userId })
          nav.closeSheet(key)
        }}
      />,
    )
  }
  const save = () => {
    if (offline) {
      nav.toast({ message: t('hotelVisitsSaveOfflineToast'), icon: 'offline' })
      return
    }
    if (invalid) return
    useVisitsLocal.getState().save()
    nav.toast({ message: t('hotelVisitsSaved'), tone: 'success', icon: 'check-circle' })
  }

  const rep = draft.repId ? staffById(draft.repId) : undefined
  const repName = rep ? (lang === 'ar' ? rep.name : rep.nameLatin) : ''
  const rangeText = (from: string, to: string) => (from === to ? f.date(from, 'short') : t('hotelVisitsBlackoutRange', { from: f.date(from, 'dayMonth'), to: f.date(to, 'short') }))

  let body
  if (state === 'loading') {
    body = (
      <div className="hv-av__skel" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={80} />
        {[0, 1, 2, 3].map(i => (
          <Skeleton key={i} variant="line" blockSize={64} />
        ))}
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" title={t('hotelVisitsAvailErrorTitle')} body={t('hotelVisitsErrorBody')} onRetry={() => nav.replace('HL-VIST-05')} />
  } else if (!isLead(role)) {
    body = <ErrorState kind="no-access" title={t('hotelVisitsAvailHiddenTitle')} body={t('hotelVisitsAvailHiddenBody')} />
  } else {
    body = (
      <>
        <div className="hv-av__pad">
          <ToggleRow title={t('hotelVisitsMasterTitle')} checked={draft.on} onChange={on => demo === null && useVisitsLocal.getState().edit({ on })} divider={false} />
        </div>
        {!draft.on ? (
          <div className="hv-av__pad">
            <Notice icon="eye-off" tone="rose" role="status" title={t('hotelVisitsOffTitle')}>
              {t('hotelVisitsOffBody')}
            </Notice>
          </div>
        ) : (
          <>
            <Section title={t('hotelVisitsSecDays')}>
              <div className="hv-av__rows">
                {WEEK_DAYS.map((d, i) => (
                  <VisitDayRow
                    key={d}
                    weekday={d}
                    day={draft.week[d]}
                    mistake={mistakes[i] ?? null}
                    onToggle={open => demo === null && useVisitsLocal.getState().setDay(d, { open })}
                    onPickFrom={() => pickTime(d, 'from')}
                    onPickTo={() => pickTime(d, 'to')}
                    last={i === WEEK_DAYS.length - 1}
                  />
                ))}
              </div>
              <Button variant="tertiary" iconStart="clock" onClick={() => nav.push('HL-SETT-05')}>
                {t('hotelVisitsSeeBusinessHours')}
              </Button>
            </Section>

            <Section title={t('hotelVisitsSecSlot')}>
              <ChipGroup<string>
                label={t('hotelVisitsSecSlot')}
                layout="wrap"
                value={String(draft.slotMinutes)}
                onChange={v => v && demo === null && useVisitsLocal.getState().edit({ slotMinutes: Number(v) as Availability['slotMinutes'] })}
                options={SLOT_CHOICES.map(m => ({ value: String(m), label: t('hotelVisitsSlotChip', { minutes: f.integer(m) }) }))}
              />
            </Section>

            <Section title={t('hotelVisitsSecRepDefault')}>
              <div className="hv-av__rep">
                <ListRow
                  flush
                  last
                  leading={rep ? <Avatar name={repName} initial={lang === 'ar' ? rep.monogram : undefined} size="sm" voice="sans" /> : undefined}
                  title={rep ? <UserText role="title">{repName}</UserText> : t('hotelVisitsRepNone')}
                  subtitle={rep ? rep.roleLabel[lang] : undefined}
                  chevron
                  onClick={pickRep}
                />
              </div>
            </Section>

            <Section title={t('hotelVisitsSecBlackouts')}>
              <div className="hv-av__blackouts">
                {draft.blackouts.map(b => (
                  <div key={b.id} className="hv-black">
                    <span className="gz-t-body hv-black__range">
                      <Figures text={rangeText(b.from, b.to)} />
                    </span>
                    <IconButton icon="trash" label={t('hotelVisitsBlackoutRemove', { range: f.plain(rangeText(b.from, b.to)) })} onClick={() => useVisitsLocal.getState().edit({ blackouts: draft.blackouts.filter(x => x.id !== b.id) })} />
                  </div>
                ))}
              </div>
              <div className="hv-av__add">
                <Chip iconStart="plus" onClick={addBlackout}>
                  {t('hotelVisitsBlackoutsAdd')}
                </Chip>
              </div>
            </Section>
          </>
        )}
      </>
    )
  }

  const showBar = isLead(role) && state !== 'loading' && state !== 'error'
  const bar = showBar ? (
    <ActionBar
      action={{
        label: t('hotelVisitsSave'),
        onPress: save,
        disabled: invalid || offline || !dirty,
        reason: invalid ? t('hotelVisitsSaveInvalid') : offline ? t('hotelVisitsSaveOfflineToast') : !dirty ? t('hotelVisitsSaveClean') : undefined,
      }}
    />
  ) : undefined

  return (
    <div className="hv-av__root">
      <Screen top={<TopBar title={t('hotelVisitsAvailTitle')} onBack={dirty ? guard : undefined} />} bottom={bar} bodyClassName="hv-av">
        {offline ? <Banner tone="offline">{t('hotelVisitsOfflineBannerShort')}</Banner> : null}
        {state === 'success' ? (
          <Banner tone="info" icon="check-circle" shape="card">
            {t('hotelVisitsSavedBanner')}
          </Banner>
        ) : null}
        {body}
      </Screen>
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelVisitsGuardTitle')} body={t('hotelVisitsGuardBody')} icon="warning-circle" confirmLabel={t('hotelVisitsGuardLeave')} cancelLabel={t('hotelVisitsGuardStay')} tone="destructive" />
      ) : null}
    </div>
  )
}
