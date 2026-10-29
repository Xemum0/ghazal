#!/usr/bin/env node
// Writes docs/architecture/api-coverage.md and FAILS when the coverage is incomplete:
//   - every selector of packages/contracts/src/selectors.ts is mapped to an operation or to a documented local/mock-only reason,
//   - every prototype store action (design/src/shell/state/types.ts) is mapped,
//   - every operationId used here exists in the bundle, and every operation of the bundle is claimed by at least one row.
//
//   node packages/contracts/openapi/scripts/gen-coverage.mjs           write the document
//   node packages/contracts/openapi/scripts/gen-coverage.mjs --check   fail when the document is stale or incomplete
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '../../../..')
const spec = JSON.parse(fs.readFileSync(path.join(here, '../ghazal.v1.json'), 'utf8'))
const OPS = new Map()
for (const [p, item] of Object.entries(spec.paths)) for (const [m, op] of Object.entries(item)) OPS.set(op.operationId, { path: p, method: m.toUpperCase(), op })

const L = (reason) => ({ local: reason })
const ops = (...ids) => ({ ops: ids })
const both = (ids, note) => ({ ops: ids, note })

// ------------------------------------------------------------------ selectors (the read operations of the prototype)
const SELECTORS = {
  getVenue: both(['getVenue'], 'VenueDetail.venue'),
  requireVenue: both(['getVenue'], 'same call; a 404 is NOT_FOUND'),
  getHall: both(['getVenue'], 'hall = venue.halls[id]; request cards get hall names from `halls` of the row'),
  getPackage: both(['getVenue', 'listPartnerPackages'], 'VenueDetail.packages (client), PackageCatalog (partner)'),
  packagesFor: both(['getVenue', 'listPartnerPackages'], 'client rows carry the Brief price (PackageOffer.forBrief)'),
  extrasFor: both(['getVenue', 'listPartnerPackages'], 'VenueDetail.extras'),
  rulesFor: both(['listPartnerPackages'], 'price rules are partner-only; clients never price anything, the server quotes'),
  getArea: ops('listAreas'),
  getGovernorate: ops('listAreas'),
  areasByGovernorate: ops('listAreas'),
  getBooking: both(['getRequest', 'getPartnerRequest'], 'BookingDetail / PartnerRequestDetail'),
  reviewsFor: ops('listVenueReviews'),
  reviewsAwaitingReply: both(['listPartnerReviews'], 'filter=awaiting_reply'),
  windowsFor: both(['listVoucherWindows', 'getVenue'], 'partner list; clients see the active ones in VenueDetail.windows'),
  activeWindows: both(['getVenue', 'searchVenues'], 'VenueDetail.windows; VenueResult.badge and windowId'),
  availabilityFor: both(['getVenueAvailability'], 'range of one month'),
  availabilityYear: both(['getVenueAvailability'], 'range of up to 366 days'),
  venueAvailabilityOn: ops('getVenueDayAvailability'),
  cardPrice: both(['searchVenues', 'getVenue'], 'VenueResult.price, VenueDetail.price (the card never computes)'),
  guestRange: both(['searchVenues', 'getVenue'], 'VenueResult.guestRange'),
  sectionTags: both(['searchVenues', 'getVenue'], 'VenueResult.tags'),
  structuresOf: both(['searchVenues', 'getVenue'], 'VenueResult.structures'),
  listVenues: both(['searchVenues', 'countVenues', 'getHome'], 'results, hero count, home shelves'),
  searchRegions: ops('searchRegions'),
  nearby: ops('listNearbyVenues'),
  compareSet: ops('compareVenues'),
  quoteFor: ops('quoteVenue'),
  quoteForProvider: ops('quoteProvider'),
  bookingsFor: both(['listRequests', 'listPartnerRequests', 'getWeddingOverview'], 'client list, partner segments, My Wedding'),
  heroBookingAs: L('prototype story helper; the mock exposes the same states through its demo tools (jump to story point)'),
  heroVoucherAs: L('prototype story helper; see heroBookingAs'),
  confirmCountdown: both(['getConfirmWindow'], 'the client ticks locally from Booking.confirmBy; this is the authoritative deadline'),
  bookingTarget: both(['listRequests', 'getRequest'], 'BookingRow.target / BookingDetail.target (TargetSummary)'),
  voucherOffered: both(['quoteVenue', 'quoteProvider'], 'Quote.voucherOffered (savings beat the KD 2 fee)'),
  getVoucher: ops('getVoucher'),
  getCreditVoucher: both(['getVoucher'], 'id or code; kind=credit'),
  voucherFor: both(['getRequest'], 'BookingDetail.voucher'),
  vouchersFor: both(['listVouchers'], 'wallet'),
  voucherOptions: both(['getVoucher'], 'VoucherDetail.options'),
  refundRequestsFor: ops('listRefundRequests'),
  getRefundRequest: ops('getRefundRequest'),
  creditVouchersFor: both(['listVouchers'], 'kind=credit items of the wallet'),
  walletFor: ops('listVouchers'),
  staffInvitationsFor: both(['listStaff'], 'StaffList.invitations'),
  billingFor: ops('getPartnerBilling'),
  redeemableFor: ops('listRedeemableVouchers'),
  checkRedemption: ops('checkVoucherCode'),
  getVisit: both(['getVisit', 'getPartnerVisit'], 'client / partner'),
  visitsFor: both(['listVisits', 'listPartnerVisits'], 'client / partner'),
  visitSlotsFor: ops('listVisitSlots'),
  visitDatesFor: ops('listVisitDates'),
  groupThreadFor: both(['getVisitThread', 'getPartnerVisitThread'], 'VisitThread (conversation, visit, messages)'),
  getProvider: both(['getServiceProvider', 'getPartnerProvider'], 'client / own profile'),
  primaryCategories: both(['listServiceCategories'], 'ServiceCategoriesResponse.primary'),
  secondaryCategories: both(['listServiceCategories'], 'ServiceCategoriesResponse.secondary'),
  listingsFor: ops('listListings'),
  activeListingOf: both(['listServiceProviders'], 'server rule: a provider reaches clients only while its listing is active; partners read their own through listListings'),
  providersFor: ops('listServiceProviders'),
  vendorsFor: both(['listServiceProviders'], 'pre-voucher alias of providersFor'),
  partnerFor: both(['getPartnerMe', 'getPartnerAccount'], 'memberships and account status'),
  personaFor: L('demo personas (hotel, hotel_non_major, service_provider): real accounts on the real backend; the mock seeds them and the demo tools switch persona'),
  paysFees: both(['getPartnerBilling', 'getPartnerMe'], 'BillingView.feeExempt, PartnerMembership.feeExempt'),
  planRates: both(['getPartnerBilling'], 'BillingView.plans (rates nullable: Rates announced soon)'),
  requestsFor: both(['listPartnerRequests'], 'segment=pending (rows carry voucher and SLA)'),
  needsYou: both(['listNeedsYou', 'getPartnerToday'], 'queue by deadline'),
  slaOf: both(['listNeedsYou', 'listPartnerRequests'], 'SlaReading computed by the server; thresholds are PlatformConfig'),
  calendarFor: ops('getPartnerCalendar'),
  softDatesFor: ops('getSoftDates'),
  openWeekendDates: both(['getSoftDates'], 'same list'),
  conversationsFor: ops('listConversations'),
  messagesFor: ops('listMessages'),
  notificationsFor: ops('listNotifications'),
  checklistFor: ops('getChecklist'),
  budgetFor: ops('getBudget'),
  daysToWedding: both(['getWeddingOverview', 'getHome'], 'daysToWedding'),
}

// ------------------------------------------------------------------ store actions (design/src/shell/state/types.ts)
const ACTIONS = {
  setLanguage: both(['updateMe'], 'local first (the locale provider); synced as Me.locale when signed in'),
  signIn: both(['verifyOtp', 'passwordLogin', 'signInWithApple', 'signInWithGoogle', 'partnerLogin', 'partnerVerifyCode', 'acceptStaffInvitation'], 'the sign-in sheet and its code and password screens'),
  signOut: ops('signOut'),
  patchUser: both(['updateMe', 'completeProfile'], 'name and sex are editable in Profile (`updateMe`); a new account gives them in About you (`completeProfile`, CA-AUTH-14)'),
  openGate: L('RETIRED by ADR 0038 D4 (no guest mode): the prototype drops the guest gate; the API still answers 401 AUTH_REQUIRED to a missing session'),
  clearGate: L('RETIRED by ADR 0038 D4 (see openGate): local UI state'),
  setWeddingProfile: both(['putWeddingProfile'], 'local for a guest (onboarding); synced after sign-in'),
  patchWeddingProfile: ops('updateWeddingProfile'),
  toggleFavourite: both(['saveWishlistItem', 'removeWishlistItem', 'mergeWishlist'], 'server calls (every client is signed in since ADR 0038 D4); mergeWishlist stays for hearts an older install kept on the device'),
  clearSignupNudge: L('RETIRED by ADR 0038 D4 (no guest hearts, so no sign-up nudge): local UI state'),
  addToCompare: L('compare tray is local (ADR 0022 C); only compareVenues is server side'),
  removeFromCompare: L('compare tray is local'),
  replaceInCompare: L('compare tray is local'),
  clearCompare: L('compare tray is local'),
  setBrief: L('the Brief is local and sent as query parameters of every Brief-aware read (ADR 0007 D3)'),
  clearBrief: L('the Brief is local'),
  startDraft: L('the booking draft is local until Review; the server never stores a draft (booking-state-machine section 5)'),
  patchDraft: L('booking draft is local'),
  toggleExtra: L('booking draft is local'),
  setStep: L('booking draft is local'),
  resetDraft: L('booking draft is local'),
  beginPayment: both(['createPaymentSession'], 'hosted gateway session of the voucher'),
  setPaymentOutcome: both(['getPaymentState'], 'success is decided by webhook plus status re-query, never by the redirect'),
  resetPayment: L('local UI state'),
  startVoucherCheckout: ops('startVoucherCheckout'),
  settleVoucherPayment: both(['getPaymentState'], 'the gateway webhook activates the voucher; the app polls the state'),
  sendRequest: ops('createRequest'),
  cancelRequest: both(['withdrawRequest', 'cancelRequest', 'declineProposal'], 'R07 withdraw, R10a and R13a cancel, counter-offer decline'),
  confirmBooking: ops('confirmRequest'),
  lapseApproval: L('server job at confirmBy (R09, voucher forfeited); the mock moves its clock; the app only refetches'),
  askSupportCredit: both(['createRefundRequest', 'getSupportConversation'], 'support chat prefilled, request recorded'),
  acceptRequest: ops('acceptRequest'),
  declineRequest: ops('declineRequest'),
  rescheduleRequest: both(['proposeDates'], 'counter-offer of 1 to 3 dates'),
  undoLastHotelAction: both(['undoAcceptRequest'], 'accept only (8 s); decline and propose are not undoable'),
  commitHotelAction: L('local: the undo toast ended'),
  redeemVoucher: both(['checkVoucherCode', 'redeemVoucher'], 'check, then one confirmation'),
  cancelByPartner: both(['revokeApproval', 'cancelConfirmedRequest'], 'R10b and R13b'),
  bookVisit: ops('bookVisit'),
  setVisitStatus: both(['cancelVisit', 'rescheduleVisit', 'answerVisitProposal', 'confirmVisit', 'declineVisit', 'proposeVisitSlot', 'markVisitArrived', 'markVisitMissed'], 'client and partner commands'),
  sendVisitMessage: both(['sendMessage'], 'the visit group conversation'),
  chooseListingPlan: ops('chooseListingPlan'),
  submitListing: ops('submitListing'),
  moderateListing: L('the web Super Admin moderates (context only); the mock exposes a control endpoint, see backend-handoff.md'),
  markNotificationRead: ops('markNotificationRead'),
  markAllNotificationsRead: ops('markAllNotificationsRead'),
  resetToStoryStart: L('mock demo tools (reset data)'),
  loadStory: L('mock demo tools (persona switch)'),
}

// ------------------------------------------------------------------ actions that live in screens, not in the store
const SCREEN_ACTIONS = [
  ['CL-ONBD-*', 'Language, Brief answers', [], 'local (device); wedding profile syncs after sign-in (putWeddingProfile)'],
  ['CL-AUTH-02/03/04', 'Code, name, sex and terms (About you), password', ['verifyOtp', 'registerAccount', 'completeProfile', 'passwordLogin', 'requestPasswordReset', 'resetPassword', 'getLegalDocument', 'requestOtp'], 'a new account is completed with `completeProfile` (name, sex, terms; CA-AUTH-14) or created with `registerAccount` (same fields plus password)'],
  ['CL-AUTH-05', 'Biometric unlock', [], 'local (`local_auth` unlocks the stored session, never a server credential)'],
  ['CL-DISC-*', 'Home, search, filters, region search, dates sheet', ['getHome', 'searchVenues', 'countVenues', 'getFilterTaxonomy', 'listAreas', 'searchRegions', 'getVenueAvailability'], ''],
  ['CL-VENU-*', 'Venue detail, dates and prices, package, hall rules', ['getVenue', 'getVenueAvailability', 'getVenueDayAvailability', 'quoteVenue', 'listVenueReviews', 'listNearbyVenues'], ''],
  ['CL-SAVD-*', 'Saved, compare', ['listWishlist', 'saveWishlistItem', 'removeWishlistItem', 'compareVenues'], 'tray itself is local'],
  ['CL-BOOK-*', 'Booking request steps, review, sent, confirm', ['quoteVenue', 'quoteProvider', 'createRequest', 'getRequest', 'confirmRequest', 'getConfirmWindow', 'requestOtp', 'verifyOtp'], 'phone verification inline on Details (PHONE_VERIFICATION_REQUIRED)'],
  ['CL-PAYM-*', 'Voucher payment', ['startVoucherCheckout', 'createPaymentSession', 'getPaymentState'], ''],
  ['CL-BKNG-*', 'Bookings, detail, cancel, counter-offer, receipts', ['listRequests', 'getRequest', 'withdrawRequest', 'cancelRequest', 'acceptProposal', 'declineProposal', 'reportIssue', 'listReceipts', 'getReceiptPdf'], ''],
  ['CL-WEDD-*', 'My Wedding, checklist, budget', ['getWeddingOverview', 'getChecklist', 'createChecklistItem', 'updateChecklistItem', 'deleteChecklistItem', 'getBudget', 'setBudget', 'addExpense', 'updateExpense', 'deleteExpense', 'listBudgetBands'], ''],
  ['CL-PLAN-*', 'Wedding planner', ['listPlannerPackages', 'getPlanner', 'createPlannerRequest', 'getCurrentPlannerRequest', 'schedulePlannerMeeting'], ''],
  ['CL-SERV-*', 'Additional services', ['listServiceCategories', 'listServiceProviders', 'getServiceProvider', 'quoteProvider', 'createQuoteRequest', 'listQuoteRequests'], ''],
  ['CL-MSGS-*', 'Messages, conversation, notifications', ['listConversations', 'createConversation', 'getConversation', 'listMessages', 'sendMessage', 'markConversationRead', 'setConversationPinned', 'createAttachmentUpload', 'listNotifications', 'getUnreadNotificationCount'], ''],
  ['CL-RVRW-01/02', 'Reviews', ['listVenueReviews', 'createReview'], 'CL-RVRW-03/04 (rewards) are retired: no endpoints'],
  ['CL-PROF-*', 'Profile, wedding info, personal info, notification preferences, settings, delete', ['getMe', 'updateMe', 'registerDevice', 'requestPhoneChange', 'confirmPhoneChange', 'getNotificationPreferences', 'updateNotificationPreferences', 'deleteAccount', 'getWeddingProfile', 'updateWeddingProfile', 'getLegalDocument'], ''],
  ['CL-VCHR-*', 'Vouchers: wallet, voucher, request sheet, reuse or ask support', ['listVouchers', 'getVoucher', 'rebindVoucher', 'createRefundRequest', 'listRefundRequests', 'getRefundRequest', 'getSupportConversation', 'listFaq'], ''],
  ['CL-VIST-*', 'Visits', ['listVisitDates', 'listVisitSlots', 'bookVisit', 'listVisits', 'getVisit', 'getVisitThread', 'cancelVisit', 'rescheduleVisit', 'answerVisitProposal'], ''],
  ['HL-ACCS-*', 'Partner access', ['partnerLogin', 'partnerVerifyCode', 'partnerForgotPassword', 'partnerResetPassword', 'getStaffInvitationPreview', 'acceptStaffInvitation', 'getPartnerAccount', 'getPartnerMe', 'refreshSession', 'getPartnerApplication'], 'HL-ACCS-04 shows the application under review or rejected with its reason (`PartnerAccount.application`)'],
  ['HL-TODY-*', 'Today, Needs you, messages, notifications', ['getPartnerToday', 'listNeedsYou', 'listConversations', 'listMessages', 'sendMessage', 'saveReplyDraft', 'listNotifications', 'switchPartnerContext'], ''],
  ['HL-BOOK-*', 'Pending, upcoming and past, detail, contact, redeem', ['listPartnerRequests', 'getPartnerRequest', 'listRedeemableVouchers', 'listRedeemedVouchers', 'checkVoucherCode', 'redeemVoucher'], 'HL-BOOK-05 (invoice) retired'],
  ['HL-DCSN-*', 'Accept, decline, propose, cancel', ['acceptRequest', 'undoAcceptRequest', 'declineRequest', 'proposeDates', 'revokeApproval', 'cancelConfirmedRequest'], 'HL-DCSN-05 (record cash) retired'],
  ['HL-CALN-*', 'Calendar month, week, day, block, email sync', ['getPartnerCalendar', 'getPartnerCalendarDay', 'createCalendarBlocks', 'removeCalendarBlockBatch', 'listCalendarHolds', 'getSoftDates', 'getCalendarSync', 'updateCalendarSync', 'sendCalendarIcs'], ''],
  ['HL-VENU-*', 'My venue', ['getPartnerVenue', 'updatePartnerVenue', 'listPartnerHalls', 'createHall', 'updateHall', 'setVenueAmenities', 'listPartnerPackages', 'createPackage', 'updatePackage', 'createExtra', 'updateExtra', 'getVenuePolicies', 'putVenuePolicies', 'getBookingRules', 'putBookingRules', 'listVenueMedia', 'createMediaUploadSession', 'completeMediaUpload', 'updateMediaItem', 'deleteMediaItem', 'reorderMedia'], ''],
  ['HL-GROW-*', 'Voucher prices, analytics, reviews', ['listVoucherWindows', 'createVoucherWindow', 'updateVoucherWindow', 'endVoucherWindow', 'getPartnerAnalytics', 'listPartnerReviews', 'getPartnerReview', 'saveReviewReplyDraft', 'replyToReview', 'reportReview', 'requestReviewRemoval'], 'HL-GROW-05 (revenue) retired'],
  ['HL-SETT-*', 'More, notification preferences, staff, billing, hours', ['getPartnerMe', 'getPartnerNotificationPreferences', 'updatePartnerNotificationPreferences', 'listStaff', 'inviteStaff', 'resendStaffInvitation', 'revokeStaffInvitation', 'changeStaffRole', 'deactivateStaff', 'reactivateStaff', 'getPartnerBilling', 'getBusinessHours', 'putBusinessHours', 'stepUp'], ''],
  ['HL-VIST-*', 'Visit requests, visit, chat, arrival, availability', ['listPartnerVisits', 'getPartnerVisit', 'getPartnerVisitThread', 'confirmVisit', 'declineVisit', 'proposeVisitSlot', 'markVisitArrived', 'markVisitMissed', 'getVisitAvailability', 'putVisitAvailability'], ''],
  ['HL-PROV-*', 'Application form, provider account, listings, plan, pay, review status, performance', ['chooseAccountType', 'resubmitPartnerApplication', 'getPartnerApplication', 'listListings', 'createListing', 'getListing', 'updateListing', 'chooseListingPlan', 'submitListing', 'createListingPaymentSession', 'getPaymentState', 'pauseListing', 'resumeListing', 'renewListing', 'requestListingFeeRefund', 'createListingUpload', 'attachListingMedia', 'getPartnerBilling', 'listProviderPackages', 'createProviderPackage', 'updateProviderPackage', 'deleteProviderPackage', 'getPartnerProvider', 'updatePartnerProvider', 'getListingPerformance'], ''],
  ['App level', 'Configuration, clock, analytics, support', ['getAppConfig', 'ingestEvents', 'getSupportConversation', 'listFaq', 'getLegalDocument', 'getPartnerMe'], ''],
]

// ------------------------------------------------------------------ verification
const problems = []
/** Store actions the prototype may have dropped (kept in the mapping above so the history stays readable). */
const RETIRED = new Set(['openGate', 'clearGate', 'clearSignupNudge'])
const selectorsSrc = fs.readFileSync(path.join(root, 'packages/contracts/src/selectors.ts'), 'utf8')
const selectorNames = [...selectorsSrc.matchAll(/^export (?:function|const) (\w+)/gm)].map((m) => m[1])
for (const n of selectorNames) if (!SELECTORS[n]) problems.push(`selector ${n} is not mapped`)
for (const n of Object.keys(SELECTORS)) if (!selectorNames.includes(n)) problems.push(`mapping for unknown selector ${n}`)

const stateSrc = fs.readFileSync(path.join(root, 'design/src/shell/state/types.ts'), 'utf8')
const actionNames = []
for (const m of stateSrc.matchAll(/^export type (\w+Slice) = \{([\s\S]*?)^\}/gm)) {
  for (const a of m[2].matchAll(/^\s{2}(\w+): \(/gm)) actionNames.push(a[1])
}
for (const n of actionNames) if (!ACTIONS[n]) problems.push(`store action ${n} is not mapped`)
for (const n of Object.keys(ACTIONS)) if (!actionNames.includes(n) && !RETIRED.has(n)) problems.push(`mapping for unknown store action ${n}`)

const claimed = new Set()
const claim = (id, where) => {
  if (!OPS.has(id)) problems.push(`${where}: unknown operation ${id}`)
  claimed.add(id)
}
for (const [k, v] of Object.entries(SELECTORS)) (v.ops ?? []).forEach((id) => claim(id, `selector ${k}`))
for (const [k, v] of Object.entries(ACTIONS)) (v.ops ?? []).forEach((id) => claim(id, `action ${k}`))
for (const [screens, , list] of SCREEN_ACTIONS) list.forEach((id) => claim(id, screens))
for (const id of OPS.keys()) if (!claimed.has(id)) problems.push(`operation ${id} is not claimed by any selector, store action or screen row`)

// ------------------------------------------------------------------ render
const link = (id) => (OPS.has(id) ? `\`${id}\`` : `\`${id}?\``)
const row = (cells) => `| ${cells.join(' | ')} |`
const lines = []
lines.push(`# API coverage: every read and write of the prototype mapped to the contract

> GENERATED by \`packages/contracts/openapi/scripts/gen-coverage.mjs\` from \`packages/contracts/src/selectors.ts\`, \`design/src/shell/state/types.ts\`, the screen inventory and \`ghazal.v1.yaml\`. The script fails when a selector, a store action or an operation is unmapped, so this table is the proof that the contract is complete against the prototype. Edit the mapping in the script, then run \`node packages/contracts/openapi/scripts/gen-coverage.mjs\`.`)
lines.push(`
Legend: an operation id is the method name of the generated repository (\`ghazal_domain\`, one interface per tag). **Local** means the state never leaves the device (ADR 0022 C) or is a prototype/demo helper; the reason is given. Mock-only control endpoints are described in \`backend-handoff.md\`.

Totals: ${selectorNames.length} selectors, ${actionNames.length} store actions, ${OPS.size} operations in ${spec.tags.length} tags.
`)
lines.push('## 1. Selectors (the read operations)\n')
lines.push(row(['Selector', 'Operation(s)', 'Note']), row(['---', '---', '---']))
for (const n of selectorNames) {
  const v = SELECTORS[n]
  lines.push(row([`\`${n}\``, v.local ? '**local**' : v.ops.map(link).join(', '), v.local ?? v.note ?? '']))
}
lines.push('\n## 2. Prototype store actions (the writes and local state)\n')
lines.push(row(['Action', 'Operation(s)', 'Note']), row(['---', '---', '---']))
for (const n of actionNames) {
  const v = ACTIONS[n]
  lines.push(row([`\`${n}\``, v.local ? '**local**' : v.ops.map(link).join(', '), v.local ?? v.note ?? '']))
}
lines.push('\n## 3. Screen flows to operations\n')
lines.push(row(['Screens', 'What', 'Operations', 'Note']), row(['---', '---', '---', '---']))
for (const [screens, what, list, note] of SCREEN_ACTIONS) lines.push(row([screens, what, list.length ? list.map(link).join(', ') : '**local**', note]))

lines.push('\n## 4. Local-only state (never sent as a draft)\n')
lines.push(`| State | Where | Reaches the server as |
|---|---|---|
| Compare tray (max 3) | device | \`compareVenues\` request body only |
| The Brief (date, guests, audience, governorates, budget; the older exact areas are deprecated) | device / profile after sign-in | query parameters of every Brief-aware read (\`governorateIds\` on \`getHome\` and \`searchVenues\`) |
| Booking draft (hall, package, extras, contact, requests) | device | \`quoteVenue\` then \`createRequest\` at Send |
| Locale and digit style | device | \`updateMe\` after sign-in |
| Favourites | server (\`saveWishlistItem\` / \`removeWishlistItem\`); hearts an older install kept on the device go with \`mergeWishlist\` | the wish list |
| Wedding profile (onboarding answers, all skippable) | device until saved | \`putWeddingProfile\` / \`updateWeddingProfile\` |
| Recently viewed venues | device | analytics events only (\`ingestEvents\`) |
| Biometric lock | device | nothing |
`)

const round2 = `## 5. Round 2 (ADR 0038, owner decisions of 2026-10-29)

| Change | Contract | Rule |
|---|---|---|
| **Sex on the client account** (CA-AUTH-14, OQ-R2-02) | \`Sex\` (female or male); \`User.sex\` (optional, null until the account is completed); \`RegisterInput.sex\` (required); \`UpdateMeInput.sex\`; new \`completeProfile\` (\`POST /me/complete\`: name, sex and terms are required) | A first code creates the account with a placeholder name and no sex; \`AuthSession.isNewUser\` stays true on every sign-in until \`completeProfile\` succeeds. A missing sex is the usual 422 VALIDATION_FAILED (\`errors: [{path: "/sex", code: "required"}]\`). Not shown to venues, not used to filter. |
| **Governorates, not areas** (CA-FLT-08, CA-ONB-10) | \`governorateIds\` on \`getHome\` (the Brief), \`searchVenues\`, \`countVenues\`, \`listServiceProviders\`; \`WeddingProfile.governorateIds\` and its input | Empty or missing = all governorates, several = any of them. \`areaIds\`, \`briefAreaIds\` and \`allAreas\` keep working and are deprecated (\`allAreas\` is the "All governorates" chip of older callers). A venue's \`areaId\` is an address line only. **The governorate list is configuration**: \`GET /areas\` returns the Super Admin's list; it starts with Kuwait's six official governorates (Capital, Hawalli, Farwaniya, Ahmadi, Jahra, Mubarak Al-Kabeer, each with an Arabic and an English name) and the Super Admin can extend it (the owner said "about 8", OQ-R2-01); the apps never hard-code the ids. |
| **Partner application** (PA-ACC-07, PA-ACC-08, OQ-R2-03) | \`chooseAccountType\` takes the form; \`PartnerApplication\` (status pending, accepted or rejected, rejectionReason, submittedAt) on \`PartnerMembership.application\` and \`PartnerAccount.application\`; \`getPartnerApplication\`, \`resubmitPartnerApplication\` | The account starts under_review with a pending application; staff accept or reject in the Super Admin web (the mock: \`POST /__mock/applications/{id}/decide\`); only an accepted account creates listings (\`createListing\` answers 403 APPLICATION_NOT_ACCEPTED); a rejected application is edited and sent again (409 APPLICATION_NOT_EDITABLE otherwise). Accounts without an application (the existing partners) count as accepted. |
| **Services independent of venues** (CA-SVC-19) | \`VenueDetail.extras\` and \`PackageCatalog.extras\` are deprecated; \`createExtra\` / \`updateExtra\` are deprecated | The responses carry an empty list; the endpoints stay valid and the engine still prices an extra when a caller asks. |
| **Store note for service providers** (CA-SVC-20, OQ-R2-04) | \`AppConfig.partnerAppUrl\` | Configuration. |
`
lines.push(round2)
const byTag = new Map()
for (const [id, o] of OPS) {
  const t = o.op.tags[0]
  if (!byTag.has(t)) byTag.set(t, [])
  byTag.get(t).push([id, o])
}
lines.push('## 6. Operations by tag\n')
lines.push(`Auth column: \`G\` guest allowed, \`O\` optional token (guests see public data, signed-in users see their own), \`B\` bearer required. \`I\` = Idempotency-Key, \`M\` = If-Match. Partner operations take \`X-Venue-Id\` or \`X-Provider-Id\`.\n`)
for (const t of spec.tags.map((x) => x.name)) {
  const list = byTag.get(t) ?? []
  lines.push(`### ${t} (${list.length})\n`, `${spec.tags.find((x) => x.name === t).description}\n`)
  lines.push(row(['Operation', 'Method and path', 'Auth', 'Flags', 'Permissions']), row(['---', '---', '---', '---', '---']))
  for (const [id, o] of list) {
    const access = { guest: 'G', optional: 'O', bearer: 'B' }[o.op['x-access']]
    const flags = [o.op['x-idempotent'] ? 'I' : '', o.op['x-if-match'] ? 'M' : '', o.op['x-paged'] ? 'page' : ''].filter(Boolean).join(' ')
    lines.push(row([`\`${id}\``, `\`${o.method} ${o.path}\``, access, flags, (o.op['x-permissions'] ?? []).map((p) => `\`${p}\``).join(', ')]))
  }
  lines.push('')
}
const text = lines.join('\n') + '\n'
const file = path.join(root, 'docs/architecture/api-coverage.md')

if (problems.length) {
  console.error(`coverage incomplete (${problems.length}):\n  - ${problems.join('\n  - ')}`)
  process.exit(1)
}
if (process.argv.includes('--check')) {
  if (!fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== text) { console.error('docs/architecture/api-coverage.md is stale'); process.exit(1) }
  console.log('api-coverage.md is current and complete')
} else {
  fs.writeFileSync(file, text)
  console.log(`wrote api-coverage.md: ${selectorNames.length} selectors, ${actionNames.length} actions, ${OPS.size} operations all mapped`)
}
