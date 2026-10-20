# Research: Product & UX — personas, journeys, IA

> Produced by an independent analyst agent during the Understand phase (Oct 2026). Inputs to ADRs in `docs/decisions/`; where this file and an ADR disagree, **the ADR wins**.

## Key insights

- The decider is not the user: the bride (Noura) owns the file, but her mother (Hessa) holds the veto and often arrives via a WhatsApp link or by being handed the phone. Share, Saved and Compare must work for someone who never creates an account.
- The single number on a venue card is misleading in Kuwait. Real cost = hall fee + per-guest menu + extras, and it swings between weekday, weekend and holiday nights. Make the Brief (date, guests, area, budget) a global context so every card shows a date-aware, guest-aware price and an availability answer.
- KNET is an immediate-debit scheme with no authorisation hold (assumption: verify with MyFatoorah), so 'hold the money now, capture on approval' only works for cards, and refunds are slow. Default booking model: request, then venue approves, then the client pays the deposit inside a time window, with the date soft-held throughout. Instant booking is an opt-in venue mode.
- The PRD's six statuses are enough if Approved is split into two presentation sub-states ('Awaiting your deposit' and 'Confirmed'). Every hotel action needs a visible client-side counterpart state, including Reschedule, which the client PRD never mentions.
- The bookable unit is space x date x session, not venue x date. Surface it with progressive disclosure: show Spaces and Sessions UI only when a venue has more than one. Women-only, men-only and mixed are attributes of a space, not a venue.
- The brief's tab 2 ('Compare / Planner') collides with 'Plan', and Compare is a transient task rather than a destination. Replace it with Saved (shortlist, wishlist and Compare entry). Rename Plan to 'My Wedding' and make Bookings its top card.
- Hotel nav (Today, Bookings, Calendar, Messages, More) is validated by the jobs. The 'persistent pending indicator' should be the Bookings tab badge plus an SLA-aware 'Needs you' block at the top of Today, so the first screen is already the inbox. Accept takes 2 taps with a deferred-send Undo. Decline takes 3 because it needs a reason that powers the client's recovery path.
- The most frequent time-critical hotel action after Accept is 'block a date I just sold by phone or WhatsApp'. It must take at most 3 taps from anywhere and support range select. Kuwait-specific shortcuts (Ramadan, Eid) are cheap and high-value.
- The PRD leaves real holes that need explicit decisions: no planner-facing surface exists in any of the four products; hotel app auth and roles are unspecified; venues have no payout visibility; reviews are notification-only on the hotel side; cash payment needs a hotel-side 'record payment' action; services have no transaction model. This document proposes a minimal, labelled resolution for each.
- The most memorable UX object is not decoration. It is one shared Booking Thread: the same status timeline seen by couple and venue, with each step 'knotting' when done. It earns the Ghazal (love poem / spun thread) meaning through certainty, which is the brief's own principle 3.

## Recommendations

### Client tab structure  _(confidence: high)_

Use 5 tabs: Discover, Saved, My Wedding, Messages, Profile. Do not give Compare or the human wedding planner a tab. Compare is a tray plus a table reachable from Discover, Saved and Venue detail. Bookings is the top card of My Wedding, with a Profile row and a Home status card as shortcuts.

*Why:* Tab real estate should go to places couples return to repeatedly. The shortlist is the family's shared object, and it also gives the PRD wishlist (venues, services, packages) a home. 'Planner' and 'Plan' are near-identical labels in both languages.

### Global Brief and date-aware pricing  _(confidence: high)_

Treat date, guests, area and budget as a global 'Brief'. Prefill it from onboarding, show it as an editable pill on Discover and Results, and make every venue card and the compare table show availability and price for that date and guest count.

*Why:* It answers the couple's real question ('free on our date, and what will it cost?'), removes the phone-call loop, and delivers the PRD's 'certainty before beauty' and sub-10-minute booking goal.

### Booking model  _(confidence: medium)_

Default is Request mode: submit (no money moves), the date is soft-held for the venue response window (default 24h), the venue approves, the client pays the deposit within a payment window (default 24h), then Confirmed. Instant mode (opt-in per venue) goes straight to pay then Confirmed. Cash and government-hall variants are request-only with a venue-recorded payment. Keep the six PRD statuses and render Approved as 'Awaiting your deposit' or 'Confirmed'.

*Why:* KNET has no authorisation hold (verify), refunds after a decline would damage trust, and the PRD's own 'Pending to Approved' flow and 'Refunded' status are preserved. The same screens serve both modes; only the Review CTA and the outcome screen differ.

### Space and session model  _(confidence: high)_

Bookable unit = space x date x session. A venue has 1 to 3 spaces, each with audience (women/men/mixed), setting, capacity and packages. A venue has 1 to 3 sessions (for example Day, Evening, Full day) with venue-defined times. Show a Spaces switcher and Session chips only when the venue has more than one. A second space on the same date (such as a men's reception hall) is sold as an Extra.

*Why:* This resolves PRD gaps 9 and 10 without clutter for single-hall venues, which are the majority. It makes the women/men/mixed filter honest and lets the hotel calendar block per space and session.

### Booking flow shape  _(confidence: high)_

Five steps, then pay, then outcome: Your event (date, session, space, guests, occasion) > Package > Extras > Your details (contact, booking-for, special requests) > Review & confirm > Payment > Confirmed or Request sent. Merge Date+Time and Personal info+Special requests. Move Guest count first, because it drives price and capacity. Interpose sign-in for guests after Extras, before any personal data.

*Why:* Guest count determines package price and capacity validity, so it cannot come after Package. Merging keeps one decision per screen while hitting the under-10-minute target, and late gating maximises completion.

### Compare behaviour  _(confidence: high)_

Persistent tray (max 3) on Discover, Results, Saved and as a header toggle on Venue detail only. It collapses to a pill after idle or on scroll, never appears in booking, Plan, Messages or Profile, and never triggers push. The table uses label-above-value rows, differences-only mode, a 'best fit for your guests' marker (not 'largest') and a Share action to WhatsApp.

*Why:* Compare must be visible without nagging. The 390pt width only fits three columns if row labels sit above the values. Families decide in WhatsApp groups, so Share is the highest-value Compare feature.

### Guest gating  _(confidence: high)_

Guests can do everything read-only plus local heart and compare, availability checks and price estimates. Gate at commit moments, preserve intent, and resume exactly: the booking request, payment, sending chat, writing a review, the planner consultation, persisting budget or checklist data, and notification-dependent features. Ask for the account right before personal data in the booking flow.

*Why:* This matches the PRD (guest browsing), App Store expectations that login is required only for account-based functionality, and conversion best practice. Hearts are the strongest sign-up hook.

### Hotel app operating model  _(confidence: high)_

Keep Today, Bookings, Calendar, Messages, More. The Bookings badge is the persistent pending indicator, and Bookings opens on Pending when count > 0. Today leads with a 'Needs you' block ordered by deadline. Accept = 2 taps with an 8-second Undo (notification dispatch deferred), Decline = reason sheet, Block date <= 3 taps with range select. Accept, decline and block are never queued offline.

*Why:* The jobs are glance, decide, block, answer. Operational surfaces must be fast and unambiguous, and ballrooms have poor connectivity. Queuing irreversible state changes offline creates double-booking risk.

### Role-aware content, constant navigation  _(confidence: medium)_

Keep the same 5 tabs for every staff role. Hide content the role cannot use (Reception: no revenue, bank or analytics; Accountant: money-first Today, no chat by default; Marketing: offers and analytics). If a deep link targets a forbidden object, show a clear 'ask your manager' screen.

*Why:* PRD section 8.7 defines Reception, Manager, Accountant and Marketing roles. In independent halls one person holds all roles, so the model must degrade to 'everything visible'.

### Services marketplace scope  _(confidence: medium)_

Services are browse, save, and enquire only: category list, vendor profile (portfolio, packages, from-price), Save, Add to budget, and Request quote which opens a vendor chat. No checkout, no payment, no vendor availability calendar in MVP.

*Why:* The PRD lists 16 services but defines no booking, payment or vendor-side product, and PDF section 4 contradicts section 14 on timing. 'Enquire' honours the requirement without inventing a second booking system.

### Notification budget and landing rules  _(confidence: high)_

Transactional notifications (booking, payment, message) always deliver and land on the exact object, with the stack rebuilt so Back is sensible. Marketing (offers, price drops, new venues) is opt-in with default quiet hours 22:00-09:00, a cap of 2 per week, and nothing in the final 7 days before the wedding. OS permission is requested after the first value moment, never at launch.

*Why:* Nagging destroys the premium feel. Weddings happen at night and families are on their phones then. A landing table with fallbacks makes deep links testable.

### Prototype scoping  _(confidence: high)_

Build the demo spine at full fidelity (P0): Client = onboarding brief, Home, Results, Filters, Venue detail, Calendar, Gallery, Compare, full booking flow in both modes, Booking detail (4 variants), My Wedding home, Saved, Messages thread. Hotel = Today, Bookings list and detail with accept and decline, Calendar with block, Create offer, Messages thread. Everything else is built to design-system standard (P1/P2) using shared patterns. Seed both apps with one shared storyline so the two prototypes show the same booking from both sides.

*Why:* About 60 client and 40 hotel surfaces exist. The spine tells the whole product story and exposes every novel pattern; the rest is mostly recombination.

## Risks & gaps

- No planner-facing surface exists among the four products (PRD section 4 lists planners as primary users; sections 6.11 and 9.8 treat them as Ghazal-assigned supply). Planner-side chat, availability and assignment are unowned. MVP assumption: the planner persona uses a normal client account, one wedding file at a time, and Ghazal planners respond through admin tooling.
- Hotel app authentication, staff invitation, venue approval or suspension states, and the role-to-permission matrix are not specified. Auth and states are inferred here (WhatsApp OTP plus invite, account-status screens). Confirm with the owner.
- Deposit rule (digest gap 8) rests on an unverified payments assumption (no KNET authorisation hold) and on default windows of 24h/24h that no venue has validated. If the owner wants 'deposit at request', Request mode would charge up front and refund on decline. That is a materially worse UX in Kuwait, so it needs an explicit owner decision.
- Venue-side money visibility is thin. The PRD gives the accountant 'Payment received' notifications and 'Bank info' but no payout, settlement or commission view in the hotel app. Revenue detail shows collected vs expected only. Payout status is a gap for Super Admin 9.4 and Finance 9.11.
- The PRD web 'approve reviews' (8.9) invites venue gate-keeping of public reviews and would erode trust. Recommend 'report abuse' only, with moderation by Ghazal admin. Needs a policy decision.
- Cash payment and government halls break the pay-online assumption. Cash needs a hotel-side 'record payment received' action (derived, not in section 7), and government halls (eligibility, fixed tariff, outside payment) are unspecified.
- Client-initiated change or cancellation of a confirmed booking is not specified beyond the status names. The design assumes cancellation by the client within policy (refund preview) and refunds processed by venue or admin on the web. Venue-initiated cancellation of a confirmed booking is routed to Support, not built in the app.
- Several proposals are not in the PRD and must be approved or cut: Occasion field (milka, henna, wedding), Share link or image, secondary Hijri dates, Waze deep link, privacy mode for revenue, quick-reply templates, venue switcher, Ramadan and Eid block shortcuts, 'send payment link to payer'. Each is cheap but is scope until the owner says otherwise.
- Kuwait market assumptions (peak Thu/Fri/Sat nights, 24h response norms, female-only photography norms, government hall eligibility, iOS share, KNET behaviour) are informed but unvalidated. A 30-minute call with two hall owners and one hotel events manager would settle most of them.
- Single-account planners and payers: the PRD has no 'multiple weddings' and no 'someone else pays' model. A planner managing three clients, or a father paying a deposit from his own Apple Pay, will hit friction. Mitigations are in the design (booking-for field, share links) but not a real solution.

## Open questions for the owner

- Deposit timing: do you accept 'request, venue approves, client pays deposit within a window' as the default (no money at request), with Instant booking as an opt-in venue mode? Or must the deposit be paid at request time?
- What are the real response and payment windows venues will accept (default 24h and 24h)? Should an unpaid approved date auto-release, and should the venue's response rate be a visible ranking signal?
- Are halls sold per space and per session in Kuwait (for example women's hall evening vs a men's reception hall vs a daytime lunch)? How many sessions do your first 10 venues actually run?
- Government halls: who may book (citizens with Civil ID?), is the tariff fixed, and does payment happen outside Ghazal? Should they be request-only with no online payment in MVP?
- Who is the 'wedding planner' user? Ghazal-employed or partner planners assigned by the admin (PRD 6.11 and 9.8), or independent planners booking for clients (PRD section 4)? Is a planner app or planner mode intended, or is it web or admin only?
- Hotel app login: WhatsApp OTP plus owner-sent staff invites, or email plus password plus 2FA? Is one person allowed to hold multiple roles, and can one account manage more than one venue?
- Services marketplace: confirm MVP is browse and enquire only (no checkout, no vendor tooling). Reconcile PDF section 4 ('vendor categories introduced after MVP') with section 14 (Phase 2 included in MVP).
- Do you approve the small proposals: Occasion field, Share link and image, Hijri secondary dates, Waze link, revenue privacy mode, quick-reply templates, Ramadan and Eid block shortcuts, 'send payment link to payer'?
- Reviews: may venues approve or hide reviews, or only reply and report abuse? Can only completed bookings review?
- Coupons: what are the stacking rules between loyalty coupons, venue coupons (hotel 7.5) and platform promos? Can a coupon apply to deposit only, or to the total?
- Cash payments: can a venue accept cash for the deposit, and who confirms receipt and when does the date release if it never arrives?
- Account deletion with an active or upcoming booking: block until settled, or accept the request and complete after the event? (Apple requires in-app initiation either way.)

---

## Full findings

# Ghazal — Product & UX Lens
Personas · jobs-to-be-done · journeys · information architecture · screen inventory · micro-interactions

**Tags used throughout**
- **[PRD]** stated in `project.md` or the PDF.
- **[Derived]** not stated, but required to complete a PRD'd flow (a screen or state that must exist).
- **[Proposal]** not in the PRD. Needs owner approval. Tracked as an open question and never silently built.
- **(assume)** a Kuwait market assumption to validate with venues or the owner.

Sample dates assume today = 10 Oct 2026. Ramadan 2027 is roughly 8 Feb to 8 Mar (moon-sighting dependent) (assume).

---

## 0. The 16 binding decisions from this lens (UX-D1 to UX-D16)

| ID | Decision (short form) | Detail in |
|---|---|---|
| UX-D1 | Client tabs: **Discover · Saved · My Wedding · Messages · Profile**. No tab for Compare or for the human planner. | 5.2 |
| UX-D2 | Hotel tabs: **Today · Bookings · Calendar · Messages · More** (hypothesis kept). | 5.5 |
| UX-D3 | The **Brief** (date, guests, area, budget) is global context. All prices and availability are date-aware and guest-aware. | 5.2, 4.5 |
| UX-D4 | Booking model: **Request mode by default (approve, then pay deposit inside a window)**. **Instant** is an opt-in venue mode. Cash and government variants are request-only. Six PRD statuses kept, with sub-states. | 4 |
| UX-D5 | Bookable unit is **space x date x session**, shown with progressive disclosure. Women/men/mixed is an attribute of a space. | 4.3 |
| UX-D6 | Booking flow: 5 steps + pay + outcome. Guests move first. Date+Time and Details+Requests are merged. Sign-in interlude sits before personal data. | 6.2 (flow 5) |
| UX-D7 | Compare = tray (max 3, anti-nag rules) + table. It lives inside Discover, Saved and Venue detail. Includes Share. | 5.2 |
| UX-D8 | Guest rules: read-only plus local heart and compare. Gate at commit moments. Resume the exact intent. | 5.3 |
| UX-D9 | My Wedding is phase-aware (pre-venue, booked, day-of, post). Countdown is a hero state, not a screen. | 6.2 (flow 9) |
| UX-D10 | Services = browse, save and enquire. No checkout. | 6.2 (flow 8) |
| UX-D11 | One canonical screen per object. Every hotel action has a visible client counterpart state. | 3.3, 5.7 |
| UX-D12 | Hotel: Undo instead of confirm. Accept = 2 taps. Decline needs a reason. Decisions are never queued offline. | 5.5 |
| UX-D13 | Money: two formatter modes (compact for browse, exact 3 dp for payments and ledgers). Western digits by default in Arabic, with a setting. | 4.5 |
| UX-D14 | Memorable UX object: the shared **Booking Thread** timeline, seen identically by couple and venue. | 7, 8 |
| UX-D15 | Notification budget: transactional always, marketing opt-in with quiet hours and a cap. Permission is asked after the first value moment. | 5.4 |
| UX-D16 | Navigation is constant across roles. Content is role-aware. Forbidden deep links get an explicit screen. | 5.5 |

---

## 1. Context that drives every decision

### 1.1 Two apps, two jobs
- **Client app** is a considered purchase made over weeks, socially, with money and emotion at stake. Its job is to move from *"is it free on our date, and what does it really cost?"* to *"the date is ours"* with no phone calls.
- **Hotel app** is an operations tool used standing, in bursts, often in ballrooms with poor signal. Its job is to turn *"what needs me now?"* into one-thumb, zero-ambiguity actions.
- The shared backbone is **one booking, seen from two sides**.

### 1.2 Kuwait facts we design around
- **Week and calendar.** Work week is Sun to Thu and weekend is Fri to Sat. Weddings cluster on Thu, Fri and Sat nights (assume). Weekend and holiday pricing makes date a price input. National and Liberation Days (25 to 26 Feb) are premium dates.
- **Ramadan and Eid** shut or limit venues. Their Hijri-driven dates shift about 11 days earlier each year. Summer (Jun to Sep) means indoor only and many families travel. Nov to Mar is outdoor and beach season (Khiran, Messila, Bnaid Al-Qar).
- **Gender-separated celebrations are still common.** There is a women's wedding hall, with a separate men's reception (diwaniya or men's hall). Mixed hotel weddings are growing. So audience is a first-class attribute. Photography, phones and staff policy in women's halls is a decision criterion, not trivia (assume).
- **Scale.** Guest counts run into the hundreds (brief: 100 to 1,500; many family weddings 300 to 1,200). Gulf word: المعازيم. Guest count is *per hall*.
- **Price structure** = hall fee + per-guest menu + extras (kosha and décor, lighting and sound, valet). A single "from" price misleads. Date and guests must be inputs.
- **Several events per wedding.** A couple often buys 2 to 4 bookings: milka (contract), henna night, wedding night, sometimes a next-day lunch.
- **Payments.** KNET (debit) is dominant, Apple Pay is widespread on iPhone, cards are secondary. Cash and bank transfer persist with halls (assume). Handoff to KNET and MyFatoorah is a redirect with an asynchronous result, so a "verifying" state is mandatory.
- **WhatsApp is the operating system.** Venues sell through WhatsApp Business, families deliberate in WhatsApp groups, voice notes outnumber typed messages, and Instagram drives discovery. Waze dominates navigation. Links travel as screenshots.
- **Decision-making is familial.** The mother holds the veto. The payer is often a parent or the groom's family, not the booker.
- **Government halls** are subsidised and citizen-restricted, with a separate process (PRD gap 10).
- **Venue staff are multinational.** EN-only and AR-only users coexist in one venue, so language is a **per-user** setting. Independent halls often put owner, GM, accountant and reception in one person.
- **Identifiers.** Phone is +965 with 8 digits (mobiles start 5, 6 or 9). Civil ID has 12 digits. A Kuwait IBAN is 30 characters starting "KW".

---

## 2. Personas (illustrative composites, not real people)

### Client personas

**C1 · Noura Al-Mutairi, 26 — the bride, who owns the file**
- **Context of use.** Works in Kuwait City and lives with family in Salmiya. Milka done, wedding targeted for spring 2027 after Eid, about 650 guests in the women's hall. Researches 21:00 to 01:00 on the sofa or in bed, in 8 to 12 minute sessions over 3 to 4 weeks. Shares screenshots to the family WhatsApp group.
- **Jobs-to-be-done.** *When we shortlist halls with our family, show which are actually free on our date and what they would really cost, so we stop chasing eight WhatsApp chats.* *When we've chosen, lock the date before someone else takes it.* *Keep every booking, payment and to-do in one place.*
- **Anxieties.** Losing the date. Hidden per-guest and extras costs. "Instagram lies" (photos vs reality). Losing a deposit. Her mother's reaction. Being left on "seen" by a venue. Exposure of private wedding details.
- **Device and habits.** iPhone (13 to 15), iOS 17+, AR UI, dark mode at night, Face ID, Apple Pay and KNET. One-handed thumb use. Voice notes. Sometimes increased text size.
- **Design implications.** Prefilled Brief, date-aware prices, a Share action on everything, a calm and honest Pending state, a gated booking flow that never loses her selections.

**C2 · Hessa Al-Enezi, 55 — mother of the bride, veto-holder and sometimes the payer**
- **Context of use.** Usually *not* a registered user. Opens a link from WhatsApp, or is handed Noura's phone. Android (mid-range Samsung) or an older iPhone, Arabic only, text size 130 to 200%. Prefers calling or voice notes. Decides with sisters.
- **Jobs-to-be-done.** *When my daughter shows me a hall, let me judge in seconds whether it is dignified and practical (capacity, women's entrance, bridal suite, kosha, valet and parking for elders, photo privacy, food), without learning an app.* *When it is time to pay, let me do it safely, from my own card or phone.*
- **Anxieties.** Tech confusion. Fine print. Being rushed. Photo and phone privacy for women. "What will people say about this hall". Capacity too small for the family. Safety of online payment.
- **Device and habits.** Large text, small-target fatigue, trusts people over screens, forwards screenshots.
- **Design implications.** Guest-first read-only browse with no sign-in wall. Facility rows that read as plain yes / extra-cost / no. Visible phone and chat. 48 to 56 px targets. A 'Send payment link to payer' [Proposal].

**C3 · Rima Haddad, 34 — independent wedding planner (power user, underserved in MVP)**
- **Context of use.** Runs a small planning business with 10 to 15 weddings a year. Two phones plus iPad, English UI with Arabic clients, WhatsApp Business all day. Shortlists for three clients at once and has relationships with venue sales managers.
- **Jobs-to-be-done.** *When a client gives me a date and budget, let me check many halls fast and send a comparison the family can open.* *Keep hold requests and paperwork organised per client.*
- **Anxieties.** Double-booking across clients. Being undercut by Ghazal's own planner packages. Commission opacity. Wasted time on halls "available" but not really. One account means one wedding.
- **Design implications.** Strong guest browse, shareable compare, a "Booking for: someone else" field at the Details step, and a clear 'not supported yet: multiple weddings' flag.

### Hotel personas

**H1 · Khalid Al-Rashidi, 46 — General Manager (hotel Director of Events, or owner-operator of an independent hall)**
- **Context of use.** On the move, on his feet, mid-event at night. Checks the phone 40+ times a day. Glances in the morning at 08:30. Owner-operators also act as accountant and reception.
- **Jobs-to-be-done.** *At the start of my day, tell me in seconds what needs my decision and what money is coming.* *Protect prime dates and fill soft ones.* *Keep my rating healthy.*
- **Anxieties.** An empty Thursday in peak season. Double-booking. Staff mistakes. Devaluing the brand with discounts. Ratings. Commission. Revenue visible to wandering eyes. A lost phone.
- **Device and habits.** iPhone Pro, bilingual. Reads in 15-second bursts. Voice-notes his team.
- **Design implications.** Today answers "what needs me" before anything else. Role-aware views. Revenue privacy toggle [Proposal]. Biometric lock.

**H2 · Maryam Al-Kandari, 28 — booking coordinator (reception)**
- **Context of use.** At a desk with the PMS or Excel, plus her own phone with the app. Handles phone calls, WhatsApp and Ghazal at once, up to 10 to 40 requests a week in peak. Cannot change prices or bank details. Language varies by colleague (some are EN-only).
- **Jobs-to-be-done.** *When a request lands, give me everything I need to decide without calling.* *Never let a request expire unseen.* *Answer the same ten questions fast.*
- **Anxieties.** Missing a request. Double-booking. A manager asking "why is this pending?". Clients ghosting after approval.
- **Design implications.** SLA countdowns, a Bookings badge, quick replies, voice notes, a one-tap call sheet, and clear permission boundaries.

**H3 · Mahmoud Saleh, 41 — accountant (part-time on the venue, expat, English-leaning, Android)**
- **Context of use.** Mostly reconciles in Excel and on the web dashboard. The app is for "did that deposit land?" checks and invoices.
- **Jobs-to-be-done.** *When a payment lands, show which booking and what is still due, so I reconcile without chasing.* *Keep bank details correct and safe.*
- **Anxieties.** Mismatch between gateway settlement and bookings. Refund status. Invoice errors. Changed IBAN fraud.
- **Design implications.** Revenue detail ledger (collected vs expected), payment status on every booking, invoice share, Bank info with re-authentication and a masked IBAN.

### What the six personas imply
- The **user** is Noura, the **decider** is Hessa, and the **power user** is Rima. Share, Saved and Compare have to work for people who never sign up.
- The hotel app serves three modes of the same venue: **decide** (GM), **respond** (coordinator), **reconcile** (accountant).

---

## 3. Journeys

### 3.1 Client journey (emotion scale: -2 anxious to +2 delighted)

| # | Stage | What they do (surfaces) | Emotion | Friction | Design response |
|---|---|---|---|---|---|
| 1 | **Discover** | Onboarding Brief, Home, Results | +1 to 0 (overwhelm) | Too many look-alike venues. Price opacity. Availability unknown. | Brief-led results. "Free on your date" is the lead shelf. Date-aware price. Curated photo order. |
| 2 | **Compare** | Heart and compare, tray, table, WhatsApp share | 0 to +1 | Decision fatigue. Mother cannot see the options. Three-venue limit. | Tray, differences-only, "best fit for your guests", share link or image. |
| 3 | **Check date** | Venue calendar, session chips | -1 to +1, or -2 if unavailable | Calendar says free but it is "request". Dead end when unavailable. Peak-price surprise. | Per-date price in the calendar. Honest "Held" language. Nearest free dates + similar venues free that day. |
| 4 | **Request or book** | Booking steps 1 to 5 | +1, -1 (form fatigue), -1 (silent wait) | Long forms. Auth wall mid-way. Unclear totals. Silence after submit. | Prefill. Five steps. Late gate with resume. Pending screen with timeline and promise. |
| 5 | **Pay deposit** | Payment, KNET or Apple Pay, verifying, confirmation | -1 to +2 (peak) | KNET redirect and return. Fear of paying twice. Refund policy unclear. Hold timer stress. | Clarity before pay (what, when, refund). A "verifying" state. "Safe to leave". Instant receipt. |
| 6 | **Plan** (planner, vendors, budget, checklist) | My Wedding, Checklist, Budget, Services, Planner, Chat | +1, -1 (budget creep), +1 | 6 to 18 months of dormancy. Overwhelm. Surprise costs. Planner upsell feels pushy. | Phase-aware home. Next-three actions. Committed vs paid vs remaining. Milestone nudges at 365/180/30/7/1/0. Planner offer once, not repeatedly. |
| 7 | **Wedding day** | Day-of mode (hero state) | +2 / stress | Needs venue phone and directions fast. | Hero: Directions, Call venue, Message planner. No marketing that week. |
| 8 | **Review** | Review prompt at T+1 day | +2 | Effort. Photo privacy. | Stars, one line, optional photos (halls, food and decor only). Points reward. |

```
Emotion curve (client)
+2 |                                 *deposit confirmed       *day-of    *review
+1 | *discover      *clarity                         *progress
 0 |
-1 |      *overwhelm      *date anxiety   *waiting for venue     *budget creep
-2 |                   (if date unavailable)
     1 Discover  2 Compare  3 Date  4 Request  5 Pay  6 Plan  7 Day  8 Review
```
- **Valley to design hardest:** "waiting for the venue" (stage 4 to 5). The Pending state is the most important screen nobody screenshots.
- **Peak:** deposit confirmed. **End:** wedding day and review.

### 3.2 Hotel journey (time-of-day anchored)

| # | Moment | What they do | Emotion | Friction | Design response |
|---|---|---|---|---|---|
| 1 | **Morning glance** 08:30 | Open Today | 0 to +1 | Scattered across WhatsApp and PMS. Unsure if overnight requests expired. | "Needs you" block first. Badge. A calm "All clear" state. |
| 2 | **Accept or decline** | Bookings > detail | -1 (SLA pressure) to +1 | Missing information. Conflict anxiety. Calling to confirm. | Request detail shows date, session, space, package, guests, total, deposit, special requests, auto conflict-check. Accept with Undo. Decline with reason or propose another date. |
| 3 | **Block a date** (phone sale) | Calendar, date, Block | -2 (urgent) to +1 | Calendar lives in diary or PMS. A couple may be booking the same night. | 3 taps, default reason "Booked offline", range select, "Hidden from couples now" confirmation. |
| 4 | **Publish a flash offer** | Soft-date insight, create offer | 0 to +1 | Do not know which dates are soft. Brand-devaluation fear. Forms. | Soft-date insight. Presets. Live card preview. Auto-expiry. Performance tracking. |
| 5 | **Answer chat** | Messages, thread | -1 to +1 | Repetitive questions. Typing Arabic on phone. Missing context. | Quick replies, voice notes, booking context bar, "needs reply" filter. |
| 6 | **Review revenue** | Today card, Revenue detail, Analytics | 0 to +1 | Reconciliation. Numbers differ from PMS. | Collected vs expected, ledger, period delta. |

```
Emotion curve (hotel, one day)
+1 |      *relief (queue clear)        *offer published       *revenue check
 0 | *glance
-1 |           *SLA pressure      *chat bursts
-2 |                 *phone sale, block date NOW
```
- **Evening-at-an-event micro-scenario.** Standing in the ballroom, one hand, poor signal, a new request pings. The notification opens the booking detail (cached shell, live status). Accept is allowed only when online; otherwise "Offline. Reconnect to accept" appears in place.

### 3.3 State pairs: every hotel action has a client counterpart (UX-D11)

| Hotel action or event | Hotel state | Client state | Client landing |
|---|---|---|---|
| Client submits (Request mode) | New request + SLA timer | Pending, "Held until {time}" | Booking detail |
| Accept | Awaiting deposit | Approved, "Awaiting your deposit" + payment timer | Booking detail, Pay CTA |
| Decline | Archived, Rejected | Rejected + reason + "Free on your date" alternatives | Booking detail + rail |
| Venue ignores for window | Expired, "Missed" | Cancelled (expired) + alternatives | Booking detail + rail |
| Reschedule (propose) | Awaiting client response | "Venue proposed {new date}": Accept / Decline / Chat | Booking detail sheet |
| Client pays deposit | "Deposit received" | Confirmed + receipt | Receipt |
| Client does not pay in window | Auto-release | Cancelled (expired) | Booking detail |
| Client cancels | Cancelled by client | Cancelled + refund preview then Refund processing | Booking detail |
| Refund completes | Refunded | Refunded | Payments history |
| Event ends | Completed | Completed then review prompt T+1 | Review composer |

### 3.4 Moments that matter (design these first)
1. Pending state (client). 2. Payment verification. 3. Date unavailable recovery. 4. Hotel "Needs you" and Accept with Undo. 5. Block date. 6. Compare table on a 390pt screen. 7. Booking Thread shared timeline. 8. Wedding-week and Day-of mode.

---

## 4. The booking model (resolves PRD gaps 8, 9, 10 for design)

### 4.1 Modes (venue-configured; UI renders from data)
- **Request (default) [Derived].** Submit creates no payment. The date is **soft-held** for the venue response window (default 24h, venue-set 12/24/48h). Venue Accept starts the client **payment window** (default 24h). Deposit paid then **Confirmed**. If either window lapses, the hold auto-releases and the booking becomes Cancelled (reason Expired). Both parties are notified and both see the reason.
- **Instant (opt-in)** `[PRD: instant-booking badge]`. Step 5 CTA is "Pay deposit". A 10-minute checkout hold protects the date during payment. On success the booking is Confirmed. The venue gets "New booking" and cannot decline (it may cancel under policy via Support).
- **Cash variant [PRD 6.9].** After Accept, the client picks "Pay deposit at venue". The venue sets a deadline. The hotel needs **Record payment received** [Derived]. If it is not recorded by the deadline, the hold releases.
- **Government halls (gap 10).** Request-only, fixed tariff, eligibility field (Civil ID) at the Details step, no online payment by default. Mark as a variant to verify with the owner.
- **Why not "charge at request, refund on decline".** KNET is an immediate-debit scheme with no authorisation hold (assume, verify with MyFatoorah), so only cards could be held. KNET refunds are slow, so a decline would turn into days of "where is my money?". Venues also prefer approving before money moves.

### 4.2 Status vocabulary (keep the six PRD statuses; sub-states are presentation only)

| PRD status | Client label (sub-state) | Hotel label | Who can act | Money |
|---|---|---|---|---|
| Pending | "Request sent" + hold timer | "New request" + SLA | Hotel: Accept / Decline / Reschedule. Client: cancel request (free) | none |
| Approved | **"Awaiting your deposit"** + payment timer | "Awaiting deposit" | Client: Pay. Hotel: Chat / Call / Reschedule | none |
| Approved | **"Confirmed"** (deposit paid) | "Confirmed · deposit received" | Client: Pay balance / Cancel. Hotel: Invoice | deposit in |
| Rejected | "Not accepted" + reason | archived | none | none |
| Cancelled | by me / by venue / expired (+ refund state) | same | none | refund preview then processing |
| Completed | "Completed" then review prompt | "Completed" | Client: Review | settled |
| Refunded | "Refunded" | "Refunded" | none | refunded |

Balance: deposit % (venue-set), balance due date (venue-set, default 14 days before). Reminders at 28, 21, 14, 7 days. Overdue balance flags on the hotel Today ("at risk").

### 4.3 Space, session and the women / men / mixed question (gap 9) [Derived, UX-D5]
- **Venue** contains 1 to 3 **Spaces**. Each space has an audience (women / men / mixed), setting (indoor / outdoor / mixed), capacity range and packages.
- **Sessions** are 1 to 3 per venue, venue-labelled with times (for example Day, Evening, Full day).
- **Bookable unit** = space x date x session.
- **Progressive disclosure.** Single-space and single-session venues (the majority) never see Spaces or Sessions UI. Multi-space venues get a Space switcher under the title and a Space question in booking step 1.
- **Extras.** A second space on the same date (for example "Men's reception hall") is an Extra with its own availability check.
- **Filter semantics.** "Women only" matches venues that have at least one women-only space. The card shows the matched space's audience.
- **Guest count** means guests in the chosen space ("Guests in this hall").
- **Hotel calendar** blocks per space and session, with a Space filter shown only when more than one exists.

### 4.4 Occasions [Proposal]
Add an optional **Occasion** chip in step 1: Wedding night (default) / Milka / Henna night / Engagement / Other. It changes capacity, package and price, and venues need it. It adds no new screen. If rejected, fall back to Special requests.

### 4.5 Price and date display rules (UX-D13)
- **Card price** = *"{price} for {date}, {N} guests"* when a Brief exists, else "From {hall fee}" plus "{per-guest}/guest". The date-aware figure is the headline.
- **Estimate breakdown** (venue detail sticky bar, Review step): hall + menu x guests + extras = total, then deposit now and balance later. No fees may appear after the Review step.
- **Money formatter modes.** *Compact* (browse): trim `.000` ("2,400 KWD" or "2,400 د.ك"), but always show full 3 digits when non-zero ("18.500", never "18.5"). *Exact* (Review, payment, invoices, ledgers, analytics): always 3 dp. AR: number then د.ك. EN: KWD then number.
- **Digits.** Default Western (0-9) in Arabic UI (Kuwait digital convention). Setting: "Digits: 0123 / ٠١٢٣" in Language & region. Tabular figures always.
- **Dates.** Gregorian primary. Optional Hijri secondary line [Proposal], default on in AR, off in EN. Week starts Sunday. Weekend marks on Fri and Sat.

---

## 5. Information architecture

### 5.1 Principles
1. **One canonical screen per object** (Venue, Booking, Conversation, Offer, Review, Package). Every other place is a link to it.
2. **Navigation is stable. Content adapts** to phase (client) or role (hotel). Never reorder tabs.
3. **Tabs are places users return to.** Tasks and tools are pushed screens or sheets.
4. **Context travels.** The Brief (client) and the active Venue and Role (hotel) are global.
5. **Three-tap rule.** Every PRD requirement group is at most 3 taps from a tab root (client), and every hotel operational task is at most 3 taps. Hotel configuration is at most 4. Booking-flow steps are excluded.
6. **Gate late, resume exactly.**
7. **Deep links rebuild the stack** (tab root, then parent, then target) so Back always makes sense. In RTL, edge-swipe back flips.

### 5.2 Client app IA

**Tab bar (UX-D1).** Labels are always visible. Order mirrors in RTL.

| # | Tab (EN / AR) | Contains | Badge |
|---|---|---|---|
| 1 | **Discover** / استكشف | Home, search, results (list or map), filters, Venues and Services switch, venue detail | none |
| 2 | **Saved** / المفضلة | Wishlist (Venues, Services, Packages), Compare entry | none |
| 3 | **My Wedding** / عرسي | Countdown, next actions, Bookings, Planner, Checklist, Budget, Payments entry | dot when an action is due (deposit, balance) |
| 4 | **Messages** / الرسائل | Inbox, threads (venue, planner, vendor, support) | unread count |
| 5 | **Profile** / حسابي | Personal and wedding info, Payments, Rewards, Notifications prefs, Language, Settings, Delete account | none |

Notification bell (header) is on Discover and My Wedding (1 tap). Profile > Notifications is the preferences screen.

**Tab-bar visibility.** Hidden in: onboarding, booking flow, gallery viewer, chat thread (composer), comparison table, full-screen map, payment webview. Visible everywhere else, including pushed detail screens. Per-tab stacks persist when switching tabs.

**Launch tab.** Discover until a booking is Confirmed. After that, My Wedding is the default launch tab. The tab order never changes.

**Sheets vs pushes.** Sheets: Brief, filters, sort, calendar, package detail, auth, cancel, reschedule response, add expense, planner scheduler. Pushes: venue detail, booking detail, comparison, chat thread, checklist, budget.

**Where Compare lives.**
- **Entry:** heart-adjacent Compare toggle on every card and on the Venue detail header; Saved has a multi-select "Compare (n/3)"; a Home "Your shortlist" module appears once something is saved.
- **Tray (component):** shows on Discover, Results and Saved only. On Venue detail it is replaced by a header badge so it never covers the primary CTA.
- **Tray rules (anti-nag).**
  - Appears only after the first add. At 1 it reads "Add one more to compare" (neutral). At 2 to 3 it reads "Compare {n}" (actionable).
  - Collapses to a small pill after about 4s idle or on scroll-down; reappears on scroll-up.
  - Never in booking, My Wedding, Messages or Profile. Never triggers a push. Dismissing "Clear" is not re-prompted that session.
  - The 4th add opens "Replace which one?" (no silent drop).
  - Tray contents persist across sessions (local for guests, synced after sign-in).
- **Table:** a pushed screen. See flow 4.

**Where Bookings lives.** Canonical: **My Wedding > Bookings** (the top card, plus a list when there is more than one). Shortcuts: Home status card (1 tap), Profile > Bookings row (same screen), and every booking notification (0 extra taps).

**Home status card (one at a time, by urgency).**

| State | Content | Action |
|---|---|---|
| Guest or no date | "When is the big day?" | Set date |
| Brief set, no booking | "{N} venues free on {date}" | See them |
| Pending | "Waiting for {venue} · {h} left" | View request |
| Approved, awaiting deposit | "{venue} approved your date. Pay {deposit} within {h}" | Pay deposit |
| Confirmed | "{N} days to go · Balance {amount} due {date}" | Open My Wedding |
| Day-of | "Today · {venue}, {time}" | Directions |
| Post-event | "How was {venue}?" | Review |

**Client tap-depth (from a cold start, signed-in, Discover).**

| Task | Taps |
|---|---|
| See if a venue is free on my date | 0 (badge on card) or 1 (open the venue, availability inline) |
| Compare two venues | 3 (Compare on card x2, then tray "Compare") |
| Request a booking (Brief prefilled) | Card 1, CTA 2, steps 3 to 7, Send 8 (about 3 to 4 minutes) |
| Check booking status | 1 (Home status card) or 2 (My Wedding, booking card) |
| Pay balance | 1 from push, or 3 in-app (My Wedding, booking, Pay) |
| Message a venue | 2 (venue page, Message) or Messages tab 1, thread 2 |
| Add an expense | 3 (My Wedding, Budget, Add) |
| Tick a checklist item | 2 (My Wedding, "Next up" tap) or 3 in the list |
| Change language | 3 (Profile, Language, choose) |
| Delete account | 3 (Profile, Settings, Delete) |

### 5.3 Client guest-gating rules (UX-D8)

| Level | Capability |
|---|---|
| **Open (no account)** | Language choice, intro, Brief (stored locally), Home, search, filters, results (list and map), venue detail incl. availability calendar and price estimate, gallery and video, reviews (read), similar venues, Share, services browse and vendor profiles, planner package info, legal pages. **Heart and Compare work locally** and merge into the account on sign-in. |
| **Soft gate (progress allowed, account at the commit moment)** | Booking flow: steps 1 to 3 are open, the account is requested before step 4 (personal data), and the selection is preserved. Budget and checklist: viewable with sample structure, "Sign in to save" at the first write. |
| **Hard gate (sheet, then resume the exact intent)** | Send booking request, pay, send a chat message, write a review, request a planner consultation, request a vendor quote, rewards and coupons, notification-based features. |

- **Sign-up nudge.** After the 3rd heart: "Sign in to keep your shortlist on every device" (once).
- **Single identity entry.** There is one unified phone-first entry: WhatsApp OTP, Apple, Google, and email as a tertiary link. No separate Sign up vs Login screens.
- **Resume.** After auth, return to the exact pre-gate state (screen, selections, scroll).
- **Why.** App Review expects login only where account-based features require it (5.1.1). Guests complete the research phase, and the heart is the strongest sign-up hook.

### 5.4 Client deep links and notification landings (UX-D15)

| Trigger | Lands on | State and behaviour | Fallback |
|---|---|---|---|
| Booking request received by venue | Booking detail (Pending) | Timeline highlighted | If deleted: My Wedding |
| **Booking approved** | Booking detail (Awaiting your deposit) | Scroll to Pay CTA, payment timer visible | If expired: Booking detail (Cancelled, expired) + alternatives |
| Booking rejected | Booking detail (Not accepted) | Reason + "Free on your date" rail | none |
| Reschedule proposed | Booking detail, response sheet open | Accept / Decline / Chat | none |
| Payment confirmed | Receipt | Check animation once | If failed: Payment retry sheet |
| Payment failed | Booking detail, Payment sheet | Retry or other method | none |
| Balance due (D-28/21/14/7) | Pay balance | Amount and due date | Booking detail |
| Message | Chat thread | Scroll to last unread | Inbox |
| Offer or price drop (saved venue) | Venue detail | Offer banner, Brief date applied | Saved |
| New venue (matches Brief) | Venue detail | none | Discover |
| Last-minute deal | Venue detail, date preset | none | Discover |
| Countdown milestone (365/180/30/7/1/0) | My Wedding home | Hero milestone state | none |
| Review request (T+1) | Review composer | Prefilled venue | Profile |
| Planner meeting reminder | Chat thread, meeting card | Add-to-calendar | none |

**Universal links** (shared from WhatsApp): `/v/{venue}?date=&guests=` opens Venue detail with that context applied as a guest. `/compare?ids=a,b,c` opens the comparison. `/b/{booking}` opens Booking detail. Gated routes go through the auth sheet and then resume. A dead link shows "This venue is no longer listed", with similar venues.

**Notification budget.** Transactional (booking, payment, message): always on. Reminders: on, with quiet hours. Marketing (offers, price drops, new venues): opt-in, default quiet hours 22:00 to 09:00, max 2 per week, and none in the final 7 days before the wedding. OS permission is requested after the first save or first booking request, never at launch. Channels: Push; WhatsApp and Email for marketing only (OTP over WhatsApp is separate).

### 5.5 Hotel app IA

**Tab bar (UX-D2).** Today · Bookings · Calendar · Messages · More (Arabic: اليوم · الحجوزات · التقويم · الرسائل · المزيد).

| Tab | Contains | Badge |
|---|---|---|
| **Today** | "Needs you" block, quick actions (Block a date, New offer), today's events, money, availability strip, messages preview, bell | none |
| **Bookings** | List (Pending, Upcoming, Past), search, booking detail with Accept, Decline, Reschedule, Call, Chat, Invoice | **pending count** (cap 9+) |
| **Calendar** | Month, Week, Day. Blocked and open dates. Date sheet. Block and unblock | none |
| **Messages** | Inbox with filters, threads | unread count |
| **More** | My venue (7.4), Grow (Offers, Analytics, Reviews), Notifications, Business (Staff, Bank info, Business hours, Languages), Account, Support | dot for setup or account issues only |

**More, grouped to at most two levels.**
- **My venue:** Photos and videos, Packages and prices, Capacity and spaces, Amenities, Policies, Booking rules, Preview as couples see it.
- **Grow:** Offers, Analytics (including Revenue detail), Reviews.
- **Inbox:** Notifications.
- **Business:** Staff, Bank info, Business hours, Languages.
- **Account:** Biometric lock, Support, Switch venue (only if the account has more than one), Log out.

**The persistent pending indicator (UX-D12, tightening brief 5).**
- The Bookings tab badge shows the count and turns danger-tinted when any request has less than 2 hours left (always with text).
- The Bookings tab opens on **Pending** when count > 0, otherwise Upcoming.
- A foreground arrival shows a non-modal top banner (6s, "Review"), a badge scale-in and a light haptic.
- The tab bar stays visible on pushed screens (except the chat composer and full-screen flows) so the indicator is always 1 tap away.
- Today's top "Needs you" block shows the same queue. The first screen is the inbox.
- Expired requests move to Past > Cancelled (expired) labelled "Missed". They are never dropped silently.

**"Needs you" ranking.** Sort by nearest deadline. Types: (1) pending requests (SLA), (2) unanswered messages older than 30 minutes, (3) balances overdue or at risk (event within 14 days), (4) reviews awaiting a reply (older than 7 days). Empty state is a deliberate "All clear".

**Today section order by role (content adapts, nav does not).**
- GM and Manager: Needs you, Today's events, Money, Opportunity (soft dates), Messages.
- Reception: Needs you, Today's events, Messages.
- Accountant: Money, Payments due, Today's events.
- Marketing: Offers, Analytics glance, Needs you.

**Role matrix [Derived from PRD 8.7; the web dashboard owns the final matrix].**

| Surface | Owner/GM | Manager | Reception | Accountant | Marketing |
|---|---|---|---|---|---|
| Today (full) | yes | yes | limited | money-first | limited |
| Accept / Decline / Reschedule | yes | yes | yes | no | no |
| Block dates | yes | yes | yes | no | no |
| Messages | yes | yes | yes | read-only | no |
| Offers | yes | yes | no | no | yes |
| Analytics and Revenue | yes | yes | no | revenue only | analytics only |
| Venue management | yes | yes | no | no | media only |
| Staff and Bank info | owner only | no | no | bank view | no |

Hide, do not lock-icon. A deep link to a forbidden object shows "You don't have access. Ask your manager."

**Account-status screens [Derived from Super Admin 9.2]:** invited-not-accepted, pending venue approval ("Under review"), suspended ("Contact Ghazal Support"), deactivated.

**Hotel tap-depth.**

| Task | Taps |
|---|---|
| Morning glance | 0 |
| **Accept a request** | 2 from a push or Needs-you row (open, Accept). Undo toast 8s. |
| **Decline** | 3 (open, Decline, reason). Reasons feed the client's alternatives. |
| **Block a date** | 3 (Calendar, date, Block with the default reason) or Today quick action then date then Block |
| Publish a flash offer | 3 to 4 with the "Quick flash" preset (New offer, dates, Publish) |
| Answer a chat | 3 (Messages, thread, send) |
| Review revenue | 1 (Today money card) |
| Analytics | 2 (More, Analytics) |
| Edit a package price | 4 (More, My venue, Packages, package) |
| Invite staff | 4 (More, Staff, Invite, role) |

### 5.6 Hotel deep links and notification landings

| Trigger | Lands on | Behaviour | Fallback |
|---|---|---|---|
| **New booking request** | Booking detail (Pending) | Accept / Decline sticky bar, SLA visible | If expired: detail with "Missed" |
| SLA warning (50% and 90%) | Booking detail | same | same |
| Booking cancelled by client | Booking detail (Cancelled) + "Date is free again. Create an offer?" CTA | none | Bookings > Past |
| Payment received | Booking detail > Payments | deposit or balance highlighted | Revenue detail |
| Balance overdue | Booking detail | "Nudge client" quick reply | none |
| New review | Review detail with Reply | none | Reviews list |
| New message | Chat thread | context bar with booking | Inbox |
| Offer ending soon or ended | Offer detail | Renew / Duplicate | Offers list |
| Account status change | Account-status screen | none | none |

### 5.7 Canonical home per object

| Object | Client canonical screen | Hotel canonical screen |
|---|---|---|
| Venue | Venue detail (C3.1) | My venue hub (H7.1); "Preview as couples see it" opens C3.1 |
| Booking | Booking detail (C6.2) | Booking detail (H3.2) |
| Conversation | Chat thread (C11.2) | Chat thread (H5.2) |
| Offer | Venue detail banner and Booking review | Offer detail (H6.3) |
| Review | Reviews list (C3.7) | Review detail (H8.3) |
| Payment | Payments history and Receipt (C6.6, C5.10) | Booking detail > Payments, Revenue detail (H2.4) |

---

## 6. Screen inventory

### 6.1 Legend
- **States.** D default · L loading (skeleton) · E empty (first use) · F no results (filtered) · X error with retry · O offline · S success or confirmation · G guest-gated · P no permission (role).
- Special states are named in the cell.
- **Priority.** P0 = demo spine, full fidelity and wired. P1 = full fidelity. P2 = design-system standard, may reuse patterns.
- **PRD column** uses section numbers (until `docs/product/feature-matrix.md` assigns IDs).
- (sheet) marks a bottom sheet, not a stacked screen.

### 6.2 Client app (about 60 surfaces)

**Flow 1 · Launch, onboarding, auth (6.1, 6.2)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C1.1 | Splash and language pick | 6.2 | D · O (bundled) | P0 | First-ever screen. Device locale preselected. Both scripts shown. No flags. |
| C1.2 | Intro (3 slides) | 6.2 | D | P1 | One promise each: Compare, Live availability, Plan everything. Skippable. |
| C1.3 | Wedding Brief steps (role, date, guests, area, budget) | 6.2 | D · E (all skippable) · X (location denied) · O · S | P0 | Date offers "Not decided" and "Flexible month". Guests via presets (100, 250, 400, 600, 800+) plus stepper. Budget = **total wedding budget** (venue share suggested at a default 40%, editable (assume)). Bride/Groom profile is deferred to C13.3, with only a "Who's planning?" chip here. |
| C1.4 | Auth entry (sheet) | 6.1 | D · L · X (invalid number, number not on WhatsApp) · O · S | P0 | Phone-first ("Continue with WhatsApp"), Apple, Google, "Use email". +965 default, 8-digit validation. |
| C1.5 | WhatsApp OTP | 6.1 | D · L · X (wrong or expired code) · cooldown · O · S | P0 | Auto-read, 30s resend cooldown. |
| C1.6 | Name and consent (new accounts) | 6.1 | D · X · S | P1 | Single field, email optional. |
| C1.7 | Email sign-in and sign-up | 6.1 | D · L · X · O · S | P2 | Tertiary path. |
| C1.8 | Forgot password (request, sent, reset) | 6.1 | D · L · X · O · S | P2 | Three states of one flow. |
| C1.9 | Biometric (pre-prompt sheet and unlock screen) | 6.1 | D · X (fail then fallback) · unavailable | P1 | Optional app lock. |
| C1.10 | Guest gate (reusable sheet) | 6.1 | D · S (resume) | P0 | Context line ("to send your request"). |

**Flow 2 · Discover (6.3, 6.4, 6.5)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C2.1 | Home | 6.3 | D · L (per shelf) · E (no match for Brief) · X (per shelf) · O (cached) · G | P0 | Brief card (hero search), status card, 6 category chips, then shelves. With a date set, lead shelf is **"Free on {date}"**. "Featured" is the one large hero card and is labelled "Featured/مميز". "Available this week" and "Last-minute deals" are one shelf with a "This week" chip (flag). Order: Brief, status, categories, Free on your date, Featured, Offers, Recommended, Trending, Nearby, Last-minute. Shelves load independently (2s NFR). |
| C2.2 | Brief sheet (date, area, budget, guests) | 6.3 | D · X · O | P0 | Same component as onboarding and Wedding info. |
| C2.3 | Search (typeahead, recents, popular areas) | 6.4 | D · E (no recents) · L · F · O | P1 | Venue-name search lives here. The hero is the Brief, not a text box. |
| C2.4 | Results, list | 6.4, 6.5 | D · L · F · X · O | P0 | Essentials as chips (date, guests, area, audience, price). Live count. |
| C2.5 | Results, map | 6.4 | D · L · F · X · O · location denied | P1 | Price-label pins and a card carousel. |
| C2.6 | Filters (sheet) | 6.4 | D · L (live count) · F (0) · X | P0 | See the filter map below. CTA reads "Show 23 venues". |
| C2.7 | Venue card (component) | 6.5 | D · saved · in-compare · unavailable-on-date · instant · offer · L · no-photo | P0 | Three densities: hero, rail, list. See card rules below. |

Filter map in C2.6 (all [PRD] 6.4 items): *Essentials* Area (location), Price, Capacity, Audience (women only / men only / mixed), Availability (on date). *Setting:* indoor, outdoor, mixed. *Facilities:* parking, valet, bridal room, buffet included, decoration included, photography allowed. *Booking:* instant booking. *Quality:* rating, luxury level, hotel brand. *Sort (separate menu):* recommended, price, rating, newest, nearest.

Venue card rules: photo carousel (3 to 5 photos) with a video badge and **no autoplay in lists**. Rating and count, area, capacity (for the chosen space), availability badge for the Brief date, heart and Compare toggles. The price is date-aware. **No filled "Book" button on every card.** A quiet "Book" or "Request" text action appears only on cards available on the user's date, and it jumps into step 1 prefilled (resolves "minimal cards" vs the PRD "Book button"). Category chips and "See all" open C2.4 with a preset. They are not screens.

**Flow 3 · Venue (6.6, 6.16 reviews)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C3.1 | Venue detail | 6.6 | D · L · X · O (cached, CTA disabled) · date-unavailable · delisted · offer-active · G | P0 | Section order: 1 Gallery hero + title block (name, area, rating and count, audience, instant and offer badges). 2 "Your date" strip with availability and price estimate (sticky on scroll). 3 Spaces (if >1). 4 Packages. 5 About. 6 Facilities in a **3-state model: Included / Extra cost / Not offered** (bridal room, groom room, decoration, buffet, lighting, stage, music, parking, valet). 7 Availability (inline month). 8 Rules and policies as accordions, with the cancellation summary always visible (cancellation, children, dress code, photography, working hours). 9 Location (map, distance, Open in Maps/Waze). 10 Reviews with owner replies. 11 FAQ. 12 Similar venues (prefer free on the same date). Sticky bar: price and one CTA ("Choose a date" / "Request booking" / "Book now" / "See free dates"). 360° tour: **no placeholder UI** (PRD says future). |
| C3.2 | Gallery viewer | 6.6 | D · L · X · O | P0 | Shared-element from card or hero. Category tabs (Hall, Entrance, Food, Bridal room, Outdoors). Video inline. |
| C3.3 | Availability calendar (sheet) | 6.6 | D · L · X · O (stale timestamp) · no-availability-this-month | P0 | Per-date state and per-date price tier. Session marks if multi-session. Selecting a date updates the sticky CTA. |
| C3.4 | Package detail (sheet) | 6.6 | D · L | P1 | Inclusions, menu, per-guest rate, min and max guests. **Do not reuse the names Silver/Gold/Royal** (reserved for planner packages). |
| C3.5 | Venue map (push) | 6.6 | D · X · O · permission | P2 | Open in Google Maps or Waze. |
| C3.6 | Reviews list | 6.16 | D · L · E · X · O | P1 | Filter (with photos, rating), owner replies inline. |
| C3.7 | Write review | 6.16 | D · L (upload) · X · O · S · ineligible | P1 | Only for Completed bookings. Photos of hall, décor and food only, with a "no identifiable faces" notice, moderated. |

**Flow 4 · Compare (6.7)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C4.1 | Compare tray (component) | 6.7 | hidden · 1 (add one more) · 2 to 3 (ready) · collapsed pill · full | P0 | Rules in 5.2. |
| C4.2 | Comparison table | 6.7 | D · L · E (0 venues) · single-venue · X · O (cached) · column-unlisted · no-date | P0 | Sticky header row with photo and name. **Label above value** rows so 3 columns fit 390pt. Rows: Price for my date, Capacity (fit for my guests), Area and distance, Rating, Availability on {date}, Included (buffet, parking, decoration) as icon plus text, Packages (count, from-price, expand), Photos (3-thumb strip). **Differences only** toggle. "Best fit" marker (price: lowest; capacity: closest to my guests). Final "decide" row has three equal-weight Request buttons. Distance is computed from the Brief area by default. Live location only if granted. Share (link or image). |
| C4.3 | Replace-venue (sheet) | 6.7 | D | P1 | On the 4th add. |

**Flow 5 · Booking (6.8, 6.9)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C5.1 | **Your event**: date, session, space, guests, occasion | 6.8 | D · L (price) · X · O · conflict ("date just taken") | P0 | Prefilled from the Brief. Only unanswered fields expand. Session and space appear only when the venue has more than one. |
| C5.2 | Package | 6.8 | D · L · X · O | P0 | Price for date and guests. One choice. |
| C5.3 | Extras | 6.8 | D · E (none offered, skip) · L · X | P1 | Quantity steppers. Running total. "No extras". |
| C5.4 | Sign-in interlude (guest) | 6.1 | = C1.10 | P0 | Between steps 3 and 4. |
| C5.5 | Your details: contact, "Booking for: myself / someone else", special requests (+ Civil ID for government halls) | 6.8 | D · X (validation) · O | P0 | Prefilled. Merges Personal info and Special requests. |
| C5.6 | Review and confirm | 6.8 | D · L (coupon) · X · O | P0 | Itemised breakdown, deposit and balance schedule, **cancellation terms in one line**, coupon field. CTA: "Send request" (Request mode) or "Pay deposit {amount}" (Instant). |
| C5.7 | Payment | 6.9 | D · L · X (declined, cancelled, timeout) · O · hold-expired | P0 | Order: KNET, Apple Pay (iOS) or Google Pay (Android), Visa/Mastercard, Cash at venue (only when allowed). Deposit vs Full toggle (default deposit). **No "Installments (soon)" row.** Checkout hold timer (Instant). |
| C5.8 | Gateway handoff and verification | 6.9 | redirecting · verifying · S · X · delayed-unknown | P0 | "Checking your payment". If unconfirmed after about 30s: "We're confirming. You can leave. We'll notify you." |
| C5.9 | Outcome: Confirmed / Request sent | 6.8 | S (confirmed) · S (pending) · X | P0 | Confirmed: summary, add to calendar, receipt, share. Pending: timeline, response promise, Message venue. Planner offer appears once here (see C7.1). |
| C5.10 | Invoice and receipt viewer | 6.8 | D · L · X · O (downloaded) | P1 | Reused from Booking detail. |
| C5.11 | Exit-flow confirm (sheet) | n/a | D | P2 | Draft is saved. |

**Flow 6 · Bookings and payments (6.10, 6.16)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C6.1 | Bookings list (inside My Wedding) | 6.10 | D · L · E · X · O · G | P0 | Upcoming and Past. Occasion labels. |
| C6.2 | **Booking detail** (all statuses) | 6.10 | Pending · Approved-awaiting-deposit · Deposit-verifying · Confirmed · Reschedule-proposed · Rejected · Cancelled (me / venue / expired) · Refund-processing · Refunded · Completed · L · X · O | P0 | The Booking Thread timeline. Venue summary, event details, package and extras, breakdown and schedule, policy recap. Actions per status: Pay deposit, Pay balance, Message, Call, Add to calendar, Directions, Invoice, Cancel, Review. **One screen, many variants. Not six screens.** |
| C6.3 | Cancel booking (sheet flow) | 6.10 | D · L · X · S · not-refundable | P1 | Reason chips, refund preview per policy, confirm. |
| C6.4 | Venue-proposed reschedule response (sheet) | Derived | D · X · S | P1 | Accept / Decline / Chat. Shows price delta. |
| C6.5 | Payments history | 6.16 | D · L · E · X · O | P1 | Deposit, balance, refund rows with receipts. |

**Flow 7 · Wedding planner (6.11)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C7.1 | Planner offer ("Need a wedding planner?") | 6.11 | D | P1 | Card on C5.9 and in My Wedding. Shown once, then only in My Wedding. |
| C7.2 | Planner packages (Silver / Gold / Royal) | 6.11 | D · L · X · O | P1 | Vertical comparison of the three. No fabricated "most popular". |
| C7.3 | Request consultation | 6.11 | D · X · S · G | P1 | Preferred package, time windows, note. |
| C7.4 | Planner chat and meeting scheduler | 6.11, 6.14 | = C11.2 + meeting card | P1 | "Schedule meeting" is a sheet inside chat. After assignment, a "Your planner" card shows in My Wedding and in the chat header. **No planner directory or profile.** Assignment is by admin (9.8). |

**Flow 8 · Services (6.12)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C8.1 | Services hub | 6.12 | D · L · X · O | P1 | Sixteen services grouped in five clusters: Capture (photography, videography), Look (bridal makeup, henna, wedding dress, suit rental), Sound and show (DJ, MC, live music), Table and décor (flowers, cake, invitations), Move and stay (luxury cars, hotels, travel, honeymoon). |
| C8.2 | Category list | 6.12 | D · L · E · F · X · O | P2 | Area, price, rating filters. |
| C8.3 | Vendor profile | 6.12 | D · L · X · O | P2 | Portfolio (no faces), packages, from-price, reviews. CTAs: Request quote, Save, Add to budget. |
| C8.4 | Request quote (sheet) | 6.12, 6.14 | D · X · S · G | P2 | Creates a vendor chat with a structured request card. |

**Flow 9 · My Wedding (6.13)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C9.1 | **My Wedding home** | 6.13 | D · L · E (no date) · X · O · G (teaser) · phase variants: pre-venue / booked / wedding-week / **day-of** / post | P0 | Order: Countdown hero (days, date, venue; milestones 365/180/30/7/1/0 are hero states), **Next up (max 3, due first)**, Booking card(s), Planner card (offer or assigned), Tools row (Checklist %, Budget remaining, Saved, Services), Wedding-info prompt. Day-of: hero becomes Directions, Call venue, Message planner. When a booking is Confirmed, offer to set the wedding date to the booking date. |
| C9.2 | Checklist | 6.13 | D · L · E · X · O · complete | P1 | Eight PRD categories. Static template schedule relative to the wedding date (rules-based, not AI). Items deep-link into Services. "Venue" auto-completes on Confirmed. Custom items. |
| C9.3 | Budget | 6.13 | D · L · E (no budget) · X · O · over-budget | P1 | **Committed vs paid vs remaining.** Venue bookings flow in automatically. Alerts at 80% and 100%. |
| C9.4 | Add expense / edit budget / checklist item (sheets) | 6.13 | D · X | P2 | Sheets. |

**Flow 10 · Saved (6.13 wishlist)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C10.1 | Saved: Venues / Services / Packages | 6.13 | D · L · E (each segment) · X · O · G (local items, "Sign in to keep") | P0 | Live availability on the Brief date ("Still free on 25 Mar"). Price-drop badge. Multi-select to Compare (n/3). Sorted by availability. |

**Flow 11 · Chat (6.14)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C11.1 | Messages inbox | 6.14 | D · L · E · X · O · G | P0 | Chips: All, Venues, Planner, Vendors, Support. Context line (booking or date). Support pinned. |
| C11.2 | Chat thread (venue, planner, vendor, support) | 6.14 | D · L · E (suggestion chips) · X · O (queued) · sending / failed / read · uploading · recording | P0 | Text, media, documents, **voice** (hold to record, slide to cancel, lock). System messages for booking events. Structured cards (booking summary, meeting, quote request). Quick chips ("Request a visit", "Ask about availability"). |
| C11.3 | Media and document viewer | 6.14 | D · L · X · O | P2 | Reuses the gallery viewer. |

**Flow 12 · Notifications (6.15)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C12.1 | Notification center | 6.15 | D · L · E · X · O · G | P1 | Grouped by day. Tap lands per 5.4. |
| C12.2 | Notification preferences and OS pre-prompt | 6.15 | D · denied · S | P2 | Categories, quiet hours, channels. |

**Flow 13 · Profile and account (6.16)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| C13.1 | Profile hub | 6.16 | D · G | P1 | Rows: Wedding info, Bookings (link), Payments (link), Saved (link), Rewards, Notifications, Language, Settings, Support, Log out. Guest view: Sign in, Language, legal only. |
| C13.2 | Personal info | 6.16 | D · X · S | P2 | Verified phone, name, email. |
| C13.3 | Wedding info (bride and groom profile) | 6.16, 6.2 | D · X · S · date-differs-from-booking | P1 | Same form as the Brief plus names. Monogram avatars only. |
| C13.4 | Rewards: points, coupons, referral | 6.16 | D · L · E · X · O | P2 | Coupon applies in C5.6. Referral shares via WhatsApp. |
| C13.5 | Language and region | 6.2, 6.16 | D | P1 | Language, digits (Western/Eastern), Hijri secondary dates. Shared with C1.1. |
| C13.6 | Settings | 6.16 | D | P2 | Biometrics, permissions, version. |
| C13.7 | **Delete account** | 6.16, NFR | D · blocked (active booking) · L · X · S | P1 | In-app. Consequences listed. Re-auth by OTP. If blocked, offer "Request deletion after {date}" and Support. Never a dead end. |
| C13.8 | Legal pages | n/a | D · L · X · O | P2 | Terms and privacy supplied by the owner. |

**Flow 14 · System**

| ID | Surface | States | Pri |
|---|---|---|---|
| C14.1 | Offline banner pattern | persistent, stale timestamp | P1 |
| C14.2 | Full-screen error, maintenance, force-update | D | P2 |
| C14.3 | Dead deep link ("no longer listed") | D | P2 |
| C14.4 | Permission pre-prompts (notifications, location, mic/camera/photos) | D · denied | P2 |

### 6.3 Hotel app (about 42 surfaces)

**Flow 1 · Access**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H1.1 | Language and sign-in (WhatsApp OTP for invited staff) | Derived | D · L · X (wrong code, not invited) · O · locked | P0 | Auth method is an open question. |
| H1.2 | OTP verify | Derived | D · L · X · cooldown · S | P0 | Same component as C1.5. |
| H1.3 | First-run: notifications and biometric (sheets) | Derived | D · denied | P2 | Biometric offered by default on (revenue and bank data). |
| H1.4 | Venue switcher (only if more than one venue) | Proposal | D | P2 | Header slot reserved. |
| H1.5 | Account-status screens: Under review / Suspended / Deactivated / Invited | Derived (9.2) | D | P1 | Needed because Super Admin can suspend or approve venues. |

**Flow 2 · Today (7.1, 7.7)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H2.1 | **Today** | 7.1 | D · L · E (**All clear**) · X · O (stale "as of 09:12") · P (role-limited) · overdue | P0 | Order in 5.5. Quick actions: **Block a date**, **New offer**. Money card taps to Revenue detail. Availability strip for 14 days plus "N open weekend dates in 60 days", which opens Calendar in soft-date mode. |
| H2.2 | Notification center | 7.7 | D · L · E · X · O | P1 | New booking, cancelled booking, payment received, new reviews. Lands per 5.6. |
| H2.3 | Notification settings | 7.7, 7.8 | D · denied | P2 | Per type. New booking alert sound is distinct. |
| H2.4 | Revenue detail (ledger) | 7.1, 7.6 | D · L · E · X · O · P | P1 | Collected vs expected, month selector, ledger (deposit, balance, refund) with booking links. Export is web only. |

**Flow 3 · Bookings (7.2)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H3.1 | Bookings list | 7.2 | D · L · E (per tab) · F (search) · X · O | P0 | Tabs: Pending (SLA bar), Upcoming, Past. Search by name, reference or date. Row: client, date, session, space, guests, package, amount, deposit state. |
| H3.2 | **Booking detail** | 7.2 | Pending · Pending-overdue · Awaiting-deposit · Confirmed · Reschedule-proposed · Rejected · Cancelled (client / expired) · Completed · Refunded · L · X · O · conflict | P0 | Special requests prominent. Client card (name, phone, "Booking for"), event, package and extras, price, payments, audit trail (who accepted). Sticky bar: Accept (primary) and Decline. Secondary: Reschedule. Icon row: Call, Chat, Invoice. |
| H3.3 | Accept (inline, with Undo toast) | 7.2 | D · L · X (date taken) · S | P0 | 8s Undo. Client notification is deferred by the same 8s. Confirmation sheet only when overriding windows. |
| H3.4 | Decline (sheet) | 7.2 | D · X · S | P0 | Reason chips (date no longer available, capacity, budget mismatch, other) plus note. A fork: "Propose another date" (becomes Reschedule). |
| H3.5 | Reschedule (sheet) | 7.2 | D · L · X · S · no-open-dates | P1 | Pick from open dates only. Shows price delta. |
| H3.6 | Contact sheet (Call / WhatsApp / Chat) | 7.2 | D | P0 | WhatsApp row [Proposal]. Phone visible only for active bookings. |
| H3.7 | Record payment received (cash or transfer) | Derived (6.9) | D · X · S | P2 | Needed for the cash variant. |
| H3.8 | Invoice view and send | 7.2 | D · L · X · O | P1 | Shared document with the client app. |

**Flow 4 · Calendar (7.3)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H4.1 | **Calendar**: Month / Week / Day | 7.3 | D · L · E (open month) · X · O (read-only) | P0 | Month shows Booked, Pending, Blocked (hatch pattern, not colour only), Open. Space filter only if more than one. Fri and Sat marks. Optional Hijri line. **Soft-date mode** (opens from Today) highlights unsold dates. |
| H4.2 | Date detail (sheet) | 7.3 | D | P0 | Bookings that day, Block/Unblock, Create offer for this date. |
| H4.3 | **Block / unblock** (sheet) | 7.3 | D · X (conflict: booking exists) · S (Undo) · O (disabled with reason) · partial-fail | P0 | Single date or range (long-press and drag). Space and session scope. Reason chips: Booked offline, Maintenance, Private event, Other. Ramadan and Eid range shortcuts [Proposal]. Feedback: "Hidden from couples now". |

**Flow 5 · Messages (7.1, 7.2)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H5.1 | Inbox | 7.1 | D · L · E · X · O | P0 | Filters: Unread, Needs reply, Booking-linked, Enquiries. |
| H5.2 | Chat thread | 7.2 | D · L · E · X · O · sending / failed | P0 | **Booking context bar** pinned (date, status, and Accept / Decline if Pending). Voice, media, documents. |
| H5.3 | Quick replies (sheet) | Proposal | D | P2 | Defaults bilingual: availability, price, visit invite, payment reminder, address. |

**Flow 6 · Offers (7.5)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H6.1 | Offers list | 7.5 | D · L · E (**with soft-date insight and CTA**) · X · O · P | P1 | Active, Scheduled, Ended. |
| H6.2 | **Create offer** (type-adaptive stepper) | 7.5 | D · validation · X · S · P | P0 | One flow for Flash sale, Discount and Coupon. Steps: type, what (percent or fixed KWD, packages, spaces), when (event dates and offer window; flash = 6/12/24/48h), limits (uses, coupon code), **live preview of the client card**, Publish. "Quick flash" preset (for example 15% for 24h). |
| H6.3 | Offer detail and performance | 7.5 | D · L · X · O | P2 | Views, claims, bookings. Pause, end, duplicate. |

**Flow 7 · My venue (7.4)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H7.1 | My venue hub | 7.4 | D · L · X · O · under-review | P1 | Listing status and sections. |
| H7.2 | Media manager (photos and videos) | 7.4 | D · E · uploading · X · O (queued) · S | P1 | Reorder, cover, categories. Camera and library upload. |
| H7.3 | Packages list and editor | 7.4 | D · E · validation · X · S · unsaved-guard · P | P1 | Base weekday and weekend price. Inclusions, per-guest rate, min and max, active toggle. Seasonal pricing and menus show "Edit on dashboard". |
| H7.4 | Capacity and spaces | 7.4 | D · validation · S · P | P2 | Audience, setting, capacity per space. |
| H7.5 | Amenities and facilities | 7.4 | D · S | P2 | Three-state toggles (Included / Extra / Not offered). |
| H7.6 | Policies | 7.4 | D · S | P2 | Cancellation tiers, children, dress code, photography. |
| H7.7 | Booking rules | 7.4 (availability), Derived | D · S · warnings | P1 | Instant vs Request, response window, payment window, deposit %, balance due, lead time. |
| H7.8 | Preview as couples see it | 7.4 | D | P2 | Opens C3.1 in preview mode. |

**Flow 8 · Analytics and reviews (7.6, 7.7)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H8.1 | Analytics overview | 7.6 | D · L · E (new venue) · insufficient-data · X · O · P | P1 | Period selector. KPIs: Views, Clicks, Bookings, Revenue, Conversion. One funnel (views, clicks, requests, confirmed). Top packages inline. Metric tap opens a drill-down. |
| H8.2 | Reviews list and detail with reply | 7.7, 6.16 | D · L · E · X · O · S (reply posted) · reported | P1 | Derived: the "new review" notification needs a landing. Reply is the minimum. Approve is not built (see gap). |

**Flow 9 · Settings (7.8)**

| ID | Screen | PRD | States | Pri | Notes |
|---|---|---|---|---|---|
| H9.1 | Account and settings hub | 7.8 | D | P1 | Biometric lock, support, log out. |
| H9.2 | Staff list | 7.8 | D · L · E (only you) · X · O · P | P1 | Roles: Reception, Manager, Accountant, Marketing. |
| H9.3 | Invite and edit staff | 7.8 | D · X · S · invite-pending / expired | P1 | Invite by WhatsApp number. |
| H9.4 | **Bank info** | 7.8 | D · E (not set) · verifying · verified · rejected · X · O (view) · P | P1 | Kuwait IBAN (30 characters, KW), bank, account name. Masked by default. Re-auth to view or edit. Changes notify the owner. |
| H9.5 | Business hours | 7.8 | D · S · X | P2 | Feeds the client "Working hours". Includes closures. |
| H9.6 | Languages | 7.8 | D | P2 | Per-user UI language. Venue content is always AR and EN. |

**Flow 10 · System:** offline banner, error, maintenance and force update, no-permission, dead deep link, account suspended (see H1.5).

### 6.4 Things that should NOT get their own screen

**Client**
- **Countdown** (hero states in C9.1 plus notifications).
- Quick categories and shelf "See all" (presets of C2.4).
- Separate Sign up and Login (one entry).
- Biometric set-up (system prompt plus a sheet).
- Schedule meeting (sheet in chat).
- Package detail (sheet). FAQ (accordion). Policies (accordions). Similar venues (rail).
- Venue card, Compare tray, voice recorder, Share (OS sheet).
- Separate Date and Time steps (merged). Separate Personal info and Special requests (merged).
- 360° tour placeholder (no UI until it ships). Installments (no UI). "AI" recommendations (rules-based shelf, no AI label or chat).
- Separate screens per booking status (variants of C6.2).
- Services booking checkout (enquire only).
- Planner directory or profile (assignment by admin).
- Loyalty "points history" (inside Rewards).

**Hotel**
- Dashboard "Availability" (a strip). "Top packages" (a section). "Call client" (action sheet).
- Accept and Decline as separate screens (inline action and sheet).
- Venue management > Offers (link to Offers) and Venue management > Availability (links to Calendar and Booking rules).
- Notification-type screens (each lands on its object).
- Venue-initiated cancellation of a Confirmed booking (route to Support).
- Customer management, VIP and blacklist, pricing engine (season and holiday), menus, FAQ editing, export, permission matrix, refund processing (web only).
- Quick-reply management (defaults only in MVP).

### 6.5 PRD coverage check

**Client (6.1 to 6.16).** 6.1 → C1.4 to C1.10. 6.2 → C1.1 to C1.3, C13.3, C13.5. 6.3 → C2.1, C2.2. 6.4 → C2.3 to C2.6. 6.5 → C2.7. 6.6 → C3.1 to C3.5. 6.7 → C4.1 to C4.3. 6.8 → C5.1 to C5.11. 6.9 → C5.7, C5.8, C6.5. 6.10 → C6.1 to C6.4. 6.11 → C7.1 to C7.4. 6.12 → C8.1 to C8.4. 6.13 → C9.1 to C9.4, C10.1. 6.14 → C11.1 to C11.3. 6.15 → C12.1, C12.2. 6.16 → C3.6, C3.7, C13.1 to C13.8.

**Hotel (7.1 to 7.8).** 7.1 → H2.1, H2.4. 7.2 → H3.1 to H3.8, H5.2. 7.3 → H4.1 to H4.3. 7.4 → H7.1 to H7.8. 7.5 → H6.1 to H6.3. 7.6 → H8.1, H2.4. 7.7 → H2.2, H2.3, H8.2. 7.8 → H9.1 to H9.6.

### 6.6 Prototype scope (demo spine)
- **Client P0 (about 22).** C1.1, C1.3, C1.4, C1.5, C1.10, C2.1, C2.2, C2.4, C2.6, C2.7, C3.1, C3.2, C3.3, C4.1, C4.2, C5.1, C5.2, C5.5, C5.6, C5.7, C5.8, C5.9, C6.1, C6.2 (4 variants: Pending, Awaiting deposit, Confirmed, Rejected), C9.1, C10.1, C11.1, C11.2.
- **Hotel P0 (about 14).** H1.1, H1.2, H2.1, H3.1, H3.2, H3.3, H3.4, H3.6, H4.1, H4.2, H4.3, H5.1, H5.2, H6.2.
- Everything else is built to design-system standard (P1 and P2), reusing sheets, lists, forms and states.
- **Verification.** Each screen is verified in both languages at 360, 390 and 430 widths.

---

## 7. Micro-interactions that make it feel premium
(All use token durations 120 / 200 / 320 / 480 ms, honour reduced motion, flip direction in RTL, and never block input.)

| # | Moment | Behaviour | The question it answers | Reduced-motion and RTL |
|---|---|---|---|---|
| 1 | Brief change | Price and availability on visible cards update in place. Only the changed digits roll (tabular figures), 200ms. | "Did my date change the price?" | Crossfade. Digits from the correct side. |
| 2 | Date select | Cell presses in, sticky CTA price morphs. Unavailable: a 2px nudge twice plus an inline reason. No red flash. | "Is this date OK, and why not?" | Static. Calendar swipe direction flips. |
| 3 | Heart | Fills with gold from the centre (200ms). A ghost heart drifts to the Saved tab (320ms). | "Where did it go?" | Fill only. |
| 4 | Add to Compare | Card thumbnail lifts into the tray (320ms emphasised). Tray count ticks. Collapses to a pill when idle. | "Did it add, and how many?" | Slide only. |
| 5 | Card to gallery | Shared-element expansion. Pinch and swipe dismiss. | "Where am I in the venue?" | Crossfade. |
| 6 | Venue header | Hero condenses as you scroll. The "Your date" strip and price bar stick. No flashing. | "Can I act without scrolling back?" | Static swap. |
| 7 | Booking steps | A thread-line progress fills inline-end. Steps slide in the direction of travel. Back reverses. | "How far, and can I go back safely?" | Fade. Mirrors in RTL. |
| 8 | Checkout hold | A quiet timer. Only the last 60s change to gold-ink. No alarm animation. | "How long is my date held?" | Same. |
| 9 | Payment verify | Determinate-style line while verifying. Success: check draws and the confirmation card rises (480ms), with one success haptic. **No confetti.** | "Did it work, and is it safe to leave?" | Instant check. |
| 10 | Status change | The Booking Thread node advances (320ms). A push landing scrolls to and highlights the changed row for 1.2s. | "What just changed?" | No highlight pulse. |
| 11 | Compare toggle | "Differences only" collapses equal rows (200ms). Column header pins. Best-fit mark appears. | "What actually differs?" | Instant. |
| 12 | Voice note | Hold to record, live waveform, slide toward the inline-start side to cancel, slide up to lock. Haptics at start, cancel and lock. | "Am I recording, and how do I cancel?" | Waveform static. Direction mirrors. |
| 13 | Countdown | Digits settle once per open. At 365/180/30/7/1/0 a single line draws under the number. | "How long is left?" | No draw. |
| 14 | Checklist tick | Check strokes in (160ms). The row settles into "done". The progress bar glides. 100% shows one understated message. | "Did that count?" | Instant. |
| 15 | Budget bar | Segmented bar (paid / committed / remaining) animates in once. Crossing 80% turns the edge gold-ink plus an inline alert. Red only when over budget. | "Where am I against budget?" | Static. |
| 16 | Skeleton to content | Placeholder is the image's own average colour, then blur-up. | "Is it loading, and what is coming?" | Crossfade. |
| 17 | Hotel Accept | Tap Accept, button resolves to "Accepted" and a toast shows "Undo 8s" (a depleting bar). | "Did it work, and can I take it back?" | Static. |
| 18 | SLA bar | A thin bar depletes in real time. Neutral, then gold at 50%, then danger at 90%, always with "2h 10m left". | "How long do I have?" | Stepwise. |
| 19 | Queue cleared | "Needs you" collapses (320ms) to "All clear". | "Am I done?" | Instant. |
| 20 | Block range | Long-press starts range, drag extends with a tick haptic per day, the sheet rises preselected, confirmed cells hatch in (200ms). Undo toast. | "What exactly am I blocking?" | Static hatch. Drag direction mirrors. |
| 21 | New request while open | Badge scale-in, top banner, light haptic. | "Something needs me." | Banner only. |
| 22 | Offer preview | Live client-card preview updates as sliders move. The flash countdown pill ticks. | "How will couples see it?" | Static. |
| 23 | Offline | Quiet persistent banner "Offline · updated 09:12". Network-dependent actions are disabled in place and explain on tap. | "Why can't I?" | Same. |
| 24 | Language switch | Instant, with a crossfade. Route and scroll are preserved. | "Did the app understand me?" | Same. |

**Haptics policy.** Only on commit moments (save, accept, pay success, toggle, range tick). Light.

**Booking Thread (UX-D14).** One timeline component (Requested, Approved, Deposit, Balance, Day) used in Booking detail on both apps. It is also the progress line in the booking flow and the verification indicator. Each node "knots" gold when done. It is used only where it carries state, never as ornament.

---

## 8. Challenging brief section 5 and 6

### 8.1 Section 5 hypotheses

| Hypothesis | Verdict | Replacement or refinement | Reason |
|---|---|---|---|
| Client tabs: Discover · Compare/Planner · Plan · Messages · Profile | **Change** | Discover · **Saved** · **My Wedding** · Messages · Profile | "Planner" collides with "Plan" and with the human planner service (AR المخطط / التخطيط). Compare is a transient task, not a destination. The shortlist is what the family returns to, and wishlist needs a home. |
| Bookings reachable from Plan, Profile and Home status card | **Keep, sharpen** | Canonical: My Wedding > Bookings. Home status card for urgency. Profile row links to the same screen. Notifications land on the object. | Time-critical booking actions need a stable home and a push route. |
| Search first-class on Discover | **Keep, strengthen** | The hero is the **Brief** (date, guests, area, budget), not a text box. Persistent Brief pill on Results. | Weddings are structured queries. A date-aware Brief powers price, availability and compare. |
| Compare as persistent tray (max 3) plus table | **Keep, add rules** | Anti-nag rules, Share, entry from Saved, label-above table, differences-only. | Visible without nagging. WhatsApp families decide collectively. |
| Guest browsing everywhere except booking, payment, chat | **Refine** | Add: reviews, planner consultation, vendor quote, persisting plan data, rewards. Allow local heart and compare. Gate before personal data. | Matches App Review expectations and conversion. Hearts are the hook. |
| Hotel tabs: Today · Bookings · Calendar · Messages · More | **Keep** | Define More's groups. Add Today quick actions and the Needs-you block. Constant nav, role-aware content. | The jobs (glance, decide, block, answer) map 1:1. |
| Pending requests in at most 1 tap via a persistent indicator | **Keep, define** | Bookings tab badge (SLA-aware tint) plus Needs-you block plus foreground banner. Bookings opens on Pending. | A floating chip would collide with the tab bar and content. |

### 8.2 Section 6 open questions (positions)
1. **Request or instant, and where is the deposit charged?** Request by default (approve, then pay inside a window), Instant opt-in. See section 4.
2. **Date and session; halls; men's and women's sections?** Space x date x session with progressive disclosure. See 4.3.
3. **Digits.** Western by default, with a setting and a formatter that switches. See 4.5.
4. **Compare without nagging.** Tray rules in 5.2.
5. **Most memorable idea.** From a UX view it is the shared Booking Thread (certainty as the signature). The visual lens can express the thread and the love-poem meaning, but the functional object is the timeline.

---

## 9. Gaps, conflicts and assumptions found beyond the digest

1. **Planner has no surface.** PRD section 4 lists the planner as a primary user. Sections 6.11 and 9.8 treat planners as Ghazal-assigned supply. No product serves the planner's side of chat, availability or assignment. MVP: planners use a normal client account, one wedding at a time.
2. **Vendor timing conflict.** PDF section 4 says vendor categories arrive after the MVP. Section 14 says the services marketplace is in the MVP. Resolution: browse and enquire only.
3. **Hotel app auth and roles** are unspecified. Inferred: WhatsApp OTP plus owner invites, with roles from 8.7.
4. **No payout or settlement view** for venues in section 7.
5. **Reviews** appear in the hotel app only as a notification. A review detail and reply is derived. "Approve" (8.9) risks venue gate-keeping. Recommend report-abuse only.
6. **Cash needs a hotel-side action** ("Record payment received") that section 7 does not list.
7. **Reschedule has no client counterpart** in section 6. Added: C6.4.
8. **Cancellation and refund mechanics** are undefined beyond status names. Design: client cancels within policy (refund preview), venue or admin processes refunds on the web, the app shows the state.
9. **Coupons have three sources** (loyalty, venue, platform) with no stacking rule.
10. **"Book button" on every card** conflicts with "minimal cards". Resolved in the card rules.
11. **"Available this week" and "Last-minute deals"** overlap. Merged into one shelf with a chip.
12. **"VIP Venues" vs "Luxury Hotels"** need definitions. Categories are CMS presets (Super Admin 9.7). The app renders from data.
13. **"Photography allowed"** is richer than a boolean in women's halls (for example phones, female photographers only). Model as a policy with options (assume).
14. **Budget semantics.** Onboarding "Budget" is the total wedding budget. The search budget filter is venue price.
15. **Guest count** means guests in the chosen space.
16. **Account deletion with active bookings.** Initiate in-app always. Completion may be deferred.
17. **Payer is not the booker.** Parent or groom's family often pays. "Send payment link" is a proposal.
18. **Site visits** happen through chat quick chips ("Request a visit"). No scheduler.
19. **Hijri and Ramadan.** Optional secondary dates. Block shortcuts for Ramadan and Eid are adjustable ranges, not fixed dates.
20. **Government halls** are unspecified (eligibility, tariff, payment).
21. **Market assumptions** (Thu/Fri/Sat peak, KNET behaviour, 24h windows, iOS share, women's-hall photography norms) need a 30-minute validation with two hall owners and one hotel events manager.

---

## 10. Components this IA demands from the design system
Status chip (six statuses plus sub-states, icon plus label) · Booking Thread timeline · Venue card (hero, rail, list) · Price display (compact, exact, date-aware) · Facility row (Included / Extra / Not offered) · Calendar cell (available, limited, unavailable, held, blocked hatch, price tier, session marks) · Date picker (single, range, flexible month, Hijri line) · Guests stepper with presets · Budget range slider (mirrored in RTL) · Compare tray and Compare column · Sticky action bar (price plus CTA) · Bottom sheet (sizes, drag) · Stepper header with thread progress · Toast with Undo · Tab bar with badges · SLA bar · Segmented control · Filter chips · Empty state · Skeleton · Offline banner · Chat bubbles (text, media, document, voice, system, structured card) · Monogram avatar · Rating · KPI tile · Funnel chart · Ledger row · Settings list row · Form fields (phone, OTP, IBAN, Civil ID).

---

## 11. Copy and naming kit (AR / EN; copy agent finalises)
- Guests: المعازيم / Guests (in this hall).
- Hall: قاعة. Venue: قاعة أو فندق / Venue. Ballroom: قاعة الاحتفالات.
- Women only / Men only / Mixed: نسائي / رجالي / مختلط.
- Request / Booking: طلب حجز / حجز.
- Deposit: عربون. Balance: المتبقي.
- Held for you until…: محجوز لك حتى…
- Awaiting your deposit: بانتظار العربون. Confirmed: مؤكد.
- Pending / Approved / Rejected / Cancelled / Completed / Refunded: بانتظار الرد / تمت الموافقة / غير مقبول / ملغي / مكتمل / تم الاسترداد.
- Wedding planner: AR copy to choose between ويدنج بلانر (colloquial, common in Kuwait) and منسّق الزفاف (formal).
- Occasions: ملكة (milka), ليلة الحناء (henna night), حفل الزفاف (wedding night).
- Tabs (client): استكشف · المفضلة · عرسي · الرسائل · حسابي. Tabs (hotel): اليوم · الحجوزات · التقويم · الرسائل · المزيد.
- Tone: no "Welcome back 👋"-style greetings. Warm and precise, never saccharine.

---

## 12. Shared demo storyline (seed both prototypes with one story)
- **Couple.** Noura Al-Mutairi (bride) with fiancé Fahad. Brief: Thu 25 Mar 2027, 650 guests (women's hall), Salmiya or Hawalli, wedding budget about 18,000 KWD (assume).
- **Venues (fictional).** Durra Grand Ballroom (Salmiya, hotel, instant booking off), Nakheel Garden Villa (Mishref, outdoor, instant on), Al Safwa Hall (Shuwaikh, independent hall, single space), Khiran Shore Pavilion (beach), a government hall (fixed tariff, request-only), plus Messila-area venues.
- **Storyline.** Noura compares Durra, Al Safwa and Nakheel, shares the table to the family WhatsApp group, and her mother Hessa opens it as a guest. Noura requests Durra for the Evening session, 650 guests, "Evening Premium" package (not Silver/Gold/Royal), occasion Wedding night. Khalid's coordinator Maryam sees the request in Needs you with 22h left, accepts it (Undo shown), Noura gets "Awaiting your deposit" with a 24h timer, pays KNET, Confirmed. The balance schedule then drives My Wedding. The hotel simultaneously blocks Fri 26 Mar as "Booked offline", then publishes a flash offer for an unsold Tuesday.
- **Rules.** The same booking ID and the same timeline must appear identically in both prototypes. Prices are KWD, with fils where realistic (for example 18.500 per guest). No identifiable faces. Monogram avatars.

---

*End of Product & UX lens.*