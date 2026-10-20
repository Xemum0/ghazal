// TaskSheet: add or edit a task of the couple's own (CL-WEDD-02 "Add item" sheet: title, optional due date, category). Opened by the
// checklist as a node (the inventory gives it no screen id). Edit and delete are reached from the row's edit control, never by swipe.
// Text diet (ADR 0034): the task name is its own placeholder (a pencil glyph keeps it a field once typed), the date is a glyph and a day,
// the category is one labelled choice; Save is one word, Delete one word.
import { useState } from 'react'
import { useBi, Button, Icon, SelectRow, TextField, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import { serviceCategories } from '../../../../mock'
import type { TaskRow } from './model'
import { useTools } from './tools'
import { DatePick } from './DatePick'
import { SheetFoot, SheetHead } from './SheetParts'

export type TaskSheetProps = {
  editing?: TaskRow
  /** The wedding date: a task is never due after it. */
  weddingDate: string | null
  today: string
}

export function TaskSheet({ editing, weddingDate, today }: TaskSheetProps) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const nav = useNav()
  const bi = useBi()
  const [title, setTitle] = useState(editing ? (typeof editing.title === 'string' ? editing.title : bi(editing.title)) : '')
  const [due, setDue] = useState<string | null>(editing?.dueOn ?? null)
  const [category, setCategory] = useState<string>(editing?.serviceCategoryId ?? '')
  const [error, setError] = useState(false)

  const options = [
    { value: '', label: t('clientMyWeddingTaskCategoryPlaceholder') },
    ...serviceCategories.map(s => ({ value: s.id, label: bi(s.name) })),
  ]

  const save = () => {
    if (!title.trim()) {
      setError(true)
      return
    }
    const s = useTools.getState()
    const patch = { title: title.trim(), dueOn: due, serviceCategoryId: category || null }
    if (editing) s.editTask(editing.id, patch)
    else s.addTask(patch)
    nav.closeSheet()
    nav.toast({ message: t('clientMyWeddingTaskAdded'), tone: 'success' })
  }

  const remove = () => {
    if (!editing) return
    const removed = useTools.getState().removeTask(editing.id)
    nav.closeSheet()
    nav.toast({
      message: t('clientMyWeddingTaskDeleted'),
      undo: true,
      action: { label: c('commonActionUndo'), onPress: () => removed && useTools.getState().restoreTask(removed) },
    })
  }

  return (
    <div className="gzmw-sheet" data-gz="TaskSheet">
      <SheetHead title={editing ? t('clientMyWeddingTaskSheetEdit') : t('clientMyWeddingTaskSheetAdd')} />
      <div className="gzmw-sheet__fields">
        <TextField
          aria-label={t('clientMyWeddingTaskTitlePlaceholder')}
          placeholder={t('clientMyWeddingTaskTitlePlaceholder')}
          startAdornment={<Icon name="edit" size="sm" tone="secondary" />}
          value={title}
          onValueChange={v => {
            setTitle(v)
            if (error && v.trim()) setError(false)
          }}
          error={error ? t('clientMyWeddingTaskTitleError') : undefined}
        />
        <DatePick label={t('clientMyWeddingTaskDueLabel')} value={due} onChange={setDue} minDate={today} maxDate={weddingDate ?? undefined} />
        <SelectRow label={t('clientMyWeddingTaskCategoryLabel')} options={options} value={category} onChange={v => setCategory(v ?? '')} />
      </div>
      <SheetFoot>
        <Button variant="primary" fullWidth onClick={save}>
          {c('commonActionSave')}
        </Button>
        {editing ? (
          <Button variant="destructive" iconStart="trash" fullWidth onClick={remove}>
            {t('clientMyWeddingTaskDelete')}
          </Button>
        ) : null}
      </SheetFoot>
    </div>
  )
}
