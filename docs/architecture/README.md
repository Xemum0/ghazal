# Architecture documentation

> **Business model changed on 2026-10-14 (ADR 0033, `docs/product/voucher-model.md`).** Ghazal now sells only a KD 2 voucher; venues and providers sell and collect everything else. Where this file mentions deposits, balances, commission, payouts, cash, instant booking, cancellation tiers, supplier split or the nine booking statuses, read the rewritten [booking-state-machine](booking-state-machine.md), [pricing-and-payments](pricing-and-payments.md) and [data-model](data-model.md) instead; this file is updated lazily.

How Ghazal (غزل), a Kuwait wedding-venue marketplace, is put together: four products on one backend, one booking model, one money model, two languages. Written for autonomous coding agents and for the owner. These files summarise and connect the decisions in `docs/decisions/` (ADRs 0001-0029) and add the detail an implementer needs; they never override an ADR. Where a file here and an ADR disagree, the ADR wins and the difference is reported in `docs/product/open-questions.md`. To change a decision, write a new ADR (`node tools/new-adr.mjs '<title>'`), then update the file here.

## Reading order

| You are | Read first | Then |
|---|---|---|
| The owner | [overview](overview.md) section 11 (decisions waiting for you), [pricing-and-payments](pricing-and-payments.md) section 10 (every number you can set) | [booking-state-machine](booking-state-machine.md) sections 1-3 |
| A design agent (prototype) | [booking-state-machine](booking-state-machine.md), [i18n-rtl](i18n-rtl.md), [design-to-code](design-to-code.md) | [pricing-and-payments](pricing-and-payments.md) sections 3-5, [data-model](data-model.md) section 8 (the seeded booking) |
| A Flutter agent | [design-to-code](design-to-code.md), [i18n-rtl](i18n-rtl.md), [api-conventions](api-conventions.md) | [security-privacy](security-privacy.md) sections 2-4 |
| An API agent | [overview](overview.md), [data-model](data-model.md), [api-conventions](api-conventions.md), [booking-state-machine](booking-state-machine.md) | [pricing-and-payments](pricing-and-payments.md), [security-privacy](security-privacy.md) |

## Files

| File | What it fixes in place |
|---|---|
| [overview.md](overview.md) | The four products, system context diagram, stack and pins, deployables, backend modules, "one booking, four lenses", the central request-approve-pay sequence, cross-cutting rules, budgets, non-goals |
| [data-model.md](data-model.md) | Five ERDs (identity, catalogue and pricing, booking and availability, money, engagement), conventions, enumerations, the exclusion constraint, indexes, the seeded booking as rows |
| [booking-state-machine.md](booking-state-machine.md) | Nine statuses under the PRD six, transition table T01-T19, overlays, timers, jobs, what each actor sees, races, reason codes, PRD text that changes |
| [pricing-and-payments.md](pricing-and-payments.md) | Price engine, display grammar, worked examples, deposit and balance, payment flow and gateway boundary, commission and ledger, cancellation and refunds, cash, documents, configuration |
| [i18n-rtl.md](i18n-rtl.md) | Pinned locale rules, the one formatter and its fixtures, digits, money, dates and Hijri, Arabic voice and plurals, typography, mirroring and the icon registry, bidi pitfalls, QA checklist |
| [security-privacy.md](security-privacy.md) | Roles and permission keys, tenancy, auth flows, sessions, step-up, account deletion, PII inventory and retention, audit log, moderation, abuse controls |
| [api-conventions.md](api-conventions.md) | Contract-first workflow, wire formats, headers, error format and code registry, pagination, idempotency, concurrency, caching, endpoint catalogue, realtime, analytics ingestion, versioning |
| [design-to-code.md](design-to-code.md) | Token pipeline, prototype CSS subset, component and screen specs, Flutter mapping, parity and goldens, the visual QA loop, handoff packet, dev-server ports and identity |

## Facts every agent must hold

| # | Fact | Where |
|---|---|---|
| 1 | Money is integer **fils** (KWD, 3 decimals), `{ fils, currency }` on the wire; the server never formats money; clients format through `GzFormat` only | i18n-rtl 2-4, api 2 |
| 2 | **Request, then pay.** A request holds no date and no money; approval creates a hold and a payment window; the deposit confirms. Instant booking is an earned per-hall opt-in. No authorise-then-capture, no charge-then-refund | state machine 1 and 4 |
| 3 | The bookable unit is **hall x session**; a booking has one or two sections (ladies, men); government halls are listings with a hand-off | data-model 3-4 |
| 4 | Nine internal statuses map to the PRD six; reschedules, counter-offers and amendments are child objects | state machine 3-5 |
| 5 | Double booking is prevented by a Postgres exclusion constraint on `slot_claims`, never by timers | data-model 7 |
| 6 | Western digits 0-9 in both languages; Arabic `د.ك` after the number, English `KD`; `KWD` only on documents and the API | i18n-rtl 3-4 |
| 7 | Asia/Kuwait, 12-hour clock, Gregorian primary, Sunday-first weeks, Thu-Sat peak band at the inline-end edge; never "ليلة" plus a weekday | i18n-rtl 5 |
| 8 | Client deadlines are absolute times; a live countdown appears only in the last 60 minutes of a pay window and during the 10-minute instant hold | state machine 1 |
| 9 | The gateway webhook plus a status re-query decides that money arrived; the return URL never does | pricing 6 |
| 10 | No identifiable faces, no avatars but monograms, empty-room imagery only | security 10 |
| 11 | The prototype's NOW is Thu 12 Nov 2026, 16:00 Asia/Kuwait; the shared booking is `GZ-2611-0147` | data-model 8 |
| 12 | A local dev URL is never typed by hand: `node tools/ports.mjs url design` | design-to-code 9 |

## Where a requirement group lands

| Requirement ids | Start in |
|---|---|
| CA-BOOK, CA-PAY, CA-STAT, HA-BOOK, HA-CAL, PL-BOOK | [booking-state-machine](booking-state-machine.md), [pricing-and-payments](pricing-and-payments.md) |
| CA-AUTH, CA-PROF-09, HA-AUTH, HA-SET, SA-SEC, NF-SEC, NF-PRIV, PL-CORE-02/03/10 | [security-privacy](security-privacy.md) |
| NF-LOC, CA-ONB, CA-SRCH area and phone fields | [i18n-rtl](i18n-rtl.md) |
| NF-DSN, NF-ANL, all component specs | [design-to-code](design-to-code.md), ADR 0019 |
| PL-ARCH, PL-PAY, NF-PERF, NF-AVL, NF-CST | [overview](overview.md), [api-conventions](api-conventions.md) |
| CA-CARD, CA-CMP, CA-HOME, CA-VDET | ADR 0018, 0009, 0007; display rules in [pricing-and-payments](pricing-and-payments.md) section 3 |

## Identifiers

| Kind | Form | Example | Defined in |
|---|---|---|---|
| Requirement | `<AP>-<GROUP>-<NN>` | `CA-BOOK-09`, `HA-CAL-04`, `PL-PAY-02`, `NF-LOC-04` | `docs/product/feature-matrix.json` (the `CL-6.5` notation in `docs/research/*` is void) |
| Screen inventory | `CL-<AREA>-<NN>`, `HL-<AREA>-<NN>` | `CL-BOOK-05`, `HL-DCSN-01` | `docs/product/screens/` |
| Spec screen | `<app>.<feature>.<screen>` | `client.booking.review` | `design/specs/screens/` |
| Decision | `NNNN` | ADR 0003 | `docs/decisions/NNNN-<slug>.md` |
| Open question | `OQ-B-nn` (booking), `OQ-L-nn` (localization), `OQ-T-nn` (technical) | `OQ-B-01` | `docs/product/open-questions.md` |
| Booking | `GZ-YYMM-XXXX` | `GZ-2611-0147` | data-model 1 |

## Decision status

Accepted and binding: ADR 0001-0004, 0007-0014, 0016-0018, 0021-0029. **Proposed, needs owner:** 0005 (deposit, balance, payment schedule), 0006 (cancellation, refund, reschedule), 0015 (imagery policy), 0019 (analytics taxonomy), 0020 (NestJS). The numbers in 0005 and 0006 are configuration placeholders; only the pay-at-request question (OQ-B-01) would change flows, and then only the request path. Facts only MyFatoorah can confirm (OQ-B-02, OQ-T-04) gate refund-arrival copy, the bank-transfer fallback and payout timing, not the design.

ADR file names are assumed to be `docs/decisions/<id>-<slug>.md` with the slugs in the decision index: 0001 `booking-model-request-then-pay`, 0002 `booking-granularity-halls-sessions-sections-channels`, 0003 `booking-status-state-machine`, 0004 `pricing-engine-and-price-display`, 0005 `deposit-balance-and-payment-schedule`, 0006 `cancellation-refund-reschedule-policy`, 0007 `client-app-navigation-and-guest-gating`, 0008 `hotel-app-navigation-and-request-triage`, 0009 `compare-ux-390px`, 0010 `numerals-currency-shared-formatter`, 0011 `dates-time-week-calendar-policy`, 0012 `phone-address-identifiers-ltr-fields`, 0013 `arabic-voice-dialect-gender-copy-rules`, 0014 `rtl-mirroring-gestures-chart-direction`, 0015 `imagery-cultural-sensitivity-policy`, 0016 `typography-cairo-poppins-figures-display-test`, 0017 `motion-principles-and-tokens`, 0018 `venue-card-anatomy-and-hero-search`, 0019 `analytics-event-taxonomy`, 0020 `backend-framework-nestjs`, 0021 `monorepo-layout-toolchain-ports`, 0022 `flutter-architecture-platform-floors`, 0023 `design-token-pipeline`, 0024 `prototype-to-flutter-handoff-contract`, 0025 `testing-strategy-visual-qa-loop`, 0026 `ci-cd-environments-secrets`, 0027 `payments-integration-boundary-myfatoorah`, 0028 `authentication-sessions-step-up`, 0029 `agentic-development-setup-file-ownership`.

## Inconsistencies found while writing, and the call made here

Each is closed by a dated amendment note in the owning ADR (decisions/README step 4) or an open-question entry; the last column says where. Updated 2026-10-12: rows 1-21, 23, 24 are closed; row 22 is a research-file example only.

| # | Inputs that disagree | Call used in these files |
|---|---|---|
| 1 | ADR 0022 lists client tabs "Discover, Compare/Planner, Plan, Messages, Profile"; ADR 0007 says Discover, Saved, My Wedding, Messages, Profile | ADR 0007; amended in ADR 0022 (status line, item D) on 2026-10-12 |
| 2 | English currency: NF-LOC-05 and ADR 0022 say `KWD`; ADR 0010 says `KD` on consumer surfaces and `KWD` on documents (OQ-L-02) | ADR 0010; amended in ADR 0022 (item E), 0004 (D6), 0001 (D3), 0006 (D3) on 2026-10-12 |
| 3 | Money wire shape: ADR 0010 `amount_fils` + `currency`; ADR 0020 and 0027 `{ fils, currency }` | Layered: DB `*_fils`, API `Money` object, analytics flat (note in ADR 0010) |
| 4 | Payment-status polling: ADR 0027 90 s; ADR 0001 D11 and 0005 D7 about 30 s | "We are confirming" at 30 s, poll silently to 90 s (note in ADR 0027) |
| 5 | Quiet hours: ADR 0007 marketing 22:00-09:00; ADR 0015 and OQ-L-15 23:00-08:00 | Both, as two windows (marketing blocked, transactional silent); config until OQ-L-15 (note in ADR 0007) |
| 6 | Hijri: ADR 0011 computes with ICU; ADR 0022 says the client never computes it; the guideline example `6 شعبان 1448` is right only at noon Kuwait time (midnight gives 5) | API ships the pair; prototype uses ICU at noon (note in ADR 0011) |
| 7 | Rejected label: ADR 0003 `غير مقبول`; ADR 0013 `اعتذرت القاعة` / "Venue unable to host"; the screen inventory uses "Not accepted" with `اعتذرت القاعة` | Resolved 2026-10-12 in ADR 0013 D4 and ADR 0003 D2: "Not accepted" / `لم يُقبل الطلب`; "Pending" / `بانتظار الرد` |
| 8 | ADR 0008 D6 (Undo returns an approval to `requested`) has no matching transition in ADR 0003 T01-T19 | Added T03u and `bookings.undo_until` (note in ADR 0003) |
| 9 | Arabic plurals: ADR 0013 D7 and the glossary called 100+ "other" and wrote `350 ضيف`; CLDR assigns by last two digits, so 350 and 650 are `many` (`350 ضيفًا`) and 300 and 400 are `other` | Resolved 2026-10-12: ADR 0013 D7, glossary and seed JSON follow CLDR; native reviewer confirms (OQ-L-06) |
| 10 | Hotel login: OQ-B-17 assumes WhatsApp OTP for invited staff; ADR 0028 and OQ-T-09 say phone + password with OTP on a new device | ADR 0028 (note added there) |
| 11 | Email path for clients without WhatsApp: ADR 0007 "Use email" link; ADR 0028 password keyed to the mobile number; OQ-L-14 email OTP | Resolved 2026-10-12: fixed +965 chip everywhere, password keyed to the mobile, Apple or Google for foreign numbers, email never an identifier (email OTP only recovers an account that already has a verified email) |
| 12 | SLA escalation 50% and 90% (journeys-ia) vs 50% and 80% (ADR 0001, 0008) | 50% and 80% (note in ADR 0008) |
| 13 | Cash: CA-PAY-06 and two research files allow a cash deposit; ADR 0005 D6 allows cash for the balance only | ADR 0005 (narrows the PRD; note added there) |
| 14 | Stale matrix text: PL-BOOK-01, PL-BOOK-03, CA-STAT-04/05, CA-TOOL-16/17, HA-DASH-03, HA-BOOK-01 | Rewritten in booking-state-machine 12 and in the matrix text and notes on 2026-10-12 |
| 15 | ADR 0023 lists motion durations 120/200/320/480; ADR 0017 adds `success` 640 | Token file includes 640 (note in ADR 0023) |
| 16 | ADR 0024 hero ids (`client.home`) break its own `<app>.<feature>.<screen>` rule; screen specs lack an inventory-id field | Mapping table in design-to-code 7; add an optional `inventory` field (note in ADR 0024) |
| 17 | ADR 0020's module list omits media, analytics and the wedding file; vendor leads have no module | Added as proposed modules in overview 5 (note in ADR 0020) |
| 18 | ADR 0019 `reason_code` values differ from ADR 0003 reason codes | Mapping in booking-state-machine 11 (note in ADR 0019) |
| 19 | ADR 0005 D3 does not say how a guest-lock credit is paid once the balance is settled | Derived: unpaid balance first, then a partial refund (note in ADR 0005) |
| 20 | ADR 0001: a venue without payout KYC "can receive requests but cannot approve into paid bookings", which means no booking can complete before KYC | Approve is blocked (`VENUE_KYC_REQUIRED`); launch dependency to confirm (note in ADR 0001) |
| 21 | Cooling-off: "within 48 h of paying when the event is 30+ days away" does not say when the 30 days is measured; "D+3" does not define D | Evaluated at payment time; D is the balance due date (note in ADR 0006) |
| 22 | The booking-payment research worked example names a ballroom after a real retail brand; content rules ban real brands | Example B is labelled a hypothetical tariff |
| 23 | `AGENTS.md` still names `design/tokens/` and `npm run` commands; ADR 0021 and 0029 replace both | Fixed 2026-10-12: AGENTS.md and CLAUDE.md now use `packages/design-tokens/src/` and the target pnpm commands |
| 24 | NF-COMP-01 says iOS 14; ADR 0022 sets iOS 15 (CF-35, OQ-T-02) | iOS 15, proposed-needs-owner (ADR 0022 item A); CF-35 appended to the matrix register on 2026-10-12 |

## Conventions for these documents

- Tables and mermaid diagrams over prose; every number carries its unit; money examples were checked by running the arithmetic.
- Mermaid blocks are parsed by `mermaid.parse` before a change is accepted; a diagram that does not parse is a bug.
- Values marked **initial** are starting numbers to tune; values marked **proposed** or **derived** are this folder's calls where an ADR is silent. Replace them through an ADR, not by editing a number in passing.
- Dev-server URLs are never written by hand in any document; quote `node tools/ports.mjs url <service>` (ADR 0021, 0029).
