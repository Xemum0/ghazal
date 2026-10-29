// The partner application (PA-ACC-07, PA-ACC-08, ADR 0038): a service provider or a private hall applies from HL-PROV-01; Ghazal staff accept or
// reject it in the Super Admin web (out of scope); only an accepted account can create listings. This file is the prototype's stand-in for that
// round trip: the form the person sent, the status, and the staff decision. Staff decisions are played by the prototype-only tray of HL-ACCS-04
// (the same pattern as the moderator tray of HL-PROV-06). A static frame never writes it; `none` means "no application in this session" and is
// treated like an accepted account (the seeded partners), so nothing else in the app changes.
// Signed out (round 2b): the form is also how the account is made. Submit holds it as `pending` (the account exists, the email is not yet verified);
// the email code of HL-ACCS-02 confirms it, and only then it becomes the application under review.
import { create } from 'zustand'
import { clock, getProvider, getVenue, personaFor, users } from '../../../../mock'
import type { Bilingual, ServiceCategoryId } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { PROVIDER_ID } from './model'

/** Provider and private hall apply with this form; a hotel or a hall chain is onboarded by Ghazal as before (ADR 0038 D3). */
export type ApplicantKind = 'service_provider' | 'private_hall'

export type ApplicationForm = {
  kind: ApplicantKind
  nameAr: string
  nameEn: string
  /** Up to three registered categories (providers only). */
  cats: ServiceCategoryId[]
  /** The open "Other / not in the list" note: staff add the category or reject (PA-ACC-08). */
  otherNote: string
  /** A governorate id from the reference data. */
  gov: string | null
  contact: string
  /** The 8 digits after +965. */
  phone: string
  email: string
  about: string
  /** Optional commercial licence reference (OQ-R2-03). */
  licence: string
}

export const MAX_CATEGORIES = 3
export const ABOUT_MAX = 240

export type ApplicationStatus = 'none' | 'under_review' | 'rejected' | 'approved'
export type ApplicationReason = 'missing_details' | 'cannot_verify' | 'category_unavailable'

export const BLANK_FORM: ApplicationForm = { kind: 'service_provider', nameAr: '', nameEn: '', cats: [], otherNote: '', gov: null, contact: '', phone: '', email: '', about: '', licence: '' }

/** Which fields stop a submit. A provider needs a category or an "Other" note; a private hall needs neither. */
export function missingOf(f: ApplicationForm) {
  return {
    nameAr: f.nameAr.trim() === '',
    nameEn: f.nameEn.trim() === '',
    cats: f.kind === 'service_provider' && f.cats.length === 0 && f.otherNote.trim() === '',
    gov: f.gov === null,
    contact: f.contact.trim() === '',
    phone: f.phone.length !== 8,
    email: !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(f.email.trim()),
    about: f.about.trim() === '',
  }
}
export const isComplete = (f: ApplicationForm): boolean => !Object.values(missingOf(f)).some(Boolean)

// ---------------------------------------------------------------- demo content (fixtures only)

const persona = personaFor('service_provider')
const user = users.find(u => u.id === persona?.userId)
const zahra = getProvider(PROVIDER_ID)
const hall = getVenue('V17')
const PHONE = (persona?.phone ?? '+96550000047').replace('+965', '')

/** Zahra Floral Studio (the demo provider of the shared story), filled in. */
export const demoProviderForm = (lang: 'en' | 'ar'): ApplicationForm => ({
  kind: 'service_provider',
  nameAr: zahra?.name.ar ?? '',
  nameEn: zahra?.name.en ?? '',
  cats: ['flowers'],
  otherNote: '',
  gov: zahra?.governorateId ?? null,
  contact: lang === 'ar' ? (user?.name ?? '') : (user?.nameLatin ?? ''),
  phone: PHONE,
  email: 'zahra@zahra-floral.example',
  about: zahra?.about[lang] ?? '',
  licence: '',
})

/** A private hall applying (a fixture hall stands in for the business). */
export const demoHallForm = (lang: 'en' | 'ar'): ApplicationForm => ({
  kind: 'private_hall',
  nameAr: hall?.name.ar ?? '',
  nameEn: hall?.name.en ?? '',
  cats: [],
  otherNote: '',
  gov: hall?.governorateId ?? null,
  contact: lang === 'ar' ? (user?.name ?? '') : (user?.nameLatin ?? ''),
  phone: PHONE,
  email: 'office@taima-hall.example',
  about: hall?.tagline[lang] ?? '',
  licence: '',
})

/** What a rejected frame shows when nothing was decided in the session (static frames). */
export const DEMO_REASONS: ApplicationReason[] = ['missing_details', 'cannot_verify']

/** The business name in the viewer's language, from what was applied for. */
export const nameOfForm = (f: Pick<ApplicationForm, 'nameAr' | 'nameEn'>): Bilingual => ({ en: f.nameEn || f.nameAr, ar: f.nameAr || f.nameEn })

// ---------------------------------------------------------------- the prototype store

type AppState = {
  status: ApplicationStatus
  form: ApplicationForm | null
  /** A signed-out applicant's form, waiting for the email code (PA-ACC-07, round 2b). Never a status: nothing is under review until the email is verified. */
  pending: ApplicationForm | null
  submittedAt: string | null
  decidedAt: string | null
  reasons: ApplicationReason[]
  /** The staff note, written in the language the viewer used when the decision was played. */
  note: string
  submit: (form: ApplicationForm) => void
  setPending: (form: ApplicationForm | null) => void
  /** The email code was right: the held form becomes the application under review. */
  confirmPending: () => void
  approve: () => void
  reject: (reasons: ApplicationReason[], note: string) => void
  reset: () => void
}

const initial = () => ({ status: 'none' as ApplicationStatus, form: null, pending: null, submittedAt: null, decidedAt: null, reasons: [] as ApplicationReason[], note: '' })

export const useApplication = create<AppState>(set => ({
  ...initial(),
  submit: form => set({ status: 'under_review', form, pending: null, submittedAt: clock.now(), decidedAt: null, reasons: [], note: '' }),
  setPending: pending => set({ pending }),
  confirmPending: () =>
    set(s => (s.pending ? { status: 'under_review', form: s.pending, pending: null, submittedAt: clock.now(), decidedAt: null, reasons: [], note: '' } : {})),
  approve: () => set({ status: 'approved', decidedAt: clock.now(), reasons: [], note: '' }),
  reject: (reasons, note) => set({ status: 'rejected', decidedAt: clock.now(), reasons, note }),
  reset: () => set(initial()),
}))

/** Only an accepted account creates listings (PA-ACC-07): an application that is still open or was rejected holds the editor back. */
export const blocksListings = (s: ApplicationStatus): boolean => s === 'under_review' || s === 'rejected'

// "Restart" in the launcher re-seeds the prototype store (a new hotelBookings copy while the session is a guest): the next story starts clean.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && state.hotelBookings !== prev.hotelBookings) useApplication.getState().reset()
})
