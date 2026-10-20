# Decisions only the owner can make

Written 2026-10-14. Plain language. Each item says what we need from you, why it matters, what the prototype assumes until you answer, and where the full text lives (ADR = decision record in `docs/decisions/`, OQ = open question in `docs/product/open-questions.md`, A-nn = working assumption in ADR 0033). Nothing here blocks the design: every answer changes a setting, a sentence or one screen, not the structure. Items that the voucher model made pointless (deposits, balances, cancellation tiers, commission, payouts, loyalty points, venue coupons, instant booking) were dropped; they are listed in OQ section 6.

## 0. Things to do or confirm now

1. **Delete the pirated archive `BookingSaaS v2.3 Nulled.rar`** from the project folder (move it out of the repo). It is a cracked script: licence violation and malware risk. The agents are forbidden to open it and tools are set to refuse it; only you can remove it. (OQ-T-07, AGENTS.md)
2. **Decide the first git commit ("baseline").** Today the repository has no commits. We recommend: one baseline commit made at your instruction at design freeze, tagged `design-v1`, in a private repository under your GitHub organisation, branch renamed `main`. Also decide whether the large generated photo variants (`design/public/images/_v`, about 63 MB) are committed or regenerated. Nobody commits until you say so. (OQ-T-07, ADR 0026)
3. **Have five Kuwaiti readers look at the display typeface** (El Messiri for headings, Manrope for English, Almarai for Arabic, chosen 2026-10-13) before visual freeze, and name the native Kuwaiti copy reviewer for the Arabic wording. (OQ-L-06, OQ-L-09, ADR 0031 addendum)
4. **Confirm the voucher numbers in section 1** (KD 2.000, 60 days, refund rules). The prototype shows them as if final but they are settings.

## 1. Money and vouchers

| # | Question | Why it matters | Prototype assumes | Ref |
|---|---|---|---|---|
| 1 | Is the voucher exactly KD 2.000, with no VAT line, and who pays the payment-gateway fee when a voucher is refunded? What is the Arabic name (the word «قسيمة» also means a land plot in Kuwait)? | On KD 2 the gateway fee is a large share of the revenue; the name appears on every screen. | KD 2.000 as a setting, no VAT, Ghazal pays refund fees, Arabic UI says «كوبون». | OQ-V-15, A-15 |
| 2 | Is a voucher tied to one venue or provider (and its quote) from the moment it is bought, or can the client move it before using it? | Tying stops resale and fits "the saving depends on that venue's price", but a client who changes their mind loses KD 2 unless reuse or refund applies. | Tied at purchase; single-use code; same-venue re-quote allowed. | OQ-V-01, A-01 |
| 3 | How long is a voucher valid, and for how long can it be reused after a request is released? | Drives reminders, wallet states and refund exposure. | 60 days to use, 60 days to reuse at the same venue. | OQ-V-02, A-02 |
| 4 | In which cases is the KD 2 refunded, only reusable, or used up? | The refund table is the main cost and trust lever of the model. | Declined, venue silent, venue cancels: reusable and refundable. Client withdraws or lets the 24 h confirm lapse: reusable only. Cancel after confirming, or completed: used up. | OQ-V-03, A-03 |
| 5 | What happens when a venue refuses to honour the voucher price after the client confirmed? | Ghazal holds no money, so its only levers are reputation and support. | 72-hour "Report an issue" opens a support case; reliability strikes; repeated cases suspend the listing; no compensation promised in the app. | OQ-V-04, A-04 |
| 6 | Can a confirmed booking be moved to another date in the app? | Rescheduling disappeared with deposits. | No; changes are agreed in chat; a new request needs a new voucher unless the venue cancelled. | OQ-V-05, A-05 |
| 7 | Does the voucher price also apply to extras (kosha, flowers, photographer, extra hour) or only to packages? | Decides whether every extra carries two prices. | Extras have one price, settled with the venue. | OQ-V-18, A-17 |
| 8 | Do signed-out visitors see the voucher price number, or only that a voucher exists? | Showing it is the sales pitch; hiding it protects venue prices from screenshots and pushes sign-up. | Guests see both prices with a lock and "Register to unlock"; they cannot buy. | OQ-V-09, A-14 |
| 9 | Is the headline saving "you save KD 2,800" (before the KD 2) or net of the voucher fee? | Honest wording of the main sales line. | The venue screens show the gross saving. | requests.md (client-venue note); voucher-model section 6 |
| 10 | Any referral or loyalty scheme (for example a free voucher for inviting a friend)? | Loyalty screens were retired; referral could return as voucher credit. | None in the MVP. | OQ-V-16 |
| 11 | Can MyFatoorah confirm in writing: refunds (windows, timing per method), KNET and Apple Pay limits, fees? | Refund copy and the "arrives in N days" promises depend on it. Now only the voucher and ad fees go through the gateway. | Generic refund-time copy until confirmed. | OQ-B-02 = OQ-T-04, ADR 0027 |

## 2. Partners and advertising

| # | Question | Why it matters | Prototype assumes | Ref |
|---|---|---|---|---|
| 12 | **What are the weekly, monthly and annual advertising or listing rates, and does the plan period start at approval or at payment?** | No screen can show a price until rates exist. | No number anywhere; the UI says "Rates announced soon"; the period starts at approval. | OQ-V-07, A-07 |
| 13 | While rates are undecided, may a provider submit a listing, have it reviewed and go live, with payment opening later? | Without this the services section is empty at launch. | Yes; the pay step stays disabled with a reason until you set the rates. | OQ-V-17 (A-16), OQ-V-P1 in OQ |
| 14 | If a listing is rejected after it was paid, is the plan kept for a resubmission, refunded, or both? | Partner refund policy and support load. | Kept 14 days, then refunded in full. | OQ-V-08, A-08 |
| 15 | Does a material edit to a live listing need a new review? | Compliance versus provider friction. | Yes for category, photos, description and prices; the old version stays live meanwhile. | OQ-V-10, A-09 |
| 16 | Do ordinary hotels and halls also pay to be live, and what makes a hotel "major" (who decides, which criteria, can it be revoked)? | The brief exempts only major hotels, which implies others pay. | All partners pay unless the Super Admin flags them major; no public criteria; the flag removes the fee, never the review. | OQ-V-13, A-12 |
| 17 | May one login hold both a hotel/hall account and a service-provider account? | Decides the account switch and the data model. | Yes, with a switch in More. | OQ-V-06, A-06 |
| 18 | How do partner staff sign in (WhatsApp invite and password, extra codes, who is Admin above Manager)? | Defines sign-in screens and role limits. | WhatsApp invite, password, code on new devices, authenticator app for admins. | OQ-B-17 = OQ-T-09, ADR 0028 |
| 19 | Can venues reply once to a review and report abuse, but not approve or hide reviews? | Venue-controlled approval would destroy trust in reviews. | Reply and report only, in the Partner app. | OQ-B-25, OQ-P-18 |

## 3. Venues and visits

| # | Question | Why it matters | Prototype assumes | Ref |
|---|---|---|---|---|
| 20 | Who staffs the Ghazal support seat in every visit group chat, in which hours, and how long do chats stay open? | A three-way chat with an empty seat is a broken promise. | Support is added automatically; read-only 24 h after the slot; archived at 30 days. Hours and service level are your business decision. | OQ-V-12, A-11 |
| 21 | Do service providers (tastings, floral consultations) also get visits with a group chat? | You described visits for hotels and halls. | Hotels and halls only; providers use a quote chat. | OQ-V-11, A-10 |
| 22 | Are governmental facilities browse-only (no voucher, no request, no visit) with a link to the official channel? | Their fees are official; there is no Ghazal price to unlock. | Yes, browse-only. | OQ-V-14, A-13 (also OQ-B-10) |
| 23 | How long may a venue take to reply to a request, and should reply speed rank venues or show a badge? | Too long freezes dates, too short makes venues miss requests. | 24 h reply window (venue picks 12, 24 or 48 h); speed ranks quietly, no public badge yet. | OQ-B-07 (reply half survives) |
| 24 | What are the real hall and session set-ups of the first venues (sessions, one wedding per day, ladies and men sections)? | Sets how much hall and session UI is real. | Afternoon, evening, full-day templates; ballrooms one wedding per day; up to two sections. | OQ-B-09, ADR 0002 |
| 25 | May the client name a family member as the venue's contact, and does the venue see that number as soon as the request is sent? | Bride privacy versus the venue's need to call. | Yes, with a clear notice at send. | OQ-B-19 |
| 26 | Do venues record offline sales as labelled blocks, and do we nudge them weekly to keep the calendar true? | A stale calendar is the biggest risk to "live availability". | Yes to both. | OQ-B-22 |
| 27 | What happens to the venue's standing when it cancels a confirmed request (strikes, ranking, suspension)? | The app must state real consequences. | A strike that lowers search rank; repeated cases suspend; voucher released and refundable. | OQ-B-18 (voucher half), A-03 |
| 28 | Venue photos: empty rooms only (no people), enforced by review? Review photos: moderated, text only, or venue-supplied only? Who staffs the queue? | Most venues' own photos show people; moderation needs a person. | Empty-room galleries; review photos go through a human queue, with text-only as the fallback. | OQ-L-07, OQ-L-08, ADR 0015 (proposed) |
| 29 | Who onboards and enters data for the first 10 to 20 venues and takes the empty-room photos? | Launch needs real listings. | Super Admin staff enter owner-supplied venues. The 21-venue roster is fictional prototype data. | OQ-P-12 |
| 30 | Home categories: what do Luxury Hotels, VIP, Beach, Outdoor mean, and are Villas a category? | Defines the quick-category tiles. | One admin-managed taxonomy; Villas added pending you. | OQ-P-06 |

## 4. Legal and operations

| # | Question | Why it matters | Prototype assumes | Ref |
|---|---|---|---|---|
| 31 | Who issues the invoices and receipts for the voucher and for listing plans (Ghazal, since venue money is no longer involved), what do your accountant and lawyer say about tax lines and e-invoicing, and is a separate Arabic PDF service acceptable in the cost plan? | Wording of every receipt. | Wording undecided. The older placeholder ("issued by the venue via Ghazal") no longer fits because venue money is off-app; tax lines at 0% pending legal review. | OQ-B-06 = OQ-T-12 (wording updated by ADR 0033) |
| 32 | Which analytics tool and consent model (first-party events, optional Firebase), what retention, has Kuwaiti data-privacy law been checked? | Needed before any tracking ships. | First-party events, a "Share usage data" toggle on by default, 13-month retention, legal sign-off before launch. | OQ-L-11 = OQ-T-14, ADR 0019 (proposed) |
| 33 | Account deletion while a voucher or a confirmed request is active: block, or accept and complete after the event? Which records must be kept? | Apple requires deleting in-app; money records are tiny now but vouchers exist. | Older text says: blocked while a future booking exists, with a support route; personal data anonymised, financial records kept. It needs rewording for vouchers. | OQ-B-20 |
| 34 | Must venues write every text in both Arabic and English before publishing, and who translates when they cannot? | Bilingual promise versus venue effort. | Both required, per-language completeness shown, no machine translation. | OQ-L-16, ADR 0013 |
| 35 | Confirm: Sunday-first weeks, Thursday to Saturday peak band, 12-hour clock; digit switch (Western or Eastern Arabic digits) visible in Settings; English "KD" versus invoice "KWD"; fixed +965 phone field. | Small defaults that appear everywhere. | As listed; Western digits by default. | OQ-L-01, L-02, L-03, L-14 |
| 36 | Push-notification timing: quiet hours 23:00 to 08:00, no marketing on Friday prayer, marketing after Maghrib in Ramadan? | Respect and store rules. | As listed (ADR 0007 says 22:00, to be reconciled). | OQ-L-15 |
| 37 | Who supplies the logo, Terms of Use, Privacy Policy, and hosts the small public page the stores need (privacy URL, account deletion)? | Store submission cannot happen without them. | Wordmark and placeholder legal screens. | OQ-P-11 |
| 38 | May the prototype be shared on an unguessable, noindex preview link, and has anyone cleared the fictional venue and brand names? | Showing the prototype outside the team. | Unguessable link, 7-day expiry, fictional content only; quick trademark check first. | OQ-T-13, OQ-L-18 |
| 39 | Are you comfortable with mirrored time axes in Arabic charts (earlier on the right)? Can five Kuwaiti users test it? | Hotel analytics screens. | Mirrored, with a table alternative. | OQ-L-05 |

## 5. Technology and accounts

| # | Question | Why it matters | Prototype assumes | Ref |
|---|---|---|---|---|
| 40 | **Backend: NestJS (recommended) or Laravel?** Who will maintain it after handover? | Decide before the first line of backend code. | NestJS 12 on Node 24; design work is identical either way. | OQ-T-01, ADR 0020 (proposed) |
| 41 | Accept iOS 15 and Android 8 as the minimum versions (the PRD said iOS 14+)? | Which phones the app supports. | Yes (conflict CF-35). | OQ-T-02, ADR 0022 |
| 42 | Are the Apple Developer and Google Play accounts personal or company accounts, and do you have a company number and a Kuwait commercial licence? | A personal Play account needs 12 testers for 14 days before release. | Company accounts in your name in week 0. | OQ-T-03, ADR 0026 |
| 43 | Which domain and app identifiers (for example `com.ghazal.client`)? | Fixed once stores see them. | Placeholders until you supply them. | OQ-T-06 |
| 44 | Monthly cloud budget cap and region (Doha is nearest); any Kuwait data-residency need? | Infrastructure choices. | USD 20 to 100 a month, me-central1. | OQ-T-05, ADR 0026 |
| 45 | WhatsApp sign-in codes: Meta directly or through a provider; who completes Meta business verification? No SMS is planned. | Sign-in cannot work without it. | Meta directly, started in week 0. | OQ-T-08, ADR 0028 |
| 46 | Venue video limits (length, size, who pays delivery cost)? | Upload and cost design. | 60 seconds, 100 MB, 720p. | OQ-T-15 |

## Working assumptions you do not need to answer now

ADR 0033 A-01 to A-17 and the proposed ADRs 0015 (imagery), 0019 (analytics), 0020 (backend) and the iOS floor in 0022 stay "working assumption" until you confirm; the prototype builds them as settings and never presents them to users as final. When you answer, tell us the item number or the OQ id and it is recorded in the ADR and moved to section 6 of `open-questions.md`.
