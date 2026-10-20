// SearchView: what replaces the list while the header search is open (HL-BOOK-02 "search-active", "no-results"). An empty field lists the
// recent searches (or a quiet drawing when there are none; the placeholder already says what can be typed); a query lists matches grouped by
// where they live (Pending, Upcoming, Past) with the matched text in weight 700; no match names what was searched and offers the way out.
// Matching is in either script (ADR 0012 D8).
import { useMemo } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { Button, EmptyState, Icon, Illustration, SectionHeader } from '../../../../system'
import { BookingRow } from './BookingRow'
import { useBookingActions } from './actions'
import { matchBooking, moneyMode, segmentOf, type Segment } from './model'
import type { Booking } from '../../../../mock'
import './search-view.css'

export type SearchViewProps = {
  query: string
  bookings: Booking[]
  recents: string[]
  onPickRecent: (q: string) => void
  onClearRecents: () => void
  onClear: () => void
  onOpened: (q: string) => void
}

const ORDER: Segment[] = ['pending', 'upcoming', 'past']

export function SearchView({ query, bookings, recents, onPickRecent, onClearRecents, onClear, onOpened }: SearchViewProps) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const f = useFormat()
  const act = useBookingActions()
  const q = query.trim()
  const hits = useMemo(() => (q ? bookings.filter(b => matchBooking(f, b, q)) : []), [bookings, f, q])
  const mode = moneyMode(hits.map(b => b.totals.voucherTotal.fils))

  if (!q) {
    return (
      <div className="hbk-search">
        {recents.length > 0 ? (
          <section className="hbk-search__recents" aria-label={t('hotelBookingsRecentTitle')}>
            <div className="hbk-search__recents-head">
              <span className="gz-t-label">{t('hotelBookingsRecentTitle')}</span>
              <Button variant="tertiary" onClick={onClearRecents}>
                {c('commonActionClear')}
              </Button>
            </div>
            <ul className="hbk-search__list">
              {recents.map(r => (
                <li key={r}>
                  <button type="button" className="gz-reset hbk-search__recent gz-t-body gz-press" onClick={() => onPickRecent(r)}>
                    <Icon name="clock" size="sm" tone="secondary" />
                    <bdi dir="auto" className="hbk-search__recent-text">
                      {r}
                    </bdi>
                  </button>
                </li>
              ))}
            </ul>
          </section>
        ) : (
          <div className="hbk-search__idle">
            <Illustration name="empty-results" size="lg" />
          </div>
        )}
      </div>
    )
  }

  if (hits.length === 0) {
    return (
      <div className="hbk-search hbk-search--none">
        <EmptyState
          fill={false}
          illustration="no-result"
          title={t('hotelBookingsNoResultsTitle', { query: `⁦${q.replace(/-/g, '-⁠').replace(/\s/g, ' ')}⁩` })}
          action={{ label: c('commonActionClear'), onPress: onClear }}
        />
      </div>
    )
  }

  return (
    <div className="hbk-search">
      {ORDER.map(seg => {
        const list = hits.filter(b => segmentOf(b) === seg)
        if (list.length === 0) return null
        const title = seg === 'pending' ? t('hotelBookingsSegPending') : seg === 'upcoming' ? t('hotelBookingsSegUpcoming') : t('hotelBookingsSegPast')
        return (
          <section key={seg} className="hbk-search__group" aria-label={title}>
            <div className="hbk-search__pad">
              <SectionHeader voice="hotel" level={2} title={title} draw="mount" />
            </div>
            <div>
              {list.map((b, i) => (
                <BookingRow
                  key={b.id}
                  booking={b}
                  mode={mode}
                  query={q}
                  last={i === list.length - 1}
                  onOpen={() => {
                    onOpened(q)
                    act.open({ id: b.id, eventDate: b.eventDate })
                  }}
                />
              ))}
            </div>
          </section>
        )
      })}
    </div>
  )
}
