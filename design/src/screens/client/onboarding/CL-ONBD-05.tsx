// CL-ONBD-05 Guests and budget. Covers CA-ONB-04, CA-ONB-05, CA-ONB-08, CA-ONB-09.
// Text diet (ADR 0034): guest count and the venue-and-catering budget are one decision in Kuwait (hall prices are per guest), so they share a
// screen, but the screen is figures and glyphs: no title, lead, captions or sentences. Guests: a large stepper (hard cap 1,500) with the
// common counts as chips; the ladies' and men's split is a switch beside the two section glyphs (the glyph is the value). Budget: the
// question is "Venue and catering" (never confused with total wedding spend, ADR 0012, 0018) with the currency as a quiet unit, five bands
// as bare figures, a histogram of what the halls cost at that guest count, a range slider whose two values are money, and the per-guest
// figure as a fact. Each half can be put off on its own (`Later`) and then shows a drawing row with the way back (`Add`). Continue writes
// both answers; Skip writes nothing.
// States: default (the demo persona's answers), split-guests (ladies 350, men 400), skipped (both halves left open).
import { useEffect, useRef, useState, type MouseEvent } from 'react'
import { ActionBar, Button, Chip, FactChip, Fig, Figures, Icon, IconListRow, RangeSlider, Screen, Stepper, Switch, layoutScale, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { budgetBands, fils, weddingProfile as storyProfile } from '../../../mock'
import { FormSection } from './_components/FormSection'
import { PriceHistogram } from './_components/PriceHistogram'
import { StepBar } from './_components/StepBar'
import { commitGuestsBudget } from './_components/profile'
import { useScreenState } from './_components/useScreenState'
import './_components/form.css'
import './CL-ONBD-05.css'

export const states = ['split-guests', 'skipped']

const GUEST_MIN = 10
const GUEST_MAX = 1500
const GUEST_STEP = 10
const PRESETS = [100, 150, 200, 300, 400, 500, 650, 800, 1000] as const
const PRESET_ROWS = [PRESETS.slice(0, 3), PRESETS.slice(3, 6), PRESETS.slice(6)] as const
/** The slider's dinars: the last band ("35,000 and above") ends at the rail's end. */
const BUDGET_MAX = 40_000
const BUDGET_STEP = 1_000
const toDinars = (fils: number) => Math.round(fils / 1000)

type Range = [number, number]

export default function ClOnbd05() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const state = useScreenState()
  const saved = usePrototype(s => s.weddingProfile)

  const story = storyProfile.guests
  const savedGuests = saved && saved.guests.women > 0 ? saved.guests : null
  const initialBudget: Range = saved?.venueBudget
    ? [toDinars(saved.venueBudget.min.fils), Math.min(toDinars(saved.venueBudget.max.fils), BUDGET_MAX)]
    : [toDinars(storyProfile.venueBudget.min.fils), toDinars(storyProfile.venueBudget.max.fils)]

  // The demo persona's answers start the form (docs/product/fixtures.md): 350 guests, KD 20,000 to 35,000.
  const [split, setSplit] = useState(state === 'split-guests' || (savedGuests?.men ?? 0) > 0)
  const [guests, setGuests] = useState(savedGuests?.women ?? story.women)
  const [men, setMen] = useState(savedGuests && savedGuests.men > 0 ? savedGuests.men : story.men)
  const [range, setRange] = useState<Range>(initialBudget)
  const [skipGuests, setSkipGuests] = useState(state === 'skipped')
  const [skipBudget, setSkipBudget] = useState(state === 'skipped')

  // The bands, as bare figures: the currency is the section's quiet unit (`KD`). Each band keeps its spoken name (under / range / and above).
  const bands = budgetBands.map(b => {
    const lo = toDinars(b.min.fils)
    const hi = b.max ? toDinars(b.max.fils) : BUDGET_MAX
    const spoken = !b.max
      ? t('clientOnboardingBudgetAbove', { amount: f.money(b.min.fils) })
      : b.min.fils === 0
        ? t('clientOnboardingBudgetUnder', { amount: f.money(b.max.fils) })
        : f.moneyRange(b.min.fils, b.max.fils)
    return { id: b.id, range: [lo, hi] as Range, from: f.integer(lo), to: b.max ? f.integer(hi) : null, spoken }
  })
  const activeBand = bands.find(b => b.range[0] === range[0] && b.range[1] === range[1])?.id ?? null
  const currency = f.moneyParts(0).currency

  // The Brief's count is the ladies' (or the single) count: it is also what the per-guest figure and the histogram are for.
  const briefGuests = skipGuests ? null : guests

  // `35,000+` with the currency on the side the language puts it: built from the formatter's parts, never typed.
  const money = (dinars: number, openEnd = false): string => {
    if (!openEnd) return f.money(dinars * 1000)
    const p = f.moneyParts(dinars * 1000)
    return f.lang === 'ar' ? `${p.integer}+ ${p.currency}` : `${p.currency} ${p.integer}+`
  }

  const perGuest =
    briefGuests && !skipBudget
      ? f.moneyRange(Math.round((range[0] * 1000) / briefGuests / 1000) * 1000, Math.round((range[1] * 1000) / briefGuests / 1000) * 1000)
      : null

  // The bands are one rail; the chosen band is brought to the middle of it (on arrival and when the slider lands on a band).
  const rail = useRef<HTMLDivElement>(null)
  const settled = useRef(false)
  useEffect(() => {
    const box = rail.current
    const chip = box?.querySelector<HTMLElement>('[aria-pressed="true"]')
    if (!box || !chip) return
    const k = layoutScale(box)
    const b = box.getBoundingClientRect()
    const r = chip.getBoundingClientRect()
    const delta = (r.left - b.left - (b.width - r.width) / 2) / k
    const smooth = settled.current && !window.matchMedia('(prefers-reduced-motion: reduce)').matches
    box.scrollTo({ left: box.scrollLeft + delta, behavior: smooth ? 'smooth' : 'auto' })
    settled.current = true
  }, [activeBand, skipBudget])

  const next = () => nav.push('CL-ONBD-06')
  const confirm = () => {
    commitGuestsBudget({
      women: skipGuests ? 0 : guests,
      men: skipGuests || !split ? 0 : men,
      budget: skipBudget ? null : { min: fils(range[0] * 1000), max: fils(range[1] * 1000) },
    })
    next()
  }

  const later = (set: (v: boolean) => void) => (
    <Button variant="tertiary" onClick={() => set(true)}>
      {t('clientOnboardingSkipHalf')}
    </Button>
  )
  // What a put-off question leaves: a drawing, its one word, and the way back in. Nothing is lost by putting it off.
  const putOff = (set: (v: boolean) => void) => (
    <IconListRow
      flush
      last
      illustration="hourglass"
      title={t('clientOnboardingSkipHalf')}
      trailing={
        <Button variant="secondary" size="sm" onClick={() => set(false)}>
          {c('commonActionAdd')}
        </Button>
      }
    />
  )

  // The whole split row is the target, the switch included once (a click on the switch is the switch's own).
  const toggleSplit = (e: MouseEvent) => {
    if ((e.target as HTMLElement).closest('button')) return
    setSplit(s => !s)
  }
  const who = (glyph: 'section-women' | 'section-men', label: string) => (
    <span className="obd-who">
      <Icon name={glyph} size="md" />
      <span className="gz-sr-only">{label}</span>
    </span>
  )
  const spokenGuests = (n: number) => f.guests(n)

  return (
    <Screen top={<StepBar step={3} total={4} onSkip={next} />} bottom={<ActionBar action={{ label: c('commonActionContinue'), onPress: confirm }} />}>
      <div className="obd-form obd-guests">
        <h1 className="gz-sr-only">{t('clientOnboardingGuestsTitle')}</h1>

        <FormSection title={t('clientOnboardingGuestsSection')} icon="users-three" action={skipGuests ? null : later(setSkipGuests)}>
          {skipGuests ? (
            putOff(setSkipGuests)
          ) : (
            <>
              {split ? (
                <div className="obd-guests__split">
                  <Stepper label={who('section-women', t('clientOnboardingGuestsLadies'))} value={guests} onChange={setGuests} min={GUEST_MIN} max={GUEST_MAX} step={GUEST_STEP} valueText={spokenGuests} />
                  <Stepper label={who('section-men', t('clientOnboardingGuestsMen'))} value={men} onChange={setMen} min={GUEST_MIN} max={GUEST_MAX} step={GUEST_STEP} valueText={spokenGuests} />
                </div>
              ) : (
                <>
                  <Stepper
                    className="obd-guests__hero"
                    label={<span className="gz-sr-only">{t('clientOnboardingGuestsExpected')}</span>}
                    value={guests}
                    onChange={setGuests}
                    min={GUEST_MIN}
                    max={GUEST_MAX}
                    step={GUEST_STEP}
                    valueText={spokenGuests}
                  />
                  <div className="obd-presets" role="group" aria-label={t('clientOnboardingGuestsPresets')}>
                    {PRESET_ROWS.map((row, i) => (
                      <div className="obd-presets__row" key={i}>
                        {row.map(n => (
                          <Chip key={n} className="obd-presets__chip" selected={guests === n} onClick={() => setGuests(n)}>
                            <Fig>{n === 1000 ? t('clientOnboardingGuestsPresetMax', { count: f.integer(n) }) : f.integer(n)}</Fig>
                          </Chip>
                        ))}
                      </div>
                    ))}
                  </div>
                </>
              )}
              {/* The split: the two section glyphs (the glyph is the value) and a switch; the sentence is the switch's accessible name. */}
              <div className="obd-split" onClick={toggleSplit}>
                <span className="obd-split__glyphs" aria-hidden="true">
                  <Icon name="section-women" size="md" />
                  <Icon name="section-men" size="md" />
                </span>
                <span className="obd-split__title gz-t-body">{t('clientOnboardingGuestsSplitTitle')}</span>
                <Switch label={t('clientOnboardingGuestsSplitLabel')} checked={split} onChange={setSplit} />
              </div>
            </>
          )}
        </FormSection>

        <FormSection title={t('clientOnboardingBudgetSection')} icon="coins" unit={currency} action={skipBudget ? null : later(setSkipBudget)}>
          {skipBudget ? (
            putOff(setSkipBudget)
          ) : (
            <>
              <div ref={rail} className="obd-bands gz-no-scrollbar" role="group" aria-label={t('clientOnboardingBudgetBands')}>
                {bands.map(b => (
                  <Chip key={b.id} className="obd-bands__chip" selected={activeBand === b.id} onClick={() => setRange(b.range)}>
                    <span className="obd-band">
                      <Fig>{b.to === null ? t('clientOnboardingGuestsPresetMax', { count: b.from }) : b.from}</Fig>
                      {b.to !== null ? (
                        <>
                          <span className="obd-band__dash" aria-hidden="true">
                            –
                          </span>
                          <Fig>{b.to}</Fig>
                        </>
                      ) : null}
                    </span>
                  </Chip>
                ))}
              </div>
              <div className="obd-slider">
                <PriceHistogram min={0} max={BUDGET_MAX} range={range} guests={briefGuests} />
                <RangeSlider
                  label={t('clientOnboardingBudgetRange')}
                  min={0}
                  max={BUDGET_MAX}
                  step={BUDGET_STEP}
                  minGap={BUDGET_STEP}
                  value={range}
                  onChange={setRange}
                  captions={null}
                  formatValue={(n, edge) => <Figures text={money(n, edge === 'max' && n === BUDGET_MAX)} />}
                  valueText={(n, edge) => (edge === 'max' && n === BUDGET_MAX ? t('clientOnboardingBudgetAbove', { amount: money(n) }) : money(n))}
                />
              </div>
              {perGuest ? <FactChip icon="per-guest" label={c('commonUnitPerGuest')} value={perGuest} /> : null}
            </>
          )}
        </FormSection>
      </div>
    </Screen>
  )
}
