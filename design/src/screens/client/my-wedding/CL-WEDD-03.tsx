// CL-WEDD-03 Budget (pushed from My Wedding; tab bar visible). Requirements: CA-TOOL-05, CA-TOOL-06, CA-TOOL-07, CA-TOOL-08, CA-TOOL-09,
// CA-TOOL-11, CA-ONB-04, CA-AUTH-10.
//
// Committed versus paid versus remaining. What is left is the hero; one segmented bar and its two figures say how the rest divides; categories
// are ranked by what has gone into them, each with its own meter; the voucher and the venue price post themselves to the venue category (read only,
// they open the booking) and the couple's own expenses sit beside them. Alerts are calm: a gold-ink note at 80%, the functional danger
// state at 100%, always a glyph and a figure. Rules, no AI. A guest sees a sample and signs in at the first write.
//
// Text diet (ADR 0034): glyphs, figures and one-word names. No caption, no hint, no sentence; the states are a drawing, three words and one verb.
// The one rule that needs a sentence (the voucher is paid in the app, the venue price to the venue) sits behind the info glyph of Payments.
import { useFormat, useT } from '../../../i18n'
import { ActionBar, Banner, EmptyState, ErrorState, FactChip, Figures, InfoButton, Screen, SectionHeader, Skeleton, TopBar, useNav } from '../../../system'
import { clock } from '../../../mock'
import { BudgetHero } from './_components/BudgetHero'
import { DateText } from './_components/DateText'
import { CategoryRow } from './_components/CategoryRow'
import { LedgerRow } from './_components/LedgerRow'
import { openGuestGate } from './_components/gate'
import { alertOf, usedOf } from './_components/model'
import { useCategoryName } from './_components/names'
import { useBudgetModel, useStateParam, useWedding } from './_components/useWedding'
import './CL-WEDD-03.css'

export const states = ['loading', 'empty-no-budget', 'alert-80', 'over-budget', 'guest-sample', 'offline-read-only', 'error']

export default function Budget() {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const catName = useCategoryName()
  const nav = useNav()
  const state = useStateParam()
  const w = useWedding()
  const variant = state === 'alert-80' ? 'alert-80' : state === 'over-budget' ? 'over-budget' : null
  const model = useBudgetModel(w, variant, state === 'empty-no-budget')

  const guest = w.guest
  const offline = state === 'offline-read-only'
  const empty = model.total === null
  const alert = alertOf(model)

  const gate = () => openGuestGate(nav, 'CL-WEDD-03')
  const addExpense = () => nav.openSheet('CL-WEDD-04')
  const editBudget = () => (guest ? gate() : nav.openSheet('CL-WEDD-05'))

  const top = <TopBar title={t('clientMyWeddingBudgetTitle')} />

  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzmw-bd" aria-busy="true">
          <div className="gzmw-bd__pad gzmw-bd__skel">
            <Skeleton inlineSize={96} blockSize={16} />
            <Skeleton inlineSize={200} blockSize={40} />
            <Skeleton blockSize={8} />
            <Skeleton blockSize={48} />
          </div>
          {Array.from({ length: 5 }, (_, i) => (
            <div key={i} className="gzmw-bd__pad gzmw-bd__skelrow">
              <Skeleton variant="circle" inlineSize={40} />
              <div className="gzmw-bd__skeltext">
                <Skeleton inlineSize={168} blockSize={24} />
                <Skeleton blockSize={4} />
              </div>
            </div>
          ))}
        </div>
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-WEDD-03')} />
      </Screen>
    )
  }
  if (empty) {
    return (
      <Screen top={top}>
        <EmptyState
          illustration="card"
          title={t('clientMyWeddingBudgetEmptyTitle')}
          action={{ label: t('clientMyWeddingBudgetEmptyAction'), variant: 'primary', onPress: editBudget }}
        />
      </Screen>
    )
  }

  // One alert at the top: the category that is over its share, else the one that reached 80%. A total over budget is the hero's own state.
  const alertText = alert
    ? alert.kind === 'over'
      ? t('clientMyWeddingBudgetAlertOver', { category: catName(alert.cat.id, alert.cat.name), amount: f.money(usedOf(alert.cat) - alert.cat.allocated) })
      : t('clientMyWeddingBudgetAlertSoft', {
          category: catName(alert.cat.id, alert.cat.name),
          percent: f.percent(Math.round((usedOf(alert.cat) / alert.cat.allocated) * 100), { maxFraction: 0 }),
        })
    : null

  const openRow = (r: (typeof model.ledger)[number]) => {
    if (r.kind === 'auto' && r.bookingId) return () => nav.push('CL-BKNG-02', { bookingId: r.bookingId })
    if (r.kind === 'manual' && !r.id.startsWith('demo-') && !offline) return () => (guest ? gate() : nav.openSheet('CL-WEDD-04', { params: { expenseId: r.id } }))
    return undefined
  }
  const currency = f.moneyParts(0).currency

  return (
    <Screen
      top={top}
      bottom={
        <ActionBar
          action={{
            label: t('clientMyWeddingBudgetAddExpense'),
            onPress: addExpense,
            disabled: offline,
            reason: offline ? t('clientMyWeddingExpenseOfflineReason') : undefined,
          }}
        />
      }
    >
      {offline ? (
        <Banner tone="offline">
          {c('commonStateOffline')} <FactChip icon="clock" value={<DateText text={f.time(clock.now())} />} label={t('clientMyWeddingUpdated')} size="sm" />
        </Banner>
      ) : null}

      <div className="gzmw-bd" data-gz-id="budget">
        <div className="gzmw-bd__top">
          {guest ? (
            <Banner tone="info" action={{ label: t('clientMyWeddingGuestAction'), onPress: gate }}>
              {t('clientMyWeddingSample')}
            </Banner>
          ) : null}
          <div className="gzmw-bd__pad">
            <BudgetHero model={model} onEdit={offline ? undefined : editBudget} />
          </div>
          {alertText ? (
            <Banner tone={alert?.kind === 'over' ? 'danger' : 'warning'} icon={alert?.kind === 'over' ? undefined : 'info'}>
              <Figures text={alertText} />
            </Banner>
          ) : null}
        </div>

        <section className="gzmw-bd__section" aria-label={t('clientMyWeddingBudgetCategories')} data-gz-id="categories">
          <div className="gzmw-bd__pad">
            <SectionHeader
              title={
                <>
                  {t('clientMyWeddingBudgetCategories')}
                  <span className="gzmw-unit gz-t-caption">{currency}</span>
                </>
              }
              onSeeAll={() => nav.push('CL-SERV-01')}
              seeAllLabel={t('clientMyWeddingToolServices')}
            />
          </div>
          <ul className="gzmw-bd__list">
            {model.cats.map((cat, i) => (
              <CategoryRow key={cat.id} cat={cat} last={i === model.cats.length - 1} />
            ))}
          </ul>
        </section>

        <section className="gzmw-bd__section" aria-label={t('clientMyWeddingBudgetLedger')} data-gz-id="ledger">
          <div className="gzmw-bd__pad">
            <SectionHeader
              title={
                <>
                  {t('clientMyWeddingBudgetLedger')}
                  <InfoButton title={t('clientMyWeddingBudgetInfoTitle')}>{t('clientMyWeddingBudgetInfoBody')}</InfoButton>
                </>
              }
            />
          </div>
          <div className="gzmw-bd__list">
            {model.ledger.map((r, i) => (
              <LedgerRow key={r.id} row={r} categories={model.cats} last={i === model.ledger.length - 1} onOpen={openRow(r)} />
            ))}
          </div>
        </section>
      </div>
    </Screen>
  )
}
