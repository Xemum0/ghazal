// CL-VENU-03 Dates and prices (sheet). Covers CA-VDET-22, CA-BOOK-01, CA-BOOK-02, CA-BOOK-14, CA-CARD-08, CA-CMP-08.
// The live availability calendar of one hall with an availability | prices switch. Day states are told by shape, never by colour alone
// (the system Calendar owns them); under the grid a focus card says what the chosen day is and what it costs in both columns (the
// voucher price and the standard price, ADR 0033) and, for a day that is not free, offers the nearest free dates and similar halls
// instead of a dead end. The Prices view shows the lowest voucher total of each day (the standard total when the venue has no voucher
// price). Also opened from booking step 1 (the date is written to the draft), from Compare ("See dates") and from the reschedule flow.
// Text diet (ADR 0034): the switch is two glyphs with one word on the chosen one, the jump to a month is a calendar glyph, the focus card is
// a date, a pill and the price glyphs; no legend sentence, no reason line, no hint. Navigates to CL-BOOK-01, CL-VENU-01, CL-VCHR-01.
import { useEffect, useMemo, useRef, useState } from 'react'
import * as mock from '../../../mock'
import { engine } from '../../../mock'
import type { AvailabilityDay, Audience, Hall, IsoDate, Venue } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useDevice } from '../../../shell/device/context'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  Banner, Button, Calendar, Chip, ErrorState, FactChip, Figures, Icon, IconButton, IconListRow, IconSegmented, Price, Skeleton, StatusPill, VenueCard, useBi, useNav,
  type CalendarDayInfo, type CalendarView,
} from '../../../system'
import { SheetFrame } from './_components/SheetFrame'
import { Mixed } from './_components/Mixed'
import { PriceBlock } from './_components/PriceBlock'
import { sessionIcon } from './_components/glyphs'
import { useDayMonth, useGuestsText, useMonthYear, useShortDay } from './_components/fmt'
import { brief4, defaultPackage, VOUCHER_FEE_FILS, fittingHalls, packageRows, quoteOf, quotePrices, similarVenues, staleStamp, useVenueBrief, useVenueId } from './_components/model'
import { useVenueActions } from './_components/useActions'
import { useOwnedVoucher, usePageFlags } from './_components/usePage'
import './CL-VENU-03.css'

export const states = ['loading', 'error', 'offline-stale', 'no-availability-this-month', 'prices-view', 'guests-missing', 'date-held', 'date-unavailable']

type Params = { venueId?: string; hallId?: string; date?: string; guests?: number; source?: string; mode?: string; bookingId?: string }
type Ym = { year: number; month: number }

const ymOf = (iso: string): Ym => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
const keyOfYm = (m: Ym): string => `${m.year}-${String(m.month).padStart(2, '0')}`

export default function DatesAndPrices() {
  const t = useT('client-venue')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const guestsText = useGuestsText()
  const monthYear = useMonthYear()
  const shortDay = useShortDay()
  const dayMonth = useDayMonth()
  const stateVenueId = useVenueId()
  const booking = nav.params.bookingId ? mock.getBooking(String(nav.params.bookingId)) : undefined
  const venue: Venue | undefined = mock.getVenue(booking?.venueId ?? stateVenueId)
  const baseBrief = useVenueBrief(venue)
  const section = booking?.sections[0]
  const brief = useMemo(
    () => ({ ...baseBrief, date: booking ? booking.eventDate : baseBrief.date, guests: booking ? (section?.guests ?? baseBrief.guests) : baseBrief.guests, audience: (section?.audience ?? baseBrief.audience) as Audience }),
    [baseBrief, booking, section],
  )
  const live = useDevice().mode === 'live'
  const flags = usePageFlags()
  const actions = useVenueActions(venue, live)
  const owned = useOwnedVoucher(venue?.id, live)

  const halls = useMemo(() => (venue ? fittingHalls(venue, brief.audience, brief.guests) : []), [venue, brief.audience, brief.guests])
  const hall: Hall | undefined = halls.find(h => h.id === (nav.params.hallId ?? section?.hallId)) ?? halls[0]

  const days = useMemo(() => (venue && hall ? mock.availabilityYear(venue.id, hall.id, brief4(brief)) : []), [venue, hall, brief])
  const byDate = useMemo(() => new Map<IsoDate, AvailabilityDay>(days.map(d => [d.date, d])), [days])

  const initialFocus: IsoDate | null = state === 'no-availability-this-month' ? null : brief.date
  const [focus, setFocus] = useState<IsoDate | null>(initialFocus)
  const [month, setMonth] = useState<Ym>(state === 'no-availability-this-month' ? { year: 2027, month: 7 } : ymOf(initialFocus ?? mock.clock.today()))
  const [view, setView] = useState<CalendarView>(state === 'prices-view' ? 'prices' : 'availability')
  // The summary of the chosen date sits under the grid in the scrolling body; a new pick brings it into view (the pinned bar keeps only the action).
  const summaryRef = useRef<HTMLDivElement>(null)
  const picked = useRef(false)
  useEffect(() => {
    if (!picked.current) return
    picked.current = false
    summaryRef.current?.scrollIntoView?.({ block: 'nearest', behavior: 'smooth' })
  }, [focus])

  if (state === 'error') {
    return (
      <SheetFrame title={t('clientVenueCalTitle')}>
        <ErrorState kind="load" fill={false} />
      </SheetFrame>
    )
  }
  if (!venue || !hall) return null
  if (state === 'loading') {
    return (
      <SheetFrame title={t('clientVenueCalTitle')}>
        <div className="gzv-cal__skeleton" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <Skeleton blockSize={44} />
          <Skeleton blockSize={40} />
          <Skeleton blockSize={280} />
        </div>
      </SheetFrame>
    )
  }

  const guestsKnown = brief.guests !== null
  const info: Record<string, CalendarDayInfo> = {}
  for (const d of days) {
    const status = d.state === 'available' ? 'available' : d.state === 'held' ? 'held' : d.state === 'closed' ? 'closed' : 'booked'
    // The Prices view shows what the visitor would pay at the venue: the voucher total when the voucher is worth its fee, else the standard total.
    const shown = d.voucherPrice ?? d.fromPrice
    info[d.date] = { status, price: guestsKnown && (status === 'available' || status === 'held') && shown ? shown.fils : undefined }
  }

  const { minDate, maxDate } = { minDate: mock.meta.availabilityWindow.from, maxDate: mock.meta.availabilityWindow.to }
  const freeIn = (key: string) => days.filter(d => d.state === 'available' && d.date.startsWith(key)).length
  const monthKeyNow = keyOfYm(month)
  const noneThisMonth = freeIn(monthKeyNow) === 0 && days.every(d => !(d.date.startsWith(monthKeyNow) && d.state === 'held'))
  const nextWithDates = (() => {
    const keys = [...new Set(days.map(d => d.date.slice(0, 7)))].sort()
    return keys.find(k => k > monthKeyNow && freeIn(k) > 0) ?? keys.find(k => freeIn(k) > 0)
  })()

  const focusDay = focus ? byDate.get(focus) : undefined
  const focusState = focusDay?.state
  const rowsOnFocus = focus ? packageRows(venue, hall, brief.audience, focus, brief.guests) : []
  const pkgRow = defaultPackage(rowsOnFocus, brief.audience)
  const quote = focus && guestsKnown ? quoteOf(venue, hall, pkgRow, focus, brief.guests) : null
  const prices = quotePrices(quote, pkgRow, brief.guests)
  const nearest = focus && focusState && focusState !== 'available' && focusState !== 'held'
    ? days.filter(d => d.state === 'available' && d.date !== focus).sort((a, b) => Math.abs(engine.diffDays(focus, a.date)) - Math.abs(engine.diffDays(focus, b.date))).slice(0, 3).map(d => d.date).sort()
    : []
  const similar = focus && focusState && focusState !== 'available' && focusState !== 'held' ? similarVenues(venue, { ...brief, date: focus }, 3) : []

  const occasions = mock.meta.occasions.filter(o => o.to >= `${monthKeyNow}-01` && o.from <= `${monthKeyNow}-31`)

  const goTo = (iso: IsoDate) => {
    setFocus(iso)
    setMonth(ymOf(iso))
  }
  const onPick = (iso: string | null) => {
    if (!iso) return
    picked.current = true
    setFocus(iso)
    if (live && !booking && nav.params.source !== 'booking') usePrototype.getState().setBrief({ date: iso, dateMode: 'exact' })
  }

  const openJump = () => {
    const keys = [...new Set(days.map(d => d.date.slice(0, 7)))].sort()
    nav.openSheet(
      <ul className="gzv-jump" data-gz-id="calendar.jump">
        {keys.map((k, i) => {
          const n = freeIn(k)
          return (
            <li key={k}>
              <IconListRow
                flush
                last={i === keys.length - 1}
                selected={k === monthKeyNow}
                onClick={() => {
                  setMonth(ymOf(`${k}-01`))
                  nav.closeSheet()
                }}
                title={monthYear(k)}
                trailing={<FactChip icon="calendar-check" value={f.integer(n)} label={t('clientVenueCalMonthDensity', { month: monthYear(k), count: n })} />}
              />
            </li>
          )
        })}
      </ul>,
      { title: t('clientVenueCalMonthTitle') },
    )
  }

  // ---- the footer action by where the sheet was opened from (ADR 0033): Get voucher, Send request with a ready voucher, or just use the date
  const source = nav.params.source === 'booking' ? 'booking' : booking ? 'reschedule' : 'venue'
  const canContinue = Boolean(focus && (focusState === 'available' || focusState === 'held'))
  const voucherHere = source === 'venue' && Boolean(prices?.eligible)
  const carry = { brief: { ...brief, date: focus }, hallId: hall.id, packageId: pkgRow?.pkg.id ?? null, date: focus }
  const onContinue = () => {
    if (!focus || !canContinue) return
    const store = usePrototype.getState()
    if (source === 'booking') {
      if (live) store.patchDraft({ eventDate: focus })
      nav.closeSheet()
      return
    }
    if (source === 'reschedule') {
      nav.closeSheet()
      nav.toast({ message: t('clientVenueCalChosen', { date: dayMonth(focus) }), tone: 'success' })
      return
    }
    if (live) store.setBrief({ date: focus, dateMode: 'exact' })
    nav.closeSheet()
    if (!voucherHere) return
    if (owned) actions.sendRequest(carry, owned)
    else actions.getVoucher(carry)
  }
  const continueLabel = voucherHere ? (owned ? t('clientVenueCtaSendRequest') : t('clientVenueCtaGetVoucher')) : t('clientVenueCalUse')

  const dateParts = focus ? f.dateWithHijri(focus) : null
  const summary = focus && dateParts ? (
    <div className="gzv-cal__sum" data-gz-id="calendar.focus" aria-live="polite">
      <div className="gzv-cal__sum-head">
        <div className="gzv-cal__sum-date">
          <p className="gzv-cal__sum-title gz-t-title">
            <Figures text={shortDay(focus)} />
          </p>
          {dateParts.secondary ? (
            <p className="gz-t-caption gzv-cal__muted">
              <Figures text={dateParts.secondary} />
            </p>
          ) : null}
        </div>
        {focusState === 'available' ? <StatusPill status="available" /> : focusState === 'held' ? <StatusPill status="held" /> : focusState ? <StatusPill status="unavailable" /> : null}
      </div>
      {focusState === 'held' ? (
        <span className="gz-sr-only" data-gz-id="calendar.held">
          {t('clientVenueHeldSr')}
        </span>
      ) : null}
      {(focusState === 'available' || focusState === 'held') && prices && pkgRow ? (
        <div className="gzv-cal__money" data-gz-id="calendar.money">
          <PriceBlock prices={prices} owned={Boolean(owned)} size="total" />
        </div>
      ) : null}
      {focusState && focusState !== 'available' && focusState !== 'held' && nearest.length > 0 ? (
        <ul className="gzv-cal__chips" data-gz-id="calendar.nearest" aria-label={t('clientVenueNearestTitle')}>
          {nearest.map(d => (
            <li key={d}>
              <Chip iconStart="calendar" onClick={() => goTo(d)}>
                <Figures text={shortDay(d)} />
              </Chip>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  ) : null

  const altBlock =
    focus && focusState && focusState !== 'available' && focusState !== 'held' && similar.length > 0 ? (
      <div className="gzv-cal__alt" data-gz-id="calendar.reason">
        <ul className="gzv-cal__similar" aria-label={t('clientVenueSimilarTitle')}>
          {similar.map(r => (
            <li key={r.venue.id}>
              <VenueCard
                variant="compact"
                venue={r.venue}
                price={r.price}
                onOpen={() => {
                  nav.closeSheet()
                  nav.push('CL-VENU-01', { venueId: r.venue.id, from: 'calendar' })
                }}
              />
            </li>
          ))}
        </ul>
      </div>
    ) : null

  const sessions = !hall.exclusiveDay && hall.sessions.length > 1 ? hall.sessions : []
  const fee = VOUCHER_FEE_FILS
  const showDisabledWhy = !canContinue ? (focus ? t('clientVenueCalPickFree') : t('clientVenueCalPickHint')) : null

  return (
    <SheetFrame
      title={t('clientVenueCalTitle')}
      footer={
        focus && focusState && !canContinue && nearest.length > 0 ? null : (
          <div className="gzv-cal__foot">
            {voucherHere && !owned ? (
              <span className="gzv-cal__fee">
                <Icon name="ticket" size="sm" tone="secondary" />
                <span className="gz-sr-only">{tc('commonVoucher')}</span>
                <Price fils={fee} size="display" />
              </span>
            ) : null}
            <div className="gzv-cal__cta">
              <Button variant="primary" fullWidth disabled={!canContinue} onClick={onContinue} iconEnd={voucherHere ? (owned ? 'send' : 'ticket') : undefined}>
                {continueLabel}
              </Button>
              {showDisabledWhy ? <span className="gz-sr-only">{showDisabledWhy}</span> : null}
            </div>
          </div>
        )
      }
    >
      {state === 'offline-stale' ? <Banner tone="offline" shape="card">{t('clientVenueOfflineBanner', { time: f.plain(f.time(staleStamp())) })}</Banner> : null}

      {!guestsKnown ? (
        <div className="gzv-cal__guests" data-gz-id="calendar.guests">
          <Button variant="secondary" iconStart="users-three" fullWidth onClick={() => nav.openSheet('CL-DISC-02', { params: { focus: 'guests' } })}>
            {t('clientVenueCalGuestsCta')}
          </Button>
        </div>
      ) : null}

      <div className="gzv-cal__tools">
        {guestsKnown ? (
          <div className="gzv-cal__switch">
            <IconSegmented
              label={`${tc('commonCalendarAvailability')} / ${tc('commonCalendarPrices')}`}
              value={view}
              onChange={setView}
              options={[
                { value: 'availability', icon: 'calendar', label: tc('commonCalendarAvailability') },
                { value: 'prices', icon: 'coins', label: tc('commonCalendarPrices') },
              ]}
            />
          </div>
        ) : (
          <span />
        )}
        <IconButton icon="calendar-dots" label={t('clientVenueCalMonthJump')} onClick={openJump} variant="outline" />
      </div>

      {noneThisMonth ? (
        <div className="gzv-cal__none" data-gz-id="calendar.none">
          <IconListRow
            flush
            last
            illustration="empty-bookings"
            title={t('clientVenueCalNone')}
            trailing={
              nextWithDates ? (
                <Button variant="tertiary" iconEnd="chevron-right" onClick={() => setMonth(ymOf(`${nextWithDates}-01`))}>
                  {monthYear(nextWithDates)}
                </Button>
              ) : undefined
            }
          />
        </div>
      ) : null}

      <Calendar
        mode="single"
        label={t('clientVenueCalTitle')}
        days={info}
        value={focus}
        onChange={onPick}
        month={month}
        onMonthChange={setMonth}
        view={view}
        onViewChange={setView}
        showViewToggle={false}
        legend={false}
        minDate={minDate}
        maxDate={maxDate}
        isSelectable={(_iso, status) => status === 'available' || status === 'held' || status === 'booked'}
        priceBasis={
          guestsKnown ? (
            <span className="gzv-cal__basis">
              <Icon name="coins" size="xs" tone="secondary" />
              <span>{f.moneyParts(0).currency}</span>
              <FactChip icon="users-three" value={f.integer(brief.guests ?? 0)} label={t('clientVenueCalBasis', { guests: guestsText(brief.guests ?? 0) })} size="sm" tone="muted" />
            </span>
          ) : undefined
        }
      />

      {occasions.length > 0 ? (
        <ul className="gzv-cal__occasions" aria-label={t('clientVenueCalOccasionsLabel')}>
          {occasions.map(o => {
            const name = bi(o.name)
            const from = dayMonth(o.from)
            const to = dayMonth(o.to)
            return (
              <li key={o.id} className="gzv-cal__occasion gz-t-caption">
                <Icon name="sparkle" size="xs" tone="accent" />
                <Figures text={o.from === o.to ? `${name} ${from}` : `${name} ${from}–${to}`} />
              </li>
            )
          })}
        </ul>
      ) : null}

      <div ref={summaryRef}>{summary}</div>
      {altBlock}
      {sessions.length > 0 && focus && (focusState === 'available' || focusState === 'held') ? (
        <ul className="gzv-cal__sessions">
          {sessions.map(s => (
            <li key={s.id}>
              <FactChip
                icon={sessionIcon(s.start)}
                label={bi(s.name)}
                value={<Mixed text={f.plain(f.timeRange(engine.at(focus, s.start), engine.at(s.end <= s.start ? engine.addDays(focus, 1) : focus, s.end)))} />}
              />
            </li>
          ))}
        </ul>
      ) : null}
    </SheetFrame>
  )
}
