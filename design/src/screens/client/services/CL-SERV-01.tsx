// CL-SERV-01 Services hub (voucher model, ADR 0033; text diet, ADR 0034). Covers CA-SVC-01 to CA-SVC-08, CA-SVC-13, CA-SVC-16, CA-SVC-19, CA-SVC-20, CA-PLAN-02, CA-PLAN-09.
// The five primary categories for post-venue needs (Hospitality and catering, Buffet services, Floral arrangements, Event styling and decor,
// Event planning and coordination) as photograph tiles that carry a category glyph, the providers count and the ticket glyph; then "More"
// (the secondary groups, CA-SVC-16) as illustrated rows (camera, oud, make-up, dress, car, suitcase, cake), the wedding-planner door and the
// saved row. The voucher is one rose strip, a ticket glyph and the KD 2 figure, and the sentence that explains it sits behind its info
// glyph. The Venues | Services switch at the top returns to Home; its selected tab is the title (the bar carries only the back glyph and a
// visually hidden h1 names the page), so "Services" is never said twice. Services are independent of venues (ADR 0038, CA-SVC-19): no venue
// page links here. The footer is the provider note (CA-SVC-20, ProviderNote): "Service provider? Apply in the Partner app". No signed-out
// variant. States: default, loading, error, offline, category-without-vendors.
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Banner, ErrorState, Fig, Figures, Icon, IconListRow, InfoButton, Price, ProviderNote, Screen, SectionHeader, Tabs, TopBar, useBi, useNav } from '../../../system'
import { PlannerEntry } from './_components/PlannerEntry'
import { PrimaryTile } from './_components/PrimaryTile'
import { GROUP_ART, PRIMARY, SECONDARY_ROWS, VOUCHER_FEE_FILS, providerCount, useLive } from './_components/model'
import './CL-SERV-01.css'

export const states = ['loading', 'error', 'offline', 'category-without-vendors']

/** The category the frame with no providers shows (the fixtures have providers everywhere). */
const EMPTY_FRAME_CATEGORY = 'buffet'

export default function ServicesHub() {
  const t = useT('client-services')
  const shell = useT('client-shell')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const { state } = useFrame()
  const live = useLive()
  const savedCount = usePrototype(s => s.favourites.vendor.length)

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'

  const countOf = (id: string) => (state === 'category-without-vendors' && id === EMPTY_FRAME_CATEGORY ? 0 : providerCount(id))

  const goHome = () => {
    if (nav.activeTab === 'discover' && nav.canGoBack) nav.pop()
    else nav.switchTab('discover')
  }
  const openCategory = (categoryId: string) => nav.push('CL-SERV-02', { categoryId })

  const [lead, ...rest] = PRIMARY
  const pairs: (typeof PRIMARY)[number][][] = []
  for (let i = 0; i < rest.length; i += 2) pairs.push(rest.slice(i, i + 2))

  const tile = (category: (typeof PRIMARY)[number], feature = false) => (
    <PrimaryTile
      key={category.id}
      category={category}
      count={countOf(category.id)}
      voucher={countOf(category.id) > 0}
      feature={feature}
      loading={loading}
      onOpen={() => openCategory(category.id)}
    />
  )

  return (
    <Screen top={<TopBar variant="standard" />}>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzs-hub">
        {/* The selected tab of the switch below is the visible title; saying "Services" twice is wordiness (ADR 0034). */}
        <h1 className="gz-sr-only">{t('clientServicesHubTitle')}</h1>
        <div className="gzs-hub__pad">
          <Tabs
            label={t('clientServicesHubSwitchLabel')}
            value="services"
            onChange={v => {
              if (v === 'venues') goHome()
            }}
            items={[
              { value: 'venues', label: shell('clientShellSwitchVenues') },
              { value: 'services', label: shell('clientShellSwitchServices') },
            ]}
          />
        </div>

        {errored ? (
          <div className="gzs-hub__pad">
            <ErrorState kind="load" fill={false} onRetry={() => nav.toast({ message: c('commonStateOffline'), tone: 'danger' })} />
          </div>
        ) : (
          <>
            <div className="gzs-hub__pad">
              <div className="gzs-hub__voucher" data-gz-id="voucher-line">
                <Icon name="ticket" size="md" />
                <span className="gzs-hub__voucher-word gz-t-title">{c('commonVoucher')}</span>
                <Price fils={VOUCHER_FEE_FILS} size="strong" />
                <span className="gzs-hub__voucher-info">
                  <InfoButton title={t('clientServicesHowTitle')} label={t('clientServicesHowTitle')}>
                    <p>
                      <Figures text={t('clientServicesHubVoucherLine', { fee: f.money(VOUCHER_FEE_FILS, { mode: 'browse' }) })} />
                    </p>
                  </InfoButton>
                </span>
              </div>
            </div>

            <section className="gzs-hub__groups gzs-hub__pad" aria-label={t('clientServicesHubGroupsLabel')} data-gz-id="primary">
              {lead ? <div className="gzs-hub__row">{tile(lead, true)}</div> : null}
              {pairs.map(pair => (
                <div key={pair[0]?.id} className="gzs-hub__row">
                  {pair.map(cat => tile(cat))}
                  {pair.length === 1 ? <span className="gzs-hub__spacer" aria-hidden="true" /> : null}
                </div>
              ))}
            </section>

            <section className="gzs-hub__more gzs-hub__pad" data-gz-id="secondary">
              <SectionHeader title={t('clientServicesHubMoreHeading')} draw={live ? 'inview' : 'mount'} />
              <div>
                {SECONDARY_ROWS.map((row, i) => {
                  const single = row.leaves.length === 1 ? row.leaves[0] : undefined
                  const title = single ? bi(single.name) : row.group ? bi(row.group.name) : ''
                  return (
                    <IconListRow
                      key={row.id}
                      flush
                      last={i === SECONDARY_ROWS.length - 1}
                      illustration={GROUP_ART[row.id]}
                      title={title}
                      onClick={() => openCategory(row.leaves[0]!.id)}
                    />
                  )
                })}
              </div>
            </section>

            <section className="gzs-hub__planner gzs-hub__pad" data-gz-id="planner">
              <PlannerEntry loading={loading} onOpen={() => nav.push('CL-PLAN-01', { from: 'services' })} />
            </section>

            <div className="gzs-hub__pad">
              <IconListRow
                flush
                icon="heart"
                title={t('clientServicesHubSavedTitle')}
                trailing={savedCount > 0 ? <Fig>{f.integer(savedCount)}</Fig> : undefined}
                onClick={() => nav.switchTab('saved')}
              />
              <ProviderNote variant="footer" />
            </div>
          </>
        )}
      </div>
    </Screen>
  )
}
