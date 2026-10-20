// CL-WEDD-04 Add expense (sheet over Budget; also the edit and delete sheet of a manual expense). Requirements: CA-TOOL-10, CA-TOOL-11.
//
// Something bought outside Ghazal, or planned: an amount, a category, an optional label, a date and Paid or Planned. The amount accepts
// Eastern-Arabic digits and normalises them (up to three decimals). Validation is blameless and shows once, on Save. Save closes the
// sheet and the row lands in the budget with an Undo bar. A guest may fill it in and is asked to sign in at Save; the sheet stays
// underneath, so what was typed is still there on return. The voucher and the venue price are posted by Ghazal and never open here.
//
// Text diet (ADR 0034): one labelled amount, the category chosen by glyph, a note that is its own placeholder, a glyph and a day, Paid or
// Planned as two glyph options that both keep their word (a payment status is money: never glyph-only, policy section 7), and one verb. No
// instruction, no note about signing in: a guest's button says "Sign in". The delete question is two words and two verbs; the success is a
// centred drawing and one word.
import { useEffect, useMemo, useRef, useState } from 'react'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { Button, FactChip, FactRow, Icon, IconSegmented, Illustration, TextField, useNav } from '../../../system'
import { flat } from '@gz/tokens'
import { clock } from '../../../mock'
import { SheetFoot, SheetHead, SheetRoot, useCurrencySlot } from './_components/SheetParts'
import { CategoryRail } from './_components/CategoryRail'
import { DatePick } from './_components/DatePick'
import { categoryGlyph, useCategoryName } from './_components/names'
import { openGuestGate } from './_components/gate'
import { buildBudget, type ManualExpense } from './_components/model'
import { useTools } from './_components/tools'
import { useStateParam, useWedding } from './_components/useWedding'
import './CL-WEDD-04.css'

/** The success token (640 ms, ADR 0017). */
const SUCCESS_MS = flat['motion.duration.success']

export const states = ['validation-error', 'saving', 'edit', 'delete-confirm', 'success', 'guest-gate', 'offline-disabled']

/** The example entry of the inventory, as the static `edit`, `delete-confirm` and `success` frames show it. */
const SAMPLE: Omit<ManualExpense, 'id' | 'label'> = { categoryId: 'makeup_henna', amount: 80_000, status: 'paid', date: '2026-11-08' }

type Phase = 'form' | 'confirm' | 'success'

/** "80", "80.5", "٨٠٫٥٠٠" -> integer fils, or null. At most three decimals. */
function toFils(text: string): number | null {
  const clean = text.replace(/[\s,]/g, '')
  const m = /^(\d+)(?:\.(\d{0,3}))?$/.exec(clean)
  if (!m) return null
  const fils = Number(m[1]) * 1000 + Number((m[2] ?? '').padEnd(3, '0'))
  return fils > 0 && Number.isSafeInteger(fils) ? fils : null
}

const filsToText = (fils: number): string => {
  const whole = Math.floor(fils / 1000)
  const rest = fils % 1000
  return rest === 0 ? String(whole) : `${whole}.${String(rest).padStart(3, '0').replace(/0+$/, '')}`
}

export default function AddExpense() {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const { lang } = useLang()
  const catName = useCategoryName()
  const nav = useNav()
  const state = useStateParam()
  const w = useWedding()
  const inert = w.inert
  const expenses = useTools(s => s.expenses)
  const auth = usePrototype(s => s.auth)

  // Which expense is being edited: a param (live), or the sample (the static edit frames).
  const expenseId = typeof nav.params.expenseId === 'string' ? nav.params.expenseId : null
  const staticEdit = state === 'edit' || state === 'delete-confirm' || state === 'success'
  const undo = c('commonActionUndo')
  const found = expenseId ? expenses.find(e => e.id === expenseId) : undefined
  const editing: ManualExpense | null = found ?? (staticEdit ? { id: 'sample', ...SAMPLE, label: t('clientMyWeddingExpenseSampleLabel') } : null)

  // The fixture's order (photo first), not alphabetical: the rail is read by glyph.
  const categories = useMemo(() => buildBudget({ status: w.status, total: undefined, alloc: {}, expenses: [] }).cats, [w.status])
  const manualCats = categories.filter(c => !c.autoLinked)
  const preset = typeof nav.params.categoryId === 'string' ? nav.params.categoryId : null
  const presetAmount = typeof nav.params.amount === 'number' ? nav.params.amount : null

  const [amount, setAmount] = useState(editing ? filsToText(editing.amount) : presetAmount ? filsToText(presetAmount) : '')
  const [categoryId, setCategoryId] = useState<string>(editing?.categoryId ?? preset ?? 'photo_video')
  const [label, setLabel] = useState(editing?.label ?? '')
  const [date, setDate] = useState<string | null>(editing?.date ?? clock.today())
  const [status, setStatus] = useState<'paid' | 'planned'>(editing?.status ?? 'paid')
  const [phase, setPhase] = useState<Phase>(state === 'delete-confirm' ? 'confirm' : state === 'success' ? 'success' : 'form')
  const [showError, setShowError] = useState(state === 'validation-error')
  const [saving, setSaving] = useState(state === 'saving')
  const timer = useRef<number | null>(null)
  useEffect(() => () => void (timer.current !== null && window.clearTimeout(timer.current)), [])

  const offline = state === 'offline-disabled'
  const guest = w.guest || state === 'guest-gate' || (!inert && auth === 'guest')
  const fils = toFils(amount)
  const error = showError && fils === null ? t('clientMyWeddingExpenseAmountError') : undefined
  const chosenCat = categories.find(c => c.id === categoryId)
  const categoryName = chosenCat ? catName(chosenCat.id, chosenCat.name) : ''

  const currencySlot = useCurrencySlot('gzmw-exp__cur')

  const save = () => {
    if (fils === null) {
      setShowError(true)
      return
    }
    if (guest) {
      if (!inert) openGuestGate(nav, 'CL-WEDD-04', { ...nav.params })
      return
    }
    const s = useTools.getState()
    const entry = { categoryId, label: label.trim(), amount: fils, status, date }
    if (editing && found) {
      s.editExpense(editing.id, entry)
      nav.closeSheet()
      nav.toast({ message: c('commonStateSaved'), tone: 'success' })
      return
    }
    const id = s.addExpense(entry)
    setSaving(true)
    // The one success moment of the flow (the success token), then the sheet leaves and the row is in the budget with Undo.
    setPhase('success')
    timer.current = window.setTimeout(() => {
      nav.closeSheet()
      nav.toast({
        message: t('clientMyWeddingBudgetAdded'),
        undo: true,
        action: { label: undo, onPress: () => void useTools.getState().removeExpense(id) },
      })
    }, SUCCESS_MS)
  }

  const remove = () => {
    if (!editing) return
    const removed = useTools.getState().removeExpense(editing.id)
    nav.closeSheet()
    nav.toast({
      message: t('clientMyWeddingExpenseDeleted'),
      undo: true,
      action: { label: undo, onPress: () => void (removed && useTools.getState().restoreExpense(removed)) },
    })
  }

  // ------------------------------------------------------------ delete confirmation (in the sheet, not a second layer)
  if (phase === 'confirm') {
    return (
      <SheetRoot data-gz="AddExpense" data-phase="confirm">
        <SheetHead title={t('clientMyWeddingExpenseDeleteTitle')} />
        <SheetFoot>
          <Button variant="destructive" iconStart="trash" fullWidth onClick={remove}>
            {t('clientMyWeddingExpenseDelete')}
          </Button>
          <Button variant="secondary" fullWidth onClick={() => setPhase('form')}>
            {t('clientMyWeddingExpenseKeep')}
          </Button>
        </SheetFoot>
      </SheetRoot>
    )
  }

  // ------------------------------------------------------------ success moment
  if (phase === 'success') {
    const shown = fils ?? editing?.amount ?? 0
    return (
      <SheetRoot data-gz="AddExpense" data-phase="success">
        <SheetHead title={t('clientMyWeddingExpenseTitleAdd')} />
        <div className="gzmw-exp__done" role="status" data-gz-id="success">
          <Illustration name="seal" size="lg" />
          <h3 className="gz-t-d2">{t('clientMyWeddingExpenseSuccessTitle')}</h3>
          <FactRow>
            <FactChip icon={categoryGlyph(chosenCat?.icon ?? '')} value={categoryName} label={t('clientMyWeddingExpenseCategory')} />
            <FactChip icon="coins" value={f.money(shown, { mode: 'exact' })} label={t('clientMyWeddingExpenseAmount')} />
          </FactRow>
        </div>
      </SheetRoot>
    )
  }

  const reasonOffline = offline ? t('clientMyWeddingExpenseOfflineReason') : undefined

  return (
    <SheetRoot data-gz="AddExpense" data-phase="form">
      <SheetHead title={editing ? t('clientMyWeddingExpenseTitleEdit') : t('clientMyWeddingExpenseTitleAdd')} />

      <div className="gzmw-sheet__fields">
        <TextField
          label={t('clientMyWeddingExpenseAmount')}
          value={amount}
          onValueChange={v => {
            setAmount(f.normalizeDigits(v))
            if (showError && toFils(f.normalizeDigits(v)) !== null) setShowError(false)
          }}
          inputMode="decimal"
          dir="ltr"
          autoComplete="off"
          {...currencySlot}
          error={error}
          disabled={offline}
        />
        <CategoryRail
          label={t('clientMyWeddingExpenseCategory')}
          options={manualCats.map(c => ({ value: c.id, icon: categoryGlyph(c.icon), label: catName(c.id, c.name) }))}
          value={categoryId}
          onChange={setCategoryId}
          disabled={offline}
        />
        <TextField
          aria-label={t('clientMyWeddingExpenseNote')}
          placeholder={t('clientMyWeddingExpenseNote')}
          startAdornment={<Icon name="edit" size="sm" tone="secondary" />}
          value={label}
          onValueChange={setLabel}
          disabled={offline}
        />
        <DatePick label={t('clientMyWeddingExpenseDate')} value={date} onChange={setDate} disabled={offline} />
        <IconSegmented<'paid' | 'planned'>
          label={t('clientMyWeddingExpenseStatus')}
          value={status}
          onChange={setStatus}
          disabled={offline}
          labels="all"
          options={[
            { value: 'paid', icon: 'check-circle', label: t('clientMyWeddingExpensePaid') },
            { value: 'planned', icon: 'calendar-dots', label: t('clientMyWeddingExpensePlanned') },
          ]}
        />
      </div>

      <SheetFoot>
        <Button variant="primary" fullWidth loading={saving} disabled={offline} reason={reasonOffline} iconStart={guest ? 'lock' : undefined} onClick={save}>
          {guest ? t('clientMyWeddingGuestAction') : c('commonActionSave')}
        </Button>
        {editing ? (
          <Button variant="destructive" iconStart="trash" fullWidth disabled={offline} onClick={() => setPhase('confirm')}>
            {t('clientMyWeddingExpenseDelete')}
          </Button>
        ) : null}
      </SheetFoot>
    </SheetRoot>
  )
}
