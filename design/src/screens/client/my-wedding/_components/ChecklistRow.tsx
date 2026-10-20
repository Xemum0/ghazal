// ChecklistRow (CL-WEDD-02): a local build because the shared ChecklistItem has no due chip with an overdue glyph beside a deep-link glyph, no
// "In progress" venue state, no edit control for the couple's own tasks and no check draw (request filed). A 44 check target, the task in one
// word, its due date as a calendar fact (never colour alone: an overdue date carries the warning glyph), and at the end one glyph: search
// (opens the service category), the chevron (the Venue row opens the booking) or edit (a task the couple added). Done is ink and quiet:
// no strike-through, no confetti, no date.
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { FactChip, Icon, IconButton, StatusPill } from '../../../../system'
import { DateText } from './DateText'
import { TASK_COPY, type TaskRow } from './model'
import { taskGlyph } from './names'
import './checklist.css'

export type ChecklistRowProps = {
  row: TaskRow
  today: string
  /** Offline: shown, not changeable. */
  readOnly?: boolean
  /** Just ticked: the check draws once (160 ms class) before the row moves to Completed. */
  fresh?: boolean
  /** The story booking exists but is not confirmed yet: the Venue row shows its status (pending or approved) instead of a lock. */
  venueStatus?: 'pending' | 'approved' | null
  last?: boolean
  onToggle: (done: boolean) => void
  onBrowse?: () => void
  onOpenBooking?: () => void
  onEdit?: () => void
}

export function ChecklistRow({ row, today, readOnly, fresh, venueStatus, last, onToggle, onBrowse, onOpenBooking, onEdit }: ChecklistRowProps) {
  const t = useT('client-my-wedding')
  const f = useFormat()
  const { lang } = useLang()
  const key = row.custom ? undefined : TASK_COPY[row.id as keyof typeof TASK_COPY]
  const title = key ? t(key) : typeof row.title === 'string' ? row.title : row.title[lang]
  const overdue = !row.done && row.dueOn !== null && row.dueOn < today
  const locked = row.auto

  let meta: React.ReactNode = null
  if (row.done) {
    meta = null
  } else if (locked) {
    meta = venueStatus ? (
      <StatusPill status={venueStatus} />
    ) : (
      <span className="gzmw-task__lock">
        <Icon name="lock" size="xs" tone="secondary" />
        <span className="gz-sr-only">{t('clientMyWeddingChecklistAuto')}</span>
      </span>
    )
  } else if (row.dueOn && overdue) {
    meta = (
      <span className="gzmw-task__due is-overdue gz-t-fig-caption">
        <Icon name="warning-circle" size="xs" tone="danger" />
        <span className="gz-sr-only">{t('clientMyWeddingChecklistOverdue', { when: f.date(row.dueOn, 'short') })}</span>
        <DateText text={f.date(row.dueOn, 'dayMonth')} />
      </span>
    )
  } else if (row.dueOn) {
    meta = <FactChip icon="calendar" size="sm" value={<DateText text={f.date(row.dueOn, 'dayMonth')} />} label={t('clientMyWeddingChecklistDue', { when: f.date(row.dueOn, 'short') })} />
  }

  const canBrowse = !row.done && Boolean(row.serviceCategoryId) && Boolean(onBrowse)
  return (
    <div data-gz="ChecklistRow" data-done={row.done || undefined} data-overdue={overdue || undefined} className={`gzmw-task${row.done ? ' is-done' : ''}${last ? ' is-last' : ''}`}>
      <button
        type="button"
        role="checkbox"
        aria-checked={row.done}
        aria-disabled={locked || readOnly || undefined}
        aria-label={title}
        className={`gz-reset gzmw-task__target gz-press${row.done ? ' is-on' : ''}`}
        onClick={() => {
          if (locked || readOnly) return
          onToggle(!row.done)
        }}
      >
        <span className="gzmw-task__box">
          {row.done ? (
            <svg className={`gzmw-task__check${fresh ? ' is-drawing' : ''}`} viewBox="0 0 16 16" aria-hidden="true">
              <path d="M3.5 8.5 6.5 11.5 12.5 4.5" pathLength={1} />
            </svg>
          ) : null}
        </span>
      </button>

      <Icon name={taskGlyph(row.id)} size="md" tone="secondary" className="gzmw-task__glyph" />

      <div className="gzmw-task__text">
        <span className="gzmw-task__title gz-t-title">
          <bdi dir="auto">{title}</bdi>
        </span>
        {meta ? <span className="gzmw-task__meta">{meta}</span> : null}
      </div>

      {row.custom && onEdit && !readOnly ? (
        <IconButton icon="edit" label={`${t('clientMyWeddingChecklistEdit')}: ${title}`} onClick={onEdit} iconSize="sm" />
      ) : canBrowse ? (
        <IconButton icon="search" label={t('clientMyWeddingChecklistBrowseLabel', { task: title })} onClick={onBrowse} iconSize="sm" />
      ) : row.auto && onOpenBooking ? (
        <IconButton icon="chevron-right" label={t('clientMyWeddingChecklistViewBookingLabel', { task: title })} onClick={onOpenBooking} iconSize="sm" />
      ) : null}
    </div>
  )
}
