# Ghazal (غزل) — Product Vision

> **Business model changed 2026-10-14 (ADR 0033, [`voucher-model.md`](voucher-model.md)).** Ghazal now sells only a KD 2 voucher; venues, halls and service providers sell and collect everything else. Anything in this file about deposits, balances, commission, payouts, cash, instant booking, cancellation tiers or the nine booking statuses is superseded; the screen inventory JSON and the architecture docs are already rewritten.

> Status: living document, design phase (NOW in all fixtures = Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait).
> Sources: `Ghazal_PRD_EN.pdf` §1-4, §13-14 · `project.md` · `docs/design/00-brief.md` · ADRs 0001-0019 · `docs/research/*`.
> Where this file and an ADR disagree, the ADR wins. Requirement IDs are from `feature-matrix.json`.

## 1. One sentence

**Ghazal is the default place a Kuwaiti couple starts planning a wedding, and the default channel through which venues fill their calendar** — "the Booking.com of wedding venues in Kuwait" (PRD §2), with a wedding-planning layer that keeps the couple inside the product for the 6 to 18 months between the first search and the wedding night.

*Ghazal* means both **love poem** and **spun thread**. The thread is the product's one signature: a single gold line that shows where a booking stands, identically to the couple and to the venue (the Booking Thread, ADR 0003 D6, ADR 0017).

## 2. The problem today

| Pain (PRD §2) | What it looks like in Kuwait |
|---|---|
| Research is scattered across Instagram and WhatsApp | Venues sell through WhatsApp Business and Instagram; families deliberate in WhatsApp groups; links travel as screenshots. About 94% of Kuwaiti social-media users are on WhatsApp [V]. |
| No side-by-side comparison | Three hotels, three PDFs, three voice notes. The mother of the bride cannot see the options unless someone forwards them. |
| Availability is unknown until someone answers the phone | The couple asks eight venues "is Thursday 14 January free?" and waits. Thursday, Friday and Saturday nights are the peak and sell first [K]. |
| Prices are inconsistent and rarely published | A single "from" price misleads: real cost = hall fee + per-guest menu (KD 20-55 per guest by tier) + extras (kosha KD 1,800-6,500), and it changes between weekday and weekend nights and around Ramadan and Eid. |
| No single record of bookings, payments, agreements | Deposits are paid in cash or by transfer; nothing says who agreed what. |

Two further facts shape the product more than any feature list:

1. **A Kuwaiti wedding is often two events in two rooms** — the ladies' reception and the men's reception, frequently on the same night in adjacent halls with separate entrances. A booking therefore carries one or two *event sections* (ADR 0002), not "a guest count".
2. **The decider is not the user.** The bride owns the file, her mother holds the veto, and a parent or the groom's family often pays. Saved, Compare and Share must work for someone who never creates an account (`personas.md`).

## 3. The Ghazal answer: six product bets

Each bet is already decided in an ADR and traced to screens in `screen-inventory.md`.

| # | Bet | In the product | Decided in |
|---|---|---|---|
| 1 | **Brief-led discovery.** Date, guests, area and budget are global context, so every card shows availability and a price *for the couple's date and guest count*. | Hero "brief card" on Home; a Brief pill on Results; "KD 18,200 for 350 guests · Thu 14 Jan · Free" on cards, Saved rows and the Compare table. | ADR 0007 D3, 0018, 0004 D6 |
| 2 | **No money moves before a human says yes.** Request mode is the default; instant booking is an earned per-hall opt-in. | CTA "Request to book", never "Book now". Venue approves inside a 24h SLA, then the couple pays the deposit inside a 24h window. No authorise-then-capture, no charge-then-refund. | ADR 0001 |
| 3 | **One booking, seen from two sides.** Every venue action has a visible client counterpart. | One canonical Booking detail per app with status variants; the Booking Thread (Request, Approval, Deposit, Balance, Day) is the same component in both apps. | ADR 0003 |
| 4 | **Two rooms, one booking.** Hall × date × session, up to two sections (ladies and men), progressive disclosure so single-hall venues see none of it. | "What are you hosting?" chips only when the venue sells more than one audience; "Both" adds a second section; Mixed is last and never the default. | ADR 0002 |
| 5 | **Honest, all-in prices with units.** | "KD 46 per guest", "From KD 16,100 for 350 guests", no fee after Review, strike-through only against a real prior price, three decimals wherever money moves. | ADR 0004, 0010 |
| 6 | **A planning layer that outlives the booking.** | My Wedding: countdown, next-up actions, checklist, budget, planner packages (one, two or three thread marks, never metal colours), services, chat. | ADR 0007 D2, PRD §6.11-6.13 |

The planner is the PRD's "biggest differentiator" (§6.11); it is built in MVP Phase 2, offered once after a request is sent or confirmed, then only inside My Wedding (ADR 0007 consequences).

## 4. Two apps, one identity, two moods

| | Client app | Hotel / venue app |
|---|---|---|
| Mood | Aspirational, emotional, image-led | Calm, operational, glanceable |
| Used | Evenings on a sofa, family passing the phone around, 8-12 minute sessions | Standing, in a corridor or a ballroom with poor signal, 15-second bursts |
| Core job | "Is it free on our date, what will it really cost, and is the date ours?" | "What needs me now, accept or decline in two taps, block the date I just sold by phone." |
| Primary users | Bride, groom, family, planner | Manager, reception, accountant, owner, marketing |
| Navigation | Discover · Saved · My Wedding · Messages · Profile (ADR 0007) | Today · Bookings · Calendar · Messages · More (ADR 0008) |
| Failure that hurts most | Silence after "Send request" | A request expiring unseen, or a double booking from stale state |

Shared back end: REST API, PostgreSQL, Redis, object storage + CDN, FCM, WhatsApp OTP, MyFatoorah, real-time chat, RBAC, audit log (PRD §5, §11). Two web dashboards (venue admin, super admin) complete the platform; this design pass treats them as context only.

## 5. Experience principles (binding; full text in `docs/design/00-brief.md` §3)

1. **Quiet luxury** — restraint, proportion and photography; never ornament. Empty-room imagery only (ADR 0015).
2. **Image is the hero** — chrome gets out of the way of the photograph.
3. **Certainty before beauty** — price, availability, deposit and status are never ambiguous or hidden behind a tap.
4. **One decision per screen** in flows; progress always visible; Back always safe; drafts never lost.
5. **Native in both scripts** — Arabic is a design target of its own (type sizes, leading, copy written for Kuwait), not a mirror of English.
6. **Operational calm** (hotel) — high density with rigorous hierarchy; colour only when it must carry meaning.
7. **Motion explains** — where did it come from, where did it go, did it work. One success moment per flow.

## 6. Success measures

The PRD (§3) states six goals with soft metrics. NF-MET rows have no numeric targets except the first; the table maps each to the analytics events that will measure it (ADR 0019) and records what is still missing.

| PRD goal | PRD metric (ID) | Measured by | Target / gap |
|---|---|---|---|
| Simplify venue booking | Request completed in under 10 minutes (`NF-MET-01`) | `booking_started` to `booking_submitted` (same `booking_draft_id`), median and p90 | **< 10 min** (PRD). Design budget with a prefilled Brief: about 3-4 minutes, 8 taps. In request mode the clock stops at "Send request"; the deposit is a second session (ADR 0001 D2). |
| Reduce booking time | Days-to-confirmation vs the manual process (`NF-MET-02`) | `booking_status_changed` requested to confirmed, `elapsed_ms_since_submit` | **GAP**: no baseline or target; collect a baseline from launch venues (OQ-P-14). |
| Help couples compare | Compare used in a meaningful share of bookings (`NF-MET-03`) | `compare_id` copied from `compare_book_clicked` to `booking_started.from_compare_id` | **GAP**: "meaningful" undefined. The join exists by design. |
| Increase venue bookings | Confirmed bookings per venue per month grow (`NF-MET-04`) | confirmed transitions by venue and month | **GAP**: no target. |
| Digitalise wedding planning | Couples active beyond the venue booking (`NF-MET-05`) | needs events for checklist, budget and chat use in the 30 days after `confirmed` | **GAP**: "active" undefined, and the ADR 0019 registry has no planning-tool events yet (only `chat_started`, `planner_consultation_requested`). |
| Build the Kuwait wedding graph | Coverage of the Kuwait venue market (`NF-MET-06`) | published venues ÷ all venues in Kuwait | **GAP**: denominator unknown. |

**Proposed health indicators** (not PRD targets; for the owner to adopt or strike, OQ-P-14). They exist because the booking model has two known failure points:

| Indicator | Why | Event source |
|---|---|---|
| Share of requests answered inside the SLA, and expiry-by-silence rate (`venue_no_response`) | Venue calendar staleness and slow replies are the biggest operational risk to "live availability" | `booking_status_changed` (`reason_code`, `elapsed_ms_since_submit`), `request_accepted.response_time_ms` |
| Approval-to-payment conversion and `client_no_payment` expiry rate | ADR 0001 trades refund pain for drop-off between approval and deposit | `booking_status_changed` awaiting_deposit to confirmed or expired |
| Search with zero results; share of searches with a date set | Brief quality drives everything downstream | `search_performed.zero_results`, `event_date` |

## 7. How Ghazal earns (so design does not undermine it)

- **Commission on every confirmed booking** (MK-COM-01), collected up front from the deposit through the gateway's supplier split, so cash balances leak nothing (ADR 0005 D9, 0027 D5). Placeholder 8% with a 10% hard cap; real rates are an owner decision (OQ-B-16).
- **Venue plans** Free / Premium / Featured / Sponsored (MK-SUB-01..03). Paid placement is always labelled `إعلان` / `Sponsored` and never hidden by the one-badge card rule (MK-SUB-04, ADR 0018 D2).
- **Planner packages** (MK-SVC-01): Silver 650, Gold 1,900, Royal 5,500 KD from-prices (placeholders; names are reserved for planners and never used for venue packages). The 25% deposit and any in-app planner payment are a proposal only (OQ-P-19): the PRD defines no planner payment model, so the MVP has no planner checkout and the deposit is arranged with the planner after the consultation.
- **Vendor marketplace** (MK-SVC-04, MVP Phase 2): browse, save and request a quote only; no checkout.
- The couple pays **no Ghazal fee and no processing fee**, at payment or refund. The line "No booking fee" does not ship until the owner confirms it is true (OQ-B-15).

## 8. What Ghazal is not (in the MVP)

- Not a classifieds app: no unframed price lists, no urgency counters, no "Only N left".
- Not a property-management system: the hotel app accepts, blocks, prices and answers; it does not run housekeeping, catering or staffing.
- Not an escrow or wallet: no stored value; refunds go back to the original payment method (ADR 0006 D5).
- Not an AI product: "Recommended for you" is rules-based; the AI wedding assistant, AI budget planner, smart timeline and smart checklist are Phase 3 (RM-AI-01..04).
- Not a GCC product yet: UAE, Saudi Arabia, Qatar, Bahrain and Oman are Phase 4 (RM-GCC-01..05). Week start, weekend, currency exponent and phone rules are per-country configuration from day one so expansion is configuration, not a rewrite (ADR 0010, 0011, 0012).
- Not a government-hall booking engine: Ministry halls are listed with an official-channel hand-off (ADR 0002 D10).
- Not a photo-of-people gallery: empty rooms only, monogram avatars, no avatar upload (ADR 0015).

## 9. Market facts the design leans on

Evidence tags as in the research: **[V]** verified from a source, **[K]** domain assumption to validate with 5-8 venue managers before inventory UI and filters are locked (OQ-B-09).

- iOS 42.9% / Android 57.1% of Kuwaiti mobile [V]. Apple Pay live in Kuwait since 6 Dec 2022 [V]; KNET is an immediate-debit scheme with no documented authorisation hold [V], which is why request-then-pay is the default.
- About 30-32% of residents are Kuwaiti nationals; many readers use Arabic as a second language, so labels are simplified modern Arabic and the hotel app's language is a per-user setting [V].
- Working week Sunday to Thursday, weekend Friday and Saturday [V]; wedding peak Thursday, Friday, Saturday nights [K]. Ramadan 1448 starts about Mon 8 Feb 2027 and swallows National and Liberation Days (25-26 Feb) [T]; Eid dates move with moon sighting, so Hijri markers are labelled approximate.
- 13 Mar to 24 Apr 2026: a ban on weddings and parties proved that an authority-order mass-reschedule path is a real case, not an edge case (ADR 0006 D7) [V].
- Kuwait has no VAT in 2026 and none expected before 2028 [V]: no tax lines unless a venue declares a service charge.
- Government wedding halls: about KD 100 rental, "empty hall" (bring decor and catering), citizens on limited income, booked in the Ministry's own app [V]; eligibility and fees are reported, not verified (OQ-B-10).

## 10. Constraints that frame the vision

| Constraint | Source |
|---|---|
| Eight-week plan: 1 week design for four products in two languages is very tight; no slot for marketplace, planner, chat, reviews and loyalty (CF-29) | PDF §15, `NF-PRJ-01..07` |
| Cold start: venue onboarding and content creation are excluded from scope, so an empty marketplace at launch is the commercial risk (`NF-EXC-01`, `NF-EXC-03`) | PDF §17 |
| Cloud cost USD 20-100 per month; excludes WhatsApp fees, email provider, video egress (CF-28) | `NF-CST-01` |
| Accounts (Apple, Google Play, Google Cloud, MyFatoorah) in the owner's name | `NF-PRJ-09` |
| Both languages from day one; no hardcoded strings; logical CSS only; tokens only | `AGENTS.md`, `NF-LOC-01..07` |
| Payments delegated to a certified gateway; no card data stored | `NF-PAYS-01` |

## 11. Where to go next

`personas.md` (who) · `journeys.md` (how it feels, end to end) · `scope-mvp.md` (what is in and out) · `glossary.md` (words) · `screen-inventory.md` (110 screens) · `open-questions.md` (what the owner must decide).
