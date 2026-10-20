// HL-SETT-05 Business hours. Requirement IDs: HA-SET-04, HA-AUTH-02.
// The hours the venue office is reachable, shown to couples, and the closures that apply; the same hours decide when a new-request alert makes
// a sound. A live "Shown to couples as" strip (an eye and the lines), seven rows starting with Sunday (a short day name, the opening and the
// closing time as two buttons with an arrow between them, the open switch; a time is its figure plus a sun, sunset or moon glyph, a closing time
// before the opening time runs past midnight and shows +1, the same time on both ends is the one mistake), "All days" under the row being edited,
// closures (Ramadan and the Eids as approximate ranges), a pinned Save and a guard against leaving unsaved. Admin edits, Manager views, other
// roles do not see the screen. Times are Kuwait time.
// Text diet (ADR 0034): no lead, no row labels, no captions; what the hours are for, that times are Kuwait time and that the Eids are estimates
// are three short lines in the sheet of the top bar's (i).
// States: loading, validation, success, error, offline, unsaved-guard, role-view-only.
import { useEffect, useRef, useState } from 'react'
import { useFrame } from '../../../shell/frame'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { ActionBar, Badge, Banner, Button, Chip, Dialog, ErrorState, Icon, IconButton, Screen, SectionHeader, Skeleton, TopBar, useNav } from '../../../system'
import { Figures, useWords } from './_components/bits'
import { Fx } from './_components/Fx'
import { ClosureContent, HoursDay, TimeContent, usePreviewLines } from './_components/HoursParts'
import { AboutSheet } from './_components/NotifParts'
import { ACCESS, SUGGESTED_CLOSURES, WEEK, isInvalidDay, roleOfState, sameWeek, type Closure, type Week, type Weekday } from './_components/model'
import { useSettingsLocal } from './_components/store'
import './HL-SETT-05.css'

export const states = ['loading', 'validation', 'success', 'error', 'offline', 'unsaved-guard', 'role-view-only']

let closureSeq = 0

export default function BusinessHours() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { lang } = useLang()
  const { t, c } = useWords()
  const preview = usePreviewLines()
  const store = useSettingsLocal()
  const role = roleOfState(state)
  const mode = state === 'role-view-only' ? 'view' : ACCESS[role].hours
  const offline = state === 'offline'
  const [about, setAbout] = useState(false)

  // Frames that show an edited week draw it without touching the live store (the canvas draws several frames at once).
  const demo: Week | null =
    state === 'validation' ? { ...store.week, 1: { ...store.week[1], from: '22:00', to: '22:00' } } : state === 'unsaved-guard' ? { ...store.week, 1: { ...store.week[1], to: '23:00' } } : null
  const week = demo ?? store.week
  const dirty = demo !== null || !sameWeek(store.week, store.savedWeek) || store.closures.length !== store.savedClosures.length || store.closures.some((x, i) => x.id !== store.savedClosures[i]?.id)
  const invalid = WEEK.some(d => isInvalidDay(week[d]))
  const lastEdited: Weekday | null = demo ? 1 : store.lastEdited

  const closureName = (x: Closure) => x.label[lang] || t('hotelSettingsHoursClosure')
  const closureRange = (x: Closure) => (x.from === x.to ? f.date(x.from, 'dayMonth') : t('hotelSettingsHoursClosureRange', { from: f.date(x.from, 'dayMonth'), to: f.date(x.to, 'dayMonth') }))

  // ---- leaving with unsaved changes
  const guard = async () => {
    if (!dirty) {
      nav.pop()
      return
    }
    const result = await nav.openDialog({
      title: t('hotelSettingsHoursGuardTitle'),
      icon: 'warning-circle',
      confirmLabel: t('hotelSettingsHoursGuardLeave'),
      cancelLabel: t('hotelSettingsHoursGuardStay'),
      tone: 'destructive',
    })
    if (result === 'confirm') {
      useSettingsLocal.getState().discardHours()
      nav.pop()
    }
  }
  // Leaving by any route drops edits that were never saved (the next visit starts from what couples see).
  const discardOnLeave = useRef(false)
  useEffect(
    () => () => {
      if (discardOnLeave.current) useSettingsLocal.getState().discardHours()
    },
    [],
  )
  discardOnLeave.current = demo === null

  // ---- sheets
  const pickTime = (day: Weekday, which: 'from' | 'to') => {
    const key = nav.openSheet(
      <TimeContent
        title={which === 'from' ? t('hotelSettingsHoursTimeFrom') : t('hotelSettingsHoursTimeTo')}
        initial={store.week[day][which]}
        onClose={() => nav.closeSheet(key)}
        onSet={v => {
          useSettingsLocal.getState().setDay(day, { [which]: v })
          nav.closeSheet(key)
        }}
      />,
    )
  }
  const addClosure = () => {
    const key = nav.openSheet(
      <ClosureContent
        onClose={() => nav.closeSheet(key)}
        onAdd={x => {
          closureSeq += 1
          useSettingsLocal.getState().addClosure({ ...x, id: `closure-local-${closureSeq}` })
          nav.closeSheet(key)
        }}
      />,
    )
  }
  const save = () => {
    if (offline) {
      nav.toast({ message: c('commonStateOffline'), icon: 'offline' })
      return
    }
    if (invalid) return
    useSettingsLocal.getState().saveHours()
    nav.toast({ message: c('commonStateSaved'), tone: 'success', icon: 'check-circle' })
  }

  const suggestions = SUGGESTED_CLOSURES.filter(s => !store.closures.some(x => x.id === s.id))

  let body
  if (state === 'loading') {
    body = (
      <div className="hs-page__skeleton" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={96} />
        {[0, 1, 2, 3, 4].map(i => (
          <Skeleton key={i} variant="line" blockSize={64} />
        ))}
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-SETT-05')} />
  } else if (mode === 'none') {
    body = <ErrorState kind="no-access" />
  } else {
    const edit = mode === 'edit'
    body = (
      <>
        <div className="hs-page__pad hs-hours__top">
          <section className="hs-hours__preview" aria-label={t('hotelSettingsHoursPreview')} aria-live="polite">
            <Icon name="eye" size="sm" tone="secondary" />
            <div className="hs-hours__lines">
              {preview(week).map(line => (
                <p key={line} className="gz-t-body hs-hours__line">
                  <Figures text={line} />
                </p>
              ))}
            </div>
            <span className="gz-sr-only">{c('commonLabelKuwaitTime')}</span>
          </section>
          {!edit ? (
            <Badge variant="quiet" bead={false} icon="lock">
              {t('hotelSettingsHoursViewOnly')}
            </Badge>
          ) : null}
        </div>

        <div className="hs-hours__rows" role="group" aria-label={t('hotelSettingsHoursWeek')}>
          {WEEK.map((d, i) => (
            <HoursDay
              key={d}
              weekday={d}
              day={week[d]}
              invalid={isInvalidDay(week[d])}
              onOpenChange={edit ? on => useSettingsLocal.getState().setDay(d, { open: on }) : undefined}
              onPickFrom={edit ? () => pickTime(d, 'from') : undefined}
              onPickTo={edit ? () => pickTime(d, 'to') : undefined}
              onCopy={edit && lastEdited === d && week[d].open ? () => useSettingsLocal.getState().copyToAll(d) : undefined}
              last={i === WEEK.length - 1}
            />
          ))}
        </div>

        <section className="hs-section" aria-label={t('hotelSettingsHoursClosures')}>
          <div className="hs-section__head">
            <SectionHeader title={t('hotelSettingsHoursClosures')} voice="hotel" />
          </div>
          {store.closures.length > 0 ? (
            <div className="hs-hours__closures">
              {store.closures.map(x => (
                <div key={x.id} className="hs-closure">
                  <Icon name="calendar-x" size="sm" tone="secondary" />
                  <span className="hs-closure__text">
                    <span className="gz-t-title hs-closure__name">
                      <bdi dir="auto">{closureName(x)}</bdi>
                    </span>
                    <span className="hs-closure__meta">
                      <span className="gz-t-fig-body-s hs-closure__range">
                        <Fx text={closureRange(x)} />
                      </span>
                      {x.approximate ? (
                        <Badge variant="quiet" bead={false}>
                          {t('hotelSettingsHoursApprox')}
                        </Badge>
                      ) : null}
                    </span>
                  </span>
                  {edit ? (
                    <IconButton icon="trash" label={t('hotelSettingsHoursRemoveClosure', { label: closureName(x) })} onClick={() => useSettingsLocal.getState().removeClosure(x.id)} />
                  ) : null}
                </div>
              ))}
            </div>
          ) : null}
          {edit ? (
            <div className="hs-page__pad hs-hours__add">
              {suggestions.length > 0 ? (
                <div className="hs-hours__suggest" role="group" aria-label={t('hotelSettingsHoursSuggested')}>
                  {suggestions.map(s => (
                    <Chip key={s.id} iconStart="plus" onClick={() => useSettingsLocal.getState().addClosure(s)}>
                      {s.label[lang]}
                    </Chip>
                  ))}
                </div>
              ) : null}
              <Button variant="tertiary" iconStart="calendar-plus" onClick={addClosure}>
                {t('hotelSettingsHoursAddClosure')}
              </Button>
            </div>
          ) : null}
        </section>
      </>
    )
  }

  const showBar = mode === 'edit' && state !== 'loading' && state !== 'error'
  const bar = showBar ? <ActionBar action={{ label: t('hotelSettingsHoursSave'), onPress: save, disabled: invalid || offline }} /> : undefined

  const hasApprox = store.closures.some(x => x.approximate)
  const aboutLines = [
    { icon: 'clock' as const, text: t('hotelSettingsHoursAbout') },
    { icon: 'globe' as const, text: c('commonLabelKuwaitTime') },
    ...(hasApprox ? [{ icon: 'calendar-x' as const, text: t('hotelSettingsHoursApproxNote') }] : []),
  ]
  const actions = state === 'loading' || state === 'error' || mode === 'none' ? [] : [{ icon: 'info' as const, label: c('commonA11yInfo'), onPress: () => setAbout(true) }]

  return (
    <div className="hs-root">
      <Screen top={<TopBar title={t('hotelSettingsMoreHours')} actions={actions} onBack={dirty ? guard : undefined} />} bottom={bar}>
        {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
        {state === 'success' ? (
          <Banner tone="info" icon="check-circle" shape="card">
            {c('commonStateSaved')}
          </Banner>
        ) : null}
        <div className="hs-page">{body}</div>
      </Screen>
      <AboutSheet open={about} onClose={() => setAbout(false)} title={t('hotelSettingsHoursAboutTitle')} lines={aboutLines} />
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelSettingsHoursGuardTitle')} icon="warning-circle" confirmLabel={t('hotelSettingsHoursGuardLeave')} cancelLabel={t('hotelSettingsHoursGuardStay')} tone="destructive" />
      ) : null}
    </div>
  )
}
