// CL-WEDD-05 Set budget (sheet over Budget). Requirements: CA-TOOL-05, CA-TOOL-08, CA-TOOL-09, CA-ONB-04.
//
// The total for the whole wedding (asked here: onboarding only gave the venue and catering band, which shows as a reference on that
// category), three suggested totals, and the split by category with steppers. A live figure says what is left to allocate; allocating more
// than the total is a calm glyph and a figure, never a block. What the alerts do is a bell and two percents, each with the glyph the Budget screen uses for it. Save returns to Budget.
// Rules, no AI.
//
// Text diet (ADR 0034): one labelled field, three bare figures, one glyph and one word per category, the currency stated once. No hint, no
// note, no sentence; a failed save is two words and the recovery text sits behind the info glyph (the error-recovery exception).
import { useMemo, useState } from 'react'
import { useFormat, useT } from '../../../i18n'
import { Banner, Button, ChipGroup, FactChip, FactRow, Icon, InfoButton, Stepper, TextField, useNav } from '../../../system'
import { budgetFor, weddingProfile } from '../../../mock'
import { SheetFoot, SheetHead, SheetRoot, useCurrencySlot } from './_components/SheetParts'
import { MiniMeter } from './_components/parts'
import { ALERT_HARD, ALERT_SOFT, PRESET_TOTALS, buildBudget } from './_components/model'
import { categoryGlyph, useCategoryName } from './_components/names'
import { useTools } from './_components/tools'
import { useStateParam, useWedding } from './_components/useWedding'
import './CL-WEDD-05.css'

export const states = ['over-allocated', 'saving', 'error', 'offline-disabled']

const KD = 1000
/** Categories move in steps of KD 100; the venue, which is most of the budget, in steps of KD 500. */
const stepOf = (id: string): number => (id === 'venue_catering' ? 500 : 100)
/** Frame demo: the venue pushed up by KD 4,000 so the allocation passes the total. */
const OVER_DEMO = 4_000

export default function SetBudget() {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const catName = useCategoryName()
  const nav = useNav()
  const state = useStateParam()
  const w = useWedding()

  const model = useMemo(() => buildBudget({ status: w.status, total: w.tools.total, alloc: w.tools.alloc, expenses: [] }), [w.status, w.tools.total, w.tools.alloc])
  // Alphabetical order would hide the story: keep the fixture order (venue first), as the couple's allocation reads.
  const cats = useMemo(() => {
    const order: string[] = budgetFor('pending').budget.categories.map(x => x.id)
    return model.cats.slice().sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id))
  }, [model.cats])

  const initialTotal = model.total === null ? '' : String(Math.round(model.total / KD))
  const [total, setTotal] = useState(initialTotal)
  const [alloc, setAlloc] = useState<Record<string, number>>(() => {
    const out: Record<string, number> = Object.fromEntries(cats.map(x => [x.id, Math.round(x.allocated / KD)]))
    if (state === 'over-allocated') out.venue_catering = (out.venue_catering ?? 0) + OVER_DEMO
    return out
  })
  const [saving, setSaving] = useState(state === 'saving')
  const [failed, setFailed] = useState(state === 'error')
  const [showError, setShowError] = useState(false)
  const offline = state === 'offline-disabled'

  const totalKd = total === '' ? null : Number(total)
  const allocated = Object.values(alloc).reduce((a, b) => a + b, 0)
  const left = (totalKd ?? 0) - allocated
  const over = totalKd !== null && left < 0
  const band = weddingProfile.venueBudget
  const reason = offline ? t('clientMyWeddingExpenseOfflineReason') : undefined
  const currencySlot = useCurrencySlot('gzmw-set__cur')
  const bare = (fils: number) => f.moneyParts(fils).amount

  const save = () => {
    if (totalKd === null || totalKd <= 0) {
      setShowError(true)
      return
    }
    setFailed(false)
    setSaving(true)
    useTools.getState().saveBudget(
      totalKd * KD,
      Object.fromEntries(Object.entries(alloc).map(([id, kd]) => [id, kd * KD])),
    )
    nav.closeSheet()
    nav.toast({ message: t('clientMyWeddingSetupSaved'), tone: 'success' })
  }

  const presetValue = totalKd !== null && PRESET_TOTALS.includes(totalKd * KD) ? totalKd * KD : null

  return (
    <SheetRoot data-gz="SetBudget" data-over={over || undefined}>
      <SheetHead title={t('clientMyWeddingSetupTitle')} />

      {failed ? (
        <Banner tone="danger" shape="card">
          {t('clientMyWeddingSetupError')}
          <InfoButton title={c('commonLabelDetails')}>{t('clientMyWeddingSetupErrorDetail')}</InfoButton>
        </Banner>
      ) : null}

      <div className="gzmw-sheet__fields">
        <TextField
          label={t('clientMyWeddingSetupTotal')}
          value={total}
          onValueChange={v => {
            const digits = f.normalizeDigits(v).replace(/[^\d]/g, '').slice(0, 7)
            setTotal(digits)
            if (showError && Number(digits) > 0) setShowError(false)
          }}
          inputMode="numeric"
          dir="ltr"
          autoComplete="off"
          {...currencySlot}
          error={showError ? t('clientMyWeddingExpenseAmountError') : undefined}
          disabled={offline}
        />
        <ChipGroup<number>
          label={t('clientMyWeddingSetupPresets')}
          value={presetValue}
          disabled={offline}
          onChange={v => v !== null && setTotal(String(Math.round(v / KD)))}
          options={PRESET_TOTALS.map(v => ({ value: v, label: <bdi dir="ltr">{bare(v)}</bdi> }))}
        />
      </div>

      <section className="gzmw-set__cats" aria-label={t('clientMyWeddingSetupCategories')} data-gz-id="categories">
        <div className="gzmw-set__sticky">
          <div className="gzmw-set__head">
            <h3 className="gz-t-title">{t('clientMyWeddingSetupCategories')}</h3>
            <p className="gzmw-set__left gz-t-fig-body" aria-live="polite" data-gz-id="unallocated">
              <span className="gz-sr-only">{over ? t('clientMyWeddingSetupOver') : t('clientMyWeddingSetupUnallocated')}</span>
              <MiniMeter share={totalKd ? Math.min(allocated / totalKd, 1) : 0} />
              <Icon name={over ? 'info' : 'coins'} size="sm" tone={over ? 'accent' : 'secondary'} />
              <span className={over ? 'gz-text-gold' : 'gz-text-strong'}>
                <bdi dir="ltr">{bare(Math.abs(left) * KD)}</bdi>
              </span>
            </p>
          </div>
        </div>
        <div className="gzmw-set__rows">
          {cats.map(x => (
            <div key={x.id} className="gzmw-set__row" data-gz-id={`category.${x.id}`}>
              <Stepper
                label={
                  <span className="gzmw-set__name">
                    <Icon name={categoryGlyph(x.icon)} size="sm" tone="secondary" />
                    {catName(x.id, x.name)}
                  </span>
                }
                value={alloc[x.id] ?? 0}
                onChange={v => setAlloc(a => ({ ...a, [x.id]: v }))}
                min={0}
                max={9999999}
                step={stepOf(x.id)}
                disabled={offline}
                valueText={n => f.money(n * KD)}
              />
              {x.id === 'venue_catering' && band ? (
                <p className="gzmw-set__ref">
                  <FactChip
                    icon="info"
                    tone="muted"
                    size="sm"
                    value={
                      <bdi dir="ltr">
                        {bare(band.min.fils)}–{bare(band.max.fils)}
                      </bdi>
                    }
                    label={t('clientMyWeddingSetupVenueReference')}
                  />
                </p>
              ) : null}
            </div>
          ))}
        </div>
      </section>

      <div className="gzmw-set__alerts" data-gz-id="alerts">
        <Icon name="bell" size="sm" tone="secondary" />
        <FactRow>
          <FactChip icon="info" tone="muted" value={f.percent(ALERT_SOFT, { maxFraction: 0 })} label={t('clientMyWeddingSetupAlertSoft', { percent: f.percent(ALERT_SOFT, { maxFraction: 0 }) })} />
          <FactChip icon="warning-circle" tone="muted" value={f.percent(ALERT_HARD, { maxFraction: 0 })} label={t('clientMyWeddingSetupAlertHard', { percent: f.percent(ALERT_HARD, { maxFraction: 0 }) })} />
        </FactRow>
      </div>

      <SheetFoot>
        <Button variant="primary" fullWidth loading={saving && !failed} disabled={offline} reason={reason} onClick={save}>
          {c('commonActionSave')}
        </Button>
      </SheetFoot>
    </SheetRoot>
  )
}
