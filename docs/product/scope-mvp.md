# Ghazal — Scope: MVP, later phases, and what this design pass covers

> **Business model changed 2026-10-14 (ADR 0033, [`voucher-model.md`](voucher-model.md)).** Ghazal now sells only a KD 2 voucher; venues, halls and service providers sell and collect everything else. Anything in this file about deposits, balances, commission, payouts, cash, instant booking, cancellation tiers or the nine booking statuses is superseded; the screen inventory JSON and the architecture docs are already rewritten.

> Source of truth for IDs and phases: `feature-matrix.json` (571 requirements, 1 line = 1 testable statement). PRD wording: `Ghazal_PRD_EN.pdf` §14, §15, §17. Conflicts: matrix §11 (CF-01 to CF-35; CF-35 is the iOS 15 floor).
> Rule from `AGENTS.md`: **never invent product scope.** A new idea goes to `open-questions.md`, not into a screen. PRD change requests are quoted separately (`NF-PRJ-10`).
> Numbers below were computed from the JSON and from `docs/product/screens/**` on the date of writing.

## 1. Phase model (PRD §14)

| Phase | Content (PRD wording) | Status |
|---|---|---|
| **Phase 1 (MVP)** | Venue discovery, booking, comparison, payments | In MVP, built first. Matrix label `MVP-P1`. |
| **Phase 2 (MVP)** | Wedding services marketplace, planner, chat, reviews; plus planning tools and loyalty that the PDF prose puts in the MVP | In MVP, second half of the build. Label `MVP-P2`. First to slip: loyalty (CF-30), then the vendor marketplace (CF-13). |
| Phase 3 | AI wedding assistant, AI budget planner, smart timeline, smart checklist | Out of scope. `P3` (RM-AI-01..04, CA-REC-01..04). The MVP ships a rules-based "Recommended for you" and rule-based budget alerts with no AI label (CF-07, CF-14, CF-33). |
| Phase 4 | UAE, Saudi Arabia, Qatar, Bahrain, Oman | Out of scope. `P4` (RM-GCC-01..05, SA-AREA-02). Readiness only: per-country configuration for week start, weekend, currency exponent, phone rules. |
| **Explicitly deferred** | 360-degree tours, payment installments, AI demand prediction, revenue forecasting, fraud detection, dynamic-pricing suggestions, GCC expansion | `deferred`, 15 lines: CA-VDET-03, CA-PAY-09, CA-SVC-12, VD-VMGT-03, VD-MKT-04, SA-NOTI-04, SA-AI-01..05, MK-SUB-06, MK-SVC-02, MK-SVC-03, MK-SVC-05. |

PRD §17: the MVP is exactly §6-9 of the PDF minus the §14 future items. CF-13 records that the PDF contradicts itself on vendors ("introduced after the MVP" in §4, "Phase 2 included in this MVP" in §14); the working call is that all of §6-9 not deferred is MVP, with Phase 2 in the second half.

## 2. Requirement totals by product

| Product (prefix) | Lines | MVP-P1 | MVP-P2 | P3 | P4 | deferred | In this design pass |
|---|---:|---:|---:|---:|---:|---:|---:|
| Client Mobile App (`CA`) | 233 | 163 | 63 | 4 | 0 | 3 | **226** |
| Venue / Hotel Mobile App (`HA`) | 73 | 63 | 10 | 0 | 0 | 0 | **73** |
| Venue Admin Dashboard, web (`VD`) | 58 | 49 | 7 | 0 | 0 | 2 | 0 (context) |
| Super Admin Dashboard, web (`SA`) | 81 | 54 | 20 | 0 | 1 | 6 | 0 (context) |
| Platform / backend (`PL`) | 33 | 30 | 3 | 0 | 0 | 0 | 0 |
| Non-functional and delivery (`NF`) | 71 | 70 | 1 | 0 | 0 | 0 | **26** (cross-cutting) |
| Monetization (`MK`) | 13 | 6 | 3 | 0 | 0 | 4 | **1** (`MK-SUB-04`, Sponsored label) |
| Roadmap (`RM`) | 9 | 0 | 0 | 4 | 5 | 0 | 0 |
| **Total** | **571** | **435** | **107** | **8** | **6** | **15** | **326** |

104 lines are *implied* (not literally in the PRD; 56 client, 28 hotel, 14 platform, 5 non-functional, 1 monetisation) and 72 carry a `GAP:` note. Implied lines are the only place the matrix goes beyond the PRD, and each is flagged so the owner can strike it.

## 3. What this design pass delivers

**In scope: the Client Mobile App and the Venue / Hotel Mobile App**, designed as an interactive web prototype ("Ghazal Design Studio", `design/`) and as a handoff for the later Flutter build. Web dashboards are context only, but the design system must extend to them.

| Deliverable | Content |
|---|---|
| Screen set | **110 screen IDs**: client 70 (45 core, 25 supporting; 5 tab roots, 17 sheets, 48 screens) and hotel 40 (21 core, 19 supporting; 5 tab roots, 7 sheets, 28 screens). Kinds across both apps: 76 screens, 24 sheets, 10 tab roots. Listed in `screen-inventory.md`. |
| Languages | Every screen in Arabic (RTL) and English (LTR), written natively, verified at 360, 390 and 430 px. |
| Coverage | **Every design-scope client requirement (226 of 226) and hotel requirement (73 of 73) is cited by at least one screen** (script check against the JSON). The 26 design-scope NF lines and `MK-SUB-04` are cross-cutting rules (localisation, performance, accessibility, palette, typography, payments safety, account deletion) and are enforced through tokens, lint and QA rather than owned by one screen. |
| States | Default, loading (static skeleton, no shimmer), empty, error and offline for key surfaces; role-limited variants for the hotel app. |
| Prototype spine ("P0", wired at full fidelity) | **Client (33):** `CL-ONBD-04..06`, `CL-DISC-01..04`, `CL-VENU-01..03`, `CL-SAVD-01`, `CL-SAVD-02`, `CL-SAVD-04`, `CL-BOOK-01..07` in both modes, `CL-PAYM-01..05`, `CL-BKNG-01`, `CL-BKNG-02` (Pending, Approved, Confirmed, Not accepted), `CL-BKNG-04`, `CL-WEDD-01`, `CL-MSGS-01`, `CL-MSGS-02`, `CL-AUTH-01`, `CL-AUTH-02`. **Hotel (14):** `HL-ACCS-01`, `HL-TODY-01`, `HL-BOOK-01`, `HL-BOOK-03`, `HL-BOOK-04`, `HL-DCSN-01`, `HL-DCSN-02`, `HL-DCSN-03`, `HL-CALN-01`, `HL-CALN-04`, `HL-GROW-02`, `HL-GROW-03`, `HL-TODY-04`, `HL-TODY-05`. Everything else is built to design-system standard by recombining shared sheets, lists and forms. |
| Shared seed story | One booking visible identically in both apps: Reem Al-Dosari to Aurelia Gulf Hotel, Thu 14 Jan 2027, 350 guests, KD 18,200.000, deposit KD 5,460.000. |
| Handoff packet | Component and screen spec JSON, six screenshots per screen, redlines for the eight hero screens (`client.home`, `client.venue.details`, `client.compare.table`, `client.booking.review`, `client.payment.outcome`, `client.bookings.detail`, `hotel.today.dashboard`, `hotel.bookings.detail`, plus `hotel.calendar.month` once frozen), tokens, ARB keys, fixtures (ADR 0024). |
| Definition of done | Both languages checked at three widths, axe clean, tokens only, RTL registry respected, requirement IDs declared (ADR 0025 D7). |

**Not in this pass:** Flutter code, backend, venue dashboard and super admin screens, tablet layouts, dark mode (light theme only for the MVP, ADR 0022 F), copywriting beyond the prototype (excluded by `NF-EXC-01`; the owner names a native Kuwaiti reviewer, OQ-L-06).

## 4. What is designed, per requirement group

Counts are matrix lines, with "designed" where they differ. Flow = the screen flow that carries the group (`screen-inventory.md`). P2 = built in the second half of the MVP, designed now.

**Client (`CA`)**

| Group | Lines | Phase | Carried by flow | Notes |
|---|---:|---|---|---|
| AUTH | 11 | P1 | auth, plus the guest gate in 10 other flows | One identity entry; WhatsApp code primary; no separate Sign up and Login |
| ONB | 9 | P1 | onboarding, profile | Brief steps all skippable |
| HOME | 16 | P1 | discover | Brief card, lead shelf "Free on {date}" |
| SRCH | 21 | P1 | discover | Filters, map, live count; women-only, men-only, mixed as per-hall audience |
| CARD | 13 | P1 | discover | Card anatomy per ADR 0018; contextual Book (OQ-L-10) |
| VDET | 26 (25) | P1 | venue | `CA-VDET-03` 360-degree tour parked: content-model field only, no UI |
| CMP | 12 | P1 | saved-compare | Tray plus table, max 3 |
| BOOK | 17 | P1 | booking, payment | Five merged steps, request or instant |
| PAY | 11 (10) | P1 | payment | `CA-PAY-09` installments parked: no UI, no "soon" row |
| STAT | 10 | P1 | bookings | One Booking detail, many variants |
| PROF | 11 | P1 | profile | In-app account deletion required by Apple and Google |
| NOTI | 8 | 6 P1, 2 P2 | messages, profile | Landing rules in ADR 0007 D11 |
| PLAN | 9 | P2 | planner | Silver / Gold / Royal as one, two, three thread marks |
| SVC | 12 (11) | P2 | services | Browse, save, request a quote; no checkout; `CA-SVC-12` parked |
| TOOL | 19 | 2 P1, 17 P2 | my-wedding | Countdown, checklist, budget, wishlist; rules-based |
| CHAT | 11 | P2 | messages | Real-time service is `PL-CORE-01` (MVP-P2) |
| REV | 6 | P2 | reviews-rewards | Reply and report only for venues (OQ-B-25) |
| LOY | 7 | P2 | reviews-rewards | First candidate to slip; earn rules undecided (OQ-P-05) |
| REC | 4 | P3 | none | AI recommendations not designed |

**Hotel (`HA`)**

| Group | Lines | Phase | Carried by flow | Notes |
|---|---:|---|---|---|
| AUTH | 4 | P1 | access | Invite-only, phone plus password, WhatsApp code on new device |
| DASH | 7 | 6 P1, 1 P2 | today | Needs-you block first |
| BOOK | 11 | 10 P1, 1 P2 | bookings, decisions | Accept (Undo), Decline, Propose another date, Cancel, Record cash |
| CAL | 9 | P1 | calendar | Month, Week, Day; block in 3 taps |
| VMGT | 10 | P1 | venue | Weekday and weekend price edits only; engine grids on web |
| OFFR | 6 | P1 | grow | One offer applies per booking |
| ANLY | 7 | P1 | grow | Funnel Views, Clicks, Requests, Confirmed |
| NOTI | 8 | 6 P1, 2 P2 | today, settings | Distinct new-request alert |
| SET | 5 | P1 | settings | Staff and bank are Admin-only with step-up |
| MSG | 5 | P2 | today | Inbox and thread with booking context bar |

## 5. Build order inside the MVP (phase mix of each flow)

Requirement phases cited by each flow's screens. Flows dominated by `MVP-P2` are designed now and built in the second half; they may slip without blocking a launch of discovery, booking, payment and the hotel operating loop.

| App | Flow | Screens | Requirements cited | P1 / P2 |
|---|---|---:|---:|---|
| Client | onboarding | 6 | 9 | 9 / 0 |
| Client | auth | 5 | 12 | 12 / 0 |
| Client | discover | 5 | 54 | 54 / 0 |
| Client | venue | 6 | 42 | 40 / 2 |
| Client | saved-compare | 4 | 21 | 19 / 2 |
| Client | booking | 7 | 30 | 27 / 3 |
| Client | payment | 5 | 21 | 18 / 3 |
| Client | bookings | 5 | 18 | 17 / 1 |
| Client | my-wedding | 5 | 23 | 5 / 18 |
| Client | planner | 4 | 11 | 1 / 10 |
| Client | services | 4 | 18 | 1 / 17 |
| Client | messages | 4 | 20 | 7 / 13 |
| Client | reviews-rewards | 4 | 19 | 5 / 14 |
| Client | profile | 6 | 26 | 24 / 2 |
| Hotel | access | 4 | 6 | 6 / 0 |
| Hotel | today | 5 | 25 | 16 / 9 |
| Hotel | bookings | 5 | 16 | 15 / 1 |
| Hotel | decisions | 5 | 9 | 9 / 0 |
| Hotel | calendar | 4 | 12 | 12 / 0 |
| Hotel | venue | 6 | 14 | 14 / 0 |
| Hotel | grow | 6 | 18 | 17 / 1 |
| Hotel | settings | 5 | 18 | 15 / 3 |

Schedule risk (CF-29): the PRD allows 1 week for design of four products in two languages, 2 weeks for the client app ("the largest single build"), and has no slot for marketplace, planner, chat, reviews or loyalty. This design set makes the descoping choice explicit and cheap; the owner decides the order (OQ-P-13). One slip is already pre-agreed in the ADRs: the **"Both" (ladies plus men) UI may ship in v1.1** while the data model supports sections from day one (ADR 0002 D6).

## 6. Explicitly not designed (and why)

| Not designed | Reason | Reference |
|---|---|---|
| 360-degree tour UI, installments UI, AI recommendation labels or chat | Deferred or Phase 3 | CA-VDET-03, CA-PAY-09, CA-REC-01..04 |
| "Installments (soon)" row, "Couples' choice" or "Most booked" badges | Not in the PRD; invented urgency or proof | ADR 0018 D2 |
| Swipe actions of any kind | Ambiguous when mirrored, inaccessible | ADR 0014 D4 |
| Vendor checkout, vendor-side product, planner directory or planner-facing app | No transaction model or surface in the PRD; planners are Ghazal-managed supply | CF-17, CF-18, OQ-P-01, OQ-P-02 |
| Multiple wedding files per account; "Send payment link to the payer" | Outside the PRD | OQ-B-24 |
| Non-wedding event types beyond the optional Occasion chip | Scope question | OQ-B-11, OQ-P-08 |
| Venue-initiated bulk reschedule after an authority order | P2 | ADR 0006 D7, OQ-B-23 |
| No-show contest flow | P2 (the no_show status UI is P2 too) | ADR 0003 D4, OQ-B-21 |
| Refund issuing and goodwill refunds, tier-level price editing, menus, permission-matrix editing, customer management, exports | Web only (dashboards own them); a money grid on a phone invites costly errors | ADR 0004 D8, ADR 0006 D10 |
| Revenue privacy toggle, quick-reply management, marketing notifications to venues | Not in the PRD; defaults only | hotel `_index.json` |
| `enquiry_only` booking channel | Enum reserved, not designed | ADR 0002 D10 |
| Dark mode, tablet layouts | Light theme only for the MVP | ADR 0022 F |
| Real photography, copywriting, venue onboarding, marketing, legal | Excluded from scope; owner supplies | NF-EXC-01..04, NF-PRJ-08 |

## 7. Proposals beyond the PRD (each needs an owner answer)

These are designed so the owner can approve, flag-off or cut each one without breaking the rest. IDs are in `open-questions.md`.

| Proposal | Where | Status in design |
|---|---|---|
| Optional Occasion chip (Wedding night, Milka, Henna night, Engagement, Other) | `CL-BOOK-01` | Removable chip, no extra screen (OQ-B-11) |
| Share via OS sheet with universal link and preview; WhatsApp row in the hotel Contact sheet | `CL-VENU-01`, `CL-SAVD-04`, `HL-BOOK-04` | Included, flagged (OQ-B-12) |
| "Notify me if this date opens" on Held dates | `CL-VENU-03` | Behind a feature flag (OQ-B-13) |
| Two-section "Both" booking | `CL-BOOK-01..05` | Data model day one; UI may ship v1.1 (OQ-B-09) |
| Family contact person with a disclosure line | `CL-BOOK-04` | Included (OQ-B-19) |
| Hijri secondary line in Arabic summaries; approximate occasion markers | date confirmations | Included (OQ-L-04) |
| Digits switch in Settings (Arabic UI only) | `CL-PROF-05` | Included as a proposal under NF-LOC-04 (IMPLIED by PDF §12 'numbers', not literal PRD text); the owner may drop it (OQ-L-01) |
| Weekly "Confirm your calendar is up to date" nudge; offline sale as a labelled block | `HL-TODY-02`, `HL-CALN-04` | Included, removable (OQ-B-22) |
| "You receive KD X" and Payable tile | `HL-BOOK-03`, `HL-TODY-01` | Only when a commission rule exists (OQ-B-16) |
| Waze in the directions chooser (designed); Instagram link on venue details (not designed) | `CL-VENU-01` | Flagged (OQ-P-09) |
| "I booked this hall" self-report for government halls | `CL-VENU-06` | Included (OQ-B-10) |
| Open-request cap of 3 per wedding file | `CL-BOOK-05` | Configuration (OQ-B-24) |
| Authority-order reason code and no-fee choice | data model, copy | Designed, bulk tooling P2 (OQ-B-23) |
| Display typeface test (Cormorant and Amiri, El Messiri) | tokens only | Control ships; test runs in parallel (OQ-L-09) |

## 8. Decisions that change what is in scope (status)

| Decision | Status | Effect if the owner says no |
|---|---|---|
| Request-then-pay by default, instant as earned opt-in (ADR 0001) | accepted, depends on OQ-B-01 and OQ-B-02 | Only the request path changes (charge at Review; refund on decline, expiry and lost slot; KNET disabled on that path); statuses and screens stay |
| Deposit 30% and balance T-14; cancellation templates and 48 h cooling-off (ADR 0005, 0006) | **proposed, needs owner** | Configuration only |
| Imagery policy: empty rooms only (ADR 0015) | **proposed, needs owner** | Venue onboarding effort and listing quality change (OQ-L-07) |
| Analytics taxonomy (ADR 0019) | **proposed, needs owner** | Settings toggle, retention and consent change (OQ-L-11) |
| Backend NestJS 12 (ADR 0020) | **proposed, needs owner** | One extra week of contract tooling if flipped to Laravel (OQ-T-01) |
| iOS 15 minimum instead of the PRD's iOS 14, Android minSdk 26 (ADR 0022) | accepted, needs sign-off as CF-35 | No device is lost (iOS 14 and 15 support the same iPhones); OQ-T-02 |

## 9. How to decide whether something is in scope

1. Find the requirement ID in `feature-matrix.json`. If it is `MVP-P1` or `MVP-P2` and its app is `client` or `hotel`, it is in this pass and a screen cites it (`screen-inventory.md`).
2. If it is `deferred`, `P3` or `P4`, it is out; keep a data-model field only where the matrix says so.
3. If it is `venue-web`, `super-admin` or `platform`, it is context: the app may need to display its result, but no screen is designed for it here.
4. If no ID exists, it is not in the PRD. Do not design it silently: add a row to `open-questions.md` with a working assumption and keep moving.
