# Ghazal — Personas

> Illustrative composites, not real people. Names, dates and amounts match the shared seed story (`docs/design/seed-rulebook.md`, `docs/design/content-guidelines.md`, `docs/product/screens/**`), so a persona here is the same person a reviewer meets in the prototype. NOW = Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait.
> The names in `docs/research/journeys-ia.md` (Noura, Hessa, Khalid Al-Rashidi, Maryam as reception) are superseded: *Maryam Al-Kandari* is a pending client in the seed, so reusing her as staff would break the shared storyline.
> Tags: **[PRD]** stated in the PRD · **[Derived]** needed to complete a PRD flow · **[K]** Kuwait assumption to validate with 5-8 venue managers.

## 1. Cast at a glance

| ID | Persona | App | Role in the decision | UI language | Device [K] | Key screens |
|---|---|---|---|---|---|---|
| C1 | **Reem Al-Dosari** ريم الدوسري (monogram ر), bride | Client | Owns the wedding file | Arabic | iPhone 13-15, Face ID | `CL-DISC-01`, `CL-BOOK-01..06`, `CL-BKNG-02`, `CL-PAYM-01..05`, `CL-WEDD-01` |
| C2 | **Umm Reem** أم ريم, mother of the bride | Client (mostly as a guest) | Holds the veto; sometimes pays | Arabic only | Mid-range Android, text 130-200% | `CL-SAVD-04`, `CL-VENU-01`, `CL-VENU-05` |
| C3 | **Fahad Al-Shammari** فهد الشمري, groom | Client (guest or second account) | Owns the men's reception; signs off budget | Arabic or English | iPhone | `CL-BOOK-01` ("Both"), `CL-WEDD-03` |
| C4 | **Rima Haddad** ريما حداد, independent planner | Client | Shortlists for several clients | English | iPhone + iPad | `CL-SAVD-04`, `CL-BOOK-04` ("Booking for") |
| H1 | **Hind Al-Enezi** هند العنزي, Manager, Aurelia Gulf Hotel (V01) | Hotel | The prototype's demo user: decides and responds | Arabic (staff are mixed) | iPhone | `HL-TODY-01`, `HL-BOOK-03`, `HL-DCSN-01..03`, `HL-CALN-04` |
| H2 | **Amal Al-Balushi** أمل البلوشي, Reception | Hotel | Front line: requests, calendar, messages | Per user | iPhone or Android | `HL-BOOK-01`, `HL-TODY-04..05`, `HL-DCSN-05` |
| H3 | **Mahmoud Saleh** محمود صالح, Accountant (part-time) | Hotel | Reconciles money | English | Android | `HL-GROW-05`, `HL-BOOK-05`, `HL-SETT-04` (masked) |
| H4 | **Khalid Al-Otaibi** خالد العتيبي, Admin (owner) | Hotel | Protects prime dates; owns staff and bank | Arabic and English | iPhone Pro | `HL-TODY-01`, `HL-SETT-03`, `HL-SETT-04` |
| H5 | **Sara Al-Qattan** سارة القطان, Marketing (invite pending, expires Sat 14 Nov) | Hotel | Offers and analytics | English | iPhone | `HL-GROW-01..04` |

The user is Reem, the **decider** is Umm Reem, the **payer** may be Fahad's family, and the **power user** is Rima. Share, Saved and Compare have to work for people who never sign up.

## 2. Client personas

### C1 · Reem Al-Dosari ريم الدوسري — the bride who owns the file

| | |
|---|---|
| Snapshot | 27, engaged to Fahad Al-Shammari. Wedding **Thu 14 Jan 2027, 63 days away**: a compressed timeline, so date availability is the whole game. Venue-and-catering budget band KD 20,000-35,000; ladies about 350 guests, men about 400; prefers **Salmiya and Sharq**. |
| Context of use | Researches 9 pm to 1 am on the sofa, in 8-12 minute sessions, with her mother and sisters watching or on a WhatsApp group. One-handed. Voice notes. Apple Pay and KNET. |
| Jobs to be done | *When we shortlist halls with the family, show which are free on 14 January and what they really cost for 350 guests, so we stop chasing eight WhatsApp chats.* · *When a venue says yes, let me lock the date before another couple takes it.* · *Keep every booking, payment and to-do in one place.* |
| Anxieties | Losing the date. Hidden per-guest charges and extras. "Instagram lies" (photos versus reality). Losing a deposit. Her mother's reaction. Being left on "seen" by a venue. Strangers seeing her phone number. |
| Delighters | "Free on your date" as the lead shelf; an absolute "Expected reply by Fri 13 Nov, 12:40 PM" instead of a ticking clock; one celebratory line at confirmation (`مبروك مقدمًا، تم تأكيد حجزكم.`). |
| Her seed request | Aurelia Gulf Hotel (V01), Danah Ballroom, ladies' reception, 350 guests × KD 52 = **KD 18,200.000**; deposit 30% **KD 5,460.000**; balance **KD 12,740.000** due Thu 31 Dec 2026. Sent Thu 12 Nov, 12:40 PM. |
| Design implications | Prefilled Brief everywhere (ADR 0007 D3); date-aware prices on cards (ADR 0018, 0004); calm Pending screen (`CL-BOOK-06`); WhatsApp-code sign-in with exact resume after the gate (ADR 0007 D9); Western digits and `د.ك` after an LTR-isolated number (ADR 0010); never "ليلة الخميس" (ADR 0011). |

### C2 · Umm Reem أم ريم — mother of the bride, veto-holder, sometimes the payer

| | |
|---|---|
| Snapshot | 55. Usually **not a registered user**: opens a link from WhatsApp or is handed Reem's phone. Arabic only, system text size 130-200%, prefers calling or voice notes, decides with her sisters. |
| Jobs to be done | *When my daughter shows me a hall, let me judge in seconds whether it is dignified and practical — women's entrance, bridal suite, kosha, valet and parking for elders, photo privacy, the food — without learning an app.* · *When it is time to pay, let me do it safely from my own card.* |
| Anxieties | Technology confusion. Fine print. Being rushed. Photo and phone privacy for women. Capacity too small for the family. "What will people say about this hall." Safety of paying online. |
| Design implications | Guest-first, read-only browse with no sign-in wall (ADR 0007 D8). Universal links `/v/{venue}?date=&guests=` and `/compare?ids=a,b,c` open for a guest (ADR 0009 D10; Share is flagged OQ-B-12). Compare fits 360 px without horizontal scroll (ADR 0009 D4). Facilities read as plain **Included / Extra / Not offered**; per-section policy facts (photography, abaya cloakroom, prayer room, separate entrance, female security) sit on Venue detail (ADR 0015 D6, `CL-VENU-05`). 44 px minimum targets with 48 px primary controls; layouts survive 200% text (ADR 0016 D8, ADR 0022 I). Call and chat visible. Paying from her own card: the pay-by link goes to the booker, who can forward it; a dedicated payer link is not built (OQ-B-24). |

### C3 · Fahad Al-Shammari فهد الشمري — the groom, owner of the men's reception

| | |
|---|---|
| Snapshot | 31. His side drives the **men's reception** (about 400 guests; Majlis Hall, 400 × KD 32 = KD 12,800) and signs off the budget. Often the payer. May have no account at all. |
| Jobs to be done | *Let me add the men's reception to the same night without a second booking.* · *Show me one total I can approve.* |
| Design implications | "Both" in booking step 1 adds a second section with its own hall, guests and package; totals are summed (the demo shows KD 31,000.000) and approval, payment and cancellation are atomic (ADR 0002 D6). The Review screen shows both sections and one payment schedule. Budget (`CL-WEDD-03`) shows committed versus paid versus remaining. |

### C4 · Rima Haddad ريما حداد — independent wedding planner (underserved in the MVP)

| | |
|---|---|
| Snapshot | 34. Runs 10-15 weddings a year with two phones and an iPad. English UI with Arabic-speaking clients. Shortlists for three clients at once and knows venue sales managers. |
| Jobs to be done | *Check many halls fast against a client's date and budget and send the family a comparison they can open.* · *Keep holds and paperwork organised per client.* |
| Anxieties | Double-booking across clients. Being undercut by Ghazal's own planner packages. Commission opacity. One account means one wedding. |
| Design implications and honest limits | Strong guest browse and shareable Compare. "Booking for: someone else" on the Details step (`CL-BOOK-04`). **Not supported in the MVP:** multiple wedding files per account; the cap of 3 open unpaid bookings per wedding file also limits parallel shortlists (OQ-B-24). A planner uses a normal client account (CF-17). |

### Segment note · expat couples

Roughly 70% of Kuwait's residents are not Kuwaiti nationals [V]. A typical expat wedding is about 250 guests at about KD 18 per person [V, 2022], booked at Classic-tier halls (Farwaniya, Jahra, Ahmadi, Qurain), often with an English UI, sometimes a mixed event, and sometimes a foreign SIM. Consequences: English is a first-class language, not a fallback; Mixed is present, neutral, last and never the default (ADR 0002 D4); the fixed `+965` phone chip excludes foreign WhatsApp numbers, so Apple, Google and email sign-in are the fallbacks (OQ-L-14).

## 3. Hotel personas (Aurelia Gulf Hotel, V01: Danah Ballroom and Majlis Hall)

The hotel app serves three modes of the same venue: **decide** (Admin, Manager), **respond** (Reception) and **reconcile** (Accountant). Navigation is identical for every role; content adapts (ADR 0008 D1). Roles hide, they never show lock icons.

### H1 · Hind Al-Enezi هند العنزي — Manager (the prototype's demo user)

| | |
|---|---|
| Snapshot | Reception manager at Aurelia Gulf Hotel. Moves between a desk, the ballroom floor and phone calls; checks the phone dozens of times a day. Role: everything except Staff and Bank information (ADR 0008 D12). |
| Jobs to be done | *At the start of any glance, tell me in seconds what needs my decision and what is coming tonight.* · *When a request lands, give me everything to decide without calling.* · *Block the date I just sold by phone, in three taps.* · *Never let a request expire unseen.* |
| Anxieties | A request lapsing inside the SLA. Double-booking from stale state. "Why is this pending?" from the owner. Clients who go silent after approval. A calendar that drifted from reality. |
| Her day at NOW | Today says "5 requests need your reply, first in 3h". Tonight: Majlis Hall men's reception 8:30 PM (310 guests, Salman Al-Harbi), Danah Ballroom ladies' reception 9:00 PM (420 guests, Najla Al-Badr, 420 × 52 = KD 21,840.000). Reem's request has 20h 40m left. |
| Design implications | Today is already the inbox: Needs-you ranked by nearest deadline (ADR 0008 D4). Accept in two taps with an 8-second Undo; Decline in three, with a required reason that powers the client's recovery path; Propose another date as the preferred alternative (ADR 0008 D6-D7, ADR 0001 D9). SLA state is text plus colour, never colour alone (ADR 0008 D3). Offline: decisions disabled in place, never queued. |

### H2 · Amal Al-Balushi أمل البلوشي — Reception

| | |
|---|---|
| Snapshot | Desk, own phone, up to 10-40 requests a week in peak. Cannot change prices or bank details. Language varies by colleague, so UI language is per user. |
| Jobs to be done | *Everything I need to decide on the card itself.* · *Answer the same ten questions fast.* · *Record cash at the desk.* |
| Permissions | Accept, Decline, Propose another date (Admin can switch this off); block and open dates; record cash on a balance; read and write messages. No revenue, bank, offers or analytics (ADR 0008 D12). Her Today shows Needs-you, events and messages; the "You receive KD X" amount is hidden from her. |

### H3 · Mahmoud Saleh محمود صالح — Accountant

| | |
|---|---|
| Snapshot | Part-time, expat, English UI, Android. Reconciles mostly in Excel and on the web dashboard; the app answers "did that deposit land?" |
| Jobs to be done | *Show which booking a payment belongs to and what is still due.* · *Keep bank details correct and safe.* |
| Design implications | Money-first Today; Booking detail money panel (deposit received, balance due, cash recorded, payout date); invoices (`HL-BOOK-05`); Bank information masked, view needs re-authentication (`HL-SETT-04`); read-only Messages. A changed-IBAN fraud is his nightmare, hence the 24-hour payout delay on a new account (ADR 0028 D6). |

### H4 · Khalid Al-Otaibi خالد العتيبي — Admin and owner

| | |
|---|---|
| Snapshot | Includes Manager. Last seen Thu 12 Nov, 3:55 PM. Owns Staff and Bank information (step-up required for both). Transferring ownership goes through Ghazal support. |
| Jobs to be done | *Protect prime Thursdays; fill the soft dates without devaluing the brand.* · *Keep our rating healthy.* · *Know what money is coming.* |
| Design implications | Today money tiles at browse precision (hero "Booked this month" with "KD X received", "Payable - next payout", "Open dates, next 30 days") only when commission and payout rules exist (OQ-B-16). A biometric lock is offered in a first-run sheet on Today after the first sign-in (revenue and bank data are sensitive). Prototype note: the demo persona is a Manager, so the Staff and Bank screens (Admin-only) need a persona or role switch to be shown. |

### H5 · Sara Al-Qattan سارة القطان — Marketing

Offers (flash, discount, coupon), analytics (views, clicks, bookings, revenue as booked value, conversion, top packages) and media (ADR 0008 D12). Her entry point is the soft-date insight: "N open weekend dates in 60 days" opens the Calendar in soft-date mode, then **New offer** (`HL-GROW-02`, `HL-GROW-03`) with a live preview of the client card. Her Today shows offers, an analytics glance and Needs-you; she cannot read or write chat (Messages are for Admin, Manager and Reception, and read-only for Accountant).

### Role-collapse case: the owner-operator

An independent hall (for example Qurain Grand Hall, V10) often has one person acting as owner, manager, accountant and reception. The role model must degrade to "everything visible" and the Staff screen to "Only you so far" with an Invite action.

## 4. People who matter but have no screen

| Actor | Why they matter | Where they appear |
|---|---|---|
| **Ghazal planner**, e.g. Nouf Al-Otaibi نوف العتيبي | Planners are Ghazal-managed supply assigned by the admin (CF-17); no fifth app | "Your planner" card (`CL-PLAN-03`), chat, video call Sun 15 Nov 7:30 PM (`CL-PLAN-04`) |
| **Ghazal Support** دعم غزل | Pinned conversation in both inboxes; handles disputes, refunds, ownership transfer, deletion requests | `CL-MSGS-01`, `HL-TODY-04`, `CL-PROF-06` |
| **Vendors**, e.g. Lamha Photography Studio استوديو لمحة للتصوير | Quote requests need a responder; vendor self-service is post-MVP (CF-18, OQ-P-02) | `CL-SERV-03`, `CL-SERV-04` |
| **Super Admin / finance** | Approves venues and payout verification, sets commission, moderates reviews, flags authority-order dates, assigns "instant-verified" | Web dashboard (context only) |

## 5. Language, access and device needs

| Persona | Language and digits | Accessibility and device needs |
|---|---|---|
| C1 Reem | Arabic UI; Western digits (default, ADR 0010) | Night use; increased text size sometimes; Face ID |
| C2 Umm Reem | Arabic only; never Latin-heavy copy | Text to 200%, 44 px minimum and 48 px primary targets, no gesture-only actions |
| C3 Fahad | Arabic or English, switchable at runtime without restart (NF-LOC-06) | Opens shared links as a guest |
| C4 Rima | English UI with Arabic venue names inside it (Cairo fallback, ADR 0016) | Tablet-size use is not designed in the MVP |
| H1-H2 | Per-user UI language; venue content is always bilingual (ADR 0013 D10) | Poor connectivity in ballrooms: cached shell with an "Offline - updated 4:00 PM" stamp |
| H3 Mahmoud | English UI; Eastern digits irrelevant | Reads exact three-decimal amounts; Android |
| H4 Khalid | Both | Biometric lock; revenue must not be visible to wandering eyes (a privacy toggle is not designed) |

## 6. Rules the personas impose (each is already an ADR)

1. **No sign-in wall before value.** Read-only browse, local hearts and Compare; the account is requested at commit moments and the exact intent resumes (ADR 0007 D8-D9).
2. **The booker is not always the payer or the decider.** Share and universal links; a "Booking for" field; no payer link in the MVP (OQ-B-24).
3. **Silence is the enemy.** Pending shows what is and is not happening to money and date, an absolute expected-reply time, Message venue and a calm timeline (ADR 0001 D5-D7).
4. **Staff need certainty, not decoration.** One primary action per card, no swipe actions, Undo instead of confirm dialogs, decisions never queued offline (ADR 0008 D5-D10).
5. **Respect privacy by default.** No faces, monogram avatars, no avatar upload, venue sees the contact number only for that request, with a disclosure line (ADR 0015; OQ-B-19).
6. **Arabic is not a translation.** Honorific plural `كم`, verbal-noun CTAs, gender-neutral copy, Khaleeji only in warm moments and in typed chat (ADR 0013).
7. **Roles hide, never lock.** Same five tabs for every staff role (ADR 0008 D1, D12).
