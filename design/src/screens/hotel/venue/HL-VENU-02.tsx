// HL-VENU-02 Packages: what the venue sells. Packages with their two prices per set of days (voucher price and standard price), the pricing
// structure and limits, one-tap active switches, an archive that can be restored, and an honest pointer to the dashboard for the price grids plus
// the door to time-boxed voucher prices (HL-GROW-01). Extras and add-on services are not part of a venue (CA-SVC-19, ADR 0038): no Extras tab,
// no catalogue; a client adds services only by choosing a service provider in the Client app.
// Requirements: HA-VMGT-03, HA-VMGT-04, HA-VMGT-05, HA-VMGT-09, HA-VMGT-11, HA-VMGT-12, HA-AUTH-02, CA-SVC-19 (voucher model, ADR 0033)
// States: loading, empty, error, offline, archived-section.
// Roles: Admin and Manager edit everything; Reception and Accountant never reach this screen (ADR 0008 D12).
import { useState } from 'react'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Button, EmptyState, ErrorState, Icon, ListRow, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { PackageRow } from './_components/Rows'
import { DashboardNote, Figures, OfflineStrip, useV } from './_components/bits'
import { useIsStatic } from './_components/editor'
import { useVenueStore, type PackageModel } from './_components/store'
import { platform, venue } from './_components/venue'
import './HL-VENU-02.css'

export const states = ['loading', 'empty', 'error', 'offline', 'archived-section']

export default function Packages() {
  const { state } = useFrame()
  const nav = useNav()
  const isStatic = useIsStatic()
  const { t, c, bi } = useV()

  const packages = useVenueStore(s => s.packages)
  const order = useVenueStore(s => s.packageOrder)

  const [archivedOpen, setArchivedOpen] = useState(state === 'archived-section')

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  // The frames show the archive from the seed's own inactive package; the live prototype reads what the manager archived.
  const demoArchived = state === 'archived-section' ? 'V01-men-lunch' : null
  const all = order.map(id => packages[id]).filter((m): m is PackageModel => Boolean(m))
  const listed = state === 'empty' ? [] : all.filter(m => !m.archived && m.id !== demoArchived)
  const archived = state === 'empty' ? [] : all.filter(m => m.archived || m.id === demoArchived)
  const name = (m: { nameAr: string; nameEn: string }) => bi({ ar: m.nameAr, en: m.nameEn })

  const openPackage = (id: string) => nav.push('HL-VENU-03', { packageId: id })
  const newPackage = () => nav.push('HL-VENU-03', { packageId: 'new' })

  const setActive = (m: PackageModel, active: boolean) => {
    if (isStatic) return
    useVenueStore.getState().setPackageActive(m.id, active)
    nav.toast({
      message: t(active ? 'hotelVenueToastPkgShown' : 'hotelVenueToastPkgHidden', { name: name(m) }),
      undo: !active,
      action: active ? undefined : { label: c('commonActionUndo'), onPress: () => useVenueStore.getState().setPackageActive(m.id, true) },
    })
  }
  const restore = (m: PackageModel) => {
    if (isStatic) return
    useVenueStore.getState().restorePackage(m.id)
    nav.toast({ message: t('hotelVenueToastRestored', { name: name(m) }), icon: 'check-circle' })
  }

  const top = (
    <>
      <TopBar title={t('hotelVenuePackagesTitle')} subtitle={bi(venue().name)} />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  const showEmpty = listed.length === 0 && archived.length === 0

  let body
  if (loading) {
    body = <ListSkeleton />
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-02')} />
  } else {
    body = (
      <div className="hv-list">
        {showEmpty ? (
          <div className="hv-list__pad">
            <EmptyState fill={false} illustration="empty-listings" title={t('hotelVenuePkgEmptyTitle')} />
          </div>
        ) : (
          <>
            <div className="hv-list__pad hv-list__rows">
              {listed.map((m, i) => (
                <PackageRow key={m.id} m={m} name={name(m)} disabled={offline} onOpen={() => openPackage(m.id)} onActive={a => setActive(m, a)} last={i === listed.length - 1 && archived.length === 0} />
              ))}
            </div>
            {archived.length > 0 ? (
              <div className="hv-list__pad hv-arch">
                <button type="button" className="gz-reset hv-arch__toggle gz-press" aria-expanded={archivedOpen} onClick={() => setArchivedOpen(o => !o)}>
                  <span className="gz-t-body-s">
                    <Figures text={t('hotelVenueArchivedHead', { count: archived.length })} />
                  </span>
                  <Icon name={archivedOpen ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
                </button>
                {archivedOpen
                  ? archived.map(m => (
                      <div key={m.id} className="hv-arch__row">
                        <span className="gz-t-body-s hv-arch__name">
                          <bdi dir="auto">{name(m)}</bdi>
                        </span>
                        <Button variant="tertiary" disabled={offline} onClick={() => restore(m)}>
                          {t('hotelVenueRestore')}
                        </Button>
                      </div>
                    ))
                  : null}
              </div>
            ) : null}
          </>
        )}

        <div className="hv-list__pad hv-list__notes">
          <DashboardNote kind="prices" />
          <ListRow
            flush
            last
            leading={<Icon name="ticket" size="md" />}
            title={t('hotelVenueWindowsRow')}
            chevron
            onClick={() => nav.push('HL-GROW-01')}
          />
        </div>
      </div>
    )
  }

  const bar =
    loading || error ? undefined : (
      <ActionBar
        action={{
          label: t('hotelVenuePkgNew'),
          iconEnd: 'plus',
          disabled: offline,
          reason: offline ? t('hotelVenueNeedsConnection') : undefined,
          onPress: newPackage,
        }}
      />
    )

  return (
    <div className="hv-root">
      <Screen top={top} bottom={bar}>
        {body}
      </Screen>
    </div>
  )
}

function ListSkeleton() {
  return (
    <div className="hv-list" aria-busy="true">
      {[0, 1, 2, 3].map(i => (
        <div key={i} className="hv-list__pad hv-list__skel">
          <Skeleton variant="line" blockSize={24} inlineSize={220} />
          <Skeleton variant="line" blockSize={20} inlineSize={140} />
          <Skeleton variant="line" blockSize={20} inlineSize={180} />
        </div>
      ))}
    </div>
  )
}
