# Ghazal — Design Brief (Client App + Hotel App)

> Mandate for the design phase. Constraints here are binding; the *interpretation* is open — take initiative, challenge weak assumptions, and record decisions in `docs/decisions/`. Challenge a decision by writing an ADR, never by silently deviating: an accepted ADR is settled (`AGENTS.md`).
>
> **Status banner (2026-10-12):** sections 5 and 6 below were written before the ADRs. They are hypotheses that the ADRs have since answered (resolutions inline). Sections 1 to 4 and 7 stand. Companion files: [01-direction.md](01-direction.md), [content-guidelines.md](content-guidelines.md), [seed-rulebook.md](seed-rulebook.md).

## 1. The product in one paragraph

Ghazal replaces *Instagram + WhatsApp + phone calls* for the biggest purchase decision of a Kuwaiti couple's year: the wedding venue. A couple (often the bride, with her mother/family weighing in) browses venues, compares up to three, sees live availability, requests a booking with a deposit, and then keeps planning inside the app. A venue manager — frequently on the move, often on a phone, often mid-event — accepts or declines requests, manages the calendar and offers, and answers couples. **Two apps, two very different moods:** the client app is *aspirational, emotional, image-led*; the hotel app is *calm, operational, glanceable*. One identity.

## 2. Who we design for

**Client app** — a bride/groom (22–35), her family, or a planner. Arabic-first for many, English for others; both must feel native, not translated. Using it at night on a sofa with family passing the phone around; deciding with money and emotion on the line. Needs: *trust, clarity of price, certainty of the date, beauty.*
**Hotel app** — venue manager / reception / accountant. Needs: *speed, zero ambiguity about what's pending, one-thumb actions, no decoration that costs time.* Uses it standing, in a corridor, in a ballroom, between phone calls.

## 3. Experience principles

1. **Quiet luxury.** The luxury is in restraint, proportion and photography — never in ornament. Think five-star hotel concierge: composed, attentive, unhurried.
2. **Image is the hero.** Venues sell through photographs. Imagery gets the space, the typography gets out of the way. UI chrome is almost invisible over imagery.
3. **Certainty before beauty.** Price, date availability, deposit amount, and booking status are never ambiguous or hidden behind a tap.
4. **One decision per screen** in flows (booking, onboarding). Progress is always visible. Back is always safe.
5. **Native in both scripts.** Arabic is a first-class design target, not a mirrored afterthought: its own type sizes/line-heights, its own copy written for Kuwait, correct mirroring of icons, progress, chevrons, sliders, calendars, charts.
6. **Operational calm** (hotel app). Information density is high but hierarchy is rigorous; colour carries meaning only when it must (pending/overdue).
7. **Motion explains.** Every animation answers a question: *where did that come from / where did it go / did it work?* Nothing decorative loops.

## 4. Visual constraints (binding)

### Colour — maximum three core colours
Source palette (PRD §10) mapped into three roles + neutrals:

| Core colour | PRD source | Role |
|---|---|---|
| **Ink** | Dark Rose Gray `#5A4B4F` | text, headings, primary dark surfaces, strokes |
| **Gold** | Matte Gold `#D8B26E` | accent, primary actions, selection, signature details |
| **Rose** | Soft Rose `#F8E7EC` | quiet tinted surfaces, highlight areas |
| *neutral* | Warm Off White `#FFF9F5` | canvas/background, plus warm greys *derived from Ink* |

Rules:
- Tints/shades of the three are allowed (define as a ramp in tokens). **No fourth hue.**
- A tiny **functional** set — desaturated success + danger (and Gold doubles as "pending/attention") — is allowed *only* for status semantics, always paired with icon + label, never decorative, never used as a brand colour.
- **Known accessibility problem to solve, not ignore:** `#D8B26E` on `#FFF9F5` ≈ 2:1 — fails for text and small icons. Gold is for fills, hairlines and large marks; text/icons that need gold use a deepened Gold-ink token that passes 4.5:1. Dark text on gold fills must pass 4.5:1 too.
- Flat, **matte** gold only — no metallic/shiny gradients. Gradients are not a styling device (scrims over photographs for legibility are allowed and must be subtle, single-purpose).

### Anti-patterns (instant rejection)
Purple/blue-indigo AI gradients · glassmorphism panels · glowing/neon effects · floating 3D blobs · emoji as iconography · "Welcome back 👋" tone · uniform grids of identical shadowed cards with no hierarchy · rainbow category chips · gradient buttons · centred-everything layouts · lorem ipsum / "John Doe" placeholder content · childish, bubbly, over-rounded or cartoonish shapes · decorative effects that don't carry information.

### Typography
PRD specifies **Cairo (Arabic)** and **Poppins (English)**. Treat as the functional UI pair unless a better, justified pairing is chosen (and documented). A refined editorial display face for headlines/brand moments (EN + AR counterpart) is open for exploration. Requirements: a deliberate type scale (state the ratio), language-specific sizes and line-heights (Arabic needs more leading and ~+1–2 px optical size), tabular figures for prices/dates/stats, never fewer than 12 px, body ≥ 15–16 px.

### Layout & measurement
- 4-pt base grid; spacing scale of multiples of 4 (e.g. 4, 8, 12, 16, 20, 24, 32, 40, 48, 64). Screen gutter is a single token. No off-grid values.
- Design frame **390 × 844** (iPhone 14/15) with safe areas (top ≈ 47, bottom ≈ 34); layouts are fluid and verified at **360, 390, 430** widths. Android and iOS share the design; only system chrome differs.
- Touch targets ≥ **44 × 44**; primary controls 48–56 high; one consistent control-height scale.
- Radius system is small and meaningful (e.g. 4 / 8 / 12 / 20 / pill) — PRD asks for rounded corners and *minimal cards*; make rounding consistent, not bubbly.
- Elevation: prefer **hairline borders and tonal surfaces** over drop-shadows; if shadows exist, a single soft, warm-tinted system.
- Icons: one set, one stroke weight, one optical size grid; mirrored in RTL where directional.

### Motion
- Token-driven durations and easings (e.g. 120 / 200 / 320 / 480 ms; one standard-out and one emphasised curve). Respect `prefers-reduced-motion`.
- Required behaviours: screen push/pop (direction-aware, flips in RTL), bottom-sheet rise/dismiss with drag, shared-element image expansion (card → gallery), tap/press feedback, stepper progress, selection states, list skeleton → content, success confirmation, calendar range selection, favourite toggle, compare-tray insertion.
- Nothing blocks input; nothing > 500 ms except deliberate success moments; no looping decorative animation.

### Imagery & content
- Real photography of venues and wedding details (curated library in `design/public/images/`, credited in `CREDITS.md`). **No identifiable faces.** Avatars = monograms.
- Realistic Kuwaiti content: real-sounding areas (Salmiya, Kuwait City, Shuwaikh, Mishref, Salwa, Jabriya, Messila, Khiran, Fintas, Bnaid Al-Qar…), hotel-style venue names (fictional), KWD prices with Kuwaiti-market magnitudes, capacities of 100–1,500 guests, Fri/Sat weekends, Sunday-start weeks.
- Copy is written (not translated) in both languages: warm, precise, never saccharine. Arabic = clear modern Arabic with Gulf-appropriate vocabulary.

## 5. Information architecture (hypotheses, answered by ADR 0007 and ADR 0008)

**Client app** bottom navigation, settled in ADR 0007 D1: *Discover* · *Saved* · *My Wedding* · *Messages* · *Profile*. The earlier hypothesis (Discover / Compare-Planner / Plan / Messages / Profile) is retired: Compare is a persistent tray (max 3) plus a pushed comparison table (ADR 0009), not a tab; bookings live in My Wedding and the Home status card; the planner is a card in My Wedding. Search is a first-class entry on Discover. Guest browsing is allowed everywhere except at commit moments (request, payment, chat), ADR 0007.
**Hotel app** bottom navigation, settled in ADR 0008: *Today* · *Bookings* · *Calendar* · *Messages* · *More*. Pending requests are reachable in one tap from anywhere through a badge plus the Needs-you inbox.

## 6. Open design questions (answered; the answers are in the ADRs)
1. Request or instant, and where is the deposit charged? Answered by ADR 0001 (accepted; owner confirms OQ-B-01): request-then-pay by default, nothing charged or held before the venue approves, instant booking as an earned per-hall opt-in.
2. Date and session; halls and men/women sections? ADR 0002: hall x date x session, up to two sections, booking channels including government halls.
3. Western vs Eastern digits? ADR 0010: Western by default; the Eastern switch is an owner-approvable proposal (OQ-L-01).
4. How does Compare stay visible without nagging? ADR 0009: an anti-nag tray and a differences-only table.
5. The single memorable visual idea? ADR 0017 adopts the thread (غزل) as progress and timeline only; the visual direction itself is a working assumption in [01-direction.md](01-direction.md) (OQ-P-20).

## 7. Quality bar — "would a senior product designer sign this?"
- Every measurement is on-grid and deliberate; every screen aligns to the same gutters and baselines.
- Hierarchy is clear at a glance: one primary action per screen.
- Visual density is consistent between screens; empty/loading/error/offline states exist for key surfaces.
- Both languages checked on every screen (no clipped text, no wrongly-mirrored icons, no Latin/Arabic baseline clash).
- Looks like a considered product, not a template: no element could be removed *or* added without a reason.

## Update 2026-10-14: typefaces and business model changed

Two things in this brief are out of date and are NOT rewritten above; read them as follows.

1. **Typefaces.** The owner chose El Messiri (display, both scripts), Manrope (English UI and figures) and Almarai (Arabic UI) on 2026-10-13 (ADR 0031 addendum). Wherever this brief, ADR 0016 or ADR 0030 names Cairo, Poppins, Newsreader or Amiri, the three faces above apply. The display-face reader test (OQ-L-09) is still recommended before visual freeze, now for El Messiri.
2. **Business model.** Ghazal now sells clients one KD 2 voucher; venues and providers sell and collect everything else off-app (ADR 0033, `docs/product/voucher-model.md`). Mentions in this brief of a deposit, balance, pay window, request-then-pay or instant booking, "price, deposit amount" certainty (principle 3), and the booking questions in section 6 describe the superseded model. Principle 3 now reads: price (standard and voucher), date availability and request status are never ambiguous. The second app is the Partner app (hotels and halls plus service providers); the document keeps the old "Hotel App" name in its title.
