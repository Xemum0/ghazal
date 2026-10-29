// CL-BOOK-07 That date is no longer available (sheet). Covers CA-BOOK-16, CA-VDET-22, CA-VCH-11.
// Text diet (ADR 0034): recovery in drawings, glyphs and figures. A calendar drawing, the outcome in two words (date taken, session taken,
// window ended), the date as a fact and the voucher as a ticket with a check (still valid: the words are its accessible name); then the nearest
// free dates of the same hall (a date and its voucher price: tap = the voucher moves to that date while its saving still passes), similar halls
// free on the same date (photo, name, price), a new date from the calendar, or back to the results. Calm, blameless, never a dead end.
// params: reason (date_taken | session_taken | confirm_window_ended), venueId, date, from (the screen that opened it).
// Navigates to CL-BOOK-01, CL-VENU-03, CL-VENU-01, CL-DISC-03.
import { BarButton, Button, FactChip, FactRow, Figures, Icon, IconListRow, Illustration, InfoButton, ListRow, Photo, Price, Skeleton, imageSrc, useBi, useNav } from '../../../system'
import { Auto, useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import * as mock from '../../../mock'
import { nearestFreeDates, rebindVoucherDate, similarHalls, type AltPrice } from './_components/alternatives'
import { sessionGlyph } from './_components/glyphs'
import { goStep, leaveFlow, useFlow, useLive } from './_components/flow'
import './_components/taken.css'

export const states = ['loading-alternatives', 'no-alternatives', 'session-taken', 'confirm-window-ended']

type Reason = 'date_taken' | 'session_taken' | 'confirm_window_ended'
type Params = { reason?: Reason; venueId?: string; date?: string; from?: string }

const FROM_STATE: Record<string, Reason> = { 'session-taken': 'session_taken', 'confirm-window-ended': 'confirm_window_ended' }

export default function DateTaken() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const live = useLive()
  const { state } = useFrame()
  const flow = useFlow(undefined)
  const patchDraft = usePrototype(s => s.patchDraft)
  const setBrief = usePrototype(s => s.setBrief)
  const areaIds = usePrototype(s => s.searchBrief.areaIds)

  const venue = nav.params.venueId ? mock.requireVenue(nav.params.venueId) : flow.venue
  const date = nav.params.date ?? flow.date
  const reason: Reason = (state && FROM_STATE[state]) || nav.params.reason || 'date_taken'
  const first = flow.sections[0]!
  const hall = venue.id === flow.venue.id ? first.hall : venue.halls[0]!
  const guests = flow.guests
  const audience = flow.audience
  const loading = state === 'loading-alternatives'
  const none = state === 'no-alternatives'

  const dates = loading || none ? [] : nearestFreeDates(venue.id, hall.id, date, guests, audience)
  const halls = loading || none ? [] : similarHalls(venue.id, date, guests, audience, areaIds ?? [])

  const session = first.sessions.find(s => s.id === first.sessionId) ?? first.sessions[0]
  const title = t(reason === 'confirm_window_ended' ? 'clientBookingTakenExpiredTitle' : reason === 'session_taken' ? 'clientBookingTakenSessionTitle' : 'clientBookingTakenTitle')
  // One drawing per sheet: the calendar (or the hourglass of a lapsed window); with no free date nearby it is the empty magnifier instead.
  const art = none ? 'no-result' : reason === 'confirm_window_ended' ? 'hourglass' : 'calendar'

  // The nearest dates share the year of the one that was lost: weekday, day and month are enough (the year joins only across a new year).
  const dayLabel = (iso: string) => {
    const c = f.civil(iso)
    const year = c.year === f.civil(date).year ? '' : ` ${f.integer(c.year)}`
    return `${f.weekdayName(c.weekday, 'short')} ${f.integer(c.day)} ${f.monthName(c.month, 'short')}${year}`
  }
  const priceOf = (p: AltPrice) => <Price fils={(p.voucher ?? p.standard).fils} size="strong" />

  const pickDate = (picked: string) => {
    const from = nav.params.from
    const voucher = flow.voucher
    if (live && voucher) {
      // The voucher is bound to its quote: it moves to the new date only while the saving still beats the voucher fee.
      if (!rebindVoucherDate(voucher, picked, audience)) {
        nav.toast({ message: t('clientBookingTakenRebindFailed'), tone: 'neutral' })
        return
      }
      nav.closeSheet()
      nav.toast({ message: t('clientBookingTakenRebound', { date: f.date(picked, 'short') }), tone: 'success' })
      if (from === 'CL-BOOK-05') goStep(nav, 4, 1)
      else if (from !== 'CL-BOOK-01') nav.push('CL-BOOK-01', { venueId: venue.id, voucherId: voucher.id, date: picked, fresh: true })
      return
    }
    if (live) patchDraft({ venueId: venue.id, eventDate: picked })
    nav.closeSheet()
    if (from === 'CL-BOOK-05') goStep(nav, 4, 1)
    else if (from !== 'CL-BOOK-01') nav.push('CL-BOOK-01', { venueId: venue.id, date: picked })
  }
  const openCalendar = () => {
    nav.closeSheet()
    nav.openSheet('CL-VENU-03', { params: { source: 'booking', venueId: venue.id, hallId: hall.id, date, guests } })
  }
  const openHall = (venueId: string) => {
    setBrief({ date, guests, audience })
    nav.closeSheet()
    leaveFlow(nav, 'discover', { id: 'CL-VENU-01', params: { venueId } })
  }
  const results = () => {
    nav.closeSheet()
    leaveFlow(nav, 'discover', { id: 'CL-DISC-03' })
  }

  return (
    <div className="bk-taken" data-gz="DateTakenSheet" data-reason={reason}>
      <div className="bk-taken__head">
        <Illustration name={art} size="md" />
        <div className="bk-taken__who">
          <h2 className="bk-taken__title gz-t-d1">{title}</h2>
          <FactRow>
            <FactChip icon={reason === 'confirm_window_ended' ? 'calendar' : 'calendar-x'} label={t('clientBookingSentDate')} value={f.date(date, 'compact')} tone="muted" />
            {reason === 'session_taken' && session ? <FactChip icon={sessionGlyph(session.start)} label={bi(session.name)} tone="muted" /> : null}
            <FactChip icon="users-three" label={t('clientBookingGuestsLabel')} value={f.integer(guests)} tone="muted" />
            <span data-gz-id="taken.voucher">
              <FactChip icon="ticket" label={t('clientBookingTakenVoucherValid')} value={<Icon name="check" size="xs" tone="success" />} tone="accent" />
            </span>
          </FactRow>
        </div>
        <span className="bk-taken__close">
          <BarButton icon="close" label={tc('commonActionClose')} onPress={() => nav.closeSheet()} />
        </span>
      </div>
      {loading ? (
        <div className="bk-taken__block" aria-busy="true" aria-label={t('clientBookingTakenLoading')}>
          {[0, 1, 2].map(i => (
            <div key={i} className="bk-taken__skel">
              <Skeleton inlineSize={160} blockSize={24} />
              <Skeleton inlineSize={96} blockSize={20} />
            </div>
          ))}
        </div>
      ) : none ? (
        <div className="bk-taken__none">
          <span className="gz-t-title">{t('clientBookingTakenNone')}</span>
          <InfoButton title={t('clientBookingTakenNone')}>
            <p>
              <Figures text={t('clientBookingTakenNoneInfo', { date: f.date(date, 'short') })} />
            </p>
          </InfoButton>
        </div>
      ) : (
        <>
          {dates.length ? (
            <section className="bk-taken__block" aria-label={t('clientBookingTakenNearest')}>
              <div>
                {dates.map((d, i) => (
                  <IconListRow
                    key={d.date}
                    flush
                    last={i === dates.length - 1}
                    icon="calendar-check"
                    title={<Figures text={dayLabel(d.date)} />}
                    trailing={priceOf(d.price)}
                    chevron
                    onClick={() => pickDate(d.date)}
                  />
                ))}
              </div>
            </section>
          ) : null}
          {halls.length ? (
            <section className="bk-taken__block" aria-label={t('clientBookingTakenSimilar', { date: f.date(date, 'short') })}>
              {/* The group has no title: a calendar check and the date say "other halls, free on this day" (the words are the accessible name; same fact as CL-BOOK-10). */}
              <FactRow>
                <FactChip icon="calendar-check" label={t('clientBookingTakenSimilar', { date: '' })} value={f.date(date, 'compact')} tone="muted" />
              </FactRow>
              <div>
                {halls.map((h, i) => (
                  <ListRow
                    key={h.venue.id}
                    flush
                    last={i === halls.length - 1}
                    chevron
                    autoDir
                    leading={<span className="bk-taken__thumb">{h.venue.cover ? <Photo src={imageSrc(h.venue.cover.file)} alt="" sizes="64px" /> : null}</span>}
                    title={<Auto>{bi(h.venue.name)}</Auto>}
                    trailing={priceOf(h.price)}
                    onClick={() => openHall(h.venue.id)}
                  />
                ))}
              </div>
            </section>
          ) : null}
        </>
      )}

      <div className="bk-taken__actions">
        <Button variant="secondary" fullWidth iconStart="calendar" onClick={openCalendar}>
          {t('clientBookingTakenAnother')}
        </Button>
        <Button variant="tertiary" onClick={results}>
          {t('clientBookingTakenResults')}
        </Button>
      </div>
    </div>
  )
}
