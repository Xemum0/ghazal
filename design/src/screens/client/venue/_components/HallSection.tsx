// HallSection (CL-VENU-01): the hall switcher (only when more than one hall fits the Brief), the hall's facts as glyphs and figures, its
// description clamped to two lines, and the session switcher (only when more than one session is free that day; an exclusive-day ballroom
// has none, ADR 0002 D5). ADR 0034: capacity, setting and exclusivity are facts (glyph and figure, the word is the accessible name); a
// session is a sun, a setting sun or a moon. Hall names are the one serif inside a control (direction 3, segmented).
import { engine } from '../../../../mock'
import type { AvailabilityDay, Hall, IsoDate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { FactChip, FactRow, IconSegmented, SectionHeader, SegmentedControl, useBi } from '../../../../system'
import { Clamp } from './Clamp'
import { Mixed } from './Mixed'
import { SETTING_ICON, sessionIcon } from './glyphs'
import './hall-section.css'

export type HallSectionProps = {
  halls: readonly Hall[]
  hall: Hall
  onHall: (hallId: string) => void
  /** The day of the Brief for this hall, to know which sessions are free. */
  day: AvailabilityDay | null
  date: IsoDate | null
  sessionId: string | null
  onSession: (sessionId: string) => void
}

const SETTING_KEY = { indoor: 'clientVenueHallIndoor', outdoor: 'clientVenueHallOutdoor', mixed: 'clientVenueHallMixed' } as const

export function HallSection({ halls, hall, onHall, day, date, sessionId, onSession }: HallSectionProps) {
  const f = useFormat()
  const t = useT('client-venue')
  const bi = useBi()
  const { lang } = useLang()

  // Sessions free that day (a held session still takes a request). Hidden for exclusive-day halls.
  const free = !hall.exclusiveDay && day ? hall.sessions.filter(s => day.sessions.some(x => x.sessionId === s.id && (x.state === 'available' || x.state === 'held'))) : []
  const rangeOf = (start: string, end: string): string => {
    const d: IsoDate = date ?? engine.addDays(mockToday(), 1)
    const from = engine.at(d, start)
    const to = engine.at(end <= start ? engine.addDays(d, 1) : d, end)
    return f.plain(f.timeRange(from, to))
  }
  const session = free.find(s => s.id === sessionId) ?? free[0]

  return (
    <section className="gzv-hall" data-gz="HallSection">
      <SectionHeader title={halls.length > 1 ? t('clientVenueHallsTitle') : <span lang={lang}>{bi(hall.name)}</span>} />
      {halls.length > 1 ? (
        <SegmentedControl
          label={t('clientVenueHallSwitchLabel')}
          face="hall"
          value={hall.id}
          onChange={onHall}
          options={halls.map(h => ({ value: h.id, label: bi(h.name) }))}
        />
      ) : null}
      <FactRow className="gzv-hall__facts" label={t('clientVenueHallFacts')}>
        <span data-gz-id="hall.facts">
          <FactChip
            icon="users-three"
            label={t('clientVenueHallCapacity')}
            value={
              <bdi dir="ltr" className="gz-num">
                {f.integer(hall.capacity.min)}–{f.integer(hall.capacity.max)}
              </bdi>
            }
          />
        </span>
        <FactChip icon={SETTING_ICON[hall.setting]} label={t(SETTING_KEY[hall.setting])} />
        {hall.exclusiveDay ? <FactChip icon="calendar-check" label={t('clientVenueHallExclusive')} value={t('clientVenueHallExclusiveShort')} /> : null}
      </FactRow>
      <div data-gz-id="hall.description">
        <Clamp text={bi(hall.description)} />
      </div>
      {free.length > 1 ? (
        <div className="gzv-hall__sessions" data-gz-id="hall.sessions">
          <IconSegmented
            label={t('clientVenueSessionSwitchLabel')}
            value={session?.id}
            onChange={onSession}
            options={free.map(s => ({ value: s.id, icon: sessionIcon(s.start), label: bi(s.name) }))}
          />
          {session ? <FactChip icon="clock" label={bi(session.name)} value={<Mixed text={rangeOf(session.start, session.end)} />} /> : null}
        </div>
      ) : null}
    </section>
  )
}

const mockToday = (): IsoDate => engine.kuwaitDateOf(engine.at('2026-11-12', '16:00'))
