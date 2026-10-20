// CL-PROF-02 Wedding info. Requirements: CA-PROF-02, CA-ONB-07, CA-ONB-09, CA-ONB-03, CA-ONB-04, CA-ONB-05, CA-ONB-06, CA-TOOL-17.
//
// The wedding file, viewable and editable at any time, text-diet edition (ADR 0034): rings and the days to go as a figure on top, then one
// glyph row per answer (role, date, guests with the women and men symbols, venue budget, areas) and the two name fields. Every field is
// optional. Dates, areas and budget open the SAME pickers as the Brief (CL-DISC-02), so a couple answers each question the same way
// wherever they meet it. Autosave per field with a quiet "Saved" toast, no Save button. An edit writes the profile and the part of the
// Brief it feeds: the countdown, the budget and the recommendations follow. If a booking sits on another date, a strip names the hotel and
// the date and offers "Use date". The Brief budget and the total wedding budget are different numbers: the second lives in My Wedding.
// States: default, editing, saving, date-differs-from-booking, error, offline.
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Banner, Button, FactChip, FactRow, Figures, Icon, IconListRow, IconStat, Illustration, Screen, TextField, TopBar, useBi, useNav } from '../../../system'
import { getArea, getVenue } from '../../../mock'
import { Mixed, PickRow } from './_components/parts'
import { useLive, useSceneState, useStoryBooking } from './_components/useProfile'
import { WeddingSheet, type WeddingField } from './_components/WeddingSheets'
import { BUDGET_CEILING_FILS, commitWedding, useWeddingProfile } from './_components/wedding'
import './CL-PROF-02.css'

export const states = ['editing', 'saving', 'date-differs-from-booking', 'error', 'offline']

const ROLE_ICON: Record<'bride' | 'groom' | 'family' | 'planner', IconName> = { bride: 'dress', groom: 'groom', family: 'team', planner: 'clipboard' }

export default function WeddingInfo() {
  const t = useT('client-profile')
  const d = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const bi = useBi()
  const { lang } = useLang()
  const state = useSceneState()
  const live = useLive()
  const profile = useWeddingProfile()
  const { booking } = useStoryBooking()

  const offline = state === 'offline'
  const [name, setName] = useState(profile.name)
  const [partner, setPartner] = useState(profile.partnerName ?? '')

  const saved = () => nav.toast({ message: c('commonStateSaved'), icon: 'check' })
  const open = (field: WeddingField) => nav.openSheet(<WeddingSheet field={field} profile={profile} onSaved={saved} />)

  // A name is saved when its field is left (autosave per field).
  const saveName = () => {
    if (name.trim() === profile.name) return
    commitWedding({ name: name.trim() })
    saved()
  }
  const savePartner = () => {
    const next = partner.trim() || null
    if (next === profile.partnerName) return
    commitWedding({ partnerName: next })
    saved()
  }

  // ------------------------------------------------------------ what each row says
  const none = c('commonLabelNotDecided')
  const exact = profile.weddingDate && profile.dateMode === 'exact'
  const hijri = exact && profile.weddingDate ? f.dateWithHijri(profile.weddingDate) : null
  const dateValue = profile.weddingDate ? (exact ? f.date(profile.weddingDate, 'full') : f.date(profile.weddingDate, 'monthYear')) : none
  const { women, men } = profile.guests
  const budget = profile.venueBudget
  const budgetValue = budget
    ? budget.max.fils >= BUDGET_CEILING_FILS
      ? d('clientDiscoverBriefBudgetOver', { amount: f.money(budget.min.fils, { mode: 'browse' }) })
      : f.moneyRange(budget.min.fils, budget.max.fils, { mode: 'browse' })
    : none
  const areaNames = profile.areaIds.map(id => getArea(id)).filter((a): a is NonNullable<ReturnType<typeof getArea>> => Boolean(a)).map(a => bi(a.name))
  const areasValue = areaNames.length > 0 ? areaNames.join(lang === 'ar' ? '، ' : ', ') : none
  const partnerLabel =
    profile.role === 'bride' ? t('clientProfileWedPartnerGroom') : profile.role === 'groom' ? t('clientProfileWedPartnerBride') : profile.role === 'family' || profile.role === 'planner' ? t('clientProfileWedPartnerCouple') : t('clientProfileWedPartnerDefault')
  const roleValue: Record<typeof profile.role, string> = {
    bride: t('clientProfileWedRoleBride'),
    groom: t('clientProfileWedRoleGroom'),
    family: t('clientProfileWedRoleFamily'),
    planner: t('clientProfileWedRolePlanner'),
  }
  const daysToGo = profile.weddingDate ? f.daysUntil(profile.weddingDate) : 0

  // A booking on another date than the wedding file (a static frame says so by its state).
  const bookingDate = booking?.eventDate ?? null
  const differs = state === 'date-differs-from-booking' || (live && bookingDate !== null && profile.weddingDate !== null && bookingDate !== profile.weddingDate)
  const venueName = booking?.venueId ? (getVenue(booking.venueId)?.name[lang] ?? '') : ''
  const applyBookingDate = () => {
    if (!bookingDate) return
    commitWedding({ weddingDate: bookingDate, dateMode: 'exact' })
    nav.toast({ message: t('clientProfileWedDateUpdated'), tone: 'success' })
  }

  return (
    <Screen top={<TopBar title={t('clientProfileWedTitle')} />}>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-wed" data-gz-id="wedding.info">
        <div className="gzpr-pad gzpr-wed__head">
          <Illustration name="rings" size="md" />
          {daysToGo > 0 ? <IconStat layout="inline" icon="countdown" value={f.integer(daysToGo)} unit={t('clientProfileWedDaysUnit', { count: daysToGo })} label={t('clientProfileWedCountdown')} tone="accent" /> : null}
        </div>

        {differs && bookingDate ? (
          <div className="gzpr-pad">
            <div className="gzpr-wed__strip" role="status" data-gz="BookingDateStrip">
              <div className="gzpr-wed__venue">
                <Icon name="hotel" size="sm" tone="secondary" />
                <bdi dir="auto" className="gz-t-body">
                  {venueName}
                </bdi>
              </div>
              <div className="gzpr-wed__use">
                <FactChip icon="calendar" value={<Mixed>{f.date(bookingDate, 'full')}</Mixed>} label={t('clientProfileWedDate')} />
                <Button variant="tertiary" onClick={applyBookingDate}>
                  {t('clientProfileWedDiffersAction')}
                </Button>
              </div>
            </div>
          </div>
        ) : null}
        {state === 'error' ? (
          <Banner tone="danger" action={{ label: c('commonActionRetry'), onPress: () => nav.replace('CL-PROF-02') }}>
            {t('clientProfileSharedSaveFailed')}
          </Banner>
        ) : null}

        <div className="gzpr-list">
          <PickRow icon={ROLE_ICON[profile.role]} label={t('clientProfileWedRole')} onClick={() => open('role')} disabled={offline} last>
            {roleValue[profile.role]}
          </PickRow>
        </div>

        <div className="gzpr-pad gzpr-wed__fields">
          <TextField
            label={t('clientProfileWedName')}
            value={name}
            onValueChange={setName}
            onBlur={saveName}
            autoComplete="name"
            enterKeyHint="next"
            disabled={offline}
            forceFocus={state === 'editing'}
          />
          <TextField
            label={partnerLabel}
            value={partner}
            onValueChange={setPartner}
            onBlur={savePartner}
            enterKeyHint="done"
            disabled={offline}
            loading={state === 'saving'}
          />
        </div>

        <div className="gzpr-list">
          <PickRow icon="calendar" label={t('clientProfileWedDate')} sub={hijri?.secondary ?? undefined} empty={!profile.weddingDate} onClick={() => open('date')} disabled={offline}>
            {dateValue}
          </PickRow>
          <PickRow icon="guests" label={t('clientProfileWedGuests')} empty={women + men === 0} onClick={() => open('guests')} disabled={offline}>
            {women + men > 0 ? (
              <FactRow>
                {women > 0 ? <FactChip icon="section-women" value={f.integer(women)} label={t('clientProfileWedLadies')} /> : null}
                {men > 0 ? <FactChip icon="section-men" value={f.integer(men)} label={t('clientProfileWedMen')} /> : null}
              </FactRow>
            ) : (
              none
            )}
          </PickRow>
          <PickRow icon="coins" label={t('clientProfileWedBudget')} empty={!budget} onClick={() => open('budget')} disabled={offline}>
            {budgetValue}
          </PickRow>
          <PickRow icon="pin" label={t('clientProfileWedAreas')} empty={areaNames.length === 0} onClick={() => open('areas')} disabled={offline}>
            {areasValue}
          </PickRow>
          <IconListRow
            icon="wallet"
            title={t('clientProfileWedTotal')}
            trailing={profile.totalBudget ? <span className="gzpr-quiet gz-t-fig-body"><Mixed>
                <Figures text={f.money(profile.totalBudget.fils, { mode: 'browse' })} />
              </Mixed></span> : undefined}
            chevron
            onClick={() => nav.push('CL-WEDD-03')}
            last
          />
        </div>
      </div>
    </Screen>
  )
}
