// "Next up": at most three actions, due first (CL-WEDD-01). Rules, not AI. The request's own step comes first (waiting for the venue), then the
// next checklist tasks, soonest first. A step that already has its own card (the 24 h confirmation, the hall search) is left out.
// ADR 0034: a row is a glyph, a one-word name and ONE fact at its end (a due date, a time left, a count). The words of the fact are its label.
// What has its own card on the hub (the planner, the 24 h confirmation, the hall search) is never repeated as a row.
import type { IconName } from '@gz/tokens'
import type { GzFormat } from '@gz/i18n'
import type { Lang } from '../../../../shell/state/types'
import type { TFunction } from '../../../../i18n'
import { TASK_COPY, type TaskRow } from './model'
import { taskGlyph } from './names'
import type { WeddingView } from './useWedding'

export type NextTarget =
  | { kind: 'booking' }
  | { kind: 'services'; categoryId: string }
  | { kind: 'checklist' }

/** The one fact at the end of a row. `date` = a civil day, `time` = time left to an instant, `count` = a number with its glyph. */
export type NextFact =
  | { kind: 'date'; on: string; label: string }
  | { kind: 'time'; at: string; label: string }
  | { kind: 'count'; n: number; icon: IconName; label: string }

export type NextRow = {
  id: string
  icon: IconName
  title: string
  fact: NextFact | null
  go: NextTarget
}

export type NextInput = {
  w: WeddingView
  tasks: readonly TaskRow[]
  remaining: number
  t: TFunction<'client-my-wedding'>
  f: GzFormat
  lang: Lang
}

export function buildNextUp({ w, tasks, remaining, t, f, lang }: NextInput): NextRow[] {
  const { phase, booking } = w
  const first: NextRow[] = []

  if (phase === 'request-pending' && booking?.respondBy) {
    first.push({
      id: 'waiting',
      icon: 'hourglass',
      title: t('clientMyWeddingNextWaiting'),
      fact: { kind: 'time', at: booking.respondBy, label: t('clientMyWeddingNextWaitingLabel', { when: f.dateTime(booking.respondBy, 'short') }) },
      go: { kind: 'booking' },
    })
  }

  // The day itself and the day after are not a to-do list: the hero (directions, call) or the review prompt carries them.
  if (phase === 'day-of' || phase === 'post-event') return []

  if (phase === 'wedding-week') {
    const rows: NextRow[] = []
    if (remaining > 0) {
      rows.push({
        id: 'checklist',
        icon: 'checklist',
        title: t('clientMyWeddingToolChecklist'),
        fact: { kind: 'count', n: remaining, icon: 'checklist', label: t('clientMyWeddingTasksLeft', { count: remaining }) },
        go: { kind: 'checklist' },
      })
    }
    // The planner is not a row here: her card sits on the same screen, with the message glyph.
    return rows.slice(0, 3)
  }

  // The dated, unfinished tasks of the checklist, soonest first, then the ones with no date.
  const open = tasks
    .filter(r => !r.done && !r.auto && r.serviceCategoryId)
    .sort((a, b) => (a.dueOn ?? '9999').localeCompare(b.dueOn ?? '9999'))
    .map<NextRow>(r => {
      const key = TASK_COPY[r.id as keyof typeof TASK_COPY]
      const title = key ? t(key) : typeof r.title === 'string' ? r.title : r.title[lang]
      return {
        id: r.id,
        icon: taskGlyph(r.id),
        title,
        fact: r.dueOn && phase !== 'no-date' ? { kind: 'date', on: r.dueOn, label: t('clientMyWeddingChecklistDue', { when: f.date(r.dueOn, 'short') }) } : null,
        go: { kind: 'services', categoryId: r.serviceCategoryId ?? '' },
      }
    })

  const out: NextRow[] = [...first.slice(0, 1)]
  if (open[0]) out.push(open[0])
  for (const r of open.slice(1)) if (out.length < 3) out.push(r)
  return out.slice(0, 3)
}
