// CountdownHero (CL-WEDD-01): the one ink panel of My Wedding. A local build because the shared CountdownCard has no milestone ticks, no
// rule under the numeral and no no-date, day-of or after-the-wedding form (request filed). Whole days only, never seconds, nothing ticks.
//
// Text diet (ADR 0034): the panel speaks in figures. No eyebrow, no sentence under the numeral, no labels on the thread.
//   count    the numeral in the display face (or the word Today / Tomorrow), its unit, the thread with its six marks (365, 180, 30, 7, 1, 0:
//            evenly spaced, not to scale; the milestones are the accessible name), and the date as a calendar fact. At a milestone one
//            gold line draws under the numeral, once. Gold is state here: the line, the part of the thread already travelled, the marks passed.
//   nodate   a calendar drawing, two words and the screen's one primary (passed as children)
//   done     the day has passed: one word of congratulation with the rings at its end (md, so the longest English word fits at 360), the
//            date on its own row below; the review prompt sits under the card
import type { ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Fig, Figures, Icon, Illustration, Skeleton, countdownMilestone } from '../../../../system'
import { MARKS, threadPosition } from './model'
import './hero.css'

const STEP = flat['motion.duration.fast']

export type CountdownHeroProps = {
  mode: 'count' | 'nodate' | 'done'
  /** Whole days to go (count). */
  days?: number
  /** Civil date of the wedding (count, done). */
  eventDate?: string | null
  /** The date is a button that opens the wedding file (CL-PROF-02): a calendar glyph, the date and a chevron, no word. */
  onDate?: () => void
  /** The primary action(s) inside the panel (no date, day-of). */
  children?: ReactNode
  loading?: boolean
}

export function CountdownHero({ mode, days = 0, eventDate, onDate, children, loading }: CountdownHeroProps) {
  const t = useT('client-my-wedding')
  const f = useFormat()
  const { lang } = useLang()

  if (loading) {
    return (
      <div className="gzmw-hero gz-on-dark is-loading" data-gz="CountdownHero" aria-busy="true">
        <Skeleton inlineSize={168} blockSize={96} className="gzmw-hero__sk" />
        <Skeleton blockSize={32} className="gzmw-hero__sk" />
        <Skeleton inlineSize={120} blockSize={24} className="gzmw-hero__sk" />
      </div>
    )
  }

  const dateInner = eventDate ? (
    <>
      <Icon name="calendar" size="sm" tone="on-dark" />
      <span className="gz-sr-only">{t('clientMyWeddingHeroDate')}</span>
      <Figures text={f.date(eventDate, 'compact')} />
      {onDate ? <Icon name="chevron-right" size="xs" className="gzmw-hero__go" /> : null}
    </>
  ) : null
  const dateFact = eventDate ? (
    onDate ? (
      <button type="button" className="gz-reset gzmw-hero__facts gzmw-hero__facts--btn gz-t-body-s gz-press" data-gz-id="date" onClick={onDate}>
        {dateInner}
      </button>
    ) : (
      <p className="gzmw-hero__facts gz-t-body-s" data-gz-id="date">
        {dateInner}
      </p>
    )
  ) : null

  if (mode === 'nodate') {
    return (
      <section className="gzmw-hero gz-on-dark" data-gz="CountdownHero" data-mode="nodate" aria-label={t('clientMyWeddingHeroDate')}>
        <div className="gzmw-hero__split">
          <div className="gzmw-hero__copy">
            <h2 className="gzmw-hero__headline gz-t-d2" lang={lang}>
              {t('clientMyWeddingHeroDate')}
            </h2>
            {children ? <div className="gzmw-hero__actions">{children}</div> : null}
          </div>
          <Illustration name="calendar" size="lg" tone="on-dark" className="gzmw-hero__art" />
        </div>
      </section>
    )
  }

  if (mode === 'done') {
    return (
      <section className="gzmw-hero gz-on-dark" data-gz="CountdownHero" data-mode="done" aria-label={t('clientMyWeddingHeroDate')}>
        <div className="gzmw-hero__split">
          <div className="gzmw-hero__copy">
            <h2 className="gzmw-hero__headline gz-t-d2" lang={lang}>
              {t('clientMyWeddingDoneTitle')}
            </h2>
          </div>
          <Illustration name="rings" size="md" tone="on-dark" className="gzmw-hero__art" />
        </div>
        {dateFact}
        {children ? <div className="gzmw-hero__actions">{children}</div> : null}
      </section>
    )
  }

  const milestone = countdownMilestone(days)
  const word = milestone === 'today' ? t('clientMyWeddingHeroWordToday') : milestone === 'tomorrow' ? t('clientMyWeddingHeroWordTomorrow') : null

  return (
    <section
      className="gzmw-hero gz-on-dark"
      data-gz="CountdownHero"
      data-mode="count"
      data-milestone={milestone ?? 'plain'}
      aria-label={`${t('clientMyWeddingHeroDate')}: ${f.countdownDays(days)}`}
    >
      <div className="gzmw-hero__num" data-gz-id="numeral">
        <span className="gzmw-hero__figure">
          {word ? (
            <span className="gz-t-d5" lang={lang}>
              {word}
            </span>
          ) : (
            <span className="gz-t-countdown" lang={lang}>
              <Fig>{f.integer(days)}</Fig>
            </span>
          )}
          {milestone ? <span className="gzmw-hero__rule gz-thread-draw" data-gz-id="milestone-rule" /> : null}
        </span>
        {word ? null : (
          <span className="gzmw-hero__unit gz-t-d1" lang={lang}>
            {t('clientMyWeddingHeroUnit', { count: days })}
          </span>
        )}
      </div>

      <Thread days={days} />

      {dateFact}
      {children ? <div className="gzmw-hero__actions">{children}</div> : null}
    </section>
  )
}

// ---------------------------------------------------------------- the thread

/** Six evenly spaced marks; each column is [half line][mark][half line], so a mark sits at the centre of its column. No labels: the
 * milestones (365, 180, 30, 7, 1, 0) are the thread's accessible name. */
function Thread({ days }: { days: number }) {
  const t = useT('client-my-wedding')
  const f = useFormat()
  const position = threadPosition(days)
  const last = MARKS.length - 1

  const half = (h: number) => {
    const share = Math.min(Math.max((position - h / 2) / 0.5, 0), 1)
    const grow = Math.round(share * 1000)
    // The bead sits where the travelled part ends, unless it ends exactly on a mark (the mark itself is the bead then).
    const bead = share > 0 && share < 1
    return (
      <span className="gzmw-thread__half" key={`h${h}`} aria-hidden="true">
        <span className="gzmw-thread__fill gz-thread-draw" style={{ flexGrow: grow, ['--gz-delay' as string]: `${h * STEP}ms` }} />
        {bead ? <span className="gzmw-thread__bead" /> : null}
        <span className="gzmw-thread__rest" style={{ flexGrow: 1000 - grow }} />
      </span>
    )
  }

  return (
    <div
      className="gzmw-thread"
      role="img"
      aria-label={`${t('clientMyWeddingHeroTimeline')}: ${MARKS.map(m => f.integer(m)).join(', ')}. ${f.countdownDays(days)}`}
      data-gz-id="thread"
    >
      {MARKS.map((mark, i) => {
        const state = position > i ? 'passed' : position === i ? 'now' : 'ahead'
        return (
          <div className="gzmw-thread__col" key={mark}>
            <div className="gzmw-thread__line">
              {i > 0 ? half(2 * i - 1) : <span className="gzmw-thread__half is-void" />}
              <span className={`gzmw-thread__mark is-${state}`} />
              {i < last ? half(2 * i) : <span className="gzmw-thread__half is-void" />}
            </div>
          </div>
        )
      })}
    </div>
  )
}
