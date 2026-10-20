// Small pieces shared by the five Settings screens: the translators, user text in its own script, the staff view (fixtures + what was
// changed in this session), the step-up round trip to the Verify screen and the one sheet anatomy of the flow (text diet: a title row and
// the content, no sub-line).
import { useContext, useEffect, useMemo, useRef, type CSSProperties, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { clock, engine, hotelSettings, hotelStaff, partnerFor, personaFor, PROTOTYPE_NOW, type HotelStaff } from '../../../../mock'
import { useT } from '../../../../i18n'
import { LayerActiveContext, useDevice } from '../../../../shell/device/context'
import { FrameContext } from '../../../../shell/frame'
import { BarButton, Fig, Figures, useBi, useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { useAccessFlow } from '../../access/_components/flow'
import { useProv } from '../../provider/_components/store'
import { billingOf, planListing, type Account, type Billing } from './model'
import { STEP_UP_MS, useSettingsLocal, VENUE_ID, type PendingAction, type Pending } from './store'
import './settings.css'

export { Fig, Figures, useBi, VENUE_ID }

export function useWords() {
  const t = useT('hotel-settings')
  const c = useT('common')
  return { t, c }
}

/** The script of a piece of user text (a name): `ar` when it has Arabic letters, otherwise `en`. */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/** User-typed text with its own script and direction (ADR 0014 D8): the role class sits on the element that carries `lang`. */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }): ReactNode {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

// ---------------------------------------------------------------- the staff view

export type StaffState = 'active' | 'invited' | 'expired' | 'deactivated'
export type StaffEntry = { person: HotelStaff; state: StaffState; canAccept: boolean; owner: boolean }

/** The team as it stands: fixtures with this session's changes applied, then the people invited in this session. */
export function useStaff(forceExpired = false, viewer: 'admin' | 'manager' = 'admin'): StaffEntry[] {
  const youId = viewer === 'manager' ? 'staff-hind' : 'staff-khalid'
  const overrides = useSettingsLocal(s => s.staffOverrides)
  const invited = useSettingsLocal(s => s.invited)
  return useMemo(() => {
    const now = Date.parse(PROTOTYPE_NOW)
    const base = hotelStaff.filter(s => s.venueId === VENUE_ID)
    return [...base, ...invited].flatMap<StaffEntry>(fixture => {
      const o = overrides[fixture.id] ?? {}
      if (o.removed) return []
      const person: HotelStaff = { ...fixture, isYou: fixture.id === youId, role: o.role ?? fixture.role, status: o.status ?? fixture.status, inviteExpiresAt: o.inviteExpiresAt ?? fixture.inviteExpiresAt }
      if (o.role) {
        const model = hotelStaff.find(s => s.role === o.role)
        if (model) {
          person.roleLabel = model.roleLabel
          person.roleSummary = model.roleSummary
        }
      }
      const lapsed = person.status === 'invited' && person.inviteExpiresAt !== null && Date.parse(person.inviteExpiresAt) < now
      const expired = person.status === 'invited' && !o.inviteExpiresAt && (lapsed || (forceExpired && fixture.id === 'staff-sara'))
      const state: StaffState = person.status === 'invited' ? (expired ? 'expired' : 'invited') : person.status === 'deactivated' ? 'deactivated' : 'active'
      return [{ person, state, canAccept: o.canAccept ?? true, owner: fixture.role === 'admin' }]
    })
  }, [overrides, invited, forceExpired, youId])
}

// ---------------------------------------------------------------- step-up (ADR 0028 D6)

type StepUpName = 'invite' | 'remove'
const stepUpName = (a: PendingAction): StepUpName => (a.kind === 'remove' ? 'remove' : 'invite')

/**
 * Ask for the fresh WhatsApp code before a high-risk staff change: a short dialog says why, then the Verify screen (HL-ACCS-02) opens in
 * step-up mode and pops back here. A confirmation lasts five minutes, so a second action in a row runs straight away.
 */
export function useStepUp(screen: Pending['screen']) {
  const nav = useNav()
  const { t, c } = useWords()
  return async (action: PendingAction, run: (action: PendingAction) => void): Promise<void> => {
    if (performance.now() < useSettingsLocal.getState().stepUpUntil) {
      run(action)
      return
    }
    const result = await nav.openDialog({
      title: t('hotelSettingsStepUpTitle'),
      body: t('hotelSettingsStepUpBodyStaff'),
      icon: 'lock',
      confirmLabel: t('hotelSettingsStepUpSend'),
      cancelLabel: c('commonActionCancel'),
    })
    if (result !== 'confirm') return
    useSettingsLocal.getState().beginStepUp(screen, action)
    nav.push('HL-ACCS-02', { mode: 'step-up', action: stepUpName(action), onVerified: () => useSettingsLocal.getState().markVerified() })
  }
}

/**
 * The asking screen runs the action when it is on top again. The Verify screen pops on success and on Back alike, so a return is
 * counted as confirmed when the Verify screen reported it (`onVerified`) or when the person spent long enough on it to have entered
 * the code; a quick Back cancels. (Request filed: the Verify screen should call `params.onVerified`.)
 */
export function useStepUpResume(screen: Pending['screen'], run: (action: PendingAction) => void) {
  const active = useContext(LayerActiveContext)
  const pending = useSettingsLocal(s => s.pending)
  const left = useRef(false)
  const runRef = useRef(run)
  runRef.current = run
  useEffect(() => {
    if (!pending || pending.screen !== screen) {
      left.current = false
      return
    }
    if (!active) {
      left.current = true
      return
    }
    if (!left.current) return
    left.current = false
    const done = pending.verified || performance.now() - pending.startedAt > 2500
    useSettingsLocal.getState().clearPending()
    if (!done) return
    useSettingsLocal.setState({ stepUpUntil: performance.now() + STEP_UP_MS })
    runRef.current(pending.action)
  }, [active, pending, screen])
}

// ---------------------------------------------------------------- sheet anatomy

export type SheetFrameProps = {
  title: ReactNode
  children?: ReactNode
  footer?: ReactNode
  onClose?: () => void
}

/**
 * The anatomy of every sheet here: a title row (ui-title, close at inline-end, 48), the scrolling body and a pinned footer under a
 * hairline. It draws its own header, so the sheet is opened without a `title` option.
 */
export function SheetFrame({ title, children, footer, onClose }: SheetFrameProps) {
  const { c } = useWords()
  const nav = useNav()
  const { height, safeBottom } = useDevice()
  const maxHeight = Math.floor((height * 0.9) / 4) * 4 - flat['space.sheet-pad-top'] - flat['space.5'] - safeBottom - flat['space.sheet-pad-bottom']
  return (
    <div className="hs-sheet" data-gz="SettingsSheet" style={{ maxBlockSize: maxHeight } as CSSProperties}>
      <div className="hs-sheet__head">
        <div className="hs-sheet__titles">
          <h2 className="hs-sheet__title gz-t-ui-title">{title}</h2>
        </div>
        <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </div>
      <div className="hs-sheet__content gz-no-scrollbar">{children}</div>
      {footer ? <div className="hs-sheet__foot">{footer}</div> : null}
    </div>
  )
}

// ---------------------------------------------------------------- whose settings these are (ADR 0033 D7)

const PROVIDER_PERSONA = personaFor('service_provider')
/** The provider the demo service-provider account runs (Zahra Floral Studio). */
export const PROVIDER_ID: string = partnerFor(PROVIDER_PERSONA?.partnerAccountId ?? '')?.providerId ?? 'vendor-flowers-zahra'
const HOTEL_PERSONA = personaFor('hotel_non_major')
export const NON_MAJOR_NAME = partnerFor(HOTEL_PERSONA?.partnerAccountId ?? '')?.name ?? { en: 'Lumi Marina Hotel', ar: 'فندق لومي مارينا' }
const PROVIDER_NAME = partnerFor(PROVIDER_PERSONA?.partnerAccountId ?? '')?.name ?? { en: 'Zahra Floral Studio', ar: 'استوديو زهرة للزهور' }
export { PROVIDER_NAME }

/**
 * The account a frame or the live prototype draws. A frame says it with `?state=` (`role-provider`, `hotel-with-plan`, anything else is the
 * demo major hotel) or with `account` in the route params; the live prototype knows it from the sign-in (the service-provider persona, or
 * the account type chosen on HL-PROV-01: a hotel that signed up as a partner is not a major hotel and pays like any other).
 */
export function useAccount(): Account {
  const frame = useContext(FrameContext)
  const live = useDevice().mode === 'live'
  const nav = useNav()
  const signedAsProvider = useAccessFlow(s => s.provider)
  const viewer = useProv(s => s.viewer)
  const state = frame?.state
  const param = nav.params.account
  if (state === 'role-provider' || state === 'provider' || param === 'provider') return { type: 'provider', major: false }
  if (state === 'hotel-with-plan' || state === 'plan-expiring' || state === 'receipts' || param === 'hotel') return { type: 'venue', major: false }
  if (state === 'fee-exempt-badge' || state === 'fee-exempt-major-hotel' || param === 'major' || param === 'venue') return { type: 'venue', major: true }
  // The player wraps every screen in a frame context too, so only a static frame (not the live prototype) is the demo hotel.
  if (frame && !live) return { type: 'venue', major: true }
  if (signedAsProvider && viewer === 'provider') return { type: 'provider', major: false }
  return { type: 'venue', major: !signedAsProvider }
}

/** Where the plan stands today: a provider's from its listings, a hotel's from the account (a major hotel has none, it is exempt). */
export function useBilling(account: Account, stateOverride?: string): Billing {
  const listings = usePrototype(s => s.listings)
  return useMemo(() => {
    const today = clock.today()
    const mine = account.type === 'provider' ? listings.filter(l => l.providerId === PROVIDER_ID) : []
    const needsChanges = mine.some(l => l.status === 'rejected')
    const live = planListing(mine)
    const days = (iso: string | null) => (iso ? engine.diffDays(today, iso) : null)
    const sample = (cycle: 'weekly' | 'monthly' | 'annual', left: number): Billing => {
      const endsOn = engine.addDays(today, left)
      return billingOf({ major: false, cycle, endsOn, daysLeft: left, ended: left < 0, needsChanges })
    }
    switch (stateOverride) {
      case 'plan-active':
      case 'receipts':
      case 'hotel-with-plan':
        return sample('monthly', 29)
      case 'plan-expiring':
        return sample('monthly', 5)
      case 'plan-expired':
        return sample('monthly', -3)
      case 'no-plan':
      case 'rates-not-announced':
        return billingOf({ major: false, cycle: null, endsOn: null, daysLeft: null, ended: false, needsChanges: false })
      case 'fee-exempt-major-hotel':
        return billingOf({ major: true, cycle: null, endsOn: null, daysLeft: null, ended: false, needsChanges: false })
      default:
    }
    if (account.major) return billingOf({ major: true, cycle: null, endsOn: null, daysLeft: null, ended: false, needsChanges })
    if (account.type === 'provider') {
      return billingOf({ major: false, cycle: live?.planCycle ?? null, endsOn: live?.endsOn ?? null, daysLeft: days(live?.endsOn ?? null), ended: live?.status === 'expired', needsChanges })
    }
    const plan = hotelSettings.billing.plan
    return billingOf({ major: false, cycle: plan.cycle, endsOn: plan.endsOn, daysLeft: days(plan.endsOn), ended: false, needsChanges })
  }, [account.type, account.major, listings, stateOverride])
}
