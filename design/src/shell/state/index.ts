// Prototype state (zustand). Read with selectors: `usePrototype(s => s.compareList)`; act with `usePrototype.getState().addToCompare(id)`.
// Persists nothing; reset on reload; `resetToStoryStart()` returns to the story start without a reload.
export { usePrototype, prototypeStore } from './store'
export { selectPendingHotelRequests, selectAwaitingClient, selectMyVouchers, selectRedeemable, selectCompareCount, useLanguageBridge } from './hooks'
export { COMPARE_MAX } from './types'
export type {
  AuthGate,
  AuthLevel,
  AuthUser,
  BookingDraft,
  BookingStep,
  CompareResult,
  FavouriteKind,
  GateReason,
  HotelAction,
  PaymentMethodKey,
  PaymentOutcome,
  PaymentState,
  VisitChat,
  VoucherPurchase,
  PrototypeState,
  SearchBrief,
  WeddingProfileState,
} from './types'
