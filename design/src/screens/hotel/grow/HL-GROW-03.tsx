// HL-GROW-03 Voucher price window, step 2 of 2: the event dates the window covers and when it runs, then publish, with the client card still on
// screen (pinned under the step thread) and the request price a couple will see. Windows are dated; there are no usage limits per code and no
// coupon codes (ADR 0033 D4).
// Text diet (ADR 0034): two shortcut chips with a glyph, the calendar, a chosen-dates figure, Start and End as two compact date fields, one switch
// for "no end", one status pill, the request price as three glyph rows; the overlap and the publish failure are fragments with their sentence
// behind an (i); the fee note sits behind the (i) of the price section.
// Requirements: HA-OFFR-01, HA-OFFR-02, HA-OFFR-06, HA-AUTH-02
// States: validation, overlap-warning, loading, success, error, offline, scheduled.
import { useMemo, useState } from 'react'
import { engine, PROTOTYPE_TODAY, softDatesFor, venueAvailabilityOn } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, Button, ChipGroup, FactChip, Icon, InfoButton, Price, Screen, Skeleton, StatusPill, Toast, ToastRegion, ToggleRow, TopBar, useNav } from '../../../system'
import { Fx, dm, useBi, useWords } from './_components/bits'
import { DatePick } from './_components/DatePick'
import { EventCalendar, type YearMonth } from './_components/EventCalendar'
import { Head } from './_components/Head'
import { Note } from './_components/Note'
import { PreviewStrip } from './_components/PreviewStrip'
import { PriceLines } from './_components/PriceLines'
import { StepThread } from './_components/StepThread'
import { useEditorDraft } from './_components/useDraft'
import { draftFils, overlaps, shortcutDates, VENUE_ID, windowRate, type Shortcut } from './_components/model'
import { useGrow } from './_components/store'
import './HL-GROW-03.css'

export const states = ['validation', 'overlap-warning', 'loading', 'success', 'error', 'offline', 'scheduled']

const monthOfIso = (iso: string): YearMonth => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
const isFree = (iso: string) => venueAvailabilityOn(VENUE_ID, iso).state === 'available'

export default function WindowSchedule() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const { draft: base, titleEn, titleAr } = useEditorDraft(state)
  const patch = useGrow(s => s.patchDraft)
  const windows = useGrow(s => s.windows)
  const loading = state === 'loading'
  const failed = state === 'error'
  const offline = state === 'offline'

  // Frame states lay their own facts over the draft (a static frame has no history to arrive with).
  const draft = state === 'validation' ? { ...base, eventDates: [], shortcut: null, untilEnd: false, endsOn: null } : base
  const rate = draftFils(draft)
  const [month, setMonth] = useState<YearMonth>(() => monthOfIso(draft.eventDates[0] ?? PROTOTYPE_TODAY))
  const [busy, setBusy] = useState(false)
  const today = PROTOTYPE_TODAY
  const soft = softDatesFor(VENUE_ID)

  // ---- shortcuts replace manual dates
  const openWeekends = useMemo(() => shortcutDates('open-weekends', isFree), [])
  const weekdays = useMemo(() => shortcutDates('weekdays', isFree), [])
  const shortcutList = (k: Shortcut) => (k === 'open-weekends' ? openWeekends : weekdays)
  const setShortcut = (k: Shortcut | null) => patch(k ? { shortcut: k, eventDates: shortcutList(k) } : { shortcut: null, eventDates: [] })
  const toggleDate = (iso: string) => {
    const has = draft.eventDates.includes(iso)
    const from = draft.shortcut ? [] : draft.eventDates
    patch({ shortcut: null, eventDates: has ? from.filter(d => d !== iso) : [...from, iso].sort() })
  }

  // ---- when it runs
  const scheduled = Boolean(draft.startsOn && draft.startsOn > today)
  const startDate = draft.startsOn ?? today

  // ---- overlap: a window with a better voucher price already covers some of these dates
  const clashes = useMemo(() => overlaps(windows, { packageIds: draft.packageIds, dates: draft.eventDates, fils: rate }), [windows, draft.packageIds, draft.eventDates, rate])
  const clash = clashes[0]

  // ---- validation
  const noDates = draft.eventDates.length === 0
  const endBeforeStart = !draft.untilEnd && Boolean(draft.endsOn && startDate > draft.endsOn)
  const noEnd = !draft.untilEnd && !draft.endsOn
  const blocked: string | undefined = offline ? t('hotelGrowOfflinePublish') : noDates ? t('hotelGrowReasonDates') : endBeforeStart || noEnd ? t('hotelGrowReasonEnd') : undefined
  const showErrors = state === 'validation' || (!state && (draft.dirty || draft.eventDates.length > 0))

  const publish = () => {
    if (busy || blocked) return
    setBusy(true)
    window.setTimeout(() => {
      const g = useGrow.getState()
      const origin = g.origin
      const made = g.publish({ en: titleEn, ar: titleAr })
      nav.pop(2)
      nav.toast({
        message: t(made.status === 'scheduled' ? 'hotelGrowToastScheduled' : 'hotelGrowToastPublished'),
        tone: 'success',
        action: {
          label: t('hotelGrowView'),
          onPress: () => {
            useGrow.getState().requestOpen(made.id)
            if (origin !== 'list') nav.push('HL-GROW-01')
          },
        },
      })
    }, 900)
  }

  const top = (
    <>
      <TopBar back title={t('hotelGrowEditorTitle')} />
      <StepThread step={2} />
      {loading || failed ? null : (
        <div className="gs-pin">
          <PreviewStrip compact rate={rate} packageIds={draft.packageIds} dates={draft.eventDates} />
        </div>
      )}
      {offline ? <Banner tone="offline">{t('hotelGrowOfflineEdit')}</Banner> : null}
    </>
  )

  const bottom = loading ? null : (
    <ActionBar
      action={{
        label: failed ? c('commonActionRetry') : t(scheduled ? 'hotelGrowSchedule' : 'hotelGrowPublish'),
        iconEnd: failed ? 'refresh' : scheduled ? 'calendar-check' : 'check',
        onPress: failed ? () => nav.replace('HL-GROW-03') : publish,
        loading: busy,
        disabled: !failed && Boolean(blocked),
        reason: !failed ? blocked : undefined,
      }}
    />
  )

  let body
  if (loading) {
    body = (
      <div className="gt-body" aria-busy="true">
        <Skeleton variant="block" blockSize={72} />
        <Skeleton variant="block" blockSize={320} />
        <Skeleton variant="line" blockSize={56} />
        <Skeleton variant="line" blockSize={56} />
      </div>
    )
  } else {
    body = (
      <div className="gt-body">
        {failed ? (
          <Note
            tone="danger"
            info={
              <InfoButton title={t('hotelGrowPublishFailedTitle')}>
                <p>{t('hotelGrowPublishFailed')}</p>
              </InfoButton>
            }
          >
            {t('hotelGrowPublishFailedTitle')}
          </Note>
        ) : null}

        <section className="gt-section">
          <Head icon="calendar-dots" title={t('hotelGrowDatesTitle')} />
          <ChipGroup<Shortcut>
            label={t('hotelGrowShortcuts')}
            layout="wrap"
            deselectable
            value={draft.shortcut}
            onChange={k => setShortcut(k)}
            options={[
              {
                value: 'open-weekends',
                label: (
                  <span className="gt-chip" title={t('hotelGrowOpenWeekendsBody', { days: 60 })}>
                    <Icon name="calendar-dots" size="xs" />
                    {t('hotelGrowOpenWeekends')}
                  </span>
                ),
              },
              {
                value: 'weekdays',
                label: (
                  <span className="gt-chip" title={t('hotelGrowWeekdaysBody', { days: 60 })}>
                    <Icon name="calendar" size="xs" />
                    {t('hotelGrowWeekdays')}
                  </span>
                ),
              },
            ]}
          />
          {draft.shortcut ? (
            <div className="gt-count">
              <FactChip icon="calendar-check" value={f.integer(shortcutList(draft.shortcut).length)} label={t('hotelGrowDatesChosen')} tone="accent" />
              <Button variant="tertiary" iconStart="calendar" onClick={() => setShortcut(null)}>
                {t('hotelGrowChooseDates')}
              </Button>
            </div>
          ) : (
            <>
              <EventCalendar
                month={month}
                onMonthChange={setMonth}
                picked={draft.eventDates}
                onToggle={toggleDate}
                minMonth={monthOfIso(today)}
                maxMonth={monthOfIso(engine.addDays(today, 360))}
                today={today}
                label={t('hotelGrowDatesTitle')}
              />
              <div className="gt-count">
                {noDates ? (
                  showErrors ? (
                    <span className="gz-t-body-s gt-count__error" role="alert">
                      <Icon name="warning-circle" size="xs" tone="danger" />
                      {t('hotelGrowNoDatesError')}
                    </span>
                  ) : (
                    <span className="gt-count__spacer" />
                  )
                ) : (
                  <FactChip icon="calendar-check" value={f.integer(draft.eventDates.length)} label={t('hotelGrowDatesChosen')} tone="accent" />
                )}
                {draft.eventDates.length > 0 ? (
                  <Button variant="tertiary" onClick={() => patch({ eventDates: [] })}>
                    {t('hotelGrowClearDates')}
                  </Button>
                ) : soft.length > 0 ? (
                  <Button variant="tertiary" iconStart="calendar-plus" onClick={() => patch({ eventDates: [...soft], shortcut: null })}>
                    {t('hotelGrowUseOpenDates')}
                  </Button>
                ) : null}
              </div>
            </>
          )}
        </section>

        {clash ? (
          <Note
            icon="offer"
            info={
              <InfoButton title={t('hotelGrowOverlapTitle')}>
                <p>
                  {t('hotelGrowOverlap', {
                    title: bi(clash.window.title),
                    value: f.money(windowRate(clash.window)),
                    dates: f.list(clash.dates.slice(0, 3).map(d => f.date(d, 'short'))),
                  })}
                </p>
              </InfoButton>
            }
          >
            <bdi dir="auto" className="gt-clash">
              {bi(clash.window.title)}
            </bdi>{' '}
            <Price fils={windowRate(clash.window)} mode="browse" size="strong" />
          </Note>
        ) : null}

        <section className="gt-section">
          <Head icon="timer" title={t('hotelGrowRunsTitle')} />
          <div className="gt-dates">
            <DatePick label={t('hotelGrowStartsLabel')} value={startDate} onChange={d => patch({ startsOn: d })} minDate={today} today={today} />
            {draft.untilEnd ? null : (
              <DatePick
                label={t('hotelGrowEndsLabel')}
                value={draft.endsOn}
                onChange={d => patch({ endsOn: d })}
                minDate={startDate}
                today={today}
                error={showErrors && endBeforeStart ? t('hotelGrowEndBeforeStart') : showErrors && noEnd ? t('hotelGrowEndRequired') : undefined}
              />
            )}
          </div>
          <ToggleRow title={t('hotelGrowUntilEnd')} checked={draft.untilEnd} onChange={on => patch({ untilEnd: on, endsOn: on ? null : draft.endsOn })} divider={false} />
          <div className="gt-status">
            <StatusPill status={scheduled ? 'requested' : 'confirmed'} label={scheduled ? t('hotelGrowScheduledPill') : c('commonListingStatusActive')} />
          </div>
        </section>

        <PriceLines rate={rate} packageIds={draft.packageIds} dates={draft.eventDates} />
      </div>
    )
  }

  return (
    <div className="gt-root">
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'success' ? (
        <ToastRegion>
          <Toast icon="check-circle" message={t('hotelGrowToastPublished')} actionLabel={t('hotelGrowView')} />
        </ToastRegion>
      ) : null}
    </div>
  )
}
