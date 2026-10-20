// HL-BOOK-02 Upcoming and past. Requirement IDs: HA-BOOK-01, HA-BOOK-11, HA-DASH-01, HA-VCH-03.
// Everything that no longer waits for a decision: Upcoming is sectioned Awaiting client (with the 24 h confirm timer and the confirm-by
// time), Confirmed (voucher not yet redeemed) and Redeemed (who redeemed it and when); Past carries a chip row: Completed, Cancelled,
// Declined, Expired (ADR 0033: no deposit, balance or refund states). The same tab hosts search
// (client name in either script, reference, or a typed date) and the date-range filter. Compact rows, no inline decision buttons.
// States: past, loading, empty, no-results, error, offline, search-active, date-filter (+ date-applied, past-none)
import { BookingsTab } from './_components/BookingsTab'
import './HL-BOOK-02.css'

export const states = ['past', 'loading', 'empty', 'no-results', 'error', 'offline', 'search-active', 'date-filter', 'date-applied', 'past-none']

export default function UpcomingAndPast() {
  return <BookingsTab screen="HL-BOOK-02" />
}
