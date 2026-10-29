# Ghazal — Requirement Traceability Matrix

> Every requirement from `project.md` and `Ghazal_PRD_EN.pdf` as an atomic, testable line with a stable ID. Screens and tests cite these IDs. Machine-readable twin: [`feature-matrix.json`](feature-matrix.json) (same IDs, same text; generated together, never edit one without the other).
>
> **Voucher model update (2026-10-14, ADR 0033):** 85 lines were appended in section 13 (new groups `CA-VCH`, `CA-VIS`, `CA-FLT`, `PA-ACC`, `PA-LST`, `PA-ADS`, `PA-REV`, `HA-VCH`, `HA-VIS`, `SA-REV`, and appended numbers in `CA-SVC`, `CA-STAT`, `CA-AUTH`, `CA-PROF`, `HA-VMGT`, `HA-ANLY`, `HA-SET`). Older lines the model supersedes or amends carry a note starting "Superseded by ADR 0033" or "Amended by ADR 0033" and are never deleted. The totals in section 2 are the original 571; the live count (656) is in `feature-matrix.json`.
>
> **571 requirements**  ·  client app 233  ·  hotel app 73  ·  104 are *implied* (not literally in the PRD)  ·  35 conflicts/gaps in the register at the end.

## 1. How to read this file

**ID scheme.** `<APP>-<GROUP>-<nn>`; two-digit, zero-padded, numbered per group in this order. **IDs are append-only and never reused**: to drop a requirement, keep the line, set its phase to `deferred` and write `Retired: reason` in Notes. New lines take the next free number in their group.

| Prefix | Product / scope | Groups |
|---|---|---|
| `CA` | Client Mobile App | AUTH, ONB, HOME, SRCH, CARD, VDET, CMP, BOOK, PAY, STAT, PLAN, SVC, TOOL, CHAT, NOTI, REV, PROF, LOY, REC |
| `HA` | Venue / Hotel Mobile App | AUTH, DASH, BOOK, CAL, VMGT, OFFR, ANLY, NOTI, SET, MSG |
| `VD` | Venue Admin Dashboard (web) | DASH, BOOK, CAL, VMGT, PRC, CUST, STAFF, RPT, REV, MKT |
| `SA` | Super Admin Dashboard (web) | DASH, VAPP, VNDR, USR, COMM, SUBS, CMS, CAT, AREA, PLNR, SUP, NOTI, FIN, ANLY, SEC, AI |
| `PL` | Platform / backend | ARCH, AUTH, PAY, BOOK, CORE |
| `NF` | Non-functional and delivery | LOC, PERF, AVL, SEC, PAYS, PRIV, SCAL, COMP, ANL, DSN, MET, PRJ, DEL, CST, EXC |
| `MK` | Monetization | COM, SUB, SVC |
| `RM` | Roadmap (deferred phases) | AI, GCC |

**Source column.** `PDF §n` = section number printed in the PDF (the file has 17 physical pages: unnumbered cover and contents, then printed pages 1-15). `project.md › Heading (Item)` = heading in the markdown PRD. Where only one document carries the item, the cell says `(not in PDF)` or `(not in project.md)`. `IMPLIED by …` = not literally stated; needed to make a stated requirement testable or complete. Implied lines are the only place this matrix goes beyond the PRD, and each is flagged so it can be struck out by the owner.

**Phase.** Only the roadmap items in PDF §14 are phased by the PRD itself: Phase 1 = venue discovery, booking, comparison, payments; Phase 2 = wedding-services marketplace, planner, chat, reviews; Phase 3 and Phase 4 as listed; plus the *explicitly deferred* list. Everything else is phased by these rules: (a) foundations (auth, onboarding, home, search, details, compare, booking, payment, status, profile, booking/payment notifications, all venue-side operations, platform and non-functional) = `MVP-P1`; (b) anything that depends on chat, reviews, planner, vendors, loyalty or the planning tools (budget, checklist, countdown, wishlist for services/packages) = `MVP-P2` (PDF §14 prose puts planning tools and chat in the MVP without assigning a phase); (c) PDF §14 Phase 3/4 = `P3`/`P4`; (d) features the PRD names as future/deferred, or that no phase covers and the PRD never schedules (for example premium analytics, SMS) = `deferred`. Per PDF §17 the MVP scope is exactly §6-9 minus the §14 future items.

**Design scope this pass.** `yes` = must appear in the Client App / Hotel App prototype (every MVP-P1/P2 line of those two apps, plus the non-functional rules that shape design). `no` = web dashboards, platform, monetization, roadmap and deferred items (context only; the design system must still extend to the dashboards).

**Notes.** `CF-nn` = entry in the conflicts register at the end of this file. `GAP:` = the PRD is silent or ambiguous; the note gives the working call (also to be logged in `docs/product/open-questions.md`). `{x}` placeholders in the JSON are already resolved to IDs.

## 2. Coverage totals

| Product | Lines | MVP-P1 | MVP-P2 | P3 | P4 | deferred | Design scope yes | Implied |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Client Mobile App (`CA`) | 233 | 163 | 63 | 4 | 0 | 3 | 226 | 56 |
| Venue / Hotel Mobile App (`HA`) | 73 | 63 | 10 | 0 | 0 | 0 | 73 | 28 |
| Venue Admin Dashboard (web) (`VD`) | 58 | 49 | 7 | 0 | 0 | 2 | 0 | 0 |
| Super Admin Dashboard (web) (`SA`) | 81 | 54 | 20 | 0 | 1 | 6 | 0 | 0 |
| Platform / backend (`PL`) | 33 | 30 | 3 | 0 | 0 | 0 | 0 | 14 |
| Non-functional and delivery (`NF`) | 71 | 70 | 1 | 0 | 0 | 0 | 26 | 5 |
| Monetization (`MK`) | 13 | 6 | 3 | 0 | 0 | 4 | 1 | 1 |
| Roadmap (deferred phases) (`RM`) | 9 | 0 | 0 | 4 | 5 | 0 | 0 | 0 |
| **Total** | **571** | **435** | **107** | **8** | **6** | **15** | **326** | **104** |

Lines carrying a `GAP`: 72. Present only in project.md: 9. Present only in the PDF: 57 (mostly §12-§18 delivery and non-functional text that project.md does not contain).

Per-group counts (client and hotel apps): `CA-AUTH` 11 · `CA-ONB` 9 · `CA-HOME` 16 · `CA-SRCH` 21 · `CA-CARD` 13 · `CA-VDET` 26 · `CA-CMP` 12 · `CA-BOOK` 17 · `CA-PAY` 11 · `CA-STAT` 10 · `CA-PLAN` 9 · `CA-SVC` 12 · `CA-TOOL` 19 · `CA-CHAT` 11 · `CA-NOTI` 8 · `CA-REV` 6 · `CA-PROF` 11 · `CA-LOY` 7 · `CA-REC` 4 · `HA-AUTH` 4 · `HA-DASH` 7 · `HA-BOOK` 11 · `HA-CAL` 9 · `HA-VMGT` 10 · `HA-OFFR` 6 · `HA-ANLY` 7 · `HA-NOTI` 8 · `HA-SET` 5 · `HA-MSG` 5

## 3. Client Mobile App (`CA`) — 233 lines

### CA-AUTH — Authentication (PDF §6.1) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-AUTH-01` | A new user can create an account (sign up) with an identifier and a password. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | GAP: identifier for password accounts (email vs phone) is unspecified. Working call (ADR 0012 D1, 0028): the Kuwait mobile number behind a fixed +965 chip; no other country codes in the MVP (foreign numbers use Apple or Google, OQ-L-14); email is optional and never an identifier. |
| `CA-AUTH-02` | A registered user can log in with identifier and password. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes |  |
| `CA-AUTH-03` | User can sign up or log in with Sign in with Apple. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | iOS: App Store 4.8 requires an equivalent privacy-preserving login whenever Google login is offered; Apple is the simplest. Must handle private-relay emails and revoke the Apple token on account deletion (CA-PROF-09). |
| `CA-AUTH-04` | User can sign up or log in with Google Sign-In. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | GAP: rules for linking Apple / Google / phone identities to one account (match on verified phone or email) are undefined. |
| `CA-AUTH-05` | User can sign up or log in with a phone number verified by a one-time code delivered over WhatsApp. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | CF-04/CF-05: project.md says generic 'Phone OTP' with Firebase Auth; PDF §5/§11/§16 fix WhatsApp as the only OTP channel with backend JWT. Resolution: WhatsApp OTP + backend JWT. |
| `CA-AUTH-06` | OTP entry screen supports code entry, resend after a countdown, code expiry and failure/lock-out states. | IMPLIED by PDF §6.1 (Phone OTP via WhatsApp) | MVP-P1 | yes | GAP: no fallback if the WhatsApp message is not delivered (SMS is excluded, PDF §16). Needs a decision (voice call, email link, retry window) and attempt rate-limiting. |
| `CA-AUTH-07` | User can reset a forgotten password through a verified channel. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | GAP: channel unspecified. Working call: WhatsApp OTP for phone-first accounts, email link where an email exists. |
| `CA-AUTH-08` | A returning user can unlock the app with device biometrics (Face ID, Touch ID, Android biometric) instead of re-entering credentials. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes | Opt-in; biometrics unlock a stored session and never replace first login. Toggle lives in Settings (CA-PROF-08). Phase derived (auth is foundational). |
| `CA-AUTH-09` | A user can browse the app (home, search, venue details, comparison) without an account. | PDF §6.1 · project.md › Authentication | MVP-P1 | yes |  |
| `CA-AUTH-10` | When a guest attempts an action that needs identity (book, pay, chat, review, planning tools), the app prompts sign-in and returns the user to the interrupted step afterwards. | IMPLIED by PDF §6.1 (guest browsing without an account) | MVP-P1 | yes | GAP: which actions need an account is unstated. Working rule: booking, payment, chat, reviews and planning tools require an account; favourites and compare work on-device and merge into the account at sign-up. |
| `CA-AUTH-11` | Sign-up requires explicit acceptance of the Terms of Use and Privacy Policy (texts supplied by the owner). | IMPLIED by PDF §17 (owner provides legal texts) and §9.6 | MVP-P1 | yes | Legal texts are an owner dependency (NF-PRJ-08). Texts served from Super Admin CMS (SA-CMS-05). |

### CA-ONB — Onboarding (PDF §6.2) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-ONB-01` | First launch shows introductory screens that present the value proposition; they are swipeable and skippable. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | project.md says 'beautiful onboarding screens', PDF says 'introductory screens'; count and copy unspecified. Working call: three screens maximum, language chosen first. |
| `CA-ONB-02` | User selects the app language (Arabic or English) during onboarding; layout direction flips immediately and the choice persists. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | Default from device locale. Must satisfy NF-LOC-01 and NF-LOC-02 from the first screen. |
| `CA-ONB-03` | User sets the wedding date, or marks it as not yet decided. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | 'Not yet decided' branch is IMPLIED: many couples shop for venues before fixing a date. Date drives availability filtering, countdown and checklist. |
| `CA-ONB-04` | User sets a budget in KWD during onboarding: the venue and catering budget band, not the total wedding spend. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | Resolved 2026-10-12 (ADR 0007 D3 amendment, OQ-P-17): the PRD wording is 'overall wedding budget', but the Brief holds the venue and catering budget (the number venue search can act on, KD 20,000 - 35,000 for the demo persona); the total wedding budget is asked separately in the Budget Manager (CA-TOOL-05). |
| `CA-ONB-05` | User sets the expected number of guests. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | GAP: men/women split is not captured although segregated sections are common at Kuwaiti weddings (CF-09); capacity filter should be able to use it. |
| `CA-ONB-06` | User selects one or more preferred areas in Kuwait. | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | Area list comes from Area Management (SA-AREA-01). Multi-select. |
| `CA-ONB-07` | User states whether they are the bride or the groom and enters basic profile details (name; partner's name optional). | PDF §6.2 · project.md › Onboarding | MVP-P1 | yes | 'Bride / Groom profile' is unspecified. Family members and planners (PDF §4 primary users) have no onboarding path (CF-17). |
| `CA-ONB-08` | Onboarding answers are stored on the device for guests and attached to the account at sign-up; they prefill search and seed Budget, Checklist and Countdown. | IMPLIED by PDF §6.2 and §6.3 (Recommended for you) | MVP-P1 | yes |  |
| `CA-ONB-09` | Every onboarding question is skippable and editable later under Profile > Wedding info. | IMPLIED by PDF §6.2 and §6.16 (wedding information) | MVP-P1 | yes |  |

### CA-HOME — Home screen (PDF §6.3) (16)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-HOME-01` | Home shows a hero search at the top of the screen. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes |  |
| `CA-HOME-02` | Hero search accepts a wedding date. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Single date vs range: venues are booked per date/session (CF-09). Defaults to the onboarding date. |
| `CA-HOME-03` | Hero search accepts an area. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Multi-select from Kuwait areas. |
| `CA-HOME-04` | Hero search accepts a budget. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | GAP: venue pricing may be per hall, per package or per guest; budget semantics must match the price model shown on cards (CA-CARD-05). |
| `CA-HOME-05` | Hero search accepts a guest count. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes |  |
| `CA-HOME-06` | Submitting the hero search opens the results screen with the entered parameters applied as filters. | IMPLIED by PDF §6.3 and §6.4 | MVP-P1 | yes |  |
| `CA-HOME-07` | Home shows a quick-category row with six categories: Luxury Hotels, Wedding Halls, Government Halls, Beach Venues, Outdoor Venues, VIP Venues. | PDF §6.3 (names not listed) · project.md › Home Screen | MVP-P1 | yes | CF-15: PDF only says 'quick categories'; names come from project.md. They do not match Super Admin categories (Hotels, Wedding Halls, Outdoor, Beach, Luxury, Government): 'VIP' has no admin category and 'Luxury Hotels' merges two. |
| `CA-HOME-08` | Tapping a quick category opens results filtered to that category. | IMPLIED by PDF §6.3 | MVP-P1 | yes |  |
| `CA-HOME-09` | A Featured Venues section lists venues with active Featured placement. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Fed by Subscriptions (SA-SUBS-03) and MK-SUB-02; paid placement must be labelled (MK-SUB-04). |
| `CA-HOME-10` | A Special Offers section lists venues with active offers. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Fed by venue offers (HA-OFFR-01). |
| `CA-HOME-11` | A Last-Minute Deals section lists discounted dates in the near term. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | GAP: 'last minute' window undefined (working call: dates within 30 days). Fed by flash sales (HA-OFFR-02). |
| `CA-HOME-12` | An Available This Week section lists venues with open dates in the current week. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Serves short-notice events, not the 6-18 month planning cycle (PDF §2); keep it compact and hide when empty. |
| `CA-HOME-13` | A Trending Venues section ranks venues by recent engagement. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | GAP: ranking definition (views, saves, booking requests). Uses analytics events (NF-ANL-02, NF-ANL-04). |
| `CA-HOME-14` | A Nearby Venues section lists venues ordered by distance from the user's location. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | Needs location permission; fallback to preferred area when denied. Google Maps Platform (PDF §11). |
| `CA-HOME-15` | A Recommended for You section personalises venues from onboarding answers and behaviour using rules-based logic. | PDF §6.3 · project.md › Home Screen | MVP-P1 | yes | CF-07: project.md lists AI recommendations; PDF defers AI to Phase 3. MVP = rules-based only (area, capacity, budget band, past views). |
| `CA-HOME-16` | Each home section has a See all destination that opens the full list with the equivalent filters applied. | IMPLIED by PDF §6.3 | MVP-P1 | yes |  |

### CA-SRCH — Search and filters (PDF §6.4) (21)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-SRCH-01` | A results screen lists venue cards for the active query and filters. | IMPLIED by PDF §6.4 (smart search filters) | MVP-P1 | yes | Must meet NF-PERF-02 (2 s). |
| `CA-SRCH-02` | Filter by location: venues within a chosen distance of the user. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | CF-21: project.md lists Location and Area separately, PDF merges them. Working call: Location = geographic distance, Area = named Kuwait area. |
| `CA-SRCH-03` | Filter by one or more named Kuwait areas. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | Area names bilingual from SA-AREA-01. |
| `CA-SRCH-04` | Filter by price range in KWD. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | GAP: price of what (lowest package, per guest, hall rental)? Working call: starting price for the selected date. |
| `CA-SRCH-05` | Filter by guest capacity (venue can host at least the stated number of guests). | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-06` | Filter by venue setting: Indoor, Outdoor or Mixed (indoor plus outdoor). | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | CF-21: 'Mixed' (setting) is a different concept from 'Mixed Event' (attendance, CA-SRCH-13); label both distinctly in EN and AR. |
| `CA-SRCH-07` | Filter by parking available. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-08` | Filter by valet service available. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-09` | Filter by bridal room available. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-10` | Filter by buffet included. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-11` | Filter by decoration included. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-12` | Filter by photography allowed. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | Photography policy matters for women-only events; must also be visible on details (CA-VDET-26). |
| `CA-SRCH-13` | Filter by attendance policy: Women only, Men only or Mixed event. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | CF-09: unclear whether a venue has one policy or separate men/women halls bookable together; the data model must allow several policies per venue. |
| `CA-SRCH-14` | Filter by availability on the selected date(s). | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | Requires a date (default: onboarding date). Semantics depend on session/hall granularity (CF-09). |
| `CA-SRCH-15` | Filter by Instant Booking (confirmed without venue approval). | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | CF-08: instant booking is implied only by this filter; its behaviour is specified in CA-BOOK-15. Superseded by ADR 0033 (voucher model, 2026-10-14): instant booking filter removed. |
| `CA-SRCH-16` | Filter by minimum rating. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes |  |
| `CA-SRCH-17` | Show the newest venues (sort by listing date). | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | CF-21: 'Rating' and 'Newest' are listed as filters but behave as sorts; exposed under CA-SRCH-21. |
| `CA-SRCH-18` | Filter by luxury level. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | GAP: scale and authority (self-declared vs admin-assigned). Working call: three tiers assigned by Super Admin, aligned with the 'Luxury' category (CF-15). |
| `CA-SRCH-19` | Filter by hotel brand. | PDF §6.4 · project.md › Smart Search Filters | MVP-P1 | yes | GAP: brand taxonomy must exist as a venue attribute (hotels only) in Venue Management and Super Admin. |
| `CA-SRCH-20` | Active filters combine (AND), appear as removable chips and can be cleared in one action. | IMPLIED by PDF §6.4 | MVP-P1 | yes |  |
| `CA-SRCH-21` | A sort control offers Recommended, Rating, Newest, Price (low to high, high to low) and Distance. | IMPLIED by PDF §6.4 (rating, newest) | MVP-P1 | yes | Sponsored placement (MK-SUB-03) must stay visibly labelled when sorted. |

### CA-CARD — Venue card (PDF §6.5) (13)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-CARD-01` | Card shows a cover photo. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes |  |
| `CA-CARD-02` | Card indicates and can preview a venue video when the venue has one. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | Bandwidth on 4G (NF-PERF): tap-to-play preview, no autoplay. |
| `CA-CARD-03` | Card shows the average rating. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes |  |
| `CA-CARD-04` | Card shows the number of reviews. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | Reviews are submitted from Phase 2 (CA-REV-01); cold-start state (no reviews yet) required. |
| `CA-CARD-05` | Card shows the starting price in KWD (lowest package price for the selected date). | PDF §6.5 (starting price only) · project.md › Venue Card (Price and Starting Price) | MVP-P1 | yes | CF-20: project.md lists both 'Price' and 'Starting Price'; PDF lists 'starting price' only. Resolution: single starting-price figure. Amended by ADR 0033 (voucher model, 2026-10-14): card shows voucher price with the standard price beneath (CA-VCH-02). |
| `CA-CARD-06` | Card shows capacity (guest range). | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes |  |
| `CA-CARD-07` | Card shows the area. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes |  |
| `CA-CARD-08` | Card shows an availability badge for the selected date. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | GAP: state set undefined. Working set: Available, Limited, Unavailable; plus 'Check dates' when no date is chosen. Never colour alone. |
| `CA-CARD-09` | Card has a favourite toggle that saves the venue to the wishlist. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | Same list as CA-TOOL-01. |
| `CA-CARD-10` | Card has a compare toggle that adds or removes the venue from the comparison set. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | Max 3 (CA-CMP-02). |
| `CA-CARD-11` | Card has a Book action that starts the booking flow for that venue. | PDF §6.5 · project.md › Venue Card | MVP-P1 | yes | Guests are routed through the auth gate (CA-AUTH-10). Card-level Book competes with the photograph; design must keep one primary action per card. |
| `CA-CARD-12` | Tapping the card opens Venue Details. | IMPLIED by PDF §6.5 and §6.6 | MVP-P1 | yes |  |
| `CA-CARD-13` | Card shows Instant Booking, Featured/Sponsored and active-offer badges where applicable. | IMPLIED by PDF §6.4 (instant booking), §9.5 (subscriptions), §7.5 (offers) | MVP-P1 | yes | Sponsored must be disclosed (MK-SUB-04). Amended by ADR 0033 (voucher model, 2026-10-14): Instant Booking badge removed; a voucher-price badge is added. |

### CA-VDET — Venue details (PDF §6.6) (26)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-VDET-01` | Venue details open with a large photo gallery (full-screen viewing, swipe, zoom). | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes |  |
| `CA-VDET-02` | The gallery includes venue videos with in-app playback. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes |  |
| `CA-VDET-03` | A 360-degree virtual tour slot for the venue. | PDF §8.4 (360 placeholder in venue dashboard); §14 (deferred) · project.md › Venue Details (360 Tour (Future)) | deferred | no | Deferred. project.md lists it in the client app as '(Future)'; PDF §6.6 omits it, PDF §8.4 reserves a placeholder in the venue dashboard, PDF §14 defers 360 tours. Keep a content-model field only; no UI in this pass. |
| `CA-VDET-04` | Details show the venue description. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes | Bilingual content (PL-CORE-08). |
| `CA-VDET-05` | Details list amenities. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes |  |
| `CA-VDET-06` | Details list venue rules. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes |  |
| `CA-VDET-07` | Details list packages with name, inclusions and price. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes | Package prices are date-dependent (CA-BOOK-14). Package selection continues into booking. Amended by ADR 0033 (voucher model, 2026-10-14): packages show two prices (CA-VCH-02). |
| `CA-VDET-08` | Details state venue capacity (minimum to maximum guests, per section where applicable). | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes | Per-section capacity depends on CF-09. |
| `CA-VDET-09` | Details embed a map showing the venue location. | PDF §6.6 · project.md › Venue Details (Map) | MVP-P1 | yes | Google Maps Platform (PDF §11). |
| `CA-VDET-10` | User can open the venue location in a maps app for directions. | PDF §6.6 (Google Maps location) · project.md › Venue Details (Google Maps) | MVP-P1 | yes | project.md lists 'Map' and 'Google Maps' separately; merged here as embed + hand-off. Apple Maps hand-off on iOS is IMPLIED. |
| `CA-VDET-11` | Details show parking information. | project.md › Venue Details (Parking) (not in PDF) | MVP-P1 | yes | CF-22: PDF §6.6 omits parking from details, yet it is a filter (PDF §6.4) and listed in project.md. |
| `CA-VDET-12` | Details show bridal room and groom room availability and specifications. | PDF §6.6 · project.md › Venue Details (Bride Room, Groom Room) | MVP-P1 | yes | Terminology: project.md 'Bride Room / Groom Room', PDF 'Bridal and groom rooms'; use bilingual terms consistently. |
| `CA-VDET-13` | Details show decoration information (included, optional, restrictions). | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes |  |
| `CA-VDET-14` | Details show buffet/catering information (included or not, in-house vs external). | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes | GAP: menus are managed in the venue dashboard (VD-VMGT-07) but no client menu viewer is specified. |
| `CA-VDET-15` | Details show lighting, stage and music/sound facilities. | PDF §6.6 · project.md › Venue Details (Lighting, Stage, Music) | MVP-P1 | yes | GAP: 'Music' is undefined (sound system, music-permitted policy or live-music contracting). |
| `CA-VDET-16` | Details show the cancellation policy. | PDF §6.6 · project.md › Venue Details (Policies › Cancellation) | MVP-P1 | yes | Drives refund logic (PL-BOOK-01) and must be repeated at booking review (CA-BOOK-09). Amended by ADR 0033 (voucher model, 2026-10-14): shows venue terms; no cancellation tier schedule. |
| `CA-VDET-17` | Details show the children policy. | PDF §6.6 · project.md › Venue Details (Policies › Children) | MVP-P1 | yes | GAP: age limits and fees. |
| `CA-VDET-18` | Details show the dress code. | PDF §6.6 · project.md › Venue Details (Policies › Dress Code) | MVP-P1 | yes | Free text per venue, bilingual. |
| `CA-VDET-19` | Details show working hours. | PDF §6.6 · project.md › Venue Details | MVP-P1 | yes | Distinct from business hours in settings (HA-SET-04) and from event time slots (CF-09). |
| `CA-VDET-20` | Details show the rating summary and the review list including owner replies. | PDF §6.6 · project.md › Venue Details (Reviews) | MVP-P1 | yes | CF-24: display ships with Phase 1 (card shows rating); submission is Phase 2 (CA-REV-01). Empty state needed at launch. |
| `CA-VDET-21` | Details show FAQs. | PDF §6.6 · project.md › Venue Details (FAQ) | MVP-P1 | yes |  |
| `CA-VDET-22` | Details show a live availability calendar marking available, booked, blocked and pending dates. | PDF §6.6 · project.md › Venue Details (Availability Calendar) | MVP-P1 | yes | Live from the venue calendar (HA-CAL-08). Session/hall granularity open (CF-09). Selecting a date deep-links into booking. |
| `CA-VDET-23` | Details show similar venues. | PDF §6.6 · project.md › Venue Details (Similar Venues) | MVP-P1 | yes | Rules-based similarity (area, capacity, price band, type). |
| `CA-VDET-24` | Details keep a persistent primary action (Check availability / Book) visible with the starting price. | IMPLIED by PDF §6.6 and §6.8 | MVP-P1 | yes |  |
| `CA-VDET-25` | Details expose favourite and add-to-compare actions. | IMPLIED by PDF §6.5 (card actions) and §6.6 | MVP-P1 | yes |  |
| `CA-VDET-26` | Details surface every attribute that is searchable as a filter (valet, photography allowed, attendance policy, instant booking, luxury level, hotel brand). | IMPLIED by PDF §6.4 and §6.6 | MVP-P1 | yes | CF-22: PDF §6.6 omits several filter attributes; users must be able to verify what they filtered on. |

### CA-CMP — Venue comparison (PDF §6.7) (12)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-CMP-01` | User can add up to three venues to a comparison set from venue cards and venue details. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes |  |
| `CA-CMP-02` | Adding a fourth venue is blocked with a message that offers replacing one of the three. | PDF §6.7 · project.md › Compare Feature (up to 3) | MVP-P1 | yes |  |
| `CA-CMP-03` | A persistent compare indicator shows the current selection (count) and opens the comparison view from anywhere in the app. | IMPLIED by PDF §6.7 | MVP-P1 | yes | Appears only after the first venue is added; must not obstruct content or tab bar. |
| `CA-CMP-04` | The comparison view shows the selected venues side by side in a table. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes | Meaningful from two venues. At 360-430 px three columns plus labels is tight: sticky label column and horizontal scroll. |
| `CA-CMP-05` | Comparison rows: price, guests (capacity), area and rating. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes | 'Guests' = capacity range; price = starting price for the chosen date. |
| `CA-CMP-06` | Comparison rows: buffet, parking and decoration. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes |  |
| `CA-CMP-07` | Comparison rows: photos and packages. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes |  |
| `CA-CMP-08` | Comparison row: availability for the chosen date. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes | Needs a date; prompt if none is set. |
| `CA-CMP-09` | Comparison row: distance from the user. | PDF §6.7 · project.md › Compare Feature | MVP-P1 | yes | GAP: distance from what origin (device location, preferred area or a chosen address). Working call: device location, else preferred area. |
| `CA-CMP-10` | Each compared venue has a Book action that starts booking directly from the comparison view. | PDF §6.7 · project.md › Compare Feature (Book button) | MVP-P1 | yes |  |
| `CA-CMP-11` | User can remove a venue from the comparison. | IMPLIED by PDF §6.7 | MVP-P1 | yes |  |
| `CA-CMP-12` | The comparison set persists across sessions and syncs to the account after sign-in. | IMPLIED by PDF §6.7 | MVP-P1 | yes |  |

### CA-BOOK — Booking flow (PDF §6.8) (17)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-BOOK-01` | Booking can be started from a venue card, venue details, the comparison view or a date on the availability calendar. | IMPLIED by PDF §6.5, §6.6, §6.7, §6.8 | MVP-P1 | yes |  |
| `CA-BOOK-02` | Step: choose the event date from the venue's availability calendar. | PDF §6.8 (choose date and time) · project.md › Booking Flow (Choose Date) | MVP-P1 | yes |  |
| `CA-BOOK-03` | Step: choose the time/session. | PDF §6.8 (choose date and time) · project.md › Booking Flow (Choose Time) | MVP-P1 | yes | CF-09: granularity undefined (evening vs full day, multiple halls, men/women sections). Design a session picker that collapses when the venue has a single session. |
| `CA-BOOK-04` | Step: choose a package. | PDF §6.8 · project.md › Booking Flow (Choose Package) | MVP-P1 | yes |  |
| `CA-BOOK-05` | Step: add optional extras priced separately. | PDF §6.8 · project.md › Booking Flow (Add Extras) | MVP-P1 | yes | GAP: no extras/add-on management is specified in the hotel app or venue dashboard (HA-VMGT-05). |
| `CA-BOOK-06` | Step: confirm guest count within the package and venue limits. | PDF §6.8 · project.md › Booking Flow (Guest Count) | MVP-P1 | yes | Price may scale per guest; validate against min/max. |
| `CA-BOOK-07` | Step: personal information (name, phone, email), prefilled from the profile. | PDF §6.8 · project.md › Booking Flow (Personal Information) | MVP-P1 | yes | The venue can call the client from the booking (HA-BOOK-06); tell the user who sees their number. |
| `CA-BOOK-08` | Step: free-text special requests. | PDF §6.8 · project.md › Booking Flow (Special Requests) | MVP-P1 | yes |  |
| `CA-BOOK-09` | Step: review booking with itemised price (package, extras, discounts), deposit due now, balance and venue policies. | PDF §6.8 · project.md › Booking Flow (Review Booking) | MVP-P1 | yes | Total, deposit and balance must be unambiguous before Confirm. Amended by ADR 0033 (voucher model, 2026-10-14): review shows standard price, voucher price and saving; no deposit or balance. |
| `CA-BOOK-10` | Step: Confirm submits a booking request with status Pending, or books immediately for instant-booking venues. | PDF §6.8 · project.md › Booking Flow (Confirm) | MVP-P1 | yes | See CA-BOOK-15 and CA-STAT-03. Amended by ADR 0033 (voucher model, 2026-10-14): Confirm sends a voucher-bound request; there is no instant booking. |
| `CA-BOOK-11` | Step: deposit payment follows Confirm (payment methods in the CA-PAY group). | PDF §6.8 · project.md › Booking Flow (Deposit Payment) | MVP-P1 | yes | Resolved by ADR 0001: request-then-pay. The deposit is a second payment session after the venue approves (the pay-by window, ADR 0005), never at Confirm; instant-booking halls pay immediately (CA-BOOK-15). Nothing is charged or held at request. Pending owner answer OQ-B-01. Superseded by ADR 0033 (voucher model, 2026-10-14): the KD 2 voucher is paid before the request (CA-VCH-05). |
| `CA-BOOK-12` | A booking confirmation screen shows the reference number, status, venue contact and next steps. | PDF §6.8 · project.md › Booking Flow (Booking Confirmation) | MVP-P1 | yes |  |
| `CA-BOOK-13` | An invoice or receipt for the payment is available after confirmation (view, download, share as PDF). | PDF §6.8 · project.md › Booking Flow (Invoice) | MVP-P1 | yes | Invoice vs receipt: deposit = receipt, final invoice after full payment. Bilingual PDF (PL-CORE-07). Kuwait tax treatment: CF-34. Amended by ADR 0033 (voucher model, 2026-10-14): the receipt is for the voucher (CA-VCH-14); there is no event invoice. |
| `CA-BOOK-14` | Displayed price reflects date-dependent pricing (weekday, weekend, holiday, season) and updates live as package, extras and guests change. | IMPLIED by PDF §2 (seasonal rates) and §8.5 | MVP-P1 | yes |  |
| `CA-BOOK-15` | Instant-booking venues confirm immediately after successful deposit, without waiting for venue approval. | IMPLIED by PDF §6.4 (instant booking filter) | MVP-P1 | yes | CF-08: PDF never defines instant booking; behaviour inferred from the filter. Venue opts in per venue. Superseded by ADR 0033 (voucher model, 2026-10-14): instant booking is removed. |
| `CA-BOOK-16` | If the chosen date or session is taken during checkout, the user is told before payment and offered alternatives. | IMPLIED by PDF §2 (live availability) | MVP-P1 | yes | Needs a short availability hold (PL-BOOK-02). |
| `CA-BOOK-17` | User must accept the venue's cancellation policy and platform terms before confirming. | IMPLIED by PDF §6.6 and §6.8 | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): consent covers the venue terms, voucher terms and platform terms, not a cancellation tier schedule. |

### CA-PAY — Payment (PDF §6.9) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-PAY-01` | User can pay with KNET. | PDF §6.9 · project.md › Payment | MVP-P1 | yes | Via MyFatoorah (PDF §11). KNET is a bank redirect: in-app web view plus deep-link return; Kuwait bank cards only. Amended by ADR 0033 (voucher model, 2026-10-14): KNET now pays the KD 2 voucher, not a deposit. |
| `CA-PAY-02` | User can pay with Visa. | PDF §6.9 · project.md › Payment | MVP-P1 | yes | Card entry handled by gateway-hosted page/SDK (NF-PAYS-01). Amended by ADR 0033 (voucher model, 2026-10-14): pays the KD 2 voucher. |
| `CA-PAY-03` | User can pay with Mastercard. | PDF §6.9 · project.md › Payment | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): pays the KD 2 voucher. |
| `CA-PAY-04` | User can pay with Apple Pay on iOS. | PDF §6.9 · project.md › Payment | MVP-P1 | yes | iOS only; sheet through MyFatoorah. Amended by ADR 0033 (voucher model, 2026-10-14): pays the KD 2 voucher. |
| `CA-PAY-05` | User can pay with Google Pay on Android. | PDF §6.9 · project.md › Payment | MVP-P1 | yes | Android only. Amended by ADR 0033 (voucher model, 2026-10-14): pays the KD 2 voucher. |
| `CA-PAY-06` | Cash is offered as a payment option only for venues that enable it. | PDF §6.9 (cash where the venue allows it) · project.md › Payment (Cash (optional)) | MVP-P1 | yes | CF-27: conflicts with the online 'deposit payment' step. Working call: cash covers the balance at the venue only; the deposit is always online. Superseded by ADR 0033 (voucher model, 2026-10-14): no cash and no event payment exists in the app; the client pays the venue directly off-app. |
| `CA-PAY-07` | User can pay the booking as a deposit (partial payment). | PDF §6.9 · project.md › Payment (Deposit) | MVP-P1 | yes | CF-08: deposit amount rule undefined (percentage vs fixed, per venue or platform-wide), as are forfeiture and refund rules. Superseded by ADR 0033 (voucher model, 2026-10-14): no deposit. |
| `CA-PAY-08` | User can pay the full amount up front. | PDF §6.9 · project.md › Payment (Full Payment) | MVP-P1 | yes |  Superseded by ADR 0033 (voucher model, 2026-10-14): no full payment in the app. |
| `CA-PAY-09` | Installment payments. | PDF §14 (deferred) · project.md › Payment (Installments (Future)) | deferred | no | Deferred. project.md lists it under Payment as '(Future)'; PDF lists it only in the deferred features (§14). Superseded by ADR 0033 (voucher model, 2026-10-14): remains deferred; no installments. |
| `CA-PAY-10` | Payment outcome screens: success, failed (retry or switch method) and pending bank confirmation. | IMPLIED by PDF §6.9 | MVP-P1 | yes | Driven by gateway webhooks (PL-PAY-02). Amended by ADR 0033 (voucher model, 2026-10-14): outcomes apply to the voucher payment (CL-PAYM-*). |
| `CA-PAY-11` | User can pay the remaining balance in the app before the event where the venue accepts online payment. | IMPLIED by PDF §6.9 (deposit or full payment) | MVP-P1 | yes | GAP: balance due date, reminders and what happens on non-payment are not specified. Superseded by ADR 0033 (voucher model, 2026-10-14): no balance exists in the app. |

### CA-STAT — Booking status and management (PDF §6.10) (10)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-STAT-01` | A Bookings list shows all of the user's bookings grouped by status with venue, date and amount. | IMPLIED by PDF §6.10 and §6.16 (bookings) | MVP-P1 | yes |  |
| `CA-STAT-02` | Booking detail shows summary, status timeline, payments, policies, invoice, venue contact and a chat entry. | IMPLIED by PDF §6.10 | MVP-P1 | yes |  |
| `CA-STAT-03` | Status Pending: request submitted and awaiting the venue's response. | PDF §6.10 · project.md › Booking Status (Pending) | MVP-P1 | yes | Resolved by ADR 0001 and 0003: a requested booking holds and charges nothing. Response window is configuration (working call 24 h, OQ-B-01); on expiry the request ends with nothing to release. 'Expired' is not one of the six PRD statuses: it maps to the Cancelled family and shows as 'Missed' on the hotel side (ADR 0003 D2; PL-BOOK-03). |
| `CA-STAT-04` | Status Approved: the venue accepted; the date is held for the couple until the pay-by time and is secured only once the deposit is paid (Confirmed). | PDF §6.10 · project.md › Booking Status (Approved) | MVP-P1 | yes | Resolved by ADR 0001 and 0003 (booking-state-machine section 12): Approved is awaiting_deposit ('held for you until {time}'); the date is secured at confirmed. Amended by ADR 0033 (voucher model, 2026-10-14): the date is secured only when the client confirms within 24 hours (CA-STAT-11). |
| `CA-STAT-05` | Status Rejected: the venue declined; the reason is shown and nothing was charged. | PDF §6.10 · project.md › Booking Status (Rejected) | MVP-P1 | yes | Venue must supply a reason (HA-BOOK-04). A rejection has no refund outcome because no money moved (ADR 0001 D4; booking-state-machine section 12). Amended by ADR 0033 (voucher model, 2026-10-14): rejection says the voucher is still the client's. |
| `CA-STAT-06` | Status Cancelled: the booking was cancelled by the client or the venue. | PDF §6.10 · project.md › Booking Status (Cancelled) | MVP-P1 | yes |  |
| `CA-STAT-07` | Status Completed: the event date has passed. | PDF §6.10 · project.md › Booking Status (Completed) | MVP-P1 | yes | Unlocks review submission (CA-REV-01). |
| `CA-STAT-08` | Status Refunded: money was returned; amount, method and expected date are shown. | PDF §6.10 · project.md › Booking Status (Refunded) | MVP-P1 | yes | Refund ownership: CF-26. Superseded by ADR 0033 (voucher model, 2026-10-14): Refunded is a voucher state, not a booking status. |
| `CA-STAT-09` | Client can cancel a booking per the venue's cancellation policy and sees the refund outcome before confirming. | IMPLIED by PDF §6.10 (Cancelled) and §6.6 (cancellation policy) | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): cancel shows the voucher outcome, not a refund calculator. |
| `CA-STAT-10` | Client is notified of a venue-proposed reschedule and can accept or decline it. | IMPLIED by PDF §7.2 (venue can reschedule) | MVP-P1 | yes | GAP: PDF gives the venue a Reschedule action but defines no client-side counterpart. Amended by ADR 0033 (voucher model, 2026-10-14): counter-offer keeps the voucher price; no reschedule after confirmation. |

### CA-PLAN — Wedding planner (PDF §6.11) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-PLAN-01` | After the user selects or books a venue, the app asks 'Need a wedding planner?'. | PDF §6.11 (offered after venue selection) · project.md › Wedding Planner Feature | MVP-P2 | yes | GAP: trigger point ambiguous (on venue selection, at booking confirmation, or on Approved). Working call: after booking confirmation. project.md calls this 'the biggest differentiator'; PDF does not. |
| `CA-PLAN-02` | Answering No dismisses the prompt without penalty and keeps the planner reachable from Plan and Services. | IMPLIED by PDF §6.11 | MVP-P2 | yes |  |
| `CA-PLAN-03` | Planner packages Silver, Gold and Royal are shown with inclusions and price. | PDF §6.11 · project.md › Wedding Planner Feature (Silver, Gold, Royal) | MVP-P2 | yes | GAP: contents and prices of the tiers are undefined; they are configured in SA-PLNR-01. Revenue model: MK-SVC-01. |
| `CA-PLAN-04` | User can select a planner package. | PDF §6.11 · project.md › Wedding Planner Feature | MVP-P2 | yes |  |
| `CA-PLAN-05` | User can request a consultation (preferred time, notes). | PDF §6.11 · project.md › Wedding Planner Feature (Request Consultation) | MVP-P2 | yes | GAP: whether the consultation is free. Request routes to a Super Admin-assigned planner (SA-PLNR-04). |
| `CA-PLAN-06` | User can schedule a meeting with the planner by picking a slot from the planner's availability. | PDF §6.11 · project.md › Wedding Planner Feature (Schedule Meeting) | MVP-P2 | yes | GAP: meeting type (video, phone, in-person) and calendar export. Availability from SA-PLNR-03. |
| `CA-PLAN-07` | Once assigned, the planner's profile (name, role, package, contact) is shown in the app. | IMPLIED by PDF §9.8 (assignments) | MVP-P2 | yes |  |
| `CA-PLAN-08` | Planner request status is visible (requested, assigned, meeting scheduled). | IMPLIED by PDF §6.11 | MVP-P2 | yes |  |
| `CA-PLAN-09` | A planner can be requested outside the venue-booking flow, from Plan or Services. | IMPLIED by PDF §6.11 | MVP-P2 | yes | CF-17: PDF only offers the planner after venue selection; planner chat itself is CA-CHAT-03. No planner-facing interface exists in any of the four products (PL-CORE-12). |

### CA-SVC — Wedding services marketplace (PDF §6.12) (12)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-SVC-01` | A Services area lists wedding service categories. | PDF §6.12 · project.md › Additional Wedding Services | MVP-P2 | yes | CF-13: PDF §4 says vendor categories arrive after the MVP; PDF §14 Phase 2 and §6.12 put the marketplace in the MVP. Treated as MVP-P2. |
| `CA-SVC-02` | Category group: photography and videography. | PDF §6.12 (Photography and videography) · project.md › Additional Wedding Services (Photography; Videography) | MVP-P2 | yes | project.md lists 16 leaf categories, PDF groups them into 7 bullets. Model 16 leaf categories under 7 groups. |
| `CA-SVC-03` | Category group: flowers and cake. | PDF §6.12 · project.md › Additional Wedding Services (Flowers; Cake) | MVP-P2 | yes |  |
| `CA-SVC-04` | Category group: DJ, MC and live music. | PDF §6.12 · project.md › Additional Wedding Services (DJ; MC; Live Music) | MVP-P2 | yes |  |
| `CA-SVC-05` | Category group: henna and bridal makeup. | PDF §6.12 · project.md › Additional Wedding Services (Henna; Bridal Makeup) | MVP-P2 | yes |  |
| `CA-SVC-06` | Category group: wedding dress and suit rental. | PDF §6.12 · project.md › Additional Wedding Services (Wedding Dress; Suit Rental) | MVP-P2 | yes |  |
| `CA-SVC-07` | Category group: luxury cars and invitations. | PDF §6.12 · project.md › Additional Wedding Services (Luxury Cars; Invitations) | MVP-P2 | yes |  |
| `CA-SVC-08` | Category group: hotels, travel and honeymoon. | PDF §6.12 · project.md › Additional Wedding Services (Hotels; Travel; HoneyMoon) | MVP-P2 | yes | Ambiguous: 'Hotels' here is guest/bridal-suite accommodation, not wedding venues; 'Travel' vs 'Honeymoon agencies' (PDF §4) overlap. |
| `CA-SVC-09` | Each category lists vendors with name, rating, starting price and photos. | IMPLIED by PDF §6.12 | MVP-P2 | yes |  |
| `CA-SVC-10` | A vendor profile shows description, packages and pricing, portfolio, reviews and availability. | IMPLIED by PDF §6.12 | MVP-P2 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): adds the voucher price (CA-SVC-14). |
| `CA-SVC-11` | User can send a service request or enquiry to a vendor. | IMPLIED by PDF §6.12 and §14 (services marketplace) | MVP-P2 | yes | GAP: no vendor booking/payment flow is specified. Working call: enquiry that opens vendor chat (CA-CHAT-04); no vendor checkout in MVP. Amended by ADR 0033 (voucher model, 2026-10-14): enquiry is complemented by a voucher request (CA-SVC-15). |
| `CA-SVC-12` | Vendor categories beyond §6.12: decoration companies, catering and entertainment. | PDF §4 (vendor categories, introduced after the MVP) · project.md › Future Vendors (Decoration Companies, Catering Companies, Entertainment) | deferred | no | CF-16: these appear as target vendors but not in §6.12 services; §4 says they arrive after the MVP. Owner to confirm. Amended by ADR 0033 (voucher model, 2026-10-14): un-deferred: decoration, catering and entertainment are now categories (CA-SVC-13). |

### CA-TOOL — Planning tools: wishlist, budget, checklist, countdown (PDF §6.13) (19)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-TOOL-01` | User can save a venue to the wishlist from a card or details. | PDF §6.13 · project.md › Wishlist (Save Venues) | MVP-P1 | yes | Card 'Favorite' and wishlist 'Save Venues' are the same list; also project.md Profile > Saved Venues. |
| `CA-TOOL-02` | User can save a service or vendor to the wishlist. | PDF §6.13 · project.md › Wishlist (Save Services) | MVP-P2 | yes |  |
| `CA-TOOL-03` | User can save a package to the wishlist. | PDF §6.13 · project.md › Wishlist (Save Packages) | MVP-P2 | yes | Ambiguous: venue package vs planner package; support both. |
| `CA-TOOL-04` | A wishlist screen groups saved items by type (venues, services, packages) and allows removal. | IMPLIED by PDF §6.13 | MVP-P1 | yes |  |
| `CA-TOOL-05` | User can set and edit a total wedding budget, asked in the Budget Manager (onboarding only gives the venue and catering band, shown as a reference for that category). | PDF §6.13 · project.md › Wedding Budget Manager (Budget) | MVP-P2 | yes | CF-14: planning tools are in the MVP (PDF §14 prose) but not assigned to Phase 1 or 2; treated as MVP-P2 'stickiness' layer. Not prefilled from onboarding (ADR 0007 D3 amendment, OQ-P-17). |
| `CA-TOOL-06` | Budget Manager shows the amount spent (recorded expenses plus in-app payments). | PDF §6.13 · project.md › Wedding Budget Manager (Spent) | MVP-P2 | yes |  |
| `CA-TOOL-07` | Budget Manager shows the remaining amount (budget minus spent). | PDF §6.13 · project.md › Wedding Budget Manager (Remaining) | MVP-P2 | yes |  |
| `CA-TOOL-08` | User can allocate the budget across categories and see spent vs allocated per category. | PDF §6.13 · project.md › Wedding Budget Manager (Categories) | MVP-P2 | yes | GAP: default category list. Working call: venue, buffet/catering, photography and video, flowers and decoration, attire, makeup and henna, cars, invitations, music, honeymoon (aligned to §6.12). |
| `CA-TOOL-09` | User is alerted when a category or the total approaches or exceeds budget. | PDF §6.13 · project.md › Wedding Budget Manager (Alerts) | MVP-P2 | yes | GAP: thresholds (working call: 80% and 100%). Delivered in-app and by push (CA-NOTI-08). Rules-based only (AI optimisation: CA-REC-04). |
| `CA-TOOL-10` | User can add manual expenses for purchases made outside Ghazal. | IMPLIED by PDF §6.13 (spent) | MVP-P2 | yes |  |
| `CA-TOOL-11` | Deposits and payments made in Ghazal post automatically to the matching budget categories. | IMPLIED by PDF §6.13 and §6.9 | MVP-P2 | yes |  |
| `CA-TOOL-12` | Checklist ships with default items: invitation, dress, venue, photographer, cake, music, flowers, transportation. | PDF §6.13 (checklist with completion percentage) · project.md › Wedding Checklist | MVP-P2 | yes | Default items come from project.md only. Smart (AI) checklist and timeline are Phase 3 (RM-AI-03, RM-AI-04). |
| `CA-TOOL-13` | User can mark checklist items complete or incomplete. | IMPLIED by PDF §6.13 | MVP-P2 | yes |  |
| `CA-TOOL-14` | Checklist shows a completed percentage. | PDF §6.13 · project.md › Wedding Checklist (Completed %) | MVP-P2 | yes |  |
| `CA-TOOL-15` | User can add, edit and delete custom checklist items. | IMPLIED by PDF §6.13 | MVP-P2 | yes |  |
| `CA-TOOL-16` | The Venue checklist item completes automatically when a booking becomes Confirmed (deposit paid); an approved but unpaid booking shows it in progress. | IMPLIED by PDF §6.13 and §6.10 | MVP-P2 | yes | Wording per booking-state-machine section 12 (ADR 0001, 0003); the PRD's 'Approved' is the Approved family, secured only at confirmed. |
| `CA-TOOL-17` | Countdown shows days remaining to the wedding date. | PDF §6.13 · project.md › Wedding Countdown | MVP-P2 | yes | Date source: the confirmed booking date overrides the onboarding date; an approved but unpaid hold does not (booking-state-machine section 12). Prompt to set a date when none exists. |
| `CA-TOOL-18` | Countdown has distinct states at 365, 180, 30 and 7 days, tomorrow and today. | PDF §6.13 (countdown milestones) · project.md › Wedding Countdown | MVP-P2 | yes | Milestone list comes from project.md; PDF only says 'countdown milestones'. Same milestones trigger reminders (CA-NOTI-08). |
| `CA-TOOL-19` | After the wedding date the countdown resolves into a completed state that prompts a review. | IMPLIED by PDF §6.13 and §6.16 | MVP-P2 | yes |  |

### CA-CHAT — Chat (PDF §6.14) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-CHAT-01` | A Messages tab lists all conversations (venue, planner, vendor, support) with last message and unread count. | IMPLIED by PDF §6.14 | MVP-P2 | yes |  |
| `CA-CHAT-02` | User can chat with a venue before and after booking. | PDF §6.14 · project.md › Chat (Venue Chat) | MVP-P2 | yes | Entry points: venue details and booking detail. Hotel-side counterpart: HA-MSG-02. Pre-booking enquiries make chat valuable early, but PDF §14 schedules Chat in Phase 2. |
| `CA-CHAT-03` | User can chat with their wedding planner. | PDF §6.14 · project.md › Chat (Planner Chat) | MVP-P2 | yes | Planner-side surface undefined (CF-17). |
| `CA-CHAT-04` | User can chat with a vendor. | PDF §6.14 · project.md › Chat (Vendor Chat) | MVP-P2 | yes |  |
| `CA-CHAT-05` | User can chat with Ghazal support. | PDF §6.14 · project.md › Chat (Support Chat) | MVP-P2 | yes | Agent side: Super Admin live chat (SA-SUP-02). |
| `CA-CHAT-06` | Messages are delivered in real time with sent/delivered state. | IMPLIED by PDF §5 (real-time chat) | MVP-P2 | yes |  |
| `CA-CHAT-07` | User can send photos and videos in a conversation. | PDF §6.14 · project.md › Chat (Media Sharing) | MVP-P2 | yes | GAP: size and type limits, scanning, retention. |
| `CA-CHAT-08` | User can send documents (for example PDF contracts) in a conversation. | PDF §6.14 · project.md › Chat (Documents) | MVP-P2 | yes |  |
| `CA-CHAT-09` | User can record, send and play voice messages. | PDF §6.14 · project.md › Chat (Voice Messages) | MVP-P2 | yes | Microphone permission flow; voice notes are heavily used in Gulf messaging, expect high usage. |
| `CA-CHAT-10` | The Messages tab shows an unread badge. | IMPLIED by PDF §6.14 | MVP-P2 | yes |  |
| `CA-CHAT-11` | User can report a message or block a conversation. | IMPLIED by PDF §6.14 (user-generated content) | MVP-P2 | yes | CF-24: not in the PRD, but apps with user-generated content need report and block to pass App Store review (guideline 1.2). |

### CA-NOTI — Notifications (PDF §6.15) (8)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-NOTI-01` | An in-app notification centre lists notifications with read/unread state and deep links to the target screen. | IMPLIED by PDF §6.15 | MVP-P1 | yes |  |
| `CA-NOTI-02` | User is notified of booking updates (status changes). | PDF §6.15 · project.md › Notifications (Booking updates) | MVP-P1 | yes |  |
| `CA-NOTI-03` | User is notified of offers. | PDF §6.15 · project.md › Notifications (Offers) | MVP-P1 | yes | Marketing category, opt-out in CA-PROF-06. |
| `CA-NOTI-04` | User is notified of price drops. | PDF §6.15 · project.md › Notifications (Price drops) | MVP-P1 | yes | GAP: trigger undefined. Working call: price drop or new offer on a wishlisted or compared venue for the user's date. |
| `CA-NOTI-05` | User is notified of new venues. | PDF §6.15 · project.md › Notifications (New venues) | MVP-P1 | yes | GAP: relevance rule. Working call: new venues in preferred areas. |
| `CA-NOTI-06` | User is notified of new messages. | PDF §6.15 · project.md › Notifications (Messages) | MVP-P2 | yes | Follows chat (Phase 2). |
| `CA-NOTI-07` | User is notified of payments (receipt, failure, balance due). | PDF §6.15 · project.md › Notifications (Payments) | MVP-P1 | yes |  |
| `CA-NOTI-08` | User receives pre-wedding reminders at countdown milestones. | PDF §6.15 · project.md › Notifications (Reminder before wedding) | MVP-P2 | yes | Same milestones as CA-TOOL-18. |

### CA-REV — Reviews (PDF §6.16) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-REV-01` | User can rate a venue from 1 to 5 stars after a Completed booking. | PDF §6.16 · project.md › Reviews (Ratings) | MVP-P2 | yes | CF-24: eligibility (completed booking = verified review) is IMPLIED; PRD silent. Rating display is Phase 1 (CA-VDET-20). Vendors and planners can presumably be reviewed too. |
| `CA-REV-02` | User can add a written comment to a review. | PDF §6.16 · project.md › Reviews (Comments) | MVP-P2 | yes |  |
| `CA-REV-03` | User can attach photos to a review. | PDF §6.16 · project.md › Reviews (Photos) | MVP-P2 | yes | User photos may show people; modesty and consent norms (especially women-only events) require a moderation rule. |
| `CA-REV-04` | User can attach videos to a review. | PDF §6.16 · project.md › Reviews (Videos) | MVP-P2 | yes | Same moderation rule; upload size and transcoding cost. |
| `CA-REV-05` | Venue owner replies appear under the review. | PDF §6.16 · project.md › Reviews (Owner replies) | MVP-P2 | yes | Reply authored in VD-REV-02. |
| `CA-REV-06` | User can report a review as abusive. | IMPLIED by PDF §6.16 and §8.9 (report abuse) | MVP-P2 | yes | CF-24: PDF gives 'report abuse' to venues only; UGC rules require a user-side report path. |

### CA-PROF — Profile and settings (PDF §6.16) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-PROF-01` | User can view and edit personal information (name, phone, email). | PDF §6.16 · project.md › Profile (Personal Info) | MVP-P1 | yes | Avatars are monograms. |
| `CA-PROF-02` | User can view and edit wedding information (date, budget, guests, areas, bride/groom). | PDF §6.16 · project.md › Profile (Wedding Info) | MVP-P1 | yes | Edits propagate to countdown, budget and recommendations. |
| `CA-PROF-03` | Profile links to Saved Venues (the wishlist). | PDF §6.16 · project.md › Profile (Saved Venues) | MVP-P1 | yes | Same screen as CA-TOOL-04. |
| `CA-PROF-04` | Profile links to the Bookings list. | PDF §6.16 · project.md › Profile (Bookings) | MVP-P1 | yes | Same screen as CA-STAT-01. |
| `CA-PROF-05` | Profile shows payment history with receipts and invoices. | PDF §6.16 · project.md › Profile (Payments) | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): payment history lists voucher receipts only. |
| `CA-PROF-06` | User can set notification preferences by category (transactional vs marketing). | project.md › Profile (Notifications) (not in PDF) | MVP-P1 | yes | CF-23: only in project.md. Needed for marketing opt-out compliance, so kept. |
| `CA-PROF-07` | User can switch language between Arabic and English at any time; the change applies immediately and persists. | PDF §6.16 · project.md › Profile (Language) | MVP-P1 | yes | NF-LOC-06. |
| `CA-PROF-08` | A Settings screen holds app preferences (biometric unlock, notification preferences, language, app version). | PDF §6.16 (language and settings) · project.md › Profile (Settings) | MVP-P1 | yes |  |
| `CA-PROF-09` | User can delete their account from within the app. | PDF §6.16 and §12 (privacy) · project.md › Profile (Delete Account) | MVP-P1 | yes | NF-PRIV-01. GAP: handling of upcoming bookings/held deposits, and retention of invoices that law requires (anonymise rather than delete). Revoke Apple token (PL-CORE-10). |
| `CA-PROF-10` | User can sign out. | IMPLIED by PDF §6.1 and §6.16 | MVP-P1 | yes |  |
| `CA-PROF-11` | Profile links to the Terms of Use and Privacy Policy. | IMPLIED by PDF §17 (owner supplies legal texts) | MVP-P1 | yes | Also required as public URLs for store listings (CF-31). |

### CA-LOY — Loyalty (PDF §6.16) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-LOY-01` | User can see a loyalty points balance. | PDF §6.16 · project.md › Loyalty (Points) | MVP-P2 | yes | CF-30: loyalty is in §6.16 (so MVP per §17) but in no roadmap phase and has no rules; first candidate to slip. Superseded by ADR 0033 (voucher model, 2026-10-14): loyalty and coupons are replaced by the voucher. |
| `CA-LOY-02` | User earns points for defined actions (for example a completed booking). | IMPLIED by PDF §6.16 | MVP-P2 | yes | GAP: earn rules, expiry and who funds the points (platform vs venue). Superseded by ADR 0033 (voucher model, 2026-10-14): loyalty points are not built. |
| `CA-LOY-03` | User can redeem points as a discount on a booking. | IMPLIED by PDF §6.16 | MVP-P2 | yes | GAP: point value in KWD. Superseded by ADR 0033 (voucher model, 2026-10-14): no in-app booking payment to discount. |
| `CA-LOY-04` | A coupons wallet lists the user's coupons with conditions and expiry. | PDF §6.16 · project.md › Loyalty (Coupons) | MVP-P2 | yes | Overlaps venue coupons (HA-OFFR-04); funding and commission base undefined. Superseded by ADR 0033 (voucher model, 2026-10-14): the coupons wallet is replaced by My vouchers (CA-VCH-06). |
| `CA-LOY-05` | User can apply a coupon or points at the booking review step. | IMPLIED by PDF §6.16 and §6.8 | MVP-P2 | yes | Redemption point is not in the PRD booking flow. Superseded by ADR 0033 (voucher model, 2026-10-14): no coupon at review. |
| `CA-LOY-06` | User gets a referral code or link to share. | PDF §6.16 · project.md › Loyalty (Referral Rewards) | MVP-P2 | yes | WhatsApp is the natural share target in Kuwait. Superseded by ADR 0033 (voucher model, 2026-10-14): referral rewards are not built (OQ-V-16). |
| `CA-LOY-07` | Referrer and referee receive rewards when the referred user completes a booking. | IMPLIED by PDF §6.16 | MVP-P2 | yes | GAP: reward values and abuse limits. Superseded by ADR 0033 (voucher model, 2026-10-14): referral rewards are not built (OQ-V-16). |

### CA-REC — AI recommendations (project.md only) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-REC-01` | AI-recommended venues. | project.md › AI Recommendations (Recommend venues) (not in PDF) | P3 | no | CF-07: project.md lists it in the client app; PDF puts AI in Phase 3. MVP uses rules-based CA-HOME-15. |
| `CA-REC-02` | AI-recommended services. | project.md › AI Recommendations (Recommend services) (not in PDF) | P3 | no | CF-07. |
| `CA-REC-03` | AI-suggested package. | project.md › AI Recommendations (Suggest package) (not in PDF) | P3 | no | CF-07. |
| `CA-REC-04` | AI budget optimisation. | project.md › AI Recommendations (Budget optimization) (not in PDF) | P3 | no | CF-07/CF-14: PDF Phase 3 'AI budget planner'. MVP only has rule-based alerts (CA-TOOL-09). |

## 4. Venue / Hotel Mobile App (`HA`) — 72 lines

### HA-AUTH — Access and roles (not specified in the PRD) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-AUTH-01` | Venue staff can log in with credentials invited or issued by the venue admin or Ghazal. | IMPLIED by PDF §7 and §11 (backend JWT) | MVP-P1 | yes | CF-25: the PRD defines no login for the hotel app. Working call: phone + password or WhatsApp OTP; no Apple/Google sign-in and no guest mode for staff. |
| `HA-AUTH-02` | Visible modules and actions depend on the staff role (Manager, Reception, Accountant, Marketing). | IMPLIED by PDF §8.7 (roles) and §12 (RBAC) | MVP-P1 | yes | GAP: role-to-permission matrix. Working call: Accountant sees revenue, payments and bank info; Reception sees bookings, calendar and messages; Marketing sees offers and analytics; Manager sees all. |
| `HA-AUTH-03` | A user who manages several venues or halls can switch the active venue. | IMPLIED by PDF §7 (purpose) and CF-09 | MVP-P1 | yes | CF-09/CF-25: hotels commonly run several halls; PRD has no multi-hall or multi-venue structure. |
| `HA-AUTH-04` | Staff can sign out, and an admin can revoke a staff session. | IMPLIED by PDF §12 (security) and §8.7 | MVP-P1 | yes |  |

### HA-DASH — Dashboard (PDF §7.1) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-DASH-01` | Dashboard lists today's bookings and events (time, client, hall, guests, status). | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Today's Bookings) | MVP-P1 | yes |  |
| `HA-DASH-02` | Dashboard shows a revenue summary for a selectable period. | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Revenue) | MVP-P1 | yes | GAP: gross vs net of commission, paid vs expected, default period. Working call: paid revenue net of commission, with expected revenue shown separately. Superseded by ADR 0033 (voucher model, 2026-10-14): no revenue; the dashboard shows requests, vouchers and open dates. |
| `HA-DASH-03` | Dashboard shows the count and list of pending requests with inline accept and reject. | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Pending Requests) | MVP-P1 | yes | Pending requests should be reachable in one tap from any screen (persistent navigation badge). |
| `HA-DASH-04` | Pending requests show elapsed time and time left before auto-expiry. | IMPLIED by PDF §6.10 (Pending) and §7.1 | MVP-P1 | yes | Expiry rule: PL-BOOK-03. |
| `HA-DASH-05` | Dashboard surfaces recent notifications. | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Notifications) | MVP-P1 | yes |  |
| `HA-DASH-06` | Dashboard surfaces unread client messages. | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Messages) | MVP-P2 | yes | Follows chat (Phase 2). |
| `HA-DASH-07` | Dashboard shows availability at a glance for the coming period (open, booked, blocked). | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Availability) | MVP-P1 | yes |  |

### HA-BOOK — Bookings (PDF §7.2) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-BOOK-01` | A bookings list with Pending, Upcoming and Past views (a chip row for the finer statuses: Awaiting deposit, Confirmed, Declined, Expired, Cancelled, Completed, Refunded), search and date filter. | IMPLIED by PDF §7.2 and §6.10 | MVP-P1 | yes | The PRD's six status tabs are the reporting vocabulary (PL-BOOK-01), not the app's tabs: booking-state-machine section 12 and ADR 0008 use Pending / Upcoming / Past. |
| `HA-BOOK-02` | Booking detail shows client, event date and session, hall, package, extras, guests, special requests, price and payment status. | IMPLIED by PDF §7.2 | MVP-P1 | yes |  |
| `HA-BOOK-03` | Venue can accept a pending booking. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Accept) | MVP-P1 | yes |  |
| `HA-BOOK-04` | Venue can reject a pending booking and must give a reason. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Reject) | MVP-P1 | yes | Reason is IMPLIED: client sees it (CA-STAT-05). A rejection moves no money: nothing was charged at request (ADR 0001 D4; CF-08 resolved). |
| `HA-BOOK-05` | Venue can reschedule a booking to another available date or session. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Reschedule) | MVP-P1 | yes | Needs client consent (CA-STAT-10). Amended by ADR 0033 (voucher model, 2026-10-14): counter-offer only; no reschedule of a confirmed booking. |
| `HA-BOOK-06` | Venue can call the client from the booking with one tap. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Call Client) | MVP-P1 | yes | Privacy: decide when the client's number is revealed (working call: once the booking is Approved or the client enquires by chat). Masked calling is out of scope. |
| `HA-BOOK-07` | The Chat action on a booking opens or creates the conversation with that client. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Chat) | MVP-P2 | yes | Channel itself: HA-MSG-02. |
| `HA-BOOK-08` | Venue can view and share the booking invoice as a PDF. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Invoice) | MVP-P1 | yes | Generated by PL-CORE-07. |
| `HA-BOOK-09` | Booking shows payment status (deposit paid, balance due, paid in full, refunded) and amounts received. | IMPLIED by PDF §7.2 and §8.2 (payment status), §7.7 (payment received) | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): shows the voucher status, not payments. |
| `HA-BOOK-10` | Venue can cancel an approved booking with a reason and sees the refund consequence first. | IMPLIED by PDF §6.10 (Cancelled) | MVP-P1 | yes | GAP: venue-initiated cancellation penalties; refund ownership CF-26. Amended by ADR 0033 (voucher model, 2026-10-14): cancel shows the voucher consequence, not a refund calculation. |
| `HA-BOOK-11` | A booking becomes Completed after the event date, automatically or by manual confirmation. | IMPLIED by PDF §6.10 (Completed) | MVP-P1 | yes | GAP: who sets Completed. Working call: automatic the day after the event. |

### HA-CAL — Calendar (PDF §7.3) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-CAL-01` | Calendar offers a monthly view. | PDF §7.3 · project.md › Hotel/Venue Mobile App › Calendar (Monthly) | MVP-P1 | yes | Week starts Sunday; Friday and Saturday are the Kuwait weekend. |
| `HA-CAL-02` | Calendar offers a weekly view. | PDF §7.3 · project.md › Hotel/Venue Mobile App › Calendar (Weekly) | MVP-P1 | yes |  |
| `HA-CAL-03` | Calendar offers a daily view. | PDF §7.3 · project.md › Hotel/Venue Mobile App › Calendar (Daily) | MVP-P1 | yes |  |
| `HA-CAL-04` | Venue can block a date or a date range, with an optional reason, and unblock it. | PDF §7.3 · project.md › Hotel/Venue Mobile App › Calendar (Blocked Dates) | MVP-P1 | yes | Covers offline bookings taken by phone, maintenance and private events. Drag and drop is web-only (PDF §8.3). |
| `HA-CAL-05` | Venue can mark dates as available and see them distinct from booked and blocked dates. | PDF §7.3 · project.md › Hotel/Venue Mobile App › Calendar (Available Dates) | MVP-P1 | yes | Semantics: a date is available unless blocked or booked; this action reopens blocked dates and shows open ones. |
| `HA-CAL-06` | Calendar marks booked (approved), pending (held) and blocked dates distinctly, never by colour alone. | IMPLIED by PDF §7.3 | MVP-P1 | yes |  |
| `HA-CAL-07` | Tapping a date opens its day agenda and the related booking. | IMPLIED by PDF §7.3 | MVP-P1 | yes |  |
| `HA-CAL-08` | Changes to blocked or available dates appear on the client availability calendar within seconds. | IMPLIED by PDF §2 (live availability per venue) | MVP-P1 | yes | Backed by PL-BOOK-02. |
| `HA-CAL-09` | Calendar supports several halls or sessions per venue. | IMPLIED by PDF §7.3 and CF-09 | MVP-P1 | yes | CF-09: undefined in the PRD; design must accommodate it without clutter. |

### HA-VMGT — Venue management (PDF §7.4) (10)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-VMGT-01` | Venue can upload, reorder, set a cover for and delete photos. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Photos) | MVP-P1 | yes | GAP: do listing edits go live immediately or after Super Admin review (SA-VAPP-01)? |
| `HA-VMGT-02` | Venue can upload and remove videos. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Videos) | MVP-P1 | yes | Large uploads on mobile data: resumable background upload. Video storage and CDN egress may exceed the PDF §16 cost envelope (CF-28). |
| `HA-VMGT-03` | Venue can create, edit and archive packages (name, inclusions, price, minimum and maximum guests). | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Packages) | MVP-P1 | yes |  |
| `HA-VMGT-04` | Venue can edit prices of packages. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Prices) | MVP-P1 | yes | GAP: weekday/weekend/holiday/season pricing is a web feature (PDF §8.5); mobile scope for date-based overrides is undefined. Working call: base price only on mobile. |
| `HA-VMGT-05` | Venue can manage extras (add-ons) offered in the client booking flow. | IMPLIED by PDF §6.8 (Add Extras) | MVP-P1 | yes | GAP: PRD has extras in booking but no way for a venue to define them (CA-BOOK-05). |
| `HA-VMGT-06` | Venue can edit capacity. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Capacity) | MVP-P1 | yes |  |
| `HA-VMGT-07` | Venue can edit amenities. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Amenities) | MVP-P1 | yes | Description, rules and FAQs are web-only in the PRD (PDF §8.4). |
| `HA-VMGT-08` | Venue can edit policies (cancellation, children, dress code). | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Policies) | MVP-P1 | yes |  |
| `HA-VMGT-09` | Venue-authored text can be entered in Arabic and English. | IMPLIED by PDF §12 (localisation) | MVP-P1 | yes | GAP: see PL-CORE-08. Show per-language completeness. |
| `HA-VMGT-10` | The venue management hub links to Offers and Availability management. | PDF §7.4 · project.md › Hotel/Venue Mobile App › Venue Management (Offers, Availability) | MVP-P1 | yes | Canonical items: HA-OFFR and HA-CAL. |

### HA-OFFR — Offers (PDF §7.5) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-OFFR-01` | Venue can create an offer with title, discount, validity dates and applicable packages or dates. | PDF §7.5 · project.md › Hotel/Venue Mobile App › Offers (Create Offer) | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): offers become voucher-price settings. |
| `HA-OFFR-02` | Venue can launch a flash sale (time-boxed or date-specific discount). | PDF §7.5 · project.md › Hotel/Venue Mobile App › Offers (Flash Sale) | MVP-P1 | yes | Feeds Last-Minute Deals (CA-HOME-11). Amended by ADR 0033 (voucher model, 2026-10-14): a flash sale is a time-boxed voucher price. |
| `HA-OFFR-03` | Venue can set a percentage or fixed-KWD discount. | PDF §7.5 · project.md › Hotel/Venue Mobile App › Offers (Discount) | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): the discount is the voucher price. |
| `HA-OFFR-04` | Venue can create coupon codes with usage limit and expiry. | PDF §7.5 · project.md › Hotel/Venue Mobile App › Offers (Coupon) | MVP-P1 | yes | GAP: who funds a coupon, and whether commission applies before or after the discount. Superseded by ADR 0033 (voucher model, 2026-10-14): venue coupon codes are removed. |
| `HA-OFFR-05` | Venue can view offers by state (active, scheduled, expired) and pause or end an offer. | IMPLIED by PDF §7.5 | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): states apply to voucher-price windows. |
| `HA-OFFR-06` | Active offers appear to clients as card badges, in Special Offers and in the booking price. | IMPLIED by PDF §6.3 and §7.5 | MVP-P1 | yes |  Amended by ADR 0033 (voucher model, 2026-10-14): shown as the voucher price and saving. |

### HA-ANLY — Analytics (PDF §7.6) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-ANLY-01` | Analytics show venue views. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Views) | MVP-P1 | yes | Source event: NF-ANL-02. |
| `HA-ANLY-02` | Analytics show clicks. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Clicks) | MVP-P1 | yes | GAP: define a click (card tap, phone tap, map tap). |
| `HA-ANLY-03` | Analytics show bookings. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Bookings) | MVP-P1 | yes |  |
| `HA-ANLY-04` | Analytics show revenue. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Revenue) | MVP-P1 | yes |  Superseded by ADR 0033 (voucher model, 2026-10-14): no revenue in the app; see HA-ANLY-08. |
| `HA-ANLY-05` | Analytics show the conversion rate. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Conversion) | MVP-P1 | yes | Working definition: bookings requested divided by venue views. |
| `HA-ANLY-06` | Analytics show top packages. | PDF §7.6 · project.md › Hotel/Venue Mobile App › Analytics (Top Packages) | MVP-P1 | yes |  |
| `HA-ANLY-07` | Analytics can be filtered by date range. | IMPLIED by PDF §7.6 | MVP-P1 | yes | MK-SUB-06 (premium analytics) may gate depth; free vs premium split undefined. |

### HA-NOTI — Notifications (PDF §7.7) (8)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-NOTI-01` | Venue staff are notified of a new booking request. | PDF §7.7 · project.md › Hotel/Venue Mobile App › Notifications (New Booking) | MVP-P1 | yes | Highest-priority alert; must stand out from other notifications. |
| `HA-NOTI-02` | Venue staff are notified of a cancelled booking. | PDF §7.7 · project.md › Hotel/Venue Mobile App › Notifications (Cancelled Booking) | MVP-P1 | yes |  |
| `HA-NOTI-03` | Venue staff are notified when a payment is received. | PDF §7.7 · project.md › Hotel/Venue Mobile App › Notifications (Payment Received) | MVP-P1 | yes |  |
| `HA-NOTI-04` | Venue staff are notified of new reviews. | PDF §7.7 · project.md › Hotel/Venue Mobile App › Notifications (Reviews) | MVP-P2 | yes | Reviews are Phase 2. |
| `HA-NOTI-05` | Venue staff are notified of new client messages. | IMPLIED by PDF §7.1 (messages) | MVP-P2 | yes |  |
| `HA-NOTI-06` | An in-app notification list shows read and unread items. | IMPLIED by PDF §7.7 | MVP-P1 | yes |  |
| `HA-NOTI-07` | Tapping a notification opens the related booking, message or review. | IMPLIED by PDF §7.7 | MVP-P1 | yes |  |
| `HA-NOTI-08` | Staff can choose which notification types they receive, limited by role. | IMPLIED by PDF §7.7 and §8.7 | MVP-P1 | yes |  |
| `HA-NOTI-09` | From a new-review notification the venue can read the review, reply once and report abuse; full review management stays on the web dashboard. | IMPLIED by PDF §7.7 (review notifications) and §8.9 (VD-REV-02/03) | MVP-P2 | yes | GAP: the PRD gives the hotel app only a review notification; reply and report are web-only (VD-REV-02/03). The app screen HL-GROW-06 is a proposal for owner approval (OQ-P-18); striking this line leaves a read-only review landing. The venue never approves, edits or hides a review (CF-24). |

### HA-SET — Settings (PDF §7.8) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-SET-01` | Admin can invite, deactivate and remove staff. | PDF §7.8 · project.md › Hotel/Venue Mobile App › Settings (Staff) | MVP-P1 | yes | Full staff and role management is also on the web (PDF §8.7). |
| `HA-SET-02` | Admin can assign a role (Manager, Reception, Accountant, Marketing) to each staff member. | IMPLIED by PDF §8.7 and §7.8 | MVP-P1 | yes |  |
| `HA-SET-03` | Admin can enter and edit bank information (account holder, bank, IBAN) used for settlement. | PDF §7.8 · project.md › Hotel/Venue Mobile App › Settings (Bank Info) | MVP-P1 | yes | Kuwait IBAN is 30 characters starting 'KW': validate. Changes need re-authentication. Payout rules: SA-COMM-06. Superseded by ADR 0033 (voucher model, 2026-10-14): no bank information exists for partners. |
| `HA-SET-04` | Admin can set business hours. | PDF §7.8 · project.md › Hotel/Venue Mobile App › Settings (Business Hours) | MVP-P1 | yes | Shown to clients as working hours (CA-VDET-19). |
| `HA-SET-05` | Staff can switch the app language between Arabic and English. | PDF §7.8 · project.md › Hotel/Venue Mobile App › Settings (Languages) | MVP-P1 | yes | NF-LOC-06. |

### HA-MSG — Messages (PDF §7.1, §7.2) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-MSG-01` | A Messages list shows client conversations with unread counts. | PDF §7.1 · project.md › Hotel/Venue Mobile App › Dashboard (Messages) | MVP-P2 | yes | GAP: shared inbox vs per-user (reception hands over to manager). |
| `HA-MSG-02` | Venue staff can exchange real-time text messages with a client. | PDF §7.2 · project.md › Hotel/Venue Mobile App › Bookings (Chat) | MVP-P2 | yes | Client side: CA-CHAT-02. |
| `HA-MSG-03` | Venue staff can send and receive photos, documents and voice messages. | IMPLIED by PDF §6.14 (media, documents, voice) | MVP-P2 | yes | Assumed symmetric with the client app. |
| `HA-MSG-04` | A conversation links to the related booking. | IMPLIED by PDF §7.2 | MVP-P2 | yes |  |
| `HA-MSG-05` | Venue staff can contact Ghazal support (ticket or chat). | IMPLIED by PDF §9.9 (tickets, live chat) | MVP-P2 | yes | GAP: PDF §6.14 defines support chat for clients only. |

## 5. Venue Admin Dashboard (web) (`VD`) — 58 lines

### VD-DASH — Venue dashboard: overview (PDF §8.1) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-DASH-01` | Dashboard shows revenue. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Revenue) | MVP-P1 | no | Context only this pass (web dashboards are the next design pass). |
| `VD-DASH-02` | Dashboard shows booking counts. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Bookings) | MVP-P1 | no |  |
| `VD-DASH-03` | Dashboard lists today's events. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Today's Events) | MVP-P1 | no |  |
| `VD-DASH-04` | Dashboard shows occupancy rate. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Occupancy Rate) | MVP-P1 | no | GAP: denominator (dates vs hall-sessions), CF-09. |
| `VD-DASH-05` | Dashboard shows pending bookings. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Pending Bookings) | MVP-P1 | no |  |
| `VD-DASH-06` | Dashboard shows average rating. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Average Rating) | MVP-P1 | no |  |
| `VD-DASH-07` | Dashboard shows top packages. | PDF §8.1 · project.md › Venue Admin Panel (Web) › Dashboard (Top Packages) | MVP-P1 | no |  |

### VD-BOOK — Venue dashboard: bookings (PDF §8.2) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-BOOK-01` | Venue can approve a booking. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Approve) | MVP-P1 | no |  |
| `VD-BOOK-02` | Venue can reject a booking. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Reject) | MVP-P1 | no |  |
| `VD-BOOK-03` | Venue can reschedule a booking. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Reschedule) | MVP-P1 | no |  |
| `VD-BOOK-04` | Venue can generate and download invoices. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Invoice) | MVP-P1 | no |  |
| `VD-BOOK-05` | Venue can issue a full or partial refund. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Refund) | MVP-P1 | no | CF-26: refunds are also owned by Super Admin Finance (PDF §9.11) and Support (PDF §9.9); authority and limits undefined. |
| `VD-BOOK-06` | Venue can see payment status per booking. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Payment Status) | MVP-P1 | no |  |
| `VD-BOOK-07` | Venue can export bookings. | PDF §8.2 · project.md › Venue Admin Panel (Web) › Booking Management (Export) | MVP-P1 | no | GAP: formats (CSV, Excel, PDF). |

### VD-CAL — Venue dashboard: calendar (PDF §8.3) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-CAL-01` | Venue can move a booking by drag and drop on the calendar. | PDF §8.3 · project.md › Venue Admin Panel (Web) › Calendar Management (Drag & Drop) | MVP-P1 | no |  |
| `VD-CAL-02` | Venue can block dates. | PDF §8.3 · project.md › Venue Admin Panel (Web) › Calendar Management (Block Dates) | MVP-P1 | no | Parity with HA-CAL-04. |
| `VD-CAL-03` | Venue can define season pricing on the calendar. | PDF §8.3 · project.md › Venue Admin Panel (Web) › Calendar Management (Season Pricing) | MVP-P1 | no | Duplicates the pricing engine (VD-PRC-04); calendar is the editing surface, engine is the rule store. |
| `VD-CAL-04` | Venue can define peak pricing on the calendar. | PDF §8.3 · project.md › Venue Admin Panel (Web) › Calendar Management (Peak Pricing) | MVP-P1 | no | Overlaps season/holiday pricing; define precedence. |
| `VD-CAL-05` | Venue can mark special events on dates. | PDF §8.3 · project.md › Venue Admin Panel (Web) › Calendar Management (Special Events) | MVP-P1 | no | GAP: meaning (private venue events that block dates, or special-priced dates). |

### VD-VMGT — Venue dashboard: venue content (PDF §8.4) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-VMGT-01` | Venue can manage the photo gallery. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Gallery) | MVP-P1 | no |  |
| `VD-VMGT-02` | Venue can manage videos. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Videos) | MVP-P1 | no |  |
| `VD-VMGT-03` | A 360-degree tour placeholder exists in the venue profile. | PDF §8.4 (360 placeholder); §14 (deferred) · project.md › Venue Admin Panel (Web) › Venue Management (360 Tour) | deferred | no | Placeholder only; the tour itself is deferred (PDF §14). project.md omits the word 'placeholder'. |
| `VD-VMGT-04` | Venue can edit amenities. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Amenities) | MVP-P1 | no |  |
| `VD-VMGT-05` | Venue can edit the description (Arabic and English). | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Description) | MVP-P1 | no | Bilingual content: see PL-CORE-08. |
| `VD-VMGT-06` | Venue can manage packages. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Packages) | MVP-P1 | no |  |
| `VD-VMGT-07` | Venue can manage menus. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Menus) | MVP-P1 | no | No client-side menu viewer is specified (CA-VDET-14). |
| `VD-VMGT-08` | Venue can edit rules. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (Rules) | MVP-P1 | no |  |
| `VD-VMGT-09` | Venue can manage FAQs. | PDF §8.4 · project.md › Venue Admin Panel (Web) › Venue Management (FAQs) | MVP-P1 | no |  |

### VD-PRC — Venue dashboard: pricing engine (PDF §8.5) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-PRC-01` | Venue can set a weekday price. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Weekday Price) | MVP-P1 | no | Kuwait weekend is Friday-Saturday; weekday/weekend split must follow it. |
| `VD-PRC-02` | Venue can set a weekend price. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Weekend Price) | MVP-P1 | no |  |
| `VD-PRC-03` | Venue can set holiday prices. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Holiday Price) | MVP-P1 | no | GAP: holiday calendar (Eid, Ramadan, National Day 25 Feb, Liberation Day 26 Feb) is Hijri-dependent; who maintains it? |
| `VD-PRC-04` | Venue can set season prices. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Season Price) | MVP-P1 | no |  |
| `VD-PRC-05` | Venue can create coupons. | PDF §8.5 and §8.9 · project.md › Venue Admin Panel (Web) › Pricing Engine (Coupon); Marketing (Coupons) | MVP-P1 | no | Merged: coupons appear in both pricing and marketing. Parity with HA-OFFR-04. |
| `VD-PRC-06` | Venue can create discounts. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Discount) | MVP-P1 | no |  |
| `VD-PRC-07` | Venue can create promotions. | PDF §8.5 · project.md › Venue Admin Panel (Web) › Pricing Engine (Promotion) | MVP-P1 | no | GAP: promotion vs discount vs offer distinction. |

### VD-CUST — Venue dashboard: customers (PDF §8.6) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-CUST-01` | Venue can see clients and their booking history. | PDF §8.6 · project.md › Venue Admin Panel (Web) › Customer Management (Clients, History) | MVP-P1 | no |  |
| `VD-CUST-02` | Venue can see upcoming weddings. | PDF §8.6 · project.md › Venue Admin Panel (Web) › Customer Management (Upcoming Weddings) | MVP-P1 | no |  |
| `VD-CUST-03` | Venue can flag VIP clients. | PDF §8.6 · project.md › Venue Admin Panel (Web) › Customer Management (VIP Clients) | MVP-P1 | no |  |
| `VD-CUST-04` | Venue can blacklist a client. | PDF §8.6 · project.md › Venue Admin Panel (Web) › Customer Management (Blacklist) | MVP-P1 | no | Privacy and fairness: needs a reason, an audit entry and an appeal path through support; data-protection rules apply. |

### VD-STAFF — Venue dashboard: staff and roles (PDF §8.7) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-STAFF-01` | Admin can create roles and assign permissions. | PDF §8.7 · project.md › Venue Admin Panel (Web) › Staff (Roles, Permissions) | MVP-P1 | no |  |
| `VD-STAFF-02` | Predefined role: Reception. | PDF §8.7 · project.md › Venue Admin Panel (Web) › Staff (Reception) | MVP-P1 | no |  |
| `VD-STAFF-03` | Predefined role: Manager. | PDF §8.7 · project.md › Venue Admin Panel (Web) › Staff (Manager) | MVP-P1 | no |  |
| `VD-STAFF-04` | Predefined role: Accountant. | PDF §8.7 · project.md › Venue Admin Panel (Web) › Staff (Accountant) | MVP-P1 | no |  |
| `VD-STAFF-05` | Predefined role: Marketing. | PDF §8.7 · project.md › Venue Admin Panel (Web) › Staff (Marketing) | MVP-P1 | no |  |

### VD-RPT — Venue dashboard: reports (PDF §8.8) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-RPT-01` | Revenue report. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Revenue) | MVP-P1 | no |  |
| `VD-RPT-02` | Bookings report. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Bookings) | MVP-P1 | no |  |
| `VD-RPT-03` | Occupancy report. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Occupancy) | MVP-P1 | no |  |
| `VD-RPT-04` | Payments report. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Payments) | MVP-P1 | no |  |
| `VD-RPT-05` | Taxes report. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Taxes) | MVP-P1 | no | CF-34: no tax regime is stated. Kuwait has no VAT in force as far as we know (verify with an accountant); report may initially cover commission and fees only. |
| `VD-RPT-06` | Reports can be exported. | PDF §8.8 · project.md › Venue Admin Panel (Web) › Reports (Exports) | MVP-P1 | no |  |

### VD-REV — Venue dashboard: reviews (PDF §8.9) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-REV-01` | Venue can approve reviews before they are shown. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Reviews (Approve) | MVP-P2 | no | CF-24: venue-controlled approval of reviews about itself undermines trust. Recommendation: venues reply and report; Super Admin moderates. |
| `VD-REV-02` | Venue can reply to reviews. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Reviews (Reply) | MVP-P2 | no |  |
| `VD-REV-03` | Venue can report an abusive review. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Reviews (Report Abuse) | MVP-P2 | no |  |

### VD-MKT — Venue dashboard: marketing (PDF §8.9) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `VD-MKT-01` | Venue can send push notifications to clients. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Marketing (Push Notifications) | MVP-P2 | no | Audience and consent rules undefined. |
| `VD-MKT-02` | Venue can send WhatsApp messages to clients. | PDF §8.9 (push, WhatsApp and email) · project.md › Venue Admin Panel (Web) › Marketing | MVP-P2 | no | CF-06: project.md lists SMS here; PDF lists WhatsApp. WhatsApp marketing needs approved templates and opt-in. |
| `VD-MKT-03` | Venue can send emails to clients. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Marketing (Email) | MVP-P2 | no | Email provider not budgeted (CF-28). |
| `VD-MKT-04` | Venue can run SMS campaigns. | project.md › Venue Admin Panel (Web) › Marketing (SMS) (not in PDF) | deferred | no | CF-06: PDF §16 states there is no SMS gateway; dropped from MVP. |
| `VD-MKT-05` | Venue can create and track marketing campaigns. | PDF §8.9 · project.md › Venue Admin Panel (Web) › Marketing (Campaigns) | MVP-P2 | no | Coupons: see VD-PRC-05. |

## 6. Super Admin Dashboard (web) (`SA`) — 81 lines

### SA-DASH — Super admin: platform dashboard (PDF §9.1) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-DASH-01` | Dashboard shows total revenue. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Total Revenue) | MVP-P1 | no | Context only this pass (web dashboards are the next design pass). |
| `SA-DASH-02` | Dashboard shows total bookings. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Total Bookings) | MVP-P1 | no |  |
| `SA-DASH-03` | Dashboard shows total venues. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Total Venues) | MVP-P1 | no |  |
| `SA-DASH-04` | Dashboard shows user counts. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Users) | MVP-P1 | no |  |
| `SA-DASH-05` | Dashboard shows wedding planner counts. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Wedding Planners) | MVP-P2 | no |  |
| `SA-DASH-06` | Dashboard shows vendor counts. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Vendors) | MVP-P2 | no |  |
| `SA-DASH-07` | Dashboard shows growth charts. | PDF §9.1 · project.md › Super Admin Panel (Owner) › Platform Dashboard (Growth, Charts) | MVP-P1 | no |  |

### SA-VAPP — Super admin: venue approval (PDF §9.2) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-VAPP-01` | Super Admin can approve a venue. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Venue Approval (Approve Venue) | MVP-P1 | no | Approved venues go live to clients. |
| `SA-VAPP-02` | Super Admin can reject a venue. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Venue Approval (Reject Venue) | MVP-P1 | no |  |
| `SA-VAPP-03` | Super Admin can suspend a venue. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Venue Approval (Suspend Venue) | MVP-P1 | no | GAP: effect on existing bookings. |
| `SA-VAPP-04` | Super Admin can verify a venue's documents. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Venue Approval (Verify Documents) | MVP-P1 | no | GAP: required document list (for example commercial licence, bank letter) is not defined. |

### SA-VNDR — Super admin: vendor approval (PDF §9.2) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-VNDR-01` | Super Admin can approve a vendor. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Vendor Approval (Approve) | MVP-P2 | no | CF-18: vendors have no self-service product; see PL-CORE-13. |
| `SA-VNDR-02` | Super Admin can reject a vendor. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Vendor Approval (Reject) | MVP-P2 | no |  |
| `SA-VNDR-03` | Super Admin can suspend a vendor. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Vendor Approval (Suspend) | MVP-P2 | no |  |
| `SA-VNDR-04` | Super Admin can manage vendor categories. | PDF §9.2 · project.md › Super Admin Panel (Owner) › Vendor Approval (Categories) | MVP-P2 | no | Category set: CF-16. |

### SA-USR — Super admin: users (PDF §9.3) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-USR-01` | Super Admin can view and manage client accounts. | PDF §9.3 · project.md › Super Admin Panel (Owner) › Users (Clients) | MVP-P1 | no |  |
| `SA-USR-02` | Super Admin can view and manage hotel/venue accounts. | PDF §9.3 · project.md › Super Admin Panel (Owner) › Users (Hotels) | MVP-P1 | no |  |
| `SA-USR-03` | Super Admin can view and manage wedding planner accounts. | PDF §9.3 · project.md › Super Admin Panel (Owner) › Users (Wedding Planners) | MVP-P2 | no | CF-17. |
| `SA-USR-04` | Super Admin can view and manage admin accounts. | PDF §9.3 · project.md › Super Admin Panel (Owner) › Users (Admins) | MVP-P1 | no |  |
| `SA-USR-05` | Super Admin can view and manage support agent accounts. | PDF §9.3 (support agents) · project.md › Super Admin Panel (Owner) › Users (Support) | MVP-P2 | no |  |

### SA-COMM — Super admin: commission management (PDF §9.4) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-COMM-01` | Super Admin can set a platform-wide commission percentage. | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Commission %) | MVP-P1 | no | Built into the MVP (PDF §13). Superseded by ADR 0033 (voucher model, 2026-10-14): no commission. |
| `SA-COMM-02` | Super Admin can override commission per venue. | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Per Venue) | MVP-P1 | no |  Superseded by ADR 0033 (voucher model, 2026-10-14): no commission. |
| `SA-COMM-03` | Super Admin can override commission per category. | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Per Category) | MVP-P1 | no | Precedence venue > category > default. Superseded by ADR 0033 (voucher model, 2026-10-14): no commission. |
| `SA-COMM-04` | Super Admin can configure revenue sharing. | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Revenue Sharing) | MVP-P1 | no | GAP: shared with whom (planners? vendors?). Superseded by ADR 0033 (voucher model, 2026-10-14): no revenue sharing. |
| `SA-COMM-05` | Super Admin can run settlements (cycle, statements). | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Settlement) | MVP-P1 | no |  Superseded by ADR 0033 (voucher model, 2026-10-14): no settlements. |
| `SA-COMM-06` | Super Admin can trigger and track payouts to venues. | PDF §9.4 · project.md › Super Admin Panel (Owner) › Commission Management (Payout) | MVP-P1 | no | Uses bank info from HA-SET-03. Superseded by ADR 0033 (voucher model, 2026-10-14): no payouts. |

### SA-SUBS — Super admin: subscriptions (PDF §9.5) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-SUBS-01` | Free subscription tier. | PDF §9.5 · project.md › Super Admin Panel (Owner) › Subscription Management (Free) | MVP-P1 | no | GAP: entitlements per tier are undefined (MK-SUB-01). Amended by ADR 0033 (voucher model, 2026-10-14): listing plans (weekly, monthly, annual) replace subscription tiers (PA-ADS-01). |
| `SA-SUBS-02` | Premium subscription tier. | PDF §9.5 · project.md › Super Admin Panel (Owner) › Subscription Management (Premium) | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): see PA-ADS-01. |
| `SA-SUBS-03` | Featured tier (placement on Home Featured Venues). | PDF §9.5 · project.md › Super Admin Panel (Owner) › Subscription Management (Featured) | MVP-P1 | no | Drives CA-HOME-09. Amended by ADR 0033 (voucher model, 2026-10-14): featured placement is a paid plan option, rates TBD. |
| `SA-SUBS-04` | Sponsored tier (boosted search results). | PDF §9.5 · project.md › Super Admin Panel (Owner) › Subscription Management (Sponsored) | MVP-P1 | no | Drives MK-SUB-03. Amended by ADR 0033 (voucher model, 2026-10-14): sponsored placement is a paid plan option, rates TBD. |

### SA-CMS — Super admin: content and CMS (PDF §9.6) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-CMS-01` | Super Admin can manage homepage content and banners. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (Homepage, Banners) | MVP-P1 | no |  |
| `SA-CMS-02` | Super Admin can manage platform offers. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (Offers) | MVP-P1 | no |  |
| `SA-CMS-03` | Super Admin can publish blog posts. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (Blogs) | MVP-P2 | no | Needs a public web property (CF-31). |
| `SA-CMS-04` | Super Admin can manage FAQs. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (FAQs); CMS (FAQ) | MVP-P1 | no | Merged: project.md lists FAQs, Terms and Privacy twice (Content Management and CMS). |
| `SA-CMS-05` | Super Admin can publish Terms of Use. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (Terms); CMS (Terms) | MVP-P1 | no | Owner supplies the text (PDF §17). |
| `SA-CMS-06` | Super Admin can publish the Privacy Policy. | PDF §9.6 · project.md › Super Admin Panel (Owner) › Content Management (Privacy); CMS (Privacy) | MVP-P1 | no | Store listings need a public URL (CF-31). |
| `SA-CMS-07` | Super Admin can manage landing pages. | PDF §9.6 · project.md › Super Admin Panel (Owner) › CMS (Landing Pages) | MVP-P2 | no | CF-31. |
| `SA-CMS-08` | Super Admin can manage the About page. | PDF §9.6 · project.md › Super Admin Panel (Owner) › CMS (About) | MVP-P2 | no |  |
| `SA-CMS-09` | Super Admin can manage the Contact page. | PDF §9.6 · project.md › Super Admin Panel (Owner) › CMS (Contact) | MVP-P2 | no |  |

### SA-CAT — Super admin: categories (PDF §9.7) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-CAT-01` | Super Admin can create, edit and order venue categories. | PDF §9.7 · project.md › Super Admin Panel (Owner) › Category Management | MVP-P1 | no | CF-15. |
| `SA-CAT-02` | Venue partner types onboarded: hotels, wedding halls, event venues, government wedding halls and luxury villas. | PDF §4 · project.md › Target Users (Secondary) | MVP-P1 | no | CF-10/CF-15: these types do not map one-to-one onto the six categories; 'event venues' and 'luxury villas' have no category. |
| `SA-CAT-03` | Initial venue categories: Hotels, Wedding Halls, Outdoor, Beach, Luxury, Government. | PDF §9.7 · project.md › Super Admin Panel (Owner) › Category Management (Hotels, Wedding Halls, Outdoor, Beach, Luxury, Government) | MVP-P1 | no | CF-15: does not match the six Home quick categories; luxury villas (PDF §4) have no category. |

### SA-AREA — Super admin: areas (PDF §9.7) (2)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-AREA-01` | Super Admin can manage all Kuwait areas (six governorates and their areas). | PDF §9.7 · project.md › Super Admin Panel (Owner) › Area Management (All Kuwait Areas) | MVP-P1 | no | Governorates: Al Asimah (Capital), Hawalli, Farwaniya, Mubarak Al-Kabeer, Ahmadi, Jahra. Names bilingual with agreed transliteration. |
| `SA-AREA-02` | Super Admin can add areas for other GCC countries. | PDF §9.7 (GCC areas in a later phase) · project.md › Super Admin Panel (Owner) › Area Management (Future GCC) | P4 | no | See RM-GCC group. |

### SA-PLNR — Super admin: wedding planner management (PDF §9.8) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-PLNR-01` | Super Admin can define planner packages (Silver, Gold, Royal) and their contents. | PDF §9.8 · project.md › Super Admin Panel (Owner) › Wedding Planner Management (Packages) | MVP-P2 | no |  |
| `SA-PLNR-02` | Super Admin can set planner pricing. | PDF §9.8 · project.md › Super Admin Panel (Owner) › Wedding Planner Management (Pricing) | MVP-P2 | no |  |
| `SA-PLNR-03` | Super Admin can manage planner availability. | PDF §9.8 · project.md › Super Admin Panel (Owner) › Wedding Planner Management (Availability) | MVP-P2 | no |  |
| `SA-PLNR-04` | Super Admin can assign planners to consultation requests and clients. | PDF §9.8 · project.md › Super Admin Panel (Owner) › Wedding Planner Management (Assignments) | MVP-P2 | no | CF-17: planners themselves have no interface. |

### SA-SUP — Super admin: support (PDF §9.9) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-SUP-01` | Support agents can manage tickets. | PDF §9.9 · project.md › Super Admin Panel (Owner) › Support (Tickets) | MVP-P2 | no |  |
| `SA-SUP-02` | Support agents can reply in live chat. | PDF §9.9 · project.md › Super Admin Panel (Owner) › Support (Live Chat) | MVP-P2 | no | Client side: CA-CHAT-05. |
| `SA-SUP-03` | Support agents can handle complaints. | PDF §9.9 · project.md › Super Admin Panel (Owner) › Support (Complaints) | MVP-P2 | no |  |
| `SA-SUP-04` | Support agents can process refunds. | PDF §9.9 · project.md › Super Admin Panel (Owner) › Support (Refunds) | MVP-P2 | no | CF-26. |

### SA-NOTI — Super admin: notification centre (PDF §9.10) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-NOTI-01` | Super Admin can send push notifications. | PDF §9.10 · project.md › Super Admin Panel (Owner) › Notification Center (Push) | MVP-P1 | no |  |
| `SA-NOTI-02` | Super Admin can send emails. | PDF §9.10 · project.md › Super Admin Panel (Owner) › Notification Center (Email) | MVP-P1 | no | Email provider not budgeted (CF-28). |
| `SA-NOTI-03` | Super Admin can send WhatsApp messages. | PDF §9.10 · project.md › Super Admin Panel (Owner) › Notification Center (WhatsApp (Future)) | MVP-P1 | no | CF-06: project.md marks WhatsApp '(Future)'; PDF lists it as MVP and already depends on it for OTP. |
| `SA-NOTI-04` | Super Admin can send SMS. | project.md › Super Admin Panel (Owner) › Notification Center (SMS) (not in PDF) | deferred | no | CF-06: PDF §16 has no SMS gateway. |

### SA-FIN — Super admin: finance (PDF §9.11) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-FIN-01` | Finance lists all transactions. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Transactions) | MVP-P1 | no |  |
| `SA-FIN-02` | Finance lists and regenerates invoices. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Invoices) | MVP-P1 | no |  |
| `SA-FIN-03` | Finance manages refunds. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Refunds) | MVP-P1 | no | CF-26. |
| `SA-FIN-04` | Finance reports taxes. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Taxes) | MVP-P1 | no | CF-34. |
| `SA-FIN-05` | Finance reports commissions earned. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Commissions) | MVP-P1 | no |  Superseded by ADR 0033 (voucher model, 2026-10-14): no commission; voucher and listing revenue reports replace it. |
| `SA-FIN-06` | Finance reports platform profit. | PDF §9.11 · project.md › Super Admin Panel (Owner) › Finance (Profit) | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): profit is voucher and listing revenue minus gateway fees. |

### SA-ANLY — Super admin: analytics (PDF §9.12) (8)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-ANLY-01` | Analytics: users. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Users) | MVP-P1 | no | Fed by NF-ANL events. |
| `SA-ANLY-02` | Analytics: retention. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Retention) | MVP-P1 | no |  |
| `SA-ANLY-03` | Analytics: revenue. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Revenue) | MVP-P1 | no |  |
| `SA-ANLY-04` | Analytics: conversion. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Conversion) | MVP-P1 | no |  |
| `SA-ANLY-05` | Analytics: most searched areas. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Most Searched Areas) | MVP-P1 | no |  |
| `SA-ANLY-06` | Analytics: top venues. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Top Venues) | MVP-P1 | no |  |
| `SA-ANLY-07` | Analytics: cancellation rate. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Cancellation Rate) | MVP-P1 | no |  |
| `SA-ANLY-08` | Analytics: peak booking months. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Analytics (Peak Booking Months) | MVP-P1 | no |  |

### SA-SEC — Super admin: security (PDF §9.12) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-SEC-01` | Super Admin can manage admin roles. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (Admin Roles) | MVP-P1 | no |  |
| `SA-SEC-02` | Super Admin can manage permissions. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (Permissions) | MVP-P1 | no |  |
| `SA-SEC-03` | Activity logs record admin actions. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (Activity Logs) | MVP-P1 | no | Activity vs audit log distinction undefined; treat activity = browsing/usage, audit = state changes. |
| `SA-SEC-04` | Audit logs record all privileged and financial state changes immutably. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (Audit Logs) | MVP-P1 | no | Backend: PL-CORE-03. |
| `SA-SEC-05` | Admin accounts require two-factor authentication. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (2FA) | MVP-P1 | no | CF-32. |
| `SA-SEC-06` | Super Admin can restrict access by IP address. | PDF §9.12 · project.md › Super Admin Panel (Owner) › Security (IP Restrictions) | MVP-P1 | no |  |

### SA-AI — Super admin: future AI dashboard (project.md, PDF §14) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-AI-01` | AI demand prediction. | PDF §14 (deferred) · project.md › Future AI Dashboard (Demand Prediction) | deferred | no |  |
| `SA-AI-02` | Revenue forecasting. | PDF §14 (deferred) · project.md › Future AI Dashboard (Revenue Forecast) | deferred | no |  |
| `SA-AI-03` | AI venue recommendations. | project.md › Future AI Dashboard (Venue Recommendations) (not in PDF) | deferred | no | CF-33: not in the PDF deferred list. |
| `SA-AI-04` | Fraud detection. | PDF §14 (deferred) · project.md › Future AI Dashboard (Fraud Detection) | deferred | no |  |
| `SA-AI-05` | Dynamic pricing suggestions. | PDF §14 (deferred) · project.md › Future AI Dashboard (Dynamic Pricing Suggestions) | deferred | no |  |

## 7. Platform and backend (`PL`) — 33 lines

### PL-ARCH — Platform architecture (PDF §5, §11) (10)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PL-ARCH-01` | The four products (client app, hotel app, venue dashboard, super admin) share one backend, one database and one media store. | PDF §5 · project.md › Platform Architecture | MVP-P1 | no | Context only this pass; no UI. |
| `PL-ARCH-02` | Both mobile apps are built with Flutter from a single codebase per app for iOS and Android. | PDF §11 · project.md › Technology Suggestions (Frontend Mobile: Flutter or React Native) | MVP-P1 | no | CF-01: project.md allows Flutter or React Native; PDF fixes Flutter. Resolution: Flutter. The web prototype is a design artefact only. |
| `PL-ARCH-03` | The two web dashboards are built with React. | PDF §11 (not in project.md) | MVP-P1 | no | project.md names no web framework. |
| `PL-ARCH-04` | The backend exposes a REST API consumed by all four products. | PDF §5, §11 · project.md › Technology Suggestions (Backend: Laravel or NestJS) | MVP-P1 | no | CF-02: framework undecided (NestJS or Laravel). Owner decision; design is backend-agnostic. |
| `PL-ARCH-05` | PostgreSQL is the primary relational store. | PDF §11 · project.md › Technology Suggestions (Database) | MVP-P1 | no |  |
| `PL-ARCH-06` | Redis provides sessions, caching and background job queues. | PDF §11 · project.md › Technology Suggestions (Database: Redis) | MVP-P1 | no |  |
| `PL-ARCH-07` | Venue photos and videos are stored in Google Cloud Storage and delivered through a CDN. | PDF §11 · project.md › Technology Suggestions (Storage: AWS S3) | MVP-P1 | no | CF-03: project.md says AWS S3; PDF says Google Cloud Storage with CDN. Resolution: GCS. |
| `PL-ARCH-08` | The platform is hosted on Google Cloud (Cloud Run, Cloud SQL, Cloud Storage). | PDF §11, §16 (not in project.md) | MVP-P1 | no | Accounts in the owner's name (NF-PRJ-09). |
| `PL-ARCH-09` | Push notifications to both apps are delivered through Firebase Cloud Messaging. | PDF §11 · project.md › Technology Suggestions (Firebase Notifications) | MVP-P1 | no | iOS delivery goes through APNs via FCM; needs Apple key setup. |
| `PL-ARCH-10` | Google Maps Platform provides venue location, distance and nearby search. | PDF §11 · project.md › Venue Details (Google Maps) | MVP-P1 | no | Map and Places usage priced into the PDF §16 cloud envelope. |

### PL-AUTH — Authentication services (PDF §5, §11) (2)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PL-AUTH-01` | The backend issues and refreshes JWT sessions and validates Apple and Google OAuth identities. | PDF §11 · project.md › Technology Suggestions (Authentication: Firebase Auth) | MVP-P1 | no | CF-04: project.md says Firebase Auth; PDF says backend JWT + OAuth. Resolution: backend JWT + OAuth. |
| `PL-AUTH-02` | A WhatsApp OTP service generates, sends, verifies and rate-limits one-time codes. | PDF §5, §11, §16 · project.md › Technology Suggestions (Authentication: OTP) | MVP-P1 | no | CF-05/CF-28: provider unspecified (WhatsApp Business Platform direct or via a BSP). Needs Meta business verification, an approved authentication template and per-message fees that PDF §16 does not budget. |

### PL-PAY — Payments (PDF §11, §12) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PL-PAY-01` | The payment gateway integration supports KNET via MyFatoorah plus Visa, Mastercard, Apple Pay and Google Pay. | PDF §11 · project.md › Technology Suggestions (Payment: KNET, MyFatoorah, Apple Pay, Google Pay) | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): gateway handles the voucher and listing fees only. |
| `PL-PAY-02` | Gateway callbacks update payment and booking state idempotently. | IMPLIED by PDF §6.9 | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): gateway handles the voucher and listing fees only. |
| `PL-PAY-03` | Refunds are executed through the gateway and recorded against the booking. | IMPLIED by PDF §8.2, §9.11 | MVP-P1 | no | CF-26. Amended by ADR 0033 (voucher model, 2026-10-14): no supplier split or payouts. |

### PL-BOOK — Booking engine (implied by PDF §6.8, §6.10, §8.5) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PL-BOOK-01` | A booking state machine enforces statuses Pending, Approved, Rejected, Cancelled, Completed and Refunded with valid transitions only. | IMPLIED by PDF §6.10 | MVP-P1 | no | GAP: transitions undefined. Proposed: Pending > Approved/Rejected/Cancelled; Approved > Completed/Cancelled; Cancelled/Rejected > Refunded. Amended by ADR 0033 (voucher model, 2026-10-14): eight request statuses replace the nine. |
| `PL-BOOK-02` | Availability is computed from bookings, holds and blocked dates, and double booking is impossible (transactional lock). | IMPLIED by PDF §2 (live availability) | MVP-P1 | no | Short checkout hold (working call: 10 minutes) matches PDF §3 'under 10 minutes'. |
| `PL-BOOK-03` | A requested booking expires automatically after the venue-response window; it holds and charges nothing, so there is nothing to release. | IMPLIED by PDF §6.10 (Pending) | MVP-P1 | no | Resolved by ADR 0001 and 0003 (T06 releases nothing). Window is configuration (working call 24 hours, OQ-B-01). An approved booking whose deposit is not paid by pay-by also expires (T09) and releases the held date. Amended by ADR 0033 (voucher model, 2026-10-14): expiry releases the hold and the voucher. |
| `PL-BOOK-04` | A pricing engine resolves the price by date (weekday, weekend, holiday, season), package, extras, guests, offers and coupons. | IMPLIED by PDF §8.5 | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): the engine resolves a standard and a voucher price. |
| `PL-BOOK-05` | A commission engine computes the platform commission for every confirmed booking (default, per venue, per category). | PDF §9.4, §13 · project.md › Commission Management | MVP-P1 | no | PDF §13: must work from the first confirmed booking. Superseded by ADR 0033 (voucher model, 2026-10-14): no commission engine. |

### PL-CORE — Cross-cutting services (PDF §5, §12) (13)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PL-CORE-01` | A real-time messaging service delivers and stores conversations and falls back to push when offline. | PDF §5 · project.md › Chat | MVP-P2 | no | Technology unspecified; Cloud Run connection limits and timeouts shape the choice (WebSocket vs managed realtime). |
| `PL-CORE-02` | Role-based access control is enforced across all products. | PDF §5, §12 · project.md › Security (Admin Roles, Permissions) | MVP-P1 | no |  |
| `PL-CORE-03` | Privileged and financial actions are written to an audit log. | PDF §5, §12 · project.md › Security (Audit Logs) | MVP-P1 | no |  |
| `PL-CORE-04` | A notification service routes push, email and WhatsApp by event type and user preference. | PDF §9.10 · project.md › Notification Center | MVP-P1 | no |  |
| `PL-CORE-05` | A transactional email provider sends receipts and notices. | IMPLIED by PDF §9.10 (email) | MVP-P1 | no | CF-28: no provider or cost in PDF §16. |
| `PL-CORE-06` | Background jobs run reminders, pending-booking expiry, price-drop detection and review prompts. | PDF §11 (not in project.md) | MVP-P1 | no |  |
| `PL-CORE-07` | Invoices and receipts are generated as bilingual (Arabic and English) PDFs. | IMPLIED by PDF §6.8 and §7.2 (invoice) | MVP-P1 | no |  |
| `PL-CORE-08` | Venue and vendor authored content (names, descriptions, FAQs, policies, package names) is stored in Arabic and English. | IMPLIED by PDF §12 (localisation) | MVP-P1 | no | GAP: PRD localises the UI but never says who translates venue content. Needs both languages or machine-translation with review. |
| `PL-CORE-09` | An analytics store aggregates events for venue and platform analytics. | IMPLIED by PDF §7.6, §9.12, §12 | MVP-P1 | no |  |
| `PL-CORE-10` | An account-deletion pipeline removes or anonymises personal data, revokes Apple tokens and keeps legally required financial records. | IMPLIED by PDF §12 (privacy) | MVP-P1 | no | Retention vs deletion conflict is a legal question; ask the owner's accountant. |
| `PL-CORE-11` | All timestamps are stored in UTC and rendered in Asia/Kuwait (UTC+3, no daylight saving). | IMPLIED by PDF §12 (localisation: dates) | MVP-P1 | no |  |
| `PL-CORE-12` | Wedding planners have an interface to receive consultation requests, chat and schedule meetings. | IMPLIED by PDF §6.11 and §9.8 | MVP-P2 | no | CF-17: no planner-facing product exists. Cheapest option within four products: a 'Planner' role in the Super Admin console. Owner decision. |
| `PL-CORE-13` | Vendors have a way to maintain profile, packages, pricing and availability. | IMPLIED by PDF §6.12 and §9.2 | MVP-P2 | no | CF-18: no vendor app or dashboard is specified. Working call: Super Admin staff enter vendor data at launch (consistent with PDF §17 exclusion of venue onboarding). |

## 8. Non-functional requirements, delivery and constraints (`NF`) — 71 lines

### NF-LOC — Localisation (PDF §12) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-LOC-01` | All four products support full Arabic (RTL) and English (LTR). | PDF §5, §12 · project.md › UI/UX Design (Typography) | MVP-P1 | yes |  |
| `NF-LOC-02` | Layouts mirror in RTL, including directional icons, progress, sliders, calendars and charts. | PDF §10, §12 (not in project.md) | MVP-P1 | yes | Includes logical CSS properties in the prototype. |
| `NF-LOC-03` | Dates are localised in Arabic and English; Gregorian is the default, with Hijri shown only where it matters (holidays, Ramadan, the Arabic summary line). | IMPLIED by PDF §12 ('mirrored layouts, dates and numbers') | MVP-P1 | yes | GAP: the PRD says only 'dates' and never mentions Hijri; the Gregorian-default and Hijri-secondary policy (ADR 0011, occasion-marker table) is a proposal for owner approval (OQ-L-03, OQ-L-04). Holiday pricing depends on Hijri dates. |
| `NF-LOC-04` | Numbers are localised in Arabic and English; Western digits 0-9 by default, with an optional switch to Eastern Arabic-Indic digits as a proposal for owner approval. | IMPLIED by PDF §12 ('mirrored layouts, dates and numbers') | MVP-P1 | yes | GAP: the PRD says only 'numbers'; it names no digit set and no switch (CF-11). Default Western digits; the Settings > Digits switch and the Eastern formatter mode are an owner-approvable proposal (OQ-L-01, ADR 0010 D2). |
| `NF-LOC-05` | Money is formatted as Kuwaiti dinar with three decimals through one shared formatter. | IMPLIED by PDF §9 ('every dinar') | MVP-P1 | yes | CF-12: PDF says 'dinar' only. Arabic shows د.ك after an LTR-isolated number; consumer English shows KD; KWD appears only on invoices, bank settings and the API (ADR 0010 D7). Avoid hard-coded currency for GCC expansion. |
| `NF-LOC-06` | The user can switch language at runtime without restarting the app. | IMPLIED by PDF §6.2, §6.16 | MVP-P1 | yes |  |
| `NF-LOC-07` | All user-facing content (including emails, push, invoices and error messages) exists in both languages. | IMPLIED by PDF §12 | MVP-P1 | yes |  |

### NF-PERF — Performance (PDF §12) (2)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-PERF-01` | The Home screen loads within 2 seconds on a normal 4G connection. | PDF §12 (not in project.md) | MVP-P1 | yes | GAP: 'normal 4G' and 'loads' undefined. Working call: 10 Mbps / 100 ms RTT, first meaningful content visible (skeleton counts as not loaded). |
| `NF-PERF-02` | The Search results screen loads within 2 seconds on a normal 4G connection. | PDF §12 (not in project.md) | MVP-P1 | yes | Image sizes and lazy loading follow from this. |

### NF-AVL — Availability (PDF §12) (2)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-AVL-01` | The platform runs on managed cloud hosting. | PDF §12 (not in project.md) | MVP-P1 | no |  |
| `NF-AVL-02` | Database backups run automatically every day. | PDF §12 (not in project.md) | MVP-P1 | no | GAP: RPO and RTO unspecified; point-in-time recovery recommended. |

### NF-SEC — Security (PDF §12) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-SEC-01` | All traffic is encrypted in transit. | PDF §12 (not in project.md) | MVP-P1 | no |  |
| `NF-SEC-02` | Credentials are stored hashed. | PDF §12 (not in project.md) | MVP-P1 | no |  |
| `NF-SEC-03` | Access is controlled by roles. | PDF §12 (not in project.md) | MVP-P1 | no | Implemented by PL-CORE RBAC. |
| `NF-SEC-04` | Admin accounts require two-factor authentication. | PDF §12 · project.md › Security (2FA) | MVP-P1 | no | CF-32: 'admin accounts' ambiguous (Super Admin only vs venue admins and staff). |
| `NF-SEC-05` | Audit logs are kept. | PDF §12 · project.md › Security (Audit Logs) | MVP-P1 | no |  |

### NF-PAYS — Payment data (PDF §12) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-PAYS-01` | No card data is stored on the platform; card handling is delegated to the certified payment gateway. | PDF §12 (not in project.md) | MVP-P1 | yes | Design implication: use gateway-hosted card entry only; no custom card form (keeps PCI scope minimal). |

### NF-PRIV — Privacy (PDF §12) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-PRIV-01` | Account deletion is available from within the client app, as required by Apple and Google. | PDF §12 · project.md › Profile (Delete Account) | MVP-P1 | yes | Google Play additionally requires a web-accessible deletion request URL (CF-31). Apple: guideline 5.1.1(v). |

### NF-SCAL — Scalability (PDF §12) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-SCAL-01` | API services are stateless and scale horizontally. | PDF §12 (not in project.md) | MVP-P1 | no |  |

### NF-COMP — Compatibility (PDF §12) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-COMP-01` | The client and hotel apps run on iOS 14 and above. | PDF §12 (not in project.md) | MVP-P1 | yes | Design on 390 x 844 and verify 360, 390 and 430 widths. CF-35: ADR 0022 sets iOS 15.0 instead of iOS 14; proposed-needs-owner until OQ-T-02 is signed (no iPhone is lost: iOS 14 and 15 support the same models). |
| `NF-COMP-02` | The client and hotel apps run on Android 8 (API 26) and above. | PDF §12 (not in project.md) | MVP-P1 | yes |  |
| `NF-COMP-03` | The web dashboards run on current versions of Chrome, Safari and Edge. | PDF §12 (not in project.md) | MVP-P1 | no | Firefox not listed. |

### NF-ANL — Analytics events (PDF §12) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-ANL-01` | A search event is tracked. | PDF §12 (not in project.md) | MVP-P1 | no | GAP: analytics tool, consent and event schema undefined. |
| `NF-ANL-02` | A venue view event is tracked. | PDF §12 (not in project.md) | MVP-P1 | no | Feeds HA-ANLY-01. |
| `NF-ANL-03` | A comparison event is tracked. | PDF §12 (not in project.md) | MVP-P1 | no | Required to measure NF-MET-03. |
| `NF-ANL-04` | A booking event is tracked. | PDF §12 (not in project.md) | MVP-P1 | no |  |
| `NF-ANL-05` | A payment event is tracked. | PDF §12 (not in project.md) | MVP-P1 | no |  |

### NF-DSN — Design system and UI/UX direction (PDF §10) (9)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-DSN-01` | The visual direction is luxury, minimal, elegant and premium: closer to a five-star hotel brand than a classified-ads app. | PDF §10 · project.md › UI/UX Design (Theme, Design Style) | MVP-P1 | yes |  |
| `NF-DSN-02` | Imagery is large and carries the screens. | PDF §10 · project.md › UI/UX Design (Large Images) | MVP-P1 | yes |  |
| `NF-DSN-03` | Screens use generous whitespace. | PDF §10 (not in project.md) | MVP-P1 | yes |  |
| `NF-DSN-04` | Cards are minimal with rounded corners. | PDF §10 · project.md › UI/UX Design (Minimal Cards, Rounded Corners) | MVP-P1 | yes |  |
| `NF-DSN-05` | Gold is a restrained accent. | PDF §10 (not in project.md) | MVP-P1 | yes |  |
| `NF-DSN-06` | Palette: Soft Rose #F8E7EC (primary surface), Warm Off White #FFF9F5 (background), Matte Gold #D8B26E (accent and actions), Dark Rose Gray #5A4B4F (text and headings). | PDF §10 · project.md › UI/UX Design (Primary Colors) | MVP-P1 | yes | PRD lists four colours; project direction maps them to three core colours (Ink, Gold, Rose) plus the warm off-white as neutral (AGENTS.md). |
| `NF-DSN-07` | Typography: Cairo for Arabic, Poppins for English. | PDF §10 · project.md › UI/UX Design (Typography) | MVP-P1 | yes | Functional UI pair; an editorial display face is open for exploration. |
| `NF-DSN-08` | Text and essential interface elements have accessible contrast. | PDF §10 (not in project.md) | MVP-P1 | yes | Target WCAG 2.2 AA (project rule). CF-19: computed WCAG ratios: Gold on Off White 1.91:1, Gold on Rose 1.68:1, white on Gold 2.0:1, Ink on Gold 4.12:1 (fails 4.5:1 for body text, passes 3:1 for large text), Ink on Off White 7.88:1, Ink on Rose 6.90:1. Gold cannot carry text or small icons; needs a deepened gold-ink token. |
| `NF-DSN-09` | All screens are built from one consistent component library. | PDF §10 (not in project.md) | MVP-P1 | yes |  |

### NF-MET — Goals and success metrics (PDF §3) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-MET-01` | A booking request is completed in under 10 minutes. | PDF §3 · project.md › Main Goals (Simplify venue booking; metric from PDF only) | MVP-P1 | yes | Measured from booking start to Confirm; drives step count and prefill in the booking flow. |
| `NF-MET-02` | Days-to-confirmation is reduced compared with the manual process. | PDF §3 · project.md › Main Goals (Reduce booking time; metric from PDF only) | MVP-P1 | no | GAP: no baseline or target; collect baseline from launch venues. |
| `NF-MET-03` | The comparison feature is used in a meaningful share of bookings. | PDF §3 · project.md › Main Goals (Help couples compare venues; metric from PDF only) | MVP-P1 | no | GAP: no target ('meaningful'); needs event attribution compare > booking. |
| `NF-MET-04` | Confirmed bookings per venue per month grow. | PDF §3 · project.md › Main Goals (Increase bookings for venues; metric from PDF only) | MVP-P1 | no | GAP: no target. |
| `NF-MET-05` | Couples remain active in the app beyond the venue booking. | PDF §3 · project.md › Main Goals (Digitalize wedding planning; metric from PDF only) | MVP-P2 | no | GAP: define 'active' (planning tool or chat use in 30 days). |
| `NF-MET-06` | Coverage of the Kuwait venue market is tracked. | PDF §3 · project.md › Main Goals (Become the Booking.com of wedding venues in Kuwait; metric from PDF only) | MVP-P1 | no | GAP: denominator (total venues in Kuwait) unknown. |

### NF-PRJ — Delivery plan and constraints (PDF §15, §17) (11)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-PRJ-01` | Phase 1 (1 week): UI/UX design for client app, hotel app and dashboard, and super admin app, with screens in Arabic and English, approved before development starts. | PDF §15 (not in project.md) | MVP-P1 | yes | This pass covers client and hotel apps only; venue dashboard and super admin follow. CF-29: one week for four products in two languages is very tight. |
| `NF-PRJ-02` | Two rounds of design revision per screen set are included. | PDF §17 (not in project.md) | MVP-P1 | yes |  |
| `NF-PRJ-03` | Review feedback is returned within two business days at each milestone. | PDF §15, §17 (not in project.md) | MVP-P1 | no | The 8-week schedule assumes this. |
| `NF-PRJ-04` | Phase 2 (2 weeks): backend, database and REST API for all four applications. | PDF §15 (not in project.md) | MVP-P1 | no | CF-29: includes payments, WhatsApp OTP and real-time chat. |
| `NF-PRJ-05` | Phase 3 (2 weeks): client mobile app for iOS and Android. | PDF §15 (not in project.md) | MVP-P1 | no | CF-29: PDF §6 calls this 'the largest single build'; the client app has about 230 line items here. |
| `NF-PRJ-06` | Phase 4 (2 weeks): hotel mobile app and venue web dashboard. | PDF §15 (not in project.md) | MVP-P1 | no |  |
| `NF-PRJ-07` | Phase 5 (1 week): super admin dashboard, QA, deployment to Google Cloud and submission to the App Store and Google Play. | PDF §15 (not in project.md) | MVP-P1 | no | Store review lead time and Apple organisation enrolment (needs a D-U-N-S number) are not in the plan. |
| `NF-PRJ-08` | The owner provides branding assets and logo, legal texts (terms of use, privacy policy) and initial venue content and data. | PDF §17 (not in project.md) | MVP-P1 | no | Hard dependency: the design is photograph-led and legal URLs gate store submission. |
| `NF-PRJ-09` | Apple, Google Play, Google Cloud and payment gateway accounts are registered in the owner's name. | PDF §16, §17 (not in project.md) | MVP-P1 | no |  |
| `NF-PRJ-10` | Changes to scope are quoted separately before being carried out. | PDF §17 (not in project.md) | MVP-P1 | no |  |
| `NF-PRJ-11` | The MVP scope is exactly sections 6 to 9 of the PDF, excluding features marked future in section 14. | PDF §17 (not in project.md) | MVP-P1 | no | CF-13: this makes everything in §6-9 not deferred in §14 part of the MVP, including vendors, loyalty and marketing. |

### NF-DEL — Deliverables (PDF §18) (10)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-DEL-01` | Complete UI/UX design files for all four applications in Arabic and English. | PDF §18 (not in project.md) | MVP-P1 | yes |  |
| `NF-DEL-02` | The client mobile app is published on the App Store and Google Play. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-03` | The hotel/venue mobile app is published on the App Store and Google Play. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-04` | The venue admin dashboard is deployed and live on the web. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-05` | The super admin dashboard is deployed and live on the web. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-06` | Backend API, database schema and admin documentation are delivered. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-07` | Full source code of every product is transferred to the owner on final payment. | PDF §17, §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-08` | The system is deployed on the owner's Google Cloud account. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-09` | A handover and training session is held for the admin team. | PDF §18 (not in project.md) | MVP-P1 | no |  |
| `NF-DEL-10` | Two months of free maintenance start on the day the apps are live on both stores. | PDF §17, §18 (not in project.md) | MVP-P1 | no |  |

### NF-CST — Operating costs (PDF §16) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-CST-01` | Recurring cloud cost stays within USD 20-100 per month (Cloud Run, Cloud SQL, Cloud Storage, CDN, Maps). | PDF §16 (not in project.md) | MVP-P1 | no | CF-28: excludes WhatsApp Business messaging fees, a transactional email provider and video egress; the envelope looks optimistic for a media-heavy marketplace. |
| `NF-CST-02` | Store and domain costs: Apple Developer Program USD 99 per year, Google Play USD 25 once, domain USD 12-20 per year. | PDF §16 (not in project.md) | MVP-P1 | no |  |
| `NF-CST-03` | Payment gateway fees (MyFatoorah setup plus per-transaction) are charged as a percentage of each booking. | PDF §16 (not in project.md) | MVP-P1 | no | Interacts with commission and refund policy: gateway fees on refunded deposits. |

### NF-EXC — Exclusions (PDF §17) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `NF-EXC-01` | Content creation, photography and copywriting are excluded from the scope. | PDF §17 (not in project.md) | MVP-P1 | no | Design uses a curated image library and written copy for the prototype only. |
| `NF-EXC-02` | Marketing, advertising and app store optimisation are excluded. | PDF §17 (not in project.md) | MVP-P1 | no |  |
| `NF-EXC-03` | Venue onboarding and data entry are excluded. | PDF §17 (not in project.md) | MVP-P1 | no | Cold-start risk: empty marketplace at launch. |
| `NF-EXC-04` | Legal, accounting and company registration services are excluded. | PDF §17 (not in project.md) | MVP-P1 | no |  |
| `NF-EXC-05` | Third-party subscriptions and cloud charges listed in PDF §16 are excluded from the development scope and paid by the owner. | PDF §16, §17 (not in project.md) | MVP-P1 | no | See NF-CST group. |

## 9. Monetization (`MK`) — 13 lines

### MK-COM — Commission (2)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `MK-COM-01` | The platform earns a commission on every confirmed booking. | PDF §13 · project.md › Monetization (Commission Per Booking); Revenue Streams (Booking Commission) | MVP-P1 | no | Merged: mechanism and stream are the same item. Engine: PL-BOOK-05; admin: SA-COMM-01. Superseded by ADR 0033 (voucher model, 2026-10-14): no commission; revenue is the KD 2 voucher. |
| `MK-COM-02` | The commission engine, subscription tiers and featured placement are live in the MVP so earnings start with the first confirmed booking. | PDF §13 (not in project.md) | MVP-P1 | no |  Amended by ADR 0033 (voucher model, 2026-10-14): the commission engine is not built; subscription tiers become listing plans. |

### MK-SUB — Subscriptions (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `MK-SUB-01` | Venues can subscribe to paid plans (Free, Premium, Featured, Sponsored) for recurring revenue. | PDF §13 · project.md › Monetization (Venue Subscription); Revenue Streams (Subscription) | MVP-P1 | no | GAP: entitlements, price and billing method (card? invoice?) per tier. Admin: SA-SUBS-01. Amended by ADR 0033 (voucher model, 2026-10-14): venues and vendors buy listing plans (PA-ADS-01), not Free/Premium/Featured/Sponsored tiers. |
| `MK-SUB-02` | Featured listings give venues paid placement on Home. | PDF §13 · project.md › Monetization (Featured Listings) | MVP-P1 | no | Client surface: CA-HOME-09. |
| `MK-SUB-03` | Sponsored results give venues boosted placement in search. | PDF §13 · project.md › Monetization (Sponsored Results) | MVP-P1 | no | Client surface: CA-SRCH-21. |
| `MK-SUB-04` | Paid and sponsored placements are labelled as such to clients. | IMPLIED by PDF §13 (featured, sponsored) | MVP-P1 | yes | Trust and advertising transparency; label in EN and AR. |
| `MK-SUB-05` | Vendors can subscribe to paid plans. | PDF §13 · project.md › Monetization (Vendor Subscription) | MVP-P2 | no | No vendor product exists (CF-18). Amended by ADR 0033 (voucher model, 2026-10-14): vendors buy weekly, monthly or annual plans. |
| `MK-SUB-06` | Venues can buy premium analytics. | PDF §13 · project.md › Monetization (Premium Analytics) | deferred | no | Not scheduled; free/premium split of HA-ANLY undefined. |

### MK-SVC — Services and advertising (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `MK-SVC-01` | Wedding planner packages are sold as a revenue stream. | PDF §13 · project.md › Monetization (Wedding Planner Packages); Revenue Streams (Wedding Planning) | MVP-P2 | no | Merged. Who delivers and who is paid (Ghazal planners vs partners): CF-17. |
| `MK-SVC-02` | In-app advertising is sold. | PDF §13 · project.md › Monetization (Advertising); Revenue Streams (Ads) | deferred | no | Not scheduled; CMS banners are the only ad surface. |
| `MK-SVC-03` | Lead generation produces revenue. | PDF §13 · project.md › Revenue Streams (Lead Generation) | deferred | no | GAP: mechanism undefined (vendor leads from enquiries?). |
| `MK-SVC-04` | The vendor marketplace produces revenue. | PDF §13 · project.md › Revenue Streams (Vendor Marketplace) | MVP-P2 | no | GAP: commission on vendor jobs would need vendor checkout, which is not specified (CA-SVC-11). |
| `MK-SVC-05` | Premium membership produces revenue. | PDF §13 · project.md › Revenue Streams (Premium Membership) | deferred | no | GAP: who is a member (clients or venues) and what it unlocks. |

## 10. Roadmap and deferred phases (`RM`) — 9 lines

### RM-AI — Phase 3: AI and smart planning (PDF §14) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `RM-AI-01` | AI wedding assistant. | PDF §14 (Phase 3) · project.md › Future Roadmap (Phase 3: AI Wedding Assistant) | P3 | no |  |
| `RM-AI-02` | AI budget planner. | PDF §14 (Phase 3) · project.md › Future Roadmap (Phase 3: Budget Planner) | P3 | no | CF-14: project.md says 'Budget Planner' without 'AI', which collides with the MVP Budget Manager. |
| `RM-AI-03` | Smart timeline. | PDF §14 (Phase 3) · project.md › Future Roadmap (Phase 3: Timeline) | P3 | no | No MVP counterpart. |
| `RM-AI-04` | Smart checklist. | PDF §14 (Phase 3) · project.md › Future Roadmap (Phase 3: Checklist) | P3 | no | CF-14: MVP has a manual checklist. |

### RM-GCC — Phase 4: GCC expansion (PDF §14) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `RM-GCC-01` | Launch in the United Arab Emirates. | PDF §14 (Phase 4) · project.md › Future Roadmap (Phase 4: UAE) | P4 | no | Per-country currency, VAT, payment methods and licensing differ; avoid hard-coding KWD and Kuwait areas. |
| `RM-GCC-02` | Launch in Saudi Arabia. | PDF §14 (Phase 4) · project.md › Future Roadmap (Phase 4: Saudi Arabia) | P4 | no | mada and Saudi VAT are likely requirements. |
| `RM-GCC-03` | Launch in Qatar. | PDF §14 (Phase 4) · project.md › Future Roadmap (Phase 4: Qatar) | P4 | no |  |
| `RM-GCC-04` | Launch in Bahrain. | PDF §14 (Phase 4) · project.md › Future Roadmap (Phase 4: Bahrain) | P4 | no | BHD uses three decimals like KWD. |
| `RM-GCC-05` | Launch in Oman. | PDF §14 (Phase 4) · project.md › Future Roadmap (Phase 4: Oman) | P4 | no | OMR uses three decimals like KWD. |

## 11. Conflicts and gaps register

Entries CF-01 to CF-12 reproduce the twelve conflicts in `docs/product/00-source-digest.md` §9 (same numbers); CF-13 onwards were found while building this matrix. Final decisions belong in `docs/decisions/` as ADRs.

| # | Topic | project.md | PDF | Affected IDs | Working resolution | Digest § 9 |
|---|---|---|---|---|---|---|
| CF-01 | Mobile framework | Flutter or React Native | Flutter, one codebase for both apps (§11) | `PL-ARCH-02` | Flutter. The web prototype is a design artefact only. | 1 |
| CF-02 | Backend framework | Laravel or NestJS | NestJS or Laravel (§11) | `PL-ARCH-04` | Undecided; owner decision. Design and API contracts stay framework-agnostic. | 2 |
| CF-03 | Media storage | AWS S3 | Google Cloud Storage + CDN (§11, §16) | `PL-ARCH-07`, `PL-ARCH-08` | Google Cloud Storage (the later, costed document). | 3 |
| CF-04 | Authentication | Firebase Auth | Backend JWT + OAuth (§11) | `PL-AUTH-01`, `CA-AUTH-05` | Backend JWT + OAuth. | 4 |
| CF-05 | OTP channel | Generic 'OTP' | WhatsApp OTP only; no SMS gateway (§5, §11, §16) | `CA-AUTH-05`, `CA-AUTH-06`, `PL-AUTH-02` | WhatsApp. Open: fallback when WhatsApp delivery fails. | 5 |
| CF-06 | Notification and marketing channels | Push, SMS, Email; WhatsApp marked '(Future)' in the notification centre | Push, WhatsApp, Email (§8.9, §9.10); no SMS subscription (§16) | `VD-MKT-02`, `VD-MKT-04`, `SA-NOTI-03`, `SA-NOTI-04` | Push + WhatsApp + Email in MVP; SMS deferred/out. WhatsApp is already required for OTP, so it cannot be 'future'. | 6 |
| CF-07 | AI recommendations | Four AI recommendation features in the client app and in the competitive advantages | AI assistant and AI budget planner are Phase 3; no AI in §6 | `CA-HOME-15`, `CA-REC-01`, `CA-REC-02`, `CA-REC-03`, `CA-REC-04` | MVP ships rules-based 'Recommended for you' and rule-based budget alerts. AI = Phase 3. | 7 |
| CF-08 | Deposit timing and booking mode | Flow ends Confirm > Deposit Payment, while status starts Pending; 'Instant Booking' filter | Same sequence; instant booking appears only as a filter | `CA-BOOK-11`, `CA-BOOK-15`, `CA-PAY-07`, `CA-SRCH-15`, `CA-STAT-03`, `PL-BOOK-03`, `HA-BOOK-04` | Resolved by ADR 0001 (request-then-pay), pending owner answer OQ-B-01: nothing is charged or held at request; the deposit is paid within a window after the venue approves; instant booking is an earned per-hall opt-in that confirms on successful deposit. The earlier recommendation (charge at Confirm, auto-refund) is withdrawn. | 8 |
| CF-09 | Booking granularity | 'Choose Date, Choose Time' | 'Choose date and time' | `CA-BOOK-03`, `CA-SRCH-13`, `CA-SRCH-14`, `HA-CAL-09`, `HA-AUTH-03`, `VD-DASH-04`, `CA-VDET-08` | Model venue > hall > session with an attendance policy per hall; UI collapses the session step when a venue has a single session. | 9 |
| CF-10 | Government halls | Listed as a venue type | Listed as a venue partner (§4) | `CA-HOME-07`, `SA-CAT-02`, `SA-CAT-03` | Treated as a category only; distinct booking and payment rules wait for an owner answer. | 10 |
| CF-11 | Numerals | Silent | 'Mirrored layouts, dates and numbers' (§12) | `NF-LOC-04` | Western digits (0-9) by default; formatter can switch to Eastern Arabic-Indic. | 11 |
| CF-12 | Currency formatting | Silent | 'Dinar' only (§9) | `NF-LOC-05` | KWD, three decimals, one shared formatter; no hard-coded currency. | 12 |
| CF-13 | Vendor marketplace timing and MVP boundary | 'Future Vendors' list | §4: vendor categories 'introduced after the MVP'; §14: Phase 2 (marketplace, planner, chat, reviews) badged 'Included in this MVP' while the prose says 'Phase 1 in full plus planning tools and chat'; §17: MVP is exactly §6-9 | `CA-SVC-01`, `SA-VNDR-01`, `NF-PRJ-11` | Treat all of §6-9 not deferred in §14 as MVP, with Phase 2 items in the second half of the build. Ask the owner to confirm the marketplace. | new |
| CF-14 | Phase 3 naming vs MVP planning tools | Phase 3 lists 'Budget Planner, Timeline, Checklist' while the client app already has Budget Manager and Checklist | Phase 3 is 'AI budget planner, smart timeline, smart checklist' | `CA-TOOL-05`, `CA-TOOL-12`, `RM-AI-02`, `RM-AI-04` | Manual budget and checklist in MVP (Phase 2 stickiness layer); AI/smart versions in Phase 3. | new |
| CF-15 | Category taxonomy | Home quick categories (Luxury Hotels, Wedding Halls, Government Halls, Beach, Outdoor, VIP) differ from Super Admin categories (Hotels, Wedding Halls, Outdoor, Beach, Luxury, Government) | Home category names not listed; Super Admin set as project.md; §4 lists luxury villas as a venue type | `CA-HOME-07`, `SA-CAT-02`, `SA-CAT-03`, `CA-SRCH-18` | One Super Admin-managed taxonomy; Home chips are curated shortcuts (Luxury Hotels = Hotels + luxury tier; VIP = flag). Add 'Villas' category pending owner. | new |
| CF-16 | Vendor category lists | §4 target vendors include decoration, catering, entertainment | §6.12 services include henna, suit rental, hotels, travel but not decoration or catering | `CA-SVC-12`, `SA-VNDR-04` | Model the 16 leaf categories of §6.12; add decoration, catering and entertainment when confirmed. | new |
| CF-17 | Wedding planner role | Planner is a primary user; planner packages are revenue; Super Admin manages planner availability and assignments | Same; no planner-facing product among the four | `CA-PLAN-09`, `PL-CORE-12`, `SA-PLNR-04`, `MK-SVC-01`, `CA-ONB-07` | Planners are Ghazal-managed supply. Cheapest planner workspace: a 'Planner' role in the Super Admin console. No fifth app. | new |
| CF-18 | Vendor self-service | Vendor approval in Super Admin; no vendor product | Same | `PL-CORE-13`, `SA-VNDR-01`, `MK-SUB-05` | Super Admin staff enter vendor data at launch; self-service is post-MVP. | new |
| CF-19 | Palette vs accessible contrast | Four-colour palette | Same palette plus 'accessible contrast' principle (§10) | `NF-DSN-08`, `NF-DSN-06` | Computed: Gold on Off White 1.91:1; Ink on Gold 4.12:1. Use a deepened gold-ink token for gold text and icons; dark text on gold fills needs a darker ink than #5A4B4F or large type only. | new |
| CF-20 | Price vs starting price on the card | Lists both 'Price' and 'Starting Price' | 'Starting price' only | `CA-CARD-05` | Single starting-price figure. | new |
| CF-21 | Filter naming and semantics | Location and Area listed separately; Rating and Newest listed as filters | 'Location and area'; 'women only / men only / mixed'; 'Mixed' also used for venue setting | `CA-SRCH-02`, `CA-SRCH-06`, `CA-SRCH-17`, `CA-SRCH-16` | Location = distance, Area = named area; Rating and Newest behave as sorts; label 'Mixed setting' and 'Mixed event' distinctly. | new |
| CF-22 | Details vs filter attributes | Details include parking and a 360 tour (future) | Details omit parking and 360; filters use attributes details do not show | `CA-VDET-11`, `CA-VDET-03`, `CA-VDET-26` | Details must show every attribute that is filterable. | new |
| CF-23 | Profile notification settings | Profile lists 'Notifications' | Not listed | `CA-PROF-06` | Keep: needed for marketing opt-out. | new |
| CF-24 | Reviews and user-generated content | Reviews: photos, videos, owner replies; venue 'Approve, Reply, Report Abuse' | §14: reviews are Phase 2 yet cards and details show ratings in Phase 1; venues 'approve and reply' (§8.9) | `VD-REV-01`, `CA-REV-06`, `CA-CHAT-11`, `CA-VDET-20`, `CA-CARD-04`, `CA-REV-01` | Venues reply and report, they do not approve; Super Admin moderates. Add user-side report/block (App Store guideline 1.2). Seed or hide ratings until reviews exist. | new |
| CF-25 | Hotel app gaps | No login, staff provisioning, multi-venue/hall model, extras or date-based pricing on mobile | Same | `HA-AUTH-01`, `HA-AUTH-03`, `HA-VMGT-04`, `HA-VMGT-05` | Design login and venue switcher; base-price editing only on mobile; extras defined in the app. | new |
| CF-26 | Refund ownership | Refund in venue bookings, Super Admin finance and support | Same (§8.2, §9.9, §9.11) | `VD-BOOK-05`, `SA-FIN-03`, `SA-SUP-04`, `PL-PAY-03`, `CA-STAT-08` | One refund service in the backend; venue initiates within policy, Super Admin overrides; all actions audited. | new |
| CF-27 | Cash vs online deposit | 'Cash (optional)' | 'Cash option where the venue allows it' | `CA-PAY-06` | Cash only for the balance at the venue; deposit is always online. | new |
| CF-28 | Cost table omissions | n/a | §16 omits WhatsApp Business messaging fees, a transactional email provider, video storage and CDN egress, and Apple organisation enrolment effort | `NF-CST-01`, `PL-AUTH-02`, `PL-CORE-05`, `HA-VMGT-02` | Ask the owner to budget these before launch. | new |
| CF-29 | Timeline feasibility | n/a | 8 weeks: design 1 week for four products in two languages; client app 2 weeks; no slot for marketplace, planner, chat, reviews, loyalty | `NF-PRJ-01`, `NF-PRJ-05`, `NF-PRJ-04` | Flag risk; this matrix lets the owner descope Phase 2 items explicitly. | new |
| CF-30 | Loyalty is unscheduled and unspecified | Loyalty: points, coupons, referral rewards | §6.16 lists it; §14 roadmap does not | `CA-LOY-01`, `CA-LOY-02`, `CA-LOY-04` | Kept at MVP-P2, flagged as first to slip; earn/redeem rules are an owner decision. | new |
| CF-31 | Public website | CMS lists landing pages, blogs, About, Contact, Terms, Privacy | Same; no public website among the four products | `SA-CMS-07`, `SA-CMS-06`, `CA-PROF-11`, `NF-PRIV-01` | A minimal public site is needed for store privacy-policy URLs and Google Play's web account-deletion URL. | new |
| CF-32 | Admin two-factor scope | Super Admin Security lists 2FA | 'Two-factor authentication for admin accounts' (§12) | `NF-SEC-04`, `SA-SEC-05` | Mandatory for Super Admin and venue admins; optional for other staff. | new |
| CF-33 | Competitive-advantage claims | Claims AI recommendations and GCC readiness as advantages | Both deferred (§14) | `CA-REC-01`, `SA-AI-03` | Do not present AI or GCC as MVP features in copy or design. | new |
| CF-34 | Taxes | Taxes in reports and finance | Same | `VD-RPT-05`, `SA-FIN-04`, `CA-BOOK-13` | No tax regime is stated; confirm with the owner's accountant before designing invoices. | new |
| CF-35 | iOS minimum version | not stated | iOS 14 and above (§12) | `NF-COMP-01` | ADR 0022 A sets iOS 15.0 (Flutter 3.47.5 generates iOS 15 targets; same device list). Proposed-needs-owner: the owner signs the change (OQ-T-02); until then it is a working assumption. Android minSdk 26 matches NF-COMP-02. | new |

## 12. Deferred-feature index (PDF §14 and project.md)

Each deferred feature is carried once, under the product where its UI or data would live; this index points to it.

| Deferred feature | Canonical IDs |
|---|---|
| 360-degree virtual tours | `CA-VDET-03`, `VD-VMGT-03` |
| Payment installments | `CA-PAY-09` |
| AI demand prediction | `SA-AI-01` |
| Revenue forecasting | `SA-AI-02` |
| Fraud detection | `SA-AI-04` |
| Dynamic pricing suggestions | `SA-AI-05` |
| GCC market expansion | `RM-GCC-01`, `RM-GCC-02`, `RM-GCC-03`, `RM-GCC-04`, `RM-GCC-05`, `SA-AREA-02` |
| Phase 3: AI wedding assistant, AI budget planner, smart timeline, smart checklist | `RM-AI-01`, `RM-AI-02`, `RM-AI-03`, `RM-AI-04`, `CA-REC-01`, `CA-REC-02`, `CA-REC-03`, `CA-REC-04` |


## 13. Voucher-model additions (ADR 0033, appended 2026-10-14)

IDs continue each group's numbering and are append-only. `PA` is a new prefix: partner-app features shared by both account types (the Partner app is the former hotel app); its lines use the app value `hotel` in the JSON. Source for every line: owner brief 2026-10-14 and ADR 0033.

### CA-VCH — Vouchers (client) (14)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-VCH-01` | A voucher explainer says in plain words what the KD 2 voucher is, that it is bound to one venue or provider and quote, that the venue or provider is paid directly off-app, and the refund and reuse rules. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Sheet shown before the first purchase and reachable from the venue detail. Voucher fee is configuration (voucher_fee_fils = 2000). |
| `CA-VCH-02` | Venue and provider details, cards and Compare show two prices per package: the standard price and the voucher price, with the saving. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Same unit and guest basis on both; saving chip only when the saving exceeds the voucher fee. Supersedes the single-price grammar of ADR 0004 D6 (second price added). |
| `CA-VCH-03` | A registered client can get a voucher from a venue or provider detail; the voucher is bound at purchase to that target and to the chosen quote (date, hall, package, guests). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Working assumption A-01 (OQ-V-01). |
| `CA-VCH-04` | Voucher purchase and voucher requests require a registered account with a verified phone; guests can see that a voucher price exists and are gated at Get voucher. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Guest gating per ADR 0007 D8; A-14 (OQ-V-09): guests see the voucher price number. |
| `CA-VCH-05` | The client pays the KD 2 voucher online by KNET, Visa, Mastercard, Apple Pay (iOS) or Google Pay (Android) through the gateway-hosted page, with success, pending-bank, failed and lapsed outcomes. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Repurposes CL-PAYM-01..05. Methods list comes from the server (ADR 0027). |
| `CA-VCH-06` | A My vouchers wallet lists the client's vouchers by state (ready to use, in a request, used, expired, refunded) with target, saving and validity. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Entry from Profile and from Booking detail. |
| `CA-VCH-07` | A voucher detail shows the single-use code and QR, the bound venue or provider and quote, usage, expiry and refund or reuse status. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Code is an LTR isolate; QR brightens the screen when opened. |
| `CA-VCH-08` | One voucher covers one request; the code is single-use and redeemable once. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Server enforces (409 VOUCHER_ALREADY_USED). |
| `CA-VCH-09` | The client sends a request at the voucher price from a voucher-bound summary showing standard price, voucher price, saving and what the venue receives. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Replaces the Review step with deposit schedule (CA-BOOK-09). |
| `CA-VCH-10` | A voucher is offered only for voucher-eligible packages whose saving exceeds the voucher fee; governmental facilities never offer one. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | A-13 (OQ-V-14). |
| `CA-VCH-11` | When a request is declined, expires, is withdrawn or is cancelled, the client sees the voucher outcome: reusable at the same venue for 60 days, refundable, or consumed. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | A-02, A-03 (OQ-V-02, OQ-V-03). |
| `CA-VCH-12` | A client can search, compare, visit and contact a venue without a voucher and pay the venue directly at the standard price. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Browse-only path; Contact the venue action on the detail. |
| `CA-VCH-13` | The client is reminded before a ready voucher expires and when a request needs confirmation. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Transactional notifications (ADR 0007 D10). |
| `CA-VCH-14` | A receipt is available for each voucher payment and for a voucher refund (credit note). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Bilingual PDF, amounts in KWD (ADR 0010 D7). Amended by ADR 0035: there is no voucher refund credit note; a granted refund request issues a credit voucher. |

### CA-VIS — Site visits and group chat (client) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-VIS-01` | A client can book a site visit to a hotel or hall from the venue detail by choosing a date and arrival slot, without a voucher. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Hotels and halls only (A-10, OQ-V-11). |
| `CA-VIS-02` | After requesting a visit the client sees a confirmation and is redirected into the dedicated chat to confirm the appointment arrival. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `CA-VIS-03` | Each visit has a dedicated group chat with exactly three roles: the client, a hotel representative and a Ghazal support representative, with role labels. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Conversation kind visit_group; membership and closing rules in voucher-model section 11. |
| `CA-VIS-04` | A visits list and visit detail show status (requested, confirmed, arrived, completed, declined, cancelled, missed) and allow cancel or reschedule request. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `CA-VIS-05` | The client confirms arrival from the visit chat (on my way, arrived). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | The representative marks the arrival. |
| `CA-VIS-06` | The client receives reminders 24 hours and 2 hours before a visit. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |

### CA-FLT — Venue search filters (client) (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-FLT-01` | Filter and search by region: governorate and area, with a free-text region search. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Extends CA-SRCH-02, CA-SRCH-03; six governorates. |
| `CA-FLT-02` | Filter by venue type: Private Hall, Governmental Facility or Hotel (multi-select). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Governmental Facility is browse-only. |
| `CA-FLT-03` | Filter by capacity range (minimum to maximum guests). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Extends CA-SRCH-05 (at-least filter) to a range. |
| `CA-FLT-04` | Filter by pricing structure: per-person pricing or bundled packages. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `CA-FLT-05` | Filter by date and availability using a filterable calendar; results show venues with an available hall on the chosen date. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Extends CA-SRCH-14. |
| `CA-FLT-06` | Filter to venues that offer a voucher price and sort by voucher price. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `CA-FLT-07` | Results show only venues matching the selected region and preferences, with a count and removable filter chips. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Restates CA-SRCH-01 and CA-SRCH-20 for the new filters. |

### CA-SVC — Additional services (client; appended to section 3) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-SVC-13` | The Additional services section lists five primary categories for post-venue needs: Hospitality and catering, Buffet services, Floral arrangements, Event styling and decor, Event planning and coordination. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Un-defers CA-SVC-12 (categories beyond PRD 6.12). The remaining categories stay as secondary. |
| `CA-SVC-14` | A provider profile shows packages with a standard price and a voucher price, portfolio, description and reviews. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Amends CA-SVC-10. |
| `CA-SVC-15` | A client can get a voucher for a provider and request the service at the voucher price. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Provider requests have no calendar claim (state machine section 8). |
| `CA-SVC-16` | Secondary categories (photography and videography, cake, DJ and MC, henna and makeup, dress and suit rental, cars, invitations, travel) are listed after the five primary ones. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes | Renders from data. |
| `CA-SVC-17` | Only approved, active listings appear in search and category lists; paid placements are labelled. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | MK-SUB-04. |
| `CA-SVC-18` | A client can contact a provider without a voucher and pay the provider directly at the standard price. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Browse-only path for providers. |

### CA-STAT — Request status (client; appended to section 3) (4)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-STAT-11` | Booking detail shows a 24-hour confirmation countdown after approval and a primary Confirm booking action. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Absolute time; live countdown only in the last 60 minutes. |
| `CA-STAT-12` | If the client does not confirm within 24 hours of approval the approval lapses and the client is told what lapsed and what happens to the voucher. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | expired with reason client_no_confirmation. |
| `CA-STAT-13` | A confirmed booking shows the voucher code and QR with the instruction to pay the venue directly and show the code. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `CA-STAT-14` | Booking statuses are Pending, Approved, Confirmed, Voucher redeemed, Not accepted, Expired, Cancelled and Completed. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Replaces the nine statuses of ADR 0003 D1; PRD families map in booking-state-machine section 3. |

### CA-AUTH — Accounts (client; appended) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-AUTH-12` | Registration creates a Client account; a separate Service provider account type exists in the Partner app. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Two account types per the owner brief. |

### CA-PROF — Profile (client; appended) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `CA-PROF-12` | Profile links to My vouchers and to Visits. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |

### PA-ACC — Partner account types (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PA-ACC-01` | A partner chooses or is assigned an account type at onboarding: Hotel or wedding hall, or Service provider. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Partner app = the former hotel app. |
| `PA-ACC-02` | The Partner app adapts its tabs, labels and modules to the account type (halls and calendar for venues, listings for providers). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | ADR 0033 D7. |
| `PA-ACC-03` | A partner can manage the account profile: business name in Arabic and English, logo, contact, categories and verification status. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-ACC-04` | A person with both account types can switch between them. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes | A-06 (OQ-V-06). |
| `PA-ACC-05` | Major hotels carry a no-fee exemption flag, set only by Ghazal, shown to the partner as a badge. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Never visible to clients. |

### PA-LST — Partner listings (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PA-LST-01` | A service provider can create a listing in a category with title, description, photos and packages, in Arabic and English. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-LST-02` | A listing package carries a standard price and a voucher price on the same basis (per person or bundled). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-LST-03` | A provider can edit, pause and archive a listing; material edits to an active listing return it to review while the approved version stays live. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | A-09 (OQ-V-10). |
| `PA-LST-04` | A listing shows its lifecycle status: draft, payment pending, pending review, approved, rejected, active, expired. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-LST-05` | A provider sees listing performance: views, saves, voucher purchases and requests. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |
| `PA-LST-06` | A provider sees and answers client requests at the voucher price using the same triage as venues (accept, decline, propose another date). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-LST-07` | A listing offers contact options for browse-only clients. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |

### PA-ADS — Advertising plans and fees (7)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PA-ADS-01` | A partner chooses a paid advertising plan with a flexible billing cycle: weekly, monthly or annual. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Rates are not decided: UI says Rates announced soon (OQ-V-07). |
| `PA-ADS-02` | A partner pays for the plan online through the gateway; payment does not publish the listing. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Listings are published only after manual approval. |
| `PA-ADS-03` | Plan rates are admin-configured values; no screen, fixture or copy carries an invented price. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Nullable rate_fils per cycle. |
| `PA-ADS-04` | Major hotels are exempt from financial obligations and listing fees; their plan step is replaced by an explanation and they still go through review. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Owner brief section 4. |
| `PA-ADS-05` | A partner can view billing: current plan, period, receipts and renewal reminders. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Settings > Billing and fees. |
| `PA-ADS-06` | A partner can renew an expired plan; there is no auto-debit. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |
| `PA-ADS-07` | A rejected listing keeps its paid plan for 14 days for resubmission, after which it is refunded. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | A-08 (OQ-V-08). |

### PA-REV — Listing review status (partner app) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `PA-REV-01` | Every listing and advertisement requires manual review and approval by an App Admin or Moderator before activation. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Content compliance and correct category placement. |
| `PA-REV-02` | A partner sees review status: pending, approved or rejected. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-REV-03` | A rejection shows reason codes and a note, and lets the partner edit and resubmit. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-REV-04` | A partner is notified when a review decision is made. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `PA-REV-05` | Exempt partners are reviewed too. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |

### HA-VCH — Voucher redemption (partner app) (5)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-VCH-01` | A partner can redeem a client voucher by scanning its QR or entering the code. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Roles: Admin, Manager, Reception. |
| `HA-VCH-02` | The redemption screen shows the bound quote and validates ownership, state and prior use with specific errors. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VCH-03` | A request shows its voucher chip and redemption status. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VCH-04` | A partner can see the vouchers redeemed in a period. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |
| `HA-VCH-05` | Redeeming records who redeemed and when and cannot be undone by the partner. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Support can adjust. |

### HA-VIS — Visit requests and group chat (partner app) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-VIS-01` | A hotel receives visit requests (client, date, slot, visitors) in Needs you and in a Visits list. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VIS-02` | A hotel representative can confirm, propose another time or decline a visit. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VIS-03` | Each visit opens a group chat for the client, a hotel representative and Ghazal support. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VIS-04` | The representative marks the client arrived and completes the visit; missed visits can be flagged within 24 hours. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VIS-05` | A partner sets visit availability (days, hours, slot length) or switches visits off. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes |  |
| `HA-VIS-06` | Visit chat membership follows the visit permission (assigned representative, Admin, Manager). | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |

### HA-VMGT — Venue management (appended) (3)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-VMGT-11` | Package editor sets a standard and a voucher price per day type and validates voucher <= standard. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Extends HA-VMGT-04. |
| `HA-VMGT-12` | Venue profile sets venue type (Private Hall, Hotel) and each package's pricing structure (per person or package). | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Governmental facilities are Ghazal-managed. |
| `HA-VMGT-13` | A what-couples-see preview shows both prices and the saving. | Owner brief 2026-10-14 · ADR 0033 | MVP-P2 | yes |  |

### HA-ANLY — Analytics (appended) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-ANLY-08` | Analytics show vouchers purchased and redeemed, requests and approvals for the venue or listing. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Replaces revenue (HA-ANLY-04). |

### HA-SET — Settings (appended) (1)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `HA-SET-06` | Settings > Billing and fees shows listing plan, ad plan, receipts and the major-hotel exemption badge. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | yes | Replaces bank information (HA-SET-03). |

### SA-REV — Review queue and platform configuration (web, out of design scope) (6)

| ID | Requirement | Source | Phase | Design scope this pass | Notes |
|---|---|---|---|---|---|
| `SA-REV-01` | Moderators see a queue of listings and advertisements pending review. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no | Web, out of design scope; context in voucher-model section 12. |
| `SA-REV-02` | A moderator can approve a listing after a content-compliance and category check. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no |  |
| `SA-REV-03` | A moderator can reject a listing with reason codes and a note. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no |  |
| `SA-REV-04` | Super Admin can set and clear the major-hotel fee exemption. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no |  |
| `SA-REV-05` | Super Admin can configure the voucher fee and validity and the weekly, monthly and annual plan rates. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no |  |
| `SA-REV-06` | Support can search a voucher by code, refund or release it, and join visit group chats as the support representative. | Owner brief 2026-10-14 · ADR 0033 | MVP-P1 | no |  |

## 14. Owner round 1 additions (2026-10-20, ADR 0035)

9 lines appended; live count 665 in `feature-matrix.json`.

| ID | Requirement | Source | Phase | Design | Notes |
|---|---|---|---|---|---|
| `CA-VCH-15` | A client can hold a credit voucher (unbound, 60 days) in the wallet and claim it with any hall, hotel or service. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Kind credit; granted only by support (CA-VCH-16). |
| `CA-VCH-16` | A client can send a refund request for an eligible voucher to Ghazal support; if support agrees the client receives a credit voucher. No money is returned. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Support chat entry; refund_requests record. Replaces money refunds (ADR 0035 D5). |
| `CA-VCH-17` | A voucher is forfeited (not valid, does not come back) when the 24 hour confirmation at the hotel or service lapses. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Voucher state forfeited; amends CA-STAT-11 and R09. |
| `HA-VCH-06` | A partner sees that a request whose client did not confirm within 24 hours lapsed and its voucher is forfeited, and the date reopens. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Partner side of CA-VCH-17. |
| `PA-BIL-01` | A partner account has a billing mode: plan (weekly, monthly or annual, rates set in Super Admin) or contract (terms as contracted, no public plan); contract is mostly for hotels and halls. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Prototype shows "Rates announced soon" for plans and a Business contract card for contract mode. |
| `PA-ACC-06` | Partner staff are invited by email (Resend) and sign in with email and password. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Replaces the WhatsApp invite of ADR 0028 for staff; client sign-in codes stay WhatsApp. |
| `HA-CAL-10` | External calendar sync is done by email (an .ics or an invitation address), not WhatsApp. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P2 | yes |  |
| `HA-REV-01` | A venue can ask support to hide or delete a review; support performs it. The venue cannot hide or delete it itself. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P1 | yes | Reply once and report stay (PA-REV, OQ-B-25). |
| `HA-VMGT-14` | A venue can upload videos in high quality up to 500 MB each. | Owner round 1 2026-10-20 · ADR 0035 | MVP-P2 | yes | Replaces 60 s, 100 MB, 720p (OQ-T-15). |

## 15. Owner round 2 additions (2026-10-29, ADR 0038)

| ID | Requirement | Source | Phase | Design scope | Notes |
|---|---|---|---|---|---|
| `CA-AUTH-13` | There is no guest mode in the Client app: after the language screen and the introduction the person signs in with their phone before anything else is shown; there is no guest-gate sheet and no signed-out browsing. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | Replaces the guest assumptions of ADR 0033 (owner-decisions item 8 is moot). The Partner app keeps its signed-out state for staff sign-in. |
| `CA-AUTH-14` | A new client account must give a name and sex (female or male) before the app opens; both are editable in Profile. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | Working assumption OQ-R2-02: stored on the account, not shown to venues, not used to filter yet. |
| `CA-ONB-10` | Onboarding does not ask for areas (the Preferred areas step is retired); the Brief is set from the date, guests and governorates. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | Retires CL-ONBD-06. |
| `CA-FLT-08` | Places are filtered by governorate only, in the Brief, Filters, Results and Vendors filters; the Client app has no exact-area selection. The governorate list is configuration (Kuwait's six governorates at start; the owner said about eight). | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | OQ-R2-01. Venues keep their area as an address line. |
| `CA-SVC-19` | Additional services and facilities are not linked to a hotel or hall: no extras or add-on services in venue packages, no service suggestions or links on venue pages; the client picks service providers in the Services hub and requests a quote from them. The first release lists only services that Ghazal's venues do not provide. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | Removes the governmental-facility 'Find catering and decor' link. |
| `CA-SVC-20` | The Client app shows a small note for service providers pointing them to the Partner app to apply; the Client app has no application form. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | OQ-R2-04: the note names the Partner app and links to its store page (configuration). |
| `PA-ACC-07` | Service providers and private halls apply with a form in the Partner app carrying their business information; Ghazal staff accept or reject each application (the reason is shown on rejection) before the account can create listings. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes | OQ-R2-03 lists the working field set. |
| `PA-ACC-08` | The application form has an open note for a service that is not among the pre-registered categories; staff can add the category or reject the application. | Owner round 2 2026-10-29 · ADR 0038 | MVP-P1 | yes |  |
