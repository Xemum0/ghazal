// HL-CALN-04 Block or open dates (sheet): take dates off sale (offline sales, maintenance, private events) or put them back on sale, for one date or a
// range, scoped by hall. A confirmed booking cannot be blocked (ADR 0002 D9): the sheet names the booking and links to its cancel flow. Offline,
// the primary rests in place. Pending requests are counted before anything changes (a request never claims the date, ADR 0001 D5).
// Text diet (ADR 0034): the head is the Block | Open switch (a lock and a door), the dates are one line and a chevron, the hall and the reason
// are chips named by a glyph, the warnings are a bead or a pill and a figure; every sentence (what couples see, what happens to a pending
// request, why a booked date refuses) is behind an (i). The outcome is a drawing, a few words and the dates.
// Requirements: HA-CAL-04, HA-CAL-05, HA-CAL-08, HA-CAL-09, HA-AUTH-02
// States: open-variant, conflict-confirmed, conflict-pending, loading, success, partial-fail, offline, error, edit-dates
// The three taps: Calendar, the date, Block (this sheet opens on that date) and the gold primary. A block resolves to the toast "Hidden from
// couples" with Undo (8 seconds) and the calendar updates in place.
import { useEffect, useMemo, useRef, useState } from 'react'
import type { BlockReason } from '../../../mock'
import { meta } from '../../../mock'
import { useFormat } from '../../../i18n'
import { Button, Checkbox, ChipGroup, FactChip, FactRow, HotelMonthGrid, Icon, IconSegmented, InfoButton, StatusPill, TextField, ThreadBead, useNav } from '../../../system'
import type { DateSpan } from '../../../system'
import { ChipRow } from './_components/ChipRow'
import { Notice } from './_components/CalNotice'
import { SheetFrame } from './_components/CalSheetFrame'
import { Outcome } from './_components/Outcome'
import { DEMO_RANGE, HALLS, TODAY, analyse, blockClaims, blockedIn, datesOfSpan, useClaims } from './_components/data'
import { Fig, Fx, UserText, useBi, useDayMonth, useLive, useReasonLabel, useShortHall, useSpanText, useWords } from './_components/calBits'
import { useCal, type YearMonth } from './_components/store'
import './HL-CALN-04.css'

export const states = ['open-variant', 'conflict-confirmed', 'conflict-pending', 'loading', 'success', 'partial-fail', 'offline', 'error', 'edit-dates']

type Mode = 'block' | 'open'
type Phase = 'idle' | 'loading' | 'success' | 'partial'
type SheetParams = { mode?: Mode; start?: string | null; end?: string | null; hallIds?: string[]; role?: string }

/** The ranges the frames of the conflict states draw: Fri 13 - Sun 15 Nov (Danah booked Fri, both halls Sat) and Thu 14 Jan 2027 (Reem's request). */
const FRAME_RANGE: Record<string, DateSpan> = {
  'conflict-confirmed': { start: '2026-11-13', end: '2026-11-15' },
  'partial-fail': { start: '2026-11-13', end: '2026-11-15' },
  'conflict-pending': { start: '2027-01-14', end: '2027-01-14' },
  'open-variant': { start: null, end: null },
}

const REASONS: { value: BlockReason; key: 'hotelCalendarReasonOffline' | 'hotelCalendarReasonMaintenance' | 'hotelCalendarReasonPrivate' | 'hotelCalendarReasonOther' }[] = [
  { value: 'offline_booking', key: 'hotelCalendarReasonOffline' },
  { value: 'maintenance', key: 'hotelCalendarReasonMaintenance' },
  { value: 'private_event', key: 'hotelCalendarReasonPrivate' },
  { value: 'other', key: 'hotelCalendarReasonOther' },
]

type Occasion = { id: string; name: { en: string; ar: string }; from: string; to: string; approximate?: boolean }
const OCCASIONS = (meta.occasions as Occasion[]).filter(o => o.id === 'ramadan-1448' || o.id.startsWith('eid'))
/** The fixture names an approximate date in words (`Ramadan 1448 (approx.)`); the chip carries the same fact as a tilde and keeps the name. */
const APPROX = /\s*[(（](approx\.|تقريبي)[)）]/

const ymOf = (iso: string): YearMonth => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })

export default function BlockDates({ state }: { state?: string }) {
  const f = useFormat()
  const nav = useNav<SheetParams>()
  const { t, c } = useWords()
  const bi = useBi()
  const live = useLive()
  const spanText = useSpanText()
  const dayMonth = useDayMonth()
  const reasonLabel = useReasonLabel()
  const short = useShortHall(HALLS)
  const p = nav.params
  const claims = useClaims()

  const [mode, setMode] = useState<Mode>(state === 'open-variant' ? 'open' : (p.mode ?? 'block'))
  const [range, setRange] = useState<DateSpan>(() => {
    if (state && FRAME_RANGE[state]) return FRAME_RANGE[state] as DateSpan
    if (!live) return { start: DEMO_RANGE.start, end: DEMO_RANGE.end }
    return { start: p.start ?? null, end: p.end ?? p.start ?? null }
  })
  const [scope, setScope] = useState<string>(state === 'conflict-pending' ? 'V01-danah' : p.hallIds && p.hallIds.length === 1 ? (p.hallIds[0] as string) : 'all')
  const [reason, setReason] = useState<BlockReason>('offline_booking')
  const [note, setNote] = useState('')
  const [expanded, setExpanded] = useState(state === 'edit-dates' || (live && !p.start && mode === 'block'))
  const [ym, setYm] = useState<YearMonth>(() => ymOf(range.start ?? TODAY))
  const [shortcut, setShortcut] = useState<string | null>(null)
  const [phase, setPhase] = useState<Phase>(state === 'loading' ? 'loading' : state === 'success' ? 'success' : state === 'partial-fail' ? 'partial' : 'idle')
  const [failed, setFailed] = useState(state === 'error')
  const offline = state === 'offline'
  const [unchecked, setUnchecked] = useState<string[]>([])
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const scopeIds = scope === 'all' ? HALLS.map(h => h.id) : [scope]
  const dates = useMemo(() => datesOfSpan(range.start, range.end), [range])
  const a = useMemo(() => analyse(dates, scopeIds, claims), [dates, scope, claims]) // eslint-disable-line react-hooks/exhaustive-deps
  const freeDates = useMemo(() => [...new Set(a.free.map(x => x.date))], [a])
  const blocked = useMemo(() => blockedIn(claims, scopeIds, dates), [claims, scope, dates]) // eslint-disable-line react-hooks/exhaustive-deps
  const blockedDates = useMemo(() => [...new Set(blocked.map(x => x.date))], [blocked])
  const chosen = blockedDates.filter(d => !unchecked.includes(d))
  const conflict = mode === 'block' && a.taken.length > 0
  const pendingTotal = a.pending.reduce((n, x) => n + x.count, 0)

  const count = mode === 'block' ? freeDates.length : chosen.length
  const needsNote = reason === 'other'

  // The reason a disabled primary rests: a caption of two or three words, never a sentence.
  let disabledReason: string | undefined
  if (offline) disabledReason = t('hotelCalendarOfflineNeed')
  else if (mode === 'block' && dates.length === 0) disabledReason = t('hotelCalendarReasonChoose')
  else if (conflict) disabledReason = t('hotelCalendarReasonConflict')
  else if (mode === 'block' && freeDates.length === 0) disabledReason = t('hotelCalendarAlreadyBlocked')
  else if (mode === 'open' && chosen.length === 0) disabledReason = t('hotelCalendarOpenEmpty')

  const close = () => nav.closeSheet()

  const submit = () => {
    if (disabledReason || phase !== 'idle') return
    if (!live) return
    setPhase('loading')
    later(() => {
      const store = useCal.getState()
      if (mode === 'block') store.commit(blockClaims(a.free, reason, needsNote ? note : ''), [])
      else store.commit([], blocked.filter(x => chosen.includes(x.date)).map(x => x.id))
      // Done: the sheet leaves at once and the calendar behind it already shows the change; the toast carries Undo for 8 s.
      nav.closeSheet()
      // (An untracked timer: this sheet unmounts when it closes.)
      window.setTimeout(
        () =>
          nav.toast({
            message: mode === 'block' ? t('hotelCalendarToastBlocked') : t('hotelCalendarToastOpened'),
            tone: 'success',
            icon: 'check-circle',
            undo: true,
            action: { label: c('commonActionUndo'), onPress: () => useCal.getState().undo() },
          }),
        250,
      )
    }, 480)
  }

  const pickShortcut = (id: string | null) => {
    setShortcut(id)
    const o = OCCASIONS.find(x => x.id === id)
    if (o) {
      setRange({ start: o.from, end: o.to })
      setYm(ymOf(o.from))
    }
  }

  const summary = range.start ? spanText(range.start, range.end) : mode === 'open' ? t('hotelCalendarOpenListTitle') : t('hotelCalendarRangeNone')
  const done = phase === 'success' || phase === 'partial'
  const titleKey = mode === 'block' ? 'hotelCalendarSheetBlockTitle' : 'hotelCalendarSheetOpenTitle'
  const dateChip = (iso: string) => <FactChip icon="calendar" label={t('hotelCalendarRangeSummary')} value={<Fx text={dayMonth(iso)} />} />

  const footer = done ? (
    <Button variant="secondary" size="cta" fullWidth onClick={close}>
      {c('commonActionDone')}
    </Button>
  ) : (
    <Button variant="primary" fullWidth loading={phase === 'loading'} disabled={Boolean(disabledReason)} reason={disabledReason} onClick={submit}>
      {mode === 'block' ? t('hotelCalendarCtaBlock', { count: conflict ? 0 : count }) : t('hotelCalendarCtaOpen', { count })}
    </Button>
  )

  // ---- the outcome: a drawing, the words of the toast, the dates (success), or what was skipped (partial)
  const result =
    phase === 'success' ? (
      <Outcome art={mode === 'block' ? 'partner-calendar' : 'doorway'} title={mode === 'block' ? t('hotelCalendarToastBlocked') : t('hotelCalendarToastOpened')}>
        <FactRow label={t('hotelCalendarRangeSummary')}>
          <FactChip icon="calendar" label={t('hotelCalendarRangeSummary')} value={<Fx text={mode === 'block' ? spanText(range.start, range.end) : f.list(chosen.map(d => f.date(d, 'short')))} />} />
        </FactRow>
      </Outcome>
    ) : phase === 'partial' ? (
      <>
        <Outcome art="calendar" title={t('hotelCalendarPartialTitle')}>
          <FactRow>
            <FactChip icon="lock" label={c('commonAvailabilityBlocked')} value={f.integer(freeDates.length)} />
            <FactChip icon="calendar-x" tone="accent" label={t('hotelCalendarPartialTitle')} value={f.integer(a.taken.length)} />
          </FactRow>
        </Outcome>
        <ul className="cal-s__list">
          {a.taken.map(x => (
            <li key={x.id} className="cal-s__skip">
              <FactRow>
                {dateChip(x.date)}
                <FactChip icon="hall" label={t('hotelCalendarHallFact')} value={short(x.hallId)} />
              </FactRow>
              <StatusPill status="booked" />
            </li>
          ))}
        </ul>
      </>
    ) : null

  const modeSwitch = (
    <IconSegmented<Mode>
      label={t('hotelCalendarModeLabel')}
      value={mode}
      labels="all"
      onChange={m => {
        setMode(m)
        setUnchecked([])
      }}
      options={[
        { value: 'block', icon: 'lock', label: t('hotelCalendarModeBlock') },
        { value: 'open', icon: 'door', label: t('hotelCalendarModeOpen') },
      ]}
    />
  )

  const info = (
    <InfoButton title={c('commonLabelDetails')}>
      <p>{mode === 'block' ? t('hotelCalendarVisibilityHint') : t('hotelCalendarOpenHint')}</p>
      {expanded ? (
        <>
          <p>{t('hotelCalendarHintDrag')}</p>
          <p>{t('hotelCalendarHintTap')}</p>
        </>
      ) : null}
    </InfoButton>
  )

  return (
    <SheetFrame title={t(titleKey)} lead={done ? undefined : modeSwitch} info={done ? undefined : info} footer={footer} onClose={close}>
      {offline ? <Notice tone="offline">{c('commonStateOffline')}</Notice> : null}
      {failed ? (
        <Notice tone="danger" action={{ label: c('commonActionRetry'), onPress: () => setFailed(false) }}>
          {t('hotelCalendarSaveFailed')}
        </Notice>
      ) : null}

      {result ?? (
        <>
          <button type="button" className="gz-reset cal-s__sum gz-press" aria-expanded={expanded} aria-label={`${summary}, ${t('hotelCalendarSumEdit')}`} onClick={() => setExpanded(e => !e)}>
            <Icon name="calendar" size="md" />
            <span className="cal-s__sumline gz-t-body">
              <Fx text={summary} />
            </span>
            {mode === 'open' && !range.start ? (
              <span className="cal-s__sumn gz-t-fig-body-s">
                <Fig>{f.integer(blockedDates.length)}</Fig>
              </span>
            ) : null}
            <Icon name={expanded ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
          </button>

          {mode === 'block' && a.pending.length > 0 ? (
            <Notice
              tone="warning"
              icon={null}
              lead={<ThreadBead tone="gold" />}
              head={
                <>
                  <span>{t('hotelCalendarRequestedLabel')}</span>
                  <span className="gz-t-fig-body-s">
                    <Fig>{f.integer(pendingTotal)}</Fig>
                  </span>
                </>
              }
              info={
                <InfoButton title={t('hotelCalendarRequestedLabel')}>
                  {a.pending.map(x => (
                    <p key={x.date}>
                      <Fx text={t('hotelCalendarPendingWarn', { count: x.count, date: f.date(x.date, 'short') })} />
                    </p>
                  ))}
                </InfoButton>
              }
            >
              <FactRow>{a.pending.slice(0, 3).map(x => <span key={x.date}>{dateChip(x.date)}</span>)}</FactRow>
            </Notice>
          ) : null}

          {conflict ? (
            <Notice
              tone="danger"
              head={<StatusPill status="booked" />}
              info={
                <InfoButton title={t('hotelCalendarWhyTitle')}>
                  <p>{t('hotelCalendarConflictBody')}</p>
                  {scope === 'all' && HALLS.length > 1 ? <p>{t('hotelCalendarConflictTip')}</p> : null}
                </InfoButton>
              }
              action={{
                label: t('hotelCalendarConflictCancel'),
                onPress: () => {
                  const id = a.taken.find(x => x.bookingId)?.bookingId
                  if (id) nav.openSheet('HL-DCSN-04', { params: { bookingId: id } })
                },
              }}
            >
              <ul className="cal-s__taken">
                {a.taken.slice(0, 3).map(x => (
                  <li key={x.id} className="cal-s__takenrow">
                    <FactRow>
                      {dateChip(x.date)}
                      <FactChip icon="hall" label={t('hotelCalendarHallFact')} value={short(x.hallId)} />
                      {x.clientName ? <UserText>{x.clientName}</UserText> : null}
                    </FactRow>
                  </li>
                ))}
              </ul>
            </Notice>
          ) : null}

          {expanded ? (
            <div className="cal-s__picker">
              <HotelMonthGrid
                halls={HALLS}
                claims={claims}
                month={ym}
                onMonthChange={setYm}
                mode="select"
                range={range}
                onRangeChange={r => {
                  setRange(r)
                  setShortcut(null)
                }}
                legend={false}
                label={t('hotelCalendarRangeSummary')}
              />
              <ChipRow icon="sparkle">
                <ChipGroup<string>
                  label={t('hotelCalendarShortcuts')}
                  layout="wrap"
                  value={shortcut}
                  deselectable
                  onChange={pickShortcut}
                  options={OCCASIONS.map(o => ({ value: o.id, label: `${o.approximate ? '≈ ' : ''}${bi(o.name).replace(APPROX, '')}` }))}
                />
              </ChipRow>
            </div>
          ) : null}

          {HALLS.length > 1 ? (
            <ChipRow icon="hall">
              <ChipGroup<string>
                label={t('hotelCalendarHallsLabel')}
                layout="wrap"
                value={scope}
                onChange={v => v && setScope(v)}
                options={[{ value: 'all', label: t('hotelCalendarHallsAll') }, ...HALLS.map(h => ({ value: h.id, label: short(h.id) }))]}
              />
            </ChipRow>
          ) : null}

          {scope !== 'all' && (HALLS.find(h => h.id === scope)?.sessions.length ?? 0) > 1 ? (
            <ChipRow icon="sun">
              <ChipGroup<string>
                label={t('hotelCalendarSession')}
                layout="wrap"
                defaultValue={HALLS.find(h => h.id === scope)?.sessions[0]?.id ?? null}
                options={(HALLS.find(h => h.id === scope)?.sessions ?? []).map(s => ({ value: s.id, label: bi(s.name) }))}
              />
            </ChipRow>
          ) : null}

          {mode === 'block' ? (
            <>
              <ChipRow icon="notes">
                <ChipGroup<BlockReason> label={t('hotelCalendarReason')} layout="wrap" value={reason} onChange={v => v && setReason(v)} options={REASONS.map(r => ({ value: r.value, label: t(r.key) }))} />
              </ChipRow>
              {needsNote ? <TextField label={t('hotelCalendarNote')} value={note} onValueChange={setNote} maxLength={80} /> : null}
            </>
          ) : blockedDates.length === 0 ? (
            <Outcome art="partner-calendar" title={t('hotelCalendarOpenEmpty')} />
          ) : (
            <ul className="cal-s__list" aria-label={t('hotelCalendarOpenListTitle')}>
              {blockedDates.map(d => {
                const rows = blocked.filter(x => x.date === d)
                const first = rows[0]
                return (
                  <li key={d} className="cal-s__item">
                    <Checkbox checked={!unchecked.includes(d)} onChange={on => setUnchecked(u => (on ? u.filter(x => x !== d) : [...u, d]))}>
                      <span className="cal-s__itext">
                        <span className="gz-t-body cal-s__idate">
                          <Fx text={f.date(d, 'short')} />
                        </span>
                        <FactRow>
                          <FactChip size="sm" icon="lock" label={t('hotelCalendarReason')} value={reasonLabel(first?.blockReason ?? null)} />
                          {rows.length < HALLS.length ? <FactChip size="sm" icon="hall" label={t('hotelCalendarHallFact')} value={rows.map(x => short(x.hallId)).join(' · ')} /> : null}
                        </FactRow>
                      </span>
                    </Checkbox>
                  </li>
                )
              })}
            </ul>
          )}
        </>
      )}
    </SheetFrame>
  )
}
