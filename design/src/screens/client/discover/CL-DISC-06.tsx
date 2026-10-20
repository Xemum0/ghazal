// CL-DISC-06 Dates for your search (sheet). Covers CA-FLT-05, CA-SRCH-14, CA-HOME-02, CA-FLT-07.
// A filterable availability calendar for search, not tied to one venue: pick a day, or drag out a short range (up to seven days), and Results shows
// only the venues with a free hall on it. Sunday-first custom calendar (no native picker), the Thursday to Saturday band at the inline-end edge,
// month arrows that mirror, and a density mark on every day by shape and never by colour alone: many halls free = the plain figure, few = the
// figure with a gold-700 bead, none = a struck figure. "Not decided yet" and "Flexible month" mirror the Brief sheet. The pinned footer states
// the live count ("Show 3 halls free on Thu 14 Jan"); applying writes the Brief date and the Results filter, "Clear date" resets. A day with no
// free hall offers the three nearest dates that have one. Opened from Results (Date chip) and from the Filters sheet (which hands the choice back).
// States: default, loading-density, range-selected, flexible-month, no-venues-on-date, offline, error.
import { useFrame } from '../../../shell/frame'
import { useNav } from '../../../system'
import { DateFilterSheet } from './_components/DateFilterSheet'
import type { Filters } from './_components/data'

export const states = ['loading-density', 'range-selected', 'flexible-month', 'no-venues-on-date', 'offline', 'error']

export default function DateFilter() {
  const nav = useNav()
  const { state } = useFrame()
  return <DateFilterSheet state={state} onApply={nav.params.onApply as ((p: Partial<Filters>) => void) | undefined} />
}
