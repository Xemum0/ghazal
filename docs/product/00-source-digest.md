# Ghazal — Source Digest

> **Business model changed 2026-10-14 (ADR 0033, [`voucher-model.md`](voucher-model.md)).** Ghazal now sells only a KD 2 voucher; venues, halls and service providers sell and collect everything else. Anything in this file about deposits, balances, commission, payouts, cash, instant booking, cancellation tiers or the nine booking statuses is superseded; the screen inventory JSON and the architecture docs are already rewritten.

> Compact, reconciled digest of the two source documents. **Originals stay untouched** in the repo root:
> `project.md` (markdown PRD, "v1.0 MVP + Future Roadmap") and `Ghazal_PRD_EN.pdf` (polished 15-page PRD, dated 1 Aug 2026).
> When the two disagree, this file records the conflict and the working resolution. Final decisions live in `docs/decisions/`.
>
> **Status banner (2026-10-12):** section 9 was written before the ADRs. Its `Resolved by` column now names the ADR that closed each gap; where it says `proposed`, the ADR is `proposed-needs-owner` and only a working assumption (see `docs/decisions/README.md`). Where this file and an accepted ADR disagree, the ADR wins.

## 1. What Ghazal is

**Ghazal (غزل)** — a premium wedding-venue marketplace for **Kuwait**, GCC later. Couples discover, compare (up to 3), check live availability, request a booking with a deposit, then plan the rest of the wedding (planner, vendors, budget, checklist, countdown, chat) in the same app. Venues run their calendar, bookings, pricing and offers from a venue app and web dashboard; the owner runs the platform from a super-admin dashboard.

Vision: *"the Booking.com of wedding venues in Kuwait"* — default place a couple starts, default channel through which venues fill their calendar. Venue booking is the entry point; the long-term value is the 6–18-month wedding-planning layer around it.

Today's pain (PRD §2): research scattered across Instagram + WhatsApp, no side-by-side comparison, availability unknown until someone answers a phone, inconsistent unpublished prices, no single record of bookings/payments/agreements.

## 2. Four products (all bilingual: Arabic RTL + English LTR)

| # | Product | Platform | Tech (PDF) | **In scope of the current design pass** |
|---|---------|----------|-----------|------|
| 1 | **Client Mobile App** | iOS + Android | Flutter | ✅ yes |
| 2 | **Venue / Hotel Mobile App** | iOS + Android | Flutter | ✅ yes |
| 3 | Venue Admin Dashboard | Web | React | next design pass (design system must extend to it) |
| 4 | Super Admin Dashboard | Web | React | next design pass |

Shared backend: REST API, PostgreSQL, Redis, object storage + CDN, FCM push, WhatsApp OTP, payment gateway, real-time chat, RBAC, audit logging.

## 3. Users

- **Primary:** bride, groom, bride's family, wedding planners.
- **Venue partners:** hotels, wedding halls, event venues, government wedding halls, luxury villas.
- **Vendors (post-MVP categories):** photographers, videographers, florists, decoration, dress shops, makeup, DJ/MC, entertainment, invitations, catering, car rental, cakes, honeymoon agencies.

## 4. Client app — requirement groups (PRD §6 / project.md)

6.1 Auth: sign up/login, Apple, Google, phone OTP **via WhatsApp**, forgot password, biometric, **guest browsing**.
6.2 Onboarding: intro screens; wedding date, budget, guest count, preferred area, bride/groom profile, language (AR/EN).
6.3 Home: hero search (date/area/budget/guests), quick categories (Luxury Hotels, Wedding Halls, Government Halls, Beach, Outdoor, VIP), featured, special offers, last-minute deals, available this week, trending, nearby, recommended for you.
6.4 Search & filters: location/area, price, capacity, indoor/outdoor/mixed, parking, valet, bridal room, buffet included, decoration included, photography allowed, **women-only / men-only / mixed**, availability, instant booking, rating, newest, luxury level, hotel brand.
6.5 Venue card: photo, video, rating + review count, price / starting price, capacity, area, availability badge, favourite, compare, book.
6.6 Venue details: large gallery, videos, (360° = future placeholder), description, amenities, rules, packages, capacity, map (Google Maps), parking, bridal room, groom room, decoration, buffet, lighting, stage, music, policies (cancellation, children, dress code), working hours, reviews, FAQ, **availability calendar**, similar venues.
6.7 Compare: up to 3 venues — price, guests, area, buffet, parking, decoration, rating, photos, packages, availability, distance, **book from the comparison view**.
6.8 Booking flow: date → time → package → extras → guest count → personal info → special requests → review → confirm → **deposit payment** → confirmation → invoice.
6.9 Payment: KNET, Visa, Mastercard, Apple Pay, Google Pay, cash (where venue allows), deposit or full payment; installments = future.
6.10 Booking status: Pending, Approved, Rejected, Cancelled, Completed, Refunded.
6.11 Wedding planner (**"biggest differentiator"**): after choosing a venue — "Need a wedding planner?" → Silver / Gold / Royal packages → request consultation → chat → schedule meeting.
6.12 Wedding services: photography, videography, flowers, cake, DJ, MC, live music, henna, bridal makeup, wedding dress, suit rental, luxury cars, invitations, hotels, travel, honeymoon.
6.13 Planning tools: wishlist (venues/services/packages), budget manager (budget/spent/remaining/categories/alerts), checklist (invitation, dress, venue, photographer, cake, music, flowers, transportation, completed %), countdown (365/180/30/7 days, tomorrow, today).
6.14 Chat: venue, planner, vendor, support; media, documents, voice messages.
6.15 Notifications: booking updates, offers, price drops, new venues, messages, payments, pre-wedding reminders.
6.16 Reviews (photos, videos, ratings, comments, owner replies) & profile (personal + wedding info, saved venues, bookings, payments, language, settings, **account deletion** — required by Apple/Google), loyalty (points, coupons, referral rewards).

## 5. Venue / Hotel mobile app — requirement groups (PRD §7)

Purpose: *manage the venue without opening a laptop.*
7.1 Dashboard: today's bookings, revenue, pending requests, notifications, messages, availability.
7.2 Bookings: accept, reject, reschedule, call client, chat, invoice.
7.3 Calendar: monthly / weekly / daily; blocked dates; available dates.
7.4 Venue management: photos & videos, packages & prices, capacity & amenities, policies, offers, availability.
7.5 Offers: create offer, flash sale, discount, coupon.
7.6 Analytics: views, clicks, bookings, revenue, conversion, top packages.
7.7 Notifications: new booking, cancelled booking, payment received, new reviews.
7.8 Settings: staff, bank info, business hours, languages.

(Web dashboards, PRD §8–9, are summarised in `docs/product/` once written; out of scope for this design pass.)

## 6. Design direction given in the PRD (§10)

Theme: **luxury · minimal · elegant · premium** — *"closer to a five-star hotel brand than a classified-ads app. Large imagery, generous whitespace, rounded cards, a restrained gold accent."*
Principles: luxury hotel feel · minimal cards · rounded corners · large images · generous whitespace · **full RTL mirroring** · **accessible contrast** · **consistent component library**.

| Role (PRD) | Name | Hex |
|---|---|---|
| Primary surface | Soft Rose | `#F8E7EC` |
| Background | Warm Off White | `#FFF9F5` |
| Accent & actions | Matte Gold | `#D8B26E` |
| Text & headings | Dark Rose Gray | `#5A4B4F` |

Typography (PRD): Arabic = **Cairo**, English = **Poppins**.

## 7. Non-functional requirements (PDF §12)

Localisation: full AR (RTL) + EN (LTR) across all four products incl. mirrored layouts, dates, numbers · Performance: home & search load ≤ 2 s on normal 4G · Availability: managed cloud, automated daily DB backups · Security: encrypted transport, hashed credentials, RBAC, 2FA for admins, audit logs · Payments: **no card data stored**, delegated to certified gateway · Privacy: in-app account deletion · Scalability: stateless API, horizontal scale · Compatibility: **iOS 14+ (PRD; ADR 0022 proposes iOS 15.0, CF-35, needs owner sign-off), Android 8+**, current Chrome/Safari/Edge · Analytics: events on search, venue view, comparison, booking, payment.

## 8. Roadmap & scope

- **MVP = Phase 1 + Phase 2:** venue discovery, booking, comparison, payments + wedding-services marketplace, planner, chat, reviews (planning tools + chat included to make the product sticky).
- **Phase 3 (out of scope):** AI wedding assistant, AI budget planner, smart timeline, smart checklist.
- **Phase 4 (out of scope):** UAE, KSA, Qatar, Bahrain, Oman.
- **Explicitly deferred:** 360° tours, payment installments, AI demand prediction, revenue forecasting, fraud detection, dynamic-pricing suggestions, GCC expansion.
- Timeline (PDF §15): 8 weeks — Phase 1 UI/UX design (1 wk, **all apps, screens in Arabic and English**, approved before dev) → backend/API/DB (2) → client app (2) → hotel app + venue dashboard (2) → super admin + QA + launch (1).
- Hosting: Google Cloud (Cloud Run, Cloud SQL, Cloud Storage + CDN, Maps). Accounts in the **owner's** name.

## 9. Conflicts & gaps between `project.md` and the PDF (working resolution)

| # | Topic | `project.md` | PDF | Working resolution | Resolved by |
|---|---|---|---|---|---|
| 1 | Mobile framework | Flutter **or** React Native | Flutter (one codebase, both apps) | **Flutter** | ADR 0022 (accepted) |
| 2 | Backend | Laravel or NestJS | NestJS or Laravel | **Undecided** — owner decision; design is backend-agnostic. Recommendation: NestJS 12 | ADR 0020 (proposed-needs-owner, OQ-T-01) |
| 3 | Media storage | AWS S3 | Google Cloud Storage + CDN | **GCS** (PDF is the later, costed document) | ADR 0026 (accepted) |
| 4 | Auth | Firebase Auth | Backend JWT + OAuth | **Backend JWT + OAuth** (PDF) | ADR 0028 (accepted) |
| 5 | OTP channel | "OTP" | **WhatsApp** OTP (no SMS gateway) | **WhatsApp** | ADR 0028 (accepted); fallback open, OQ-T-08 |
| 6 | Marketing channels | Push, SMS, Email | Push, **WhatsApp**, Email | Push + WhatsApp + Email; SMS out | matrix CF-06 |
| 7 | AI recommendations | listed in client app (venues, services, package, budget optimisation) | AI assistant/budget planner = Phase 3 | MVP ships **rules-based** "Recommended for you" + budget suggestions; no AI chat | matrix CF-07 |
| 8 | Deposit timing | "Confirm → Deposit Payment" before status Pending→Approved | not specified | ~~GAP~~ **Resolved by ADR 0001, pending owner answer OQ-B-01:** request-then-pay; no money moves before the venue approves; instant booking is an earned per-hall opt-in | ADR 0001 (accepted), ADR 0005 (proposed, deposit numbers) |
| 9 | Booking granularity | "Choose Date, Choose Time" | — | ~~GAP~~ **Resolved:** hall x date x session; up to two sections (ladies and men's) | ADR 0002 (accepted) |
| 10 | Government halls | listed as a venue type | — | ~~GAP~~ **Resolved:** government halls are a booking channel with their own rules | ADR 0002 (accepted) |
| 11 | Numerals | — | "mirrored layouts, dates and numbers" | ~~GAP~~ **Resolved:** the PRD is silent on the digit set; Western 0-9 by default, an Eastern-digit switch is an owner-approvable proposal | ADR 0010 (accepted), OQ-L-01 |
| 12 | Currency | — | "dinar" | ~~GAP~~ **Resolved:** KWD, 3 decimals, one shared formatter; consumer English `KD`, Arabic `د.ك`, `KWD` only on invoices and the API | ADR 0010 D7 (accepted) |
