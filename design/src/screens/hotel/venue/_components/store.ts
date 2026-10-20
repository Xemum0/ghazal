// The venue flow's memory: what the manager has saved in this session across the six screens (photos, packages, extras, halls, policy, rules).
// It is flow-local on purpose (the shared prototype store has no venue slice; requested in docs/engineering/requests.md) and holds only
// SAVED values: every editor keeps its own draft and writes here on Save, so leaving without saving never changes anything.
// Money is integer fils, durations are hours or days, ids are fixture ids. Nothing persists past a reload.
import { create } from 'zustand'
import type { AmenityState, Audience, Bilingual, GalleryItem, HallSetting, PricingBasis, VenueType, Weekday } from '../../../../mock'
import {
  SEED_GAPS,
  amenityRows,
  halls,
  libraryPhotos,
  rulesOf,
  venue,
  venueExtras,
  venuePackages,
} from './venue'

// ---------------------------------------------------------------- media

export type PhotoStatus = 'live' | 'review' | 'rejected'
export type PhotoItem = { id: string; image: GalleryItem; status: PhotoStatus; reason?: 'person'; /** The English alt text is still missing (HA-VMGT-09: three photos in the story). */ gapEn?: boolean }
export type VideoItem = { id: string; title: Bilingual; seconds: number; poster: GalleryItem; status: 'live' | 'review' }
export type UploadItem = { id: string; kind: 'photo' | 'video'; label: Bilingual; progress: number; status: 'uploading' | 'failed' | 'queued'; reason?: 'large'; poster: GalleryItem | null }

// ---------------------------------------------------------------- packages and extras

/** One set of days: the standard column and the voucher column on the same basis (both empty = no voucher price). Integer fils. */
export type TierModel = {
  on: boolean
  perGuestFils: number | null
  flatFils: number | null
  voucherPerGuestFils: number | null
  voucherFlatFils: number | null
}
export type PricingStructure = 'per_person' | 'package'
/** `per_guest` is the per-person structure; `flat` and `flat_plus_per_guest` are the two bundled-package bases. */
export const structureOf = (basis: PricingBasis): PricingStructure => (basis === 'per_guest' ? 'per_person' : 'package')
export type PackageModel = {
  id: string
  isNew: boolean
  nameAr: string
  nameEn: string
  descAr: string
  descEn: string
  audiences: Audience[]
  hallIds: string[]
  basis: PricingBasis
  weekday: TierModel
  weekend: TierModel
  minGuests: number
  maxGuests: number
  guestStep: number
  inclusions: Bilingual[]
  active: boolean
  archived: boolean
  /** A bundle (the full night) is priced as the sum of its parts: its prices are read-only here. */
  bundle: boolean
}

export type ExtraUnit = 'event' | 'hour' | 'guest' | 'unit'
export type ExtraModel = {
  id: string
  isNew: boolean
  nameAr: string
  nameEn: string
  descAr: string
  descEn: string
  priceFils: number
  /** Real price range of the seed ("from KD 1,800, up to KD 6,500"); display only. */
  fromFils: number | null
  upToFils: number | null
  unit: ExtraUnit
  unitLabel: Bilingual | null
  active: boolean
}

// ---------------------------------------------------------------- halls

export type SessionModel = { id: string; nameAr: string; nameEn: string; start: string; end: string; bufferBeforeMin: number; bufferAfterMin: number }
export type PhotographyFact = 'female_only' | 'allowed' | 'none'
export type MusicFact = 'dj_or_band' | 'live' | 'duff_only' | 'none'
export type HallModel = {
  id: string
  nameAr: string
  nameEn: string
  capacityMax: number
  minGuests: Record<Audience, number>
  audiences: Audience[]
  setting: HallSetting
  sessions: SessionModel[]
  exclusiveDay: boolean
  amenities: Record<string, AmenityState>
  facts: Partial<Record<Audience, { photography: PhotographyFact; music: MusicFact }>>
}

// ---------------------------------------------------------------- policy and rules

export type ChildrenRule = { limited: boolean; age: number }
export type HoursModel = { id: string; days: Weekday[]; open: string; close: string }
/** The venue's own terms (ADR 0033): free text in each language, shown as written and settled with the client directly, plus the house rules. */
export type PolicyModel = {
  termsAr: string
  termsEn: string
  women: ChildrenRule
  men: ChildrenRule
  dressAr: string
  dressEn: string
  hours: HoursModel[]
}

/** Request mode only. The confirm window (24 hours) is fixed by the owner and is not part of the model. */
export type RulesModel = {
  hallId: string
  responseHours: 12 | 24 | 48
  minNoticeDays: number
}

/** The venue type the partner holds; a change waits for Ghazal to verify it (it drives the client filter). */
export type ProfileModel = { type: VenueType; pending: boolean }

// ---------------------------------------------------------------- seeds

type RuleLike = { perGuest: { fils: number } | null; flat: { fils: number } | null; voucherPerGuest: { fils: number } | null; voucherFlat: { fils: number } | null }
const tierOf = (rule: RuleLike | null): TierModel => ({
  on: rule !== null,
  perGuestFils: rule?.perGuest?.fils ?? null,
  flatFils: rule?.flat?.fils ?? null,
  voucherPerGuestFils: rule?.voucherPerGuest?.fils ?? null,
  voucherFlatFils: rule?.voucherFlat?.fils ?? null,
})

export function seedPackage(id: string): PackageModel | null {
  const pkg = venuePackages().find(p => p.id === id)
  if (!pkg) return null
  const rules = rulesOf(id)
  const gap = SEED_GAPS[id]
  return {
    id,
    isNew: false,
    nameAr: pkg.name.ar,
    nameEn: pkg.name.en,
    descAr: pkg.description.ar,
    descEn: gap?.descEn ? '' : pkg.description.en,
    audiences: [...pkg.audiences],
    hallIds: pkg.hallIds,
    basis: pkg.pricingBasis,
    weekday: tierOf(rules.weekday),
    weekend: tierOf(rules.weekend),
    minGuests: pkg.minGuests,
    maxGuests: pkg.maxGuests,
    guestStep: pkg.guestStep,
    inclusions: pkg.inclusions,
    active: pkg.active,
    archived: false,
    bundle: pkg.components !== null,
  }
}

export function blankPackage(): PackageModel {
  return {
    id: 'new-package',
    isNew: true,
    nameAr: '',
    nameEn: '',
    descAr: '',
    descEn: '',
    audiences: [],
    hallIds: [],
    basis: 'per_guest',
    weekday: { on: true, perGuestFils: null, flatFils: null, voucherPerGuestFils: null, voucherFlatFils: null },
    weekend: { on: true, perGuestFils: null, flatFils: null, voucherPerGuestFils: null, voucherFlatFils: null },
    minGuests: 200,
    maxGuests: 500,
    guestStep: 5,
    inclusions: [],
    active: false,
    archived: false,
    bundle: false,
  }
}

const unitOf = (e: { pricingUnit: string; unitLabel: Bilingual | null }): ExtraUnit =>
  e.pricingUnit === 'per_guest' ? 'guest' : e.pricingUnit === 'flat' ? 'event' : e.unitLabel?.en.includes('hour') ? 'hour' : 'unit'

export function seedExtra(id: string): ExtraModel | null {
  const e = venueExtras().find(x => x.id === id)
  if (!e) return null
  return {
    id,
    isNew: false,
    nameAr: e.name.ar,
    nameEn: e.name.en,
    descAr: e.description.ar,
    descEn: e.description.en,
    priceFils: e.price.fils,
    fromFils: e.priceMin?.fils ?? null,
    upToFils: e.priceMax?.fils ?? null,
    unit: unitOf(e),
    unitLabel: e.unitLabel,
    active: e.active,
  }
}

export function blankExtra(): ExtraModel {
  return { id: 'new-extra', isNew: true, nameAr: '', nameEn: '', descAr: '', descEn: '', priceFils: 0, fromFils: null, upToFils: null, unit: 'event', unitLabel: null, active: true }
}

export function seedHall(id: string): HallModel | null {
  const h = halls().find(x => x.id === id)
  if (!h) return null
  const mins = { women: h.capacity.min, men: h.capacity.min, mixed: h.capacity.min } as Record<Audience, number>
  const facts: HallModel['facts'] = {}
  for (const s of h.sections) {
    mins[s.audience] = s.minGuests
    facts[s.audience] = { photography: s.policy.photography, music: s.policy.music }
  }
  const amenities: Record<string, AmenityState> = {}
  for (const a of amenityRows()) amenities[a.id] = a.state
  return {
    id,
    nameAr: h.name.ar,
    nameEn: h.name.en,
    capacityMax: h.capacity.max,
    minGuests: mins,
    audiences: h.sections.map(s => s.audience),
    setting: h.setting,
    sessions: h.sessions.map(s => ({ id: s.id, nameAr: s.name.ar, nameEn: s.name.en, start: s.start, end: s.end, bufferBeforeMin: s.bufferBeforeMin, bufferAfterMin: s.bufferAfterMin })),
    exclusiveDay: h.exclusiveDay,
    amenities,
    facts,
  }
}

export function seedPolicy(): PolicyModel {
  const v = venue()
  const women = v.halls[0]?.sections.find(sec => sec.audience === 'women')?.policy.boysMaxAge ?? null
  const men = v.halls[0]?.sections.find(sec => sec.audience === 'men')?.policy.boysMaxAge ?? null
  return {
    termsAr: v.policies.terms.ar,
    termsEn: v.policies.terms.en,
    women: { limited: women !== null, age: women ?? 8 },
    men: { limited: men !== null, age: men ?? 12 },
    dressAr: v.policies.dressCode.ar,
    dressEn: v.policies.dressCode.en,
    hours: v.hours.rules.map((r, i) => ({ id: `hrs-${i + 1}`, days: [...r.days], open: r.open, close: r.close })),
  }
}

export function seedRules(hallId: string): RulesModel {
  const v = venue()
  return { hallId, responseHours: v.policies.responseSlaHours, minNoticeDays: 2 }
}

export const seedProfile = (): ProfileModel => ({ type: venue().type, pending: false })

function seedPhotos(): PhotoItem[] {
  const gallery = venue().gallery
  // The story: two photos wait for review (the bridal-suite detail and a buffet photo), one earlier upload was not approved.
  const review = new Set([15, 17])
  const gapEn = new Set([3, 11, 20])
  const items: PhotoItem[] = gallery.map((image, i) => ({ id: `ph-${i + 1}`, image, status: review.has(i) ? 'review' : 'live', gapEn: gapEn.has(i) || undefined }))
  const spare = libraryPhotos().find(p => p.zone === 'hall')
  if (spare && items.length > 0) {
    // 24 photos in all: the not-approved upload replaces the last layout photo in the count.
    items[items.length - 1] = { id: 'ph-rejected', image: { ...spare, zone: items[items.length - 1]?.image.zone ?? spare.zone }, status: 'rejected', reason: 'person' }
  }
  return items
}

function seedVideos(): VideoItem[] {
  const g = venue().gallery
  const stage = g.find(x => x.zone === 'stage_kosha') ?? g[0]
  const hall = g[0]
  return [
    { id: 'vid-1', title: { en: 'Danah Ballroom walkthrough', ar: 'جولة في قاعة الدانة' }, seconds: 14, poster: hall as GalleryItem, status: 'live' },
    { id: 'vid-2', title: { en: 'Kosha set-up', ar: 'تجهيز الكوشة' }, seconds: 9, poster: stage as GalleryItem, status: 'live' },
  ]
}

// ---------------------------------------------------------------- store

export type VenueStore = {
  photos: PhotoItem[]
  videos: VideoItem[]
  uploads: UploadItem[]
  cameraWarned: boolean
  packages: Record<string, PackageModel>
  extras: Record<string, ExtraModel>
  halls: Record<string, HallModel>
  policy: PolicyModel
  rules: Record<string, RulesModel>
  profile: ProfileModel
  /** Package and extra ids in display order, new ones last. */
  packageOrder: string[]
  extraOrder: string[]

  // media
  movePhoto: (id: string, by: -1 | 1) => void
  setCover: (id: string) => void
  deletePhoto: (id: string) => void
  editPhoto: (id: string, patch: { zone: GalleryItem['zone']; alt: Bilingual }) => void
  addPhoto: (image: GalleryItem) => string
  replacePhoto: (id: string, image: GalleryItem) => void
  deleteVideo: (id: string) => void
  startUpload: (item: UploadItem) => void
  setUpload: (id: string, patch: Partial<UploadItem>) => void
  finishUpload: (id: string) => void
  dropUpload: (id: string) => void
  setCameraWarned: () => void

  // packages and extras
  savePackage: (model: PackageModel) => string
  setPackageActive: (id: string, active: boolean) => void
  archivePackage: (id: string) => void
  restorePackage: (id: string) => void
  saveExtra: (model: ExtraModel) => string
  setExtraActive: (id: string, active: boolean) => void

  // halls, policy, rules
  saveHall: (model: HallModel) => void
  savePolicy: (model: PolicyModel) => void
  saveRules: (model: RulesModel) => void
  setVenueType: (type: VenueType) => void

  reset: () => void
}

const initial = () => {
  const packages: Record<string, PackageModel> = {}
  for (const p of venuePackages()) {
    const m = seedPackage(p.id)
    if (m) packages[p.id] = m
  }
  const extras: Record<string, ExtraModel> = {}
  for (const e of venueExtras()) {
    const m = seedExtra(e.id)
    if (m) extras[e.id] = m
  }
  const hallModels: Record<string, HallModel> = {}
  const rules: Record<string, RulesModel> = {}
  for (const h of halls()) {
    const m = seedHall(h.id)
    if (m) hallModels[h.id] = m
    rules[h.id] = seedRules(h.id)
  }
  return {
    photos: seedPhotos(),
    videos: seedVideos(),
    uploads: [] as UploadItem[],
    cameraWarned: false,
    packages,
    extras,
    halls: hallModels,
    policy: seedPolicy(),
    rules,
    profile: seedProfile(),
    packageOrder: venuePackages().map(p => p.id),
    extraOrder: venueExtras().map(e => e.id),
  }
}

let counter = 0
const nextId = (prefix: string): string => {
  counter += 1
  return `${prefix}-${counter}`
}

export const useVenueStore = create<VenueStore>()(set => ({
  ...initial(),

  movePhoto: (id, by) =>
    set(s => {
      const i = s.photos.findIndex(p => p.id === id)
      const j = i + by
      if (i < 0 || j < 0 || j >= s.photos.length) return s
      const next = s.photos.slice()
      const a = next[i]
      const b = next[j]
      if (!a || !b) return s
      next[i] = b
      next[j] = a
      return { photos: next }
    }),
  setCover: id =>
    set(s => {
      const i = s.photos.findIndex(p => p.id === id)
      const item = s.photos[i]
      if (i <= 0 || !item) return s
      return { photos: [item, ...s.photos.filter(p => p.id !== id)] }
    }),
  deletePhoto: id => set(s => ({ photos: s.photos.filter(p => p.id !== id) })),
  editPhoto: (id, patch) => set(s => ({ photos: s.photos.map(p => (p.id === id ? { ...p, gapEn: undefined, image: { ...p.image, zone: patch.zone, alt: patch.alt } } : p)) })),
  addPhoto: image => {
    const id = nextId('ph-new')
    set(s => ({ photos: [...s.photos, { id, image, status: 'review' }] }))
    return id
  },
  replacePhoto: (id, image) => set(s => ({ photos: s.photos.map(p => (p.id === id ? { id, image, status: 'review' } : p)) })),
  deleteVideo: id => set(s => ({ videos: s.videos.filter(v => v.id !== id) })),
  startUpload: item => set(s => ({ uploads: [...s.uploads, item] })),
  setUpload: (id, patch) => set(s => ({ uploads: s.uploads.map(u => (u.id === id ? { ...u, ...patch } : u)) })),
  finishUpload: id => set(s => ({ uploads: s.uploads.filter(u => u.id !== id) })),
  dropUpload: id => set(s => ({ uploads: s.uploads.filter(u => u.id !== id) })),
  setCameraWarned: () => set({ cameraWarned: true }),

  savePackage: model => {
    const id = model.isNew ? nextId('pkg-new') : model.id
    const saved: PackageModel = { ...model, id, isNew: false }
    set(s => ({ packages: { ...s.packages, [id]: saved }, packageOrder: s.packageOrder.includes(id) ? s.packageOrder : [...s.packageOrder, id] }))
    return id
  },
  setPackageActive: (id, active) => set(s => (s.packages[id] ? { packages: { ...s.packages, [id]: { ...s.packages[id], active } } } : s)),
  archivePackage: id => set(s => (s.packages[id] ? { packages: { ...s.packages, [id]: { ...s.packages[id], archived: true, active: false } } } : s)),
  restorePackage: id => set(s => (s.packages[id] ? { packages: { ...s.packages, [id]: { ...s.packages[id], archived: false } } } : s)),

  saveExtra: model => {
    const id = model.isNew ? nextId('x-new') : model.id
    const saved: ExtraModel = { ...model, id, isNew: false }
    set(s => ({ extras: { ...s.extras, [id]: saved }, extraOrder: s.extraOrder.includes(id) ? s.extraOrder : [...s.extraOrder, id] }))
    return id
  },
  setExtraActive: (id, active) => set(s => (s.extras[id] ? { extras: { ...s.extras, [id]: { ...s.extras[id], active } } } : s)),

  saveHall: model => set(s => ({ halls: { ...s.halls, [model.id]: model } })),
  savePolicy: model => set({ policy: model }),
  saveRules: model => set(s => ({ rules: { ...s.rules, [model.hallId]: model } })),
  setVenueType: type => set(s => ({ profile: { type, pending: type !== seedProfile().type } })),

  reset: () => set(initial()),
}))

// ---------------------------------------------------------------- derived

/** Language completeness of a bilingual pair set: how many required fields each language still misses. */
export type Completeness = { ar: number; en: number }
export const completeness = (pairs: ReadonlyArray<{ ar: string; en: string }>): Completeness => ({
  ar: pairs.filter(p => p.ar.trim() === '').length,
  en: pairs.filter(p => p.en.trim() === '').length,
})

export const packageCompleteness = (m: PackageModel): Completeness =>
  completeness([
    { ar: m.nameAr, en: m.nameEn },
    { ar: m.descAr, en: m.descEn },
  ])
