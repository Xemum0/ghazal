// CountdownCard (My Wedding, Home once a booking is confirmed; ADR 0011 D7, direction section 3 "Ink panels"): the one ink panel of a
// screen. Whole days only, never seconds, never a ticking number. The numeral is the display serif at 96 (Amiri 104 in Arabic),
// the unit and one calm sentence sit beside and under it. Milestones (a year, six months, a month, a week, tomorrow, today) change the
// sentence; tomorrow and today replace the numeral with the word. A gold 2 px thread shows how far along the wait is (a state).
//
// states  plain, milestone 365 / 180 / 30 / 7, tomorrow, today, loading
import { useMemo } from 'react'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Button, Icon, Skeleton } from '../core'
import { cx } from '../core/cx'
import { Figures } from './bits'
import { defineWords, p } from './copy'
import './countdown.css'

const useW = defineWords({
  eyebrow: p('Your wedding', 'زفافكم'),
  unitOne: p('day', 'يوم'),
  unitMany: p('days', 'يومًا'),
  tomorrow: p('Tomorrow', 'غدًا'),
  today: p('Today', 'اليوم'),
  toGo: p('until your wedding', 'حتى زفافكم'),
  year: p('A year of planning ahead.', 'عام كامل من التحضير أمامكم.'),
  half: p('Six months to go.', 'ستة أشهر تفصلكم عن الحفل.'),
  month: p('One month to go. A good time to settle the details.', 'شهر واحد يفصلكم عن الحفل، وقت مناسب لحسم التفاصيل.'),
  week: p('One week to go. Your guest count is now locked.', 'أسبوع واحد يفصلكم عن الحفل. تم تثبيت عدد الضيوف.'),
  tomorrowLine: p('Everything is set for tomorrow.', 'كل شيء جاهز ليوم غدٍ.'),
  todayLine: p('Today is your day.', 'اليوم يومكم.'),
  progress: p('Waiting time elapsed', 'الوقت المنقضي من الانتظار'),
  days: p('{n} days', '{n} يومًا'),
})

export type CountdownMilestone = 'year' | 'half' | 'month' | 'week' | 'tomorrow' | 'today' | null

/** The milestone a day count lands on (365, 180, 30, 7, 1, 0); anything else is a plain count. */
export function countdownMilestone(days: number): CountdownMilestone {
  if (days <= 0) return 'today'
  if (days === 1) return 'tomorrow'
  if (days === 7) return 'week'
  if (days === 30) return 'month'
  if (days === 180) return 'half'
  if (days === 365) return 'year'
  return null
}

export type CountdownCardProps = {
  /** Whole calendar days to the wedding (`daysToWedding()`); 0 = today. */
  days: number
  /** The wedding date (civil `YYYY-MM-DD`), spelled out in the facts line. */
  eventDate: string
  /** Venue and hall line under the date. */
  where?: string
  /** 0 to 1: how much of the wait has passed (booking made to wedding day). Omit to hide the thread. */
  progress?: number
  actionLabel?: string
  onAction?: () => void
  loading?: boolean
  className?: string
}

export function CountdownCard({ days, eventDate, where, progress, actionLabel, onAction, loading, className }: CountdownCardProps) {
  const f = useFormat()
  const w = useW()
  const { lang } = useLang()
  const milestone = useMemo(() => countdownMilestone(days), [days])

  if (loading) {
    return (
      <div className={cx('gz-countdown gz-on-dark is-loading', className)} data-gz="CountdownCard" aria-busy="true">
        <Skeleton inlineSize={96} blockSize={16} className="gz-countdown__sk" />
        <Skeleton inlineSize={160} blockSize={96} className="gz-countdown__sk" />
        <Skeleton inlineSize={220} blockSize={20} className="gz-countdown__sk" />
      </div>
    )
  }

  const word = milestone === 'today' ? w('today') : milestone === 'tomorrow' ? w('tomorrow') : null
  // The unit noun by the formatter's plural rule (Arabic: 1 يوم, 2 يومان, 3-10 أيام, 11+ يومًا).
  const unit = f.plural(days, lang === 'ar' ? { '=1': 'يوم', '=2': 'يومان', few: 'أيام', many: 'يومًا', other: 'يوم' } : { '=1': 'day', other: 'days' })
  const line = milestone ? w(milestone === 'today' ? 'todayLine' : milestone === 'tomorrow' ? 'tomorrowLine' : milestone) : w('toGo')
  const done = Math.min(Math.max(progress ?? 0, 0), 1)
  // Flex ratios in whole permille: no widths, no calc.
  const grow = Math.round(done * 1000)

  return (
    <section data-gz="CountdownCard" data-milestone={milestone ?? 'plain'} className={cx('gz-countdown gz-on-dark', className)} aria-label={w('eyebrow')}>
      <p className="gz-countdown__eyebrow gz-t-label gz-text-gold">{w('eyebrow')}</p>

      <div className="gz-countdown__num" data-gz-id="numeral">
        {word ? (
          <span className="gz-countdown__word gz-t-d5" lang={lang}>
            {word}
          </span>
        ) : (
          <>
            <span className="gz-countdown__big gz-t-countdown" lang={lang}>
              <bdi dir="ltr">{f.integer(days)}</bdi>
            </span>
            <span className="gz-countdown__unit gz-t-d1" lang={lang}>
              {unit}
            </span>
          </>
        )}
      </div>

      <p className="gz-countdown__line gz-t-body gz-text-muted">{line}</p>

      {progress !== undefined ? (
        <div className="gz-countdown__thread" role="img" aria-label={`${w('progress')}: ${f.percent(done * 100, { maxFraction: 0 })}`} data-gz-id="thread">
          <span className="gz-countdown__fill" style={{ flexGrow: grow }} />
          <span className="gz-countdown__knot" />
          <span className="gz-countdown__rest" style={{ flexGrow: 1000 - grow }} />
        </div>
      ) : null}

      <div className="gz-countdown__facts">
        <Icon name="calendar" size="sm" tone="on-dark" />
        <span className="gz-t-body-s">
          <Figures text={f.date(eventDate, 'full')} />
          {where ? <span className="gz-text-muted"> · {where}</span> : null}
        </span>
      </div>

      {actionLabel ? (
        <Button variant="tertiary" onDark iconEnd="chevron-right" onClick={onAction} className="gz-countdown__action">
          {actionLabel}
        </Button>
      ) : null}
    </section>
  )
}
