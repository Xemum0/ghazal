// HL-BOOK-01 Pending requests (tab root). Requirement IDs: HA-BOOK-01, HA-BOOK-03, HA-BOOK-04, HA-BOOK-06, HA-BOOK-07, HA-DASH-03, HA-DASH-04, HA-NOTI-01, HA-AUTH-02.
// Triage: every request waiting for a reply as a decision-ready card, nearest deadline first, with one gold Accept and two quiet
// alternatives (ADR 0008 D5). The tab opens here when anything is pending, otherwise on Upcoming (D2). Decisions run in the Decisions flow:
// Accept = two taps with the 8 s Undo, or its confirm sheet when competing requests or an event within 14 days apply; it starts the
// client's 24 h confirm window (ADR 0033). The card shows the voucher chip and the voucher price with the standard price struck through.
// Requirement IDs also: HA-VCH-03, PA-LST-06.
// States: loading, empty, error, offline, danger-sla, conflict, role-read-only, new-arrival, search-active
import { BookingsTab } from './_components/BookingsTab'
import './HL-BOOK-01.css'

export const states = ['loading', 'empty', 'error', 'offline', 'danger-sla', 'conflict', 'role-read-only', 'new-arrival', 'search-active']

export default function PendingRequests() {
  return <BookingsTab screen="HL-BOOK-01" />
}
